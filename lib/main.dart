import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'app_state.dart';
import 'design/tokens.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/skill_selection_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BeRoughApp());
}

class BeRoughApp extends StatelessWidget {
  const BeRoughApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeRough',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: BeColors.canvas,
        fontFamily: BeFonts.family,
        colorScheme: const ColorScheme.dark(
          primary: BeColors.primary,
          onPrimary: BeColors.onPrimary,
          surface: BeColors.canvas,
          onSurface: BeColors.ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: BeFonts.family,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.18,
            color: BeColors.ink,
          ),
          iconTheme: IconThemeData(color: BeColors.ink),
        ),
        textTheme: const TextTheme(
          displayLarge: BeFonts.displayXl,
          displayMedium: BeFonts.displayLg,
          displaySmall: BeFonts.displayMd,
          headlineMedium: BeFonts.displayMd,
          titleLarge: BeFonts.titleMd,
          titleMedium: BeFonts.titleSm,
          bodyLarge: BeFonts.bodyMdInk,
          bodyMedium: BeFonts.bodyMd,
          bodySmall: BeFonts.bodySm,
          labelLarge: BeFonts.button,
          labelSmall: BeFonts.captionUppercase,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: BeColors.primary,
            foregroundColor: BeColors.onPrimary,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm, vertical: 14),
            minimumSize: const Size(0, 48),
            textStyle: BeFonts.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: BeColors.ink,
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: BeColors.ink, width: 1),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(horizontal: 31, vertical: 13),
            minimumSize: const Size(0, 48),
            textStyle: BeFonts.button.copyWith(color: BeColors.ink),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: BeColors.canvas,
          labelStyle: BeFonts.bodyMd.copyWith(color: BeColors.muted),
          hintStyle: BeFonts.bodyMd.copyWith(color: BeColors.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BeRadii.sm),
            borderSide: const BorderSide(color: BeColors.hairline, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BeRadii.sm),
            borderSide: const BorderSide(color: BeColors.primary, width: 1),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: BeColors.canvas,
          selectedItemColor: BeColors.primary,
          unselectedItemColor: BeColors.muted,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(
            fontFamily: BeFonts.family,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.65,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: BeFonts.family,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.65,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: BeColors.hairline,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: BeColors.canvasElevated,
          contentTextStyle: BeFonts.bodyMd.copyWith(color: BeColors.ink),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

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
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await AppState.instance.loadFromDisk();

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final bool hasProfile = AppState.instance.hasProfileData;

    if (user != null) {
      if (AppState.instance.nickname.isEmpty) {
        AppState.instance.nickname = user.displayName ?? "";
      }
      if (AppState.instance.profilePhotoPath == null) {
        AppState.instance.profilePhotoPath = user.photoURL;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => hasProfile
              ? const HomeScreen()
              : const SkillSelectionScreen(),
        ),
      );
      return;
    }

    final bool hasSeenOnboarding = await AppState.instance.getOnboardingSeen();
    if (!mounted) return;

    if (hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: BeColors.canvas,
      body: Center(
        child: CircularProgressIndicator(color: BeColors.primary),
      ),
    );
  }
}