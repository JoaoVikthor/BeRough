import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../app_state.dart';
import '../profile_screen.dart';
import 'trail_detail_screen.dart'; // <--- ADICIONE ESTA LINHA AQUI
import '../run/RunTrackingScreen.dart'; // ADICIONADO PARA O NOVO MÓDULO DE GPS

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String athleteName = user?.displayName ?? "Atleta BeRough";

    // Filtro estrito: Só mostra as habilidades que o ID está salvo no state (as que você escolheu)
    final activeSkills = AppState.instance.availableSkills
        .where((s) => AppState.instance.selectedSkillIds.contains(s.id))
        .toList();
    
    final runs = AppState.instance.runHistory;

    // PROGRESSÃO DE NÍVEL REAL:
    // Baseado no número de exercícios/corridas registradas no histórico
    final int completedExercises = runs.length; 
    final int currentLevel = (completedExercises ~/ 3) + 1; // Sobe 1 nível a cada 3 exercícios
    final int currentXP = completedExercises * 50;
    final int nextLevelXP = currentLevel * 150;
    final double levelProgress = nextLevelXP > 0 ? (currentXP / nextLevelXP) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: _buildAppBar(user, athleteName, context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLevelCard(currentLevel, currentXP, nextLevelXP, levelProgress),
              const SizedBox(height: 24),
              
              _buildSectionHeader("SUAS METAS ATIVAS"),
              const SizedBox(height: 12),
              activeSkills.isEmpty
                  ? _buildEmptySkillsCard()
                  : _buildSkillsList(activeSkills),
              const SizedBox(height: 24),

              // BOTAO NOVO PARA INICIAR CORRIDA REAL
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RunTrackingScreen()),
                    );
                  },
                  icon: const Icon(Icons.satellite_alt, color: Colors.white),
                  label: const Text("INICIAR CORRIDA COM GPS", style: TextStyle(fontFamily: 'Oswald', letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader("HISTÓRICO DE CORRIDAS"),
              const SizedBox(height: 12),
              runs.isEmpty
                  ? _buildEmptyRunsCard()
                  : _buildRunsList(runs),
              const SizedBox(height: 24),

              _buildSectionHeader("CONSELHO DO TREINADOR"),
              const SizedBox(height: 12),
              _buildCoachTip(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(User? user, String athleteName, BuildContext context) {
    // Verifica a origem da imagem (link do Google ou arquivo da Galeria)
    ImageProvider? avatarImage;
    if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      if (user.photoURL!.startsWith('http')) {
        avatarImage = NetworkImage(user.photoURL!);
      } else {
        avatarImage = FileImage(File(user.photoURL!));
      }
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "FORÇA & RAÇA",
            style: TextStyle(
              color: Color(0xFF9C27B0),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            athleteName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Oswald',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF9C27B0), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1A1A24),
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildAddTrailButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Aqui você pode direcionar para a tela de seleção de exercícios no futuro
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Abrindo menu para adicionar novas trilhas..."),
              backgroundColor: Color(0xFF9C27B0),
            ),
          );
        },
        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF9C27B0)),
        label: const Text(
          "ADICIONAR NOVAS TRILHAS",
          style: TextStyle(color: Color(0xFF9C27B0), fontFamily: 'Oswald', letterSpacing: 1.0),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF9C27B0), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildLevelCard(int level, int currentXP, int nextLevelXP, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E102F), Color(0xFF13091E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ATLETA ROUGH NÍVEL $level",
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Oswald',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "XPs: $currentXP / $nextLevelXP",
                  style: const TextStyle(color: Color(0xFFE040FB), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF1A1A24),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySkillsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: const Text(
        "Nenhuma habilidade em foco.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildSkillsList(List<dynamic> skills) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0, // Formato mais quadrado para caber a imagem e a rodinha
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        final double skillProgress = 0.35; // Progresso visual de exemplo

        return GestureDetector(
          onTap: () {
            // Navegação para a tela de etapas da trilha (AGORA RECEBE O OBJETO SKILL)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrailDetailScreen(skill: skill), // MODIFICADO
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Área reservada para IMAGEM do exercício no futuro
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF13131A),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_outlined, color: Colors.white24, size: 36),
                    ),
                  ),
                ),
                // Área do Título e Progresso
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          skill.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontFamily: 'Oswald', fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Rodinha de progresso circular
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: skillProgress,
                              backgroundColor: Colors.white12,
                              color: const Color(0xFF9C27B0),
                              strokeWidth: 3,
                            ),
                            Center(
                              child: Text(
                                "${(skillProgress * 100).toInt()}%",
                                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyRunsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: const Text(
        "Nenhuma corrida registrada.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildRunsList(List<dynamic> runs) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: runs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final run = runs[index]; // Agora isso é um RunLog de verdade!
        
        // Convertendo os metros para KM formatado com 2 casas decimais
        final double km = run.distanceInMeters / 1000;
        final String distanceFormatted = km.toStringAsFixed(2);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF22222D)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$distanceFormatted km",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "Pace: ${run.pace}",
                style: const TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoachTip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports, color: Color(0xFF9C27B0), size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DICA DO TREINADOR",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Oswald', letterSpacing: 1.0),
                ),
                SizedBox(height: 6),
                Text(
                  "Não pule as etapas da sua jornada. Consistência vence o talento a longo prazo. Ajuste suas cargas hoje e mantenha a execução perfeita!",
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}