import 'package:flutter/material.dart';
import '../app_state.dart';
import '../design/tokens.dart';
import '../design/ui.dart';
import 'journey/dashboard_screen.dart';
import 'journey/trail_detail_screen.dart';
import 'running_screen.dart';
import 'skill_selection_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      _buildJourneyTab(),
      _buildTriboPlaceholder(),
      const ProfileScreen(),
    ];
  }

  IconData _getSkillIcon(String iconName) {
    switch (iconName) {
      case 'arrow_upward': return Icons.arrow_upward_rounded;
      case 'sports_gymnastics': return Icons.sports_gymnastics_rounded;
      case 'horizontal_rule': return Icons.horizontal_rule_rounded;
      case 'fitness_center': return Icons.fitness_center_rounded;
      case 'flag': return Icons.flag_rounded;
      case 'accessibility_new': return Icons.accessibility_new_rounded;
      default: return Icons.fitness_center;
    }
  }

  Widget _buildTriboPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BeSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined,
                size: 64, color: BeColors.muted),
            const SizedBox(height: BeSpacing.xs),
            Text(
              "TRIBO\nEm Breve",
              textAlign: TextAlign.center,
              style: BeFonts.displayMd.copyWith(
                  color: BeColors.muted, fontSize: 22, letterSpacing: -0.22),
            ),
            const SizedBox(height: BeSpacing.xxs),
            Text(
              "Comunidade e feed social para os atletas BeRough.",
              textAlign: TextAlign.center,
              style: BeFonts.bodyMd.copyWith(color: BeColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyTab() {
    return Builder(
      builder: (context) {
        final selectedIds = AppState.instance.selectedSkillIds;
        // Mostra APENAS as trilhas que o usuário selecionou previamente.
        final selectedSkills = AppState.instance.availableSkills
            .where((s) => selectedIds.contains(s.id))
            .toList();

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: BeSpacing.sm),
                Text(
                  "SUA JORNADA",
                  style: BeFonts.displayMd.copyWith(
                      fontSize: 28, letterSpacing: -0.28, color: BeColors.ink),
                ),
                const SizedBox(height: BeSpacing.xxs),
                Text(
                  "As missões disponíveis refletem diretamente as escolhas do seu perfil.",
                  style: BeFonts.bodyMd.copyWith(color: BeColors.body),
                ),
                const SizedBox(height: BeSpacing.sm),

                _buildMissionCard(
                  context,
                  title: "Corrida ao Ar Livre",
                  subtitle: "Rastreamento por GPS em tempo real",
                  description:
                      "Monitore seu trajeto no mapa, calcule seu ritmo (pace) e meça suas calorias de forma real.",
                  isActive: true,
                  badgeText: "Cardio Ativo",
                  icon: Icons.directions_run_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RunningScreen()),
                  ),
                ),
                const SizedBox(height: BeSpacing.xs),

                if (selectedSkills.isEmpty)
                  _buildEmptyTrilhasCard(context)
                else
                  ...selectedSkills.map((skill) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: BeSpacing.xxs),
                      child: _buildMissionCard(
                        context,
                        title: "Desafio ${skill.name}",
                        subtitle: skill.category,
                        description:
                            "Progressões com o peso corporal focadas no desenvolvimento de força neural para ${skill.name}.",
                        isActive: true,
                        badgeText: "${skill.difficulty} — Missão Ativa",
                        icon: _getSkillIcon(skill.iconName),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TrailDetailScreen(skill: skill),
                          ),
                        ).then((_) => setState(() {})),
                      ),
                    );
                  }),

                const SizedBox(height: BeSpacing.xxs),
                SizedBox(
                  width: double.infinity,
                  child: BeOutlineButton(
                    label: "Gerenciar Trilhas",
                    icon: Icons.add_circle_outline,
                    onPressed: () async {
                      final bool? updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SkillSelectionScreen(isEditMode: true),
                        ),
                      );
                      if (updated == true && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(height: BeSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTrilhasCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BeSpacing.sm),
      decoration: BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border.all(color: BeColors.hairline, width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.map_outlined, size: 48, color: BeColors.muted),
          const SizedBox(height: BeSpacing.xs),
          Text(
            "Nenhuma trilha selecionada ainda.",
            style: BeFonts.titleMd.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            "Toque em GERENCIAR TRILHAS para escolher suas metas de treino.",
            textAlign: TextAlign.center,
            style: BeFonts.bodySm.copyWith(color: BeColors.body),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required bool isActive,
    required String badgeText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final Color border = isActive ? BeColors.primary : BeColors.hairline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BeSpacing.xs),
      decoration: BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border.all(color: border, width: isActive ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BeBadgePill(
                label: badgeText,
                background: isActive
                    ? BeColors.primary.withOpacity(0.12)
                    : BeColors.canvasElevated,
                foreground:
                    isActive ? BeColors.primary : BeColors.muted,
              ),
              Icon(icon,
                  color: isActive ? BeColors.primary : BeColors.muted,
                  size: 24),
            ],
          ),
          const SizedBox(height: BeSpacing.xxs),
          Text(title,
              style: BeFonts.titleMd.copyWith(
                color: isActive ? BeColors.ink : BeColors.muted,
                fontSize: 20,
              )),
          Text(subtitle,
              style: BeFonts.caption.copyWith(color: BeColors.muted)),
          const SizedBox(height: BeSpacing.xxs),
          Text(
            description,
            style: BeFonts.bodySm.copyWith(
                color: isActive ? BeColors.body : BeColors.muted),
          ),
          const SizedBox(height: BeSpacing.xs),
          if (isActive)
            SizedBox(
              width: double.infinity,
              child: BePrimaryButton(
                label: "Iniciar Missão",
                onPressed: onTap,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: BeColors.hairline, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: BeColors.canvas,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: BeColors.primary,
          unselectedItemColor: BeColors.muted,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Jornada',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Tribo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}