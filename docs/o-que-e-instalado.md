# O que é instalado (e o que não é)

O comando é usado por várias pessoas em computadores diferentes. Ele instala apenas
ferramentas e visual; nada da conta ou da máquina de quem mantém o repositório.

## Instala

- Drivers e microcode adequados ao hardware detectado
- Apps nativos do GNOME (Arquivos, Console, Texto, Calculadora, Calendário, Papers...)
- Utilitários de sistema: PipeWire, Bluetooth, `ufw`, Timeshift, `fwupd`, zram, Flatpak
- `yay` e alguns pacotes do AUR para o estilo Apple (Blur my Shell, ponteiro, fonte Inter)
  e a busca Vicinae
- Os apps do repositório (Aparência, Monitor, Firewall, Controle do zram, Versões...)
- Configurações do GNOME (`gnome/configuracoes.ini`)

## Não instala

- **Navegador.** Nenhum (nem Firefox, nem o Web do GNOME). Cada pessoa escolhe o seu.
  As parametrizações do tema (botões coloridos, ícone, `userChrome.css` do Firefox,
  `gtk.css` do Chrome) se aplicam ao navegador que estiver instalado.
- Contas, e-mails, chaves SSH/GPG, tokens, `git config` ou qualquer acesso
- Projetos, arquivos ou caminhos da pasta pessoal de outra pessoa
- O conteúdo de `pessoal/` (configurações só da máquina do mantenedor)
- Steam, emuladores, editores de código e outros apps de terceiros

Essas regras são verificadas pelos [testes de regressão](testes.md): um push que instale um
navegador ou contenha um caminho `/home/<usuário>` fixo é bloqueado.

## Desfazer

- `pacman.conf` e a lista de espelhos ganham uma cópia `*.antes-gnome-setup` antes de mudar
- Escolher um tema "GNOME" na Aparência desfaz o estilo Apple e volta ao que havia antes
