import 'package:flutter/material.dart';
import '../app_state.dart';
import '../design/tokens.dart';
import '../design/ui.dart';
import 'running_screen.dart';

/// Lista detalhada do histórico de corridas persistido no AppState.
/// Resenha cada corrida com distância, pace, tempo, calorias, data e mini-mapa
/// desenhado em canvas a partir das coordenadas salvas.
class RunHistoryScreen extends StatefulWidget {
  const RunHistoryScreen({super.key});

  @override
  State<RunHistoryScreen> createState() => _RunHistoryScreenState();
}

class _RunHistoryScreenState extends State<RunHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final runs = AppState.instance.runHistory;

    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: AppBar(
        title: Text("HISTÓRICO DE CORRIDAS"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: BeColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: runs.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(BeSpacing.xs),
                itemCount: runs.length,
                separatorBuilder: (_, __) => const SizedBox(height: BeSpacing.xxs),
                itemBuilder: (context, index) => _buildRunCard(runs[index]),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RunningScreen()),
        ).then((_) {
          if (mounted) setState(() {});
        }),
        backgroundColor: BeColors.primary,
        foregroundColor: BeColors.onPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        icon: const Icon(Icons.directions_run),
        label: Text("NOVA CORRIDA", style: BeFonts.button),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BeSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off, size: 64, color: BeColors.muted),
            const SizedBox(height: BeSpacing.xs),
            Text(
              "Você ainda não registrou nenhuma corrida.",
              textAlign: TextAlign.center,
              style: BeFonts.bodyMd.copyWith(color: BeColors.body),
            ),
            const SizedBox(height: 4),
            Text(
              "Toque em NOVA CORRIDA para iniciar seu primeiro treino com GPS.",
              textAlign: TextAlign.center,
              style: BeFonts.caption.copyWith(color: BeColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildRunCard(RunLog run) {
    final double km = run.distanceInMeters / 1000;
    final String day =
        "${run.date.day}/${run.date.month.toString().padLeft(2, '0')}/${run.date.year}";

    return Container(
      decoration: BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border.all(color: BeColors.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: BeColors.canvas,
              child: run.route.isNotEmpty
                  ? CustomPaint(painter: RoutePainter(coordinates: run.route))
                  : Center(
                      child: Icon(Icons.map_outlined,
                          color: BeColors.muted, size: 36)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(BeSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${km.toStringAsFixed(2)} km",
                        style: BeFonts.titleMd.copyWith(fontSize: 20)),
                    BeBadgePill(label: day),
                  ],
                ),
                const SizedBox(height: BeSpacing.xxs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat("PACE", "${run.pace} /km"),
                    _buildStat("TEMPO", _formatTime(run.seconds)),
                    _buildStat("KCAL", "${run.calories}"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: BeFonts.titleMd.copyWith(fontSize: 14)),
        const SizedBox(height: 2),
        Text(label,
            style: BeFonts.captionUppercase.copyWith(
                color: BeColors.body, fontSize: 9, letterSpacing: 1.1)),
      ],
    );
  }
}