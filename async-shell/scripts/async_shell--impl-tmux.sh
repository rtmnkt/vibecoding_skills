#!/bin/bash
# Tmux implementation for async_shell

impl_get_current_pane() {
    tmux display-message -p '#{pane_id}'
}

impl_dispatch() {
    local cmd="$1"
    shift
    
    case "$cmd" in
        info)
            echo "Session: $(tmux display-message -p '#{session_name}')"
            echo "Window:  $(tmux display-message -p '#{window_index}')"
            echo "Pane:    $(tmux display-message -p '#{pane_index}') ($(impl_get_current_pane))"
            ;;
        
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
        
        panes)
            tmux list-panes -F '#{pane_id} #{pane_index}: #{pane_current_command} [#{pane_width}x#{pane_height}]#{?pane_active, (active),}'
            ;;
        
        type)
            local pane="$1"
            shift
            tmux send-keys -t "$pane" "$*"
            ;;
        
        key)
            local pane="$1"
            shift
            for k in "$@"; do
                tmux send-keys -t "$pane" "$k"
            done
            ;;
        
        submit)
            local pane="$1"
            tmux send-keys -t "$pane" Enter
            sleep 3
            tmux capture-pane -t "$pane" -p | add_line_numbers
            ;;
        
        capture)
            local pane="$1"
            tmux capture-pane -t "$pane" -p | add_line_numbers
            ;;
        
        history)
            local pane="$1"
            local lines="${2:-100}"
            tmux capture-pane -t "$pane" -p -S "-$lines" | add_line_numbers
            ;;
        
        focus)
            local pane="$1"
            tmux select-pane -t "$pane"
            ;;
        
        kill)
            local pane="$1"
            tmux kill-pane -t "$pane"
            echo "Killed pane: $pane"
            ;;
        
        wait)
            local pane="$1"
            local timeout="${2:-30}"
            local pattern="${3:-\$|#|>>>|>}"
            local start=$(date +%s)
            while true; do
                local output=$(tmux capture-pane -t "$pane" -p | tail -5)
                if echo "$output" | grep -qE "$pattern"; then
                    echo "$output"
                    return 0
                fi
                local now=$(date +%s)
                if [ $((now - start)) -ge "$timeout" ]; then
                    echo "Timeout waiting for prompt"
                    return 1
                fi
                sleep 0.5
            done
            ;;
        
        current)
            impl_get_current_pane
            ;;
        
        *)
            echo "Unknown command: $cmd"
            exit 1
            ;;
    esac
}
