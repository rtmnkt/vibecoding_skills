#!/usr/bin/env bash
# Async Shell - Unified interface for background shell management
# Supports tmux

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect multiplexer environment
detect_env() {
    if [ -n "$TMUX" ]; then echo "tmux"
    elif tmux list-sessions &>/dev/null; then echo "tmux"
    elif command -v tmux &>/dev/null; then echo "tmux"
    else echo "none"
    fi
}

IMPL="${ASYNC_SHELL_IMPL:-$(detect_env)}"
ASYNC_SESSION="${ASYNC_SHELL_SESSION:-async_shell}"
CMD="${1:-help}"

# Ensure session exists (for tmux)
ensure_session() {
    if [ "$IMPL" = "tmux" ]; then
        tmux has-session -t "$ASYNC_SESSION" 2>/dev/null || \
            tmux new-session -d -s "$ASYNC_SESSION"
    fi
}

# Add line numbers to output
add_line_numbers() {
    nl -ba -w4 -s': '
}

# Show help
show_help() {
    cat << 'EOF'
USAGE: bash $0 <command> [args...]

COMMANDS:
  new [cmd]                   Create new shell, returns @N
  list                        List managed shells
  type <@N> <text>            Type text (no Enter)
  key <@N> <key...>           Send special keys
  submit <@N>                 Send Enter
  capture <@N> [-h lines]     Capture output with line numbers
                              -h: include scroll buffer (lines)
  kill <@N>                   Close shell
  current                     Get current shell ID
  help                        Show this help

UTIL (pane operations):
  util split <v|h> [cmd]      Split current pane
  util focus <%N>             Focus pane
  util panes                  List panes

KEYS:
  C-c (Ctrl+C), C-d (Ctrl+D), C-l (Ctrl+L)

WORKFLOW:
  1. new "bash"               # Start background shell
  2. type @1 "command"        # Type text
  3. submit @1                # Send Enter
  4. capture @1               # Check output
  5. kill @1                  # Cleanup

ID FORMAT:
  @N = window ID (e.g., @1, @2)
  %N = pane ID (e.g., %0, %1)

SESSION:
  Default session: async_shell
  Override: ASYNC_SHELL_SESSION=my_session bash $0 list
EOF
}

case "$CMD" in
    help|-h|--help)
        show_help
        exit 0
        ;;
    *)
        if [ "$IMPL" = "none" ]; then
            echo "Error: No terminal multiplexer available"
            echo "Install tmux first"
            exit 1
        fi
        
        IMPL_FILE="$SCRIPT_DIR/async_shell--impl-${IMPL}.sh"
        if [ ! -f "$IMPL_FILE" ]; then
            echo "Error: Implementation not found: $IMPL_FILE"
            exit 1
        fi
        
        ensure_session
        export ASYNC_SESSION
        source "$IMPL_FILE"
        shift
        impl_dispatch "$CMD" "$@"
        ;;
esac
