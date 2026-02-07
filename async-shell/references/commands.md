# async_shell.sh Commands

## Pane Management

| Command | Args | Description |
|---------|------|-------------|
| `info` | - | Current session/window/pane info |
| `panes` | - | List all panes |
| `split` | `[h\|v] [cmd]` | Split, returns new pane_id |
| `focus` | `<pane>` | Move focus to pane |
| `kill` | `<pane>` | Close pane |
| `current` | - | Get current pane ID |

## Input

| Command | Args | Description |
|---------|------|-------------|
| `type` | `<pane> <text>` | Type text (no Enter) |
| `key` | `<pane> <key...>` | Send special keys |
| `submit` | `<pane>` | Enter → 3s wait → capture |

## Output

| Command | Args | Description |
|---------|------|-------------|
| `capture` | `<pane>` | Visible area with line numbers |
| `history` | `<pane> [lines]` | Scroll buffer with line numbers |

## Special Keys

| Key | Name |
|-----|------|
| Enter | `Enter` |
| Escape | `Escape` |
| Ctrl+C | `C-c` |
| Ctrl+D | `C-d` |
| Ctrl+L | `C-l` |
| Tab | `Tab` |
| Up/Down | `Up` / `Down` |

## Output Format

All capture commands include line numbers:
```
   1: first line
   2: second line
   ...
```

## Pane IDs

Format: `%<number>` (e.g., `%42`, `%43`)

Obtained from:
- `split` output: `Created pane: %42 (original: %41)`
- `panes` listing
- `current` command
