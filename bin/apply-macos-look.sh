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
#  - outros nativos com ícones coloridos do WhiteSur feitos para apps parecidos (sem moldura branca
#    e sem copiar a Apple): Arquivos = pasta com casinha, Programas = sacola azul, Contatos, Clima,
#    Discos, Câmera, Extensões; Web ganha um globo próprio no formato do Mac
#  - Calendário: ícone próprio com a data de hoje (icone-calendario, atualizado todo dia)
#  - pastas no estilo Mac dentro do Arquivos (Documentos, Downloads, Música, Imagens, Código...)
#  - lixeira clara no tema claro e escura no tema escuro (tema "MacApps-dark", que herda o MacApps)
#  - Relógios, Mapas, Configurações, Fontes, Logs, Papers e Apostrophe: ícone do GNOME
# Bateria, rede, volume, símbolos e apps de fora continuam como são. Só o código-fonte dos
# ícones (7,7 MB) é baixado, numa pasta temporária apagada no fim.
# Para mudar a escolha, edite as listas abaixo e aumente MAC_VERSAO.
MAC=/usr/local/share/icons/MacApps
MAC_VERSAO=7
if [ "$(cat "$MAC/.versao" 2>/dev/null)" != "$MAC_VERSAO" ]; then
  TMP=$(mktemp -d)
  curl -fsSL https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.tar.gz |
    tar xz -C "$TMP" --strip-components=1
  python3 -I - "$TMP" "$TMP/MacApps" <<'PY'
import os, shutil, sys

SRC, OUT = sys.argv[1:3]
MAC = ["org.gnome.Console", "org.gnome.SystemMonitor", "utilities-system-monitor", "org.gnome.tweaks",
       "org.gnome.Loupe", "org.gnome.Showtime", "org.gnome.Characters", "org.gnome.Connections",
       "org.gnome.Decibels", "org.gnome.SimpleScan", "org.gnome.Yelp", "org.gnome.Tour",
       "org.freedesktop.MalcontentControl", "gnome-color-manager", "gufw", "htop", "timeshift",
       "preferences-system-network", "org.gnome.Calculator", "org.gnome.TextEditor", "org.gnome.Music"]
# App -> (pasta do WhiteSur, ícone): desenhos feitos para outros apps, no estilo Mac
TROCA = {"org.gnome.Nautilus": ("places", "user-home"),
         "org.gnome.Software": ("alternative", "softwarecenter"),
         "org.gnome.Contacts": ("apps", "addressbook"),
         "org.gnome.Weather": ("apps", "indicator-weather"),
         "org.gnome.DiskUtility": ("apps", "gnome-disks"),
         "org.gnome.baobab": ("apps", "baobab"),
         "org.gnome.Snapshot": ("apps", "hu.irl.cameractrls"),
         "org.gnome.Extensions": ("apps", "extensions"),
         "com.mattjakeman.ExtensionManager": ("apps", "extensions")}
# Web: globo branco num quadrado azul arredondado (desenho próprio, sem a bússola do Safari)
WEB = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="fundo" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#5ac8fa"/><stop offset="1" stop-color="#1e6fe0"/>
    </linearGradient>
    <radialGradient id="luz" cx="0.35" cy="0.25" r="0.75">
      <stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="1" stop-color="#fff" stop-opacity="0"/>
    </radialGradient>
    <filter id="sombra" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="1.5" stdDeviation="2" flood-color="#0b2350" flood-opacity="0.35"/>
    </filter>
    <clipPath id="globo"><circle cx="64" cy="64" r="36"/></clipPath>
  </defs>
  <rect x="8" y="8" width="112" height="112" rx="25" fill="url(#fundo)" filter="url(#sombra)"/>
  <rect x="8" y="8" width="112" height="112" rx="25" fill="url(#luz)"/>
  <g fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" filter="url(#sombra)">
    <circle cx="64" cy="64" r="36"/>
    <g clip-path="url(#globo)">
      <ellipse cx="64" cy="64" rx="15" ry="36"/>
      <line x1="64" y1="28" x2="64" y2="100"/>
      <line x1="28" y1="64" x2="100" y2="64"/>
      <path d="M33 46 Q64 54 95 46"/>
      <path d="M33 82 Q64 74 95 82"/>
    </g>
  </g>
</svg>
"""
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


os.makedirs(f"{OUT}/apps/scalable")
os.makedirs(f"{OUT}/places/scalable")
for name in MAC:
    if path := whitesur("apps", name):
        shutil.copy(path, f"{OUT}/apps/scalable/{name}.svg")
for name, (pasta, icone) in TROCA.items():
    path = (f"{SRC}/alternative/apps/scalable/{icone}.svg" if pasta == "alternative"
            else whitesur(pasta, icone))
    if path and os.path.isfile(path):
        shutil.copy(path, f"{OUT}/apps/scalable/{name}.svg")
with open(f"{OUT}/apps/scalable/org.gnome.Epiphany.svg", "w") as f:
    f.write(WEB)
for name in LIXEIRA:
    if path := whitesur("places", name):
        shutil.copy(path, f"{OUT}/places/scalable/{name}.svg")
# Tema escuro: só troca a lixeira pela versão escura; o resto vem do MacApps
ESCURO = OUT + "-dark"
os.makedirs(f"{ESCURO}/places/scalable")
for name in LIXEIRA:
    if path := whitesur("places", f"{name}-dark"):
        shutil.copy(path, f"{ESCURO}/places/scalable/{name}.svg")
with open(f"{ESCURO}/index.theme", "w") as f:
    f.write("[Icon Theme]\nName=MacApps-dark\nComment=MacApps com a lixeira escura\n"
            "Inherits=MacApps,Adwaita,hicolor\nDirectories=places/scalable\n\n"
            "[places/scalable]\nSize=64\nMinSize=8\nMaxSize=512\nType=Scalable\nContext=Places\n")
# Pastas coloridas do Mac (os ícones simbólicos da barra lateral continuam os do GNOME)
nomes = {f[:-4] for d in ("src", "links") for f in os.listdir(f"{SRC}/{d}/places/scalable")
         if f.endswith(".svg")}
for name in sorted(nomes):
    if "symbolic" in name or not (name.startswith("folder") or
                                  name in ("user-desktop", "user-home", "user-bookmarks",
                                           "network-workgroup")):
        continue
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
  sudo rm -rf "$MAC" "$MAC-dark"
  sudo cp -r "$TMP/MacApps" "$MAC"
  sudo cp -r "$TMP/MacApps-dark" "$MAC-dark"
  sudo gtk-update-icon-cache -qf "$MAC" || true
  sudo gtk-update-icon-cache -qf "$MAC-dark" || true
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
