#!/bin/bash
# Screen implementation for async_shell
# Note: Screen has limited pane control compared to tmux

impl_dispatch() {
    local cmd="$1"
    shift
    
    case "$cmd" in
        info)
            echo "Screen session: $STY"
            ;;
        
        split)
            screen -X split
            screen -X focus
            screen -X screen
            echo "Split created (screen has limited pane control)"
            ;;
        
        panes)
            screen -Q windows 2>/dev/null || echo "Use Ctrl+a w to list windows"
            ;;
        
        type)
            local window="$1"
            shift
            screen -p "$window" -X stuff "$*"
            ;;
        
        key)
            local window="$1"
            shift
            for k in "$@"; do
                # Convert key names to screen format
                case "$k" in
                    Enter) screen -p "$window" -X stuff "$(printf '\r')" ;;
                    Escape) screen -p "$window" -X stuff "$(printf '\033')" ;;
                    C-c) screen -p "$window" -X stuff "$(printf '\003')" ;;
                    C-d) screen -p "$window" -X stuff "$(printf '\004')" ;;
                    C-l) screen -p "$window" -X stuff "$(printf '\014')" ;;
                    *) screen -p "$window" -X stuff "$k" ;;
                esac
            done
            ;;
        
        submit)
            local window="$1"
            screen -p "$window" -X stuff "$(printf '\r')"
            sleep 3
            local tmpfile=$(mktemp)
            screen -X hardcopy -h "$tmpfile"
            cat "$tmpfile" | grep -v "^$" | tail -50 | add_line_numbers
            rm -f "$tmpfile"
            ;;
        
        capture)
            local tmpfile=$(mktemp)
            screen -X hardcopy -h "$tmpfile"
            cat "$tmpfile" | grep -v "^$" | tail -50 | add_line_numbers
            rm -f "$tmpfile"
            ;;
        
        history)
            # Screen doesn't have easy history access like tmux
            local tmpfile=$(mktemp)
            screen -X hardcopy -h "$tmpfile"
            cat "$tmpfile" | grep -v "^$" | add_line_numbers
            rm -f "$tmpfile"
            ;;
        
        focus)
            local window="$1"
            screen -X select "$window"
            ;;
        
        kill)
            local window="$1"
            screen -p "$window" -X kill
            echo "Killed window: $window"
            ;;
        
        current)
            echo "screen-window"
            ;;
        
        *)
            echo "Unknown command: $cmd"
            echo "Note: Screen support is limited. Recommend using tmux."
            exit 1
            ;;
    esac
}
