import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import './screens/auth/onboarding_screen.dart';
// Corrigido: O app_state está na mesma pasta raiz que o main.dart
import 'app_state.dart';
import './screens/auth_screen.dart';
import 'screens/auth_screen.dart'; 
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializando o Firebase com as configurações do seu projeto
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const BeRoughApp());
}

class BeRoughApp extends StatelessWidget {
  const BeRoughApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeRough',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF9C27B0),
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        fontFamily: 'Inter',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C27B0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Oswald',
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  void _checkInitialAuth() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      // 1. Se o usuário estiver logado no Firebase, vai direto para a Home/Dashboard
      if (FirebaseAuth.instance.currentUser != null) {
        // Recupera o apelido do perfil do Firebase e atualiza o estado
        AppState.instance.nickname = FirebaseAuth.instance.currentUser?.displayName ?? "";
        AppState.instance.profilePhotoPath = FirebaseAuth.instance.currentUser?.photoURL;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        return;
      }

      // 2. Se não estiver logado, checa se já viu o Onboarding alguma vez
      final bool hasSeenOnboarding = await AppState.instance.getOnboardingSeen();

      if (mounted) {
        if (hasSeenOnboarding) {
          // Já viu os banners antes? Vai direto para a tela de autenticação
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        } else {
          // Primeira vez abrindo o app? Mostra a apresentação
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF9C27B0)),
      ),
    );
  }
}