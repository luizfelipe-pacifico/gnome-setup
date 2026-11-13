#!/usr/bin/env bash
# Deixa um GNOME recém-instalado (Arch Linux ou derivados) igual ao meu setup:
# pacman colorido e rápido, yay, drivers certos para a CPU/GPU, ajustes de desempenho,
# apps nativos do GNOME, extensões, meus apps (monitor, aparência, zram...) e configurações.
# Rode como seu usuário (sem sudo). Pode rodar de novo para atualizar: só faz o que falta.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
LOG="$HOME/.cache/gnome-setup-instalacao.log"
mkdir -p "$(dirname "$LOG")"
# Grava o log pelo "script", que mantém o terminal: com "tee" o pacman acha que não está num
# terminal e esconde as barras de progresso (a do Pac-Man inclusive)
if [ -z "${GNOME_SETUP_NO_SCRIPT:-}" ] && [ -t 1 ] && command -v script >/dev/null; then
  export GNOME_SETUP_NO_SCRIPT=1
  exec script -qefa -c "$(printf '%q ' bash "$(readlink -f "$0")" "$@")" "$LOG"
fi
[ -t 1 ] || exec > >(tee -a "$LOG") 2>&1

azul=$'\e[1;34m'; verde=$'\e[1;32m'; amarelo=$'\e[1;33m'; vermelho=$'\e[1;31m'; fim=$'\e[0m'
etapa() { echo; echo "${azul}==>${fim} $*"; }
ok()    { echo "  ${verde}✓${fim} $*"; }
aviso() { echo "  ${amarelo}!${fim} $*"; }
erro()  { echo "${vermelho}Erro:${fim} $*"; exit 1; }

[ "$EUID" -eq 0 ] && erro "rode como seu usuário, sem sudo (o yay não roda como root)."
command -v pacman >/dev/null || erro "este script é para Arch Linux e derivados (precisa do pacman)."

etapa "Pedindo a senha de administrador uma vez"
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &

# ---------------------------------------------------------------- hardware
etapa "Lendo o hardware"
ARCH=$(uname -m)
CPU_VENDOR=$(grep -m1 -oP '^vendor_id\s*:\s*\K.*' /proc/cpuinfo || true)
CPU_NOME=$(grep -m1 -oP '^model name\s*:\s*\K.*' /proc/cpuinfo ||
           tr -d '\0' 2>/dev/null < /sys/firmware/devicetree/base/model || echo "$ARCH")
case "$CPU_VENDOR" in
  GenuineIntel) CPU=intel ;;
  AuthenticAMD) CPU=amd ;;
  *) if grep -qi qcom /sys/firmware/devicetree/base/compatible 2>/dev/null ||
        grep -q 'CPU implementer.*0x51' /proc/cpuinfo; then CPU=qualcomm; else CPU=outro; fi ;;
esac
sudo pacman -S --needed --noconfirm pciutils >/dev/null
GPUS=$(lspci -nn 2>/dev/null | grep -E '\[03(00|02|80)\]' || true)
tem_gpu() { grep -qi "\[$1:" <<<"$GPUS"; }
NVIDIA_IDS=$(grep -oiP '\[10de:\K[0-9a-f]{4}' <<<"$GPUS" || true)
LAPTOP=$(ls /sys/class/power_supply/BAT* >/dev/null 2>&1 && echo sim || echo não)
# systemd-detect-virt imprime "none" e sai com erro fora de VM: não somar outro "none"
VIRT=$(systemd-detect-virt 2>/dev/null || true); VIRT=${VIRT:-none}
RAM_GB=$(awk '/MemTotal/ { printf "%.0f", $2 / 1048576 }' /proc/meminfo)
MULTILIB=$([ "$ARCH" = x86_64 ] && echo sim || echo não)
ok "CPU: $CPU_NOME ($CPU, $ARCH, $(nproc) núcleos)"
while read -r g; do [ -n "$g" ] && ok "GPU: ${g#*: }"; done <<<"$GPUS"
ok "RAM: ${RAM_GB} GB · notebook: $LAPTOP · máquina virtual: $VIRT"

# ---------------------------------------------------------------- pacman
etapa "Configurando o pacman (cores, downloads paralelos, multilib)"
PC=/etc/pacman.conf
sudo cp -n "$PC" "$PC.antes-gnome-setup" || true
sudo sed -i 's/^#Color/Color/; s/^#VerbosePkgLists/VerbosePkgLists/' "$PC"
sudo sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' "$PC"
grep -q '^ILoveCandy' "$PC" || sudo sed -i '/^Color/a ILoveCandy' "$PC"
if [ "$MULTILIB" = sim ] && ! grep -q '^\[multilib\]' "$PC"; then
  sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' "$PC"
fi
ok "pacman com cor, barra de progresso Pac-Man e 10 downloads ao mesmo tempo"
# Antes de instalar: o pacman não extrai as partes repetidas do que vamos colocar (menos SSD)
sudo "$REPO_DIR/bin/enxugar-sistema" | tail -1

# Espelhos escolhidos há menos de 7 dias continuam bons: quem roda de novo não espera o reflector
if [ "$ARCH" = x86_64 ] && grep -q '^Server.*archlinux' /etc/pacman.d/mirrorlist 2>/dev/null &&
   [ -z "$(find /etc/pacman.d/mirrorlist -mtime -7 2>/dev/null)" ]; then
  etapa "Escolhendo os espelhos mais rápidos"
  sudo pacman -S --needed --noconfirm reflector >/dev/null
  echo "  testando a velocidade dos espelhos (até 3 minutos, sem mostrar nada na tela)..."
  sudo cp -n /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.antes-gnome-setup || true
  if sudo timeout 180 reflector --latest 20 --protocol https --sort rate --download-timeout 3 \
       --save /etc/pacman.d/mirrorlist 2>/dev/null; then ok "espelhos atualizados"
  else aviso "reflector demorou ou falhou, mantendo os espelhos atuais"; fi
fi

etapa "Atualizando o sistema"
sudo pacman -Syu --noconfirm

# Instala só o que existe nos repositórios (nomes mudam entre Arch, Arch ARM e derivados)
DISPONIVEIS=$(pacman -Slq | sort -u)
instalar() {
  local quer=() p
  for p in "$@"; do grep -qxF "$p" <<<"$DISPONIVEIS" && quer+=("$p") || aviso "pacote $p não existe aqui, pulando"; done
  [ ${#quer[@]} -gt 0 ] && sudo pacman -S --needed --noconfirm "${quer[@]}"
  return 0
}

# ---------------------------------------------------------------- yay
etapa "Instalando o yay (para pacotes do AUR)"
instalar base-devel git
if ! command -v yay >/dev/null; then
  TMP=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$TMP/yay-bin"
  (cd "$TMP/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$TMP"
fi
# Precisa de uma operação (-Y): "yay --save" sozinho vira "yay -Syu" escondido e trava esperando resposta
yay -Y --save --answerdiff None --answerclean None --removemake </dev/null >/dev/null 2>&1 || true
ok "yay $(yay --version | awk '{print $2}')"
sudo install -Dm644 "$REPO_DIR/sistema/etc/makepkg.conf.d/90-paralelo.conf" /etc/makepkg.conf.d/90-paralelo.conf
ok "pacotes do AUR compilam com os $(nproc) núcleos"

# ---------------------------------------------------------------- drivers
etapa "Drivers para este computador"
DRV=(mesa linux-firmware)
L32=()
case "$CPU" in
  intel) DRV+=(intel-ucode); [ "$LAPTOP" = sim ] && DRV+=(thermald) ;;
  amd)   DRV+=(amd-ucode) ;;
esac
if tem_gpu 8086; then
  DRV+=(vulkan-intel intel-media-driver vpl-gpu-rt); L32+=(lib32-vulkan-intel lib32-mesa)
  # Gerações antigas (antes da Broadwell) usam o driver de vídeo antigo
  grep -qiP '\[8086:0[0-9a-f]{3}\]' <<<"$GPUS" && DRV+=(libva-intel-driver)
fi
if tem_gpu 1002; then
  DRV+=(vulkan-radeon); L32+=(lib32-vulkan-radeon lib32-mesa)
fi
if [ -n "$NVIDIA_IDS" ]; then
  # Turing (GTX 16xx / RTX 20xx) e mais novas: driver aberto da NVIDIA. Antigas: nouveau.
  NOVA=não
  for id in $NVIDIA_IDS; do [ $((16#$id)) -ge $((16#1e00)) ] && NOVA=sim; done
  if [ "$NOVA" = sim ]; then
    DRV+=(nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver)
    L32+=(lib32-nvidia-utils)
    for k in linux linux-lts linux-zen linux-hardened; do pacman -Q "$k" &>/dev/null && DRV+=("$k-headers"); done
    printf 'options nvidia NVreg_PreserveVideoMemoryAllocations=1\noptions nvidia_drm modeset=1 fbdev=1\n' |
      sudo tee /etc/modprobe.d/nvidia.conf >/dev/null
    NVIDIA_SERVICOS=sim
  else
    DRV+=(vulkan-nouveau); L32+=(lib32-vulkan-nouveau)
    aviso "NVIDIA antiga (antes da GTX 16xx): usando o driver livre nouveau"
  fi
  # Notebook com duas placas: GNOME ganha "Abrir com a placa dedicada" no menu
  { tem_gpu 8086 || tem_gpu 1002; } && DRV+=(switcheroo-control nvidia-prime)
fi
[ "$CPU" = qualcomm ] && DRV+=(vulkan-freedreno)
case "$VIRT" in
  kvm|qemu) DRV+=(spice-vdagent qemu-guest-agent) ;;
  oracle)   DRV+=(virtualbox-guest-utils) ;;
  vmware)   DRV+=(open-vm-tools) ;;
esac
[ "$MULTILIB" = sim ] && DRV+=("${L32[@]}")
# Os drivers entram na mesma transação dos apps (mais abaixo): uma resolução e um download só
ok "drivers escolhidos: ${DRV[*]}"

# ---------------------------------------------------------------- apps nativos
etapa "Apps nativos do GNOME e utilitários do sistema"
GNOME_APPS=(gnome-shell gdm nautilus gnome-console gnome-control-center gnome-settings-daemon
  gnome-session gnome-keyring gnome-menus gnome-backgrounds gnome-tweaks extension-manager
  gnome-software gnome-text-editor gnome-calculator gnome-calendar gnome-characters gnome-clocks
  gnome-contacts gnome-weather gnome-maps gnome-music gnome-logs gnome-disk-utility
  gnome-system-monitor gnome-font-viewer gnome-color-manager gnome-connections
  gnome-remote-desktop gnome-user-share gnome-user-docs yelp baobab loupe showtime decibels
  snapshot simple-scan sushi malcontent orca tecla grilo-plugins
  papers apostrophe   # leitor de PDF e leitor/editor de Markdown
  # Sem navegador: cada pessoa instala o que quiser (o tema se aplica ao Firefox/Chrome que existir)
  xdg-desktop-portal-gnome xdg-user-dirs-gtk network-manager-applet zenity)
SISTEMA=(pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber gst-plugin-pipewire
  gst-libav gst-plugins-ugly gst-thumbnailers
  gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive
  gvfs-smb gvfs-wsdd ntfs-3g exfatprogs dosfstools btrfs-progs
  bluez bluez-utils power-profiles-daemon gamemode zram-generator ufw timeshift cronie
  fwupd smartmontools htop atop fastfetch jq wget curl unzip flatpak pacman-contrib
  python-gobject gtk3 gtk4 libadwaita usbutils xdg-utils)
[ "$MULTILIB" = sim ] && SISTEMA+=(lib32-gamemode)
instalar "${DRV[@]}" "${GNOME_APPS[@]}" "${SISTEMA[@]}"
[ "${NVIDIA_SERVICOS:-}" = sim ] && sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume 2>/dev/null || true
pacman -Q switcheroo-control &>/dev/null && sudo systemctl enable switcheroo-control || true
pacman -Q thermald &>/dev/null && sudo systemctl enable thermald || true
yay -S --needed --noconfirm vicinae-bin || aviso "Vicinae (busca rápida) não instalou"
ok "apps instalados"

# ---------------------------------------------------------------- desempenho
etapa "Ajustes de desempenho"
E="$REPO_DIR/sistema/etc"
sudo install -Dm644 "$E/sysctl.d/90-desempenho.conf" /etc/sysctl.d/90-desempenho.conf
# Mitigação de split lock deixa jogos/emuladores lentos em CPUs x86 recentes
[ "$ARCH" = x86_64 ] && echo "kernel.split_lock_mitigate = 0" | sudo tee /etc/sysctl.d/91-splitlock.conf >/dev/null
[ -f /etc/systemd/zram-generator.conf ] && grep -q '^\[zram0\]' /etc/systemd/zram-generator.conf ||
  sudo install -Dm644 "$E/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf
sudo install -Dm644 "$E/tmpfiles.d/90-sem-zswap.conf" /etc/tmpfiles.d/90-sem-zswap.conf
sudo install -Dm644 "$E/tmpfiles.d/00-crash-retention.conf" /etc/tmpfiles.d/00-crash-retention.conf
sudo install -Dm644 "$E/udev/rules.d/60-ioschedulers.rules" /etc/udev/rules.d/60-ioschedulers.rules
sudo install -Dm644 "$E/systemd/journald.conf.d/90-tamanho.conf" /etc/systemd/journald.conf.d/90-tamanho.conf
sudo install -Dm644 "$E/systemd/coredump.conf.d/90-tamanho.conf" /etc/systemd/coredump.conf.d/90-tamanho.conf
sudo install -Dm644 -t /etc/systemd/system "$E"/systemd/system/limpeza-sistema.{service,timer}
sudo install -Dm644 "$REPO_DIR/sistema/usr/local/share/user-tmpfiles.d/limpeza.conf" \
  /usr/local/share/user-tmpfiles.d/limpeza.conf
sudo install -Dm644 "$E/gamemode.ini" /etc/gamemode.ini
sudo install -Dm644 -t /etc/systemd/system "$E"/systemd/system/crash-report.{path,service,timer}
sudo install -Dm644 "$E/systemd/system/ufw.service.d/sempre-ativo.conf" /etc/systemd/system/ufw.service.d/sempre-ativo.conf
if [ -f /etc/bluetooth/main.conf ]; then
  # Conecta mais rápido, mostra a bateria dos fones e liga o Bluetooth ao iniciar
  sudo sed -i 's/^#\?FastConnectable *=.*/FastConnectable = true/; s/^#\?Experimental *=.*/Experimental = true/;
               s/^#\?AutoEnable *=.*/AutoEnable=true/' /etc/bluetooth/main.conf
fi
sudo systemctl daemon-reload
sudo sysctl --system >/dev/null
sudo systemd-tmpfiles --create >/dev/null 2>&1 || true
sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=block || true
for s in power-profiles-daemon bluetooth fstrim.timer systemd-oomd cronie ufw \
         crash-report.path crash-report.timer limpeza-sistema.timer gdm; do
  sudo systemctl enable "$s" 2>/dev/null || aviso "serviço $s não existe aqui"
done
# O atop gravando histórico a cada minuto gasta SSD à toa: fica só para usar na hora (comando atop)
sudo systemctl disable --now atop atopacct 2>/dev/null || true
sudo ufw --force enable >/dev/null 2>&1 || true
# O app Firewall (estilo macOS) substitui o Gufw
pacman -Q gufw &>/dev/null && sudo pacman -Rns --noconfirm gufw >/dev/null 2>&1 || true
sudo systemctl start systemd-zram-setup@zram0.service 2>/dev/null || true
ok "zram ($(grep -oP 'zram-size = \K.*' /etc/systemd/zram-generator.conf)), memória, discos, logs e firewall"
ok "limpeza automática: pacotes velhos, logs, coredumps, cache e lixeira antigos"
ok "modos de energia (Economia/Equilibrado/Desempenho) e GameMode ligando o Desempenho nos jogos"

# ---------------------------------------------------------------- meus apps
etapa "Instalando meus apps"
APPS=(seletor-de-tema apply-macos-look.sh aparencia-aplicar-todos monitor-temp projetos-git
      gnome-app-grid-order crash-report gamemode-profile controle-zram zram-aplicar firewall
      firewall-aplicar limpeza-sistema icone-calendario enxugar-sistema vicinae-leve
      aparencia-usuario aparencia-todos-usuarios)
sudo install -m755 "${APPS[@]/#/$REPO_DIR/bin/}" /usr/local/bin/
for d in local.seletor.tema local.luizfelipe.MonitorTemp local.luizfelipe.ProjetosGit \
         io.github.luizfelipe.AppGridOrder local.controle.zram local.luizfelipe.Firewall; do
  sed 's|^Exec=/home/[^/]*/\.local/bin/|Exec=/usr/local/bin/|' "$REPO_DIR/applications/$d.desktop" |
    sudo install -Dm644 /dev/stdin "/usr/local/share/applications/$d.desktop"
done
# Nome antigo do atalho da Aparência (o dock não achava o ícone com ele aberto)
sudo rm -f /usr/local/share/applications/seletor-de-tema.desktop
sudo install -Dm644 -t /usr/local/share/icons/hicolor/scalable/apps "$REPO_DIR"/icons/*.svg
sudo install -Dm644 -t /usr/share/backgrounds/seletor-de-tema "$REPO_DIR"/wallpapers/*.jpg
# Cópia na pasta pessoal (~/wallpapers) para achar e usar fácil; não sobrescreve nem apaga nada
mkdir -p "$HOME/wallpapers" && cp -n "$REPO_DIR"/wallpapers/*.jpg "$HOME/wallpapers/"
sudo install -Dm644 -t /usr/share/gnome-background-properties \
  "$REPO_DIR"/sistema/usr/share/gnome-background-properties/seletor-de-tema.xml
sudo install -Dm644 "$E/xdg/autostart/gnome-app-grid-order.desktop" /etc/xdg/autostart/gnome-app-grid-order.desktop
sudo install -Dm644 -t /usr/local/lib/systemd/user \
  "$REPO_DIR"/sistema/usr/local/lib/systemd/user/icone-calendario.{service,timer}
sudo update-desktop-database -q /usr/local/share/applications 2>/dev/null || true
# O /etc/gamemode.ini já chama o gamemode-profile; um do usuário igual faria ele rodar duas vezes
grep -qs gamemode-profile "$HOME/.config/gamemode.ini" && rm -f "$HOME/.config/gamemode.ini"
mkdir -p "$HOME/.config/app-grid-order"
[ -f "$HOME/.config/app-grid-order/mode" ] || echo alphabetical > "$HOME/.config/app-grid-order/mode"
ok "Aparência, Monitor, Controle do zram, Firewall, Versões, Ordem dos Aplicativos, relatórios de crash"

# ---------------------------------------------------------------- extensões
etapa "Extensões do GNOME"
SHELL_VER=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
extensao() {
  local url tmp
  url=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=$1&shell_version=$SHELL_VER" |
        python3 -c 'import json,sys; print(json.load(sys.stdin)["download_url"])' 2>/dev/null) ||
    { aviso "$1 não tem versão para o GNOME $SHELL_VER"; return 0; }
  tmp=$(mktemp -d)
  curl -fsSL "https://extensions.gnome.org$url" -o "$tmp/ext.zip" && gnome-extensions install --force "$tmp/ext.zip"
  rm -rf "$tmp"
  ok "$1"
}
extensao appindicatorsupport@rgcjonas.gmail.com
# Dock, menu do pé do GNOME, efeito de minimizar e as minhas extensões ficam para todos os
# usuários: o aparencia-todos-usuarios instala (mais abaixo)

# Configurações do usuário precisam do D-Bus da sessão (fora do GNOME, cria um temporário)
sessao() { if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then "$@"; else dbus-run-session "$@"; fi; }

etapa "Componentes do estilo Apple (vidro, ponteiro, ícones de apps, fonte, efeito de minimizar)"
sessao /usr/local/bin/apply-macos-look.sh || aviso "algum componente do estilo Apple falhou; dá para tentar de novo pelo Seletor de Tema"

# ---------------------------------------------------------------- configurações
etapa "Configurações do GNOME"
# Não mexe no dock: os apps fixados são escolha de cada pessoa (o setup só instala o que falta)
sessao dconf load / < "$REPO_DIR/gnome/configuracoes.ini"
command -v vicinae >/dev/null && systemctl --user enable vicinae.service 2>/dev/null || true
install -Dm644 -t "$HOME/.local/share/vicinae/themes" "$REPO_DIR"/vicinae/themes/*.toml   # cores do Mac
# Busca leve: sem o motor Node e sem indexar as pastas ocultas (dados de apps, caches)
/usr/local/bin/vicinae-leve || true
systemctl --user enable systemd-tmpfiles-clean.timer 2>/dev/null || true   # limpa o cache do usuário
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable icone-calendario.timer 2>/dev/null || true         # data de hoje no ícone
/usr/local/bin/icone-calendario || true
ok "energia, touchpad, dock, pastas de apps, atalhos e extensões"

etapa "Estilização para todos os usuários (contas atuais, contas novas e tela de login)"
sessao /usr/local/bin/aparencia-todos-usuarios || aviso "a estilização de algum usuário falhou"

# No primeiro login depois de reiniciar, abre o Seletor de Tema para escolher a aparência.
# Só uma vez: ao abrir, ele marca a escolha como feita, e rodar o setup de novo não recria o atalho
ESCOLHA_FEITA="$HOME/.config/seletor-de-tema/escolha-inicial-feita"
if [ ! -e "$ESCOLHA_FEITA" ]; then
  mkdir -p "$HOME/.config/autostart"
  cat > "$HOME/.config/autostart/escolher-tema.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Escolher tema
Exec=sh -c 'mkdir -p "$HOME/.config/seletor-de-tema"; touch "$HOME/.config/seletor-de-tema/escolha-inicial-feita"; rm -f "$HOME/.config/autostart/escolher-tema.desktop"; exec /usr/local/bin/seletor-de-tema'
X-GNOME-Autostart-Delay=3
NoDisplay=true
EOF
fi

# Sobras da instalação
yay -Yc --noconfirm >/dev/null 2>&1 || true          # dependências de compilação que ficaram sem uso
rm -rf "$HOME/.cache/yay"/*
sudo /usr/local/bin/enxugar-sistema || true      # cache de pacotes da instalação

# ---------------------------------------------------------------- fim
echo
echo "${verde}Tudo instalado!${fim} Log completo em $LOG"
echo "Depois de reiniciar, o Seletor de Tema abre para você escolher a aparência (GNOME ou estilo Mac)."
TEM_JANELA=$([ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] && command -v zenity >/dev/null && echo sim || echo não)
perguntar() {   # perguntar "texto" "sim" "não"
  if [ "$TEM_JANELA" = sim ]; then
    zenity --question --title="Instalação concluída" --icon=seletor-de-tema --text="$1" \
      --ok-label="$2" --cancel-label="$3" 2>/dev/null
  else
    local r; read -rp "$(echo -e "$1" | tr '\n' ' ')[S/n] " r </dev/tty || r=n
    [[ "${r:-s}" =~ ^[sS]$ ]]
  fi
}
# Com outra conta logada o systemd recusa o reboot normal ("User X is logged in"): força,
# fechando as sessões de todas as contas
reiniciar() { systemctl reboot 2>/dev/null || systemctl reboot -i; }
if perguntar "Tudo pronto!\n\nReinicie o computador para terminar.\nNo próximo login você escolhe o tema." \
     "Reiniciar agora" "Depois"; then
  reiniciar
fi
exit 0
