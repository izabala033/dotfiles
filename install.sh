#!/bin/bash
set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "==> Updating system..."
sudo pacman -Syu --noconfirm

echo "==> Installing base packages..."
sudo pacman -S --needed --noconfirm git base-devel stow

if ! command -v yay &> /dev/null; then
    echo "==> Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    pushd /tmp/yay
    makepkg -si --noconfirm
    popd
fi

install_packages() {
    local file=$1
    if [ -f "$file" ]; then
        echo "==> Installing packages from $file..."
        yay -S --needed --noconfirm $(grep -v '^#' "$file")
    fi
}

install_packages "$DOTFILES_DIR/packages/base.txt"

read -p "Install Hyprland packages? (y/n): " choice
[[ $choice == [Yy]* ]] && install_packages "$DOTFILES_DIR/packages/hyprland.txt"

echo "==> Stowing dotfiles..."
cd "$DOTFILES_DIR"

for dir in */ ; do
    if [ "$dir" != "packages/" ]; then
        stow "${dir%/}"
        echo "==> Stowed ${dir%/}"
    fi
done

echo "==> Installation complete!"