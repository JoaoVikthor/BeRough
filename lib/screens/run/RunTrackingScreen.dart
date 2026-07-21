import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
// Corrigido: Apontando para o app_state na raiz da pasta lib
import '../../app_state.dart';

class RunTrackingScreen extends StatefulWidget {
  const RunTrackingScreen({Key? key}) : super(key: key);

  @override
  State<RunTrackingScreen> createState() => _RunTrackingScreenState();
}

class _RunTrackingScreenState extends State<RunTrackingScreen> {
  bool _isTracking = false;
  bool _hasPermissions = false;
  
  // Métricas
  double _distanceInMeters = 0.0;
  int _secondsElapsed = 0;
  List<Position> _route = [];

  StreamSubscription<Position>? _positionStream;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      // Verifica se o GPS do celular está ligado
      bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      setState(() {
        _hasPermissions = isLocationServiceEnabled;
      });
      if (!isLocationServiceEnabled) {
        _showError("Por favor, ative o GPS (Localização) do seu aparelho.");
      }
    } else {
      _showError("Permissão de localização negada. O rastreio não funcionará.");
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  void _toggleTracking() {
    if (!_hasPermissions) {
      _checkPermissions();
      return;
    }

    setState(() {
      _isTracking = !_isTracking;
    });

    if (_isTracking) {
      _startTracking();
    } else {
      _pauseTracking();
    }
  }

  void _startTracking() {
    // Inicia o cronômetro
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });

    // Inicia o stream de GPS de alta precisão
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2, // Atualiza a cada 2 metros movidos
      ),
    ).listen((Position position) {
      if (_route.isNotEmpty) {
        // Calcula a distância real entre o último ponto e o atual
        double distance = Geolocator.distanceBetween(
          _route.last.latitude, _route.last.longitude,
          position.latitude, position.longitude,
        );
        setState(() {
          _distanceInMeters += distance;
        });
      }
      _route.add(position);
    });
  }

  void _pauseTracking() {
    _timer?.cancel();
    _positionStream?.cancel();
  }

  void _finishRun() {
    _pauseTracking();
    
    if (_distanceInMeters < 50) {
      _showError("Distância muito curta para ser registrada.");
      return;
    }

    // Calcula o Pace médio (Minutos por KM)
    double km = _distanceInMeters / 1000;
    double minutes = _secondsElapsed / 60;
    double paceDecimal = minutes / km;
    
    int paceMin = paceDecimal.floor();
    int paceSec = ((paceDecimal - paceMin) * 60).round();
    String paceString = "$paceMin:${paceSec.toString().padLeft(2, '0')}/km";

    // Calcula Calorias (Estimativa grosseira: peso * km)
    double peso = 75.0; // Idealmente pegar do AppState
    try { peso = (AppState.instance as dynamic).weight ?? 75.0; } catch(_) {}
    int calorias = (peso * km).round();

    // Salva no Histórico Global
    RunLog newLog = RunLog(
      distanceInMeters: _distanceInMeters,
      seconds: _secondsElapsed,
      pace: paceString,
      calories: calorias,
      date: DateTime.now(),
      route: _route,
    );
    
    AppState.instance.runHistory.insert(0, newLog);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Corrida salva com sucesso!"), backgroundColor: Colors.green),
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Formatação de Textos Visuais
    String minutesStr = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    String secondsStr = (_secondsElapsed % 60).toString().padLeft(2, '0');
    
    double km = _distanceInMeters / 1000;
    
    // Pace atual seguro contra divisão por zero
    String currentPace = "0:00";
    if (km > 0.01) {
       double m = (_secondsElapsed / 60) / km;
       int pMin = m.floor();
       int pSec = ((m - pMin) * 60).round();
       currentPace = "$pMin:${pSec.toString().padLeft(2, '0')}";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("RASTREAMENTO GPS", style: TextStyle(fontFamily: 'Oswald', letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      km.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold, fontFamily: 'Oswald'),
                    ),
                    const Text("QUILÔMETROS", style: TextStyle(color: Colors.grey, fontSize: 14, letterSpacing: 2)),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetricData("TEMPO", "$minutesStr:$secondsStr"),
                        Container(width: 1, height: 40, color: const Color(0xFF333333)),
                        _buildMetricData("PACE (MIN/KM)", currentPace),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A24),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_secondsElapsed > 0 && !_isTracking)
                    FloatingActionButton(
                      heroTag: "btn_stop",
                      backgroundColor: Colors.redAccent,
                      onPressed: _finishRun,
                      child: const Icon(Icons.stop, size: 30, color: Colors.white),
                    ),
                  
                  GestureDetector(
                    onTap: _toggleTracking,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isTracking ? Colors.amber : const Color(0xFF9C27B0),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isTracking ? Colors.amber : const Color(0xFF9C27B0)).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Icon(
                        _isTracking ? Icons.pause : Icons.play_arrow,
                        size: 40,
                        color: Colors.white,
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

  Widget _buildMetricData(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Oswald')),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}