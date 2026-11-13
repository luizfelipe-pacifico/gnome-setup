#!/usr/bin/env bash
# Comando de uma linha só para a estilização (Aparência estilo Apple/GNOME e app Firewall),
# para qualquer Arch Linux (ou derivado) com GNOME, sem rodar o setup inteiro:
#   bash <(curl -fsSL https://raw.githubusercontent.com/luizfelipe-pacifico/gnome-setup/main/estilo.sh)
# Baixa (ou atualiza) este repositório e roda o bin/instalar-seletor-de-tema.
set -euo pipefail
REPO="https://github.com/luizfelipe-pacifico/gnome-setup.git"
DEST="$HOME/.local/share/gnome-setup"

[ "$EUID" -eq 0 ] && { echo "Rode como seu usuário, sem sudo."; exit 1; }
command -v pacman >/dev/null || { echo "Este comando é para Arch Linux e derivados."; exit 1; }

command -v git >/dev/null || sudo pacman -S --needed --noconfirm git
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only
else
  git clone --depth 1 "$REPO" "$DEST"
fi
exec bash "$DEST/bin/instalar-seletor-de-tema"
