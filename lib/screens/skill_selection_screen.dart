import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_state.dart';
import '../design/tokens.dart';
import '../design/ui.dart';
import '../models/trail_generator.dart';
import 'home_screen.dart';

class SkillSelectionScreen extends StatefulWidget {
  final bool isEditMode;

  const SkillSelectionScreen({super.key, this.isEditMode = false});

  @override
  State<SkillSelectionScreen> createState() => _SkillSelectionScreenState();
}

class _SkillSelectionScreenState extends State<SkillSelectionScreen> {
  final List<String> _tempSelectedIds = [];

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Campos de meta por skill (chave: skillId).
  final Map<String, ExerciseGoal> _tempGoals = {};
  // Controladores por skill (gerados sob demanda).
  final Map<String, List<TextEditingController>> _goalControllers = {};

  @override
  void initState() {
    super.initState();
    _loadPersistentData();
  }

  Future<void> _loadPersistentData() async {
    await AppState.instance.loadFromDisk();
    if (!mounted) return;
    setState(() {
      _tempSelectedIds.addAll(AppState.instance.selectedSkillIds);
      _nicknameController.text = AppState.instance.nickname;
      _weightController.text = AppState.instance.weight.toString();
      _heightController.text = AppState.instance.height.toString();
      _ageController.text = AppState.instance.age.toString();
      // Carrega metas já salvas.
      AppState.instance.goals.forEach((k, v) => _tempGoals[k] = v);
    });
  }

  void _toggleSkill(String id) {
    setState(() {
      if (_tempSelectedIds.contains(id)) {
        _tempSelectedIds.remove(id);
      } else {
        _tempSelectedIds.add(id);
      }
    });
  }

  void _ensureGoalControllers(CalisthenicsSkill skill) {
    if (_goalControllers.containsKey(skill.id)) return;
    final isRun = skill.isRunning;
    final existing = _tempGoals[skill.id];
    if (isRun) {
      _goalControllers[skill.id] = [
        TextEditingController(
            text: existing != null
                ? (existing.targetDistanceMeters / 1000).toStringAsFixed(2)
                : '1.00'), // km
        TextEditingController(
            text: existing != null
                ? (existing.targetSeconds / 60).toStringAsFixed(0)
                : '10'), // min
        TextEditingController(
            text: existing != null
                ? (existing.targetSeconds % 60).toStringAsFixed(0).padLeft(2, '0')
                : '00'), // seg
      ];
    } else {
      // Categoria de calistenia: detecta tipo.
      final kind = _calistheniaKind(skill, existing);
      _goalControllers[skill.id] = [
        TextEditingController(
            text: existing != null
                ? existing.targetReps.toString()
                : kind == CalistheniaKind.hold
                    ? '30'
                    : '10'), // reps ou hold-seg
        TextEditingController(
            text: existing != null
                ? existing.targetSets.toString()
                : kind == CalistheniaKind.sets
                    ? '3'
                    : '1'),
      ];
    }
  }

  CalistheniaKind _calistheniaKind(
      CalisthenicsSkill skill, ExerciseGoal? existing) {
    if (existing != null) {
      if (existing.metricKind == TrailMetricKind.hold) return CalistheniaKind.hold;
      if (existing.metricKind == TrailMetricKind.sets) return CalistheniaKind.sets;
    }
    // Categoria inferida da category do skill.
    final cat = skill.category.toLowerCase();
    if (cat.contains('isometr') || cat.contains('equilíbrio') ||
        cat.contains('equilibrio')) {
      return CalistheniaKind.hold;
    }
    if (cat.contains('força') || cat.contains('forca') ||
        cat.contains('puxada') || cat.contains('explosiva')) {
      return CalistheniaKind.sets;
    }
    return CalistheniaKind.reps;
  }

  void _commitGoalFor(CalisthenicsSkill skill) {
    _ensureGoalControllers(skill);
    final controllers = _goalControllers[skill.id]!;
    if (skill.isRunning) {
      final km = double.tryParse(controllers[0].text.trim()) ?? 1.0;
      final min = double.tryParse(controllers[1].text.trim()) ?? 10.0;
      final sec = double.tryParse(controllers[2].text.trim()) ?? 0.0;
      _tempGoals[skill.id] = ExerciseGoal(
        skillId: skill.id,
        targetDistanceMeters: km * 1000,
        targetSeconds: min * 60 + sec,
      );
    } else {
      final kind = _calistheniaKind(skill, _tempGoals[skill.id]);
      final v1 = int.tryParse(controllers[0].text.trim()) ?? 10;
      final v2 = int.tryParse(controllers[1].text.trim()) ?? 1;
      if (kind == CalistheniaKind.hold) {
        _tempGoals[skill.id] = ExerciseGoal(
          skillId: skill.id,
          targetSeconds: v1.toDouble(),
        );
      } else if (kind == CalistheniaKind.sets) {
        _tempGoals[skill.id] = ExerciseGoal(
          skillId: skill.id,
          targetReps: v1,
          targetSets: v2,
        );
      } else {
        _tempGoals[skill.id] = ExerciseGoal(
          skillId: skill.id,
          targetReps: v1,
        );
      }
    }
  }

  void _confirmSelection() async {
    final String nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Defina seu apelido para o perfil de atleta!")),
      );
      return;
    }
    if (_tempSelectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione pelo menos 1 trilha para treinar!")),
      );
      return;
    }

    AppState.instance.nickname = nickname;
    AppState.instance.weight = double.tryParse(_weightController.text) ?? 75.0;
    AppState.instance.height = double.tryParse(_heightController.text) ?? 1.75;
    AppState.instance.age = int.tryParse(_ageController.text) ?? 25;

    AppState.instance.selectedSkillIds.clear();
    AppState.instance.selectedSkillIds.addAll(_tempSelectedIds);

    // Confirma metas: percorre as skills selecionadas e grava os goals.
    for (final skill in AppState.instance.availableSkills) {
      if (_tempSelectedIds.contains(skill.id)) {
        _commitGoalFor(skill);
      } else {
        // Remove a meta se desselecionou.
        _tempGoals.remove(skill.id);
      }
    }
    AppState.instance.goals.clear();
    AppState.instance.goals.addAll(_tempGoals);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(nickname);
      await user.reload();
    }

    await AppState.instance.saveProfile();

    if (!mounted) return;
    if (widget.isEditMode) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Iniciante': return BeColors.semanticSuccess;
      case 'Intermediário': return BeColors.semanticInfo;
      case 'Avançado': return BeColors.semanticWarning;
      case 'Elite': return BeColors.primary;
      default: return BeColors.semanticSuccess;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skills = AppState.instance.availableSkills;

    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: widget.isEditMode
          ? AppBar(
              title: Text("Gerenciar Trilhas".toUpperCase()),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isEditMode) ...[
                      const SizedBox(height: BeSpacing.sm),
                      RichText(
                        text: TextSpan(
                          style: BeFonts.displayMd.copyWith(
                              fontSize: 32, letterSpacing: -0.32),
                          children: const [
                            TextSpan(
                                text: 'CONFIGURAR ',
                                style: TextStyle(color: BeColors.ink)),
                            TextSpan(
                                text: 'PERFIL',
                                style: TextStyle(color: BeColors.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: BeSpacing.xxs),
                      Text(
                        "Forneça suas métricas corporais e defina os focos da sua jornada.",
                        style: BeFonts.bodyMd,
                      ),
                      const SizedBox(height: BeSpacing.sm),
                    ],

                    _buildFormSection(),
                    const SizedBox(height: BeSpacing.sm),

                    const BeSectionLabel("Suas Metas Ativas — Múltipla Escolha"),
                    const SizedBox(height: 4),
                    Text(
                      "Selecione todas as modalidades que deseja focar ou treinar.",
                      style: BeFonts.caption.copyWith(color: BeColors.muted),
                    ),
                    const SizedBox(height: BeSpacing.xs),

                    ...skills.map((skill) {
                      final isSelected = _tempSelectedIds.contains(skill.id);
                      return _buildSkillRow(skill, isSelected);
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: BeSpacing.sm, vertical: BeSpacing.xxs),
              child: SizedBox(
                width: double.infinity,
                child: BePrimaryButton(
                  label: widget.isEditMode
                      ? "Salvar Alterações"
                      : "Construir Meu Cronograma (${_tempSelectedIds.length})",
                  onPressed: _confirmSelection,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillRow(CalisthenicsSkill skill, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleSkill(skill.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: BeSpacing.xxs),
        padding: const EdgeInsets.all(BeSpacing.xs),
        decoration: BoxDecoration(
          color: BeColors.canvasElevated,
          border: Border.all(
            color: isSelected ? BeColors.primary : BeColors.hairline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BeColors.primary.withOpacity(0.12)
                        : BeColors.canvas,
                    border: Border.all(
                      color: isSelected ? BeColors.primary : BeColors.hairline,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getSkillIcon(skill.iconName),
                    color: isSelected ? BeColors.primary : BeColors.muted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: BeSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(skill.name,
                              style: BeFonts.titleMd.copyWith(fontSize: 16)),
                          const SizedBox(width: BeSpacing.xxs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(skill.difficulty)
                                  .withOpacity(0.12),
                            ),
                            child: Text(
                              skill.difficulty.toUpperCase(),
                              style: BeFonts.captionUppercase.copyWith(
                                color: _getDifficultyColor(skill.difficulty),
                                fontSize: 8,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(skill.category,
                          style:
                              BeFonts.caption.copyWith(color: BeColors.muted)),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? BeColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? BeColors.primary : BeColors.hairline,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          color: BeColors.onPrimary, size: 14)
                      : null,
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: BeSpacing.xxs),
              _buildGoalEditor(skill),
            ],
          ],
        ),
      ),
    );
  }

  /// Editor de meta de UMA skill. Expande quando selecionada.
  Widget _buildGoalEditor(CalisthenicsSkill skill) {
    _ensureGoalControllers(skill);
    final controllers = _goalControllers[skill.id]!;

    if (skill.isRunning) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BeSectionLabel('Meta de Corrida'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Distância (km)',
                  hint: 'Ex: 1.00',
                  controller: controllers[0],
                  type:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: BeSpacing.xxs),
              Expanded(
                child: _buildField(
                  label: 'Min',
                  hint: '10',
                  controller: controllers[1],
                  type: TextInputType.number,
                ),
              ),
              const SizedBox(width: BeSpacing.xxs),
              Expanded(
                child: _buildField(
                  label: 'Seg',
                  hint: '00',
                  controller: controllers[2],
                  type: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ex.: 1 km em 10 min. Será o alvo final da sua trilha.',
            style: BeFonts.caption.copyWith(color: BeColors.muted),
          ),
        ],
      );
    }

    final kind = _calistheniaKind(skill, _tempGoals[skill.id]);
    if (kind == CalistheniaKind.hold) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BeSectionLabel('Meta de Isometria'),
          const SizedBox(height: 4),
          _buildField(
            label: 'Segurar (segundos)',
            hint: 'Ex: 30',
            controller: controllers[0],
            type: TextInputType.number,
          ),
        ],
      );
    }
    if (kind == CalistheniaKind.sets) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BeSectionLabel('Meta de Repetições'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Reps/série',
                  hint: 'Ex: 10',
                  controller: controllers[0],
                  type: TextInputType.number,
                ),
              ),
              const SizedBox(width: BeSpacing.xxs),
              Expanded(
                child: _buildField(
                  label: 'Séries',
                  hint: 'Ex: 3',
                  controller: controllers[1],
                  type: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BeSectionLabel('Meta de Repetições'),
        const SizedBox(height: 4),
        _buildField(
          label: 'Repetições totais',
          hint: 'Ex: 10',
          controller: controllers[0],
          type: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BeSectionLabel("Dados do Atleta"),
        const SizedBox(height: BeSpacing.xxs),
        _buildField(
          label: "Seu Apelido no App",
          hint: "Ex: Vikthor",
          controller: _nicknameController,
          type: TextInputType.text,
        ),
        const SizedBox(height: BeSpacing.xxs),
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: "Peso (kg)",
                hint: "Ex: 75.0",
                controller: _weightController,
                type: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: BeSpacing.xxs),
            Expanded(
              child: _buildField(
                label: "Altura (m)",
                hint: "Ex: 1.75",
                controller: _heightController,
                type: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: BeSpacing.xxs),
            Expanded(
              child: _buildField(
                label: "Idade (anos)",
                hint: "Ex: 25",
                controller: _ageController,
                type: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required TextInputType type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BeSectionLabel(label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: type,
          style: beBodyMdInk,
          decoration: beInputDecoration(hint: hint),
        ),
      ],
    );
  }
}