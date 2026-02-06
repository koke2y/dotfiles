#!/bin/bash
set -euo pipefail

if [ "$(uname)" != "Darwin" ]; then
    echo "Not macOS!"
    exit 1
fi

echo "==> Installing Xcode Command Line Tools..."
xcode-select --install 2>/dev/null || true

echo "==> Installing Homebrew..."
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "==> Installing chezmoi and applying dotfiles..."
brew install chezmoi
chezmoi init --apply --source="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing packages..."
brew bundle --global

echo "==> Configuring macOS defaults..."
# Base
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Dock
defaults write com.apple.dock launchanim -bool false
# Finder
defaults write com.apple.finder DisableAllAnimations -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
# Menu bar
defaults write com.apple.menuextra.clock DateFormat -string 'EEE d MMM HH:mm'
defaults write com.apple.menuextra.battery ShowPercent -string "YES"
# Restart affected apps
for app in "Dock" "Finder" "SystemUIServer"; do
    killall "${app}" &>/dev/null || true
done

echo "==> Done!"
