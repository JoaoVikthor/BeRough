import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';
import '../running_screen.dart';
import '../journey/trail_detail_screen.dart';

class TrainingOptionsScreen extends StatefulWidget {
  const TrainingOptionsScreen({super.key});

  @override
  State<TrainingOptionsScreen> createState() => _TrainingOptionsScreenState();
}

class _TrainingOptionsScreenState extends State<TrainingOptionsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AppState.instance.loadFromDisk();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _handleTap(_TrainingOption option) {
    switch (option.id) {
      case 'guided_trail':
        final skills = AppState.instance.selectedSkillIds;
        if (skills.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecione uma trilha primeiro.')),
          );
          return;
        }
        final skillId = skills.first;
        final skill = AppState.instance.availableSkills.firstWhere(
          (s) => s.id == skillId,
          orElse: () => AppState.instance.availableSkills.first,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrailDetailScreen(skill: skill),
          ),
        );
        break;
      case 'gps_run':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RunningScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Em breve')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeColors.canvas,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: BeColors.primary),
              )
            : Column(
                children: [
                  const _Header(),
                  Expanded(
                    child: _TrainingOptionsGrid(
                      options: _buildOptions(),
                      onTap: _handleTap,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BeSpacing.xs,
                      BeSpacing.xs,
                      BeSpacing.xs,
                      BeSpacing.sm,
                    ),
                    child: BeOutlineButton(
                      label: 'VOLTAR',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<_TrainingOption> _buildOptions() {
    return const [
      _TrainingOption(
        id: 'guided_trail',
        title: 'Trilha Guiada',
        description: 'Siga a trilha progressiva calibrada',
        duration: '15-30 min',
        icon: Icons.route,
      ),
      _TrainingOption(
        id: 'free_workout',
        title: 'Treino Livre',
        description: 'Escolha exercícios individuais',
        duration: '10-45 min',
        icon: Icons.fitness_center,
      ),
      _TrainingOption(
        id: 'gps_run',
        title: 'Corrida GPS',
        description: 'Rastreamento em tempo real',
        duration: '20-60 min',
        icon: Icons.directions_run,
      ),
      _TrainingOption(
        id: 'flash_challenge',
        title: 'Desafio Relâmpago',
        description: 'Sequência intensa curta',
        duration: '5-10 min',
        icon: Icons.bolt,
      ),
      _TrainingOption(
        id: 'active_recovery',
        title: 'Recuperação Ativa',
        description: 'Mobilidade e alongamento',
        duration: '10-15 min',
        icon: Icons.self_improvement,
      ),
      _TrainingOption(
        id: 'assessment',
        title: 'Avaliação',
        description: 'Teste seu baseline',
        duration: '5-20 min',
        icon: Icons.fact_check,
      ),
    ];
  }
}

class _TrainingOption {
  final String id;
  final String title;
  final String description;
  final String duration;
  final IconData icon;

  const _TrainingOption({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.icon,
  });
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BeSpacing.xs,
        BeSpacing.sm,
        BeSpacing.xs,
        BeSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPÇÕES DE TREINO',
            style: BeFonts.displayMd.copyWith(
              fontSize: 28,
              letterSpacing: -0.28,
            ),
          ),
          const SizedBox(height: BeSpacing.xxs),
          Text(
            'Escolha como treinar hoje',
            style: BeFonts.bodyMd.copyWith(color: BeColors.body),
          ),
          const SizedBox(height: BeSpacing.xs),
          const BeHairline(),
        ],
      ),
    );
  }
}

class _TrainingOptionsGrid extends StatelessWidget {
  final List<_TrainingOption> options;
  final ValueChanged<_TrainingOption> onTap;

  const _TrainingOptionsGrid({required this.options, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 48,
              color: BeColors.muted,
            ),
            const SizedBox(height: BeSpacing.xs),
            Text(
              'Nenhuma opção disponível',
              style: BeFonts.bodyMd.copyWith(color: BeColors.body),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        BeSpacing.xs,
        BeSpacing.xs,
        BeSpacing.xs,
        BeSpacing.sm,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: BeSpacing.xs,
          crossAxisSpacing: BeSpacing.xs,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final option = options[index];
          return _OptionCard(
            option: option,
            onTap: () => onTap(option),
          );
        },
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final _TrainingOption option;
  final VoidCallback onTap;

  const _OptionCard({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: BeCard(
        padding: const EdgeInsets.all(BeSpacing.xs),
        borderColor: BeColors.hairline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(option.icon, size: 40, color: BeColors.primary),
            const SizedBox(height: BeSpacing.xs),
            Text(
              option.title,
              style: BeFonts.titleSm.copyWith(color: BeColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: BeSpacing.xxxs),
            Expanded(
              child: Text(
                option.description,
                style: BeFonts.caption.copyWith(color: BeColors.body),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: BeSpacing.xxs),
            Align(
              alignment: Alignment.bottomLeft,
              child: BeBadgePill(label: option.duration),
            ),
          ],
        ),
      ),
    );
  }
}