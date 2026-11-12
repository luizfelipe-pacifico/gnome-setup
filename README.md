# gnome-setup

Meu GNOME no Arch Linux, montado com um comando: aparência (GNOME padrão ou estilo Mac),
apps que fiz para o dia a dia, drivers certos para o hardware e ajustes para gastar pouca
RAM e pouco SSD.

> Repositório pessoal. Não aceito contribuições (pull requests e issues ficam desligados).
> Pode usar à vontade, mas as mudanças são só minhas.

## Instalar

Num Arch Linux com GNOME recém-instalado, abra o Terminal e rode **como seu usuário**
(sem `sudo`; a senha é pedida uma vez):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/luizfelipe-pacifico/gnome-setup/main/instalar.sh)
```

No final aparece uma janela para **reiniciar**. No primeiro login depois disso, o
**Seletor de Tema** abre sozinho para você escolher a aparência: GNOME claro/escuro ou
estilo Mac claro/escuro.

Para **atualizar** depois, rode o mesmo comando: ele baixa a versão nova e só faz o que falta.
O log fica em `~/.cache/gnome-setup-instalacao.log`.

## O que o comando faz

**Terminal e pacotes**
- pacman com cores, barra Pac-Man (`ILoveCandy`), 10 downloads paralelos e repositório
  multilib (em x86_64)
- espelhos mais rápidos com `reflector`
- `yay` para o AUR, compilando com todos os núcleos

**Drivers (lê o hardware e se adapta)**
- CPU Intel, AMD ou ARM/Snapdragon: microcode certo (Intel/AMD) e `thermald` em notebooks Intel
- GPU Intel, AMD e NVIDIA, integrada ou dedicada, inclusive notebook com duas placas:
  - Intel: Vulkan e aceleração de vídeo (driver antigo nas gerações antes da Broadwell)
  - AMD: Vulkan (RADV)
  - NVIDIA GTX 16xx / RTX e mais novas: driver aberto da NVIDIA, com suspensão funcionando.
    NVIDIA mais antigas usam o nouveau.
  - Duas placas: o GNOME ganha "Abrir com a placa dedicada"
  - Snapdragon: Vulkan Freedreno
- Máquinas virtuais (QEMU/KVM, VirtualBox, VMware): ferramentas de integração

**Desempenho, RAM e SSD**
- zram (memória comprimida na RAM) com zstd e ajustes de memória para zram; zswap desligado
- agendador de disco por tipo (NVMe, SSD, HD), TRIM semanal e menos escrita de uma vez só
- perfis de energia Economia / Equilibrado / Desempenho. O GameMode liga o Desempenho
  sozinho nos jogos e volta ao perfil anterior quando o jogo fecha.
- `systemd-oomd` para o sistema não travar quando a memória acaba
- split lock sem mitigação em x86 (jogos e emuladores ficam mais rápidos)
- logs limitados a 100 MB e coredumps a 500 MB. O `atop` não fica gravando histórico.
- **limpeza automática**: toda semana apaga pacotes velhos baixados, logs antigos e
  runtimes Flatpak sem uso. Todo dia apaga caches sem uso (miniaturas, sobras do yay e do
  pip, cache de shaders...). Lixeira e temporários com mais de 30 dias também somem.
- a loja do GNOME não baixa atualizações sozinha em segundo plano

**Apps nativos do GNOME** (só os nativos: outros navegadores, editores de código, Steam, emuladores
e outros apps de terceiros ficam de fora). Arquivos, Console, Configurações, Ajustes, Texto,
Calculadora, Calendário, Relógios, Clima, Mapas, Música, Fotos (Loupe), Vídeos (Showtime),
Câmera, Scanner, Discos, Uso do disco, Logs, Monitor do sistema, Gerenciador de Extensões,
**Papers** (leitor de PDF), **Apostrophe** (leitor/editor de Markdown), **Web** (o navegador
do GNOME, que no estilo Mac fica parecido com o Safari) e mais. Também instala
PipeWire, Bluetooth, firewall (`ufw` + Gufw), Timeshift (backups), `fwupd` (firmware) e acesso a
Google Drive / OneDrive pelo Arquivos (Contas Online).

**Meus apps**

| App | Para quê |
| --- | --- |
| Seletor de Tema | Alterna GNOME e estilo Mac, claro ou escuro (abaixo) |
| Monitor de Temperatura | Temperatura, ventoinha, CPU, RAM, bateria e troca do modo de energia. Funciona com Intel, AMD e ARM. |
| Controle do zram | Arraste para escolher quanto da RAM vira memória comprimida |
| Ordem dos Aplicativos | Grade de apps em ordem alfabética ou aleatória |
| Projetos Git | Ver alterações, salvar versões e restaurar projetos |
| Relatórios de crash | Cada programa que trava gera um relatório legível em `/var/log/crash-reports` |

**Extensões**: Dash to Dock, Kiwi Menu e AppIndicator (versão certa para o seu GNOME,
direto do extensions.gnome.org).

## Estilo Mac (pelo Seletor de Tema)

Escolher um tema "Apple" aplica o estilo; escolher um tema "GNOME" desfaz tudo e volta ao
que você tinha antes. Os ajustes valem só para os apps nativos do GNOME e para os meus apps.
Apps de fora (Firefox, Chrome, Flatpaks etc.) continuam como são.

- botões fechar/minimizar/maximizar coloridos e à esquerda
- ponteiro do macOS e fonte Inter
- ícones dos apps nativos no formato do Mac, sem copiar os da Apple: Console, Monitor,
  Calculadora, Editor de Texto e Lixeira no estilo Mac. Arquivos e Programas com uma pasta e uma
  sacola azuis. Web, Calendário, Música, Mapas, Configurações e os outros com o próprio ícone do
  GNOME numa base arredondada. Bateria, rede, volume e apps de fora continuam como são
  (~600 KB no disco).
- dock embaixo e centralizada, com pontinho nos apps abertos
- relógio com dia da semana e sem canto ativo
- papel de parede próprio, claro e escuro
- **Super+Espaço** abre a busca (Vicinae), como o Spotlight
- vidro na barra, dock e tela de apps (Blur my Shell, modo leve) e efeito de minimizar "lâmpada"

## Organização do repositório

```
instalar.sh            comando de uma linha (baixa o repositório e roda o setup)
setup.sh               instalação completa, adaptada ao hardware
bin/                   meus apps e scripts (vão para /usr/local/bin)
applications/, icons/  atalhos e ícones dos apps
wallpapers/            papéis de parede (gerar.py recria)
gnome/configuracoes.ini   configurações do GNOME (dconf)
sistema/               arquivos de sistema: desempenho, zram, discos, limpeza, crash, firewall
pessoal/               coisas só da minha máquina (RPCS3, controle de PS4); o setup não instala
```

Para atualizar só a aparência sem rodar tudo: `bin/instalar-seletor-de-tema`.

Requisitos: Arch Linux (ou derivado com pacman) e GNOME. Testado no GNOME 51.
