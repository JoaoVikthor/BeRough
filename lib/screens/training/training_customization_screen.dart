import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';

class TrainingCustomizationScreen extends StatefulWidget {
  const TrainingCustomizationScreen({super.key});

  @override
  State<TrainingCustomizationScreen> createState() =>
      _TrainingCustomizationScreenState();
}

class _TrainingCustomizationScreenState
    extends State<TrainingCustomizationScreen> {
  static const List<String> _intensityOptions = ['Leve', 'Moderado', 'Intenso'];
  static const List<String> _focusOptions = [
    'Peito',
    'Costas',
    'Pernas',
    'Core',
    'Ombros',
    'Braços',
    'Cardio',
  ];

  static const Map<String, List<String>> _focusToCategories = {
    'Peito': ['Força de Empurrar'],
    'Costas': ['Força de Puxada'],
    'Pernas': ['Pernas'],
    'Core': ['Isometria'],
    'Ombros': ['Força de Empurrar'],
    'Braços': ['Força de Empurrar', 'Força de Puxada'],
    'Cardio': ['Cardio'],
  };

  String _intensity = 'Moderado';
  double _durationMinutes = 30;
  final Set<String> _focusAreas = <String>{};
  final Set<String> _selectedExerciseIds = <String>{};

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

  List<CalisthenicsSkill> get _filteredSkills {
    final all = AppState.instance.availableSkills;
    if (_focusAreas.isEmpty) return all;
    final categories = <String>{};
    for (final area in _focusAreas) {
      categories.addAll(_focusToCategories[area] ?? const <String>[]);
    }
    return all.where((s) => categories.contains(s.category)).toList();
  }

  void _toggleFocus(String area) {
    setState(() {
      if (_focusAreas.contains(area)) {
        _focusAreas.remove(area);
      } else {
        _focusAreas.add(area);
      }
    });
  }

  void _toggleExercise(String id) {
    setState(() {
      if (_selectedExerciseIds.contains(id)) {
        _selectedExerciseIds.remove(id);
      } else {
        _selectedExerciseIds.add(id);
      }
    });
  }

  void _generate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Treino personalizado gerado!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: AppBar(
        backgroundColor: BeColors.canvas,
        elevation: 0,
        centerTitle: false,
        titleSpacing: BeSpacing.xs,
        title: const Text('PERSONALIZAR TREINO', style: BeFonts.titleMd),
        foregroundColor: BeColors.ink,
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: BeColors.primary),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        BeSpacing.xs,
                        BeSpacing.xs,
                        BeSpacing.xs,
                        BeSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BeSectionLabel('INTENSIDADE'),
                          const SizedBox(height: BeSpacing.xxs),
                          _IntensitySelector(
                            options: _intensityOptions,
                            selected: _intensity,
                            onSelect: (v) =>
                                setState(() => _intensity = v),
                          ),
                          const SizedBox(height: BeSpacing.sm),
                          const BeHairline(),
                          const SizedBox(height: BeSpacing.sm),
                          const BeSectionLabel('DURAÇÃO'),
                          const SizedBox(height: BeSpacing.xs),
                          _DurationSlider(
                            minutes: _durationMinutes,
                            onChanged: (v) =>
                                setState(() => _durationMinutes = v),
                          ),
                          const SizedBox(height: BeSpacing.sm),
                          const BeHairline(),
                          const SizedBox(height: BeSpacing.sm),
                          const BeSectionLabel('FOCO MUSCULAR'),
                          const SizedBox(height: BeSpacing.xxs),
                          _FocusChips(
                            options: _focusOptions,
                            selected: _focusAreas,
                            onToggle: _toggleFocus,
                          ),
                          const SizedBox(height: BeSpacing.sm),
                          const BeHairline(),
                          const SizedBox(height: BeSpacing.sm),
                          const BeSectionLabel('EXERCÍCIOS SELECIONADOS'),
                          const SizedBox(height: BeSpacing.xs),
                          _ExerciseFilterList(
                            skills: _filteredSkills,
                            selectedIds: _selectedExerciseIds,
                            onToggle: _toggleExercise,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BeSpacing.xs,
                      BeSpacing.xxs,
                      BeSpacing.xs,
                      BeSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: BeOutlineButton(
                            label: 'Cancelar',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: BeSpacing.xs),
                        Expanded(
                          child: BePrimaryButton(
                            label: 'Gerar Treino',
                            onPressed: _generate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _IntensitySelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _IntensitySelector({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: BeSpacing.xxs,
      runSpacing: BeSpacing.xxs,
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onSelect(option),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BeSpacing.xs,
              vertical: BeSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? BeColors.primary.withValues(alpha: 0.12)
                  : BeColors.canvas,
              border: Border.all(
                color: isSelected ? BeColors.primary : BeColors.hairline,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(BeRadii.none),
            ),
            child: Text(
              option,
              style: BeFonts.titleSm.copyWith(
                color: isSelected ? BeColors.primary : BeColors.ink,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  final double minutes;
  final ValueChanged<double> onChanged;

  const _DurationSlider({
    required this.minutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${minutes.round()} min', style: BeFonts.titleMd),
        const SizedBox(height: BeSpacing.xxs),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: BeColors.primary,
            inactiveTrackColor: BeColors.hairline,
            thumbColor: BeColors.primary,
            overlayColor: BeColors.primary.withValues(alpha: 0.12),
            trackHeight: 2,
          ),
          child: Slider(
            min: 10,
            max: 90,
            divisions: 80,
            value: minutes,
            activeColor: BeColors.primary,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _FocusChips extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _FocusChips({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: BeSpacing.xxs,
      runSpacing: BeSpacing.xxs,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onToggle(option),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: BeSpacing.xs,
              vertical: BeSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: BeColors.canvas,
              border: Border.all(
                color: isSelected ? BeColors.primary : BeColors.hairline,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(BeRadii.full),
            ),
            child: Text(
              option,
              style: BeFonts.bodyMd.copyWith(
                color: isSelected ? BeColors.primary : BeColors.body,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ExerciseFilterList extends StatelessWidget {
  final List<CalisthenicsSkill> skills;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _ExerciseFilterList({
    required this.skills,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: BeSpacing.xs,
          vertical: BeSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: BeColors.canvasElevated,
          border: Border.all(color: BeColors.hairline, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 40,
              color: BeColors.muted,
            ),
            const SizedBox(height: BeSpacing.xs),
            Text(
              'Nenhum exercício corresponde ao foco selecionado',
              style: BeFonts.bodyMd.copyWith(color: BeColors.body),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border.all(color: BeColors.hairline, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < skills.length; i++) ...[
            if (i > 0) const BeHairline(),
            _ExerciseTile(
              skill: skills[i],
              selected: selectedIds.contains(skills[i].id),
              onToggle: () => onToggle(skills[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final CalisthenicsSkill skill;
  final bool selected;
  final VoidCallback onToggle;

  const _ExerciseTile({
    required this.skill,
    required this.selected,
    required this.onToggle,
  });

  IconData _resolveIcon(String iconName) {
    return _iconMap[iconName] ?? Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BeSpacing.xs,
          vertical: BeSpacing.xs,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: selected,
                onChanged: (_) => onToggle(),
                activeColor: BeColors.primary,
                checkColor: BeColors.onPrimary,
                side: const BorderSide(color: BeColors.hairline, width: 1),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            const SizedBox(width: BeSpacing.xs),
            Icon(
              _resolveIcon(skill.iconName),
              size: 24,
              color: BeColors.body,
            ),
            const SizedBox(width: BeSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name,
                    style: BeFonts.titleSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: BeSpacing.xxxs),
                  Text(
                    skill.difficulty,
                    style: BeFonts.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Map<String, IconData> _iconMap = <String, IconData>{
  'fitness_center': Icons.fitness_center,
  'accessibility_new': Icons.accessibility_new,
  'flag': Icons.flag,
  'sports_gymnastics': Icons.sports_gymnastics,
  'arrow_upward': Icons.arrow_upward,
  'horizontal_rule': Icons.horizontal_rule,
};