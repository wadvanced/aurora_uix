#!/bin/bash
# Prepares a Claude Code cloud session: restores the cached build when a cache store is
# configured (PROJECT and CACHE_BUCKET), then fetches and compiles dependencies and builds
# the dialyzer PLT. Idempotent and incremental; see scripts/build_cache.sh.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# The hook input (JSON on stdin) carries the session id; it names this session's cache log.
if [ ! -t 0 ]; then
  BUILD_CACHE_SESSION="$(jq -r '.session_id // empty' 2>/dev/null || true)"
  export BUILD_CACHE_SESSION
fi

scripts/build_cache.sh ensure
