import 'package:flutter/material.dart' hide Path;
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../app_state.dart';
import '../design/tokens.dart';
import 'run_summary_screen.dart';

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  final MapController _mapController = MapController();

  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  double _distanceInMeters = 0.0;
  int _calories = 0;
  String _currentPace = "-'--\"";

  // Checa se a localização atual foi obtida (para poder renderizar o mapa no
  // local do atleta imediatamente, estilo apps de corrida profissionais).
  Position? _currentPosition;
  bool _isLocating = true;

  // Rota capturada — usada tanto no mapa (em LatLng) quanto no cronômetro.
  final List<Position> _routeCoordinates = [];
  final List<LatLng> _mapPoints = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  String _gpsStatus = "Buscando sinal...";
  Color _gpsSignalColor = BeColors.semanticWarning;
  bool _isSimulatorMode = false;

  @override
  void initState() {
    super.initState();
    _bootstrapGPS();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Verifica permissão e pega a posição inicial do atleta antes de habilitar o
  /// botão de "play". Em simulador, sintetiza uma posição base em São Paulo.
  Future<void> _bootstrapGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _gpsStatus = "GPS Desativado";
        _gpsSignalColor = BeColors.semanticWarning;
        _isLocating = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _gpsStatus = "Permissão Negada";
          _gpsSignalColor = BeColors.semanticWarning;
          _isLocating = false;
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _gpsStatus = "Permissão Bloqueada";
        _gpsSignalColor = BeColors.semanticWarning;
        _isLocating = false;
      });
      return;
    }

    try {
      final Position first = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = first;
        _isLocating = false;
        _gpsStatus = "GPS Pronto";
        _gpsSignalColor = BeColors.semanticSuccess;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _gpsStatus = "Falha ao obter localização";
        _gpsSignalColor = BeColors.semanticWarning;
      });
    }
  }

  void _startWorkout() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _gpsStatus = _isSimulatorMode ? "Modo Simulador" : "Sinal Conectado";
      _gpsSignalColor = BeColors.semanticSuccess;
      _routeCoordinates.clear();
      _mapPoints.clear();
      _distanceInMeters = 0.0;
      _seconds = 0;

      // Ponto de partida inicial no mapa.
      if (_currentPosition != null) {
        _routeCoordinates.add(_currentPosition!);
        _mapPoints
            .add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _calculateCalories();
        _calculatePace();
        if (_isSimulatorMode) _simulateMovement();
      });
    });

    if (!_isSimulatorMode && _currentPosition != null) {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      );
      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position position) {
        if (_isRunning) _addCoordinate(position);
      }, onError: (error) {
        debugPrint("Erro na captura de sinal de GPS: $error");
      });
    }
  }

  void _addCoordinate(Position newPosition) {
    if (_routeCoordinates.isNotEmpty) {
      final Position lastPosition = _routeCoordinates.last;
      final double distanceBetween = Geolocator.distanceBetween(
        lastPosition.latitude,
        lastPosition.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
      if (distanceBetween > 1.5) {
        setState(() {
          _distanceInMeters += distanceBetween;
          _routeCoordinates.add(newPosition);
          _mapPoints.add(LatLng(newPosition.latitude, newPosition.longitude));
          _currentPosition = newPosition;
          _mapController.move(
              LatLng(newPosition.latitude, newPosition.longitude), 17.0);
        });
      }
    } else {
      setState(() {
        _routeCoordinates.add(newPosition);
        _mapPoints.add(LatLng(newPosition.latitude, newPosition.longitude));
        _currentPosition = newPosition;
      });
    }
  }

  /// Simula uma caminhada/corrida em redor de um ponto para testes no emulador.
  void _simulateMovement() {
    final double baseLat = -23.5489; // São Paulo
    final double baseLong = -46.6388;
    final double radiusOffset = 0.0002;
    final double angle = _seconds * 0.15;
    final double newLat =
        baseLat + (sin(angle) * radiusOffset * (_seconds * 0.05));
    final double newLong =
        baseLong + (cos(angle) * radiusOffset * (_seconds * 0.05));
    final fakePosition = Position(
      latitude: newLat,
      longitude: newLong,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 2.8,
      speedAccuracy: 0.0,
    );

    if (fakePosition == _routeCoordinates.lastOrNull) return;
    if (_mapPoints.isEmpty ||
        Geolocator.distanceBetween(
              _routeCoordinates.last.latitude,
              _routeCoordinates.last.longitude,
              fakePosition.latitude,
              fakePosition.longitude,
            ) >
            1.5) {
      _addCoordinate(fakePosition);
    }
  }

  void _calculatePace() {
    if (_distanceInMeters == 0) return;
    final double distanceInKm = _distanceInMeters / 1000;
    final double minutesDecimal = (_seconds / 60) / distanceInKm;
    final int minutes = minutesDecimal.toInt();
    final int seconds = ((minutesDecimal - minutes) * 60).toInt();
    if (minutes < 60) {
      setState(() {
        _currentPace =
            "${minutes.toString().padLeft(2, '0')}'${seconds.toString().padLeft(2, '0')}\"";
      });
    }
  }

  void _calculateCalories() {
    final double userWeight = AppState.instance.weight;
    setState(() {
      _calories = (_distanceInMeters / 1000 * userWeight * 0.9).toInt();
    });
  }

  void _pauseWorkout() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    setState(() {
      _isPaused = true;
      _isRunning = false;
      _gpsStatus = "Treino Pausado";
      _gpsSignalColor = BeColors.semanticWarning;
    });
  }

  void _stopWorkout() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BeColors.canvasElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text("Finalizar Corrida?", style: BeFonts.titleMd.copyWith(fontSize: 18)),
        content: Text(
          "Deseja fechar o treino e prosseguir para analisar suas parciais e gerar seu resumo?",
          style: BeFonts.bodyMd.copyWith(color: BeColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("DESCARTAR",
                style: BeFonts.button.copyWith(color: BeColors.semanticWarning)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RunSummaryScreen(
                    distanceInMeters: _distanceInMeters,
                    seconds: _seconds,
                    pace: _currentPace,
                    calories: _calories,
                    routeCoordinates: List.from(_routeCoordinates),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: BeColors.primary, elevation: 0),
            child: Text("VER MEU RESUMO", style: BeFonts.button),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: AppBar(
        backgroundColor: BeColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: BeColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("TRACKER DE CORRIDA"),
        actions: [
          Row(
            children: [
              Icon(Icons.smart_toy_outlined, color: BeColors.muted, size: 16),
              Switch(
                value: _isSimulatorMode,
                activeThumbColor: BeColors.primary,
                inactiveThumbColor: BeColors.muted,
                inactiveTrackColor: BeColors.canvasElevated,
                onChanged: _isRunning
                    ? null
                    : (value) {
                        setState(() {
                          _isSimulatorMode = value;
                          if (value) {
                            // Sintetiza ponto de partida para liberar o mapa no simulador.
                            _currentPosition = Position(
                              latitude: -23.5489,
                              longitude: -46.6388,
                              timestamp: DateTime.now(),
                              accuracy: 1.0,
                              altitude: 0.0,
                              altitudeAccuracy: 0.0,
                              heading: 0.0,
                              headingAccuracy: 0.0,
                              speed: 0.0,
                              speedAccuracy: 0.0,
                            );
                            _isLocating = false;
                            _gpsStatus = "Modo Simulador";
                            _gpsSignalColor = BeColors.primary;
                          } else {
                            _gpsStatus = "Buscando sinal...";
                            _gpsSignalColor = BeColors.semanticWarning;
                            _bootstrapGPS();
                          }
                        });
                      },
              ),
            ],
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status do sinal de GPS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BeSpacing.xs, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: BeColors.canvasElevated,
                  border: Border.all(color: BeColors.hairline, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gps_fixed, color: _gpsSignalColor, size: 18),
                        const SizedBox(width: 8),
                        Text(_gpsStatus,
                            style: BeFonts.bodyMd.copyWith(color: BeColors.ink)),
                      ],
                    ),
                    if (_isSimulatorMode)
                      Text("Teste Ativo",
                          style: BeFonts.captionUppercase.copyWith(
                              color: BeColors.primary,
                              fontSize: 10,
                              letterSpacing: 1.1)),
                  ],
                ),
              ),
            ),

            // MAPA (flutter_map) ocupando a maior parte da tela
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: BeSpacing.xs),
                decoration: BoxDecoration(
                  color: BeColors.canvasElevated,
                  border: Border.all(color: BeColors.hairline, width: 1),
                ),
                child: _buildMapArea(),
              ),
            ),

            // Cronômetro + métricas compactas
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(_seconds),
                    style: BeFonts.numberDisplay
                        .copyWith(fontSize: 60, letterSpacing: -1.2),
                  ),
                  Text("DURAÇÃO",
                      style: BeFonts.captionUppercase.copyWith(
                          color: BeColors.body, fontSize: 10, letterSpacing: 1.6)),
                  const SizedBox(height: BeSpacing.xxs),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: BeSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetric("DISTÂNCIA",
                            (_distanceInMeters / 1000).toStringAsFixed(2), "km"),
                        Container(width: 1, height: 32, color: BeColors.hairline),
                        _buildMetric("RITMO", _currentPace, "/km"),
                        Container(width: 1, height: 32, color: BeColors.hairline),
                        _buildMetric("CALORIAS", "$_calories", "kcal"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botões de controle
            Padding(
              padding: const EdgeInsets.only(
                  bottom: BeSpacing.sm, left: BeSpacing.xs, right: BeSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_isRunning || _isPaused)
                    _buildSecondaryButton(
                        icon: Icons.stop_rounded,
                        color: BeColors.semanticWarning,
                        onPressed: _stopWorkout),
                  GestureDetector(
                    onTap: _isRunning ? _pauseWorkout : _startWorkout,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _isRunning ? BeColors.canvasElevated : BeColors.primary,
                        shape: BoxShape.circle,
                        border: _isRunning
                            ? Border.all(color: BeColors.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: BeColors.onPrimary,
                        size: 36,
                      ),
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

  /// Área do mapa: exibe flutter_map centrado na posição do atleta com a rota
  /// em vermelho (Rosso Corsa) sendo desenhada em tempo real. Quando o GPS não
  /// está disponível, mostra o placeholder do Custom Canvas (RoutePainter) como
  /// fallback editorial — para visualizar o trajeto mesmo sem mapa.
  Widget _buildMapArea() {
    if (_isLocating || _currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
                color: BeColors.primary, strokeWidth: 2),
            const SizedBox(height: BeSpacing.xxs),
            Text("Buscando sinal de GPS...",
                style: BeFonts.bodyMd.copyWith(color: BeColors.body)),
          ],
        ),
      );
    }

    final LatLng center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 17.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        // Linha do percurso em tempo real (Rosso Corsa)
        if (_mapPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _mapPoints,
                color: BeColors.primary,
                strokeWidth: 5.0,
              ),
            ],
          ),
        // Marcador da posição atual do atleta
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 22,
              height: 22,
              child: Container(
                decoration: BoxDecoration(
                  color: BeColors.primary.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: BeColors.primary, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: BeColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, String unit) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: BeFonts.titleMd.copyWith(fontSize: 22)),
            const SizedBox(width: 2),
            Text(unit,
                style: BeFonts.caption.copyWith(color: BeColors.muted)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label,
            style: BeFonts.captionUppercase.copyWith(
                color: BeColors.body, fontSize: 9, letterSpacing: 1.1)),
      ],
    );
  }

  Widget _buildSecondaryButton(
      {required IconData icon, required Color color, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: BeColors.canvasElevated,
          shape: BoxShape.circle,
          border: Border.all(color: BeColors.hairline, width: 1),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}

/// Pintor vetorial mantido apenas para o histórico (mini-mapa) e resumo —
/// exibe a rota a partir de coordenadas salvas quando não há mapa real.
class RoutePainter extends CustomPainter {
  final List<Position> coordinates;

  RoutePainter({required this.coordinates});

  @override
  void paint(Canvas canvas, Size size) {
    if (coordinates.length < 2) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLong = double.infinity;
    double maxLong = -double.infinity;

    for (var pos in coordinates) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLong) minLong = pos.longitude;
      if (pos.longitude > maxLong) maxLong = pos.longitude;
    }

    final double padding = 20.0;
    final double widthFactor = size.width - (padding * 2);
    final double heightFactor = size.height - (padding * 2);
    final double latRange = maxLat - minLat == 0 ? 1 : maxLat - minLat;
    final double longRange = maxLong - minLong == 0 ? 1 : maxLong - minLong;

    final Paint linePaint = Paint()
      ..color = BeColors.primary
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final ui.Path path = ui.Path();

    Offset getOffset(Position pos) {
      final double x =
          padding + ((pos.longitude - minLong) / longRange) * widthFactor;
      final double y =
          padding + (1.0 - ((pos.latitude - minLat) / latRange)) * heightFactor;
      return Offset(x, y);
    }

    path.moveTo(getOffset(coordinates.first).dx, getOffset(coordinates.first).dy);
    for (int i = 1; i < coordinates.length; i++) {
      final offset = getOffset(coordinates[i]);
      path.lineTo(offset.dx, offset.dy);
    }

    canvas.drawPath(path, linePaint);

    final Paint pointPaint = Paint()..style = PaintingStyle.fill;
    pointPaint.color = BeColors.semanticSuccess;
    canvas.drawCircle(getOffset(coordinates.first), 6.0, pointPaint);
    pointPaint.color = BeColors.ink;
    canvas.drawCircle(getOffset(coordinates.last), 7.0, pointPaint);
    pointPaint.color = BeColors.primary.withOpacity(0.5);
    canvas.drawCircle(getOffset(coordinates.last), 12.0, pointPaint);
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) {
    return oldDelegate.coordinates.length != coordinates.length;
  }
}