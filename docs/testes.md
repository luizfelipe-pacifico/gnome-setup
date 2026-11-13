# Testes de regressão

`tests/regressao.sh` checa o repositório inteiro sem instalar nada. Cada erro resolvido
ganha um teste, para nunca voltar ao GitHub.

## Rodar

```bash
bash tests/regressao.sh
```

## Onde rodam sozinhos

- **Antes de cada push**: `.githooks/pre-push`. Ative uma vez por clone:
  `git config core.hooksPath .githooks`. Se algum teste falhar, o push não sai.
- **No GitHub**: `.github/workflows/regressao.yml` roda a cada push.

## O que é checado

| Grupo | Checagem |
| --- | --- |
| Sintaxe | `bash -n` em todos os scripts, `shellcheck -S error` (se instalado), Python compila |
| Erros resolvidos | `yay --save` sempre com `-Y`; yay/pacman com saída escondida nunca esperam resposta; `systemd-detect-virt` sem `none` duplicado |
| Serve para qualquer pessoa | nenhum navegador instalado; sem `/home/<usuário>` fixo; sem e-mails, tokens, chaves ou `git config --global`; `pessoal/` nunca instalado |
| Arquivos | tudo o que o `setup.sh` copia existe no repositório |

## Adicionar um teste

Ao corrigir um erro, acrescente uma linha `checa "descrição" comando` na seção
"Erros já resolvidos", com um comentário dizendo a data e o sintoma. Confira que o teste
**falha** na versão antiga (`git stash`) e **passa** na corrigida.
