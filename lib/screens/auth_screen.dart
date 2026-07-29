import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';
import 'auth/signup_screen.dart';
import 'skill_selection_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoadingEmail = false;
  bool _isLoadingGoogle = false;
  bool _obscurePassword = true;

  void _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() => _isLoadingEmail = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoadingEmail = false);
      _goToNextScreen();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingEmail = false);
      String errorMessage = 'Erro ao fazer login.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = 'Email ou senha incorretos.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Formato de email inválido.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _loginWithGoogle() async {
    setState(() => _isLoadingGoogle = true);

    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        if (!mounted) return;
        setState(() => _isLoadingGoogle = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      setState(() => _isLoadingGoogle = false);
      _goToNextScreen();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingGoogle = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao autenticar com o Google: $e')),
      );
    }
  }

  void _goToNextScreen() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SkillSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: BeSpacing.sm, vertical: BeSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: BeSpacing.sm),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: BeFonts.displayMd.copyWith(
                    fontSize: 40,
                    letterSpacing: -0.4,
                  ),
                  children: const [
                    TextSpan(
                        text: 'Be', style: TextStyle(color: BeColors.ink)),
                    TextSpan(
                        text: 'Rough',
                        style: TextStyle(color: BeColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: BeSpacing.xxs),
              Text(
                "Entre para continuar sua evolução",
                textAlign: TextAlign.center,
                style: BeFonts.bodyMd,
              ),
              const SizedBox(height: BeSpacing.xl),

              const BeSectionLabel("Email"),
              const SizedBox(height: BeSpacing.xxs),
              TextField(
                controller: _emailController,
                style: beBodyMdInk,
                keyboardType: TextInputType.emailAddress,
                decoration: beInputDecoration(hint: "seu@email.com"),
              ),
              const SizedBox(height: BeSpacing.xs),

              const BeSectionLabel("Senha"),
              const SizedBox(height: BeSpacing.xxs),
              TextField(
                controller: _passwordController,
                style: beBodyMdInk,
                obscureText: _obscurePassword,
                decoration: beInputDecoration(
                  hint: "••••••••",
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: BeColors.muted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text("Esqueceu a senha?",
                      style: BeFonts.bodyMd
                          .copyWith(color: BeColors.primary)),
                ),
              ),
              const SizedBox(height: BeSpacing.xs),

              BePrimaryButton(
                label: "Entrar",
                icon: null,
                onPressed: _isLoadingEmail ? null : _loginWithEmail,
                isLoading: _isLoadingEmail,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: BeSpacing.sm),
                child: Row(
                  children: [
                    const Expanded(child: BeHairline()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("ou continue com",
                          style: BeFonts.caption
                              .copyWith(color: BeColors.muted)),
                    ),
                    const Expanded(child: BeHairline()),
                  ],
                ),
              ),

              BeOutlineButton(
                label: "Google",
                icon: Icons.g_mobiledata,
                onPressed: _isLoadingGoogle ? null : _loginWithGoogle,
              ),

              const SizedBox(height: BeSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Ainda não tem uma conta?",
                      style: BeFonts.bodyMd.copyWith(color: BeColors.muted)),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignupScreen()),
                    ),
                    child: Text("Cadastre-se",
                        style: BeFonts.bodyMd.copyWith(
                            color: BeColors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}