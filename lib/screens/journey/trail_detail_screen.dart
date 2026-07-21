import 'package:flutter/material.dart';
// IMPORT CORRIGIDO: Subindo 2 pastas para acessar o app_state.dart na raiz do lib
import '../../app_state.dart';

class TrailDetailScreen extends StatefulWidget {
  final CalisthenicsSkill skill;

  const TrailDetailScreen({Key? key, required this.skill}) : super(key: key);

  @override
  State<TrailDetailScreen> createState() => _TrailDetailScreenState();
}

class _TrailDetailScreenState extends State<TrailDetailScreen> {
  bool _isAdapted = false; 
  late int completedStages;

  @override
  void initState() {
    super.initState();
    // Puxa do AppState quantas etapas o usuário já concluiu dessa skill
    completedStages = AppState.instance.completedStages[widget.skill.id] ?? 0;
  }

  void _completeStage() {
    setState(() {
      completedStages++;
      AppState.instance.completedStages[widget.skill.id] = completedStages;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Etapa concluída! Próximo nível desbloqueado."), backgroundColor: Colors.green),
    );
  }

  void _showReevaluationDialog() {
    TextEditingController recordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text("Avaliação de Progresso", style: TextStyle(color: Colors.white, fontFamily: 'Oswald', fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Você evoluiu no ${widget.skill.name}! Qual é sua nova marca agora?", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: recordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Digite seu novo recorde",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0D0D12),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF9C27B0)), borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (recordController.text.isNotEmpty) {
                setState(() {
                  AppState.instance.userRecords[widget.skill.id] = recordController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Novo Recorde Salvo! 💪"), backgroundColor: Color(0xFF9C27B0)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0)),
            child: const Text("Salvar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateStages() {
    String category = widget.skill.category.toLowerCase();
    
    if (_isAdapted) {
      return [
        {"title": "Adaptação: Isometria", "desc": "Mantenha a posição inicial por 30s. 3 séries.", "locked": completedStages < 0, "completed": completedStages >= 1},
        {"title": "Adaptação: Movimento Negativo", "desc": "Faça apenas a descida controlada. 5 reps.", "locked": completedStages < 1, "completed": completedStages >= 2},
        {"title": "Desafio Adaptado", "desc": "Tente executar 1 repetição com forma perfeita.", "locked": completedStages < 2, "completed": completedStages >= 3},
      ];
    }

    if (category.contains("puxada")) {
      return [
        {"title": "Fortalecimento de Pegada", "desc": "Dead hang (pendurado na barra) por 45s.", "locked": completedStages < 0, "completed": completedStages >= 1},
        {"title": "Puxada Escapular", "desc": "Ativação de escápula na barra. 3x 10 reps.", "locked": completedStages < 1, "completed": completedStages >= 2},
        {"title": "Desafio Final: ${widget.skill.name}", "desc": "Execute o movimento completo. Meta: 5 reps.", "locked": completedStages < 2, "completed": completedStages >= 3},
      ];
    } else {
      return [
        {"title": "Adaptação Básica", "desc": "Foco na amplitude de movimento.", "locked": completedStages < 0, "completed": completedStages >= 1},
        {"title": "Aumento de Volume", "desc": "Maior número de repetições/tempo.", "locked": completedStages < 1, "completed": completedStages >= 2},
        {"title": "Desafio Final: ${widget.skill.name}", "desc": "Execução perfeita do movimento.", "locked": completedStages < 2, "completed": completedStages >= 3},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = _generateStages();
    String? currentRecord = AppState.instance.userRecords[widget.skill.id];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.skill.name.toUpperCase(), style: const TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentRecord != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber)),
                        child: Text("🏆 Seu Recorde Atual: $currentRecord", textAlign: TextAlign.center, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                      ),
                      
                    _buildAIAssistantCard(),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("ETAPAS DE PROGRESSÃO", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        if (!_isAdapted)
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _isAdapted = true);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("O Coach IA recalculou sua rota."), backgroundColor: Colors.amber));
                            },
                            icon: const Icon(Icons.refresh, size: 14, color: Colors.amber),
                            label: const Text("FALHEI, ADAPTAR", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...stages.asMap().entries.map((entry) {
                      int idx = entry.key + 1;
                      var stage = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildStageCard(
                          stageNumber: idx,
                          title: stage["title"],
                          description: stage["desc"],
                          isLocked: stage["locked"],
                          isCompleted: stage["completed"],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            // Botão fixo na base para atualizar o recorde
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _showReevaluationDialog,
                icon: const Icon(Icons.emoji_events, color: Colors.white),
                label: const Text("ATUALIZAR MEU RECORDE", style: TextStyle(color: Colors.white, fontFamily: 'Oswald', fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: const Color(0xFF9C27B0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isAdapted ? Colors.amber : const Color(0xFF333333)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: _isAdapted ? Colors.amber : const Color(0xFF9C27B0), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAdapted ? "ROTA RECALCULADA PELA IA" : "ESTRATÉGIA GERADA PELA IA",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Oswald'),
                ),
                const SizedBox(height: 6),
                Text(
                  _isAdapted 
                    ? "Reduzi a intensidade da trilha focando em exercícios de base isométrica. Respeite o processo!"
                    : "Analisei o nível de dificuldade (${widget.skill.difficulty}). Dividi o treinamento em etapas para evitar lesões.",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard({required int stageNumber, required String title, required String description, required bool isLocked, required bool isCompleted}) {
    final Color bgColor = isLocked ? const Color(0xFF13131A) : const Color(0xFF1A1A24);
    final Color borderColor = isCompleted ? Colors.green : (isLocked ? const Color(0xFF22222D) : const Color(0xFF9C27B0).withOpacity(0.5));

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isLocked ? 1 : 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.withOpacity(0.2) : (isLocked ? Colors.transparent : const Color(0xFF9C27B0).withOpacity(0.2)),
                shape: BoxShape.circle,
                border: Border.all(color: isLocked ? Colors.grey.shade700 : Colors.transparent),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.green, size: 20)
                    : (isLocked ? Icon(Icons.lock, color: Colors.grey.shade600, size: 18) : Text("$stageNumber", style: const TextStyle(color: Color(0xFFE040FB), fontWeight: FontWeight.bold, fontSize: 16))),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isLocked ? Colors.grey.shade600 : Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (!isLocked && !isCompleted) 
              IconButton(
                icon: const Icon(Icons.play_circle_fill, color: Color(0xFF9C27B0), size: 32),
                onPressed: _completeStage,
              ),
          ],
        ),
      ),
    );
  }
}