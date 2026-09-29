#!/usr/bin/env bash
#
# A private, disposable PostgreSQL instance per checkout, for `mix test`.
#
# Every checkout — the main clone and each git worktree — tests against its own
# postmaster, so concurrent `mix test` runs never share a server, a checkpointer
# or a database name, and the developer's real server is never touched by the
# suite. The instance is created on first use,
# lives under /tmp, and is destroyed with `rm -rf`: no `DROP DATABASE`, nothing
# to wait for, nothing to leak.
#
# `test/config/test.exs` runs `ensure` itself under MIX_ENV=test (unless CI or
# AURORA_UIX_TEST_PG=shared is set), so plain `mix test` in any checkout just works.
#
#   scripts/test_pg.sh ensure   # create if missing, start if stopped; prints the socket dir
#   scripts/test_pg.sh status   # where the instance is and whether it runs
#   scripts/test_pg.sh psql     # open psql on it (extra args are passed through)
#   scripts/test_pg.sh stop     # stop it (immediate — the data is disposable)
#   scripts/test_pg.sh destroy  # stop and delete its data directory
#   scripts/test_pg.sh sweep    # destroy every instance whose checkout no longer exists
#   scripts/test_pg.sh stop-idle    # stop every running instance with no client connected
#   scripts/test_pg.sh destroy-all  # destroy every instance, running or not
#
# The instance listens on a Unix socket inside its own data directory and on no
# TCP port at all, so there is nothing to allocate and nothing that can collide:
# clients connect with socket_dir = the data directory (Postgrex's `:socket_dir`,
# psql's `-h`). Instances are keyed by the checkout's directory name plus a short
# hash of its full path, so two clones named alike never collide either. Each
# instance records its checkout path in CHECKOUT; `sweep` destroys the ones
# whose path is gone. A stopped instance costs nothing but disk and `ensure`
# restarts it in well under a second, so `stop-idle` is safe to run any time.

set -euo pipefail

INSTANCES_ROOT="${AURORA_UIX_TEST_PG_ROOT:-/tmp/aurora_uix_pg}"
PG_USER=postgres

# --- Privilege drop ---------------------------------------------------------------
# initdb/pg_ctl refuse to run as root. Cloud sessions run this script as root; a
# local checkout never does (a developer's shell is never uid 0), so this is a
# no-op there and the direct-call behavior is unchanged.
run_as_pg() {
  if [ "$(id -u)" -eq 0 ]; then
    runuser -u "$PG_USER" -- "$@"
  else
    "$@"
  fi
}

# --- PostgreSQL binaries -------------------------------------------------------
# Homebrew's postgresql@16 is keg-only; look there when pg_ctl is not on PATH.
pg_bin() {
  if command -v "$1" >/dev/null 2>&1; then
    command -v "$1"
    return
  fi
  local candidate
  for candidate in /opt/homebrew/opt/postgresql@*/bin /usr/local/opt/postgresql@*/bin /usr/lib/postgresql/*/bin; do
    if [ -x "$candidate/$1" ]; then
      echo "$candidate/$1"
      return
    fi
  done
  echo "test_pg: $1 not found; install PostgreSQL client tools or set AURORA_UIX_TEST_PG=shared" >&2
  exit 1
}

# --- Identity --------------------------------------------------------------------
checkout_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd -P
}

# `section-812-be-1` -> `section_812_be_1`; the hash keeps same-named clones apart.
instance_name() {
  local root="$1"
  local base
  base=$(basename "$root" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//')
  local hash
  hash=$(printf '%s' "$root" | cksum | cut -d' ' -f1)
  printf '%s-%08x' "$base" "$hash"
}

instance_dir() {
  echo "$INSTANCES_ROOT/$(instance_name "$1")"
}

# --- Lifecycle -------------------------------------------------------------------
running() {
  "$(pg_bin pg_ctl)" status -D "$1" >/dev/null 2>&1
}

create() {
  local data="$1" root="$2"
  mkdir -p "$INSTANCES_ROOT"
  # initdb runs as $PG_USER (see run_as_pg); it needs write access to create
  # its data dir under here, which a root-owned $INSTANCES_ROOT wouldn't grant.
  [ "$(id -u)" -eq 0 ] && chown "$PG_USER" "$INSTANCES_ROOT"
  run_as_pg "$(pg_bin initdb)" -D "$data" -U "$PG_USER" --auth=trust \
    --encoding=UTF8 --locale=en_US.UTF-8 >"$data.initdb.log" 2>&1 \
    || { cat "$data.initdb.log" >&2; exit 1; }
  rm -f "$data.initdb.log"
  printf '%s\n' "$root" >"$data/CHECKOUT"
  # Disposable data: trade every durability guarantee for speed. Unix socket
  # only — the socket directory is passed at start, since it is the data dir.
  cat >>"$data/postgresql.conf" <<'CONF'

# --- aurora_uix test instance (scripts/test_pg.sh) ---
listen_addresses = ''
fsync = off
synchronous_commit = off
full_page_writes = off
shared_buffers = 256MB
max_connections = 120
log_min_messages = warning
log_checkpoints = off
CONF
}

start() {
  local data="$1"
  run_as_pg "$(pg_bin pg_ctl)" start -D "$data" -w -s -l "$data/server.log" \
    -o "-k '$data'" >/dev/null
}

ensure() {
  local root data
  root=$(checkout_root)
  data=$(instance_dir "$root")
  [ -f "$data/PG_VERSION" ] || create "$data" "$root"
  running "$data" || start "$data"
  echo "$data"
}

status() {
  local root data
  root=$(checkout_root)
  data=$(instance_dir "$root")
  echo "checkout: $root"
  echo "instance: $data"
  if [ ! -f "$data/PG_VERSION" ]; then
    echo "state:    absent"
  elif running "$data"; then
    echo "state:    running (socket $data/.s.PGSQL.5432)"
  else
    echo "state:    stopped"
  fi
}

open_psql() {
  local data
  data=$(ensure)
  exec "$(pg_bin psql)" -h "$data" -U "$PG_USER" -d "${PGDATABASE:-aurora_uix_test}" "$@"
}

stop_instance() {
  local data="$1"
  if running "$data"; then
    run_as_pg "$(pg_bin pg_ctl)" stop -D "$data" -m immediate -s >/dev/null
  fi
}

destroy_instance() {
  local data="$1"
  stop_instance "$data"
  rm -rf "$data"
  echo "destroyed $(basename "$data")"
}

client_connections() {
  "$(pg_bin psql)" -h "$1" -U "$PG_USER" -d postgres -Atq \
    -c "select count(*) from pg_stat_activity where backend_type = 'client backend' and pid <> pg_backend_pid()" \
    2>/dev/null || echo 0
}

stop_idle() {
  local data connections
  [ -d "$INSTANCES_ROOT" ] || { echo "no instances"; return; }
  for data in "$INSTANCES_ROOT"/*/; do
    data="${data%/}"
    [ -f "$data/PG_VERSION" ] && running "$data" || continue
    connections=$(client_connections "$data")
    if [ "$connections" -eq 0 ]; then
      stop_instance "$data"
      echo "stopped   $(basename "$data")"
    else
      echo "busy      $(basename "$data") ($connections connection(s))"
    fi
  done
}

destroy_all() {
  local data
  [ -d "$INSTANCES_ROOT" ] || { echo "no instances"; return; }
  for data in "$INSTANCES_ROOT"/*/; do
    data="${data%/}"
    [ -f "$data/PG_VERSION" ] || continue
    destroy_instance "$data"
  done
}

sweep() {
  local data checkout
  [ -d "$INSTANCES_ROOT" ] || { echo "no instances"; return; }
  for data in "$INSTANCES_ROOT"/*/; do
    data="${data%/}"
    [ -f "$data/PG_VERSION" ] || continue
    checkout=$(cat "$data/CHECKOUT" 2>/dev/null || true)
    if [ -n "$checkout" ] && [ -e "$checkout/.git" ]; then
      echo "kept      $(basename "$data") ($checkout)"
    else
      destroy_instance "$data"
    fi
  done
}

case "${1:-}" in
  ensure) ensure ;;
  status) status ;;
  psql) shift; open_psql "$@" ;;
  stop) stop_instance "$(instance_dir "$(checkout_root)")" ;;
  destroy) destroy_instance "$(instance_dir "$(checkout_root)")" ;;
  sweep) sweep ;;
  stop-idle) stop_idle ;;
  destroy-all) destroy_all ;;
  *)
    echo "usage: scripts/test_pg.sh {ensure|status|psql|stop|destroy|sweep|stop-idle|destroy-all}" >&2
    exit 64
    ;;
esac
