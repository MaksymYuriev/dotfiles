# dotfiles

My macOS setup for frontend development: keyboard-driven, tiled windows, AI agents in the terminal.
Ghostty, AeroSpace, Raycast, Karabiner, Neovim (LazyVim), Claude Code, ZSA Voyager.

Deploys to a fresh Mac with one command via [chezmoi](https://www.chezmoi.io). No secrets live in this repo: SSH keys and commit signing are handled by 1Password.

Hotkey cheat sheet: [`docs/cheatsheet.html`](docs/cheatsheet.html) (open it locally in a browser).

> **For friends and colleagues.** This is my personal setup and it's intentionally opinionated: it changes macOS system settings, keyboard shortcuts, and how you switch input languages. Before running it, read [what changes on your system](#what-changes-on-your-system) and [how to make it yours](#how-to-make-it-yours). The best way to use it is to fork it and edit your copy.

---

## Contents

- [Requirements](#requirements)
- [What gets installed](#what-gets-installed)
- [What changes on your system](#what-changes-on-your-system)
- [Setting up a new Mac](#setting-up-a-new-mac)
- [Keyboard: one scheme for any keyboard](#keyboard-one-scheme-for-any-keyboard)
- [How to make it yours](#how-to-make-it-yours)
- [Day-to-day usage](#day-to-day-usage)
- [Rolling back](#rolling-back)
- [Troubleshooting](#troubleshooting)
- [Structure](#structure)

---

## Requirements

| | |
|---|---|
| **Mac** | Apple Silicon (M1 or newer). The Homebrew path `/opt/homebrew` is hardcoded; on Intel it's `/usr/local` |
| **macOS** | 14 Sonoma or newer (Touch ID for `sudo` relies on `sudo_local`) |
| **Permissions** | An admin user: Homebrew and system settings ask for your password |
| **1Password** | A 1Password 8 account with an SSH key item. Used for SSH to GitHub and commit signing |
| **GitHub** | An account with that key added **twice**: as an Authentication key and as a Signing key |
| **Network** | About 5 GB of downloads (apps, Xcode CLT, Node, language servers) |
| **Time** | ~30 minutes, ~10 of them hands-on |

Optional: ZSA Voyager (everything works without it), a Logitech MX mouse, an ultrawide monitor.

---

## What gets installed

Everything comes from the [`Brewfile`](Brewfile). Items marked ⚙️ are only there for my hardware and can be removed.

**Terminal and shell**

| | |
|---|---|
| [Ghostty](https://ghostty.org) | Fast, native terminal with splits |
| [Starship](https://starship.rs) | Prompt with git status and runtime versions |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `z project` jumps to a directory by partial name |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder: history with `⌃R`, files with `⌃T` |
| eza, bat, ripgrep, fd, jq | Modern `ls`, `cat`, `grep`, `find`, and JSON processing |
| zsh-autosuggestions, zsh-syntax-highlighting | History suggestions and command highlighting |
| JetBrains Mono Nerd Font | Font with icons for the terminal and editor |

**Git**

| | |
|---|---|
| git, [delta](https://github.com/dandavison/delta) | Git with readable diffs |
| [lazygit](https://github.com/jesseduffield/lazygit) | Git TUI (`lg`) |
| gh, glab | GitHub and GitLab CLIs |

**Windows and keyboard**

| | |
|---|---|
| [AeroSpace](https://github.com/nikitabobko/AeroSpace) | i3-style tiling window manager with its own workspaces instead of macOS Spaces |
| [Raycast](https://raycast.com) | Launcher replacing Spotlight, app hotkeys |
| [Karabiner-Elements](https://karabiner-elements.pqrs.org) | Caps Lock → Meh, language keys, the same on any keyboard |
| ⚙️ Keymapp | Flashing the ZSA Voyager |
| ⚙️ BetterDisplay | Custom resolutions for an ultrawide monitor |
| ⚙️ Logi Options+ | Logitech MX mouse driver |

**Editors and AI**

| | |
|---|---|
| [Neovim](https://neovim.io) + [LazyVim](https://lazyvim.org) | Main editor. TypeScript, Tailwind, ESLint, Prettier via LSP |
| VS Code | Fallback editor for debugging. Minimal extensions from `vscode/extensions.txt` |
| [Claude Code](https://claude.com/claude-code) | Main AI agent in the terminal |
| [OpenCode](https://opencode.ai) | Agent for experimenting with other models (OpenRouter and others) |

**Runtimes and infrastructure**

| | |
|---|---|
| [mise](https://mise.jdx.dev) | Versions of Node, pnpm and more (replaces nvm). Installs Node LTS and pnpm |
| [OrbStack](https://orbstack.dev) | Docker runtime, lighter than Docker Desktop |
| Google Chrome | Browser for DevTools (Safari is the daily browser) |

**Other**

| | |
|---|---|
| 1Password CLI | `op` for injecting secrets into `.env` without plaintext files |
| chezmoi | Manages this repo |
| mas | Installs Mac App Store apps from the CLI |

---

## What changes on your system

The scripts live in [`.chezmoiscripts/`](.chezmoiscripts). Read them before running anything; they're short.

| Script | Runs | What it does |
|---|---|---|
| `00-homebrew` | once | Homebrew + Xcode Command Line Tools |
| `10-brew-bundle` | whenever `Brewfile` changes | `brew bundle` |
| `20-runtimes` | once | Node LTS and pnpm via mise; pnpm refuses package versions younger than 24h; Claude Code |
| `30-vscode-extensions` | whenever the list changes | VS Code extensions |
| `40-macos-defaults` | once | System settings (below) |
| `50-sudo-touchid` | once | Touch ID for `sudo` (`/etc/pam.d/sudo_local`) |

**macOS settings** (`40-macos-defaults`):
- Fast key repeat; press-and-hold for accents disabled (needed for vim motions).
- F1–F12 behave as standard function keys.
- Smart quotes, smart dashes, and autocorrect disabled.
- Finder: show extensions and hidden files, path bar, list view.
- Dock: auto-hide, no recent apps.
- Spaces: no automatic reordering; `Displays have separate Spaces` disabled (AeroSpace recommendation).
- Screenshots saved to `~/Screenshots`.
- **`⌃Space` input-language switching disabled**: languages are switched with dedicated keys via Karabiner.

**Config files created in `~`:** `.aerospace.toml`, `.config/ghostty/`, `.config/karabiner/`, `.config/nvim/`, `.gitconfig`, `.ssh/config`, `.zprofile`, `.zshrc`. If you already have any of them, chezmoi shows the diff and asks before overwriting.

---

## Setting up a new Mac

### 1. Manual, before anything else (5 min)

1. Sign in to your Apple ID, update macOS.
2. Install **1Password** from [1password.com](https://1password.com/downloads/mac) and sign in.
3. 1Password → Settings → Developer → enable **Use the SSH agent** and **Integrate with 1Password CLI**.
4. Create or find your **SSH Key** item and copy its public key (`ssh-ed25519 AAAA...`). Make sure it's added to GitHub as both an Authentication and a Signing key.

### 2. Preview what will change (recommended)

```bash
cd ~
sh -c "$(curl -fsLS get.chezmoi.io)" -- init MaksymYuriev
~/bin/chezmoi diff
```

This applies nothing, it only shows the changes. The installer puts `chezmoi` into `./bin` of the current directory, hence `cd ~` first. If you forked the repo, replace `MaksymYuriev` with your GitHub username.

### 3. Apply (15–20 min)

```bash
~/bin/chezmoi apply
```

Or everything at once, without the preview:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply MaksymYuriev
```

chezmoi asks for your name, email, and SSH public key for git. When it finishes, **log out and back in**.

### 4. Manual, after (10 min): permissions macOS won't let you automate

| What | Where |
|---|---|
| AeroSpace | Launch → Privacy & Security → Accessibility (Device Control) |
| Raycast | Onboarding: grant Device Control and Files. Take `⌘Space` from Spotlight (Keyboard → Keyboard Shortcuts → Spotlight) |
| Raycast hotkeys | Settings → Advanced → Import your `.rayconfig` export, if you have one |
| Karabiner | Launch → Setup: grant all permissions. Virtual Keyboard: **ANSI**. Devices: enable **Modify events** for programmable keyboards |
| Karabiner rules | Complex Modifications → Add predefined rule → enable all three rules |
| Input sources | Keyboard → Input Sources: **ABC** and **Ukrainian** (or your second language, see below) |
| GitHub | `ssh -T git@github.com` → Touch ID → `Hi <username>!` |
| Neovim | Run `nvim`: plugins install themselves. Open any `.ts` file: Mason installs the language servers |

**Don't grant Ghostty the Device Control permission:** everything running inside the terminal (npm scripts, agents) would inherit the ability to control other apps. The Ghostty hotkey goes through Raycast instead.

### 5. Keyboard

**ZSA Voyager:** Keymapp → Flash → `keyboards/voyager/v2/voyager_v2.bin`. Details in [`keyboards/voyager/README.md`](keyboards/voyager/README.md).

**Any other keyboard:** nothing to do, see the next section.

---

## Keyboard: one scheme for any keyboard

The whole scheme rests on five modifier roles. Each role has exactly one job, so hotkeys from different tools never collide.

| Role | Used for |
|---|---|
| **Meh** (`⌃⌥⇧`) | AeroSpace: focus, workspaces, layouts. Raycast: app hotkeys |
| **Hyper** (Meh + `⌘`) | AeroSpace: moving windows |
| `⌘` | Apps and macOS |
| `⌥`, `⌃` | Neovim and zsh only |
| **EN / UA** (F18 / F19) | Language switching: each key always selects its language instead of cycling |

How the roles map to different keyboards:

| | Meh | Hyper | EN / UA |
|---|---|---|---|
| **ZSA Voyager** | hold `E` or `I` | Meh + hold left thumb `⌫` | bottom corners (F18 / F19) |
| **MacBook** | hold `Caps Lock` | `Caps` + `⌘` | tap left / right `⌘` |
| **Regular external keyboard** | hold `Caps Lock` | `Caps` + `⌘` | tap left / right `⌘` |
| **Other programmable (QMK / VIA / ZMK)** | mod-tap `MEH_T` on `E` and `I` | same as Voyager | two keys sending `F18` / `F19` |

A quick tap on `Caps Lock` is still `Esc`. The Karabiner rules apply to **every keyboard except ZSA ones** (vendor ID `12951` = `0x3297`), so a new keyboard works without any changes.

### Porting to another programmable keyboard

Minimum:
1. `F18` and `F19` on two convenient keys.
2. Mod-taps `MEH_T(KC_E)` and `MEH_T(KC_I)`.
3. Home-row mods: `A`=⌃, `S`=⌥, `D`=⌘, `F`=⇧, mirrored `J`=⇧, `K`=⌘, `L`=⌥, `;`=⌃.
4. **Chordal Hold** and **Permissive Hold** enabled.

Recommended (diagrams in `keyboards/voyager/README.md`, code in `keyboards/voyager/v2/keymap.c`):

5. Symbol layer on a right-thumb hold: top row = Shift+digits, home row holds mirrored brackets `< { [ (` | `) ] } >`.
6. Navigation layer on the other right-thumb hold: arrows on `hjkl`, left hand holds `⌃ ⌥ ⌘ ⇧` on the home row, undo/cut/copy/paste/redo on `QWERT`.

---

## How to make it yours

The easiest path: **fork**, edit your copy, and use your username instead of `MaksymYuriev` in the setup commands.

| To change | Where |
|---|---|
| Apps | `Brewfile`: drop the ⚙️ items if you don't have that hardware, add your own |
| Second language instead of Ukrainian | `dot_config/karabiner/assets/complex_modifications/maksim.json`: replace `^uk$` with your language code (`^pl$`, `^de$`, ...) |
| Workspaces and which apps go where | `dot_aerospace.toml`, the `on-window-detected` blocks. Get any app's ID with `aerospace list-apps` |
| AeroSpace bindings | `dot_aerospace.toml`, the `[mode.main.binding]` section |
| Terminal font and theme | `dot_config/ghostty/config` |
| System settings | `.chezmoiscripts/run_once_after_40-macos-defaults.sh`: comment out whatever you don't like |
| Neovim | `dot_config/nvim/`. The Ukrainian `langmap` in `lua/config/options.lua` is only needed for a Cyrillic layout |
| VS Code extensions | `vscode/extensions.txt` |

`keyboards/voyager/` holds my personal layout; delete it if you don't have a Voyager.

---

## Day-to-day usage

```bash
chezmoi edit ~/.aerospace.toml         # edit through chezmoi
chezmoi add ~/.config/ghostty/config   # or pull in changes made directly
chezmoi diff                           # preview
chezmoi apply                          # apply
chezmoi cd && git add -A && git commit -m "..." && git push
chezmoi update                         # on another Mac: pull + apply
```

New app: add a line to the `Brewfile` → `chezmoi apply` runs `brew bundle` automatically.

---

## Rolling back

- **Configs:** chezmoi never deletes files it didn't create. To stop managing them, run `chezmoi purge` (removes chezmoi itself and its state; your config files in `~` stay).
- **Apps:** `brew uninstall --cask <name>`, or `brew bundle cleanup --file=Brewfile --force` to remove everything not listed in the Brewfile.
- **macOS settings:** `defaults delete <domain> <key>` for a specific item from the script, or System Settings by hand.
- **Touch ID for sudo:** `sudo rm /etc/pam.d/sudo_local`.
- **Voyager firmware:** Keymapp → Flash → the original `.bin` from Oryx.

---

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `claude: command not found` | `PATH` wasn't picked up. Open a new terminal or run `source ~/.zprofile` |
| Language keys beep | Karabiner isn't modifying that keyboard: Devices → **Modify events** |
| `` ` `` types `§` | Karabiner's virtual keyboard is set to ISO. Switch to **ANSI** |
| Meh types letters instead of triggering a hotkey | Hold `E`/`I` a bit longer, or use the Meh key on the opposite hand from the letter |
| Ghostty windows vanish on `⌘T` | Native tabs don't work with AeroSpace. Already remapped to a new window: `cmd+t=new_window` |
| A window won't tile | It was in native fullscreen. Focus it → Meh+`Space` |
| A window got lost | `aerospace list-windows --all` |
| `config-version` warning | The config already has `config-version = 2`; if you see it, you're running an old config |

---

## Structure

```
.chezmoi.toml.tmpl          # asks name, email, SSH key on first run
.chezmoiscripts/            # bootstrap scripts
Brewfile                    # apps and CLI tools
dot_aerospace.toml          # ~/.aerospace.toml
dot_config/ghostty/         # ~/.config/ghostty/
dot_config/karabiner/       # ~/.config/karabiner/
dot_config/nvim/            # ~/.config/nvim/ (LazyVim)
dot_gitconfig.tmpl          # ~/.gitconfig (commit signing via 1Password)
dot_zprofile, dot_zshrc     # zsh
private_dot_ssh/config      # SSH via 1Password agent
keyboards/voyager/          # Voyager layout: plan, QMK source, firmware
vscode/extensions.txt       # VS Code extensions
docs/cheatsheet.html        # hotkey cheat sheet
```

## License

MIT, except `keyboards/voyager/`: it's derived from [QMK](https://github.com/qmk/qmk_firmware) and therefore GPL-2.0-or-later. See [LICENSE](LICENSE).
