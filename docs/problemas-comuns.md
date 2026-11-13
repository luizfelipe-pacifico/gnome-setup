# Problemas comuns

Primeiro, veja o log: `~/.cache/gnome-setup-instalacao.log`.

## A instalação para em "Instalando o yay" (corrigido em 12/11/2026)

**Sintoma:** depois de `there is nothing to do` na etapa do yay, nada mais acontece.

**Causa:** o setup gravava as opções do yay com `yay --save ...`. Sem uma operação, o yay
roda `yay -Syu` (atualização completa) e, como a saída estava escondida, ficava esperando
uma resposta que nunca aparecia na tela.

**Correção:** agora é `yay -Y --save ...`, que só grava as opções, com a entrada fechada
(`</dev/null`) para nunca esperar resposta. Se você já rodou a versão antiga, aperte
`Ctrl+C` e rode o comando de instalação de novo.

## "máquina virtual: none" seguido de outro "none" (corrigido em 12/11/2026)

O `systemd-detect-virt` imprime `none` e sai com erro fora de máquina virtual; o setup
somava outro `none`. Era só visual.

## O reflector demora

Ele tem limite de 3 minutos. Se passar, o setup mantém os espelhos atuais e segue.

## Uma extensão "não tem versão para o GNOME"

A extensão ainda não foi atualizada para a sua versão do GNOME. O setup avisa e continua.

## Rodei com sudo

Rode sem `sudo`: o yay não funciona como root. A senha é pedida quando precisa.

## "User ... is logged in on tty2" ao reiniciar no fim (corrigido em 13/11/2026)

O systemd não reinicia enquanto outra conta tem sessão aberta. Agora, se o reinício normal
falhar, o setup força (`systemctl reboot -i`), fechando as sessões de todas as contas.
