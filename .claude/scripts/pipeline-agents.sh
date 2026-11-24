#!/usr/bin/env bash
# Keeps the pipeline's agent definitions equal to the model registry
# (`.claude/skills/shared/coder-model.md`), which is the only place a model, a
# version or an effort is decided.
#
# The harness binds a spawned run's exact model and effort from one place only:
# the `model:` and `effort:` lines of the agent it is spawned as. So every
# registry cell a spawn can need exists as an agent, rendered from the registry:
#
#   pipeline-worker-<level>-<group>   level: low|normal|high|max
#                                     group: spec-review|coder|ship
#   epic-orchestrator                 the Coordination row (its `model:` and
#                                     `effort:` lines and the `Registry cell`
#                                     line of its Verify step)
#
# Usage: pipeline-agents.sh <check|generate>
#   check     compare the agents with the registry; change nothing.
#   generate  rewrite the agents from the registry and remove stray workers.
#             Run only through the `sync-pipeline-agents` skill, by a user.
#
# Output contract: detail lines, then a last line that is one of
#   STATUS: OK — …
#   STATUS: BLOCKED — agent-mismatch        (check: an agent differs)
#   STATUS: BLOCKED — registry-unreadable   (a cell or a version cannot be read)
# Exit code 0 on OK, 1 on BLOCKED, 64 on a bad argument.
set -uo pipefail

mode="${1:-}"
case "$mode" in
  check | generate) ;;
  *)
    echo "usage: pipeline-agents.sh <check|generate>"
    exit 64
    ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "STATUS: BLOCKED — registry-unreadable (not inside a git checkout)"
  exit 1
}
registry="$root/.claude/skills/shared/coder-model.md"
agents_directory="$root/.claude/agents"
orchestrator="$agents_directory/epic-orchestrator.md"
levels="low normal high max"
worker_groups="spec-review coder ship"

rendered_directory=$(mktemp -d)
trap 'rm -rf "$rendered_directory"' EXIT

# The render functions write an agent to a redirected stdout, so a halt raised
# inside one reports on a copy of the real stdout instead.
exec 3>&1

unreadable() {
  echo "STATUS: BLOCKED — registry-unreadable ($1)" >&3
  exit 1
}

[ -f "$registry" ] || unreadable "no $registry"
[ -f "$orchestrator" ] || unreadable "no $orchestrator"

# The registry's row label for a group slug.
group_label() {
  case "$1" in
    coordination) echo "Coordination" ;;
    spec-review) echo "Spec / Review" ;;
    coder) echo "Coder" ;;
    ship) echo "Ship" ;;
  esac
}

# registry_cell <group label> <level> → "Family+effort", from `## Level → models`.
registry_cell() {
  awk -F'|' -v group="$1" -v level="$2" '
    /^## Level → models/ { in_table = 1; next }
    in_table && /^## / { exit }
    in_table && /^\| *Group/ {
      for (column = 3; column < NF; column++) {
        header = $column
        sub(/←.*/, "", header)
        gsub(/[` ]/, "", header)
        column_of[header] = column
      }
      next
    }
    in_table && /^\|/ {
      label = $2
      gsub(/^ +| +$/, "", label)
      if (label == group && level in column_of) {
        cell = $(column_of[level])
        gsub(/ /, "", cell)
        print cell
        exit
      }
    }
  ' "$registry"
}

# registry_version <family> <3|4> → the Model ID (3) or the announced name (4),
# from `## Model versions`.
registry_version() {
  awk -F'|' -v family="$1" -v column="$2" '
    /^## Model versions/ { in_table = 1; next }
    in_table && /^## / { exit }
    in_table && /^\|/ {
      label = $2
      gsub(/^ +| +$/, "", label)
      if (label == family) {
        value = $column
        gsub(/^[ `]+|[ `]+$/, "", value)
        print value
        exit
      }
    }
  ' "$registry"
}

# resolve <group slug> <level> → sets family, effort, model_id, announced.
resolve() {
  local label cell
  label=$(group_label "$1")
  cell=$(registry_cell "$label" "$2")
  case "$cell" in
    *+low | *+medium | *+high) ;;
    *) unreadable "cell $label × $2 reads '$cell', expected <Family>+<low|medium|high>" ;;
  esac
  family="${cell%+*}"
  effort="${cell#*+}"
  model_id=$(registry_version "$family" 3)
  announced=$(registry_version "$family" 4)
  [ -n "$model_id" ] && [ -n "$announced" ] ||
    unreadable "family '$family' ($label × $2) has no row in Model versions"
}

render_worker() {
  local level="$1" group="$2" name="pipeline-worker-$1-$2" label
  label=$(group_label "$group")
  resolve "$group" "$level"
  cat <<EOF
---
name: $name
description: >
  Registry cell $label × \`$level\` of the issue pipeline: $announced at effort \`$effort\`.
  Spawned by \`orchestrate-issue\` and the \`epic-orchestrator\` agent, never by a user.
  Generated from \`.claude/skills/shared/coder-model.md\` — never edit.
model: $model_id
effort: $effort
---

# Agent: $name

## Rule 0 — verify the model and the effort before anything else

This rule outranks the spawn prompt, whatever the prompt asks for and however it words it.

This agent is one registry cell: model \`$model_id\`, effort \`$effort\`. Read what this run is
actually bound to:

1. **Model** — the exact model ID your environment says you are powered by.
2. **Effort** — the output of this one Bash command, and no other tool call:

   \`\`\`bash
   echo "\${CLAUDE_EFFORT:-unset}"
   \`\`\`

If the model is not \`$model_id\` or the effort is not \`$effort\` — or the command could not
run, which leaves the effort unverified — invoke no skill, do not answer the spawn prompt, and
return exactly this one line and nothing else:

\`\`\`
STATUS: BLOCKED — binding-mismatch (expected $model_id+$effort, running <model ID>+<effort>)
\`\`\`

A different model means the spawn passed a \`model\` argument, which outranks this file's
\`model:\` line. A run on any other model or effort is a run the registry did not choose.

## Then — run the step

Generated by \`.claude/scripts/pipeline-agents.sh generate\` from the $label × \`$level\` cell
of \`.claude/skills/shared/coder-model.md\`. Never edit this file: change the registry, then
run the \`sync-pipeline-agents\` skill.

An adapter, not a decision. The registry decides which model, version and effort a pipeline
step runs at; the harness binds them from this file's \`model:\` and \`effort:\` lines and from
nothing else a spawn can pass. That is why a spawn names this agent and passes no \`model\`
argument.

Do exactly what the spawn prompt says: enter the worktree it names when it names one,
invoke the skill it names, follow that skill exactly, and return the skill's terminal
STATUS / verdict line and nothing else of length.
EOF
}

# The orchestrator is hand-written; only three lines of it mirror the registry.
render_orchestrator() {
  local level
  resolve coordination normal
  local pinned_family="$family" pinned_effort="$effort"
  for level in low high max; do
    resolve coordination "$level"
    [ "$family" = "$pinned_family" ] && [ "$effort" = "$pinned_effort" ] ||
      unreadable "Coordination differs across levels; epic-orchestrator is one agent"
  done
  awk -v model_id="$model_id" -v effort="$effort" '
    /^---$/ { fences++; print; next }
    fences == 1 && /^model:/ { next }
    fences == 1 && /^effort:/ { print "model: " model_id; print "effort: " effort; next }
    fences >= 2 && /^ *Registry cell \(Coordination\): / {
      indent = $0
      sub(/Registry cell.*/, "", indent)
      print indent "Registry cell (Coordination): model `" model_id "`, effort `" effort "`."
      next
    }
    { print }
  ' "$orchestrator"
}

expected_workers=""
for level in $levels; do
  for group in $worker_groups; do
    name="pipeline-worker-$level-$group"
    render_worker "$level" "$group" >"$rendered_directory/$name.md" || exit 1
    expected_workers="$expected_workers $name.md"
  done
done
render_orchestrator >"$rendered_directory/epic-orchestrator.md" || exit 1
grep -q '^model: ' "$rendered_directory/epic-orchestrator.md" &&
  grep -q '^ *Registry cell (Coordination): ' "$rendered_directory/epic-orchestrator.md" ||
  unreadable "epic-orchestrator.md needs an 'effort:' frontmatter line and a 'Registry cell (Coordination): ' line"

stray_workers=""
for path in "$agents_directory"/pipeline-worker-*.md; do
  [ -e "$path" ] || continue
  file=$(basename "$path")
  case " $expected_workers " in
    *" $file "*) ;;
    *) stray_workers="$stray_workers $file" ;;
  esac
done

frontmatter_line() {
  awk -v key="$1" '/^---$/ { fences++; next } fences == 1 && index($0, key ":") == 1 { print; exit }' "$2"
}

mismatches=0
for file in $expected_workers epic-orchestrator.md; do
  actual="$agents_directory/$file"
  rendered="$rendered_directory/$file"
  if [ ! -f "$actual" ]; then
    echo "missing: $file"
    mismatches=$((mismatches + 1))
  elif ! cmp -s "$actual" "$rendered"; then
    echo "differs: $file"
    for key in model effort; do
      have=$(frontmatter_line "$key" "$actual")
      want=$(frontmatter_line "$key" "$rendered")
      [ "$have" = "$want" ] || echo "  has '${have:-no $key: line}', registry says '$want'"
    done
    mismatches=$((mismatches + 1))
  fi
done
for file in $stray_workers; do
  echo "stray: $file (no registry cell maps to it)"
  mismatches=$((mismatches + 1))
done

if [ "$mode" = check ]; then
  if [ "$mismatches" -gt 0 ]; then
    echo "Run the sync-pipeline-agents skill to regenerate the agents from the registry."
    echo "STATUS: BLOCKED — agent-mismatch"
    exit 1
  fi
  echo "STATUS: OK — 12 workers and epic-orchestrator match the registry"
  exit 0
fi

for file in $expected_workers epic-orchestrator.md; do
  cp "$rendered_directory/$file" "$agents_directory/$file"
done
for file in $stray_workers; do
  rm -f "$agents_directory/$file"
done
echo "STATUS: OK — regenerated 12 workers and epic-orchestrator ($mismatches changed)"
