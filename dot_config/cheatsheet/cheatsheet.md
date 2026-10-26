# Cheatsheet  ·  q close  ·  j/k or arrows scroll  ·  / search  ·  Extended sections below

Meh = hold Caps (built-in kbd) / hold E or I (Voyager).  Hyper = Meh + ⌘.  tmux prefix = Ctrl-b.
Voyager: this cheatsheet = hold Tab + outer key of the Esc row.

## AeroSpace (windows)
`Meh+h/j/k/l`        focus left / down / up / right
`Hyper+h/j/k/l`      move window left / down / up / right
`Meh+1..5`           go to workspace      `Hyper+1..5`  send window there
`Meh+Tab`            previous workspace
`Meh+r` then `=`     equalize window sizes (then Esc)
`Meh+;` then `a`     send every window back to its home workspace
`Meh+;` then `r`     reset layout tree (flatten)
`Meh+/`  tiles       `Meh+,`  accordion       `Meh+Space`  float/tile       `Meh+f`  fullscreen
`Meh+`` `            this cheatsheet

## tmux (sessions → windows → panes)
`prefix f`           fuzzy-jump to any window of any session  (● = agent waits for you)
`prefix d`           detach (agents keep running)     `tmux attach -t name`  come back
`prefix c`           new window     `prefix n/p`  next/prev     `prefix 1..9`  jump
`prefix %` / `"`     split right / below (same dir)     `prefix z`  zoom pane     `prefix x`  close pane
`Ctrl-h/j/k/l`      move between panes — also across Neovim splits (or `prefix h/j/k/l`)
`prefix [`           scroll/copy mode (vi keys; `v` select, `y` copy to clipboard, `q` leave)
`agent -s career kata03`      new Claude window "kata03" in session "career"
`agent -m sonnet -s career keys`   same, on Sonnet

## Neovim (LazyVim, leader = Space; press Space and wait for the which-key menu)
`Space Space`        find files            `Space /`  grep in project
`Space e` / `E`      file explorer toggle (project root / cwd)     `Space ,`  switch buffer
`H` / `L`            prev / next buffer    `Space bd` close buffer
`Ctrl-h/j/k/l`       move between splits and tmux panes     `Space -` / `|`  split below / right
`Space wd`           close split           `Space wm`  zoom split / back       `Space bb`  other buffer
`Ctrl-s`             save                  `gcc`  comment line     `s`  jump anywhere (flash)
`grn` rename · `gra` code action · `grr` references · `Space cf` format
`Space gg`           lazygit               `Space sk`  search all keymaps

────────────────────────────────────────────────────────────────────────────

## Extended: AeroSpace
Resize mode  (`Meh+r`, leave with Esc/Enter)
  `h` / `l`          narrower / wider by 100          `j` / `k`  taller / shorter by 100
  `=`                balance all sizes

Service mode  (`Meh+;`, then one key)
  `Esc`              reload config                    `r`  flatten workspace tree
  `f`                toggle floating / tiling         `a`  regroup windows to home workspaces
  `h/j/k/l`          join focused window with neighbour (nest them as one container)

Layout
  `Meh+/`            tiles (cycles horizontal / vertical)
  `Meh+,`            accordion (windows stacked, one visible)  — the default layout
  `Meh+Space`        floating <-> tiling for the focused window
  `Meh+f`            fullscreen toggle

Home workspaces (auto-assigned when a window opens)
  1 VS Code · 2 Ghostty · 3 Safari / Chrome · 4 Telegram · 5 Notes
  Always floating: 1Password, System Settings

## Extended: tmux
Sessions
  `prefix $`         rename session              `prefix ( / )`  previous / next session
  `prefix s`         built-in session/window tree
  `tmux ls`          list sessions               `tmux kill-session -t name`  delete one
Windows
  `prefix ,`         rename window               `prefix &`  close window
Panes
  `Ctrl-h/j/k/l`     move between panes without prefix (passes through to Neovim when it runs there)
  `prefix h/j/k/l`   same, with prefix            `prefix {` / `}`  swap panes (or click)
  `prefix Ctrl-l`    clear the screen in a shell (plain Ctrl-l now moves right)
  Note: `prefix l` is no longer "last window".
Copy mode  (`prefix [`)
  `h j k l` `w b` `0 $` `gg G` move like in Vim   `/` search   `v` select   `Ctrl-v` block   `y` copy to macOS clipboard   `q` leave
Misc
  `prefix :`         command prompt (e.g. `source-file ~/.tmux.conf` to reload)
  `prefix ?`         list every key binding
  Ctrl-b is also "page back" in Neovim; inside tmux use Ctrl-u / Ctrl-f instead.
Agents
  `agent research`           session <repo>-research in the current dir (no worktree)
  `agent -w feat-x`          also creates a git worktree + branch feat-x
  `agent -s career kata03`   window in an existing session (created if missing)
  Status bar: blue = current, ● yellow = an agent finished / needs permission.

## Extended: Neovim
Vim basics
  `h j k l`          move                `w` / `b` / `e`  word forward / back / end
  `0` / `$`          line start / end    `gg` / `G`  file start / end    `Ctrl-d/u`  half page
  `}` / `{`          next / prev paragraph (blank-line block)   works with operators: `d}` `y}` `v}`   `s`  flash jump
  `i` `a` `o`        insert before / after / new line below      `Esc`  back to normal
  `dd` `yy` `p`      delete line / yank line / paste             `u`  undo    `Ctrl-r`  redo
  `ciw` `ci"`        change word / text inside quotes            `.`  repeat last change
  `v` `V` `Ctrl-v`   visual: char / line / block                 `/text`  search, `n` / `N` next / prev
  `:w` `:q` `:wq`    save / quit / both       `Space qq`  quit all
Macros  (the same edit on several similar lines: do it once by hand, replay on the rest)
  `qq` … `q`         record into register q; finish the edit with `j` so the replay moves to the next line
  `3@q` / `@@`       replay 3 times / replay the last macro again
  `f"` `cf;` `D`     jump to a char · change up to and including a char · delete to line end (no `5s`: `s` = flash)
Find & search  (Space s…)
  `Space sg`         grep                `Space sw`  grep word under cursor   `Space sr`  search & replace
  `Space ff` / `fr`  files / recent      `Space fg`  git files   `Space fp`  projects
  `Space fF` / `sG`  files / grep in cwd only (Space Space, ff, sg search from the project root)   check `:pwd`, set with `:cd dir`
  `Space sd`         diagnostics         `Space sh`  help pages  `Space sk`  keymaps  `Space sC`  commands
  `Space su`         undo tree           `Space s"`  registers   `Space sm`  marks
Splits  (buffer = open file, window = split showing a buffer)
  `Space |` / `-`    split right / below (same buffer, then open another file with `Space Space`)
  in a file picker:  `Ctrl-v` open in vertical split · `Ctrl-s` open in horizontal split (instead of Enter)
  `Ctrl-h/j/k/l`     move between splits (and tmux panes)    `Space wd`  close split    `Space wm`  zoom / unzoom
  `Ctrl-arrows`      resize split          `Space bb`  jump to the previous buffer (task <-> solution)
  Each split has its own buffer: to change the LEFT one, `Ctrl-h` first, then switch buffer (`Space Space` / `Space ,` / `H` `L`), `Ctrl-l` back.
  Code left + docs right: keep left untouched; in the right split toggle task <-> concept with `Space bb`
    (`H`/`L` walk every open buffer. Careful: `Space bo` = Delete Other Buffers, it also closes the docs open in the other split)
Buffers / windows / tabs
  `Space bb` or `` Space ` ``  other buffer      `Space bo`  close other buffers
  `Space wd`         close window        `Space wm`  zoom window    `Ctrl-arrows`  resize split
  `Space Tab Tab`    new tab             `Space Tab ]` / `[`  next / prev tab
Code
  `K`  hover · `gd` definition  (when an LSP is attached)       `Space cd`  line diagnostics
  `]d` / `[d`        next / prev diagnostic        `]e` / `[e`  next / prev error
  `Space cm`         Mason (LSP / tool installer)  `Space xx`  diagnostics list (Trouble)
  `Alt-j` / `Alt-k`  move line down / up           `gco` / `gcO`  comment below / above
  `Space cM`         add all missing imports (TS)  `Space co`  organize imports (drop unused, sort)
  `Space ca`         code action on the cursor (e.g. "Add import from ...")
Run tests / shell commands  (katas: run from ~/Dev/career/katas)
  tmux `prefix "`, then `pnpm vitest 02`   watch mode below the editor, reruns on every save; `Ctrl-j/k` between them
  `Ctrl-/`           floating terminal: `pnpm test 02`; `Ctrl-/` again hides / shows it
  `:split | term pnpm test 02`   one-off run in a terminal split (close with `Space wd`)
  `:!cmd`            avoid for tests: output only lands in the message history (`Space snh`)
Git
  `Space gg`         lazygit             `Space gs`  status      `Space gd`  diff hunks
  `Space gb`         blame line          `Space gl`  log         `Space gf`  current file history
  `Space gp` / `gP`  GitHub PRs (open / all)
Toggles & misc
  `Space ul` line numbers · `uw` wrap · `us` spelling · `ud` diagnostics · `uh` inlay hints · `uz` zen
  `Ctrl-/`           terminal             `Space l`  Lazy (plugins)   `Space n`  notification history
  `Space qs` / `ql`  restore session / last session

## Extended: Voyager
  `Meh`              hold E or I               `Hyper`  Meh + hold Backspace (thumb ⌘)
  `Ctrl`             hold A or ;               `Alt`  S or L     `⌘`  D or K
  `` ` `` / `~`      hold Enter + outer key of the Esc row   (Sym layer)
  this cheatsheet    hold Tab + outer key of the Esc row     (Nav layer)
  `=`                hold Enter + G   (no `=` on the base layer, e.g. in AeroSpace resize mode)
