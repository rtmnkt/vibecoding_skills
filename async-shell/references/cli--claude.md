# Claude CLI Reference

Operation patterns for Claude Code CLI.

---

## send_message

precondition: prompt visible (>, ❯, etc.)
steps:
  1. type @N "<message>"
  2. submit @N
  3. capture @N → expect response or processing indicator

---

## change_model

precondition: prompt visible
steps:
  1. type @N "/model"
  2. submit @N
  3. capture @N → expect selection list
  4. key @N <number>
  5. capture @N → confirm

---

## approve_tool

precondition: approval prompt visible ([y/n], "Allow?", etc.)
action: key @N y | n | a | d
  - y: allow once
  - n: deny once
  - a: always allow
  - d: always deny

---

## cancel_operation

precondition: processing indicator visible
action: key @N Escape

---

## interrupt

precondition: any
action: key @N C-c

---

## exit_cli

precondition: prompt visible
steps:
  1. type @N "/quit"
  2. submit @N
fallback: if processing → key @N Escape, retry

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

Note: Commands may vary by CLI version.

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
