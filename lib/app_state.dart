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
}

/// Representação de uma Skill de Calistenia selecionável
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

/// Centralizador de Estado em Memória (Singleton)
class AppState {
  static final AppState instance = AppState._internal();
  AppState._internal();

  // Dados do perfil do usuário
  double weight = 75.0;
  double height = 1.75;
  int age = 25;
  String nickname = "";
  String? profilePhotoPath;

  // Histórico de corridas gravadas
  final List<RunLog> runHistory = [];

  // Lista de ID das Skills selecionadas pelo usuário
  final List<String> selectedSkillIds = [];

  // NOVO: Mapas para salvar o progresso real e recordes do atleta!
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
}