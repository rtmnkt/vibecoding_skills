#!/bin/bash
# Async shell manager - interface with dynamic implementation loading
# Usage: async_shell.sh <command> [args...]

set -e

SCRIPT_DIR="$(dirname "$0")"

# Detect environment
detect_env() {
    if [ -n "$TMUX" ]; then echo "tmux"
    elif [ -n "$STY" ]; then echo "screen"
    else echo "none"
    fi
}

IMPL="${ASYNC_SHELL_IMPL:-$(detect_env)}"
CMD="${1:-help}"

# Add line numbers to output
add_line_numbers() {
    nl -ba -w4 -s': '
}

# Help
show_help() {
    cat << 'EOF'
Async Shell Manager

COMMANDS:
  new [cmd]                   Create new background shell, returns @N
  list                        List managed shells
  type <@N> <text>            Type text (no Enter)
  key <@N> <key...>           Send special keys
  submit <@N>                 Enter + capture
  capture <@N> [-w sec] [-h lines]
                              Capture output with line numbers
                              -w: wait before capture (default: 0)
                              -h: include scroll buffer (lines)
  kill <@N>                   Close shell
  current                     Get current shell ID
  help                        Show this help

UTIL COMMANDS:
  util split [h|v] [cmd]      Split pane, returns %N
  util focus <pane>           Focus pane within window
  util panes                  List panes in current window

SPECIAL KEYS:
  Enter, Escape, Tab, Up, Down, Left, Right
  C-c (Ctrl+C), C-d (Ctrl+D), C-l (Ctrl+L)

WORKFLOW:
  1. new "claude"             # Start background agent
  2. type @1 "message"        # Type text
  3. submit @1                # Send + capture
  4. capture @1               # Check state
  5. kill @1                  # Cleanup

ID FORMAT:
  @N  - Window ID (e.g., @1, @2)
  %N  - Pane ID (e.g., %1, %2) for util commands
EOF
}

# Main dispatch
case "$CMD" in
    detect)
        echo "$IMPL"
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        if [ "$IMPL" = "none" ]; then
            echo "Error: Not inside a terminal multiplexer session"
            echo "Start a session first, then run this script"
            exit 1
        fi
        
        IMPL_FILE="$SCRIPT_DIR/async_shell--impl-${IMPL}.sh"
        if [ ! -f "$IMPL_FILE" ]; then
            echo "Error: Implementation not found: $IMPL_FILE"
            exit 1
        fi
        
        source "$IMPL_FILE"
        shift
        impl_dispatch "$CMD" "$@"
        ;;
esac
