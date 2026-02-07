#!/usr/bin/env bash
# tmux implementation for async_shell

# Get current window ID
impl_get_current_window() {
    tmux display-message -p '#{window_id}'
}

# Parse capture options: [-h lines] <target>
parse_capture_opts() {
    CAPTURE_HISTORY=""
    CAPTURE_TARGET=""
    
    while [ $# -gt 0 ]; do
        case "$1" in
            -h)
                CAPTURE_HISTORY="$2"
                shift 2
                ;;
            *)
                CAPTURE_TARGET="$1"
                shift
                ;;
        esac
    done
}

# Main dispatcher
impl_dispatch() {
    local cmd="$1"
    shift
    
    case "$cmd" in
        new)
            local original=$(impl_get_current_window)
            local new_window
            if [ $# -gt 0 ]; then
                new_window=$(tmux new-window -t "$ASYNC_SESSION" -d -P -F '#{window_id}' "$*")
            else
                new_window=$(tmux new-window -t "$ASYNC_SESSION" -d -P -F '#{window_id}')
            fi
            echo "Created: $new_window (from: $original)"
            ;;
        
        list)
            tmux list-windows -t "$ASYNC_SESSION" -F '#{window_id} #{window_index}: #{window_name} [#{window_width}x#{window_height}]#{?window_active, (active),}'
            ;;
        
        type)
            local target="$1"
            shift
            local submit_flag=""
            local text=""
            
            while [ $# -gt 0 ]; do
                case "$1" in
                    -s)
                        submit_flag=1
                        shift
                        ;;
                    *)
                        text="$text$1 "
                        shift
                        ;;
                esac
            done
            
            text="${text% }"
            tmux send-keys -t "$target" -l "$text"
            
            if [ -n "$submit_flag" ]; then
                tmux send-keys -t "$target" Enter
            fi
            ;;
        
        key)
            local target="$1"
            shift
            for key in "$@"; do
                tmux send-keys -t "$target" "$key"
            done
            ;;
        
        submit)
            local target="$1"
            tmux send-keys -t "$target" Enter
            ;;
        
        capture)
            parse_capture_opts "$@"
            
            if [ -z "$CAPTURE_TARGET" ]; then
                echo "Error: capture requires target"
                exit 1
            fi
            
            if [ -n "$CAPTURE_HISTORY" ]; then
                tmux capture-pane -t "$CAPTURE_TARGET" -p -S "-$CAPTURE_HISTORY" | add_line_numbers
            else
                tmux capture-pane -t "$CAPTURE_TARGET" -p | add_line_numbers
            fi
            ;;
        
        kill)
            local target="$1"
            tmux kill-window -t "$target"
            echo "Killed: $target"
            ;;
        
        current)
            impl_get_current_window
            ;;
        
        util)
            local subcmd="$1"
            shift
            case "$subcmd" in
                split)
                    local direction="$1"
                    shift
                    local split_opt="-h"
                    [ "$direction" = "v" ] && split_opt="-v"
                    if [ $# -gt 0 ]; then
                        tmux split-window $split_opt -d -P -F '#{pane_id}' "$*"
                    else
                        tmux split-window $split_opt -d -P -F '#{pane_id}'
                    fi
                    ;;
                focus)
                    tmux select-pane -t "$1"
                    ;;
                panes)
                    tmux list-panes -F '#{pane_id} #{pane_index}: [#{pane_width}x#{pane_height}]#{?pane_active, (active),}'
                    ;;
                *)
                    echo "Unknown util command: $subcmd"
                    exit 1
                    ;;
            esac
            ;;
        
        *)
            echo "Unknown command: $cmd"
            exit 1
            ;;
    esac
}
