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

# Help (implementation-independent)
show_help() {
    cat << 'EOF'
Async Shell Manager

Commands:
  info                       Current session/pane info
  panes                      List all panes
  split [h|v] [cmd]          Split pane, returns new pane_id
  type <pane_id> <text>      Type text (no Enter)
  key <pane_id> <key...>     Send special keys
  submit <pane_id>           Enter + 3s wait + capture
  capture <pane_id>          Visible area with line numbers
  history <pane_id> [lines]  Scroll buffer with line numbers
  focus <pane_id>            Focus on pane
  kill <pane_id>             Close pane
  current                    Get current pane id
  detect                     Show detected environment

Workflow:
  1. split v "claude"        # New pane with agent
  2. type %42 "message"      # Type text
  3. submit %42              # Send + wait + capture
  4. capture %42             # Check state
  5. kill %42                # Cleanup
EOF
}

# Main dispatch
case "$CMD" in
    detect)
        echo "$IMPL"
        ;;
    help)
        show_help
        ;;
    *)
        if [ "$IMPL" = "none" ]; then
            echo "Error: Not inside tmux or screen session"
            echo "Start tmux first, then run this script"
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
