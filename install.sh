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

backup_unmanaged_file() {
    local target=$1
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
        echo "==> Backing up unmanaged $target to $backup"
        mv "$target" "$backup"
    fi
}

backup_unmanaged_file "$HOME/.config/Thunar/uca.xml"
backup_unmanaged_file "$HOME/.config/xfce4/helpers.rc"

echo "==> Stowing dotfiles..."
cd "$DOTFILES_DIR"

for dir in */ ; do
    if [ "$dir" != "packages/" ]; then
        stow "${dir%/}"
        echo "==> Stowed ${dir%/}"
    fi
done

echo "==> Installation complete!"
