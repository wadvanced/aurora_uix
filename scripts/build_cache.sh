#!/usr/bin/env bash
#
# Restores and saves the compiled dependencies, the test build and the dialyzer PLT, so a
# fresh machine does not recompile them (about 30 minutes cold).
#
#   scripts/build_cache.sh key       # print the cache key for this machine and lockfile
#   scripts/build_cache.sh check     # test that the store can be reached and written
#   scripts/build_cache.sh restore   # download and unpack the cached parts for the key
#   scripts/build_cache.sh build     # fetch and compile dependencies, build the PLT (incremental)
#   scripts/build_cache.sh save      # pack and upload each part that is not stored yet
#   scripts/build_cache.sh ensure    # check, restore, then build and save each part in turn
#
# The cache lives in S3, in two objects per key:
#
#   s3://$CACHE_BUCKET/build-cache/$PROJECT/<key>-build.tar.zst   deps/ and _build/<env> per env
#   s3://$CACHE_BUCKET/build-cache/$PROJECT/<key>-plt.tar.zst     priv/plts
#
# and needs PROJECT, CACHE_BUCKET and AWS credentials (AWS_ACCESS_KEY_ID,
# AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION) in the environment. Without PROJECT and
# CACHE_BUCKET there is no store: `restore` and `save` do nothing and `ensure` only builds.
# BUILD_CACHE_LOCAL_DIR=<dir> uses a local directory as the store instead of S3.
#
# Which Mix environments are prepared, set per project in the cloud environment:
#
#   BUILD_CACHE_MIX_ENVS   environments compiled and cached, space-separated (default: dev test)
#   BUILD_CACHE_PLT_ENV    environment the dialyzer PLT is built in (default: dev)
#
# dialyxir is `only: [:dev]` here and `mix consistency` runs in dev, while `mix test` runs in
# test, so both are compiled and the PLT is built in dev. The settings are part of the cache key.
#
# `ensure` saves the build part as soon as the dependencies compile, before the slow PLT
# step, so a session that is stopped or times out during the PLT still leaves the build part
# behind and the next session only builds the PLT.
#
# While it runs, `ensure` keeps a progress log in the store, one object per session start,
# rewritten at every step and every BUILD_CACHE_LOG_INTERVAL seconds (default 30), including
# mix's own output:
#
#   s3://$CACHE_BUCKET/build-cache/$PROJECT/logs/<UTC start>-<session>.log
#
# <session> is BUILD_CACHE_SESSION (the hook passes the Claude Code session id) or a random
# tag. Every line carries its UTC time, mix's output included. Names start with the start
# time, so the newest log sorts last:
#   aws s3 ls s3://$CACHE_BUCKET/build-cache/$PROJECT/logs/ | sort | tail -1
#
# Every session start also appends a START and an END line to a shared index (the last 500
# lines are kept), so concurrent sessions never overwrite each other's progress:
#
#   s3://$CACHE_BUCKET/build-cache/$PROJECT/latest.log
#
#   2026-10-22T16:40:01Z START session_01AbC key 3f51aebaf36323a0 log build-cache/aurora_uix/logs/...
#   2026-10-22T17:12:44Z END   session_01AbC exit 0 after 1963s: build part stored, plt part stored
#
# The key hashes everything that makes a build machine-specific: mix.lock, .tool-versions,
# the OS release, the CPU architecture and the C library version. A cache for another
# machine type is never used. After unpacking, `mix compile` must succeed; otherwise the
# unpacked files are deleted and the caller builds from scratch.
#
# This script never fails a session start because of the cache: every cache problem prints a
# line and falls through to a normal build.

set -uo pipefail

cd "$(dirname "$0")/.."

PARTS=(build plt)

MIX_ENVS="${BUILD_CACHE_MIX_ENVS:-dev test}"
PLT_ENV="${BUILD_CACHE_PLT_ENV:-dev}"
# Mix commands without an explicit environment (deps.get, the Hex and rebar installs).
export MIX_ENV="${PLT_ENV}"
# test/config/test.exs starts a per-checkout PostgreSQL (scripts/test_pg.sh) whenever the
# test config loads. Compiling and building the PLT never touch the database, so use the shared
# connection settings and start nothing.
export AURORA_UIX_TEST_PG="${AURORA_UIX_TEST_PG:-shared}"
export LANG="${LANG:-C.UTF-8}" LC_ALL="${LC_ALL:-C.UTF-8}"
export ELIXIR_ERL_OPTIONS="${ELIXIR_ERL_OPTIONS:-+fnu}"

# A non-interactive shell does not source the asdf profile.
if ! command -v mix >/dev/null 2>&1 && [ -f "$HOME/.asdf/asdf.sh" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.asdf/asdf.sh"
fi

STARTED_AT=$(date +%s)
LOG_FILE="$(mktemp)"
SESSION_TAG="$(printf '%s' "${BUILD_CACHE_SESSION:-}" | tr -cd 'A-Za-z0-9_-')"
[ -n "$SESSION_TAG" ] || SESSION_TAG="$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')"
LOG_NAME="$(date -u +%Y%m%dT%H%M%SZ)-${SESSION_TAG}"
LOG_OBJECT_ENABLED=0
HEARTBEAT_PID=""

log() {
  printf 'build_cache: [%s +%ss] %s\n' "$(date -u +%H:%M:%S)" "$(( $(date +%s) - STARTED_AT ))" "$*" |
    tee -a "$LOG_FILE"
  push_log
}

# Prefixes each line of a command's output with the UTC time.
stamp() {
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    printf '%s %s\n' "$(date -u +%H:%M:%S)" "$line"
  done
}

# Runs a command, showing its output and appending it, time-stamped, to the log file; keeps
# the command's exit status (pipefail).
logged() { "$@" 2>&1 | stamp | tee -a "$LOG_FILE"; }

# What happened to each cache part, for the END line of the shared index.
declare -A PART_STATUS=([build]="not cached" [plt]="not cached")

index_object() { printf 'build-cache/%s/latest.log' "$PROJECT"; }

# Appends one line to the shared index (read, append, write; the last 500 lines are kept).
append_index() {
  [ "$LOG_OBJECT_ENABLED" -eq 1 ] || return 0
  local index
  index="$(mktemp)"
  store_get "$(index_object)" "$index" >/dev/null 2>&1 || : >"$index"
  printf '%s\n' "$1" >>"$index"
  tail -n 500 "$index" >"$index.tail" && mv "$index.tail" "$index"
  store_put "$index" "$(index_object)" >/dev/null 2>&1 || true
  rm -f "$index"
}

log_object() { printf 'build-cache/%s/logs/%s.log' "$PROJECT" "$LOG_NAME"; }

push_log() {
  [ "$LOG_OBJECT_ENABLED" -eq 1 ] || return 0
  store_put "$LOG_FILE" "$(log_object)" >/dev/null 2>&1 || true
}

start_heartbeat() {
  [ "$LOG_OBJECT_ENABLED" -eq 1 ] || return 0
  (
    while sleep "${BUILD_CACHE_LOG_INTERVAL:-30}"; do
      store_put "$LOG_FILE" "$(log_object)" >/dev/null 2>&1 || true
    done
  ) &
  HEARTBEAT_PID=$!
}

finish() {
  local status=$?
  [ -n "$HEARTBEAT_PID" ] && kill "$HEARTBEAT_PID" 2>/dev/null
  push_log
  append_index "$(date -u +%FT%TZ) END   $SESSION_TAG exit $status after $(( $(date +%s) - STARTED_AT ))s: build part ${PART_STATUS[build]}, plt part ${PART_STATUS[plt]}"
  rm -f "$LOG_FILE"
}
trap finish EXIT

cache_key() {
  {
    cat mix.lock .tool-versions
    # shellcheck disable=SC1091
    . /etc/os-release && echo "$ID $VERSION_ID"
    uname -m
    ldd --version 2>&1 | head -1
    echo "envs: $MIX_ENVS plt: $PLT_ENV"
  } | sha256sum | cut -c1-16
}

store_configured() {
  [ -n "${PROJECT:-}" ] && { [ -n "${BUILD_CACHE_LOCAL_DIR:-}" ] || [ -n "${CACHE_BUCKET:-}" ]; }
}

# Paths packed into each part.
part_paths() {
  case "$1" in
    build) printf 'deps'; for env in $MIX_ENVS; do printf ' _build/%s' "$env"; done; echo ;;
    plt) echo "priv/plts" ;;
  esac
}

object_name() { printf 'build-cache/%s/%s-%s.tar.zst' "$PROJECT" "$(cache_key)" "$1"; }

store_has() {
  if [ -n "${BUILD_CACHE_LOCAL_DIR:-}" ]; then
    [ -f "$BUILD_CACHE_LOCAL_DIR/$1" ]
  else
    aws s3api head-object --bucket "$CACHE_BUCKET" --key "$1" >/dev/null 2>&1
  fi
}

store_get() {
  if [ -n "${BUILD_CACHE_LOCAL_DIR:-}" ]; then
    cp "$BUILD_CACHE_LOCAL_DIR/$1" "$2"
  else
    aws s3 cp --only-show-errors "s3://$CACHE_BUCKET/$1" "$2"
  fi
}

store_put() {
  if [ -n "${BUILD_CACHE_LOCAL_DIR:-}" ]; then
    mkdir -p "$(dirname "$BUILD_CACHE_LOCAL_DIR/$2")" && cp "$1" "$BUILD_CACHE_LOCAL_DIR/$2"
  else
    aws s3 cp --only-show-errors "$1" "s3://$CACHE_BUCKET/$2"
  fi
}

# Writes the progress log object, so a missing tool, host, key or permission shows up in
# the first seconds of a session instead of after the build. Sets STORE_USABLE when the tools
# are present, and STORE_WRITABLE when the probe write succeeds.
STORE_USABLE=0
STORE_WRITABLE=0
check() {
  if ! store_configured; then
    log "no store configured (PROJECT and CACHE_BUCKET), the cache is not used"
    return 0
  fi

  if [ -z "${BUILD_CACHE_LOCAL_DIR:-}" ]; then
    if ! command -v aws >/dev/null 2>&1; then
      log "STORE UNUSABLE: the aws command is not installed, the cache will not be read or saved"
      return 0
    fi
    if ! command -v zstd >/dev/null 2>&1; then
      log "STORE UNUSABLE: zstd is not installed, the cache will not be read or saved"
      return 0
    fi
  fi

  STORE_USABLE=1
  local error
  printf 'build_cache: session start on %s, key %s, project %s\n' "$(hostname)" "$(cache_key)" "$PROJECT" >>"$LOG_FILE"
  if error=$(store_put "$LOG_FILE" "$(log_object)" 2>&1); then
    STORE_WRITABLE=1
    log "store reachable and writable; progress log at $(log_object)"
  else
    log "STORE UNUSABLE: could not write $(log_object), the cache will not be saved: ${error:-no message}"
  fi
  return 0
}

restore_part() {
  local part="$1" object archive
  object="$(object_name "$part")"

  if ! store_has "$object"; then
    log "no cached $part part for this machine and lockfile"
    return 1
  fi

  archive="$(mktemp)"
  log "downloading the $part part"
  if store_get "$object" "$archive" && tar --zstd -xf "$archive"; then
    PART_STATUS[$part]="restored"
    rm -f "$archive"
    return 0
  fi

  log "could not download or unpack the $part part, discarding it"
  rm -f "$archive"
  # shellcheck disable=SC2046
  rm -rf $(part_paths "$part")
  return 1
}

restore() {
  if ! store_configured || [ "$STORE_USABLE" -ne 1 ]; then
    return 0
  fi

  local restored=0 part
  for part in "${PARTS[@]}"; do
    restore_part "$part" && restored=1
  done

  if [ "$restored" -eq 1 ]; then
    if compile_all_envs >/dev/null 2>&1; then
      log "cache restored and verified"
    else
      log "restored cache does not compile on this machine, discarding it"
      rm -rf deps _build priv/plts
      PART_STATUS=([build]="discarded" [plt]="discarded")
    fi
  fi
  return 0
}

compile_all_envs() {
  local env
  for env in $MIX_ENVS; do
    MIX_ENV="$env" mix compile || return 1
  done
}

build_deps() {
  logged mix local.hex --force --if-missing && logged mix local.rebar --force --if-missing &&
    logged mix deps.get || return 1
  local env
  for env in $MIX_ENVS; do
    log "compiling the $env environment"
    MIX_ENV="$env" logged mix deps.compile && MIX_ENV="$env" logged mix compile || return 1
  done
}

build_plt() { MIX_ENV="$PLT_ENV" logged mix dialyzer --plt; }

build() { build_deps && build_plt; }

save_part() {
  local part="$1" object archive present_paths path
  store_configured || return 0
  [ "$STORE_WRITABLE" -eq 1 ] || { log "not saving the $part part: the store is not writable"; PART_STATUS[$part]="not saved"; return 0; }

  object="$(object_name "$part")"
  if store_has "$object"; then
    log "the $part part is already stored"
    [ "${PART_STATUS[$part]}" = "restored" ] || PART_STATUS[$part]="already stored"
    return 0
  fi

  present_paths=()
  for path in $(part_paths "$part"); do
    [ -e "$path" ] && present_paths+=("$path")
  done
  [ "${#present_paths[@]}" -gt 0 ] || { log "nothing to save for the $part part"; return 0; }

  archive="$(mktemp)"
  log "packing the $part part (${present_paths[*]})"
  if tar --zstd -cf "$archive" "${present_paths[@]}" && store_put "$archive" "$object"; then
    log "stored $object"
    PART_STATUS[$part]="stored"
  else
    log "could not store the $part part"
    PART_STATUS[$part]="upload failed"
  fi
  rm -f "$archive"
  return 0
}

save() {
  local part
  for part in "${PARTS[@]}"; do
    save_part "$part"
  done
}

case "${1:-}" in
  key) cache_key ;;
  check) check ;;
  restore)
    check
    restore
    ;;
  build) build ;;
  save)
    check
    save
    ;;
  ensure)
    check
    if [ "$STORE_WRITABLE" -eq 1 ]; then
      LOG_OBJECT_ENABLED=1
      append_index "$(date -u +%FT%TZ) START $SESSION_TAG key $(cache_key) log $(log_object)"
      start_heartbeat
    fi
    restore
    log "compiling dependencies"
    build_deps || { log "dependency build failed"; exit 1; }
    save_part build
    log "building the dialyzer PLT (about 18 minutes when there is no cached PLT)"
    build_plt || { log "PLT build failed"; exit 1; }
    save_part plt
    log "done"
    ;;
  *)
    sed -n '3,12p' "$0"
    exit 2
    ;;
esac
