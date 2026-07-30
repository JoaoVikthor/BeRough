import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';

/// Modelo interno de um post da comunidade para exibição no feed social.
class CommunityPost {
  final String id;
  final String authorName;
  final String? avatarUrl;
  final String title;
  final String timeAgo;
  final int durationMinutes;
  final int starsCount;
  final int exercisesCount;
  final int xpEarned;
  final String levelBadge;
  final List<String> exercisePlaceholders;
  int likesCount;
  bool isLiked;

  CommunityPost({
    required this.id,
    required this.authorName,
    this.avatarUrl,
    required this.title,
    required this.timeAgo,
    required this.durationMinutes,
    required this.starsCount,
    required this.exercisesCount,
    required this.xpEarned,
    required this.levelBadge,
    required this.exercisePlaceholders,
    this.likesCount = 0,
    this.isLiked = false,
  });
}

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final List<CommunityPost> _posts = [
    CommunityPost(
      id: '1',
      authorName: 'magoma',
      title: 'Rutina básica',
      timeAgo: 'Há 35 min',
      durationMinutes: 18,
      starsCount: 0,
      exercisesCount: 7,
      xpEarned: 517,
      levelBadge: 'Iniciante',
      likesCount: 12,
      exercisePlaceholders: [
        'Flexões',
        'Agachamentos',
        'Prancha',
        'Abdominais',
        'Polichinelos',
        'Afundo'
      ],
    ),
    CommunityPost(
      id: '2',
      authorName: 'marinusvincent',
      title: 'Sessão Força Neural',
      timeAgo: 'Há 36 min',
      durationMinutes: 23,
      starsCount: 13,
      exercisesCount: 9,
      xpEarned: 994,
      levelBadge: 'Intermediário',
      likesCount: 24,
      exercisePlaceholders: [
        'Barra Fixa',
        'Paralelas',
        'Handstand Prep',
        'L-Sit Hold',
        'Flexão Diamante',
        'Pistol Squat'
      ],
    ),
    CommunityPost(
      id: '3',
      authorName: 'Atleta Rough',
      title: 'Corrida de Resistência 5K',
      timeAgo: 'Há 42 min',
      durationMinutes: 35,
      starsCount: 7,
      exercisesCount: 10,
      xpEarned: 980,
      levelBadge: 'Avançado',
      likesCount: 18,
      exercisePlaceholders: [
        'Corrida 5K',
        'Aquecimento',
        'Tiros de Reta',
        'Educativos',
        'Stretching',
        'Recuperação'
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: BeSpacing.sm),
              const _CommunityHeader(),
              const SizedBox(height: BeSpacing.xs),
              const _PersonalStatsBanner(),
              const SizedBox(height: BeSpacing.sm),
              const BeSectionLabel("ATIVIDADE RECENTE"),
              const SizedBox(height: BeSpacing.xs),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: BeSpacing.xs),
                    child: _CommunityPostCard(
                      post: post,
                      onLikePressed: () {
                        setState(() {
                          post.isLiked = !post.isLiked;
                          post.likesCount += post.isLiked ? 1 : -1;
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: BeSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TRIBO",
          style: BeFonts.displayMd.copyWith(
            fontSize: 28,
            letterSpacing: -0.28,
            color: BeColors.ink,
          ),
        ),
        const SizedBox(height: BeSpacing.xxs),
        Text(
          "Mantenha-se no caminho com a comunidade de atletas BeRough.",
          style: BeFonts.bodyMd.copyWith(color: BeColors.body),
        ),
      ],
    );
  }
}

class _PersonalStatsBanner extends StatelessWidget {
  const _PersonalStatsBanner();

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final nickname = state.nickname.isNotEmpty ? state.nickname : "Atleta";
    final totalRuns = state.runHistory.length;
    final xp = state.currentXP;

    return BeCard(
      borderColor: BeColors.primary.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(BeSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: BeColors.primary,
                    child: Icon(Icons.person, color: BeColors.onPrimary, size: 20),
                  ),
                  const SizedBox(width: BeSpacing.xxs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: BeFonts.titleSm.copyWith(color: BeColors.ink),
                      ),
                      Text(
                        "Nível ${state.athleteLevel} • Atleta Rough",
                        style: BeFonts.caption.copyWith(color: BeColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
              BeBadgePill(
                label: "$xp XP",
                background: BeColors.primary.withValues(alpha: 0.15),
                foreground: BeColors.primary,
              ),
            ],
          ),
          const SizedBox(height: BeSpacing.xs),
          const BeHairline(),
          const SizedBox(height: BeSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                icon: Icons.timer_outlined,
                value: state.totalTimeFormatted,
                label: "Tempo Total",
              ),
              _StatChip(
                icon: Icons.star_border_rounded,
                value: "${state.totalCompletedStages}",
                label: "Etapas Concluídas",
              ),
              _StatChip(
                icon: Icons.fitness_center_outlined,
                value: "$totalRuns",
                label: "Treinos",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: BeColors.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: BeFonts.titleSm.copyWith(fontSize: 14, color: BeColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: BeFonts.caption.copyWith(fontSize: 11, color: BeColors.muted),
        ),
      ],
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onLikePressed;

  const _CommunityPostCard({
    required this.post,
    required this.onLikePressed,
  });

  @override
  Widget build(BuildContext context) {
    return BeCard(
      padding: const EdgeInsets.all(BeSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Usuário
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: BeColors.canvas,
                    child: Text(
                      post.authorName.isNotEmpty
                          ? post.authorName[0].toUpperCase()
                          : 'A',
                      style: BeFonts.captionUppercase
                          .copyWith(color: BeColors.primary),
                    ),
                  ),
                  const SizedBox(width: BeSpacing.xxs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: BeFonts.titleSm.copyWith(
                          fontSize: 14,
                          color: BeColors.ink,
                        ),
                      ),
                      Text(
                        post.timeAgo,
                        style: BeFonts.caption.copyWith(color: BeColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
              BeBadgePill(
                label: post.levelBadge,
                background: BeColors.canvas,
                foreground: BeColors.muted,
              ),
            ],
          ),
          const SizedBox(height: BeSpacing.xs),

          // Título do Treino
          Text(
            post.title,
            style: BeFonts.titleMd.copyWith(fontSize: 18, color: BeColors.ink),
          ),
          const SizedBox(height: BeSpacing.xxs),

          // Métricas do Treino
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: BeColors.muted),
              const SizedBox(width: 4),
              Text(
                '${post.durationMinutes}m',
                style: BeFonts.caption.copyWith(color: BeColors.body),
              ),
              const SizedBox(width: BeSpacing.xs),
              Icon(Icons.star_rounded, size: 14, color: BeColors.accentYellow),
              const SizedBox(width: 4),
              Text(
                '${post.starsCount}',
                style: BeFonts.caption.copyWith(color: BeColors.body),
              ),
              const SizedBox(width: BeSpacing.xs),
              Icon(Icons.fitness_center_rounded,
                  size: 14, color: BeColors.muted),
              const SizedBox(width: 4),
              Text(
                '${post.exercisesCount} exerc.',
                style: BeFonts.caption.copyWith(color: BeColors.body),
              ),
              const Spacer(),
              Text(
                '+${post.xpEarned} XP',
                style: BeFonts.captionUppercase.copyWith(
                  color: BeColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: BeSpacing.xs),

          // Grid de Thumbnails dos Exercícios
          _ExerciseThumbnailsGrid(exercises: post.exercisePlaceholders),
          const SizedBox(height: BeSpacing.xs),

          const BeHairline(),
          const SizedBox(height: BeSpacing.xxs),

          // Rodapé do Post (Interações)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: onLikePressed,
                icon: Icon(
                  post.isLiked ? Icons.local_fire_department : Icons.local_fire_department_outlined,
                  size: 18,
                  color: post.isLiked ? BeColors.primary : BeColors.muted,
                ),
                label: Text(
                  post.isLiked ? 'FORÇA! (${post.likesCount})' : 'FORÇA & RAÇA (${post.likesCount})',
                  style: BeFonts.captionUppercase.copyWith(
                    color: post.isLiked ? BeColors.primary : BeColors.muted,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 18, color: BeColors.muted),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link do treino copiado!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseThumbnailsGrid extends StatelessWidget {
  final List<String> exercises;

  const _ExerciseThumbnailsGrid({required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BeSpacing.xxs),
      decoration: BoxDecoration(
        color: BeColors.canvas,
        borderRadius: BorderRadius.circular(BeRadii.sm),
        border: Border.all(color: BeColors.hairline, width: 1),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 2.2,
        ),
        itemCount: exercises.take(6).length,
        itemBuilder: (context, index) {
          final exerciseName = exercises[index];
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: BeColors.canvasElevated,
              borderRadius: BorderRadius.circular(BeRadii.xs),
              border: Border.all(color: BeColors.hairline, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center, size: 12, color: BeColors.primary),
                const SizedBox(height: 2),
                Text(
                  exerciseName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BeFonts.caption.copyWith(fontSize: 10, color: BeColors.ink),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
