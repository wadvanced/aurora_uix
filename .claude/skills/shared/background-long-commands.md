# Backgrounding gate.sh and the full test suite

Single source of truth for how to run `.claude/scripts/gate.sh` and a **full**
test suite. Referenced from the skills that invoke them; never duplicated into
them.

Both are long: `gate.sh` ends in `dialyzer` (~10 min on a first run), and the
full suite is several hundred DB-backed tests. Neither belongs in the foreground, and neither is
ever polled. There is exactly one way to run them, the same for every agent:

1. **Start it** with Bash's `run_in_background: true`, passing the plain
   command — `.claude/scripts/gate.sh` or `.claude/scripts/suite.sh`. Both
   write their last stdout line, `EXIT: <code>`, into a verdict file as well.
2. **Wait once** with one **foreground** Bash call:
   `.claude/scripts/wait-verdict.sh gate` (or `suite`). It blocks until the
   verdict file ends in `EXIT:` (up to 570 s, under the Bash tool's 600 s
   ceiling) and prints the verdict.
3. **`STILL_RUNNING`** means the timeout passed first. Call `wait-verdict.sh`
   again. Never anything else — no `sleep`, `ps`, `pgrep`, `kill -0` loop or
   `tail` of the log.

This never depends on a completion notification arriving, which is why it works
for a spawned skill as well as for a root session.

This applies to every `gate.sh` invocation and every **full** test suite
(`.claude/scripts/suite.sh`, which takes `mix test` flags but refuses a path).
It does not apply to a targeted run (`mix test <file>`, `mix test --failed`,
`.claude/scripts/section-test.sh`) — those stay in the foreground.

## No shell `&`

The command runs in the **foreground of** the `run_in_background` Bash call.
Never add a trailing shell `&`, `nohup`, or `$!`. A shell-backgrounded command
returns to the shell at once, so the call completes empty and there is nothing
to read but a polling loop.

```bash
# wrong — shell-backgrounded; returns immediately with nothing to read
.claude/scripts/gate.sh &
nohup .claude/scripts/gate.sh > /tmp/gate.log 2>&1 &
```

## Mechanical guard

`.claude/hooks/guard-long-commands.sh` (a `PreToolUse` hook on Bash) rejects
these shapes with a one-line message: a shell-backgrounded gate or suite, a
direct `mix consistency`, a full `mix test` not wrapped by `suite.sh`, and the
poll shapes. A command containing `GATE_DIRECT=1` is always allowed — the
escape hatch for a human-directed session. A rejection is a pointer back to
this note, not something to work around.
