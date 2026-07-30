import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';

/// Árvore de Evolução — mapa vertical de nodes circulares conectados,
/// representando os níveis de progressão do atleta em calistenia
/// (Iniciante → Básico → Intermediário → Avançado → Elite).
///
/// Cada node mostra ícone, título do nível e badge de skills
/// desbloqueadas/total. Tocar um node desbloqueado abre um dialog com as
/// skills daquele nível.
class EvolutionTreeScreen extends StatefulWidget {
  const EvolutionTreeScreen({super.key});

  @override
  State<EvolutionTreeScreen> createState() => _EvolutionTreeScreenState();
}

class _EvolutionTreeScreenState extends State<EvolutionTreeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  static const List<String> _kLevelOrder = [
    'Iniciante',
    'Básico',
    'Intermediário',
    'Avançado',
    'Elite',
  ];

  static const Map<String, IconData> _kLevelIcons = {
    'Iniciante': Icons.fitness_center,
    'Básico': Icons.accessibility_new,
    'Intermediário': Icons.sports_gymnastics,
    'Avançado': Icons.arrow_upward,
    'Elite': Icons.military_tech,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<_LevelData> _buildLevels() {
    final skills = AppState.instance.availableSkills;
    final selected = AppState.instance.selectedSkillIds.toSet();
    final completed = AppState.instance.completedStages;

    final Map<String, List<CalisthenicsSkill>> grouped = {};
    for (final skill in skills) {
      grouped.putIfAbsent(skill.difficulty, () => []).add(skill);
    }

    final List<_LevelData> levels = [];
    for (final name in _kLevelOrder) {
      final list = grouped[name] ?? const <CalisthenicsSkill>[];
      int unlocked = 0;
      for (final s in list) {
        if (selected.contains(s.id) || (completed[s.id] ?? 0) > 0) {
          unlocked++;
        }
      }
      levels.add(_LevelData(
        name: name,
        skills: list,
        unlocked: unlocked,
      ));
    }

    bool frontierOpen = true;
    for (final level in levels) {
      if (level.total == 0) {
        level.state = _EvolutionState.locked;
        continue;
      }
      if (level.unlocked >= level.total) {
        level.state = _EvolutionState.unlocked;
        continue;
      }
      if (frontierOpen) {
        level.state = _EvolutionState.current;
        frontierOpen = false;
      } else {
        level.state = _EvolutionState.locked;
      }
    }
    return levels;
  }

  void _openLevelDialog(_LevelData level) {
    if (level.state == _EvolutionState.locked) return;
    showDialog<void>(
      context: context,
      builder: (_) => _LevelDialog(level: level),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levels = _buildLevels();

    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: AppBar(
        backgroundColor: BeColors.canvas,
        foregroundColor: BeColors.ink,
        elevation: 0,
        centerTitle: true,
        title: Text('ÁRVORE DE EVOLUÇÃO', style: BeFonts.titleMd),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: BeSpacing.xs,
            vertical: BeSpacing.sm,
          ),
          child: Column(
            children: [
              const SizedBox(height: BeSpacing.xxs),
              for (int i = 0; i < levels.length; i++) ...[
                _EvolutionNode(
                  data: levels[i],
                  pulseScale: _pulseScale,
                  onTap: () => _openLevelDialog(levels[i]),
                ),
                if (i < levels.length - 1)
                  _EvolutionConnector(
                    unlocked: levels[i].state != _EvolutionState.locked,
                  ),
              ],
              const SizedBox(height: BeSpacing.lg),
              BeOutlineButton(
                label: 'VOLTAR PARA JORNADA',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: BeSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

enum _EvolutionState { locked, current, unlocked }

class _LevelData {
  final String name;
  final List<CalisthenicsSkill> skills;
  final int unlocked;

  _LevelData({
    required this.name,
    required this.skills,
    required this.unlocked,
  });

  int get total => skills.length;
  _EvolutionState state = _EvolutionState.locked;
}

class _EvolutionNode extends StatelessWidget {
  final _LevelData data;
  final Animation<double> pulseScale;
  final VoidCallback onTap;

  const _EvolutionNode({
    required this.data,
    required this.pulseScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = data.state == _EvolutionState.current;
    final isUnlocked = data.state == _EvolutionState.unlocked;
    final isLocked = data.state == _EvolutionState.locked;

    final Color ringColor = isLocked
        ? BeColors.canvasElevated
        : BeColors.primary;
    final Color iconColor = isLocked ? BeColors.muted : BeColors.ink;
    final Color titleColor = isLocked ? BeColors.muted : BeColors.ink;
    final Color badgeBg = isLocked
        ? BeColors.canvasElevated
        : BeColors.primary;
    final Color badgeFg = isLocked ? BeColors.muted : BeColors.onPrimary;

    final IconData levelIcon = _EvolutionTreeScreenState._kLevelIcons[data.name] ??
        Icons.fitness_center;
    final IconData overlayIcon =
        isLocked ? Icons.lock : (isUnlocked ? Icons.check : Icons.play_arrow);

    Widget circle = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: ringColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isLocked ? BeColors.hairline : BeColors.primary,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(levelIcon, color: iconColor, size: 36),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: BeColors.canvas,
                shape: BoxShape.circle,
                border: Border.all(color: BeColors.hairline, width: 1),
              ),
              child: Icon(overlayIcon, color: iconColor, size: 14),
            ),
          ),
        ],
      ),
    );

    if (isCurrent) {
      circle = ScaleTransition(scale: pulseScale, child: circle);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            circle,
            const SizedBox(height: BeSpacing.xxs),
            Text(
              data.name.toUpperCase(),
              style: BeFonts.captionUppercase.copyWith(color: titleColor),
            ),
            const SizedBox(height: BeSpacing.xxxs),
            BeBadgePill(
              label: '${data.unlocked}/${data.total}',
              background: badgeBg,
              foreground: badgeFg,
            ),
          ],
        ),
      ),
    );
  }
}

class _EvolutionConnector extends StatelessWidget {
  final bool unlocked;
  const _EvolutionConnector({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: CustomPaint(
        painter: _ConnectorPainter(unlocked: unlocked),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final bool unlocked;
  const _ConnectorPainter({required this.unlocked});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = unlocked ? BeColors.primary : BeColors.hairline
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final path = Path();
    path.moveTo(cx, 0.0);
    path.cubicTo(cx, h * 0.5, cx, h * 0.5, cx, h);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.unlocked != unlocked;
}

class _LevelDialog extends StatelessWidget {
  final _LevelData level;
  const _LevelDialog({required this.level});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BeColors.canvasElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: BeColors.hairline, width: 1),
      ),
      title: Text(
        level.name.toUpperCase(),
        style: BeFonts.titleMd,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: level.skills.isEmpty
            ? Text(
                'Nenhuma skill mapeada para este nível ainda.',
                style: BeFonts.bodyMd,
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: level.skills.length,
                separatorBuilder: (context, index) => const BeHairline(),
                itemBuilder: (_, i) {
                  final skill = level.skills[i];
                  final isSelected = AppState.instance.selectedSkillIds
                      .contains(skill.id);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: BeSpacing.xxs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? BeColors.primary
                              : BeColors.muted,
                          size: 18,
                        ),
                        const SizedBox(width: BeSpacing.xxs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(skill.name, style: BeFonts.titleSm),
                              const SizedBox(height: 2),
                              Text(skill.category, style: BeFonts.bodySm),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        BeOutlineButton(
          label: 'FECHAR',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}