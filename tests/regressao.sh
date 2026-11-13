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

# 2026-11-13: o dconf load trocava os apps fixados no dock pelos do setup. Os da pessoa ficam.
checa "dock mantém os apps já fixados" bash -c '
  grep -B3 "dconf load / < \"\$REPO_DIR/gnome/configuracoes.ini\"" setup.sh | grep -q "FIXADOS_ANTES=" &&
  grep -q "antes + \[a for a in setup if a not in antes\]" setup.sh'

# 2026-11-13: o Monitor de Temperatura era fixado no dock sozinho. O setup só fixa apps
# nativos do GNOME; apps do repositório (local.*, io.github.*) nunca entram no dock sozinhos.
# 2026-11-13: o Calendário também não pode ser fixado sozinho.
# 2026-11-13: o Calendário também não pode ser fixado sozinho.
checa "dock sem apps do repositório nem Calendário fixados" bash -c '
  ! grep -E "^favorite-apps=" gnome/configuracoes.ini | grep -qE "local\.|io\.github\.|MonitorTemp|Calendar"'

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
for f in $(grep -oE '\$(REPO_DIR|E)/[A-Za-z0-9_./{},-]+' setup.sh | sort -u); do
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
