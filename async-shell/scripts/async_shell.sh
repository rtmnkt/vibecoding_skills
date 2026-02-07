#!/usr/bin/env bash
# Async Shell - Unified interface for background shell management
# Supports tmux

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

# Strip trailing blank lines from output
strip_trailing_blanks() {
    awk '/./{last=NR} {a[NR]=$0} END{for(i=1;i<=last;i++) print a[i]}'
}

# Add line numbers to output (bottom-relative: 1 is the last line)
add_line_numbers() {
    awk '{ a[NR] = $0 } END { for (i = NR; i >= 1; i--) printf "%4d: %s\n", NR - i + 1, a[i] }'
}

# Show help
show_help() {
    cat << 'EOF'
USAGE: bash $0 <command> [args...]

COMMANDS:
  new [cmd]                   Create new shell, returns @N
  list                        List managed shells
  type <@N> <text> [-s]       Type text (no Enter), -s to auto-submit
  key <@N> <key...>           Send special keys
  submit <@N>                 Send Enter
  capture <@N> [-h lines]     Capture output with line numbers
                              -h: last N lines (including history)
  capture-diff <@N>           Diff since last capture-diff (unified format)
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
  4. capture @1               # View current screen
  5. capture-diff @1          # Monitor changes (polling)
  6. kill @1                  # Cleanup

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
