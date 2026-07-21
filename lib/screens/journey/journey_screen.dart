import 'package:flutter/material.dart';
import '../../app_state.dart';
import 'trail_detail_screen.dart';
import '../../goal_setting_screen.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({Key? key}) : super(key: key);

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  @override
  Widget build(BuildContext context) {
    // Filtramos apenas as skills que o usuário ativou nas metas
    final activeSkills = AppState.instance.availableSkills
        .where((s) => AppState.instance.selectedSkillIds.contains(s.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "MINHA JORNADA",
          style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TRILHAS ATIVAS",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              activeSkills.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeSkills.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildJourneyCard(activeSkills[index]);
                      },
                    ),
              const SizedBox(height: 24),
              
              _buildAddTrailButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: const Column(
        children: [
          Icon(Icons.map, size: 48, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            "Você ainda não iniciou nenhuma trilha de evolução.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard(CalisthenicsSkill skill) {
    return GestureDetector(
      onTap: () {
        // CORREÇÃO APLICADA AQUI: O parâmetro "skill: skill" agora é passado corretamente!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrailDetailScreen(skill: skill),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center, color: Color(0xFF9C27B0)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Oswald',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Dificuldade: ${skill.difficulty}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTrailButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Direciona o usuário de volta para definir mais metas
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GoalSettingScreen()),
          );
        },
        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF9C27B0)),
        label: const Text(
          "ADICIONAR NOVAS TRILHAS",
          style: TextStyle(color: Color(0xFF9C27B0), fontFamily: 'Oswald', letterSpacing: 1.0),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF9C27B0), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}