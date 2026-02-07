#!/bin/bash
# Tmux implementation for async_shell

impl_get_current_window() {
    tmux display-message -p '#{window_id}'
}

impl_get_current_pane() {
    tmux display-message -p '#{pane_id}'
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

impl_dispatch() {
    local cmd="$1"
    shift
    
    case "$cmd" in
        new)
            local original=$(impl_get_current_window)
            local new_window
            if [ $# -gt 0 ]; then
                new_window=$(tmux new-window -d -P -F '#{window_id}' "$*")
            else
                new_window=$(tmux new-window -d -P -F '#{window_id}')
            fi
            echo "Created: $new_window (from: $original)"
            ;;
        
        list)
            tmux list-windows -F '#{window_id} #{window_index}: #{window_name} [#{window_width}x#{window_height}]#{?window_active, (active),}'
            ;;
        
        type)
            local target="$1"
            shift
            # Send text without Enter - critical for TUI apps
            tmux send-keys -t "$target" "$*"
            ;;
        
        key)
            local target="$1"
            shift
            # Send each key separately - critical for TUI apps
            for k in "$@"; do
                tmux send-keys -t "$target" "$k"
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
                    local dir="${1:-v}"
                    shift || true
                    local split_flag="-v"
                    [ "$dir" = "h" ] && split_flag="-h"
                    
                    local original_pane=$(impl_get_current_pane)
                    local new_pane
                    if [ $# -gt 0 ]; then
                        new_pane=$(tmux split-window $split_flag -d -P -F '#{pane_id}' "$*")
                    else
                        new_pane=$(tmux split-window $split_flag -d -P -F '#{pane_id}')
                    fi
                    echo "Created pane: $new_pane (original: $original_pane)"
                    ;;
                
                focus)
                    local pane="$1"
                    tmux select-pane -t "$pane"
                    ;;
                
                panes)
                    tmux list-panes -F '#{pane_id} #{pane_index}: #{pane_current_command} [#{pane_width}x#{pane_height}]#{?pane_active, (active),}'
                    ;;
                
                *)
                    echo "Unknown util command: $subcmd"
                    echo "Available: split, focus, panes"
                    exit 1
                    ;;
            esac
            ;;
        
        *)
            echo "Unknown command: $cmd"
            echo "Run with 'help' for usage"
            exit 1
            ;;
    esac
}
