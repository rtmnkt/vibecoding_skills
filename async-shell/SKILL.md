---
name: async-shell
description: Coordinate with interactive async agents in separate contexts. Run another Claude in separate pane for second opinion, objective review, pair programming, or parallel tasks. Also for background process management.
---

# Async Shell

Coordinate with interactive async agents in separate contexts.

```bash
SCRIPT="/mnt/skills/user/async-shell/scripts/async_shell.sh"
bash $SCRIPT help
```

**Note**: Use `bash $SCRIPT` to avoid permission issues on read-only mounts.

Run `bash $SCRIPT help` for command reference.

---

## Session Management

The script auto-creates a default session (`async_shell`) on first use. Override with:

```bash
ASYNC_SHELL_SESSION=my_session bash $SCRIPT list
```

---

## Async Agent Patterns

### objective_review

goal: get fresh perspective, avoid context bias from current conversation
when: need validation, self-doubt on approach, user requests objective view

```
1. bash $SCRIPT list → check existing
2. bash $SCRIPT new "claude" → @N
3. bash $SCRIPT capture @N -w 3 → wait for prompt
4. bash $SCRIPT type @N "<clear problem statement + specific question>"
5. bash $SCRIPT submit @N
6. bash $SCRIPT capture @N -w 5 → read response
7. bash $SCRIPT kill @N (or keep for follow-up)
```

note: provide complete context in message; agent has no access to your conversation

---

### delegate_task

goal: offload isolated task, preserve main context tokens
when: simple task, no conversation history needed, well-defined input/output

```
1. bash $SCRIPT new "claude -p '<task description>'" → runs and exits
   or
   bash $SCRIPT new "claude" → @N for interactive task
2. bash $SCRIPT capture @N -w 5 → get result
3. bash $SCRIPT kill @N (if interactive)
```

examples:
- format conversion
- simple code generation
- summarization of provided text

---

### parallel_execution

goal: concurrent independent tasks
when: multiple unrelated tasks, time-sensitive

```
1. bash $SCRIPT new "claude -p '<task 1>'" → @1
2. bash $SCRIPT new "claude -p '<task 2>'" → @2
3. bash $SCRIPT new "claude -p '<task 3>'" → @3
4. poll each with capture -w
5. capture each → collect results
6. kill all
```

note: each task must be self-contained

---

### interactive_dialogue

goal: pair programming, iterative refinement, extended collaboration
when: complex problem, need back-and-forth, exploratory discussion

```
1. bash $SCRIPT new "claude" → @N
2. bash $SCRIPT capture @N -w 3 → confirm ready
3. loop:
   - bash $SCRIPT type @N "<message>"
   - bash $SCRIPT submit @N
   - bash $SCRIPT capture @N -w 5 → read response
   - decide: continue / adjust / end
4. bash $SCRIPT kill @N when done
```

---

## Basic Operations

### run_background_process

```
1. bash $SCRIPT list → check existing
2. bash $SCRIPT new "<command>" → @N
3. bash $SCRIPT capture @N → verify started
```

### check_state

```
bash $SCRIPT capture @N → current visible
bash $SCRIPT capture @N -h 100 → with scroll buffer
bash $SCRIPT capture @N -w 3 → wait before capture
```

### send_input

```
1. bash $SCRIPT capture @N → verify ready
2. bash $SCRIPT type @N "<text>"
3. bash $SCRIPT submit @N
   or
   bash $SCRIPT key @N Enter (no capture after)
```

### cleanup

```
bash $SCRIPT kill @N
bash $SCRIPT list → confirm removed
```

---

## Pane Operations (util)

For simultaneous display within a single window:

```
bash $SCRIPT util split v "command" → %N (vertical split)
bash $SCRIPT util split h "command" → %N (horizontal split)
bash $SCRIPT util panes → list panes
bash $SCRIPT util focus %N → switch focus
```

Use window operations (`new`, `kill`) for most background tasks.
Use pane operations only when visual side-by-side is needed.

---

## Implementation

Script: `scripts/async_shell.sh`
Claude CLI patterns: `references/cli--claude.md`

Run `bash $SCRIPT help` for full command list and options.
