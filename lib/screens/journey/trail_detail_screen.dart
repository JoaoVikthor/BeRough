import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';
import '../../models/trail_generator.dart';
import '../running_screen.dart';
import '../skill_selection_screen.dart';
import '../trail/step_screen.dart';

/// Trilha de progressão — mapa de nodes conectados estilo Duolingo.
///
/// Cada `TrailStep` é um node arredondado ligado por conectores curvos;
/// node bloqueado (lock), atual (Rosso Corsa pulsante), concluído (check).
/// Tocar o node atual abre a `StepScreen`.
///
/// Se a skill for corrida e ainda não houver baseline, exige uma corrida
/// de avaliação (ou usar histórico) antes de gerar a trilha.
class TrailDetailScreen extends StatefulWidget {
  final CalisthenicsSkill skill;

  const TrailDetailScreen({super.key, required this.skill});

  @override
  State<TrailDetailScreen> createState() => _TrailDetailScreenState();
}

class _TrailDetailScreenState extends State<TrailDetailScreen> {
  late int completedStages;
  TrailPlan? _plan;
  bool _needsBaseline = false;

  @override
  void initState() {
    super.initState();
    completedStages = AppState.instance.completedStages[widget.skill.id] ?? 0;
    _refreshPlan();
  }

  void _refreshPlan() {
    setState(() {
      final goal = AppState.instance.goalFor(widget.skill.id);
      if (goal == null) {
        _needsBaseline = false;
        _plan = null;
        return;
      }
      if (!TrailGenerator.hasBaseline(widget.skill)) {
        _needsBaseline = true;
        _plan = null;
        return;
      }
      _needsBaseline = false;
      _plan = TrailGenerator.generatePlan(widget.skill);
    });
  }

  void _startStep(TrailStep step, bool isFinal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StepScreen(skill: widget.skill, step: step, isFinalStep: isFinal),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _refreshPlan();
        });
      }
    });
  }

  void _openBaselineDialog() {
    if (widget.skill.isRunning) {
      _openRunBaselineDialog();
    } else {
      _openCalisthenicsBaselineDialog();
    }
  }

  /// Diálogo de baseline de CORRIDA — usa o histórico ou uma corrida de
  /// avaliação ao vivo.
  void _openRunBaselineDialog() {
    final app = AppState.instance;
    final hasHistory = app.lastRun != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BeColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title:
            Text("Calibrar Treino", style: BeFonts.titleMd.copyWith(fontSize: 18)),
        content: Text(
          hasHistory
              ? "Para dimensionar sua trilha de corrida, usamos uma corrida prévia como base. Usar seu último registro ou rodar uma avaliação agora?"
              : "Para dimensionar sua trilha de corrida, rode uma avaliação curta agora (corrida de 3-5 min). Ela servirá de base para os passos.",
          style: BeFonts.bodyMd.copyWith(color: BeColors.body),
        ),
        actions: [
          if (hasHistory)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _useHistoryBaseline();
              },
              child: Text("USAR HISTÓRICO",
                  style: BeFonts.button.copyWith(color: BeColors.primary)),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _runAssessment();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: BeColors.primary, elevation: 0),
            child: Text("AVALIAR AGORA", style: BeFonts.button),
          ),
        ],
      ),
    );
  }

  /// Diálogo de baseline de CALISTENIA — pergunta quantos DAQUELE exercício
  /// o atleta consegue fazer hoje (reps, ou segundos em holds).
  void _openCalisthenicsBaselineDialog() {
    final skill = widget.skill;
    final goal = AppState.instance.goalFor(skill.id);
    final kind = TrailGenerator.metricKindFor(skill, goal);
    final isHold = kind == TrailMetricKind.hold;
    final unit = isHold ? 'segundos' : 'repetições';
    final verb = isHold ? 'segurar' : 'fazer';

    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BeColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text("Avaliação do Exercício",
            style: BeFonts.titleMd.copyWith(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHold
                  ? 'Por quantos $unit você consegue $verb ${skill.name} hoje, com boa forma?'
                  : 'Quantas $unit de ${skill.name} você consegue $verb hoje, seguidas, com boa forma?',
              style: BeFonts.bodyMd.copyWith(color: BeColors.body),
            ),
            const SizedBox(height: BeSpacing.xxs),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: beBodyMdInk,
              decoration: beInputDecoration(
                  hint: isHold ? 'Ex: 30' : 'Ex: 8'),
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
              final v = int.tryParse(controller.text.trim()) ?? 0;
              if (v <= 0) return;
              Navigator.pop(context);
              AppState.instance.setCalisthenicsBaseline(skill.id, v);
              await AppState.instance.saveProfile();
              if (!mounted) return;
              setState(() => _refreshPlan());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Baseline de ${skill.name}: $v $unit")),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: BeColors.primary, elevation: 0),
            child: Text("SALVAR BASE", style: BeFonts.button),
          ),
        ],
      ),
    );
  }

  void _useHistoryBaseline() {
    AppState.instance.setRunBaselineFromHistory();
    AppState.instance.saveProfile();
    setState(() => _refreshPlan());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Baseline: ${AppState.instance.runBaseline!.describe()}")),
    );
  }

  void _runAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RunningScreen(isAssessment: true),
      ),
    ).then((_) {
      if (mounted) setState(() => _refreshPlan());
    });
  }

  void _showReevaluationDialog() {
    final skill = widget.skill;
    final goal = AppState.instance.goalFor(skill.id);
    final isHold = !skill.isRunning &&
        TrailGenerator.metricKindFor(skill, goal) == TrailMetricKind.hold;
    final unit = isHold ? 'segundos' : 'repetições';

    showDialog(
      context: context,
      builder: (context) {
        TextEditingController recordController = TextEditingController();
        return AlertDialog(
          backgroundColor: BeColors.canvasElevated,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(skill.isRunning
              ? "Atualizar Recorde"
              : "Atualizar Avaliação do Exercício",
              style: BeFonts.titleMd.copyWith(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skill.isRunning
                    ? "Você evoluiu no ${skill.name}! Qual é sua nova marca?"
                    : "Quant${isHold ? 'os segundos' : 'as repetições'} de ${skill.name} você consegue fazer AGORA?",
                style: BeFonts.bodyMd.copyWith(color: BeColors.body),
              ),
              const SizedBox(height: BeSpacing.xxs),
              TextField(
                controller: recordController,
                keyboardType: skill.isRunning
                    ? TextInputType.text
                    : TextInputType.number,
                style: beBodyMdInk,
                decoration: beInputDecoration(
                    hint: skill.isRunning
                        ? "Ex: 5 km em 30 min"
                        : (isHold ? "Ex: 45" : "Ex: 12")),
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
                if (recordController.text.trim().isEmpty) return;
                if (!skill.isRunning) {
                  final v = int.tryParse(recordController.text.trim()) ?? 0;
                  if (v <= 0) return;
                  AppState.instance.setCalisthenicsBaseline(skill.id, v);
                } else {
                  setState(() {
                    AppState.instance.userRecords[skill.id] =
                        recordController.text;
                  });
                }
                await AppState.instance.saveProfile();
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() => _refreshPlan());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(skill.isRunning
                      ? "Novo Recorde Salvo!"
                      : "Avaliação atualizada: ${recordController.text.trim()} $unit")),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: BeColors.primary, elevation: 0),
              child: Text("Salvar", style: BeFonts.button),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = AppState.instance.goalFor(widget.skill.id);
    final skill = widget.skill;

    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: AppBar(title: Text(skill.name.toUpperCase())),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(goal),
                    const SizedBox(height: BeSpacing.sm),

                    if (_needsBaseline)
                      _buildBaselineRequiredCard()
                    else if (_plan == null)
                      _buildNoGoalCard()
                    else
                      _buildTrailMap(),

                    const SizedBox(height: BeSpacing.sm),
                    if (!skill.isRunning)
                      _buildCalisthenicsBaselineBanner(skill)
                    else if (AppState.instance.runBaseline != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(BeSpacing.xxs),
                        decoration: BoxDecoration(
                          color: BeColors.canvasElevated,
                          border: Border.all(color: BeColors.primary, width: 1),
                        ),
                        child: Text(
                          "Baseline de corrida: ${AppState.instance.runBaseline!.describe()}",
                          textAlign: TextAlign.center,
                          style: BeFonts.titleMd.copyWith(
                              color: BeColors.primary, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: BeSpacing.sm, vertical: BeSpacing.xxs),
              child: Row(
                children: [
                  Expanded(
                    child: BeOutlineButton(
                      label: "Definir Meta",
                      icon: Icons.flag_outlined,
                      onPressed: () async {
                        await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SkillSelectionScreen(isEditMode: true),
                          ),
                        );
                        if (mounted) setState(() => _refreshPlan());
                      },
                    ),
                  ),
                  const SizedBox(width: BeSpacing.xxs),
                  Expanded(
                    child: BePrimaryButton(
                      label: "Recorde",
                      icon: Icons.emoji_events,
                      onPressed: _showReevaluationDialog,
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

  Widget _buildHeader(ExerciseGoal? goal) {
    final progress = _plan == null
        ? 0.0
        : (completedStages / _plan!.totalSteps).clamp(0.0, 1.0);
    return BeCard(
      padding: const EdgeInsets.all(BeSpacing.xs),
      borderColor: BeColors.hairline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.skill.name.toUpperCase(),
                  style: BeFonts.titleMd.copyWith(fontSize: 16)),
              if (goal != null)
                BeBadgePill(
                  label: goal.describe(widget.skill),
                  background: BeColors.primary.withValues(alpha: 0.12),
                  foreground: BeColors.primary,
                ),
            ],
          ),
          const SizedBox(height: BeSpacing.xxs),
          if (goal != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(BeSpacing.xxxs),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: BeColors.canvasElevated,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(BeColors.primary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text("$completedStages / ${_plan?.totalSteps ?? 0} passos",
                style: BeFonts.caption.copyWith(color: BeColors.muted)),
          ] else
            Text("Defina sua meta para gerar a trilha.",
                style: BeFonts.bodyMd.copyWith(color: BeColors.body)),
        ],
      ),
    );
  }

  Widget _buildNoGoalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BeSpacing.sm),
      decoration: BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border.all(color: BeColors.hairline, width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.flag_outlined, size: 48, color: BeColors.muted),
          const SizedBox(height: BeSpacing.xs),
          Text("Nenhuma meta definida",
              style: BeFonts.titleMd.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            "Toque em DEFINIR META e informe o alvo deste exercício.",
            textAlign: TextAlign.center,
            style: BeFonts.bodySm.copyWith(color: BeColors.body),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineRequiredCard() {
    final skill = widget.skill;
    final goal = AppState.instance.goalFor(skill.id);
    final isRun = skill.isRunning;
    final title = isRun ? "Calibre sua corrida" : "Avalie seu exercício";
    final body = isRun
        ? "Precisamos de uma corrida prévia para dimensionar seus passos. Use seu histórico ou rode uma avaliação agora."
        : (TrailGenerator.metricKindFor(skill, goal) == TrailMetricKind.hold
            ? "Quantos segundos você consegue segurar ${skill.name} hoje? Isso calibra os passos da trilha."
            : "Quantas repetições de ${skill.name} você consegue fazer hoje? Isso calibra os passos da trilha.");
    final cta = isRun ? "Calibrar Agora" : "Avaliar Agora";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BeSpacing.sm),
      decoration: BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border.all(color: BeColors.primary, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.fact_check_outlined, size: 48, color: BeColors.primary),
          const SizedBox(height: BeSpacing.xs),
          Text(title, style: BeFonts.titleMd.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text(body,
              textAlign: TextAlign.center,
              style: BeFonts.bodySm.copyWith(color: BeColors.body)),
          const SizedBox(height: BeSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: BePrimaryButton(
              label: cta,
              icon: Icons.fact_check_outlined,
              onPressed: _openBaselineDialog,
            ),
          ),
        ],
      ),
    );
  }

  /// Banner do baseline de calistenia: mostra quantos daquele exercício o
  /// atleta consegue fazer hoje (reps ou segundos).
  Widget _buildCalisthenicsBaselineBanner(CalisthenicsSkill skill) {
    final baseline = AppState.instance.calisthenicsBaselineOf(skill.id);
    if (baseline == null) return const SizedBox.shrink();
    final goal = AppState.instance.goalFor(skill.id);
    final isHold =
        TrailGenerator.metricKindFor(skill, goal) == TrailMetricKind.hold;
    final unit = isHold ? 'segundos' : 'reps';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BeSpacing.xxs),
      decoration: BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border.all(color: BeColors.primary, width: 1),
      ),
      child: Text(
        "Você faz hoje: $baseline $unit de ${skill.name}",
        textAlign: TextAlign.center,
        style: BeFonts.titleMd.copyWith(color: BeColors.primary, fontSize: 13),
      ),
    );
  }

  /// Mapa de nodes conectados estilo Duolingo.
  Widget _buildTrailMap() {
    final steps = _plan!.steps;
    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isDone = i < completedStages;
        final isCurrent = i == completedStages;
        final isLocked = i > completedStages;
        // Serpenteamento: desloca nodes para a esquerda/direita alternadamente.
        final alignLeft = i.isEven;

        return Column(
          children: [
            Row(
              mainAxisAlignment: alignLeft
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                _trailNode(step, i, isDone, isCurrent, isLocked),
              ],
            ),
            if (i < steps.length - 1) _connector(alignLeft),
          ],
        );
      }),
    );
  }

  Widget _trailNode(TrailStep step, int i, bool isDone, bool isCurrent, bool isLocked) {
    final Color color = isDone
        ? BeColors.semanticSuccess
        : isCurrent
            ? BeColors.primary
            : BeColors.canvasElevated;
    final Color borderColor = isLocked ? BeColors.hairline : color;

    return GestureDetector(
      onTap: isLocked ? null : () => _startStep(step, i == _plan!.steps.length - 1),
      child: Opacity(
        opacity: isLocked ? 0.55 : 1.0,
        child: Container(
          width: 72,
          padding: const EdgeInsets.all(BeSpacing.xxs),
          decoration: BoxDecoration(
            color: BeColors.canvasElevated,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(BeRadii.full), // node arredondado
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCurrent ? BeColors.primary : BeColors.canvas,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDone
                          ? BeColors.semanticSuccess
                          : borderColor,
                      width: 1),
                ),
                child: _nodeIcon(isDone, isCurrent, isLocked, i),
              ),
              const SizedBox(height: 4),
              Text("PASSO ${i + 1}",
                  style: BeFonts.caption.copyWith(
                      color: isLocked ? BeColors.muted : BeColors.ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6),
                  maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nodeIcon(bool isDone, bool isCurrent, bool isLocked, int i) {
    if (isDone) {
      return Icon(Icons.check, color: BeColors.semanticSuccess, size: 26);
    }
    if (isCurrent) {
      return Icon(Icons.play_arrow_rounded, color: BeColors.onPrimary, size: 26);
    }
    return Icon(Icons.lock_outline, color: BeColors.muted, size: 20);
  }

  /// Conector curvo entre nodes (estilo trilha Duolingo).
  Widget _connector(bool alignLeft) {
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: CustomPaint(
        painter: _ConnectorPainter(alignLeft),
      ),
    );
  }
}

/// Pinta um conector curvo (S) entre dois nodes consecutivos.
class _ConnectorPainter extends CustomPainter {
  final bool alignLeft;
  _ConnectorPainter(this.alignLeft);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BeColors.hairline
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final dx = alignLeft ? 36.0 : w - 36.0;

    final path = Path();
    path.moveTo(dx, 0.0);
    path.cubicTo(dx, h * 0.5, w - dx, h * 0.5, w - dx, h);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.alignLeft != alignLeft;
}