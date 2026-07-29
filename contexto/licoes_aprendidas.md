# Lições Aprendidas — BeRough

Princípios consolidados a partir de `erros_comuns.md`. Ler antes de iniciar qualquer sessão.

## Fluxo de trabalho
1. **Antes de editar**: rode `grep -r "<Classe>/<método>" lib | Select-String` para mapear referências. Nunca delete um arquivo sem antes confirmar que nada mais o referencia.
2. **Durante a edição**: prefira `write` (reescrita total) quando a refatoração toca >30% de um arquivo médio ou quando há muitos acentos/símbolos. Reserve `edit` para substituições pontuais e únicas.
3. **Depois de editar**: rode `flutter analyze lib` e corrija todos os `warning`/`error`. Imports não usados são um sintoma de refatoração incompleta.
4. **Ao final de uma sessão**: atualize `.skill/beRough_log.md` com a Sessão correspondente e, se houve um erro não-trivial, adicione uma entrada em `contexto/erros_comuns.md`.

## Arquitetura do BeRough
- **Pasta oficial de telas**: `lib/screens/`. Não crie versões raiz duplicadas (ex.: `lib/home_screen.dart`).
- **Estado central**: `lib/app_state.dart` (Singleton). Dados persistem em `SharedPreferences` até a Fase 4 migrar para Firestore.
- **AuthGate** decide a tela inicial em `main.dart`:
  - Logado com perfil salvo → `HomeScreen`
  - Logado sem perfil salvo → `SkillSelectionScreen`
  - Não logado + onboarding visto → `AuthScreen`
  - Não logado + onboarding não visto → `OnboardingScreen`
- **Fluxo pós-auth**: Todo login/cadastro converge para `SkillSelectionScreen`. Não crie variantes como `GoalSettingScreen` — foi removida.
- **Home** usa `IndexedStack` na `screens/home_screen.dart` para preservar estado entre as 4 abas (`Início`, `Jornada`, `Tribo`, `Perfil`). Não troque por body direto.

## Corrida
- **Tela oficial**: `RunningScreen` (agora com **mapa real flutter_map** centrado na posição do atleta + PolylineLayer da rota em Rosso Corsa + MarkerLayer de posição + pause + cronômetro + resumo + histórico).
- **Modo Simulador**: sintetiza uma posição base em São Paulo na primeira vez que é ativado (quando não há GPS real, ex: emulador). Trajetória espiralada para testar desenho no mapa.
- **`RoutePainter`** (Custom Canvas) mantido APENAS como fallback para mini-mapa no `RunHistoryScreen` e trajeto no `RunSummaryScreen` — não usa tiles/async.
- **NÃO** reintroduza um arquivo `run/RunTrackingScreen.dart` separado — o fluxo oficial fecha em `RunningScreen`.
- Calorias usam `AppState.weight`: `kcal ≈ km × pesoKg × 0.9`.
- Ao salvar corrida: `AppState.instance.addRunToHistory(RunLog(...))` — já persiste em disco. Não mexa diretamente em `runHistory.add(...)`.
- **Imports críticos** ao trabalhar com `flutter_map` em `running_screen.dart`:
  - `import 'package:flutter/material.dart' hide Path;` (evita conflito com `Path<T>` do flutter_map)
  - `import 'dart:ui' as ui;` e use `ui.Path()` no CustomPainter
  - `import 'package:latlong2/latlong.dart';` (NÃO `latlong2/latlong2.dart`)

## Persistência
- Use `AppState.loadFromDisk()` no `initState` de telas que precisam dos dados restaurados (ex.: `SkillSelectionScreen` faz isso para pré-preencher controllers).
- Use `AppState.saveProfile()` sempre que alterar métricas/skills/etapas/recordes.
- Use `AppState.clearUserData()` no logout (já chamado em `ProfileScreen`).
- **Helpers de estatística já expostos em `AppState`** — NÃO recalcule localemente:
  - `athleteLevel`, `currentXP`, `nextLevelXP`, `levelProgress`
  - `totalDistanceMeters`, `totalDistanceKm`, `totalRunSeconds`, `totalTimeFormatted`, `totalCalories`
  - `totalCompletedStages`, `totalPRs`
  Reaproveite esses getters no Dashboard e no ProfileScreen; duplicar a lógica quebra em sincronizar com payloads futuros do Firestore.

## Jornada (aba Home)
- Mostrar **APENAS** as skills em `selectedSkillIds`. O `home_screen.dart` filtra `availableSkills.where(selectedIds.contains)` — não volte a iterar sobre TODAS as skills com estado "bloqueado". Se o usuário não selecionou nenhuma, exiba `_buildEmptyTrilhasCard` com CTA para "GERENCIAR TRILHAS".
- Botão "INICIAR MISSÃO" sempre abre `TrailDetailScreen(skill: skill)` direto; não tem mais snackbar "bloqueado".

## Perfil
- A informação pertinente ao usuário inclui: avatar (câmera/galeria/URL Google), apelido, email, nível/XP+progresso, peso/altura/idade, IMC lúdico patente corporal, totais de corridas (qtd/km/tempo/kcal), trilhas ativas com etapas concluídas, PRs salvos, histórico de corridas e logout.
- Estado pode ser editado pelo ícone de "Editar perfil" no AppBar (vai para `SkillSelectionScreen(isEditMode: true)`).
- Ao voltar de qualquer sub-tela, chame `setState(() {})` para refletir novos recordes/etapas/corridas.

## Layout / Design (a partir de DESIGN.md — Sessão 02)
- A `DESIGN.md` é um sistema visual **Ferrari** (não o tema roxo original). **Substituir** todo o tema antigo:
  - Canvas: `#181818` (NÃO preto puro, NÃO `#0D0D12`)
  - Cards/superfícies elevadas: `#303030`
  - Accent: `#da291c` (Rosso Corsa) — usado **raramente** apenas em CTAs primários, marca e highlights de posição.
  - Texto: branco (#FFFFFF), body #969696, muted #666666
  - Hairline #303030 (1px, mesma cor que cards)
- **Bordas**: `0px` sharp em todos os CTAs, cards e bands. Pílulas (radius full) **só** para badges.
- **Tipografia**: Inter (fallback de FerrariSans). Display weight **500** (nunca bold), body 400, CTA 700 uppercase + 1.4px tracking. CTAs usam `letterSpacing: 1.4`.
- **Sombra**: **SEM drop shadows**. Profundidade vem de fotografia + brightness-step (canvas → canvas-elevated) + hairlines 1px.
- **Spacing**: ladder 4/8/16/24/32/48/64/96/128. Nunca valores ad-hoc.
- CTAs primários: altura 48px, padding 14×32px, uppercase 14px / 700 / 1.4px tracking.
- Inputs dark: bg #181818, border hairline 1px #303030, radius 4px, padding 14×16px, altura 48px.
- Inputs em `TextFormField`/`TextField`: não use cores púrpuras focais; border focus em Rosso Corsa.

## Booleans do review
- ✍️ Antes de "testar", lembre: `flutter` no Windows PATH está em `E:\Flutter\flutter_windows_3.41.9-stable\flutter\bin\flutter.bat`. Sempre chame pelo caminho completo no PowerShell.
- ⏱️ GPS em background consome bateria — primeira execução de `running_screen.dart` chama `Geolocator.getPositionStream`. Não inicie o stream se não houver permissão/posição.