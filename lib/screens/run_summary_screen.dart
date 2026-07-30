import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../app_state.dart';
import '../design/tokens.dart';
import '../design/ui.dart';
import 'home_screen.dart';
import 'trail/step_complete_screen.dart';

class RunSummaryScreen extends StatelessWidget {
  final double distanceInMeters;
  final int seconds;
  final String pace;
  final int calories;
  final List<Position> routeCoordinates;

  /// true quando esta corrida foi uma avaliação — ao salvar, vira o baseline
  /// usado para dimensionar a trilha de corrida.
  final bool isAssessment;

  /// true quando esta corrida é um PASSO de uma trilha de corrida. Ao
  /// salvar, o resumo marca o passo como concluído e abre a tela de
  /// parabéns correspondente.
  final bool isTrailStep;

  /// Id da skill de corrida cuja trilha está sendo executada (quando
  /// `isTrailStep` for true).
  final String? trailSkillId;

  /// true se este passo é o último da trilha (meta final).
  final bool isFinalStep;

  const RunSummaryScreen({
    super.key,
    required this.distanceInMeters,
    required this.seconds,
    required this.pace,
    required this.calories,
    required this.routeCoordinates,
    this.isAssessment = false,
    this.isTrailStep = false,
    this.trailSkillId,
    this.isFinalStep = false,
  });

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int remainingSeconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _saveAndExit(BuildContext context) async {
    await AppState.instance.addRunToHistory(RunLog(
      distanceInMeters: distanceInMeters,
      seconds: seconds,
      pace: pace,
      calories: calories,
      date: DateTime.now(),
      route: routeCoordinates,
    ));

    // Se foi avaliação, grava como baseline da trilha de corrida.
    if (isAssessment) {
      AppState.instance.setRunBaselineAssessment(
        distanceMeters: distanceInMeters,
        seconds: seconds.toDouble(),
        pace: pace,
        route: routeCoordinates,
      );
      await AppState.instance.saveProfile();
    }

    // Se é um passo de trilha, marca como concluído e abre a tela de
    // parabéns da trilha (em vez de só voltar para a Home).
    TrailStep? step;
    if (isTrailStep && trailSkillId != null) {
      final completed =
          AppState.instance.completedStages[trailSkillId!] ?? 0;
      AppState.instance.completedStages[trailSkillId!] = completed + 1;
      await AppState.instance.saveProfile();
      step = TrailStep(
        id: '${trailSkillId!}_run',
        index: completed,
        goalFraction: 1.0,
        title: isFinalStep ? 'Desafio Final: corrida' : 'Passada de corrida',
        desc: '',
        metricKind: TrailMetricKind.distance,
        targetValue: distanceInMeters,
        estimateFromBaseline: seconds.toDouble(),
      );
    }

    if (!context.mounted) return;

    if (isTrailStep && step != null) {
      final skill = AppState.instance.availableSkills
          .firstWhere((s) => s.id == trailSkillId);
      final completedStep = step;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => StepCompleteScreen(
            skill: skill,
            step: completedStep,
            isFinalStep: isFinalStep,
            achievedLog:
                "Corrida de ${(distanceInMeters / 1000).toStringAsFixed(2)} km em ${_formatTime(seconds)} (pace $pace).",
          ),
        ),
        (Route<dynamic> route) => route.isFirst,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _openShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BeColors.canvasElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BeSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("COMPARTILHAR ATIVIDADE",
                    style: BeFonts.titleMd.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  "Seu card esportivo com o percurso estilizado está pronto para publicação.",
                  textAlign: TextAlign.center,
                  style: BeFonts.bodySm.copyWith(color: BeColors.body),
                ),
                const SizedBox(height: BeSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareOption(
                      icon: Icons.share_rounded,
                      label: "Feed Strava",
                      color: BeColors.semanticWarning,
                      onTap: () {
                        Navigator.pop(context);
                        _showShareSuccess(context, "Publicado no Strava!");
                      },
                    ),
                    _buildShareOption(
                      icon: Icons.camera_alt_rounded,
                      label: "Instagram",
                      color: BeColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _showShareSuccess(context, "Enviado para o Instagram!");
                      },
                    ),
                    _buildShareOption(
                      icon: Icons.message_rounded,
                      label: "WhatsApp",
                      color: BeColors.semanticSuccess,
                      onTap: () {
                        Navigator.pop(context);
                        _showShareSuccess(context, "Link gerado!");
                      },
                    ),
                  ],
                ),
                const SizedBox(height: BeSpacing.xxs),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShareSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: BeFonts.caption.copyWith(color: BeColors.ink)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double distanceInKm = distanceInMeters / 1000;

    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("ATIVIDADE CONCLUÍDA"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: BeSpacing.xs, vertical: 12),
                decoration: BoxDecoration(
                  color: BeColors.canvasElevated,
                  border: Border.all(color: BeColors.primary.withValues(alpha: 0.3), width: 1),
                ),
                child: Stack(
                  children: [
                    if (routeCoordinates.isNotEmpty)
                      Positioned.fill(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              routeCoordinates.first.latitude,
                              routeCoordinates.first.longitude,
                            ),
                            initialZoom: 16.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                              subdomains: const ['a', 'b', 'c', 'd'],
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: routeCoordinates
                                      .map((p) => LatLng(p.latitude, p.longitude))
                                      .toList(),
                                  color: BeColors.primary,
                                  strokeWidth: 5.0,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(routeCoordinates.first.latitude,
                                      routeCoordinates.first.longitude),
                                  width: 18,
                                  height: 18,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: BeColors.semanticSuccess,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Marker(
                                  point: LatLng(routeCoordinates.last.latitude,
                                      routeCoordinates.last.longitude),
                                  width: 18,
                                  height: 18,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: BeColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: BeColors.ink, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.map_outlined,
                            color: BeColors.muted, size: 64),
                      ),
                    Positioned(
                      top: 20,
                      left: 20,
                      child: RichText(
                        text: TextSpan(
                          style: BeFonts.titleMd.copyWith(fontSize: 20),
                          children: const [
                            TextSpan(
                                text: 'Be', style: TextStyle(color: BeColors.ink)),
                            TextSpan(
                                text: 'Rough',
                                style: TextStyle(color: BeColors.primary)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BeColors.canvas.withValues(alpha: 0.85),
                          border: Border.all(color: BeColors.hairline, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatCol("DISTÂNCIA",
                                "${distanceInKm.toStringAsFixed(2)} km"),
                            _buildStatCol("PACE", "$pace /km"),
                            _buildStatCol("TEMPO", _formatTime(seconds)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BeSpacing.xs),
                child: Row(
                  children: [
                    Expanded(child: _buildHeroStat(Icons.local_fire_department, "$calories kcal", "Calorias", BeColors.semanticWarning)),
                    const SizedBox(width: BeSpacing.xxs),
                    Expanded(
                      child: _buildHeroStat(
                        Icons.calendar_today,
                        "${DateTime.now().day}/${DateTime.now().month.toString().padLeft(2, '0')}",
                        "Data Registro",
                        BeColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: BeSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BeSpacing.xs),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: BeOutlineButton(
                      label: "Compartilhar Atividade",
                      icon: Icons.share,
                      onPressed: () => _openShareSheet(context),
                    ),
                  ),
                  const SizedBox(height: BeSpacing.xxs),
                  SizedBox(
                    width: double.infinity,
                    child: BePrimaryButton(
                      label: "Salvar no Histórico",
                      onPressed: () => _saveAndExit(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BeSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: BeFonts.captionUppercase.copyWith(
                color: BeColors.body, fontSize: 8, letterSpacing: 1.1)),
        const SizedBox(height: 2),
        Text(value,
            style: BeFonts.titleMd.copyWith(fontSize: 14)),
      ],
    );
  }

  Widget _buildHeroStat(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(BeSpacing.xs),
      decoration: BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border.all(color: BeColors.hairline, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(value, style: BeFonts.titleMd.copyWith(fontSize: 18)),
          Text(label,
              style: BeFonts.captionUppercase.copyWith(
                  color: BeColors.body, fontSize: 9, letterSpacing: 1.1)),
        ],
      ),
    );
  }
}