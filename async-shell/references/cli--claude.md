# Claude CLI Reference

Operation patterns for Claude Code CLI.

---

## send_message

precondition: prompt visible (>, ❯, etc.)
steps:
  1. type "<message>"
  2. submit
  3. capture → expect response or processing indicator

---

## change_model

precondition: prompt visible
steps:
  1. type "/model" → submit
  2. capture → expect selection list
  3. key <number> or type selection
  4. capture → confirm

---

## approve_tool

precondition: approval prompt visible ([y/n], "Allow?", etc.)
action: key y | n | a | d
  - y: allow once
  - n: deny once
  - a: always allow
  - d: always deny

---

## cancel_operation

precondition: processing indicator visible
action: key Escape

---

## interrupt

precondition: any
action: key C-c

---

## exit_cli

precondition: prompt visible
steps:
  1. type "/quit" or "/exit" → submit
fallback: if processing → key Escape, retry

---

## screen_states

| pattern | state | input? |
|---------|-------|--------|
| prompt (>, ❯) | idle | yes |
| spinner, "thinking" | processing | no |
| streaming text | generating | no |
| [y/n/a/d], "Allow" | approval | key only |
| numbered list | selection | key only |
| error text | error | yes |

---

## common_commands

| command | purpose |
|---------|---------|
| /help | help |
| /model | change model |
| /clear | clear conversation |
| /quit, /exit | exit |

Note: Commands may vary by CLI implementation.

---

## special_keys

| action | key |
|--------|-----|
| send/confirm | Enter |
| cancel | Escape |
| interrupt | C-c |
| clear screen | C-l |
| history | Up / Down |
| autocomplete | Tab |
