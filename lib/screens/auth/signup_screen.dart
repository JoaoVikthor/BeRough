import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';
import '../ai_coach_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleSignUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AICoachScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String errorMessage = 'Erro ao criar conta. Tente novamente.';
      if (e.code == 'weak-password') {
        errorMessage = 'A senha fornecida é muito fraca (mínimo 6 caracteres).';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Já existe uma conta com este email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Formato de email inválido.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado de servidor.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: BeColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Junte-se à Tribo",
                style: BeFonts.displayMd.copyWith(
                  fontSize: 32,
                  letterSpacing: -0.32,
                ),
              ),
              const SizedBox(height: BeSpacing.xxs),
              Text(
                "Crie sua conta e inicie sua jornada na calistenia.",
                style: BeFonts.bodyMd,
              ),
              const SizedBox(height: BeSpacing.lg),

              _buildField(
                label: "Nome Completo",
                hint: "Seu nome",
                controller: _nameController,
                isPassword: false,
              ),
              const SizedBox(height: BeSpacing.xs),
              _buildField(
                label: "Email",
                hint: "seu@email.com",
                controller: _emailController,
                isPassword: false,
              ),
              const SizedBox(height: BeSpacing.xs),
              _buildField(
                label: "Senha",
                hint: "••••••••",
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: BeSpacing.xs),
              _buildField(
                label: "Confirmar Senha",
                hint: "••••••••",
                controller: _confirmPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: BeSpacing.lg),

              BePrimaryButton(
                label: "Criar Conta",
                onPressed: _isLoading ? null : _handleSignUp,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isPassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BeSectionLabel(label),
        const SizedBox(height: BeSpacing.xxs),
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          style: beBodyMdInk,
          decoration: beInputDecoration(
            hint: hint,
            suffix: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: BeColors.muted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}