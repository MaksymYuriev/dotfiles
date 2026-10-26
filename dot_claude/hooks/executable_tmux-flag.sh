#!/bin/bash
# tmux-flag.sh set|clear — mark this agent's tmux window as waiting for input (shown in the status bar)
[[ -n ${TMUX:-} && -n ${TMUX_PANE:-} ]] || exit 0
case ${1:-} in
  set)
    # skip if you are already looking at this window
    [[ $(tmux display-message -p -t "$TMUX_PANE" '#{&&:#{session_attached},#{window_active}}') == 1 ]] && exit 0
    tmux set-option -w -t "$TMUX_PANE" @needs-input 1 ;;
  clear) tmux set-option -wu -t "$TMUX_PANE" @needs-input ;;
esac
