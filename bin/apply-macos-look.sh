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

# Ícones de apps nativos num tema "MacApps" pequeno (alguns KB), que herda o Adwaita:
#  - estilo Mac (WhiteSur): Console, Monitor, Calculadora, Editor de Texto, Lixeira e outros
#  - Arquivos e Programas: versões alternativas do WhiteSur (pasta e sacola azuis, sem Finder/App Store)
#  - Web, Calendário, Música, Mapas, Configurações e os demais: o próprio ícone do GNOME numa base
#    arredondada no formato do Mac (combina sem copiar os apps da Apple)
# Bateria, rede, volume, símbolos e apps de fora continuam como são. Só o código-fonte dos
# ícones (7,7 MB) é baixado, numa pasta temporária apagada no fim.
# Para mudar a escolha, edite as listas abaixo e aumente MAC_VERSAO.
MAC=/usr/local/share/icons/MacApps
MAC_VERSAO=4
if [ "$(cat "$MAC/.versao" 2>/dev/null)" != "$MAC_VERSAO" ]; then
  TMP=$(mktemp -d)
  curl -fsSL https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.tar.gz |
    tar xz -C "$TMP" --strip-components=1
  python3 -I - "$TMP" "$TMP/MacApps" <<'PY'
import base64, os, shutil, sys

SRC, OUT = sys.argv[1:3]
MAC = ["org.gnome.Console", "org.gnome.SystemMonitor", "utilities-system-monitor", "org.gnome.tweaks",
       "org.gnome.Loupe", "org.gnome.Showtime", "org.gnome.Characters", "org.gnome.Connections",
       "org.gnome.Decibels", "org.gnome.SimpleScan", "org.gnome.Yelp", "org.gnome.Tour",
       "org.freedesktop.MalcontentControl", "gnome-color-manager", "gufw", "htop", "timeshift",
       "preferences-system-network", "org.gnome.Calculator", "org.gnome.TextEditor"]
ALTERNATIVO = {"org.gnome.Nautilus": "file-manager", "org.gnome.Software": "softwarecenter"}
BASE_MAC = ["org.gnome.Epiphany", "org.gnome.Calendar", "org.gnome.clocks", "org.gnome.Contacts",
            "org.gnome.Maps", "org.gnome.Music", "org.gnome.Weather", "org.gnome.Settings",
            "org.gnome.DiskUtility", "org.gnome.baobab", "org.gnome.font-viewer", "org.gnome.Logs",
            "org.gnome.Papers", "org.gnome.Snapshot", "org.gnome.Extensions",
            "com.mattjakeman.ExtensionManager"]
LIXEIRA = ["user-trash", "user-trash-full"]


def whitesur(kind, name):
    """Segue os links do WhiteSur (links/ -> links/ -> src/) até o arquivo real."""
    for _ in range(10):
        link = f"{SRC}/links/{kind}/scalable/{name}.svg"
        if not os.path.islink(link):
            break
        name = os.path.basename(os.readlink(link))[:-4]
    path = f"{SRC}/src/{kind}/scalable/{name}.svg"
    return path if os.path.isfile(path) else None


def base_mac(icon):
    data = base64.b64encode(open(icon, "rb").read()).decode()
    return f"""<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="b" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#e4e7ee"/>
    </linearGradient>
    <filter id="s" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="1.5" stdDeviation="2" flood-color="#1a2440" flood-opacity="0.28"/>
    </filter>
  </defs>
  <rect x="8" y="8" width="112" height="112" rx="25" fill="url(#b)" filter="url(#s)"/>
  <rect x="8.5" y="8.5" width="111" height="111" rx="24.5" fill="none" stroke="#000" stroke-opacity="0.06"/>
  <image x="20" y="20" width="88" height="88" xlink:href="data:image/svg+xml;base64,{data}"/>
</svg>
"""


os.makedirs(f"{OUT}/apps/scalable")
os.makedirs(f"{OUT}/places/scalable")
for name in MAC:
    if path := whitesur("apps", name):
        shutil.copy(path, f"{OUT}/apps/scalable/{name}.svg")
for name, alt in ALTERNATIVO.items():
    path = f"{SRC}/alternative/apps/scalable/{alt}.svg"
    if os.path.isfile(path):
        shutil.copy(path, f"{OUT}/apps/scalable/{name}.svg")
for name in BASE_MAC:
    gnome = f"/usr/share/icons/hicolor/scalable/apps/{name}.svg"
    if os.path.isfile(gnome):
        with open(f"{OUT}/apps/scalable/{name}.svg", "w") as f:
            f.write(base_mac(gnome))
for name in LIXEIRA:
    if path := whitesur("places", name):
        shutil.copy(path, f"{OUT}/places/scalable/{name}.svg")
PY
  cat > "$TMP/MacApps/index.theme" <<'EOF'
[Icon Theme]
Name=MacApps
Comment=Ícones de apps nativos no formato do Mac; o resto vem do Adwaita
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
  echo "$MAC_VERSAO" > "$TMP/MacApps/.versao"
  sudo rm -rf "$MAC"
  sudo cp -r "$TMP/MacApps" "$MAC"
  sudo gtk-update-icon-cache -qf "$MAC" || true
  rm -rf "$TMP"
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
