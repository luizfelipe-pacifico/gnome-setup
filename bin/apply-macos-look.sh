#!/usr/bin/env bash
# Instala o que o estilo Apple (macOS) precisa: vidro (Blur my Shell), ponteiro macOS,
# ícones WhiteSur, fonte Inter e o efeito de minimizar "lâmpada mágica".
# Botões coloridos, dock, barra, atalhos e papel de parede são só configuração: o app aplica.
# Conversa com o app Seletor de Tema pelo arquivo ~/.config/seletor-de-tema/status
set -e
STATUS_DIR="$HOME/.config/seletor-de-tema"
mkdir -p "$STATUS_DIR"
echo instalando > "$STATUS_DIR/status"
trap '[ "$(cat "$STATUS_DIR/status")" = instalando ] && echo erro > "$STATUS_DIR/status"' EXIT

PKGS=(gnome-shell-extension-blur-my-shell apple_cursor whitesur-icon-theme inter-font)
yay -S --needed --noconfirm "${PKGS[@]}"
for p in "${PKGS[@]}"; do rm -rf "$HOME/.cache/yay/$p"; done   # não guarda sobras de build

# Efeito de minimizar estilo macOS, baixado do extensions.gnome.org para a versão do Shell
LAMP=compiz-alike-magic-lamp-effect@hermes83.github.com
SHELL_VER=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
URL=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=$LAMP&shell_version=$SHELL_VER" |
      python3 -c 'import json,sys; print(json.load(sys.stdin)["download_url"])' 2>/dev/null || true)
if [ -n "$URL" ]; then
  TMP=$(mktemp -d)
  curl -fsSL "https://extensions.gnome.org$URL" -o "$TMP/lamp.zip"
  gnome-extensions install --force "$TMP/lamp.zip"
  rm -rf "$TMP"
else
  echo "Aviso: efeito de minimizar não tem versão para o GNOME $SHELL_VER, pulando."
fi

# Vidro onde faz sentido
SD=/usr/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas
B=org.gnome.shell.extensions.blur-my-shell
b(){ gsettings --schemadir "$SD" set "$B.$1" "$2" "$3" 2>/dev/null || true; }
b panel blur true;        b panel static-blur true      # static = quase zero custo de GPU/RAM
b dash-to-dock blur true; b dash-to-dock static-blur true
b overview blur true;     b overview style-components 3  # tela de apps transparente sobre fundo desfocado
b appfolder blur true;    b appfolder style-dialogs 3    # pastas de apps como vidro
b lockscreen blur true
b applications blur false                                 # janelas sem blur: economiza GPU

echo instalado > "$STATUS_DIR/status"
# Se o estilo Apple já está escolhido, aplica o que acabou de chegar (e liga as extensões)
command -v seletor-de-tema >/dev/null && seletor-de-tema --reaplicar
echo "Pronto. Saia e entre na sessão para o vidro e o efeito de minimizar aparecerem."
