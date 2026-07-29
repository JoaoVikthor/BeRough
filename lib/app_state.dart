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

    weight = 75.0;
    height = 1.75;
    age = 25;
    nickname = "";
    profilePhotoPath = null;
    runHistory.clear();
    selectedSkillIds.clear();
    completedStages.clear();
    userRecords.clear();
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
}