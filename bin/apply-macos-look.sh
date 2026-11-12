#!/usr/bin/env bash
# Instala o que o estilo Apple (macOS) precisa: vidro (Blur my Shell), ponteiro macOS,
# ícones de apps estilo Mac, fonte Inter e o efeito de minimizar "lâmpada mágica".
# Pensado para ocupar pouco: sem sobras de compilação e só alguns ícones (poucos KB).
# Botões coloridos, dock, barra, atalhos e papel de parede são só configuração: o app aplica.
# Conversa com o app Seletor de Tema pelo arquivo ~/.config/seletor-de-tema/status
set -e
STATUS_DIR="$HOME/.config/seletor-de-tema"
mkdir -p "$STATUS_DIR"
echo instalando > "$STATUS_DIR/status"
trap '[ "$(cat "$STATUS_DIR/status")" = instalando ] && echo erro > "$STATUS_DIR/status"' EXIT

PKGS=(gnome-shell-extension-blur-my-shell apple_cursor inter-font)
yay -S --needed --noconfirm "${PKGS[@]}"

# Ícones: do WhiteSur ficam só alguns apps nativos do GNOME (e a lixeira), num tema "MacApps"
# que herda o Adwaita. Bateria, rede, volume e símbolos continuam os do GNOME; apps de fora
# (navegadores etc.) e ícones que são cópia de apps da Apple (Finder, App Store, Calendário,
# Música, Mapas...) ficam com o ícone original. O pacote inteiro (~190 MB) sai do disco.
# Para mudar a escolha, edite COM_MAC e aumente MAC_VERSAO.
MAC=/usr/local/share/icons/MacApps
MAC_VERSAO=3
COM_MAC=(org.gnome.Console utilities-terminal org.gnome.SystemMonitor utilities-system-monitor
         org.gnome.tweaks org.gnome.Loupe org.gnome.Showtime org.gnome.Characters
         org.gnome.Connections org.gnome.Decibels org.gnome.SimpleScan org.gnome.Yelp
         org.gnome.gitlab.somas.Apostrophe org.freedesktop.MalcontentControl
         gnome-color-manager gufw htop timeshift preferences-system-network)
if [ "$(cat "$MAC/.versao" 2>/dev/null)" != "$MAC_VERSAO" ]; then
  W=/usr/share/icons/WhiteSur
  [ -d "$W/apps/scalable" ] || yay -S --needed --noconfirm whitesur-icon-theme
  sudo rm -rf "$MAC"
  sudo mkdir -p "$MAC/apps/scalable" "$MAC/places/scalable"
  for ic in "${COM_MAC[@]}"; do
    [ -e "$W/apps/scalable/$ic.svg" ] && sudo cp -L "$W/apps/scalable/$ic.svg" "$MAC/apps/scalable/"
  done
  sudo cp -L "$W/places/scalable/user-trash.svg" "$W/places/scalable/user-trash-full.svg" "$MAC/places/scalable/"
  sudo tee "$MAC/index.theme" >/dev/null <<'EOF'
[Icon Theme]
Name=MacApps
Comment=Alguns ícones de apps nativos estilo Mac (WhiteSur); o resto vem do Adwaita
Inherits=Adwaita,hicolor
Directories=apps/scalable,places/scalable

[apps/scalable]
Size=128
MinSize=8
MaxSize=512
Type=Scalable
Context=Applications

[places/scalable]
Size=64
MinSize=8
MaxSize=512
Type=Scalable
Context=Places
EOF
  echo "$MAC_VERSAO" | sudo tee "$MAC/.versao" >/dev/null
  sudo gtk-update-icon-cache -qf "$MAC" || true
fi
pacman -Q whitesur-icon-theme &>/dev/null && sudo pacman -Rns --noconfirm whitesur-icon-theme
# Cópia do ponteiro no home (versão antiga deste script) duplica o que o pacote já instalou
[ -d /usr/share/icons/macOS ] && rm -rf "$HOME/.local/share/icons/macOS" "$HOME/.local/share/icons/macOS-White"
for p in "${PKGS[@]}" whitesur-icon-theme; do rm -rf "$HOME/.cache/yay/$p"; done   # sem sobras de build

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
[ -d "$SD" ] || SD=/usr/share/glib-2.0/schemas   # versões novas do pacote usam o lugar padrão
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
