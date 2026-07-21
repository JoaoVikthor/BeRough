import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_state.dart';
import 'home_screen.dart';

class SkillSelectionScreen extends StatefulWidget {
  final bool isEditMode; // Permite usar a mesma tela para gerenciar as trilhas no painel

  const SkillSelectionScreen({Key? key, this.isEditMode = false}) : super(key: key);

  @override
  State<SkillSelectionScreen> createState() => _SkillSelectionScreenState();
}

class _SkillSelectionScreenState extends State<SkillSelectionScreen> {
  final List<String> _tempSelectedIds = [];
  
  // Controllers do Formulário de Métricas Reais do Atleta
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Se estiver editando, pré-carrega as seleções salvas no AppState
    _tempSelectedIds.addAll(AppState.instance.selectedSkillIds);
    _nicknameController.text = AppState.instance.nickname;
    _weightController.text = AppState.instance.weight.toString();
    _heightController.text = AppState.instance.height.toString();
    _ageController.text = AppState.instance.age.toString();
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

  /* STREAMING_CHUNK: Gravando métricas e apelido de forma estruturada... */
  void _confirmSelection() async {
    final String nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Defina seu apelido para o perfil de atleta!"), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    if (_tempSelectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione pelo menos 1 trilha para treinar!"), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    // Salva as métricas no gerenciador de estado
    AppState.instance.nickname = nickname;
    AppState.instance.weight = double.tryParse(_weightController.text) ?? 75.0;
    AppState.instance.height = double.tryParse(_heightController.text) ?? 1.75;
    AppState.instance.age = int.tryParse(_ageController.text) ?? 25;

    // Atualiza a lista múltipla de Skills escolhidas
    AppState.instance.selectedSkillIds.clear();
    AppState.instance.selectedSkillIds.addAll(_tempSelectedIds);

    // Sincroniza o apelido no metadado oficial do Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(nickname);
      await user.reload();
    }

    if (mounted) {
      if (widget.isEditMode) {
        // Retorna para a tela anterior se estiver editando trilhas
        Navigator.pop(context, true);
      } else {
        // Envia para a Home se for a configuração inicial
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
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
      case 'Iniciante': return Colors.greenAccent;
      case 'Intermediário': return Colors.blueAccent;
      case 'Avançado': return Colors.orangeAccent;
      case 'Elite': return Colors.redAccent;
      default: return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skills = AppState.instance.availableSkills;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: widget.isEditMode 
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text("GERENCIAR TRILHAS", style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.bold)),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isEditMode) ...[
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Oswald'),
                          children: [
                            TextSpan(text: 'CONFIGURAR ', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'PERFIL', style: TextStyle(color: Color(0xFF9C27B0))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Forneça suas métricas corporais e defina os focos da sua jornada.",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                    ],

                    /* STREAMING_CHUNK: Formulário interativo para entrada de métricas do Atleta... */
                    _buildFormSection(),
                    const SizedBox(height: 32),

                    const Text(
                      "SUAS METAS ATIVAS (Múltipla Escolha)",
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Oswald', letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Selecione todas as modalidades que deseja focar ou treinar.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    /* STREAMING_CHUNK: Listando trilhas do Iniciante ao Elite... */
                    ...skills.map((skill) {
                      final isSelected = _tempSelectedIds.contains(skill.id);
                      return GestureDetector(
                        onTap: () => _toggleSkill(skill.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A24),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF9C27B0) : const Color(0xFF333333),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF9C27B0).withOpacity(0.2) : const Color(0xFF0D0D12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getSkillIcon(skill.iconName),
                                  color: isSelected ? const Color(0xFF9C27B0) : Colors.grey,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          skill.name,
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Oswald'),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getDifficultyColor(skill.difficulty).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            skill.difficulty.toUpperCase(),
                                            style: TextStyle(color: _getDifficultyColor(skill.difficulty), fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(skill.category, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF9C27B0) : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? const Color(0xFF9C27B0) : const Color(0xFF333333), width: 2),
                                ),
                                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmSelection,
                  child: Text(
                    widget.isEditMode ? "SALVAR ALTERAÇÕES" : "CONSTRUIR MEU CRONOGRAMA (${_tempSelectedIds.length})",
                    style: const TextStyle(letterSpacing: 1.0),
                  ),
                ),
              ),
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
        const Text(
          "DADOS DO ATLETA",
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Oswald', letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        _buildInputField("Seu Apelido no App", "Ex: Vikthor", _nicknameController, TextInputType.text),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildInputField("Peso (kg)", "Ex: 75.0", _weightController, const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField("Altura (m)", "Ex: 1.75", _heightController, const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField("Idade (anos)", "Ex: 25", _ageController, TextInputType.number)),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A24),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 1.5)),
          ),
        ),
      ],
    );
  }
}