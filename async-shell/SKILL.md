---
name: async-shell
description: Coordinate with interactive async agents in separate contexts. Run another Claude in separate pane for second opinion, objective review, pair programming, or parallel tasks. Also for background process management.
---

# Async Shell

Coordinate with interactive async agents in separate contexts.

**IMPORTANT: Always use the async_shell.sh script. Do NOT use tmux commands directly.**

```bash
SCRIPT="/mnt/skills/user/async-shell/scripts/async_shell.sh"
```

## Async Agent Patterns

### objective_review

goal: get fresh perspective, avoid context bias from current conversation
when: need validation, self-doubt on approach, user requests objective view

```
1. $SCRIPT panes → check existing
2. $SCRIPT split v "claude" → agent_pane
3. $SCRIPT capture agent_pane → wait for prompt
4. $SCRIPT type agent_pane "<clear problem statement + specific question>"
5. $SCRIPT submit agent_pane
6. $SCRIPT capture agent_pane → read response
7. $SCRIPT kill agent_pane (or keep for follow-up)
```

note: provide complete context in message; agent has no access to your conversation

---

### delegate_task

goal: offload isolated task, preserve main context tokens
when: simple task, no conversation history needed, well-defined input/output

```
1. $SCRIPT split v "claude -p '<task description>'" → runs and exits
   or
   $SCRIPT split v "claude" → agent_pane for interactive task
2. $SCRIPT capture → get result
3. $SCRIPT kill (if interactive)
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
1. split v "claude -p '<task 1>'" → pane1
2. split v "claude -p '<task 2>'" → pane2
3. split v "claude -p '<task 3>'" → pane3
4. wait or poll each pane
5. capture each → collect results
6. kill all
```

note: each task must be self-contained

---

### interactive_dialogue

goal: pair programming, iterative refinement, extended collaboration
when: complex problem, need back-and-forth, exploratory discussion

```
1. split v "claude" → agent_pane
2. capture → confirm ready
3. loop:
   - type agent_pane "<message>"
   - submit agent_pane
   - capture agent_pane → read response
   - decide: continue / adjust / end
4. kill agent_pane when done
```

---

## Basic Operations

### run_background_process

```
1. panes → check existing
2. split v "<command>" → pane_id
3. capture → verify started
```

### check_state

```
capture <pane> → current visible
history <pane> [lines] → with scroll buffer
```

### send_input

```
1. capture → verify ready
2. type <pane> "<text>"
3. submit → or key <pane> Enter (no wait)
```

### cleanup

```
kill <pane>
panes → confirm removed
```

---

## Implementation

Script: `scripts/async_shell.sh`  
Backend implementations: `scripts/async_shell--impl-*.sh`

Commands: see `references/commands.md`
Claude CLI: see `references/cli--claude.md`
