import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';

class TrailDetailScreen extends StatefulWidget {
  final CalisthenicsSkill skill;

  const TrailDetailScreen({super.key, required this.skill});

  @override
  State<TrailDetailScreen> createState() => _TrailDetailScreenState();
}

class _TrailDetailScreenState extends State<TrailDetailScreen> {
  bool _isAdapted = false;
  late int completedStages;

  @override
  void initState() {
    super.initState();
    completedStages = AppState.instance.completedStages[widget.skill.id] ?? 0;
  }

  void _completeStage() async {
    setState(() {
      completedStages++;
      AppState.instance.completedStages[widget.skill.id] = completedStages;
    });
    await AppState.instance.saveProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Etapa concluída! Próximo nível desbloqueado.")),
    );
  }

  void _showReevaluationDialog() {
    TextEditingController recordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BeColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text("Avaliação de Progresso",
            style: BeFonts.titleMd.copyWith(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Você evoluiu no ${widget.skill.name}! Qual é sua nova marca agora?",
              style: BeFonts.bodyMd.copyWith(color: BeColors.body),
            ),
            const SizedBox(height: BeSpacing.xxs),
            TextField(
              controller: recordController,
              style: beBodyMdInk,
              decoration: beInputDecoration(hint: "Digite seu novo recorde"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar",
                style: BeFonts.button.copyWith(color: BeColors.muted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (recordController.text.isNotEmpty) {
                setState(() {
                  AppState.instance.userRecords[widget.skill.id] =
                      recordController.text;
                });
                await AppState.instance.saveProfile();
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Novo Recorde Salvo!")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: BeColors.primary, elevation: 0),
            child: Text("Salvar", style: BeFonts.button),
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
        {"title": "Fortalecimento de Pegada", "desc": "Dead hang por 45s.", "locked": completedStages < 0, "completed": completedStages >= 1},
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
      backgroundColor: BeColors.canvas,
      appBar: AppBar(
        title: Text(widget.skill.name.toUpperCase()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentRecord != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: BeSpacing.xxs, bottom: BeSpacing.xs),
                        padding: const EdgeInsets.all(BeSpacing.xxs),
                        decoration: BoxDecoration(
                          color: BeColors.canvasElevated,
                          border: Border.all(color: BeColors.primary, width: 1),
                        ),
                        child: Text("Seu Recorde Atual: $currentRecord",
                            textAlign: TextAlign.center,
                            style: BeFonts.titleMd.copyWith(
                                color: BeColors.primary, fontSize: 14)),
                      ),

                    _buildAIAssistantCard(),
                    const SizedBox(height: BeSpacing.sm),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const BeSectionLabel("Etapas de Progressão"),
                        if (!_isAdapted)
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _isAdapted = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("O Coach IA recalculou sua rota.")),
                              );
                            },
                            icon: const Icon(Icons.refresh,
                                size: 14, color: BeColors.primary),
                            label: Text("FALHEI, ADAPTAR",
                                style: BeFonts.captionUppercase.copyWith(
                                    color: BeColors.primary,
                                    fontSize: 10,
                                    letterSpacing: 1.1)),
                          ),
                      ],
                    ),
                    const SizedBox(height: BeSpacing.xxs),

                    ...stages.asMap().entries.map((entry) {
                      int idx = entry.key + 1;
                      var stage = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: BeSpacing.xxs),
                        child: _buildStageCard(
                          stageNumber: idx,
                          title: stage["title"],
                          description: stage["desc"],
                          isLocked: stage["locked"],
                          isCompleted: stage["completed"],
                        ),
                      );
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
                  label: "Atualizar Meu Recorde",
                  icon: Icons.emoji_events,
                  onPressed: _showReevaluationDialog,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAssistantCard() {
    return BeCard(
      padding: const EdgeInsets.all(BeSpacing.xs),
      borderColor: _isAdapted ? BeColors.primary : BeColors.hairline,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome,
              color: _isAdapted ? BeColors.primary : BeColors.primary, size: 22),
          const SizedBox(width: BeSpacing.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAdapted
                      ? "ROTA RECALCULADA PELA IA"
                      : "ESTRATÉGIA GERADA PELA IA",
                  style: BeFonts.captionUppercase.copyWith(
                      color: BeColors.ink, letterSpacing: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  _isAdapted
                      ? "Reduzi a intensidade da trilha focando em exercícios de base isométrica. Respeite o processo!"
                      : "Analisei o nível de dificuldade (${widget.skill.difficulty}). Dividi o treinamento em etapas para evitar lesões.",
                  style: BeFonts.bodySm.copyWith(color: BeColors.body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard({
    required int stageNumber,
    required String title,
    required String description,
    required bool isLocked,
    required bool isCompleted,
  }) {
    final Color borderColor =
        isCompleted ? BeColors.semanticSuccess : (isLocked ? BeColors.hairline : BeColors.primary);

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(BeSpacing.xs),
        decoration: BoxDecoration(
          color: BeColors.canvasElevated,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isLocked ? BeColors.hairline : borderColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check,
                        color: BeColors.semanticSuccess, size: 18)
                    : (isLocked
                        ? Icon(Icons.lock,
                            color: BeColors.muted, size: 16)
                        : Text("$stageNumber",
                            style: BeFonts.titleMd.copyWith(
                                color: BeColors.primary, fontSize: 16))),
              ),
            ),
            const SizedBox(width: BeSpacing.xxs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: BeFonts.titleSm.copyWith(
                          color: isLocked ? BeColors.muted : BeColors.ink)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: BeFonts.caption.copyWith(color: BeColors.muted)),
                ],
              ),
            ),
            if (!isLocked && !isCompleted)
              IconButton(
                icon: const Icon(Icons.play_circle_fill,
                    color: BeColors.primary, size: 30),
                onPressed: _completeStage,
              ),
          ],
        ),
      ),
    );
  }
}