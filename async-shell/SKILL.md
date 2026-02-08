---
name: async-shell
description: Coordinate with interactive async agents in separate contexts. Run another Claude in separate pane for second opinion, objective review, pair programming, or parallel tasks. Also for background process management.
---

# Async Shell

Manage background shells for parallel task execution and async agent coordination.

```bash
chmod +x scripts/async_shell.sh
SCRIPT="scripts/async_shell.sh"
```

Run `$SCRIPT help` for command reference.

---

## Scope

**This skill provides:**
- Background shell creation and termination
- Text input and key sending
- Screen output capture (full view and differential)

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

goal: run independent task, check result when needed
when: no interaction needed

```bash
$SCRIPT new "your_command"              # → @N
$SCRIPT capture @N                      # check output when needed
$SCRIPT kill @N
```

---

### batch_parallel

goal: run multiple independent tasks concurrently
when: several unrelated tasks

```bash
$SCRIPT new "task1" # → @1
$SCRIPT new "task2" # → @2
$SCRIPT new "task3" # → @3
# poll for completion
$SCRIPT capture-diff @1
$SCRIPT capture-diff @2
$SCRIPT capture-diff @3
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

## Screen Operations

### capture - View current screen

View the current screen state. For one-shot checks and interactive sessions.

```bash
$SCRIPT capture @N              # visible screen with line numbers
$SCRIPT capture @N -h 100       # last 100 lines with line numbers
```

### capture-diff - Monitor for changes

Detect and show changes since last `capture-diff` call. For polling loops.
Uses unified diff format (`-`/`+` prefixes). Returns `(no change)` when nothing happened.

```bash
$SCRIPT capture-diff @N         # diff since last check
```

**Output patterns:**
- `(initial)` + full content: first call, baseline established
- `(no change)`: no activity since last check
- `(output detected, screen unchanged)`: activity detected but screen returned to same state
- Unified diff: content changed (` ` = context, `-` = removed, `+` = added)

**When to use which:**
- `capture`: view current state, interactive sessions, reading responses
- `capture-diff`: polling for completion, monitoring background tasks

---

## Basic Operations

```bash
$SCRIPT new "bash"              # create shell → @N
$SCRIPT list                    # list shells
$SCRIPT type @N "<text>"        # type text (no Enter)
$SCRIPT type @N "<text>" -s     # type text and submit (auto-Enter)
$SCRIPT submit @N               # send Enter
$SCRIPT capture @N              # view current screen
$SCRIPT capture @N -h 100       # last 100 lines
$SCRIPT capture-diff @N         # diff since last check
$SCRIPT kill @N                 # close shell
$SCRIPT current                 # get current shell ID
```

**Chained operations:**
```bash
# Type then capture output
$SCRIPT type @N "ls -la" -s && $SCRIPT capture @N

# Type with menu selection
$SCRIPT type @N "1" && $SCRIPT capture @N
```

**Important:** Use `-s` flag only for commands that require Enter. For single-character menu inputs (e.g., `1`, `2`, `q`, `y`), omit `-s` as these accept input immediately.

---


## Notes

- **When to use bash**:
  - Use `new "bash"` for interactive sessions (multiple commands, `cd`, `export`, loops, pipes)
  - Use `new "command"` for single commands (e.g., `npm test`, `make build`)
  - Use `new "VAR=val command"` for environment variables (e.g., `ENV=prod npm start`)
- **Completion detection**: Poll with `capture-diff` (recommended) or check with `capture`
- **capture**: Returns visible screen with line numbers. `-h N` gets last N lines
- **capture-diff**: Returns unified diff since last check. Detects all activity via timestamps; `(no change)` is reliable
- **submit**: Sends Enter only, no capture

---

## Implementation

Script: `scripts/async_shell.sh`
Claude CLI patterns: `references/cli--claude.md`
