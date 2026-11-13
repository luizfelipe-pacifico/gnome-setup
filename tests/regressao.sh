#!/usr/bin/env bash
# Testes de regressão: cada erro já resolvido vira uma checagem aqui, para nunca voltar.
# Rodam sozinhos antes de cada push (.githooks/pre-push) e no GitHub Actions.
#   bash tests/regressao.sh
set -uo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

falhas=0
passou() { echo "  ok   $*"; }
falhou() { echo "  FALHA $*"; falhas=$((falhas + 1)); }
checa() { local nome=$1; shift; if "$@"; then passou "$nome"; else falhou "$nome"; fi; }

# Scripts em bash que o instalador roda (pessoal/ não é instalado e fica de fora)
mapfile -t SCRIPTS < <(
  { ls instalar.sh estilo.sh setup.sh
    grep -lE '^#!.*\b(ba)?sh\b' bin/* ; } | sort -u)
INSTALADOS=(instalar.sh estilo.sh setup.sh bin/* gnome/* applications/* sistema -r)

echo "== Sintaxe"
for f in "${SCRIPTS[@]}"; do checa "bash -n $f" bash -n "$f"; done
for f in $(grep -lE '^#!.*python' bin/*); do
  checa "python compila $f" python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$f"
done
if command -v shellcheck >/dev/null; then
  for f in "${SCRIPTS[@]}"; do checa "shellcheck (erros) $f" shellcheck -S error "$f"; done
fi

echo "== Erros já resolvidos"
# 2026-11-12: "yay --save" sem operação roda "yay -Syu" escondido e a instalação travava
# logo depois de "Instalando o yay". Toda chamada de --save precisa de uma operação (-Y).
checa "yay --save sempre com -Y" \
  bash -c '! grep -rnE "^[^#]*yay[[:space:]]+--save" setup.sh bin/ instalar.sh estilo.sh'

# Chamadas ao yay/pacman com saída escondida não podem esperar resposta do teclado
checa "yay/pacman escondidos usam --noconfirm ou -Y" bash -c '
  ! grep -nE "^[[:space:]]*(sudo[[:space:]]+)?(yay|pacman)[[:space:]][^|#]*>/dev/null" setup.sh bin/* |
    grep -vE -- "--noconfirm|-Y|-Q|-Sl|--version" | grep .'

# 2026-11-12: "systemd-detect-virt || echo none" imprimia "none" duas vezes fora de VM
checa "VIRT sem none duplicado" bash -c '! grep -nE "systemd-detect-virt[^|]*\|\|[[:space:]]*echo" setup.sh'

# 2026-11-13: rodar o setup de novo (para atualizar) recriava o atalho e a escolha de
# aparência abria outra vez. O atalho só é criado se a escolha inicial nunca foi feita.
checa "escolha de aparência só uma vez" bash -c '
  grep -q "escolha-inicial-feita" setup.sh &&
  grep -B3 "escolher-tema.desktop\" <<" setup.sh | grep -q "ESCOLHA_FEITA"'

# 2026-11-13: o setup trocava os apps fixados no dock e fixava sozinho o Monitor de
# Temperatura e o Calendário. O dock é escolha de cada pessoa: o setup nunca escreve nele.
checa "setup nunca mexe nos apps fixados no dock" bash -c '
  ! grep -rnE "favorite-apps|favorite_apps" gnome/ setup.sh instalar.sh estilo.sh bin/ sistema/'

# 2026-11-13: o reinício no fim falhava com outra conta logada ("User X is logged in on tty2").
# Se o reboot normal falhar, força (reboot -i), reiniciando mesmo com outras contas logadas.
checa "reinício força com outra conta logada" bash -c '
  grep -qE "systemctl reboot 2>/dev/null \|\| systemctl reboot -i" setup.sh &&
  ! grep -nE "^[^#]*&&[[:space:]]*systemctl reboot[[:space:]]*$|^[[:space:]]*systemctl reboot[[:space:]]*$" setup.sh'

# 2026-11-13: papéis de parede também em ~/wallpapers (setup e estilo.sh), sem sobrescrever
# os arquivos da pessoa; todo .jpg do repositório aparece em Configurações → Aparência
checa "papéis de parede copiados para ~/wallpapers sem sobrescrever" bash -c '
  grep -q "cp -n \"\$REPO_DIR\"/wallpapers/\*.jpg \"\$HOME/wallpapers/\"" setup.sh &&
  grep -q "cp -n wallpapers/\*.jpg \"\$HOME/wallpapers/\"" bin/instalar-seletor-de-tema'
for w in wallpapers/*.jpg; do
  checa "$(basename "$w") listado na Aparência do GNOME" \
    grep -q "/$(basename "$w")<" sistema/usr/share/gnome-background-properties/seletor-de-tema.xml
done
for f in $(grep -oE "seletor-de-tema/[^<]+\.jpg" sistema/usr/share/gnome-background-properties/seletor-de-tema.xml); do
  checa "existe wallpapers/${f#seletor-de-tema/}" test -f "wallpapers/${f#seletor-de-tema/}"
done
checa "papéis de parede em 4K" bash -c '
  for w in wallpapers/*.jpg; do
    python3 -c "import struct,sys
d=open(sys.argv[1],\"rb\").read(); i=2
while i<len(d):
    m=d[i+1]; L=struct.unpack(\">H\",d[i+2:i+4])[0]
    if m in (0xC0,0xC1,0xC2):
        h,w=struct.unpack(\">HH\",d[i+5:i+9]); sys.exit(0 if w>=3840 and h>=2152 else 1)
    i+=2+L
sys.exit(1)" "$w" || { echo "  pequeno: $w"; exit 1; }
  done'

# 2026-11-13: Upscale 4K (Imagens → ☰ → Abrir com… → Upscale 4K)
checa "Upscale 4K instalado pelo setup" bash -c '
  grep -q "upscale-4k)" setup.sh && grep -q "local.gnomesetup.Upscale; do" setup.sh &&
  grep -qE "^[[:space:]]+imagemagick\)" setup.sh'
checa "Upscale 4K aparece em Abrir com… para imagens" bash -c '
  f=applications/local.gnomesetup.Upscale.desktop
  grep -q "^MimeType=.*image/jpeg;.*image/png;" $f && grep -q "^Exec=/usr/local/bin/upscale-4k %F" $f &&
  ! grep -q "^NoDisplay=true" $f'
if command -v magick >/dev/null; then
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  magick -size 640x360 gradient:navy-orange "$T/foto pequena.png"
  magick -size 3840x2160 xc:gray "$T/grande.jpg"
  cp "$T/foto pequena.png" "$T/original.png"
  UPSCALE_SILENCIOSO=1 bin/upscale-4k "$T/foto pequena.png" "$T/grande.jpg" >/dev/null 2>&1
  checa "Upscale 4K gera nome-4k.jpg com 3840×2160" \
    bash -c '[ "$(magick identify -format %wx%h "$1")" = 3840x2160 ]' _ "$T/foto pequena-4k.jpg"
  checa "Upscale 4K não mexe na original" cmp -s "$T/foto pequena.png" "$T/original.png"
  checa "Upscale 4K pula imagem que já é 4K" test ! -e "$T/grande-4k.jpg"
  magick -size 400x800 xc:white "$T/retrato.png"
  UPSCALE_SILENCIOSO=1 bin/upscale-4k "$T/retrato.png" >/dev/null 2>&1
  checa "Upscale 4K não corta foto em pé" \
    bash -c '[ "$(magick identify -format %wx%h "$1")" = 2160x4320 ]' _ "$T/retrato-4k.jpg"
fi

# 2026-11-13: o aparencia-todos-usuarios roda da cópia em /usr/local/bin e procurava as
# extensões em /usr/local/extensoes: widgets e seleção limpa nunca iam para o sistema e não
# ligavam nas outras contas. Quem chama passa a pasta do repositório; sem ela, para com erro.
checa "aparencia-todos-usuarios usa GNOME_SETUP_DIR" grep -q 'REPO_DIR="${GNOME_SETUP_DIR:-' bin/aparencia-todos-usuarios
checa "aparencia-todos-usuarios para sem as extensões" grep -qE '\[ -d "\$REPO_DIR/extensoes" \] \|\|.*exit 1' bin/aparencia-todos-usuarios
for f in setup.sh bin/instalar-seletor-de-tema; do
  checa "$f passa GNOME_SETUP_DIR ao aparencia-todos-usuarios" bash -c '
    ! grep -E "^[^#]*/usr/local/bin/aparencia-todos-usuarios" "$1" | grep -v GNOME_SETUP_DIR= | grep -q .' _ "$f"
done
T=$(mktemp -d); mkdir "$T/bin"; cp bin/aparencia-todos-usuarios "$T/bin/"
checa "cópia instalada sem o repositório para antes de instalar" \
  bash -c '! env -u GNOME_SETUP_DIR PATH=/nada /usr/bin/bash "$1/bin/aparencia-todos-usuarios" 2>/dev/null' _ "$T"
rm -rf "$T"

echo "== Serve para qualquer pessoa"
# Navegador é escolha de cada um: o setup não instala nenhum
checa "nenhum navegador instalado" bash -c '
  ! grep -nwE "firefox|firefox-developer-edition|epiphany|chromium|google-chrome|brave-bin|vivaldi|librewolf|zen-browser-bin" \
    <(grep -hvE "^[[:space:]]*#" setup.sh bin/instalar-seletor-de-tema bin/apply-macos-look.sh |
      grep -E "pacman -S|yay -S|^[[:space:]]+[a-z0-9-]+( |$)|GNOME_APPS|SISTEMA|PKGS|DRV")'
# Nada com o caminho da minha pasta pessoal, usuário ou contas
checa "sem /home/<usuário> fixo" bash -c '! grep -rnE "/home/[a-z]" "${@}" --exclude-dir=pessoal' _ \
  setup.sh instalar.sh estilo.sh bin gnome applications sistema extensoes
checa "sem dados pessoais (e-mail, tokens, chaves)" bash -c '
  ! grep -rniE "[a-z0-9._-]+@(gmail|cnpjotas|hotmail|outlook)\.|ghp_[A-Za-z0-9]|BEGIN [A-Z ]*PRIVATE KEY|authorized_keys|git config --global" \
    setup.sh instalar.sh estilo.sh bin gnome applications sistema extensoes'
checa "pessoal/ não é instalado" bash -c '! grep -nE "pessoal/" setup.sh instalar.sh estilo.sh bin/*'
checa "configurações sem papel de parede de /home" bash -c '! grep -nE "file:///home" gnome/configuracoes.ini'

echo "== Arquivos que o setup copia existem"
for f in $(grep -hoE '\$(REPO_DIR|E)/[A-Za-z0-9_./{},-]+' setup.sh bin/aparencia-todos-usuarios | sort -u); do
  f=${f/\$REPO_DIR\//}; f=${f/\$E\//sistema/etc/}
  [[ $f == */ || ( $f == *'}'* && $f != *'{'* ) ]] && continue   # expansões como ${APPS[@]/#/...}
  for g in $(eval echo "$f"); do
    [[ $g == *'*'* ]] && { compgen -G "$g" >/dev/null && passou "existe $g" || falhou "existe $g"; continue; }
    checa "existe $g" test -e "$g"
  done
done

echo
if [ "$falhas" -gt 0 ]; then echo "$falhas teste(s) falharam."; exit 1; fi
echo "Todos os testes passaram."
