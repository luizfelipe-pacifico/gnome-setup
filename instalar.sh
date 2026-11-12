#!/usr/bin/env bash
# Comando de uma linha para um GNOME recém-instalado (Arch Linux):
#   bash <(curl -fsSL https://raw.githubusercontent.com/__REPO__/main/instalar.sh)
# Baixa (ou atualiza) este repositório e roda o setup.sh.
set -euo pipefail
REPO="https://github.com/__REPO__.git"
DEST="$HOME/.local/share/gnome-setup"

[ "$EUID" -eq 0 ] && { echo "Rode como seu usuário, sem sudo."; exit 1; }
command -v pacman >/dev/null || { echo "Este setup é para Arch Linux e derivados."; exit 1; }

command -v git >/dev/null || sudo pacman -S --needed --noconfirm git
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only
else
  git clone --depth 1 "$REPO" "$DEST"
fi
exec bash "$DEST/setup.sh"
