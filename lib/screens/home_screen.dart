import 'package:flutter/material.dart';
import '../app_state.dart';
import 'journey/dashboard_screen.dart';
import 'running_screen.dart';
import 'profile_screen.dart'; // Importação do arquivo de perfil real

// Este arquivo gerencia a barra de navegação inferior (Bottom Navigation)
// e alterna entre as telas principais do BeRough.

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      _buildJourneyTab(), // Aba de Jornada dinâmica
      const Center(child: Text("Comunidade / Feed (Em Breve)", style: TextStyle(color: Colors.white))),
      const ProfileScreen(), // Tela de Perfil Real na quarta aba!
    ];
  }

  IconData _getSkillIcon(String iconName) {
    switch (iconName) {
      case 'arrow_upward': return Icons.arrow_upward_rounded;
      case 'sports_gymnastics': return Icons.sports_gymnastics_rounded;
      case 'horizontal_rule': return Icons.horizontal_rule_rounded;
      case 'fitness_center': return Icons.fitness_center_rounded;
      case 'flag': return Icons.flag_rounded;
      case 'accessibility_new': return Icons.accessibility_new_rounded;
      default: return Icons.fitness_center;
    }
  }

  Widget _buildJourneyTab() {
    return Builder(
      builder: (context) {
        final allSkills = AppState.instance.availableSkills;
        final selectedIds = AppState.instance.selectedSkillIds;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SUA JORNADA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oswald',
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "As missões disponíveis refletem diretamente as escolhas do seu perfil.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),

                _buildMissionCard(
                  context,
                  title: "Corrida ao Ar Livre",
                  subtitle: "Rastreamento por GPS em tempo real",
                  description: "Monitore seu trajeto com o Custom Canvas dinâmico, calcule seu ritmo (pace) e meça suas calorias de forma real.",
                  isActive: true,
                  badgeText: "CARDIO ATIVO",
                  icon: Icons.directions_run_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RunningScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                ...allSkills.map((skill) {
                  final bool isSelected = selectedIds.contains(skill.id);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildMissionCard(
                      context,
                      title: "Desafio ${skill.name}",
                      subtitle: skill.category,
                      description: "Progressões avançadas com o peso corporal focadas no desenvolvimento de força neural para ${skill.name}.",
                      isActive: isSelected,
                      badgeText: isSelected ? "MISSÃO DISPONÍVEL" : "BLOQUEADO (Selecione no Onboarding)",
                      icon: _getSkillIcon(skill.iconName),
                      onTap: () {
                        if (isSelected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Iniciando rotina de treinos para ${skill.name}! Core firme, atleta."),
                              backgroundColor: const Color(0xFF9C27B0),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Esta skill está bloqueada. Altere suas metas no Onboarding para liberar."),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildMissionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required bool isActive,
    required String badgeText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF9C27B0).withOpacity(0.5) : const Color(0xFF333333),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF9C27B0).withOpacity(0.2) : const Color(0xFF333333).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: isActive ? const Color(0xFFE040FB) : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Icon(icon, color: isActive ? const Color(0xFF9C27B0) : Colors.grey, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white30,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Oswald',
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(color: isActive ? Colors.grey : Colors.white24, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(color: isActive ? Colors.white70 : Colors.white24, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "INICIAR MISSÃO",
                  style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF333333), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF0D0D12),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF9C27B0),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Jornada',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Tribo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}