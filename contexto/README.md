# Pasta `contexto/` — Memória de Erros e Lições

> Esta pasta existe para **registrar erros que já cometi neste projeto e padrões a evitar**, de forma que sessões futuras possam consultar e não repetir os mesmos gargalos. Toda vez que ocorrer um problema não-trivial, adicione uma entrada em `erros_comuns.md` ou `licoes_aprendidas.md`.

## Arquivos
- `erros_comuns.md` — Catálogo de erros já cometidos (com causa raiz e solução).
- `licoes_aprendidas.md` — Princípios e melhores práticas consolidados a partir desses erros.
- `checlist_refatoracao.md` — Checklist de verificação antes/não/depois de mexer em código BeRough.

## Quando atualizar
- Sempre que uma edição falhar de forma não-óbvia (encoding, line endings, match ambíguo).
- Sempre que quebrar uma referência cruzada ao apagar um arquivo.
- Sempre que o `flutter analyze` revelar um padrão recorrente (ex.: imports não usados após refator).
- Sempre que um bug for corrigido.
- Sempre que regressar a um tema visual (ex.: aplicar DESIGN.md) e houver decisão a ser lembrada.

## Convenção das entradas
Cada erro deve conter:
- **Data** ISO
- **Sintoma** (o que aconteceu)
- **Causa raiz** (por que aconteceu)
- **Correção** (o que foi feito)
- **Como evitar** (regra prática)