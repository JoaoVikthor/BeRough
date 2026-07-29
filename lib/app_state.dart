import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

/// Estrutura de dados para representar um treino de corrida finalizado
class RunLog {
  final double distanceInMeters;
  final int seconds;
  final String pace;
  final int calories;
  final DateTime date;
  final List<Position> route;

  RunLog({
    required this.distanceInMeters,
    required this.seconds,
    required this.pace,
    required this.calories,
    required this.date,
    required this.route,
  });

  Map<String, dynamic> toJson() => {
    'distanceInMeters': distanceInMeters,
    'seconds': seconds,
    'pace': pace,
    'calories': calories,
    'date': date.toIso8601String(),
    'route': route.map((p) => {
      'lat': p.latitude,
      'lng': p.longitude,
      'timestamp': p.timestamp.toIso8601String(),
      'accuracy': p.accuracy,
      'altitude': p.altitude,
      'heading': p.heading,
      'speed': p.speed,
    }).toList(),
  };

  factory RunLog.fromJson(Map<String, dynamic> j) {
    final List<dynamic> raw = j['route'] ?? [];
    final List<Position> route = raw.map((e) {
      final m = e as Map<String, dynamic>;
      return Position(
        latitude: (m['lat'] ?? 0).toDouble(),
        longitude: (m['lng'] ?? 0).toDouble(),
        timestamp: DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
        accuracy: (m['accuracy'] ?? 0).toDouble(),
        altitude: (m['altitude'] ?? 0).toDouble(),
        altitudeAccuracy: 0.0,
        heading: (m['heading'] ?? 0).toDouble(),
        headingAccuracy: 0.0,
        speed: (m['speed'] ?? 0).toDouble(),
        speedAccuracy: 0.0,
      );
    }).toList();

    return RunLog(
      distanceInMeters: (j['distanceInMeters'] ?? 0).toDouble(),
      seconds: (j['seconds'] ?? 0).toInt(),
      pace: j['pace'] ?? "-'--\"",
      calories: (j['calories'] ?? 0).toInt(),
      date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      route: route,
    );
  }
}

class CalisthenicsSkill {
  final String id;
  final String name;
  final String category;
  final String difficulty;
  final double initialProgress;
  final String iconName;

  CalisthenicsSkill({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.initialProgress,
    required this.iconName,
  });

  /// true para a skill de corrida (usa GPS + baseline de corrida).
  bool get isRunning => id == 'running_skill';
}

/// Tipo de métrica que um passo de trilha mede.
enum TrailMetricKind { time, reps, sets, hold, distance }

/// Classificação de calistenia usada pela UI de seleção de metas para decidir
/// quais campos mostrar (reps, séries, ou isometria em segundos). Espelha o
/// subconjunto de `TrailMetricKind` aplicável à calistenia.
enum CalistheniaKind { reps, sets, hold }

/// Meta definida pelo atleta para UMA skill (o alvo final da trilha).
class ExerciseGoal {
  final String skillId;

  /// Distância alvo em metros (corrida). 0 se não se aplica.
  final double targetDistanceMeters;

  /// Tempo alvo em segundos (corrida: 1km em X min; hold: tempo de isometria).
  final double targetSeconds;

  /// Repetições por série alvo (calistenia reps). 0 se não se aplica.
  final int targetReps;

  /// Número de séries alvo (calistenia). 0 se não se aplica.
  final int targetSets;

  ExerciseGoal({
    required this.skillId,
    this.targetDistanceMeters = 0,
    this.targetSeconds = 0,
    this.targetReps = 0,
    this.targetSets = 0,
  });

  TrailMetricKind get metricKind {
    if (targetDistanceMeters > 0) return TrailMetricKind.distance;
    if (targetReps > 0 && targetSets > 0) return TrailMetricKind.sets;
    if (targetReps > 0) return TrailMetricKind.reps;
    if (targetSeconds > 0) return TrailMetricKind.hold;
    return TrailMetricKind.time;
  }

  String describe(CalisthenicsSkill skill) {
    if (skill.isRunning) {
      final km = (targetDistanceMeters / 1000).toStringAsFixed(2);
      final min = (targetSeconds / 60).toStringAsFixed(0);
      final s = (targetSeconds % 60).toInt().toString().padLeft(2, '0');
      return '$km km em $min\':$s"';
    }
    switch (metricKind) {
      case TrailMetricKind.sets:
        return '$targetSets séries de $targetReps reps';
      case TrailMetricKind.reps:
        return '$targetReps repetições';
      case TrailMetricKind.hold:
        return 'isometria de ${(targetSeconds).toStringAsFixed(0)}s';
      case TrailMetricKind.time:
        return 'tempo alvo ${(targetSeconds).toStringAsFixed(0)}s';
      case TrailMetricKind.distance:
        return '${(targetDistanceMeters / 1000).toStringAsFixed(2)} km';
    }
  }

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'distance': targetDistanceMeters,
        'seconds': targetSeconds,
        'reps': targetReps,
        'sets': targetSets,
      };

  factory ExerciseGoal.fromJson(Map<String, dynamic> j) => ExerciseGoal(
        skillId: j['skillId'] ?? '',
        targetDistanceMeters: (j['distance'] ?? 0).toDouble(),
        targetSeconds: (j['seconds'] ?? 0).toDouble(),
        targetReps: (j['reps'] ?? 0).toInt(),
        targetSets: (j['sets'] ?? 0).toInt(),
      );
}

/// Origem do baseline de corrida usado para dimensionar os passos da trilha.
enum BaselineSource { history, assessment, manual }

/// Métrica prévia de corrida — base para dimensionar progressivos de treino.
class RunBaseline {
  final double distanceMeters;
  final double seconds;
  final String pace;
  final BaselineSource source;
  final DateTime capturedAt;

  RunBaseline({
    required this.distanceMeters,
    required this.seconds,
    required this.pace,
    required this.source,
    required this.capturedAt,
  });

  double get avgPaceSecPerKm => distanceMeters > 0
      ? seconds / (distanceMeters / 1000)
      : double.infinity;

  Map<String, dynamic> toJson() => {
        'distanceMeters': distanceMeters,
        'seconds': seconds,
        'pace': pace,
        'source': source.name,
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory RunBaseline.fromJson(Map<String, dynamic> j) => RunBaseline(
        distanceMeters: (j['distanceMeters'] ?? 0).toDouble(),
        seconds: (j['seconds'] ?? 0).toDouble(),
        pace: j['pace'] ?? "-'--\"",
        source: BaselineSource.values.firstWhere(
          (s) => s.name == (j['source'] ?? 'manual'),
          orElse: () => BaselineSource.manual,
        ),
        capturedAt:
            DateTime.tryParse(j['capturedAt'] ?? '') ?? DateTime.now(),
      );

  String describe() {
    final km = (distanceMeters / 1000).toStringAsFixed(2);
    final min = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).floor().toString().padLeft(2, '0');
    return '$km km em $min:$s ($pace)';
  }
}

/// Um passo de uma trilha progressiva.
class TrailStep {
  final String id;
  final int index;

  /// Fração da meta final (0..1) que este passo representa (progressão).
  final double goalFraction;
  final String title;
  final String desc;

  /// Referência de mídia (gif/imagem/video) a inserir depois; null = placeholder.
  final String? mediaRef;
  final TrailMetricKind metricKind;

  /// Valor alvo do passo (sem unidade — interpretado por metricKind).
  final double targetValue;

  /// Estimativa derivada do baseline (para contexto/coach).
  final double estimateFromBaseline;

  TrailStep({
    required this.id,
    required this.index,
    required this.goalFraction,
    required this.title,
    required this.desc,
    this.mediaRef,
    required this.metricKind,
    required this.targetValue,
    required this.estimateFromBaseline,
  });
}

/// Plano de trilha completo de uma skill.
class TrailPlan {
  final String skillId;
  final List<TrailStep> steps;

  /// Índice do passo atual (0-based). Persistido pelo AppState.completedStages.
  int get currentIndex =>
      (AppState.instance.completedStages[skillId] ?? 0).clamp(0, steps.length);

  TrailPlan({required this.skillId, required this.steps});

  int get totalSteps => steps.length;
}

/// Centralizador de Estado em Memória (Singleton).
///
/// Para o MVP da Fase 3, os dados do perfil (peso/altura/idade/apelido),
/// skills selecionadas, etapas concluídas, recordes e o histórico de
/// corridas são persistidos localmente via SharedPreferences. Na Fase 4,
/// esses dados serão migrados para o Firestore.
class AppState {
  static final AppState instance = AppState._internal();
  AppState._internal();

  // Chaves de persistência
  static const _kWeight = 'profile_weight';
  static const _kHeight = 'profile_height';
  static const _kAge = 'profile_age';
  static const _kNickname = 'profile_nickname';
  static const _kSkills = 'profile_selected_skills';
  static const _kCompletedStages = 'profile_completed_stages';
  static const _kUserRecords = 'profile_user_records';
  static const _kRunHistory = 'profile_run_history';
  static const _kUserRestored = 'profile_user_restored';
  static const _kGoals = 'profile_exercise_goals';
  static const _kRunBaseline = 'profile_run_baseline';
  static const _kCalisthenicsBaselines =
      'profile_calisthenics_baselines';

  bool _restored = false;

  double weight = 75.0;
  double height = 1.75;
  int age = 25;
  String nickname = "";
  String? profilePhotoPath;

  final List<RunLog> runHistory = [];
  final List<String> selectedSkillIds = [];

  final Map<String, int> completedStages = {};
  final Map<String, String> userRecords = {};
  final Map<String, ExerciseGoal> goals = {};

  /// Baseline por exercício de calistenia — quantas reps (ou segundos, em
  /// holds) o atleta consegue fazer HOJE daquele exercício. Métrica de
  /// comparação para gerar a trilha progressiva. NÃO usa a corrida.
  final Map<String, int> calisthenicsBaselines = {};

  RunBaseline? runBaseline;

  final List<CalisthenicsSkill> availableSkills = [
    CalisthenicsSkill(
      id: "push_ups", name: "Flexões Básicas", category: "Força de Empurrar",
      difficulty: "Iniciante", initialProgress: 0.5, iconName: "fitness_center",
    ),
    CalisthenicsSkill(
      id: "squats", name: "Agachamento Livre", category: "Pernas",
      difficulty: "Iniciante", initialProgress: 0.6, iconName: "accessibility_new",
    ),
    CalisthenicsSkill(
      id: "running_skill", name: "Corrida de Rua", category: "Cardio",
      difficulty: "Iniciante", initialProgress: 0.4, iconName: "flag",
    ),
    CalisthenicsSkill(
      id: "handstand_prep", name: "Plantar Bananeira", category: "Equilíbrio",
      difficulty: "Intermediário", initialProgress: 0.1, iconName: "sports_gymnastics",
    ),
    CalisthenicsSkill(
      id: "pull_ups", name: "Barra Fixa", category: "Força de Puxada",
      difficulty: "Intermediário", initialProgress: 0.3, iconName: "arrow_upward",
    ),
    CalisthenicsSkill(
      id: "muscle_up", name: "Muscle Up", category: "Força Explosiva",
      difficulty: "Avançado", initialProgress: 0.0, iconName: "arrow_upward",
    ),
    CalisthenicsSkill(
      id: "front_lever", name: "Front Lever", category: "Isometria",
      difficulty: "Elite", initialProgress: 0.0, iconName: "horizontal_rule",
    ),
  ];

  Future<void> saveOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
  }

  Future<bool> getOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_onboarding') ?? false;
  }

  // ===== Persistência de perfil e progresso =====

  bool get hasProfileData => _restored && selectedSkillIds.isNotEmpty && nickname.isNotEmpty;

  /// Carrega do disco tudo o que foi salvo localmente. Idempotente.
  Future<void> loadFromDisk() async {
    if (_restored) return;
    final prefs = await SharedPreferences.getInstance();

    try {
      weight = prefs.getDouble(_kWeight) ?? weight;
      height = prefs.getDouble(_kHeight) ?? height;
      age = prefs.getInt(_kAge) ?? age;
      nickname = prefs.getString(_kNickname) ?? nickname;

      final skills = prefs.getStringList(_kSkills);
      if (skills != null) {
        selectedSkillIds
          ..clear()
          ..addAll(skills);
      }

      final completedRaw = prefs.getString(_kCompletedStages);
      if (completedRaw != null) {
        final map = jsonDecode(completedRaw) as Map<String, dynamic>;
        completedStages.clear();
        map.forEach((k, v) => completedStages[k] = (v as num).toInt());
      }

      final recordsRaw = prefs.getString(_kUserRecords);
      if (recordsRaw != null) {
        final map = jsonDecode(recordsRaw) as Map<String, dynamic>;
        userRecords.clear();
        map.forEach((k, v) => userRecords[k] = v.toString());
      }

      final runsRaw = prefs.getString(_kRunHistory);
      if (runsRaw != null) {
        final list = jsonDecode(runsRaw) as List<dynamic>;
        runHistory
          ..clear()
          ..addAll(list.map((e) => RunLog.fromJson(e as Map<String, dynamic>)));
      }

      final goalsRaw = prefs.getString(_kGoals);
      if (goalsRaw != null) {
        final map = jsonDecode(goalsRaw) as Map<String, dynamic>;
        goals.clear();
        map.forEach((k, v) =>
            goals[k] = ExerciseGoal.fromJson(v as Map<String, dynamic>));
      }

      final baselineRaw = prefs.getString(_kRunBaseline);
      if (baselineRaw != null) {
        runBaseline = RunBaseline.fromJson(
            jsonDecode(baselineRaw) as Map<String, dynamic>);
      }

      final calBaselinesRaw = prefs.getString(_kCalisthenicsBaselines);
      if (calBaselinesRaw != null) {
        final map = jsonDecode(calBaselinesRaw) as Map<String, dynamic>;
        calisthenicsBaselines.clear();
        map.forEach(
            (k, v) => calisthenicsBaselines[k] = (v as num).toInt());
      }

      _restored = true;
      _restoredFlagSet(prefs);
    } catch (_) {
      _restored = true;
    }
  }

  void _restoredFlagSet(SharedPreferences prefs) {
    prefs.setBool(_kUserRestored, true);
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kWeight, weight);
    await prefs.setDouble(_kHeight, height);
    await prefs.setInt(_kAge, age);
    await prefs.setString(_kNickname, nickname);
    await prefs.setStringList(_kSkills, selectedSkillIds);
    await prefs.setString(_kCompletedStages, jsonEncode(completedStages));
    await prefs.setString(_kUserRecords, jsonEncode(userRecords));
    await prefs.setString(_kGoals,
        jsonEncode(goals.map((k, v) => MapEntry(k, v.toJson()))));
    if (runBaseline != null) {
      await prefs.setString(_kRunBaseline, jsonEncode(runBaseline!.toJson()));
    }
    await prefs.setString(
        _kCalisthenicsBaselines, jsonEncode(calisthenicsBaselines));
  }

  Future<void> addRunToHistory(RunLog run) async {
    runHistory.insert(0, run);
    await _saveRunHistory();
  }

  Future<void> clearRunHistory() async {
    runHistory.clear();
    await _saveRunHistory();
  }

  Future<void> _saveRunHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(runHistory.map((r) => r.toJson()).toList());
    await prefs.setString(_kRunHistory, encoded);
  }

  /// Limpa todos os dados do usuário (usado no logout).
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWeight);
    await prefs.remove(_kHeight);
    await prefs.remove(_kAge);
    await prefs.remove(_kNickname);
    await prefs.remove(_kSkills);
    await prefs.remove(_kCompletedStages);
    await prefs.remove(_kUserRecords);
    await prefs.remove(_kRunHistory);
    await prefs.remove(_kUserRestored);
    await prefs.remove(_kGoals);
    await prefs.remove(_kRunBaseline);
    await prefs.remove(_kCalisthenicsBaselines);

    weight = 75.0;
    height = 1.75;
    age = 25;
    nickname = "";
    profilePhotoPath = null;
    runHistory.clear();
    selectedSkillIds.clear();
    completedStages.clear();
    userRecords.clear();
    goals.clear();
    calisthenicsBaselines.clear();
    runBaseline = null;
    _restored = false;
  }

  // ===== Estatísticas agregadas (usadas no Perfil e Dashboard) =====

  /// Nível do atleta: sobe 1 a cada 3 atividades registradas.
  int get athleteLevel => (runHistory.length ~/ 3) + 1;

  /// XP atual = corridas × 50.
  int get currentXP => runHistory.length * 50;

  /// XP alvo para o próximo nível.
  int get nextLevelXP => athleteLevel * 150;

  /// Progresso fracionário (0..1) para o próximo nível.
  double get levelProgress =>
      nextLevelXP > 0 ? (currentXP / nextLevelXP).clamp(0.0, 1.0) : 0.0;

  /// Distância total percorrida em metros (somatório das corridas).
  double get totalDistanceMeters =>
      runHistory.fold(0.0, (s, r) => s + r.distanceInMeters);

  /// Tempo total em segundos.
  int get totalRunSeconds => runHistory.fold(0, (s, r) => s + r.seconds);

  /// Calorias totais queimadas.
  int get totalCalories => runHistory.fold(0, (s, r) => s + r.calories);

  /// Distância total em km (string formatada).
  String get totalDistanceKm => (totalDistanceMeters / 1000).toStringAsFixed(2);

  /// Tempo total formatado "HH:MM:SS".
  String get totalTimeFormatted {
    final int s = totalRunSeconds;
    final int h = s ~/ 3600;
    final int m = (s % 3600) ~/ 60;
    final int sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  /// Conta total de etapas concluídas em todas as skills.
  int get totalCompletedStages =>
      completedStages.values.fold(0, (s, v) => s + v);

  /// Número de recordes pessoais distintos salvos.
  int get totalPRs => userRecords.length;

  // ===== Metas, baseline de corrida e trilhas =====

  ExerciseGoal? goalFor(String skillId) => goals[skillId];

  void setGoal(ExerciseGoal goal) {
    goals[goal.skillId] = goal;
  }

  /// true quando a corrida está entre as trilhas selecionadas.
  bool get runningSkillEnabled =>
      selectedSkillIds.contains('running_skill');

  /// Última corrida registrada (candidata a baseline via histórico).
  RunLog? get lastRun => runHistory.isEmpty ? null : runHistory.first;

  /// Define/eterna o baseline de corrida a partir de uma corrida existente.
  void setRunBaselineFromHistory() {
    final r = lastRun;
    if (r == null) return;
    runBaseline = RunBaseline(
      distanceMeters: r.distanceInMeters,
      seconds: r.seconds.toDouble(),
      pace: r.pace,
      source: BaselineSource.history,
      capturedAt: r.date,
    );
  }

  /// Define baseline manual (input do atleta).
  void setRunBaselineManual({
    required double distanceMeters,
    required double seconds,
    required String pace,
  }) {
    runBaseline = RunBaseline(
      distanceMeters: distanceMeters,
      seconds: seconds,
      pace: pace,
      source: BaselineSource.manual,
      capturedAt: DateTime.now(),
    );
  }

  /// Define baseline a partir de uma corrida de avaliação recém-feita.
  void setRunBaselineAssessment({
    required double distanceMeters,
    required double seconds,
    required String pace,
    required List<Position> route,
  }) {
    runBaseline = RunBaseline(
      distanceMeters: distanceMeters,
      seconds: seconds.toDouble(),
      pace: pace,
      source: BaselineSource.assessment,
      capturedAt: DateTime.now(),
    );
  }

  // ===== Baseline de calistenia (por exercício) =====
  //
  // Quantos DAQUELE exercício o atleta consegue fazer HOJE (reps, ou
  // segundos em holds). É a métrica de comparação para gerar a trilha
  // progressiva daquela skill — não usa a corrida.

  int? calisthenicsBaselineOf(String skillId) =>
      calisthenicsBaselines[skillId];

  /// Define o baseline de calistenia. Também espelha em `userRecords`
  /// (formato legível) para a UI de Perfil mostrar "PR".
  void setCalisthenicsBaseline(String skillId, int value) {
    calisthenicsBaselines[skillId] = value;
    userRecords[skillId] = value.toString();
  }
}