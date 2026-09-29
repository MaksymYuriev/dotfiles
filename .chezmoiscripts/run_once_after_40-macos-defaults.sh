#!/usr/bin/env bash
# macOS defaults for a keyboard-driven dev setup. Log out/in after running.
set -euo pipefail

# Keyboard: fast repeat, no press-and-hold accents (required for Vim motions in VS Code)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write com.apple.keyboard.fnState -bool true   # F1..F12 as standard keys (F2 rename, F12 go-to-def)

# Disable "smart" text substitutions that break code snippets
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Dock + Spaces (AeroSpace-friendly)
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false          # don't reorder Spaces
defaults write com.apple.dock expose-group-apps -bool true    # AeroSpace recommendation for Mission Control
defaults write com.apple.spaces spans-displays -bool true     # "Displays have separate Spaces" OFF

# Ctrl+Cmd+drag moves windows from anywhere
defaults write -g NSWindowShouldDragOnGesture -bool true

# Screenshots
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"

# Disable Ctrl+Space / Ctrl+Opt+Space input source switching (F18/F19 via Karabiner instead)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "<dict><key>enabled</key><false/></dict>"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 "<dict><key>enabled</key><false/></dict>"

killall Dock Finder SystemUIServer 2>/dev/null || true
echo "macOS defaults applied. Log out and back in."
