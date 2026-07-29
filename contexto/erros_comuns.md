# Erros Comuns — Catálogo

Formato: `### [Data] Sintoma` → Causa → Correção → Como evitar.

---

### [2026-07-28] `edit` reclama "oldString not found" apesar de o texto aparecer na leitura
- **Sintoma**: a ferramenta `edit` falhou ao substituir blocos que continham palavras acentuadas em português ("Missão", "Disponível", "está") e conteúdo atualmente sob `home_screen.dart`.
- **Causa raiz**: o arquivo em disco estava em UTF-8 com BOM/CRLF, mas o texto colado no parâmetro `oldString` vinha via clipboard com caracteres acentuados trocados (`?` no lugar de `ã`, `?` no lugar de `ç`). O `Get-Content` do PowerShell 5.1 mostrava os caracteres errados porque a codificação padrão de console não era UTF-8. A string enviada ao matcher nunca esteve literalmente no arquivo.
- **Correção**: reescrevi o arquivo inteiro com `write` (substituição completa) em vez de fazer várias edições pontuais. Para arquivos pequenos/médios isso é mais seguro.
- **Como evitar**:
  1. Antes de `edit` em arquivos com acentos, leia de novo com `read` e **copie o texto exato mostrado pelo `read`** (não o que está no terminal do PowerShell).
  2. Prefira `write` (reescrita total) em arquivos médios (~<300 linhas) e refatorações amplas.
  3. Use `edit` em strings ASCII puro (nomes de variável, código) e mantenha blocos curtos e únicos.

### [2026-07-28] Edição atingiu o alvo errado deixando toast inconsistente
- **Sintoma**: alterei o conteúdo de `_buildAppBar` em `dashboard_screen.dart` para inserir o botão "INICIAR CORRIDA" e acabei mudando o `onTap` do avatar do topo — originalmente deveria abrir `ProfileScreen`, mas passou a abrir `RunningScreen`.
- **Causa raiz**: o `oldString` foi muito genérico ("onTap: () { Navigator.push(...) }") e fez match no primeiro `onTap` encontrado (o do avatar) em vez do botão de corrida alvo.
- **Correção**: reescrevi o trecho com contexto suficiente (linhas `actions: [` e `GestureDetector`) para tornar a correspondência única e restaurei o `onTap` do avatar para `ProfileScreen`.
- **Como evitar**:
  1. Sempre inclua contexto suficiente (linhas irmãs, chave do widget) para tornar o `oldString` **único no arquivo**.
  2. Se o snippet aparece em múltiplos lugares (ex.: vários `onTap`), **não use `replaceAll`** atoa, prefira reescrita total do arquivo.
  3. Após uma edição em larga escala, leia de novo o `grep` para confirmar que o estado final está consistente (ex.: `ProfileScreen` continua sendo referenciada onde deve).

### [2026-07-28] `flutter analyze` aponta `unused_import` em loop de refator
- **Sintoma**: warnings recorrentes de `unused_import` em `dashboard_screen.dart` e `run_history_screen.dart` depois de mover referências entre arquivos.
- **Causa raiz**: ao refatorar imports eu adicionei novos e removi código que os usava, mas me esqueci de limpar imports órfãos. Também importei `geolocator` em `run_history_screen.dart` sem usar (peguei do `running_screen.dart` por hábito).
- **Correção**: rodei `flutter analyze lib` no fim e apaguei imports não usados.
- **Como evitar**:
  1. **Sempre rode `flutter analyze lib` após uma rodada de edições** e antes de fechar a sessão.
  2. Ao remover uma feature (ex.: aviso de tela de corrida), verifique se a chamada de import que ela fazia ainda é usada em algum lugar.
  3. Use `grep -r "NomeDaClasse" lib/` antes de apagar uma importação para garantir que não há mais referências.

### [2026-07-28] Código morto (versões antigas) poluindo a raiz `lib/`
- **Sintoma**: havia `lib/home_screen.dart` (raiz) e `lib/screens/home_screen.dart` (oficial); `lib/goal_setting_screen.dart` (raiz) e `lib/screens/skill_selection_screen.dart` (substituto). O `main.dart` importava ambos por acidente.
- **Causa raiz**: o projeto cresceu em fopen-do-grande — quando um arquivo foi movido de pasta, a versão antiga não foi apagada. Vários imports apontavam para o antigo.
- **Correção**: rastreei com `grep` todas as referências, migrei a última, e **deleti os arquivos mortos** com `Remove-Item`.
- **Como evitar**:
  1. Ao mover um arquivo, **sempre apague o original** após confirmar que nenhuma referência resta (`grep -r "<NomeClasse>" lib`).
  2. Não use dois nomes parecidos na raiz e em subpasta para a mesma classe — escolha um único caminho oficial.
  3. Visão de conjunto periódica: `Get-ChildItem -Recurse lib` para detectar duplicações.

### [2026-07-28] Botão "Iniciar Missão" só exibia SnackBar em vez de abrir a tela
- **Sintoma**: na aba Jornada (`home_screen.dart`), o `INICIAR MISSÃO` de cada skill mostrava "Iniciando rotina de treinos..." e nada acontecia. A `TrailDetailScreen` só era aberta pelo Dashboard.
- **Causa raiz**: implementação inicial preguiçosa — snackbar temporário foi deixado no lugar da navegação. 
- **Correção**: troquei o toast por `Navigator.push → TrailDetailScreen(skill: skill)` com `.then((_) => setState(() {}))` para refletir etapas concluídas ao voltar.
- **Como evitar**:
  1. Snackbars de "placeholder" devem ter um comentário `// TODO` e serem substituídos na mesma sessão.
  2. Após adicionar uma tela nova, **teste todos os pontos de entrada** (Dashboard, Jornada, Perfil) — não apenas um.

### [2026-07-28] Fluxo pós-login divergente entre login e cadastro
- **Sintoma**: usuário que fazia login por email/Google ia para `GoalSettingScreen` (sem apelido); quem se cadastrava passava por `AICoachScreen` → `SkillSelectionScreen` (com apelido). Os fluxos tinham comportamentos diferentes.
- **Causa raiz**:追加ação incremental sem visão de produto. Cada porta de entrada foi codada em momentos distintos.
- **Correção**: unifiquei ambos em `SkillSelectionScreen` (com apelido + métricas + skills).
- **Como evitar**:
  1. Modele o "journey map" do usuário **antes** de codar portas de entrada: Onboarding → Login/Cadastro → Setup Perfil → Home. Tudo que chega ao setup deve convergir.
  2. Se houver mais de uma porta para a mesma etapa, padronize o próximo passo delas em uma única tela.

### [2026-07-28] `Path` indefinido / `moveTo` não existe em `Path<LatLng>` ao usar flutter_map
- **Sintoma**: ao reintegrar flutter_map no `RunningScreen`, o `RoutePainter` (Custom Canvas) quebrou com `The method 'moveTo' isn't defined for the type 'Path'` e `argument_type_not_assignable: Path<LatLng> não pode ser atribuído a Path`.
- **Causa raiz**: importando `flutter_map` (que exporta `Path<T>` genérico) junto com `material.dart`, o Dart passou a entender que o `Path` referenciado era o genérico do flutter_map, não o `dart:ui.Path` do Flutter.
- **Correção**: `import 'package:flutter/material.dart' hide Path;` para esconder o path genérico do material quando flutter_map está em escopo, e usar `dart:ui as ui;` + `ui.Path()` explicitamente quando criar path do canvas.
- **Como evitar**:
  1. Sempre que integrar flutter_map em um arquivo que já usa `CustomPainter` com `Path`, **esconda** o `Path` do material com `hide Path` no import.
  2. Prefira qualificar: `ui.Path()` em vez de `Path()` em pintores custom.
  3. Rode `flutter analyze` imediatamente após adicionar um novo package pesado; esse tipo de conflito de namespace aparece logo no primeiro analyze.

### [2026-07-28] Import `latlong2/latlong2.dart` não resolve URI
- **Sintoma**: `Target of URI doesn't exist: 'package:latlong2/latlong2.dart'` ao usar `LatLng`.
- **Causa raiz**: caminho de import errado. O correto é `package:latlong2/latlong.dart` (exporta a classe `LatLng`);不少人 erram pensando que o arquivo leva o nome do package.
- **Correção**: `import 'package:latlong2/latlong.dart';`.
- **Como evitar**:
  1. Copie o import direto da documentação do pub.dev, não tente deduzir.
  2. Quando o analyzer reclamar de URI inexistente após adicionar package, rode `flutter pub get` e confirme o Storkpath; se persistir, o caminho do arquivo está errado.

---

## Padrões recorrentes a lembrar
- **Sempre rode `flutter analyze lib` antes de fechar a sessão.**
- **`grep` antes de `Remove-Item`**: confirme que nenhuma referência resta.
- **Prefira `write` (reescrita total) para refatorações que tocam >30% de um arquivo médio.**
- **Para `edit` em arquivos acentuados**, copie do `read`, não do terminal do PowerShell.
- **Quando um botão/navigation parece "pronto" mas só tem toast**, marque com `TODO` e resolva na mesma sessão.
- **flutter_map + CustomPainter**: use `hide Path` no import do material e qualifique `ui.Path()` — conflito de namespace é certo.
- **Import `latlong2`**: o caminho é `latlong2/latlong.dart`, não `latlong2/latlong2.dart`.