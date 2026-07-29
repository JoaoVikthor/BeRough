import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_state.dart';
import '../design/tokens.dart';
import '../design/ui.dart';
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
        child: Row(
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
                      style: BeFonts.caption.copyWith(color: BeColors.muted)),
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
      ),
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