import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart'; 
import 'auth/signup_screen.dart'; // Certifique-se de que este arquivo existe no projeto depois
import '../goal_setting_screen.dart'; // <-- Importando a nova tela de definição de metas

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoadingEmail = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() => _isLoadingEmail = false);
      _goToNextScreen();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoadingEmail = false);
      String errorMessage = 'Erro ao fazer login.';
      
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Email ou senha incorretos.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Formato de email inválido.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _loginWithGoogle() async {
    setState(() => _isLoadingGoogle = true);

    try {
      // 1. Na v7.x+, precisamos inicializar a instância global uma vez antes do uso
      await GoogleSignIn.instance.initialize();
      
      // 2. Chamamos o 'authenticate' em vez do 'signIn' antigo
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      
      if (googleUser == null) {
        setState(() => _isLoadingGoogle = false);
        return; // Usuário cancelou o fluxo de login
      }

      // 3. Obtemos os tokens de autenticação da conta selecionada
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. Criamos a credencial para o Firebase usando apenas o idToken (o accessToken não é mais necessário na v7)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 5. Realizamos o login no Firebase Authentication
      await FirebaseAuth.instance.signInWithCredential(credential);

      setState(() => _isLoadingGoogle = false);
      _goToNextScreen();
    } catch (e) {
      setState(() => _isLoadingGoogle = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao autenticar com o Google: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _goToNextScreen() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GoalSettingScreen()), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'Oswald'),
                  children: [
                    TextSpan(text: 'Be', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'Rough', style: TextStyle(color: Color(0xFF9C27B0))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Entre para continuar sua evolução", 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey, fontSize: 16)
              ),
              const SizedBox(height: 50),

              const Text("Email", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true, fillColor: const Color(0xFF1A1A24),
                  hintText: "seu@email.com", hintStyle: const TextStyle(color: Colors.white30),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9C27B0))),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text("Senha", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true, fillColor: const Color(0xFF1A1A24),
                  hintText: "••••••••", hintStyle: const TextStyle(color: Colors.white30),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9C27B0))),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Esqueceu a senha?", style: TextStyle(color: Color(0xFF9C27B0))),
                ),
              ),
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: _isLoadingEmail ? null : _loginWithEmail,
                child: _isLoadingEmail 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("ENTRAR"),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFF333333))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("ou continue com", style: TextStyle(color: Colors.grey, fontSize: 12))),
                    Expanded(child: Divider(color: Color(0xFF333333))),
                  ],
                ),
              ),
              
              OutlinedButton.icon(
                onPressed: _isLoadingGoogle ? null : _loginWithGoogle,
                icon: _isLoadingGoogle 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF9C27B0), strokeWidth: 2))
                    : const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
                label: const Text("Google", style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF333333)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFF1A1A24),
                ),
              ),
              
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Ainda não tem uma conta?", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    child: const Text("Cadastre-se", style: TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}