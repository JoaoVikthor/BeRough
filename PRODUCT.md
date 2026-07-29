# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Atletas amadores e entusiastas de calistenia/corrida de rua que treinam sozinhos, sem personal. Chegam ao app em momentos de treino (diariamente ou algumas vezes por semana), buscando estruturação progressiva para não estagnar nem se lesionar. Estado mental: querem direção clara e feedback de evolução, não montagens aleatórias de treino.

## Product Purpose

BeRough é um app de treinamento progressivo com peso corporal e corrida. Existe para transformar uma meta numérica (ex.: "correr 1 km em 10 min", "fazer 10 flexões") em uma trilha de passos sequenciais — do mais fácil até o alvo final — calibrada à condição atual do atleta. Sucesso significa o usuário concluir cada passo da trilha e atingir a meta que definiu, sentindo progressão mensurável.

## Positioning

Diferencia-se por trilhas geradas dinamicamente a partir de uma corrida/avaliação prévia usada como baseline métrico, dimensionando cada passo do treino segundo a dificuldade do exercício e a meta daquele exercício — não planos genéricos fixos como apps concorrentes.

## Operating Context

Fluxo: onboarding → auth → seleção de trilhas + perfil (peso/altura/idade/apelido + meta por exercício) → dashboard de progresso → aba Jornada com trilhas → tela de exercício passo a passo → tela de parabéns/log de metas. Treinos de corrida usam GPS em tempo real com mapa. Dados persistem localmente (SharedPreferences) hoje; Firestore previsto em fase futura.

## Capabilities and Constraints

- Stack: Flutter (Dart), firebase_auth, geolocator, flutter_map + latlong2, shared_preferences, image_picker, permission_handler, google_generative_ai.
- Tracking de corrida em tempo real via stream de posição GPS; rota desenhada no mapa.
- Progresso de trilhas e recordes persistidos localmente hoje; migração a Firestore é decisão em aberto.
- Decisão em aberto: plataforma `android` registrada — web existe apenas p/ dev; confirmar se haverá build nativo iOS no futuro.

## Brand Commitments

- Nome: BeRough ("Be" + "Rough" — força & raça).
- Voz/marca registrada no app: cue "FORÇA & RAÇA", "ATLETA ROUGH".
- Mundo visual atual: canvas near-black (#181818), accent Rosso Corsa (#DA291C) usado raramente, cantos retos, tipografia Inter (substituto de FerrariSans). — NOTA: o DESIGN.md atual é um template de marketing Ferrari que não reflete fielmente o app; será evoluído nesta fase.
- Restrição confirmada: a trilha passo-a-passo adotará nodes conectados estilo Duolingo como EXCEÇÃO visual à regra de cantos retos, mantendo o canvas dark.

## Evidence on Hand

- Telas implementadas em `lib/screens/`: dashboard, running_screen, run_summary, trail_detail, skill_selection, auth/onboarding, profile, ai_coach.
- Design tokens em `lib/design/tokens.dart` e componentes em `lib/design/ui.dart`.
- Histórico de corridas já captura distância, pace, calorias e rota (`RunLog` em `app_state.dart`).
- Ausências a não fabricar: nenhum logo de marca existe; nenhum gif/vídeo animado de exercício fornecido (placeholders serão previstos).

## Product Principles

1. A meta do usuário é o norte — toda trilha termina no alvo que ele definiu.
2. Progressão calibrada: passos dimensionados pela condição atual (baseline), não por planos fixos.
3. Consistência vence talento: feedback e log de conquistas em cada passo.
4. Rastreio real: corrida com GPS ao vivo e trajeto visível no resumo.
5. Sem invenção de dados: placeholders explícitos onde faltam imagens/vídeos/viz.

## Accessibility & Inclusion

Alvos de toque de 48px já presentes. Pendente: contraste a validar nos novos nodes da trilha e na tela de exercício com mídia.