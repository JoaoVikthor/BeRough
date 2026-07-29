import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../app_state.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';
import '../profile_screen.dart';
import '../running_screen.dart';
import '../run_history_screen.dart';
import 'trail_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _kImageBox = 88;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String athleteName = user?.displayName ?? "Atleta BeRough";

    final activeSkills = AppState.instance.availableSkills
        .where((s) => AppState.instance.selectedSkillIds.contains(s.id))
        .toList();

    final runs = AppState.instance.runHistory;

    final int completedExercises = runs.length;
    final int currentLevel = (completedExercises ~/ 3) + 1;
    final int currentXP = completedExercises * 50;
    final int nextLevelXP = currentLevel * 150;
    final double levelProgress =
        nextLevelXP > 0 ? (currentXP / nextLevelXP).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: _buildAppBar(user, athleteName, context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLevelCard(currentLevel, currentXP, nextLevelXP, levelProgress),
              const SizedBox(height: BeSpacing.sm),

              const BeSectionLabel("Suas Metas Ativas"),
              const SizedBox(height: BeSpacing.xxs),
              activeSkills.isEmpty
                  ? _buildEmptySkillsCard()
                  : _buildSkillsList(activeSkills),
              const SizedBox(height: BeSpacing.sm),

              SizedBox(
                width: double.infinity,
                child: BePrimaryButton(
                  label: "Iniciar Corrida com GPS",
                  icon: Icons.satellite_alt,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RunningScreen()),
                  ).then((_) {
                    if (mounted) setState(() {});
                  }),
                ),
              ),
              const SizedBox(height: BeSpacing.sm),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BeSectionLabel("Histórico de Corridas"),
                  if (runs.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RunHistoryScreen()),
                      ).then((_) {
                        if (mounted) setState(() {});
                      }),
                      child: Text("VER TUDO",
                          style: BeFonts.captionUppercase.copyWith(
                              color: BeColors.primary,
                              fontSize: 10)),
                    ),
                ],
              ),
              const SizedBox(height: BeSpacing.xxs),
              runs.isEmpty ? _buildEmptyRunsCard() : _buildRunsList(runs),
              const SizedBox(height: BeSpacing.sm),

              const BeSectionLabel("Conselho do Treinador"),
              const SizedBox(height: BeSpacing.xxs),
              _buildCoachTip(),
              const SizedBox(height: BeSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(User? user, String athleteName, BuildContext context) {
    ImageProvider? avatarImage;
    if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      if (user.photoURL!.startsWith('http')) {
        avatarImage = NetworkImage(user.photoURL!);
      } else {
        avatarImage = FileImage(File(user.photoURL!));
      }
    }

    return AppBar(
      backgroundColor: BeColors.canvas,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("FORÇA & RAÇA",
              style: BeFonts.captionUppercase.copyWith(
                  color: BeColors.primary,
                  fontSize: 10,
                  letterSpacing: 1.4)),
          Text(athleteName.toUpperCase(),
              style: BeFonts.titleMd.copyWith(
                  fontSize: 16, letterSpacing: 0.2)),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BeColors.primary, width: 1),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: BeColors.canvasElevated,
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? const Icon(Icons.person, size: 18, color: BeColors.ink)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(int level, int currentXP, int nextLevelXP, double progress) {
    return BeCard(
      padding: const EdgeInsets.all(BeSpacing.xs),
      borderColor: BeColors.hairline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ATLETA ROUGH NÍVEL $level",
                  style: BeFonts.titleMd.copyWith(fontSize: 16)),
              BeBadgePill(
                label: "XPs: $currentXP / $nextLevelXP",
                background: BeColors.primary.withOpacity(0.12),
                foreground: BeColors.primary,
              ),
            ],
          ),
          const SizedBox(height: BeSpacing.xxs),
          ClipRRect(
            borderRadius: BorderRadius.circular(BeSpacing.xxxs),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: BeColors.canvasElevated,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(BeColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySkillsCard() {
    return BeCard(
      borderColor: BeColors.hairline,
      child: Text(
        "Nenhuma habilidade em foco.",
        textAlign: TextAlign.center,
        style: BeFonts.bodyMd.copyWith(color: BeColors.muted),
      ),
    );
  }

  Widget _buildSkillsList(List<dynamic> skills) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.95,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        final int completed = AppState.instance.completedStages[skill.id] ?? 0;
        final double skillProgress = (completed / 3.0).clamp(0.0, 1.0);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TrailDetailScreen(skill: skill)),
          ).then((_) {
            if (mounted) setState(() {});
          }),
          child: Container(
            decoration: BoxDecoration(
              color: BeColors.canvasElevated,
              border: Border.all(color: BeColors.hairline, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: BeColors.canvas,
                    child: Center(
                      child: Icon(Icons.image_outlined,
                          color: BeColors.muted, size: _kImageBox / 2.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(BeSpacing.xxs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          skill.name.toUpperCase(),
                          style: BeFonts.captionUppercase.copyWith(
                              color: BeColors.ink,
                              fontSize: 10,
                              letterSpacing: 0.8),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: skillProgress,
                              backgroundColor: BeColors.canvasElevated,
                              color: BeColors.primary,
                              strokeWidth: 2,
                            ),
                            Center(
                              child: Text(
                                "${(skillProgress * 100).toInt()}%",
                                style: BeFonts.caption.copyWith(
                                    color: BeColors.ink,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyRunsCard() {
    return BeCard(
      borderColor: BeColors.hairline,
      child: Text(
        "Nenhuma corrida registrada.",
        textAlign: TextAlign.center,
        style: BeFonts.bodyMd.copyWith(color: BeColors.muted),
      ),
    );
  }

  Widget _buildRunsList(List<dynamic> runs) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: runs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final run = runs[index];
        final double km = run.distanceInMeters / 1000;
        return BeCard(
          padding: const EdgeInsets.all(BeSpacing.xs),
          borderColor: BeColors.hairline,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${km.toStringAsFixed(2)} km",
                  style: BeFonts.titleMd.copyWith(fontSize: 16)),
              Text("Pace: ${run.pace}",
                  style: BeFonts.bodyMd.copyWith(
                      color: BeColors.primary,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoachTip() {
    return BeCard(
      padding: const EdgeInsets.all(BeSpacing.xs),
      borderColor: BeColors.hairline,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BeColors.primary.withOpacity(0.12),
              border: Border.all(color: BeColors.primary, width: 1),
            ),
            child: const Icon(Icons.sports,
                color: BeColors.primary, size: 22),
          ),
          const SizedBox(width: BeSpacing.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("DICA DO TREINADOR",
                    style: BeFonts.captionUppercase.copyWith(
                        color: BeColors.ink, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Text(
                  "Não pule as etapas da sua jornada. Consistência vence o talento a longo prazo. Ajuste suas cargas hoje e mantenha a execução perfeita!",
                  style: BeFonts.bodySm.copyWith(color: BeColors.body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}