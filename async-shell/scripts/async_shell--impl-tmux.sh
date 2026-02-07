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
                impl_dispatch submit "$target"
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
                tmux capture-pane -t "$CAPTURE_TARGET" -p -S - | strip_trailing_blanks | tail -n "$CAPTURE_HISTORY" | add_line_numbers
            else
                tmux capture-pane -t "$CAPTURE_TARGET" -p | add_line_numbers
            fi
            ;;

        capture-diff)
            local target="$1"
            if [ -z "$target" ]; then
                echo "Error: capture-diff requires target"
                exit 1
            fi

            local sanitized="${target//@/_}"
            local snapshot="/tmp/async_shell_snapshot_${sanitized}.txt"
            local ts_file="/tmp/async_shell_ts_${sanitized}.txt"
            local current="/tmp/async_shell_current_${sanitized}.txt"

            # Check activity timestamp
            local current_ts
            current_ts=$(tmux display-message -t "$target" -p '#{window_activity}')
            local stored_ts
            stored_ts=$(cat "$ts_file" 2>/dev/null || echo "0")

            if [ "$current_ts" = "$stored_ts" ] && [ -f "$snapshot" ]; then
                echo "(no change)"
                return
            fi

            # Activity detected - capture current state (strip trailing blanks to reduce noise)
            tmux capture-pane -t "$target" -p | strip_trailing_blanks > "$current"

            if [ ! -f "$snapshot" ]; then
                # First time - establish baseline
                cp "$current" "$snapshot"
                echo "$current_ts" > "$ts_file"
                echo "(initial)"
                cat "$current"
                rm -f "$current"
                return
            fi

            # Compute diff
            local raw_diff
            raw_diff=$(diff -u "$snapshot" "$current")
            local diff_exit=$?

            if [ $diff_exit -eq 0 ]; then
                # Content identical despite activity
                echo "(output detected, screen unchanged)"
            elif [ $diff_exit -eq 1 ]; then
                # Content changed - output unified diff without header/hunk markers
                echo "$raw_diff" | tail -n +3 | grep -v '^@@'
                cp "$current" "$snapshot"
            else
                echo "Error: diff failed"
            fi

            echo "$current_ts" > "$ts_file"
            rm -f "$current"
            ;;

        kill)
            local target="$1"
            # Clean up capture-diff state files
            local sanitized="${target//@/_}"
            rm -f "/tmp/async_shell_snapshot_${sanitized}.txt"
            rm -f "/tmp/async_shell_ts_${sanitized}.txt"
            rm -f "/tmp/async_shell_current_${sanitized}.txt"
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
