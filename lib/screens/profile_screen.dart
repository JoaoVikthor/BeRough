import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../app_state.dart'; 
import 'auth/onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  double get _weight {
    try { return (AppState.instance as dynamic).weight ?? 76.5; } catch(_) { return 76.5; }
  }
  double get _height {
    try { return (AppState.instance as dynamic).height ?? 1.78; } catch(_) { return 1.78; }
  }
  int get _age {
    try { return (AppState.instance as dynamic).age ?? 24; } catch(_) { return 24; }
  }

  double get _bmi {
    if (_height > 0) {
      return _weight / (_height * _height);
    }
    return 0;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isUploading = true);

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePhotoURL(pickedFile.path);
          await user.reload();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent),
                    SizedBox(width: 12),
                    Text("Foto de perfil atualizada com sucesso!"),
                  ],
                ),
                backgroundColor: Color(0xFF1A1A24),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Falha ao acessar mídia do aparelho: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showImageSourceSelector() {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "FOTO DO ATLETA",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Oswald',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Selecione a origem da imagem para atualizar seu perfil no BeRough.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text("CÂMERA"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C27B0),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                        label: const Text("GALERIA", style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? photoURL) {
    if (_isUploading) {
      return const CircularProgressIndicator(color: Color(0xFF9C27B0));
    }

    if (photoURL == null || photoURL.isEmpty) {
      return const Icon(Icons.person, size: 54, color: Colors.white24);
    }

    if (photoURL.startsWith('http') || photoURL.startsWith('https')) {
      return ClipOval(
        child: Image.network(
          photoURL,
          width: 108,
          height: 108,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 54, color: Colors.white24),
        ),
      );
    }

    return ClipOval(
      child: Image.file(
        File(photoURL),
        width: 108,
        height: 108,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 54, color: Colors.white24);
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Fazer Logout?", style: TextStyle(color: Colors.white, fontFamily: 'Oswald')),
          content: const Text(
            "Você sairá da sua conta de atleta BeRough, mas seus treinos continuarão salvos no banco de dados.",
            style: TextStyle(color: Colors.grey, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                
                AppState.instance.selectedSkillIds.clear();
                AppState.instance.runHistory.clear();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    this.context,
                    MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("SAIR"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String athleteName = user?.displayName ?? "Atleta BeRough";
    final String athleteEmail = user?.email ?? "atleta@berough.com";
    final String? photoURL = user?.photoURL;
    
    final selectedSkills = AppState.instance.availableSkills
        .where((s) => AppState.instance.selectedSkillIds.contains(s.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "PERFIL DE ATLETA",
          style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF9C27B0), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9C27B0).withOpacity(0.15),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xFF1A1A24),
                        child: _buildAvatar(photoURL),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceSelector,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF9C27B0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                athleteName,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Oswald'),
              ),
              const SizedBox(height: 4),
              Text(
                athleteEmail,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(child: _buildMetricItem("PESO", "$_weight", "kg")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricItem("ALTURA", "$_height", "m")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricItem("IDADE", "$_age", "anos")),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle("SEU PERFIL CORPORAL (IMC)"),
              const SizedBox(height: 12),
              _buildLudicBMICard(),
              
              const SizedBox(height: 32),

              _buildSectionTitle("SUA TRILHA DE EVOLUÇÃO"),
              const SizedBox(height: 12),
              if (selectedSkills.isEmpty)
                _buildInfoCard("Nenhuma habilidade ativa selecionada.")
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedSkills.map((skill) {
                    return Chip(
                      backgroundColor: const Color(0xFF1A1A24),
                      side: const BorderSide(color: Color(0xFF333333)),
                      avatar: const Icon(Icons.fitness_center_rounded, color: Color(0xFF9C27B0), size: 16),
                      label: Text(
                        skill.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text("SAIR DA CONTA", style: TextStyle(fontFamily: 'Oswald', letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF271313),
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ); 
  }

  Widget _buildMetricItem(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Oswald')),
              const SizedBox(width: 2),
              Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }

  Widget _buildLudicBMICard() {
    final double currentBmi = _bmi;
    String title = "";
    String subtitle = "";
    Color color = Colors.white;
    IconData icon = Icons.fitness_center;

    if (currentBmi == 0) {
      return const SizedBox();
    } else if (currentBmi < 18.5) {
      title = "NINJA ÁGIL";
      subtitle = "Leve, rápido e mestre da gravidade! Foco na hipertrofia para voar mais alto.";
      color = Colors.blueAccent;
      icon = Icons.air;
    } else if (currentBmi >= 18.5 && currentBmi < 25) {
      title = "MÁQUINA ESTÉTICA";
      subtitle = "Equilíbrio perfeito de força e controle! Seu corpo é uma verdadeira arma.";
      color = Colors.greenAccent;
      icon = Icons.bolt;
    } else if (currentBmi >= 25 && currentBmi < 30) {
      title = "TANQUE DE GUERRA";
      subtitle = "Força bruta pura! Cargas altas não são problema. Trabalhe a mobilidade.";
      color = Colors.orangeAccent;
      icon = Icons.shield;
    } else {
      title = "JUGGERNAUT ROUGH";
      subtitle = "Poder inabalável! Construa resistência e veja a verdadeira transformação acontecer.";
      color = Colors.redAccent;
      icon = Icons.local_fire_department;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), const Color(0xFF1A1A24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontFamily: 'Oswald',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "IMC: ${currentBmi.toStringAsFixed(1)}",
                        style: TextStyle(
                          color: color,
                          fontFamily: 'Oswald',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}