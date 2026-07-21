import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../app_state.dart';
import 'running_screen.dart'; // Importação do RoutePainter
import 'home_screen.dart';

class RunSummaryScreen extends StatelessWidget {
  final double distanceInMeters;
  final int seconds;
  final String pace;
  final int calories;
  final List<Position> routeCoordinates;

  const RunSummaryScreen({
    Key? key,
    required this.distanceInMeters,
    required this.seconds,
    required this.pace,
    required this.calories,
    required this.routeCoordinates,
  }) : super(key: key);

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int remainingSeconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _saveAndExit(BuildContext context) {
    AppState.instance.runHistory.add(RunLog(
      distanceInMeters: distanceInMeters,
      seconds: seconds,
      pace: pace,
      calories: calories,
      date: DateTime.now(),
      route: routeCoordinates,
    ));

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _openShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "COMPARTILHAR NO STRAVA & REDES",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Oswald',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Seu card esportivo com o percurso do mapa estilizado em néon está pronto para publicação.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareOption(
                      icon: Icons.share_rounded,
                      label: "Feed Strava",
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _showShareSuccess(context, "Publicado no Strava!");
                      },
                    ),
                    _buildShareOption(
                      icon: Icons.camera_alt_rounded,
                      label: "Instagram Stories",
                      color: const Color(0xFFE1306C),
                      onTap: () {
                        Navigator.pop(context);
                        _showShareSuccess(context, "Enviado para o Instagram!");
                      },
                    ),
                    _buildShareOption(
                      icon: Icons.message_rounded,
                      label: "WhatsApp",
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _showShareSuccess(context, "Link de percurso gerado!");
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShareSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A24),
        duration: const Duration(seconds: 2),
      ),
    );
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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double distanceInKm = distanceInMeters / 1000;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "ATIVIDADE CONCLUÍDA",
          style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      if (routeCoordinates.isNotEmpty)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: RoutePainter(coordinates: routeCoordinates),
                          ),
                        )
                      else
                        const Center(
                          child: Icon(Icons.map_outlined, color: Colors.white24, size: 64),
                        ),
                      Positioned(
                        top: 20,
                        left: 20,
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Oswald', letterSpacing: 0.5),
                            children: [
                              TextSpan(text: 'Be', style: TextStyle(color: Colors.white)),
                              TextSpan(text: 'Rough', style: TextStyle(color: Color(0xFF9C27B0))),
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
                            color: const Color(0xFF0D0D12).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("DISTÂNCIA", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text("${distanceInKm.toStringAsFixed(2)} km", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Oswald')),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("PACE", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text("$pace /km", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Oswald')),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("TEMPO", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(_formatTime(seconds), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Oswald')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A24),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF333333)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 28),
                            const SizedBox(height: 8),
                            Text("$calories kcal", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Oswald')),
                            const Text("CALORIAS", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.0)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A24),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF333333)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF9C27B0), size: 24),
                            const SizedBox(height: 8),
                            Text(
                              "${DateTime.now().day}/${DateTime.now().month.toString().padLeft(2, '0')}",
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Oswald'),
                            ),
                            const Text("DATA REGISTRO", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.0)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openShareSheet(context),
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text("COMPARTILHAR ATIVIDADE", style: TextStyle(color: Colors.white, fontFamily: 'Oswald', fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.white30, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _saveAndExit(context),
                      child: const Text("SALVAR NO HISTÓRICO"),
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
}