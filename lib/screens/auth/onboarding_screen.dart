import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Domine seu Próprio Corpo",
      "subtitle": "Esqueça as máquinas. Na calistenia, a gravidade é o seu único peso e a rua é a sua academia.",
    },
    {
      "title": "Desbloqueie Novas Skills",
      "subtitle": "Das primeiras flexões ao Muscle-Up. Um mapa de evolução passo a passo adaptado ao seu nível.",
    },
    {
      "title": "A Força da Consistência",
      "subtitle": "Desafie seus limites, registre seu progresso e compartilhe suas conquistas. O treino começa agora.",
    },
  ];

  void _goToAuth() async {
    await AppState.instance.saveOnboardingSeen();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A24),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF333333)),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.fitness_center, size: 60, color: Color(0xFF9C27B0)),
                                const SizedBox(height: 16),
                                Text(
                                  "[ Espaço para Mídia ${index + 1} ]",
                                  style: const TextStyle(color: Colors.grey),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          onboardingData[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Oswald',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          onboardingData[index]["subtitle"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _goToAuth,
                    child: const Text("Pular", style: TextStyle(color: Colors.grey)),
                  ),
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => buildDot(index, context),
                    ),
                  ),
                  _currentPage == onboardingData.length - 1
                      ? ElevatedButton(
                          onPressed: _goToAuth,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(150, 50),
                          ),
                          child: const Text("Começar"),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF9C27B0),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward, color: Colors.white),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF9C27B0) : const Color(0xFF333333),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}