import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';
import '../auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Domine seu Próprio Corpo",
      "subtitle":
          "Esqueça as máquinas. Na calistenia, a gravidade é o seu único peso e a rua é a sua academia.",
    },
    {
      "title": "Desbloqueie Novas Skills",
      "subtitle":
          "Das primeiras flexões ao Muscle-Up. Um mapa de evolução passo a passo adaptado ao seu nível.",
    },
    {
      "title": "A Força da Consistência",
      "subtitle":
          "Desafie seus limites, registre seu progresso e compartilhe suas conquistas. O treino começa agora.",
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
      backgroundColor: BeColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hero cinematáfico — placeholder para fotografia full-bleed.
                        Container(
                          height: MediaQuery.of(context).size.height * 0.42,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: BeColors.canvasElevated,
                            border: Border.all(color: BeColors.hairline, width: 1),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fitness_center,
                                    size: 64, color: BeColors.primary),
                                const SizedBox(height: BeSpacing.xxs),
                                Text("[ Fotografia hero ]",
                                    style: BeFonts.caption
                                        .copyWith(color: BeColors.muted)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: BeSpacing.lg),
                        Text(
                          onboardingData[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: BeFonts.displayMd.copyWith(
                            color: BeColors.ink,
                            fontSize: 30,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: BeSpacing.xs),
                        Text(
                          onboardingData[index]["subtitle"]!,
                          textAlign: TextAlign.center,
                          style: BeFonts.bodyMd.copyWith(
                            color: BeColors.body,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: BeSpacing.sm, vertical: BeSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _goToAuth,
                    child: Text("Pular",
                        style:
                            BeFonts.bodyMd.copyWith(color: BeColors.muted)),
                  ),
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                  _currentPage == onboardingData.length - 1
                      ? BePrimaryButton(
                          label: "Começar",
                          onPressed: _goToAuth,
                          minWidth: 140,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: BeColors.primary,
                            border:
                                Border.all(color: BeColors.primary, width: 1),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward,
                                color: BeColors.onPrimary),
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
            const SizedBox(height: BeSpacing.xxs),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final bool active = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 2,
      width: active ? 24 : 12,
      decoration: BoxDecoration(
        color: active ? BeColors.primary : BeColors.hairline,
      ),
    );
  }
}