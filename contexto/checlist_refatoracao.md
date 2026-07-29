# Checklist de Refatoração — BeRough

Rodar antes/depois de qualquer edição substancial.

## Antes de mexer
- [ ] Rodei `grep -r "<ClasseTela>" lib` para mapear quem referencia o que vou mudar.
- [ ] Li o arquivo alvo completo com `read` (não partirei do que lembro).
- [ ] Confirmei se a alteração toca um bloco único (uso `edit`) ou amplo (uso `write`).
- [ ] Se arquivos acentuados: copiarei `oldString` do `read`, não do terminal PowerShell.

## Durante a edição
- [ ] Mantive imports enxutos — adicionei só o necessário.
- [ ] Não quebrei navegação cruzada: o `Navigator.push` continua apontando para uma tela existente.
- [ ] Não deixei `TODO` snackbar no lugar de navegação real.
- [ ] Usei tokens de design (cores/typography/spacing) — não hex inline.
- [ ] Respeitei `rounded.none` (0px) em CTAs e cards; pílulas só para badges.
- [ ] Sem drop shadows (exceto o único `0 4px 8px rgba(0,0,0,0.1)` em hover de cards, não utilizado).

## Depois de mexer
- [ ] Rodei `flutter analyze lib` (caminho: `E:\Flutter\flutter_windows_3.41.9-stable\flutter\bin\flutter.bat`).
- [ ] Corrigi todo `error` e `warning` que sejam dos meus arquivos.
- [ ] Rodei `grep` para confirmar que não sobraram referências órfãs a classes/telas removidas.
- [ ] Atualizei `.skill/beRough_log.md` com a Sessão.
- [ ] Adicionei entrada em `contexto/erros_comuns.md` se houve erro novo.
- [ ] Atualizei `contexto/licoes_aprendidas.md` se houve princípio novo.

## Padrões de commit (quando solicitado)
- Mensagem concisa em português, no estilo: `feat: <área> <descrição>` ou `fix: <descrição>`.
- Nunca commitar sem `flutter analyze` limpo.
- Nunca commitar secrets (API keys, google-services.json fora do padrão).