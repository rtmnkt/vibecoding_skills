---
name: async-shell
description: Coordinate with interactive async agents in separate contexts. Run another Claude in separate pane for second opinion, objective review, pair programming, or parallel tasks. Also for background process management.
---

# Async Shell

Manage background shells for parallel task execution and async agent coordination.

```bash
SCRIPT="/mnt/skills/user/async-shell/scripts/async_shell.sh"
chmod +x "$SCRIPT"
```

Run `bash $SCRIPT help` for command reference.

---

## Scope

**This skill provides:**
- Background shell creation and termination
- Text input and key sending
- Screen output capture

**Out of scope (caller's responsibility):**
- Task completion detection and waiting
- Result interpretation
- Polling strategies

---

## Patterns

### fire_and_forget

goal: run independent task, collect result via file
when: no interaction needed, result can be written to file

```bash
bash $SCRIPT new "bash -c 'your_command > /tmp/result.txt'"
# check /tmp/result.txt when needed
```

---

### batch_parallel

goal: run multiple independent tasks concurrently
when: several unrelated tasks

```bash
bash $SCRIPT new "bash -c 'task1 > /tmp/r1.txt'" # → @1
bash $SCRIPT new "bash -c 'task2 > /tmp/r2.txt'" # → @2
bash $SCRIPT new "bash -c 'task3 > /tmp/r3.txt'" # → @3
# check result files for completion
bash $SCRIPT kill @1 && bash $SCRIPT kill @2 && bash $SCRIPT kill @3
```

---

### interactive_agent

goal: coordinate with another Claude instance
when: need fresh perspective, objective review, pair programming

```bash
bash $SCRIPT new "bash"                          # → @N
bash $SCRIPT type @N "claude" && bash $SCRIPT submit @N
bash $SCRIPT capture @N                          # wait for prompt
bash $SCRIPT type @N "<message>" && bash $SCRIPT submit @N
bash $SCRIPT capture @N                          # read response
bash $SCRIPT kill @N
```

note: provide complete context in message; agent has no access to your conversation

---

### parallel_agents

goal: multiple agents working concurrently
when: need multiple independent perspectives or parallel subtasks

```bash
bash $SCRIPT new "bash" # → @1
bash $SCRIPT new "bash" # → @2

bash $SCRIPT type @1 "claude" && bash $SCRIPT submit @1
bash $SCRIPT type @2 "claude" && bash $SCRIPT submit @2

# send tasks
bash $SCRIPT type @1 "<task A>" && bash $SCRIPT submit @1
bash $SCRIPT type @2 "<task B>" && bash $SCRIPT submit @2

# collect results
bash $SCRIPT capture @1
bash $SCRIPT capture @2

bash $SCRIPT kill @1 && bash $SCRIPT kill @2
```

---

## Basic Operations

```bash
bash $SCRIPT new "bash"              # create shell → @N
bash $SCRIPT list                    # list shells
bash $SCRIPT type @N "<text>"        # type text (no Enter)
bash $SCRIPT submit @N               # send Enter
bash $SCRIPT capture @N              # get visible output
bash $SCRIPT capture @N -h 100       # include scroll buffer
bash $SCRIPT kill @N                 # close shell
bash $SCRIPT current                 # get current shell ID
```

**Chained operations:**
```bash
bash $SCRIPT type @N "command" && bash $SCRIPT submit @N
```

---

## Pane Operations (util)

For side-by-side display within a single window:

```bash
bash $SCRIPT util split v "bash"     # vertical split → %N
bash $SCRIPT util split h "bash"     # horizontal split → %N
bash $SCRIPT util panes              # list panes
bash $SCRIPT util focus %N           # switch focus
```

Use window operations (`new`, `kill`) for background tasks.
Use pane operations only when visual side-by-side is needed.

---

## Notes

- **Environment variables**: Use `new "bash"` then set env vars, or `new "bash -c 'VAR=val command'"`
- **Completion detection**: Use result files (recommended) or poll with `capture`
- **capture**: Returns current screen snapshot, no waiting
- **submit**: Sends Enter only, no capture

---

## Implementation

Script: `scripts/async_shell.sh`
Claude CLI patterns: `references/cli--claude.md`
