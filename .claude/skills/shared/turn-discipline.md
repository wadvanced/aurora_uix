# Turn discipline

Single source of truth for tool-call economy within a skill run. Referenced from
every pipeline skill; never duplicated into them.

- **Batch independent tool calls.** Calls with no data dependency between them go
  in one message, not one call per turn — a preflight's several `gh`/`git` reads,
  a spawn batch's several `Agent` calls, several independent file reads.
- **Never poll.** No `ps` / `sleep` / repeated `echo` loop waiting on a
  background job. Start it with `run_in_background`, then make one foreground
  `wait-verdict.sh` call (`background-long-commands.md` names the two commands
  this applies to).
- **One `Edit` per file per turn.** Two edits to the same file in one turn race
  each other's line numbers; make one, let it land, then the next.
- **Never re-`Read` a file this turn's `Edit`/`Write` just changed.** The tool
  result already confirms the write; a same-turn re-read burns a call to learn
  nothing new.
- **No narration-only turns.** A turn that calls no tool and advances nothing is
  a turn spent on prose alone — say it inside the turn that does the next real
  thing, not a turn of its own.
- **`Read` / `Grep` / `Glob` over shell `cat` / `grep` / `find`.** The dedicated
  tools are cheaper and do not round-trip through a shell.
- **Route a long command to a log, not the transcript.** Redirect its output to
  a file, echo `EXIT: <code>` after it, and read the log only when that code is
  non-zero.
