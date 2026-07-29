# BeRough - Log de Evolução do Projeto

> Este arquivo registra o histórico de desenvolvimento do app BeRough, seguindo o Plano de Projeto. Cada entrada é datada e classifica a fase correspondente.

---

## Visão Geral

BeRough é um app mobile (Flutter) focado em calistenia + corrida de rua, com gamificação, rastreamento GPS e simulação de Coach IA.

- Stack: Flutter (Dart), Firebase Auth, SharedPreferences, Geolocator, flutter_map.
- Estado: Singleton `AppState` em memória (provisório até a Fase 4 - Firestore).

---

## Histórico de Etapas Concluídas

### Fase 1 - Fundação e Protótipo Funcional
- [x] Estruturação base do projeto Flutter.
- [x] Criação do `AppState` (Singleton) com mock de dados (skills, histórico de corridas, recordes).
- [x] Telas de Onboarding, Auth (login email/Google) e Cadastro (UI).
- [x] `HomeScreen` com `BottomNavigationBar`.

### Fase 2 - Integração e Lógica Core
- [x] Firebase Auth real (Email/Senha + Google Sign-in) em `auth_screen.dart` e `signup_screen.dart`.
- [x] Tela de Definição de Metas (`SkillSelectionScreen` com métricas corporais + apelido + múltiplas skills).
- [x] Dashboard dinâmico (XP/nível calculados em tempo real a partir de `AppState.runHistory` e `selectedSkillIds`).
- [x] Tela de Perfil com cálculo lúdico de IMC ("Ninja Ágil", "Máquina Estética", "Tanque de Guerra", "Juggernaut Rough") e avatar (câmera/galeria/URL Google).
- [x] Sistema de GPS e mapa em `running_screen.dart` (Custom Canvas com `RoutePainter`) e versão alternativa `run/RunTrackingScreen.dart` (flutter_map + tiles escuros).

### Fase 3 - Refinamento de UX/UI e Sistema de Jornada
- [x] `trail_detail_screen.dart`: etapas sequenciais com bloqueio, botão "Falhei, Adaptar" recalculando `_isAdapted`, funil por categoria (puxada vs. base), sistema de PRs.
- [x] Simulação de Coach IA via `ai_coach_screen.dart` (Gemini integrado + fallback simulado sem API Key).
- [x] Refinamento visual geral (sombras, espaçamentos, ícones) - concluído na Sessão 01.
- [x] Persistência local transitória (SharedPreferences) - etapa intermediária que prepara a Fase 4.

### Fase 4 - Persistência e Backend (Próximos Passos)
- [ ] Substituir AppState em memória por Firestore (a base de persistência local já está implementada, falta migrar para a nuvem).
- [ ] Salvar histórico real de corridas na nuvem.
- [ ] Sincronizar recordes/etapas concluídas por usuário.

### Fase 5 - Expansão (Backlog)
- [ ] Integração Strava/Google Fit.
- [ ] Comunidade/Feed social.
- [ ] IA real para montar treinos baseados em fadiga e feedback textual.

---

## Revisão Técnica (Sessão de Melhorias)

### Problemas identificados
1. **Código morto / duplicado**:
   - `lib/home_screen.dart` (raiz) - versão antiga com 3 abas, não mais referenciada por `main.dart`.
   - `lib/goal_setting_screen.dart` (raiz) - duplica funcionalidade de `screens/skill_selection_screen.dart` (que é mais completo, com campo de apelido).
   - `screens/run/run_history_screen.dart` - arquivo criado vazio (0 bytes).
2. **Imports duplicados no `main.dart`**: `./screens/auth_screen.dart` e `screens/auth_screen.dart` repetidos.
3. **Fluxo inconsistente de onboarding pós-login**:
   - Login por email/Google -> `GoalSettingScreen` (sem apelido).
   - Cadastro -> `AICoachScreen` -> `SkillSelectionScreen` (com apelido).
   - Usuário já logado que reabre o app -> direto para `HomeScreen` com dados do `AppState` em default (dados corporais perdidos por falta de persistência).
4. **HomeScreen não preserva estado das abas** ao trocar de aba (sem `IndexedStack`), forçando rebuild da árvore de widgets.
5. **Inconsistência de tela de corrida**: Dashboard abre `RunTrackingScreen` (versão leve, não salva histórico), enquanto a aba Jornada abre `RunningScreen` (versão completa com resumo + histórico). Botão de pausa/cronômetro só existe na completa.
6. **Cálculo de calorias hardcoded** em `running_screen.dart` (`_distanceInMeters * 0.075` assume 75kg), ignorando `AppState.weight`.
7. **`updatePhotoURL(pickedFile.path)`**: passa caminho local de arquivo para o Firebase Auth, que espera uma URL pública. Funciona em runtime mas não é correto; deveria usar URL de storage hospedado (Fase 4).
8. **Fontes do Design System (Oswald/Inter)** não declaradas em `pubspec.yaml` - texto cai para fallback do sistema.
9. **Refinamento visual**: cards do Dashboard/Perfil sem sombras/espessura definidas pelo design system.

### Melhorias aplicadas nesta sessão
- (veja próxima seção "Sessões de Melhoria")

---

## Sessões de Melhoria

### Sessão 01 - Revisão e Cleanup Estrutural (28/07/2026)
- [x] Criada pasta `.skill/` com este log.
- [x] Removidos imports duplicados de `auth_screen.dart` em `main.dart`.
- [x] Removido código morto: `lib/home_screen.dart`, `lib/goal_setting_screen.dart`, `lib/screens/journey/journey_screen.dart` (após migração de referências).
- [x] Unificado fluxo pós-login: `auth_screen.dart` agora aponta para `SkillSelectionScreen` (com apelido + métricas + skills múltiplas), em vez de `GoalSettingScreen`.
- [x] `main.dart` / AuthGate reaproveita `SkillSelectionScreen` para usuários já autenticados que ainda não têm métricas salvas no `AppState`. `AppState.loadFromDisk()` é chamado antes do roteamento para pré-popular os dados.
- [x] `screens/home_screen.dart` passa a usar `IndexedStack` para preservar estado das abas (cronômetro da corrida, mapa, scrolls).
- [x] Botão "INICIAR MISSÃO" da aba Jornada agora abre `TrailDetailScreen` ao invés de apenas exibir snackbar; adicionado botão "GERENCIAR TRILHAS" que abre `SkillSelectionScreen` em modo edição (`isEditMode: true`) e atualiza a lista ao voltar.
- [x] Dashboard passa a abrir a versão completa `RunningScreen` (com resumo e histórico) ao invés de `RunTrackingScreen`, unificando a UX de corrida.
- [x] Adicionado link "VER TUDO" no Dashboard rodando a nova tela `RunHistoryScreen`.
- [x] Corrigido cálculo de calorias em `running_screen.dart` para usar `AppState.instance.weight` (estimativa MET por peso: kcal ≈ km * pesoKg * 0.9).
- [x] Implementado `lib/screens/run_history_screen.dart` (antes era um arquivo vazio de 0 bytes): lista detalhada com mini-mapa em canvas (RoutePainter), pace, tempo, calorias, data e FAB para nova corrida.
- [x] Barra de progresso real nos cards de skill do Dashboard: agora lê `AppState.completedStages[skill.id]` em vez do hardcoded `0.35`.
- [x] Refinamento visual: adicionadas sombras sutis e espaçamentos consistentes nos cards do Dashboard, Perfil e abas (raio 12-20px, brand #9C27B0, sombras pretas `0.25`).
- [x] Adicionada persistência local via SharedPreferences em `AppState`:
  - `loadFromDisk()` restaura ao abrir: weight, height, age, nickname, selectedSkillIds, completedStages, userRecords e runHistory (com `RunLog.toJson/fromJson`).
  - `saveProfile()`, `addRunToHistory()`, `clearUserData()` e `_saveRunHistory()` propagam mudanças ao disco.
  - `TrailDetailScreen` persiste etapas concluídas e recordes; `RunSummaryScreen` salva corridas via `addRunToHistory()`; `ProfileScreen` no logout chama `clearUserData()`.
- [x] `SkillSelectionScreen` agora chama `loadFromDisk()` no initState e `saveProfile()` ao confirmar, garantindo que usuários recém-logados vejam seus dados pré-preenchidos e que novas edições sejam persistidas.
- [x] `flutter analyze lib` rodado; apenas warnings pré-existentes em `auth_screen.dart` (null check no fluxo Google v7) permanecem, sem erros.

#### Arquivos modificados nesta sessão
- `lib/main.dart` (refs/import e AuthGate com `loadFromDisk` + roteamento condicional)
- `lib/app_state.dart` (métodos de persistência + `RunLog.toJson/fromJson` + `clearUserData`)
- `lib/screens/auth_screen.dart` (redirecionamento para `SkillSelectionScreen`)
- `lib/screens/skill_selection_screen.dart` (`loadFromDisk` + `saveProfile`)
- `lib/screens/home_screen.dart` (`IndexedStack`, missões abrem `TrailDetailScreen`, botão GERENCIAR TRILHAS, sombras)
- `lib/screens/journey/dashboard_screen.dart` (RunningScreen unificado, VER TUDO, progresso real, setState ao voltar, sombras)
- `lib/screens/journey/trail_detail_screen.dart` (persistir etapa/recorde)
- `lib/screens/running_screen.dart` (cálculo de calorias por peso + import AppState)
- `lib/screens/run_summary_screen.dart` (`addRunToHistory` persistente)
- `lib/screens/run_history_screen.dart` (criado do zero, histórico listável)
- `lib/screens/profile_screen.dart` (logout com `clearUserData`)
- `.skill/beRough_log.md` (criado e atualizado)

### Débitos Técnicos restantes (entregas futuras)
- Migrar `updatePhotoURL` para URL hospedada (Firebase Storage) na Fase 4.
- Embutir fontes Inter como assets no `pubspec.yaml` (atualmente usa fallback do sistema; `BeFonts.family = 'Inter'` espera o asset registrado).
- Substituir `.withOpacity()` por `.withValues()` em todo o código (deprecation do Flutter 3.41 — 21 infos restantes, não blocker).
- Otimização de GPS em background (mencionado nas considerações técnicas).
- Tela de "Tribo/Comunidade" ainda exibe placeholder.
- Warning pré-existente em `auth_screen.dart` (null check Google Sign-in v7) — corrigido na Sessão 02 ao substituir por `final GoogleSignInAccount? googleUser = await ...authenticate();`.

---

### Sessão 02 - Implementação do DESIGN.md + pasta contexto/ (28/07/2026)
- [x] Criada pasta `contexto/` na raiz do projeto com:
  - `README.md` explicando o propósito da memória de erros.
  - `erros_comuns.md` catalogando 6 erros cometidos na Sessão 01 (encoding/acentos, edit em alvo errado, unused imports, código morto, snackbar no lugar de navegação, fluxo divergente).
  - `licoes_aprendidas.md` com princípios consolidados (workflow, arquitetura, corrida, persistência, layout Ferrari).
  - `checlist_refatoracao.md` com checklist pré/durante/pós edição.
- [x] Criados design tokens centralizados em `lib/design/tokens.dart` seguindo `DESIGN.md`:
  - `BeColors`: canvas #181818, primary #DA291C (Rosso Corsa) + primaryActive, ink #FFF, body #969696, muted #666, hairline #303030, canvasElevated #303030, semantic info/success/warning.
  - `BeRadii`: none 0, xs 2, sm 4, md 6, lg 8, xl 12, full 9999.
  - `BeSpacing`: xxxs 4 → super 128 (escala 8px).
  - `BeFonts`: Inter (substituto de FerrariSans), 13 text styles (displayMega → numberDisplay), display weight 500, CTA 700 uppercase 1.4px tracking, body 400.
- [x] Criados widgets reutilizáveis em `lib/design/ui.dart`:
  - `BePrimaryButton` (Rosso Corsa, sharp 0px, uppercase 1.4px tracking, 48px altura).
  - `BeOutlineButton` (1px ink border, transparente, sharp corners).
  - `BeCard` (canvas-elevated, sharp, 1px hairline).
  - `BeBadgePill` (única pílula no sistema).
  - `BeSectionLabel`, `BeHairline`, `beInputDecoration()` (canvas dark, radius 4px, focus em Rosso Corsa).
- [x] `main.dart`: tema global reescrito com tokens — colorScheme dark, appBar transparente, textTheme mapeando tokens, elevatedButton/outlinedButton com sharp corners, inputDecorationTheme, bottomNavigationBarTheme em Rosso Corsa, snackBarTheme canvasElevated.
- [x] Refatoradas TODAS as telas para usar tokens + widgets do DESIGN.md:
  - `auth/onboarding_screen.dart`: hero placeholder em canvas-elevated + hairline, dot indicator 2px alternando Rosso Corsa/hairline, display 30px weight 500.
  - `auth_screen.dart`: BePrimaryButton/BeOutlineButton, beInputDecoration, BeBadgePill-free, section labels uppercase caption, separador com BeHairline.
  - `auth/signup_screen.dart`: displayMd 32px, fields com beInputDecoration, BePrimaryButton "Criar Conta".
  - `skill_selection_screen.dart`: canvasElevated cards com border Rosso Corsa quando selecionado, difficulty badge uppercase, BeBadgePill semantic colors, BePrimaryButton "Construir Meu Cronograma (N)".
  - `home_screen.dart`: IndexedStack mantido; tabs com BottomNav dark + Rosso Corsa; mission cards em canvas-elevated com BeBadgePill; aba Tribo com placeholder editorial (icon + displayMd).
  - `journey/dashboard_screen.dart`: gradientes roxos removidos, BeCard em canvasElevated, level progress bar em Rosso Corsa, skill cards grid 2-up com canvas+canvasElevated, runs list em BeCard, coach tip com ícone em container primary.
  - `journey/trail_detail_screen.dart`: AI card em BeCard (border primary quando adaptado), stage cards em canvasElevated com border green/rosso/hairline conforme estado, "FALHEI, ADAPTAR" em captionUppercase primary, recorde em container primary border.
  - `profile_screen.dart`: avatar circle border primary 1px, métricas em BeCard (3 colunas), IMC card lúdico ("NINJA ÁGIL"/"MÁQUINA ESTÉTICA"/"TANQUE DE GUERRA"/"JUGGERNAUT ROUGH") com badges semantic em canvasElevated e hairline color, skills em Wrap de BeBadgePill.
  - `running_screen.dart`: GPS status com border hairline, canvas do trajeto em canvasElevated, cronômetro 72px em numberDisplay, métricas com divisores hairline 1px, botão circular primary/canvasElevated, RoutePainter em Rosso Corsa com start verde + ponta ink/rosso.
  - `run_summary_screen.dart`: hero card em canvasElevated com border primary .withOpacity(.3) (info-only), stats overlay em canvas .85, hero stats pares com semantic colors, BeOutlineButton "Compartilhar" + BePrimaryButton "Salvar no Histórico".
  - `run_history_screen.dart`: cards em canvasElevated, aspect 16/9 mini-mapa em canvas com RoutePainter, FAB extended Rosso Corsa sharp corners uppercase, BeBadgePill para data.
  - `ai_coach_screen.dart`: bottom hairline 1px, bubbles em primary (user) / canvasElevated (bot) com border hairline, ícone do coach em container canvasElevated com border, input com beInputDecoration, send button em círculo primary.
- [x] Apagado o código morto restante `lib/screens/run/RunTrackingScreen.dart` (e pasta `run/` vazia) — referência experimental descontinuada, fluxo oficial fecha em `RunningScreen`.
- [x] `flutter analyze` rodado após cada ajuste; estado final: **0 errors, 0 warnings**, 21 infos (todos `.withOpacity` deprecation do Flutter 3.41).
- [x] Erros de regressão capturados durante o processo:
  - `const TextTheme` rejeitava `BeFonts.bodyMdInk` (não const por causa do `copyWith`). Fix: promovi `bodyMdInk`/`bodyMdOnLight` a `const TextStyle(...)` diretos.
  - `BeRadii.xxs` não existe (é `BeSpacing.xxs`). Fix no dashboard.

#### Arquivos modificados nesta sessão
- `lib/design/tokens.dart` (NOVO)
- `lib/design/ui.dart` (NOVO)
- `lib/main.dart` (tema Ferrari completo)
- `lib/screens/auth/onboarding_screen.dart`
- `lib/screens/auth_screen.dart`
- `lib/screens/auth/signup_screen.dart`
- `lib/screens/skill_selection_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/journey/dashboard_screen.dart`
- `lib/screens/journey/trail_detail_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/running_screen.dart`
- `lib/screens/run_summary_screen.dart`
- `lib/screens/run_history_screen.dart`
- `lib/screens/ai_coach_screen.dart`
- `lib/screens/run/RunTrackingScreen.dart` (DELETADO)
- `contexto/README.md`, `erros_comuns.md`, `licoes_aprendidas.md`, `checlist_refatoracao.md` (NOVOS)
- `.skill/beRough_log.md` (atualizado)

---

### Sessão 03 - Ajustes de UX: jornadas filtradas, mapa real e perfil de usuário (28/07/2026)
- [x] **Jornada filtra trilhas selecionadas**: a aba Jornada em `home_screen.dart` não mostra mais TODAS as skills disponíveis. Agora lista APENAS as que o usuário marcou em `AppState.selectedSkillIds`, cada uma com badge `${skill.difficulty} — Missão Ativa` e `OnTap` direto para `TrailDetailScreen`. Quando não há nenhuma selecionada, exibe `_buildEmptyTrilhasCard` (card editorial com ícone + CTA "GERENCIAR TRILHAS"). O comportamento "Snackbar de bloqueado" sumiu porque não há mais cards bloqueados — o fluxo só mostra o que está ativo.
- [x] **Mapa real em `RunningScreen` (Strava-like)**: reintegrado `flutter_map` + `latlong2/latlong.dart` (que estavam no `pubspec`). Agora:
  - `_bootstrapGPS()` pega `getCurrentPosition` antes de habilitar o start.
  - `_isLocating` exibe spinner "Buscando sinal de GPS..." enquanto não tem posição.
  - `FlutterMap` com tiles escuros `cartocdn.com/dark_all` centra na posição inicial do atleta, zoom 17.
  - `PolylineLayer` desenha a rota em Rosso Corsa em tempo real a partir de `_mapPoints` (lista de `LatLng` espelhada de `_routeCoordinates`).
  - `MarkerLayer` exibe o marcador de posição atual com círculo semi-transparente Rosso Corsa + inner dot.
  - `_mapController.move(...)` reenquadra a câmera a cada novo ponto (seguidor automático).
  - Modo Simulador sintetiza uma posição base em São Paulo e gera trajetória em espiral para testes no emulador sem GPS real.
  - `RoutePainter` (Custom Canvas) mantido como fallback apenas para mini-mapa no histórico e tela de resumo (não precisa de tiles/async).
- [x] **Reescrita de `ProfileScreen` com info pertinente do usuário**:
  - Cabeçalho: avatar editável (câmera/galeria), apelido (`AppState.nickname` com fallback), email.
  - **Card de Nível/XP** (Rosso Corsa) — calculado via `AppState.athleteLevel / currentXP / nextLevelXP` e progress bar; label "Faltam N XP para o nível N+1".
  - **Métricas corporais**: peso/altura/idade (3 cards + IMC card lúdico "NINJA ÁGIL / MÁQUINA ESTÉTICA / TANQUE DE GUERRA / JUGGERNAUT ROUGH").
  - **Estatísticas de corrida** (4 stat cards 2×2): total de corridas, km totais, tempo total "HH:MM:SS", kcal totais — todos agregados via helpers `AppState.totalDistanceMeters / totalRunSeconds / totalCalories / totalDistanceKm / totalTimeFormatted`.
  - **Trilhas & Recordes**: lista das skills selecionadas, cada uma com etapas concluídas ("Etapas: N/3 · Dificuldade") e badge `PR: <record>` ou "Sem PR".
  - **Recordes Pessoais (PRs)**: cada PR salvo em `AppState.userRecords` vira um card próprio com `emoji_events` e check verde.
  - Botão "Ver Histórico de Corridas" → `RunHistoryScreen`.
  - Botão "Sair da Conta" → logout com `AppState.clearUserData()`.
  - AppBar com ícone de "Editar perfil" → abre `SkillSelectionScreen(isEditMode: true)`.
- [x] **AppState enriquecido** com helpers de estatísticas: `athleteLevel`, `currentXP`, `nextLevelXP`, `levelProgress`, `totalDistanceMeters`, `totalRunSeconds`, `totalCalories`, `totalDistanceKm`, `totalTimeFormatted`, `totalCompletedStages`, `totalPRs`. Reaproveitados no Dashboard e no ProfileScreen.
- [x] **Bugs corrigidos** capturados nesta sessão (registrados em `contexto/erros_comuns.md`):
  - Conflito `Path` (flutter_map vs Flutter) — resolvido com `import 'package:flutter/material.dart' hide Path;` + `dart:ui as ui` + `ui.Path()`.
  - Import incorreto `latlong2/latlong2.dart` → correto é `latlong2/latlong.dart` (apenas `latlong2/latlong.dart` exporta a classe `LatLng`).
  - `_subLabel` não referenciado no Profile → removido.

#### Arquivos modificados nesta sessão
- `lib/app_state.dart` (helpers de estatística)
- `lib/screens/home_screen.dart` (filtro aplicado, empty state)
- `lib/screens/running_screen.dart` (flutter_map + mapa Strava-like)
- `lib/screens/profile_screen.dart` (reescrita completa)
- `.skill/beRough_log.md` (atualizado)
- `contexto/erros_comuns.md`, `contexto/licoes_aprendidas.md` (atualizados)

---

## Como atualizar este log
Ao concluir uma nova sessão de trabalho no projeto, adicione uma nova entrada em **Sessões de Melhoria** com:
- Data
- Lista de checkboxes `[x]` das melhorias/fixes aplicados
- Atualização do estado das Fases na seção **Histórico de Etapas Concluídas** se aplicável.
Mantenha os Débitos Técnicos atualizados.