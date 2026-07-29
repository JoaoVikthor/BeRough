import 'package:flutter/material.dart';
import 'dart:async';
import '../../app_state.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';
import '../running_screen.dart';
import 'step_complete_screen.dart';

/// Tela de exercício passo a passo.
///
/// - Área de mídia reservada (placeholder para gif/imagem/vídeo animado
///   a inserir posteriormente — `mediaRef`).
/// - Contador conforme métrica do passo:
///   · `time`   → cronômetro progressivo.
///   · `hold`   → cronômetro regressivo (isometria).
///   · `reps`   → contador de repetições.
///   · `sets`   → contador de séries concluídas.
///   · `distance` → delega para a tela de corrida ao vivo (RunningScreen).
/// - Ao concluir, abre `StepCompleteScreen`.
class StepScreen extends StatefulWidget {
  final CalisthenicsSkill skill;
  final TrailStep step;
  final bool isFinalStep;

  const StepScreen({
    super.key,
    required this.skill,
    required this.step,
    required this.isFinalStep,
  });

  @override
  State<StepScreen> createState() => _StepScreenState();
}

class _StepScreenState extends State<StepScreen> {
  Timer? _timer;
  int _elapsedSec = 0;
  bool _isRunning = false;

  // Para hold (regressivo).
  int? _holdRemaining;
  bool _holdFinished = false;

  // Contadores de reps/sets.
  int _repsDone = 0;
  int _setsDone = 0;
  int get _targetSets => widget.step.estimateFromBaseline.round();
  int get _targetReps => widget.step.targetValue.round();

  @override
  void initState() {
    super.initState();
    if (widget.step.metricKind == TrailMetricKind.hold) {
      _holdRemaining = widget.step.targetValue.round();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSec++;
        if (widget.step.metricKind == TrailMetricKind.hold &&
            _holdRemaining != null &&
            !_holdFinished) {
          _holdRemaining = _holdRemaining! - 1;
          if (_holdRemaining! <= 0) {
            _holdRemaining = 0;
            _holdFinished = true;
            _isRunning = false;
            _timer?.cancel();
          }
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _elapsedSec = 0;
      if (widget.step.metricKind == TrailMetricKind.hold) {
        _holdRemaining = widget.step.targetValue.round();
        _holdFinished = false;
      }
    });
  }

  void _markSet() {
    setState(() {
      _setsDone++;
    });
  }

  void _addRep() {
    setState(() => _repsDone++);
  }

  void _completeStep() {
    _timer?.cancel();
    // Persiste progresso da skill.
    final completed =
        AppState.instance.completedStages[widget.skill.id] ?? 0;
    AppState.instance.completedStages[widget.skill.id] = completed + 1;
    AppState.instance.saveProfile();

    final log = _buildAchievedLog();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StepCompleteScreen(
          skill: widget.skill,
          step: widget.step,
          isFinalStep: widget.isFinalStep,
          achievedLog: log,
        ),
      ),
    );
  }

  String _buildAchievedLog() {
    switch (widget.step.metricKind) {
      case TrailMetricKind.distance:
        return "${widget.step.title} — corrida concluída.";
      case TrailMetricKind.hold:
        return "Isometria de ${widget.step.targetValue.toStringAsFixed(0)}s mantida.";
      case TrailMetricKind.time:
        final m = _elapsedSec ~/ 60;
        final s = _elapsedSec % 60;
        return "Tempo registrado: ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.";
      case TrailMetricKind.reps:
        return "$_repsDone repetições executadas (meta $_targetReps).";
      case TrailMetricKind.sets:
        return "$_setsDone séries de $_targetReps reps concluídas.";
    }
  }

  String _fmt(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.step.metricKind;

    // Se o passo é um passo de corrida (distance), delega imediatamente para
    // a tela de corrida ao vivo.
    if (kind == TrailMetricKind.distance) {
      return _buildDistanceDelegation(context);
    }

    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: AppBar(
        title: Text("PASSO ${widget.step.index + 1}".toUpperCase()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: BeColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do passo
              const SizedBox(height: BeSpacing.xs),
              Text(stepTitle,
                  style: BeFonts.displayMd.copyWith(fontSize: 24)),
              const SizedBox(height: 4),
              Text(widget.step.desc,
                  style: BeFonts.bodyMd.copyWith(color: BeColors.body)),
              const SizedBox(height: BeSpacing.sm),

              // Área de mídia reservada (placeholder para gif/imagem/vídeo)
              _buildMediaSlot(),
              const SizedBox(height: BeSpacing.sm),

              // Métrica / contador
              Expanded(child: _buildMetricArea(kind)),

              // Controles
              _buildControls(kind),
              const SizedBox(height: BeSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: BePrimaryButton(
                  label: "Concluir Passo",
                  icon: Icons.check_circle_outline,
                  onPressed: _completeStep,
                ),
              ),
              const SizedBox(height: BeSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  String get stepTitle => widget.step.title;

  /// Slot de mídia: se `mediaRef` existir no futuro, carrega o asset; enquanto
  /// não há asset, mostra o placeholder editorial (sem inventar conteúdo).
  Widget _buildMediaSlot() {
    final ref = widget.step.mediaRef;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: BeColors.canvasElevated,
          border: Border.all(color: BeColors.hairline, width: 1),
        ),
        child: ref == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_outlined,
                      color: BeColors.muted, size: 48),
                  const SizedBox(height: BeSpacing.xxs),
                  Text("MÍDIA DO EXERCÍCIO",
                      style: BeFonts.captionUppercase.copyWith(
                          color: BeColors.muted,
                          fontSize: 10,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text("GIF/vídeo animado a ser inserido",
                      style: BeFonts.caption.copyWith(color: BeColors.muted)),
                ],
              )
            : Image.asset(ref, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildMetricArea(TrailMetricKind kind) {
    switch (kind) {
      case TrailMetricKind.time:
      case TrailMetricKind.hold:
        final display = kind == TrailMetricKind.hold
            ? _fmt(_holdRemaining ?? 0)
            : _fmt(_elapsedSec);
        final label = kind == TrailMetricKind.hold ? "RESTANTE" : "TEMPO";
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(display,
                style: BeFonts.numberDisplay
                    .copyWith(fontSize: 64, letterSpacing: -1.2)),
            Text(label,
                style: BeFonts.captionUppercase.copyWith(
                    color: BeColors.body,
                    fontSize: 11,
                    letterSpacing: 1.4)),
            if (kind == TrailMetricKind.hold && _holdFinished) ...[
              const SizedBox(height: BeSpacing.xs),
              BeBadgePill(
                label: "Hold Concluído",
                background: BeColors.semanticSuccess.withOpacity(0.12),
                foreground: BeColors.semanticSuccess,
              ),
            ],
          ],
        );
      case TrailMetricKind.reps:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("$_repsDone",
                style: BeFonts.numberDisplay
                    .copyWith(fontSize: 64, letterSpacing: -1.2)),
            Text("REPETIÇÕES (meta $_targetReps)",
                style: BeFonts.captionUppercase.copyWith(
                    color: BeColors.body,
                    fontSize: 11,
                    letterSpacing: 1.4)),
          ],
        );
      case TrailMetricKind.sets:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("$_setsDone / $_targetSets",
                style: BeFonts.numberDisplay
                    .copyWith(fontSize: 64, letterSpacing: -1.2)),
            Text("SÉRIES CONCLUÍDAS",
                style: BeFonts.captionUppercase.copyWith(
                    color: BeColors.body,
                    fontSize: 11,
                    letterSpacing: 1.4)),
            const SizedBox(height: BeSpacing.xxs),
            Text("$_repsDone reps nesta série (meta $_targetReps)",
                style: BeFonts.caption.copyWith(color: BeColors.muted)),
          ],
        );
      case TrailMetricKind.distance:
        return const SizedBox.shrink();
    }
  }

  Widget _buildControls(TrailMetricKind kind) {
    if (kind == TrailMetricKind.time || kind == TrailMetricKind.hold) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleButton(
            icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onTap: _isRunning ? _pauseTimer : _startTimer,
            primary: true,
          ),
          const SizedBox(width: BeSpacing.xs),
          _circleButton(
            icon: Icons.refresh_rounded,
            onTap: _resetTimer,
          ),
        ],
      );
    }
    if (kind == TrailMetricKind.reps) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleButton(
            icon: Icons.add,
            label: "REP",
            onTap: _addRep,
            primary: true,
          ),
        ],
      );
    }
    if (kind == TrailMetricKind.sets) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleButton(
            icon: Icons.add,
            label: "REP",
            onTap: _addRep,
          ),
          const SizedBox(width: BeSpacing.xs),
          _circleButton(
            icon: Icons.check_circle_outline,
            label: "SÉRIE",
            onTap: _markSet,
            primary: true,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _circleButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: primary ? BeColors.primary : BeColors.canvasElevated,
          shape: BoxShape.circle,
          border: primary
              ? null
              : Border.all(color: BeColors.primary, width: 2),
        ),
        child: label == null
            ? Icon(icon,
                color: primary ? BeColors.onPrimary : BeColors.primary,
                size: 36)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      color:
                          primary ? BeColors.onPrimary : BeColors.primary,
                      size: 26),
                  Text(label,
                      style: BeFonts.caption.copyWith(
                          color: primary
                              ? BeColors.onPrimary
                              : BeColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0)),
                ],
              ),
      ),
    );
  }

  /// Para passos de corrida, abre a RunningScreen com a meta daquele passo.
  /// Ao voltar, considera o passo concluído.
  Widget _buildDistanceDelegation(BuildContext context) {
    final goal = AppState.instance.goalFor(widget.skill.id);
    final targetKm =
        goal != null ? goal.targetDistanceMeters / 1000 : 1.0;
    // Alvo do passo (km) fica acessível ao widget abaixo se necessário.
    return _RunStepHost(
      skill: widget.skill,
      step: widget.step,
      isFinalStep: widget.isFinalStep,
      targetKm: targetKm,
    );
  }
}

/// Hospedeiro do passo de corrida: usa RunningScreen mas, ao finalizar,
/// marca o passo como concluído e abre a tela de parabéns.
class _RunStepHost extends StatelessWidget {
  final CalisthenicsSkill skill;
  final TrailStep step;
  final bool isFinalStep;
  final double targetKm;

  const _RunStepHost({
    required this.skill,
    required this.step,
    required this.isFinalStep,
    required this.targetKm,
  });

  @override
  Widget build(BuildContext context) {
    return RunningScreen(
      key: ValueKey('step_run_${step.id}'),
      isTrailStep: true,
      trailSkillId: skill.id,
      isFinalStep: isFinalStep,
    );
  }
}