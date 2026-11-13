# Instalação e atualização

## Requisitos

- Arch Linux ou derivado com `pacman` (EndeavourOS, Manjaro, Arch ARM...)
- GNOME instalado
- Rodar **como seu usuário**, sem `sudo`. A senha de administrador é pedida uma vez.

## Instalação completa

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/luizfelipe-pacifico/gnome-setup/main/instalar.sh)
```

O `instalar.sh` clona (ou atualiza) o repositório em `~/.local/share/gnome-setup` e roda o
`setup.sh`, que segue estas etapas:

1. Lê o hardware (CPU, GPU, RAM, notebook, máquina virtual)
2. Configura o pacman (cores, downloads paralelos, multilib) e escolhe os espelhos mais rápidos
3. Atualiza o sistema
4. Instala o `yay` (AUR), se ainda não existir
5. Instala os drivers certos para o hardware
6. Instala os apps nativos do GNOME e utilitários do sistema
7. Aplica os ajustes de desempenho (zram, discos, logs, limpeza, firewall)
8. Instala os apps do repositório em `/usr/local/bin`
9. Extensões do GNOME, estilo Apple e configurações
10. Aplica a estilização para todas as contas e para a tela de login

No fim, oferece reiniciar. No primeiro login, a janela **Aparência** abre para escolher o tema.

## Só a estilização

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/luizfelipe-pacifico/gnome-setup/main/estilo.sh)
```

Instala a Aparência, o dock, o menu do GNOME e o app Firewall, sem mexer em drivers, pacman
nem desempenho.

## Atualizar

Rode o mesmo comando de novo. Ele baixa a versão nova e só faz o que falta.

## Log

Tudo o que aparece na tela fica em `~/.cache/gnome-setup-instalacao.log`.
