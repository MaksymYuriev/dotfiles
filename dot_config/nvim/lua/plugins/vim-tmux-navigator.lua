-- Ctrl-h/j/k/l move between Neovim splits and tmux panes (tmux side: ~/.tmux.conf)
return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  keys = {
    { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Go to Left Window / tmux pane" },
    { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Go to Lower Window / tmux pane" },
    { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Go to Upper Window / tmux pane" },
    { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Go to Right Window / tmux pane" },
  },
}
