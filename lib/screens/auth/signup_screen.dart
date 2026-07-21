import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleSignUp() async {
    // Validação básica
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Integração Real com Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Opcional: Atualiza o perfil do Firebase com o nome fornecido
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      setState(() => _isLoading = false);

      if (mounted) {
        // Após o cadastro com sucesso, enviamos ele direto para o Coach
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AICoachScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = 'Erro ao criar conta. Tente novamente.';
      
      // Tratamento de erros comuns do Firebase
      if (e.code == 'weak-password') {
        errorMessage = 'A senha fornecida é muito fraca (mínimo 6 caracteres).';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Já existe uma conta com este email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Formato de email inválido.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro inesperado de servidor.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Volta para a tela de Login
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Junte-se à Tribo",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Oswald', color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "Crie sua conta e inicie sua jornada na calistenia.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              _buildTextField("Nome Completo", "Seu nome", _nameController, false),
              const SizedBox(height: 20),
              _buildTextField("Email", "seu@email.com", _emailController, false),
              const SizedBox(height: 20),
              
              _buildTextField("Senha", "••••••••", _passwordController, true),
              const SizedBox(height: 20),
              _buildTextField("Confirmar Senha", "••••••••", _confirmPasswordController, true),
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("CRIAR CONTA"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A24),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9C27B0))),
            suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          ),
        ),
      ],
    );
  }
}