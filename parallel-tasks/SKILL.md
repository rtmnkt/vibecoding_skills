---
name: parallel-tasks
description: Parallel task execution and coordination using Task Management + async-shell. Use when you need to execute multiple independent tasks concurrently with separate Claude instances, coordinate multi-step workflows across sessions, or delegate parallel execution to a coordinator to minimize token consumption in the main conversation.
---

# Parallel Task Coordination

Efficiently execute multiple tasks in parallel using Task Management + async-shell. Delegate coordination to minimize main Claude's token consumption.

## Dependencies

- **async-shell skill**: Required for tmux session management
- **Task Management**: Built-in Claude Code feature

## Environment Variables

```bash
# Claude Code command (default: claude)
export CLAUDE_CODE="claude"

# Shared task list ID for cross-session coordination
export CLAUDE_CODE_TASK_LIST_ID="my-project"
```

## Core Pattern: Coordinator Delegation (Recommended)

Delegate everything to a coordinator. Main Claude only receives final results. **95% token reduction.**

```bash
# Main Claude
export CLAUDE_CODE="claude"

${CLAUDE_CODE} -p "You are coordinator. Execute:
1. Create 5 tasks (CLAUDE_CODE_TASK_LIST_ID=my-project)
2. Launch 5 bash sessions via async-shell (@2-@6)
3. Start ${CLAUDE_CODE} in each session, assign tasks
4. Loop: check TaskList until all 5 completed
5. Aggregate results and respond"

# Blocks until complete
# Internal parallel execution invisible
# Receives final result only
```

**Coordinator's internal process** (invisible to main Claude):

```
Coordinator
  ├─ TaskCreate task1, task2, task3, task4, task5
  ├─ SCRIPT="/mnt/skills/user/async-shell/scripts/async_shell.sh"
  ├─ chmod +x $SCRIPT  # Make executable
  ├─ $SCRIPT new bash → @2, @3, @4, @5, @6
  ├─ Setup each session:
  │   $SCRIPT type @N "export CLAUDE_CODE_TASK_LIST_ID=my-project"
  │   $SCRIPT type @N "${CLAUDE_CODE}"
  │
  ├─ @2 worker: execute task1 → TaskUpdate task1 --status completed
  ├─ @3 worker: execute task2 → TaskUpdate task2 --status completed
  ├─ @4 worker: execute task3 → TaskUpdate task3 --status completed
  ├─ @5 worker: execute task4 → TaskUpdate task4 --status completed
  └─ @6 worker: execute task5 → TaskUpdate task5 --status completed
  
  while true; do
    count=$(TaskList | grep completed | wc -l)
    if [[ $count -eq 5 ]]; then
      aggregate results
      respond
      break
    fi
    sleep 5
  done
```

**Key points:**
- **Workers** (@2-@6): Execute tasks, update `TaskUpdate --status completed`
- **Coordinator**: Check TaskList for completion only (doesn't execute tasks)
- **Main Claude**: Sees only final aggregated results

## async-shell Script Usage

Script path: `/mnt/skills/user/async-shell/scripts/async_shell.sh`

```bash
# First make executable (once per session)
chmod +x /mnt/skills/user/async-shell/scripts/async_shell.sh
```

**Always define `SCRIPT` variable in the same Bash call when using it:**

```bash
SCRIPT="/mnt/skills/user/async-shell/scripts/async_shell.sh"
$SCRIPT new bash
$SCRIPT type @2 "command"
$SCRIPT submit @2
```

## Shared Task List Mechanism

```bash
# Session A
export CLAUDE_CODE_TASK_LIST_ID="project-x"
${CLAUDE_CODE}
# TaskCreate → saved to project-x

# Session B
export CLAUDE_CODE_TASK_LIST_ID="project-x"
${CLAUDE_CODE}
# TaskList → sees Session A's tasks
# TaskUpdate → can update Session A's tasks
```

All sessions with same `CLAUDE_CODE_TASK_LIST_ID` share tasks.

## Worker Setup Pattern

Each worker session needs:

```bash
export CLAUDE_CODE_TASK_LIST_ID="shared-project"
${CLAUDE_CODE}

# Inside worker:
# "Get unclaimed task from TaskList
#  TaskUpdate status to in_progress
#  Execute task
#  TaskUpdate status to completed
#  Record result"
```

## Best Practices

### Use coordinator delegation by default

```bash
# ✅ Recommended
${CLAUDE_CODE} -p "Coordinator: execute 5 tasks in parallel"

# ❌ Avoid (high token cost)
while true; do
  TaskList ...  # Main Claude polling directly
  sleep 5
done
```

### Abstract with environment variables

```bash
# ✅ Flexible
export CLAUDE_CODE="claude"
${CLAUDE_CODE} -p "..."

# ❌ Hardcoded
claude -p "..."
```

### Match task count to session count

```bash
# 5 tasks → 5 sessions (@2-@6)
# 1 session = 1 worker = 1 task
```

## Approval Settings

For scripted mode with `-p` flag, use:

```bash
${CLAUDE_CODE} -p "..." --dangerously-skip-permissions
```

## Troubleshooting

**Tasks not shared**: Different `CLAUDE_CODE_TASK_LIST_ID` in sessions. Use same ID everywhere.

**Worker won't start**: Missing environment variables. Explicitly set in each session:
```bash
$SCRIPT type @2 "export CLAUDE_CODE=claude"
$SCRIPT submit @2
```

**Coordinator doesn't detect completion**: Workers not running `TaskUpdate --status completed`. Add explicit instruction:
```bash
${CLAUDE_CODE} -p "After task completion, MUST run:
TaskUpdate --task-id <id> --status completed"
```

**Script permission denied**: Run `chmod +x` on the async-shell script before use.

## Token Efficiency

| Pattern | Main Claude Tokens | Use Case |
|---------|-------------------|----------|
| Coordinator delegation | ~5% | Production |
| Partial delegation | ~30% | Hybrid control |
| Manual control | 100% | Debugging |

## Examples

### Parallel file processing

```bash
export CLAUDE_CODE="claude"
export CLAUDE_CODE_TASK_LIST_ID="batch-processing"

${CLAUDE_CODE} -p "Coordinator:
Process 5 files in parallel: file1.txt, file2.txt, file3.txt, file4.txt, file5.txt
Create 5 tasks, launch 5 workers, aggregate results"
```

### API endpoint testing

```bash
export CLAUDE_CODE="claude"
export CLAUDE_CODE_TASK_LIST_ID="api-tests"

${CLAUDE_CODE} -p "Test 5 API endpoints in parallel:
/api/users, /api/products, /api/orders, /api/payments, /api/reports
Test GET/POST/PUT/DELETE for each, aggregate results"
```

### Code review

```bash
export CLAUDE_CODE="claude"
export CLAUDE_CODE_TASK_LIST_ID="code-review"

${CLAUDE_CODE} -p "Review 5 PRs in parallel: PR#123-127
Check: code quality, security issues, performance concerns
Aggregate findings into unified report"
```

## Design Rationale

**Separation of concerns:**
- Main Claude: Strategic decisions
- Coordinator: Parallel execution management
- Workers: Individual task execution

**Token efficiency:**
- Main Claude gives minimal instructions
- Internal processing delegated to coordinator

**Scalability:**
- Add more tasks → adjust session count
- Pattern remains unchanged

**Debuggability:**
- Task Management provides centralized state
- Task progress visible via TaskList

## Constraints

**Task completion checking** requires periodic TaskList queries (3-10s interval). This is unavoidable due to tmux/async-shell architecture.

**Solution**: Delegate checking responsibility to coordinator, minimizing impact on main Claude.

## Summary

Combine **Task Management + async-shell + coordinator pattern** for efficient parallel task processing.

**Core principles:**
- Delegate completion checking to coordinator
- Abstract with `CLAUDE_CODE` environment variable
- Share state via `CLAUDE_CODE_TASK_LIST_ID`
- Main Claude focuses on strategy, delegates execution
