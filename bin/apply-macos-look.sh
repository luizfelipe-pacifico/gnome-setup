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
#    e sem copiar a Apple): Programas = sacola azul, Contatos, Clima,
#    Discos, Câmera, Extensões
#  - desenhos próprios no estilo da sacola do Programas (o quadrado é o próprio objeto, nada colado
#    em cima): Web (bússola sobre globo), Arquivos (gaveteiro), Vim (placa verde com o V) e
#    Vicinae (lua no céu escuro)
#  - Firefox: a raposa no globo de sempre, no azul do Developer Edition e sem moldura
#  - Calendário: ícone próprio com a data de hoje (icone-calendario, atualizado todo dia)
#  - pastas no estilo Mac dentro do Arquivos (Documentos, Downloads, Música, Imagens, Código...)
#  - lixeira clara no tema claro e escura no tema escuro (tema "MacApps-dark", que herda o MacApps)
#  - Relógios, Mapas, Configurações, Fontes, Logs, Papers e Apostrophe: ícone do GNOME
# Bateria, rede, volume, símbolos e apps de fora continuam como são. Só o código-fonte dos
# ícones (7,7 MB) é baixado, numa pasta temporária apagada no fim.
# Para mudar a escolha, edite as listas abaixo e aumente MAC_VERSAO.
MAC=/usr/local/share/icons/MacApps
MAC_VERSAO=13
if [ "$(cat "$MAC/.versao" 2>/dev/null)" != "$MAC_VERSAO" ]; then
  TMP=$(mktemp -d)
  curl -fsSL https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.tar.gz |
    tar xz -C "$TMP" --strip-components=1
  python3 -I - "$TMP" "$TMP/MacApps" <<'PY'
import os, re, shutil, sys

SRC, OUT = sys.argv[1:3]
MAC = ["org.gnome.Console", "org.gnome.SystemMonitor", "utilities-system-monitor", "org.gnome.tweaks",
       "org.gnome.Loupe", "org.gnome.Showtime", "org.gnome.Characters", "org.gnome.Connections",
       "org.gnome.Decibels", "org.gnome.SimpleScan", "org.gnome.Yelp", "org.gnome.Tour",
       "org.freedesktop.MalcontentControl", "gnome-color-manager", "htop", "timeshift",
       "preferences-system-network", "org.gnome.Calculator", "org.gnome.TextEditor", "org.gnome.Music"]
# App -> (pasta do WhiteSur, ícone): desenhos feitos para outros apps, no estilo Mac
TROCA = {"org.gnome.Software": ("alternative", "softwarecenter"),
         "org.gnome.Contacts": ("apps", "addressbook"),
         "org.gnome.Weather": ("apps", "indicator-weather"),
         "org.gnome.DiskUtility": ("apps", "gnome-disks"),
         "org.gnome.baobab": ("apps", "baobab"),
         "org.gnome.Snapshot": ("apps", "hu.irl.cameractrls"),
         "org.gnome.Extensions": ("apps", "extensions"),
         "com.mattjakeman.ExtensionManager": ("apps", "extensions")}
# Web: bússola sobre um globo, o quadrado é o próprio mostrador
WEB = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="fundo" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#5ec3ff"/><stop offset="1" stop-color="#1663e0"/>
    </linearGradient>
    <radialGradient id="luz" cx="0.3" cy="0.2" r="0.85">
      <stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="1" stop-color="#fff" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="vermelho" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#ff6b5e"/><stop offset="1" stop-color="#e0262b"/>
    </linearGradient>
    <linearGradient id="branco" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#dfe6ef"/>
    </linearGradient>
    <filter id="sombra" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="1.5" stdDeviation="2" flood-color="#000" flood-opacity="0.3"/>
    </filter>
    <filter id="leve" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="1.5" stdDeviation="1.5" flood-color="#06205a" flood-opacity="0.4"/>
    </filter>
    <clipPath id="forma"><rect x="8" y="8" width="112" height="112" rx="25"/></clipPath>
    <clipPath id="globo"><circle cx="64" cy="64" r="40"/></clipPath>
  </defs>
  <!-- mostrador azul -->
  <rect x="8" y="8" width="112" height="112" rx="25" fill="url(#fundo)" filter="url(#sombra)"/>
  <rect x="8" y="8" width="112" height="112" rx="25" fill="url(#luz)"/>
  <!-- marquinhas da bússola -->
  <g stroke="#fff" stroke-opacity="0.9" stroke-linecap="round">
    <line x1="64.0" y1="14.0" x2="64.0" y2="20.0" stroke-width="2.4"/><line x1="70.5" y1="14.4" x2="70.1" y2="17.4" stroke-width="1.4"/><line x1="76.9" y1="15.7" x2="76.2" y2="18.6" stroke-width="1.4"/><line x1="83.1" y1="17.8" x2="82.0" y2="20.6" stroke-width="1.4"/><line x1="89.0" y1="20.7" x2="87.5" y2="23.3" stroke-width="1.4"/><line x1="94.4" y1="24.3" x2="92.6" y2="26.7" stroke-width="1.4"/><line x1="99.4" y1="28.6" x2="95.1" y2="32.9" stroke-width="2.4"/><line x1="103.7" y1="33.6" x2="101.3" y2="35.4" stroke-width="1.4"/><line x1="107.3" y1="39.0" x2="104.7" y2="40.5" stroke-width="1.4"/><line x1="110.2" y1="44.9" x2="107.4" y2="46.0" stroke-width="1.4"/><line x1="112.3" y1="51.1" x2="109.4" y2="51.8" stroke-width="1.4"/><line x1="113.6" y1="57.5" x2="110.6" y2="57.9" stroke-width="1.4"/><line x1="114.0" y1="64.0" x2="108.0" y2="64.0" stroke-width="2.4"/><line x1="113.6" y1="70.5" x2="110.6" y2="70.1" stroke-width="1.4"/><line x1="112.3" y1="76.9" x2="109.4" y2="76.2" stroke-width="1.4"/><line x1="110.2" y1="83.1" x2="107.4" y2="82.0" stroke-width="1.4"/><line x1="107.3" y1="89.0" x2="104.7" y2="87.5" stroke-width="1.4"/><line x1="103.7" y1="94.4" x2="101.3" y2="92.6" stroke-width="1.4"/><line x1="99.4" y1="99.4" x2="95.1" y2="95.1" stroke-width="2.4"/><line x1="94.4" y1="103.7" x2="92.6" y2="101.3" stroke-width="1.4"/><line x1="89.0" y1="107.3" x2="87.5" y2="104.7" stroke-width="1.4"/><line x1="83.1" y1="110.2" x2="82.0" y2="107.4" stroke-width="1.4"/><line x1="76.9" y1="112.3" x2="76.2" y2="109.4" stroke-width="1.4"/><line x1="70.5" y1="113.6" x2="70.1" y2="110.6" stroke-width="1.4"/><line x1="64.0" y1="114.0" x2="64.0" y2="108.0" stroke-width="2.4"/><line x1="57.5" y1="113.6" x2="57.9" y2="110.6" stroke-width="1.4"/><line x1="51.1" y1="112.3" x2="51.8" y2="109.4" stroke-width="1.4"/><line x1="44.9" y1="110.2" x2="46.0" y2="107.4" stroke-width="1.4"/><line x1="39.0" y1="107.3" x2="40.5" y2="104.7" stroke-width="1.4"/><line x1="33.6" y1="103.7" x2="35.4" y2="101.3" stroke-width="1.4"/><line x1="28.6" y1="99.4" x2="32.9" y2="95.1" stroke-width="2.4"/><line x1="24.3" y1="94.4" x2="26.7" y2="92.6" stroke-width="1.4"/><line x1="20.7" y1="89.0" x2="23.3" y2="87.5" stroke-width="1.4"/><line x1="17.8" y1="83.1" x2="20.6" y2="82.0" stroke-width="1.4"/><line x1="15.7" y1="76.9" x2="18.6" y2="76.2" stroke-width="1.4"/><line x1="14.4" y1="70.5" x2="17.4" y2="70.1" stroke-width="1.4"/><line x1="14.0" y1="64.0" x2="20.0" y2="64.0" stroke-width="2.4"/><line x1="14.4" y1="57.5" x2="17.4" y2="57.9" stroke-width="1.4"/><line x1="15.7" y1="51.1" x2="18.6" y2="51.8" stroke-width="1.4"/><line x1="17.8" y1="44.9" x2="20.6" y2="46.0" stroke-width="1.4"/><line x1="20.7" y1="39.0" x2="23.3" y2="40.5" stroke-width="1.4"/><line x1="24.3" y1="33.6" x2="26.7" y2="35.4" stroke-width="1.4"/><line x1="28.6" y1="28.6" x2="32.9" y2="32.9" stroke-width="2.4"/><line x1="33.6" y1="24.3" x2="35.4" y2="26.7" stroke-width="1.4"/><line x1="39.0" y1="20.7" x2="40.5" y2="23.3" stroke-width="1.4"/><line x1="44.9" y1="17.8" x2="46.0" y2="20.6" stroke-width="1.4"/><line x1="51.1" y1="15.7" x2="51.8" y2="18.6" stroke-width="1.4"/><line x1="57.5" y1="14.4" x2="57.9" y2="17.4" stroke-width="1.4"/>
  </g>
  <!-- globo suave no meio -->
  <g clip-path="url(#globo)" fill="none" stroke="#fff" stroke-opacity="0.45" stroke-width="2.2">
    <circle cx="64" cy="64" r="39"/>
    <ellipse cx="64" cy="64" rx="17" ry="40"/>
    <line x1="64" y1="24" x2="64" y2="104"/>
    <line x1="24" y1="64" x2="104" y2="64"/>
    <path d="M28 46 Q64 55 100 46"/><path d="M28 82 Q64 73 100 82"/>
  </g>
  <!-- agulha vermelha e branca, com as pontas arredondadas -->
  <g filter="url(#leve)" stroke-linejoin="round" stroke-width="3">
    <path d="M90 38 L69 69 L59 59 Z" fill="url(#vermelho)" stroke="url(#vermelho)"/>
    <path d="M38 90 L59 59 L69 69 Z" fill="url(#branco)" stroke="url(#branco)"/>
  </g>
  <circle cx="64" cy="64" r="3.5" fill="#fff"/>
</svg>
"""
# Arquivos: o quadrado é um gaveteiro, com uma folha saindo da gaveta de cima
ARQUIVOS = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="fundo" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#5aaefc"/><stop offset="1" stop-color="#2b82f0"/>
    </linearGradient>
    <filter id="sombra" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="1.5" stdDeviation="2" flood-color="#000" flood-opacity="0.3"/>
    </filter>
    <filter id="leve" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="1" stdDeviation="1" flood-color="#000" flood-opacity="0.25"/>
    </filter>
    <clipPath id="forma"><rect x="8" y="8" width="112" height="112" rx="25"/></clipPath>
  </defs>
  <rect x="8" y="8" width="112" height="112" rx="25" fill="url(#fundo)" filter="url(#sombra)"/>
  <g clip-path="url(#forma)">
    <rect x="8" y="66" width="112" height="54" fill="#1f6fd8" opacity="0.35"/>
    <rect x="8" y="64" width="112" height="3" fill="#fff" opacity="0.35"/>
  </g>
  <rect x="40" y="18" width="48" height="34" rx="5" fill="#fff" filter="url(#leve)"/>
  <rect x="48" y="25" width="22" height="3" rx="1.5" fill="#9cc3f5"/>
  <rect x="48" y="31" width="30" height="3" rx="1.5" fill="#9cc3f5"/>
  <path d="M8 40 H120 V64 H8 Z" fill="url(#fundo)" clip-path="url(#forma)"/>
  <rect x="34" y="37" width="60" height="6" rx="3" fill="#174fa8" opacity="0.6"/>
  <rect x="50" y="50" width="28" height="8" rx="4" fill="#fff" filter="url(#leve)"/>
  <rect x="50" y="88" width="28" height="8" rx="4" fill="#fff" filter="url(#leve)"/>
</svg>
"""
# Vim: o quadrado é a placa verde com o V
VIM = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="fundo" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#43c46c"/><stop offset="1" stop-color="#178a45"/>
    </linearGradient>
    <filter id="sombra" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="1.5" stdDeviation="2" flood-color="#000" flood-opacity="0.3"/>
    </filter>
    <filter id="leve" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="1" stdDeviation="1" flood-color="#000" flood-opacity="0.25"/>
    </filter>
    <clipPath id="forma"><rect x="8" y="8" width="112" height="112" rx="25"/></clipPath>
    <linearGradient id="letra" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#dfe9e3"/>
    </linearGradient>
  </defs>
  <rect x="8" y="8" width="112" height="112" rx="25" fill="url(#fundo)" filter="url(#sombra)"/>
  <g clip-path="url(#forma)">
    <path d="M8 64 L64 8 L120 64 L64 120 Z" fill="#fff" opacity="0.1"/>
  </g>
  <path d="M38 34 H56 L64 70 L73 34 H90 L71 94 H57 Z" fill="url(#letra)" stroke="url(#letra)"
        stroke-width="6" stroke-linejoin="round" filter="url(#leve)"/>
</svg>
"""
# Vicinae: o quadrado é o céu escuro com a lua crescente
VICINAE = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="fundo" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#3a3a42"/><stop offset="1" stop-color="#121216"/>
    </linearGradient>
    <filter id="sombra" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="1.5" stdDeviation="2" flood-color="#000" flood-opacity="0.3"/>
    </filter>
    <filter id="leve" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="1" stdDeviation="1" flood-color="#000" flood-opacity="0.25"/>
    </filter>
    <clipPath id="forma"><rect x="8" y="8" width="112" height="112" rx="25"/></clipPath>
    <linearGradient id="lua" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#d4d7e0"/>
    </linearGradient>
    <mask id="crescente">
      <circle cx="64" cy="64" r="38" fill="#fff"/>
      <circle cx="50" cy="60" r="31" fill="#000"/>
    </mask>
  </defs>
  <rect x="8" y="8" width="112" height="112" rx="25" fill="url(#fundo)" filter="url(#sombra)"/>
  <circle cx="64" cy="64" r="38" fill="url(#lua)" mask="url(#crescente)" filter="url(#leve)"/>
</svg>
"""
# Firefox: a raposa no globo, no azul do Developer Edition (logo do WhiteSur sem a moldura branca)
FIREFOX = ["firefox", "firefox-developer-edition", "org.mozilla.firefox"]
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
with open(f"{OUT}/apps/scalable/org.gnome.Nautilus.svg", "w") as f:
    f.write(ARQUIVOS)
for name, svg in (("gvim", VIM), ("vim", VIM), ("vicinae", VICINAE)):
    with open(f"{OUT}/apps/scalable/{name}.svg", "w") as f:
        f.write(svg)
if path := whitesur("apps", "firefox-developer-edition"):
    with open(path) as f:
        logo = f.read()
    fim = logo.index("</defs>") + 7
    corpo = re.sub(r"<image\b[^>]*/>", "", logo[fim:], count=1)          # sombra da moldura
    corpo = re.sub(r'<rect width="14.817"[^>]*/>', "", corpo, count=1)    # moldura branca
    c = 8.4665  # centro do desenho: a logo cresce um pouco para ocupar o lugar da moldura
    logo = (logo[:fim] + f'<g transform="translate({c} {c}) scale(1.18) translate({-c} {-c})">'
            + corpo[:corpo.rindex("</svg>")] + "</g></svg>")
    for name in FIREFOX:
        with open(f"{OUT}/apps/scalable/{name}.svg", "w") as f:
            f.write(logo)
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
