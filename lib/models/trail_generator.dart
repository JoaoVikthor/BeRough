import '../app_state.dart';

/// Gera um `TrailPlan` a partir de uma `ExerciseGoal` calibrado ao baseline
/// disponível (corrida: `RunBaseline`; calistenia: `calisthenicsBaselines`).
///
/// Sem baseline, retorna `null` — a UI deve exigir a captura por exercício
/// (quantos daquele exercício o atleta consegue fazer) antes de dimensionar
/// a trilha. Nunca inventa métrica.
class TrailGenerator {
  TrailGenerator._();

  /// Determina o tipo de métrica de uma skill de calistenia a partir da
  /// meta (se houver) ou da categoria. Usado para frases e médias.
  static TrailMetricKind metricKindFor(
      CalisthenicsSkill skill, ExerciseGoal? goal) {
    if (skill.isRunning) return TrailMetricKind.distance;
    if (goal != null) return goal.metricKind;
    final cat = skill.category.toLowerCase();
    if (cat.contains('isometr') ||
        cat.contains('equilíbrio') ||
        cat.contains('equilibrio')) {
      return TrailMetricKind.hold;
    }
    if (cat.contains('força') ||
        cat.contains('forca') ||
        cat.contains('puxada') ||
        cat.contains('explosiva')) {
      return TrailMetricKind.sets;
    }
    return TrailMetricKind.reps;
  }

  /// true quando já existe baseline suficiente para dimensionar a trilha.
  static bool hasBaseline(CalisthenicsSkill skill) {
    if (skill.isRunning) return AppState.instance.runBaseline != null;
    return AppState.instance.calisthenicsBaselineOf(skill.id) != null;
  }

  static TrailPlan? generatePlan(CalisthenicsSkill skill) {
    final goal = AppState.instance.goalFor(skill.id);
    if (goal == null) return null;
    if (!hasBaseline(skill)) return null;

    if (skill.isRunning) return _runningPlan(skill, goal);
    return _calisthenicsPlan(skill, goal);
  }

  // ===== Corrida =====

  static TrailPlan _runningPlan(CalisthenicsSkill skill, ExerciseGoal goal) {
    final baseline = AppState.instance.runBaseline!;
    final targetKm = goal.targetDistanceMeters / 1000;
    final targetSec = goal.targetSeconds;
    final fractions = [0.4, 0.6, 0.8, 1.0];
    final steps = <TrailStep>[];

    for (var i = 0; i < fractions.length; i++) {
      final f = fractions[i];
      final stepKm = targetKm * f;
      // Pace estimado parte do baseline e melhora suavemente até o alvo.
      final baselinePace = baseline.avgPaceSecPerKm; // s/km
      final targetPace = targetSec / targetKm; // s/km
      final estPace = baselinePace +
          (targetPace - baselinePace) * (f); // interpola até o alvo
      final estSec = stepKm * estPace;

      final isFinal = i == fractions.length - 1;
      steps.add(TrailStep(
        id: '${skill.id}_$i',
        index: i,
        goalFraction: f,
        title: isFinal
            ? 'Desafio Final: ${targetKm.toStringAsFixed(2)} km'
            : 'Passada ${i + 1}: ${stepKm.toStringAsFixed(2)} km',
        desc: isFinal
            ? 'Sustente o ritmo-alvo e alcansen sua meta de ${goal.describe(skill)}.'
            : 'Corra ${stepKm.toStringAsFixed(2)} km num ritmo controlado. Estimativa ~${_fmtPace(estPace)}/km.',
        metricKind: TrailMetricKind.distance,
        targetValue: stepKm * 1000,
        estimateFromBaseline: estSec,
      ));
    }
    return TrailPlan(skillId: skill.id, steps: steps);
  }

  static String _fmtPace(double secPerKm) {
    final m = secPerKm.floor();
    final s = ((secPerKm - m) * 60).floor().toString().padLeft(2, '0');
    return "$m'$s\"";
  }

  // ===== Calistenia =====

  static TrailPlan _calisthenicsPlan(
      CalisthenicsSkill skill, ExerciseGoal goal) {
    // Baseline = quantos DAQUELE exercício o atleta consegue fazer hoje.
    // (reps para reps/sets; segundos para hold).
    final int baselineValue =
        AppState.instance.calisthenicsBaselineOf(skill.id) ?? 1;
    final bool isHold = goal.metricKind == TrailMetricKind.hold ||
        metricKindFor(skill, goal) == TrailMetricKind.hold;

    final fractions = [0.4, 0.7, 1.0];
    final steps = <TrailStep>[];

    // ---- Hold (isometria/equilíbrio): baseline em segundos ----
    if (isHold) {
      final double targetSec = goal.targetSeconds > 0 ? goal.targetSeconds : 30;
      final int baselineSec = baselineValue > 0 ? baselineValue : 1;
      for (var i = 0; i < fractions.length; i++) {
        final f = fractions[i];
        // Interpola do baseline até o alvo: passo inicial perto do baseline.
        final double stepSec =
            (baselineSec + (targetSec - baselineSec) * f).ceil().toDouble();
        final isFinal = i == fractions.length - 1;
        steps.add(TrailStep(
          id: '${skill.id}_$i',
          index: i,
          goalFraction: f,
          title: isFinal
              ? 'Desafio Final: segurar ${targetSec.toStringAsFixed(0)}s'
              : 'Isometria ${i + 1}: ${stepSec.toStringAsFixed(0)}s',
          desc: isFinal
              ? 'Mantenha a posição por ${targetSec.toStringAsFixed(0)}s. Forma perfeita.'
              : 'Hold de ${stepSec.toStringAsFixed(0)}s (seu recorde é $baselineSec s). 3 séries, descanso 45s.',
          metricKind: TrailMetricKind.hold,
          targetValue: stepSec,
          estimateFromBaseline: baselineSec.toDouble(),
        ));
      }
      return TrailPlan(skillId: skill.id, steps: steps);
    }

    // ---- Reps / Sets: baseline em reps ----
    final int baselineReps = baselineValue > 0 ? baselineValue : 1;
    final int targetReps = goal.targetReps > 0 ? goal.targetReps : 5;
    final int targetSets = goal.targetSets > 0 ? goal.targetSets : 3;

    for (var i = 0; i < fractions.length; i++) {
      final f = fractions[i];
      // Interpola do baseline até o alvo de reps.
      final int stepReps =
          (baselineReps + (targetReps - baselineReps) * f)
              .ceil()
              .clamp(1, targetReps);
      final int stepSets = targetSets == 1
          ? 1
          : (targetSets * (0.6 + 0.4 * f)).ceil().clamp(1, targetSets);
      final int estTotal = stepReps * stepSets;
      final isFinal = i == fractions.length - 1;
      final kind =
          targetSets > 1 ? TrailMetricKind.sets : TrailMetricKind.reps;

      steps.add(TrailStep(
        id: '${skill.id}_$i',
        index: i,
        goalFraction: f,
        title: isFinal
            ? 'Desafio Final: $targetReps reps × $targetSets séries'
            : 'Volume ${i + 1}: $stepReps reps × $stepSets séries',
        desc: isFinal
            ? 'Execute $targetReps repetições em $targetSets séries. Conquiste sua meta!'
            : 'Você faz $baselineReps hoje. Faça $stepReps reps × $stepSets séries (descanso 60s). Total $estTotal reps.',
        metricKind: kind,
        targetValue: stepReps.toDouble(),
        estimateFromBaseline: stepSets.toDouble(),
      ));
    }
    return TrailPlan(skillId: skill.id, steps: steps);
  }
}