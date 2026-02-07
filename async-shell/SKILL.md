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

Run `$SCRIPT help` for command reference.

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

## Session Management

The script auto-creates a default session (`async_shell`) on first use. Override with:

```bash
ASYNC_SHELL_SESSION=my_session $SCRIPT list
```

---

## Patterns

### fire_and_forget

goal: run independent task, collect result via file
when: no interaction needed, result can be written to file

```bash
$SCRIPT new "bash -c 'your_command > /tmp/result.txt'"
# check /tmp/result.txt when needed
```

---

### batch_parallel

goal: run multiple independent tasks concurrently
when: several unrelated tasks

```bash
$SCRIPT new "bash -c 'task1 > /tmp/r1.txt'" # → @1
$SCRIPT new "bash -c 'task2 > /tmp/r2.txt'" # → @2
$SCRIPT new "bash -c 'task3 > /tmp/r3.txt'" # → @3
# check result files for completion
$SCRIPT kill @1 && $SCRIPT kill @2 && $SCRIPT kill @3
```

---

### interactive_agent

goal: coordinate with another Claude instance
when: need fresh perspective, objective review, pair programming

```bash
$SCRIPT new "bash"                          # → @N
$SCRIPT type @N "claude" && $SCRIPT submit @N
$SCRIPT capture @N                          # wait for prompt
$SCRIPT type @N "<message>" && $SCRIPT submit @N
$SCRIPT capture @N                          # read response
$SCRIPT kill @N
```

note: provide complete context in message; agent has no access to your conversation

---

### parallel_agents

goal: multiple agents working concurrently
when: need multiple independent perspectives or parallel subtasks

```bash
$SCRIPT new "bash" # → @1
$SCRIPT new "bash" # → @2

$SCRIPT type @1 "claude" && $SCRIPT submit @1
$SCRIPT type @2 "claude" && $SCRIPT submit @2

# send tasks
$SCRIPT type @1 "<task A>" && $SCRIPT submit @1
$SCRIPT type @2 "<task B>" && $SCRIPT submit @2

# collect results
$SCRIPT capture @1
$SCRIPT capture @2

$SCRIPT kill @1 && $SCRIPT kill @2
```

---

## Basic Operations

```bash
$SCRIPT new "bash"              # create shell → @N
$SCRIPT list                    # list shells
$SCRIPT type @N "<text>"        # type text (no Enter)
$SCRIPT submit @N               # send Enter
$SCRIPT capture @N              # get visible output
$SCRIPT capture @N -h 100       # get last 100 lines from scroll buffer (bottom-relative)
$SCRIPT kill @N                 # close shell
$SCRIPT current                 # get current shell ID
```

**Chained operations:**
```bash
$SCRIPT type @N "command" && $SCRIPT submit @N
```

---


## Notes

- **Environment variables**: Use `new "bash"` then set env vars, or `new "bash -c 'VAR=val command'"`
- **Completion detection**: Use result files (recommended) or poll with `capture`
- **capture**: Returns output from bottom of scroll buffer. `-h N` gets last N lines (bottom-relative)
- **submit**: Sends Enter only, no capture

---

## Implementation

Script: `scripts/async_shell.sh`
Claude CLI patterns: `references/cli--claude.md`
