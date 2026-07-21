import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'run_summary_screen.dart'; // Importação essencial para redirecionar no final

class RunningScreen extends StatefulWidget {
  const RunningScreen({Key? key}) : super(key: key);

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  // Métricas do atleta em tempo real
  double _distanceInMeters = 0.0;
  int _calories = 0;
  String _currentPace = "-'--\"";
  
  // Lista de pontos geográficos (latitude e longitude) para desenhar o rastro do trajeto
  final List<Position> _routeCoordinates = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  // Estado da permissão e sinal de GPS
  String _gpsStatus = "Buscando sinal...";
  Color _gpsSignalColor = Colors.orange;
  bool _isSimulatorMode = false; // Permite simular passos no emulador estático

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Testar se os serviços de localização estão ativos no aparelho
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _gpsStatus = "GPS Desativado";
        _gpsSignalColor = Colors.redAccent;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _gpsStatus = "Permissão Negada";
          _gpsSignalColor = Colors.redAccent;
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _gpsStatus = "Permissão Bloqueada";
        _gpsSignalColor = Colors.redAccent;
      });
      return;
    }

    // GPS pronto para uso
    setState(() {
      _gpsStatus = "GPS Pronto";
      _gpsSignalColor = Colors.greenAccent;
    });
  }

  void _startWorkout() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _gpsStatus = _isSimulatorMode ? "Modo Simulador" : "Sinal Conectado";
      _gpsSignalColor = Colors.greenAccent;
    });

    // Inicia cronômetro de 1 em 1 segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _calculateCalories();
        _calculatePace();
        
        // Se o modo simulador estiver ativo, criamos pontos artificiais para desenhar o mapa
        if (_isSimulatorMode) {
          _simulateMovement();
        }
      });
    });

    // Inicia escuta das coordenadas GPS reais (apenas se não estiver em simulador)
    if (!_isSimulatorMode) {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Atualiza a cada 3 metros percorridos
      );

      _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position position) {
        if (_isRunning) {
          _addCoordinate(position);
        }
      }, onError: (error) {
        debugPrint("Erro na captura de sinal de GPS: $error");
      });
    }
  }

  void _addCoordinate(Position newPosition) {
    if (_routeCoordinates.isNotEmpty) {
      // Calcula a distância métrica entre o último ponto registrado e o novo recebido
      final Position lastPosition = _routeCoordinates.last;
      final double distanceBetween = Geolocator.distanceBetween(
        lastPosition.latitude,
        lastPosition.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );

      // Filtra ruídos normais de GPS parado (pequenas flutuações de sinal)
      if (distanceBetween > 1.5) {
        setState(() {
          _distanceInMeters += distanceBetween;
          _routeCoordinates.add(newPosition);
        });
      }
    } else {
      setState(() {
        _routeCoordinates.add(newPosition);
      });
    }
  }

  void _simulateMovement() {
    // Simula uma trajetória fazendo curvas para testar o desenho vetorial no Canvas
    final double baseLat = -22.9068; 
    final double baseLong = -43.1729;
    final double radiusOffset = 0.0001; 
    
    final double angle = _seconds * 0.15;
    final double newLat = baseLat + (sin(angle) * radiusOffset * (_seconds * 0.05));
    final double newLong = baseLong + (cos(angle) * radiusOffset * (_seconds * 0.05));

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

    _addCoordinate(fakePosition);
  }

  void _calculatePace() {
    if (_distanceInMeters == 0) return;
    
    // Calcula ritmo (minutos por quilômetro)
    final double distanceInKm = _distanceInMeters / 1000;
    final double minutesDecimal = (_seconds / 60) / distanceInKm;
    
    final int minutes = minutesDecimal.toInt();
    final int seconds = ((minutesDecimal - minutes) * 60).toInt();

    if (minutes < 60) {
      setState(() {
        _currentPace = "${minutes.toString().padLeft(2, '0')}'${seconds.toString().padLeft(2, '0')}\"";
      });
    }
  }

  void _calculateCalories() {
    // Estimativa metabólica para corrida baseada no peso médio de 75kg
    setState(() {
      _calories = (_distanceInMeters * 0.075).toInt();
    });
  }

  void _pauseWorkout() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    setState(() {
      _isPaused = true;
      _isRunning = false;
      _gpsStatus = "Treino Pausado";
      _gpsSignalColor = Colors.orange;
    });
  }

  void _stopWorkout() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Finalizar Corrida?", style: TextStyle(color: Colors.white, fontFamily: 'Oswald')),
        content: const Text(
          "Deseja fechar o treino e prosseguir para analisar suas parciais e gerar seu percurso néon?",
          style: TextStyle(color: Colors.grey, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha dialog
              Navigator.pop(context); // Cancela o treino e volta
            },
            child: const Text("DESCARTAR", style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fecha dialog
              
              // REDIRECIONA DEFINITIVAMENTE PARA A TELA DE RESUMO
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
              backgroundColor: const Color(0xFF9C27B0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text("VER MEU RESUMO"),
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
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("TRACKER DE CORRIDA", style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          // Interruptor inteligente para simulação no emulador
          Row(
            children: [
              const Icon(Icons.smart_toy_outlined, color: Colors.white54, size: 16),
              Switch(
                value: _isSimulatorMode,
                activeColor: const Color(0xFF9C27B0),
                onChanged: _isRunning ? null : (value) {
                  setState(() {
                    _isSimulatorMode = value;
                    _gpsStatus = value ? "Modo Simulador" : "Buscando sinal...";
                    _gpsSignalColor = value ? Colors.purpleAccent : Colors.orange;
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gps_fixed, color: _gpsSignalColor, size: 18),
                        const SizedBox(width: 8),
                        Text(_gpsStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    if (_isSimulatorMode)
                      const Text(
                        "Teste Ativo",
                        style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),

            // Painel visual do trajeto percorrido (Custom Canvas)
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Desenha o trajeto capturado se houver pontos
                      if (_routeCoordinates.isNotEmpty)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: RoutePainter(coordinates: _routeCoordinates),
                          ),
                        )
                      else
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_run, color: Color(0xFF9C27B0), size: 48),
                              SizedBox(height: 12),
                              Text(
                                "Seu trajeto aparecerá aqui",
                                style: TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "(Dica: Ative o Simulador no topo)",
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Cronômetro principal
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(_seconds),
                    style: const TextStyle(
                      fontSize: 76,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Oswald',
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const Text("DURAÇÃO", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2)),
                  
                  const SizedBox(height: 24),
                  
                  // Métricas
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetric("DISTÂNCIA", (_distanceInMeters / 1000).toStringAsFixed(2), "km"),
                        Container(width: 1, height: 40, color: const Color(0xFF333333)),
                        _buildMetric("RITMO", _currentPace, "/km"),
                        Container(width: 1, height: 40, color: const Color(0xFF333333)),
                        _buildMetric("CALORIAS", "$_calories", "kcal"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botões de controle de atividade
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_isRunning || _isPaused)
                    _buildSecondaryButton(
                      icon: Icons.stop_rounded, 
                      color: Colors.redAccent, 
                      onPressed: _stopWorkout
                    ),
                  
                  GestureDetector(
                    onTap: _isRunning ? _pauseWorkout : _startWorkout,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isRunning ? const Color(0xFF1A1A24) : const Color(0xFF9C27B0),
                        shape: BoxShape.circle,
                        border: _isRunning ? Border.all(color: const Color(0xFF9C27B0), width: 3) : null,
                        boxShadow: _isRunning ? [] : [
                          BoxShadow(
                            color: const Color(0xFF9C27B0).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
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

  Widget _buildMetric(String label, String value, String unit) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Oswald', color: Colors.white),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildSecondaryButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}

// Pintor vetorial dinâmico para desenhar a linha do trajeto da corrida
class RoutePainter extends CustomPainter {
  final List<Position> coordinates;

  RoutePainter({required this.coordinates});

  @override
  void paint(Canvas canvas, Size size) {
    if (coordinates.length < 2) return;

    // Achar os extremos (bounding box) da rota capturada para poder enquadrar no tamanho da caixa
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

    // Calcula margem para o mapa não bater colado nas bordas da tela
    final double padding = 20.0;
    final double widthFactor = size.width - (padding * 2);
    final double heightFactor = size.height - (padding * 2);

    final double latRange = maxLat - minLat == 0 ? 1 : maxLat - minLat;
    final double longRange = maxLong - minLong == 0 ? 1 : maxLong - minLong;

    // Configurando pincel de desenho da linha (Rastro Roxo Néon)
    final Paint linePaint = Paint()
      ..color = const Color(0xFF9C27B0)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();

    // Converte coordenadas decimais em pontos gráficos da tela (pixels proporcionais)
    Offset getOffset(Position pos) {
      // Regra de proporção simples
      final double x = padding + ((pos.longitude - minLong) / longRange) * widthFactor;
      // Inverta o y porque no canvas gráfico o y cresce para baixo, e a latitude cresce para cima
      final double y = padding + (1.0 - ((pos.latitude - minLat) / latRange)) * heightFactor;
      return Offset(x, y);
    }

    // Desenhando o trajeto do início ao fim
    path.moveTo(getOffset(coordinates.first).dx, getOffset(coordinates.first).dy);
    for (int i = 1; i < coordinates.length; i++) {
      final offset = getOffset(coordinates[i]);
      path.lineTo(offset.dx, offset.dy);
    }

    canvas.drawPath(path, linePaint);

    // Pintar um ponto verde no início e um círculo de pulsação na ponta atual do atleta
    final Paint pointPaint = Paint()..style = PaintingStyle.fill;
    
    // Início (Verde)
    pointPaint.color = Colors.greenAccent;
    canvas.drawCircle(getOffset(coordinates.first), 6.0, pointPaint);

    // Ponta final / Posição atual (Roxo Brilhante)
    pointPaint.color = Colors.white;
    canvas.drawCircle(getOffset(coordinates.last), 7.0, pointPaint);
    pointPaint.color = const Color(0xFF9C27B0).withOpacity(0.5);
    canvas.drawCircle(getOffset(coordinates.last), 12.0, pointPaint);
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) {
    return oldDelegate.coordinates.length != coordinates.length;
  }
}