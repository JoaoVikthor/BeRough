import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_state.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';
import 'auth/onboarding_screen.dart';
import 'run_history_screen.dart';
import 'skill_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  double get _weight => AppState.instance.weight;
  double get _height => AppState.instance.height;
  int get _age => AppState.instance.age;
  double get _bmi => _height > 0 ? _weight / (_height * _height) : 0;

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isUploading = true);
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePhotoURL(pickedFile.path);
          await user.reload();
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Foto de perfil atualizada com sucesso!")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Falha ao acessar mídia: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: BeColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BeSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("FOTO DO ATLETA",
                  style: BeFonts.titleMd.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                "Selecione a origem da imagem para atualizar seu perfil.",
                style: BeFonts.bodySm.copyWith(color: BeColors.body),
              ),
              const SizedBox(height: BeSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: BePrimaryButton(
                      label: "Câmera",
                      icon: Icons.camera_alt_outlined,
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: BeSpacing.xxs),
                  Expanded(
                    child: BeOutlineButton(
                      label: "Galeria",
                      icon: Icons.photo_library_outlined,
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoURL) {
    if (_isUploading) {
      return const CircularProgressIndicator(color: BeColors.primary);
    }
    if (photoURL == null || photoURL.isEmpty) {
      return const Icon(Icons.person, size: 54, color: BeColors.muted);
    }
    if (photoURL.startsWith('http')) {
      return ClipOval(
        child: Image.network(photoURL,
            width: 108,
            height: 108,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.person, size: 54, color: BeColors.muted)),
      );
    }
    return ClipOval(
      child: Image.file(File(photoURL),
          width: 108,
          height: 108,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.person, size: 54, color: BeColors.muted)),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BeColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text("Fazer Logout?",
            style: BeFonts.titleMd.copyWith(fontSize: 18)),
        content: Text(
          "Você sairá da sua conta de atleta BeRough, mas seus treinos continuarão salvos no dispositivo.",
          style: BeFonts.bodyMd.copyWith(color: BeColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCELAR",
                style: BeFonts.button.copyWith(color: BeColors.muted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              await AppState.instance.clearUserData();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  this.context,
                  MaterialPageRoute(
                      builder: (context) => const OnboardingScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: BeColors.primary, elevation: 0),
            child: Text("SAIR", style: BeFonts.button),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String athleteName =
        user?.displayName ?? AppState.instance.nickname.ifEmpty("Atleta BeRough");
    final String athleteEmail = user?.email ?? "atleta@berough.com";
    final String? photoURL = user?.photoURL;

    final state = AppState.instance;
    final selectedSkills = state.availableSkills
        .where((s) => state.selectedSkillIds.contains(s.id))
        .toList();

    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: AppBar(
        title: Text("PERFIL DE ATLETA"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: BeColors.ink, size: 20),
            tooltip: "Editar perfil",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const SkillSelectionScreen(isEditMode: true)),
            ).then((_) {
              if (mounted) setState(() {});
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------ Cabeçalho com avatar + nome + email ------
              const SizedBox(height: BeSpacing.xs),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: BeColors.primary, width: 1),
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: BeColors.canvasElevated,
                        child: _buildAvatar(photoURL),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceSelector,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: BeColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: BeColors.onPrimary, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BeSpacing.xxs),
              Center(
                child: Text(athleteName,
                    style: BeFonts.titleMd.copyWith(fontSize: 22)),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(athleteEmail,
                    style: BeFonts.bodySm.copyWith(color: BeColors.body)),
              ),

              const SizedBox(height: BeSpacing.sm),

              // ------ Progresso de Nível / XP ------
              _buildLevelCard(),
              const SizedBox(height: BeSpacing.sm),

              // ------ Métricas corporais ------
              const BeSectionLabel("Métricas Corporais"),
              const SizedBox(height: BeSpacing.xxs),
              Row(
                children: [
                  Expanded(child: _buildMetricItem("PESO", "$_weight", "kg")),
                  const SizedBox(width: BeSpacing.xxs),
                  Expanded(child: _buildMetricItem("ALTURA", "$_height", "m")),
                  const SizedBox(width: BeSpacing.xxs),
                  Expanded(child: _buildMetricItem("IDADE", "$_age", "anos")),
                ],
              ),
              const SizedBox(height: BeSpacing.xxs),
              _buildLudicBMICard(),

              const SizedBox(height: BeSpacing.sm),

              // ------ Estatísticas agregadas (corridas) ------
              const BeSectionLabel("Estatísticas de Corrida"),
              const SizedBox(height: BeSpacing.xxs),
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(Icons.directions_run,
                          "${state.runHistory.length}", "Corridas", BeColors.primary)),
                  const SizedBox(width: BeSpacing.xxs),
                  Expanded(
                      child: _buildStatCard(Icons.straighten,
                          state.totalDistanceKm, "km totais", BeColors.ink)),
                ],
              ),
              const SizedBox(height: BeSpacing.xxs),
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(Icons.timer,
                          state.totalTimeFormatted, "Tempo total", BeColors.ink)),
                  const SizedBox(width: BeSpacing.xxs),
                  Expanded(
                      child: _buildStatCard(Icons.local_fire_department,
                          "${state.totalCalories}", "kcal totais", BeColors.semanticWarning)),
                ],
              ),

              const SizedBox(height: BeSpacing.sm),

              // ------ Trilhas / progresso ------
              const BeSectionLabel("Trilhas & Recordes"),
              const SizedBox(height: BeSpacing.xxs),
              _buildTrilhasResumo(selectedSkills),

              const SizedBox(height: BeSpacing.xs),

              // ------ Recordes pessoais ------
              if (state.totalPRs > 0) ...[
                const BeSectionLabel("Recordes Pessoais (PRs)"),
                const SizedBox(height: BeSpacing.xxs),
                ...state.userRecords.entries.map((entry) {
                  final skill = state.availableSkills
                      .where((s) => s.id == entry.key)
                      .firstOrNull;
                  return _buildPRCard(skill?.name ?? entry.key, entry.value);
                }),
                const SizedBox(height: BeSpacing.xs),
              ],

              // ------ Botão histórico ------
              SizedBox(
                width: double.infinity,
                child: BeOutlineButton(
                  label: "Ver Histórico de Corridas",
                  icon: Icons.history,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RunHistoryScreen()),
                  ),
                ),
              ),
              const SizedBox(height: BeSpacing.xxs),

              // ------ Logout ------
              SizedBox(
                width: double.infinity,
                child: BeOutlineButton(
                  label: "Sair da Conta",
                  icon: Icons.logout,
                  onPressed: _showLogoutDialog,
                ),
              ),
              const SizedBox(height: BeSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    final state = AppState.instance;
    final int level = state.athleteLevel;
    final int xp = state.currentXP;
    final int next = state.nextLevelXP;
    final double progress = state.levelProgress;

    return BeCard(
      padding: const EdgeInsets.all(BeSpacing.xs),
      borderColor: BeColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ATLETA ROUGH NÍVEL $level",
                  style: BeFonts.titleMd.copyWith(fontSize: 16)),
              BeBadgePill(
                label: "XPs: $xp / $next",
                background: BeColors.primary.withValues(alpha: 0.12),
                foreground: BeColors.primary,
              ),
            ],
          ),
          const SizedBox(height: BeSpacing.xxs),
          ClipRRect(
            borderRadius: BorderRadius.circular(BeSpacing.xxxs),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: BeColors.canvas,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(BeColors.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Faltam ${next - xp} XP para o nível ${level + 1}.",
            style: BeFonts.caption.copyWith(color: BeColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, String unit) {
    return BeCard(
      padding: const EdgeInsets.all(BeSpacing.xxs),
      borderColor: BeColors.hairline,
      child: Column(
        children: [
          Text(label,
              style: BeFonts.captionUppercase.copyWith(
                  color: BeColors.body, fontSize: 9, letterSpacing: 1.1)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: BeFonts.titleMd.copyWith(fontSize: 18)),
              const SizedBox(width: 2),
              Text(unit,
                  style: BeFonts.caption.copyWith(color: BeColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(BeSpacing.xs),
      decoration: BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border.all(color: BeColors.hairline, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: BeFonts.titleMd.copyWith(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: BeFonts.captionUppercase.copyWith(
                  color: BeColors.body, fontSize: 9, letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildLudicBMICard() {
    final double currentBmi = _bmi;
    if (currentBmi == 0) return const SizedBox();

    String title;
    String subtitle;
    Color color;
    IconData icon;

    if (currentBmi < 18.5) {
      title = "NINJA ÁGIL";
      subtitle = "Leve, rápido e mestre da gravidade. Foco na hipertrofia.";
      color = BeColors.semanticInfo;
      icon = Icons.air;
    } else if (currentBmi < 25) {
      title = "MÁQUINA ESTÉTICA";
      subtitle = "Equilíbrio perfeito de força e controle. Seu corpo é uma arma.";
      color = BeColors.semanticSuccess;
      icon = Icons.bolt;
    } else if (currentBmi < 30) {
      title = "TANQUE DE GUERRA";
      subtitle = "Força bruta pura. Cargas altas não são problema.";
      color = BeColors.semanticWarning;
      icon = Icons.shield;
    } else {
      title = "JUGGERNAUT ROUGH";
      subtitle = "Poder inabalável. Construa resistência e transforme-se.";
      color = BeColors.primary;
      icon = Icons.local_fire_department;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BeSpacing.xs),
      decoration: BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color, width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: BeSpacing.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(title,
                          style:
                              BeFonts.titleMd.copyWith(color: color, fontSize: 14)),
                    ),
                    BeBadgePill(
                      label: "IMC: ${currentBmi.toStringAsFixed(1)}",
                      background: color.withValues(alpha: 0.12),
                      foreground: color,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: BeFonts.bodySm.copyWith(color: BeColors.body)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrilhasResumo(List<CalisthenicsSkill> selected) {
    if (selected.isEmpty) {
      return BeCard(
        borderColor: BeColors.hairline,
        child: Text(
          "Nenhuma habilidade ativa. Toque no ícone de editar para escolher suas trilhas.",
            style: BeFonts.bodySm.copyWith(color: BeColors.body)),
      );
    }

    final state = AppState.instance;
    return Column(
      children: selected.map((skill) {
        final int completed = state.completedStages[skill.id] ?? 0;
        final String? pr = state.userRecords[skill.id];
        return Container(
          margin: const EdgeInsets.only(bottom: BeSpacing.xxs),
          padding: const EdgeInsets.all(BeSpacing.xxs),
          decoration: BoxDecoration(
            color: BeColors.canvasElevated,
            border: Border.all(color: BeColors.hairline, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BeColors.canvas,
                  border: Border.all(color: BeColors.hairline, width: 1),
                ),
                child: const Icon(Icons.fitness_center,
                    color: BeColors.primary, size: 18),
              ),
              const SizedBox(width: BeSpacing.xxs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(skill.name,
                        style: BeFonts.titleSm.copyWith(fontSize: 14)),
                    Text(
                      "Etapas: $completed/3 · ${skill.difficulty}",
                      style: BeFonts.caption.copyWith(color: BeColors.muted),
                    ),
                  ],
                ),
              ),
              if (pr != null)
                BeBadgePill(
                  label: "PR: $pr",
                  background: BeColors.primary.withValues(alpha: 0.12),
                  foreground: BeColors.primary,
                )
              else
                BeBadgePill(
                  label: "Sem PR",
                  background: BeColors.canvasElevated,
                  foreground: BeColors.muted,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPRCard(String skillName, String record) {
    return Container(
      margin: const EdgeInsets.only(bottom: BeSpacing.xxs),
      padding: const EdgeInsets.all(BeSpacing.xs),
      decoration: BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border.all(color: BeColors.primary, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: BeColors.primary, size: 24),
          const SizedBox(width: BeSpacing.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skillName,
                    style: BeFonts.captionUppercase.copyWith(
                        color: BeColors.body, fontSize: 10, letterSpacing: 1.1)),
                Text(record,
                    style: BeFonts.titleMd.copyWith(fontSize: 16)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: BeColors.semanticSuccess, size: 20),
        ],
      ),
    );
  }
}

/// Extensão utilitária para fallback seguro de nickname vazio.
extension _StringX on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}