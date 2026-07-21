import 'package:flutter/material.dart';
// Corrigido: Subindo uma pasta para encontrar o app_state.dart
import 'app_state.dart';
import 'home_screen.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({Key? key}) : super(key: key);

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  // Lista temporária para gerenciar as seleções do usuário na tela
  final List<dynamic> _localSelectedIds = [];

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carrega seleções prévias caso existam
    try {
      _localSelectedIds.addAll(AppState.instance.selectedSkillIds);
    } catch (_) {}
  }

  void _toggleSkill(dynamic skillId) {
    setState(() {
      if (_localSelectedIds.contains(skillId)) {
        _localSelectedIds.remove(skillId);
      } else {
        _localSelectedIds.add(skillId);
      }
    });
  }

  void _finishGoalSetting() {
    // Salva as métricas corporais via AppState (os valores são parseados com segurança)
    try {
      (AppState.instance as dynamic).age = int.tryParse(_ageController.text) ?? 24;
      (AppState.instance as dynamic).weight = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 75.0;
      (AppState.instance as dynamic).height = double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 1.75;
    } catch (e) {
      debugPrint("Erro ao salvar métricas corporais: $e");
    }

    // Atualiza o estado global com as novas metas escolhidas
    try {
      AppState.instance.selectedSkillIds.clear();
      for (var id in _localSelectedIds) {
        AppState.instance.selectedSkillIds.add(id);
      }
    } catch (e) {
      debugPrint("Erro ao salvar metas no AppState: $e");
    }

    // Prossegue para a HomeScreen após definir as metas
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Busca a lista de habilidades disponíveis no AppState
    List<dynamic> skills = [];
    try {
      skills = AppState.instance.availableSkills;
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "DEFINIÇÃO DE METAS",
          style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "DEFINA SUAS",
                style: TextStyle(
                  color: Color(0xFF9C27B0),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const Text(
                "PRIMEIRAS METAS",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Oswald',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Selecione as habilidades que você deseja focar na sua trilha de evolução.",
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),

              const Text(
                "SEUS PARÂMETROS",
                style: TextStyle(
                  color: Color(0xFF9C27B0),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInputField("Idade", _ageController, TextInputType.number, "anos")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInputField("Peso", _weightController, const TextInputType.numberWithOptions(decimal: true), "kg")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInputField("Altura", _heightController, const TextInputType.numberWithOptions(decimal: true), "m")),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                "METAS DE TREINO",
                style: TextStyle(
                  color: Color(0xFF9C27B0),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              skills.isEmpty 
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text("Nenhuma habilidade cadastrada no sistema.", style: TextStyle(color: Colors.white54)),
                    )
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: skills.length,
                    itemBuilder: (context, index) {
                      final skill = skills[index];
                      final bool isSelected = _localSelectedIds.contains(skill.id);

                        return GestureDetector(
                          onTap: () => _toggleSkill(skill.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF9C27B0).withOpacity(0.15) : const Color(0xFF1A1A24),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF9C27B0) : const Color(0xFF333333),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: const Color(0xFF9C27B0).withOpacity(0.2), blurRadius: 12, spreadRadius: 1)]
                                  : [],
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.fitness_center_rounded,
                                        size: 40,
                                        color: isSelected ? const Color(0xFF9C27B0) : Colors.white54,
                                      ),
                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          skill.name.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.grey,
                                            fontFamily: 'Oswald',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Icon(Icons.check_circle, color: Color(0xFF9C27B0), size: 20),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _localSelectedIds.isEmpty ? null : _finishGoalSetting,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    disabledBackgroundColor: const Color(0xFF333333),
                  ),
                  child: Text(
                    _localSelectedIds.isEmpty ? "SELECIONE AO MENOS UMA" : "INICIAR JORNADA",
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      letterSpacing: 1.0,
                      color: _localSelectedIds.isEmpty ? Colors.grey : Colors.white
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, TextInputType type, String suffix) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontFamily: 'Oswald'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: Color(0xFF9C27B0), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF1A1A24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9C27B0)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}