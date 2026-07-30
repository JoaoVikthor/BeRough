import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../design/tokens.dart';
import '../../design/ui.dart';

/// Tela de parabéns exibida ao concluir um passo da trilha.
///
/// Mostra um **log** com as metas atingidas daquele passo/etapa e, se for o
/// último passo da trilha, celebra a conquista da meta final.
class StepCompleteScreen extends StatelessWidget {
  final CalisthenicsSkill skill;
  final TrailStep step;

  /// true quando este era o último passo da trilha (meta final atingida).
  final bool isFinalStep;

  /// Resumo textual de métricas alcançadas (preenchido pela step_screen).
  final String achievedLog;

  /// XP ganho por concluir este passo.
  final int xpGained;

  const StepCompleteScreen({
    super.key,
    required this.skill,
    required this.step,
    required this.isFinalStep,
    required this.achievedLog,
    this.xpGained = 50,
  });

  void _goBackToTrail(BuildContext context) {
    // Volta direto para a HomeScreen (tab Jornada) — limpa a pilha.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isFinalStep ? "META ATINGIDA" : "PASSO CONCLUÍDO"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: BeColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: BeColors.primary, width: 2),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: BeColors.primary, size: 56),
              ),
              const SizedBox(height: BeSpacing.sm),
              Text(
                isFinalStep
                    ? "PARABÉNS! META FINAL"
                    : "PARABÉNS! PASSO ${step.index + 1}",
                textAlign: TextAlign.center,
                style: BeFonts.displayMd
                    .copyWith(fontSize: 26, color: BeColors.ink),
              ),
              const SizedBox(height: BeSpacing.xxs),
              Text(
                isFinalStep
                    ? "Você conquistou sua meta de ${skill.name}. Trilha completa!"
                    : "Etapa ${step.index + 1} de ${skill.name.toUpperCase()} concluída.",
                textAlign: TextAlign.center,
                style: BeFonts.bodyMd.copyWith(color: BeColors.body),
              ),
              const SizedBox(height: BeSpacing.lg),

              // Log com metas atingidas
              BeSectionLabel("LOG DE METAS"),
              const SizedBox(height: BeSpacing.xxs),
              BeCard(
                padding: const EdgeInsets.all(BeSpacing.xs),
                borderColor: BeColors.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _logRow(Icons.check_circle, step.title,
                        color: BeColors.semanticSuccess),
                    const SizedBox(height: BeSpacing.xxs),
                    const BeHairline(),
                    const SizedBox(height: BeSpacing.xxs),
                    _logRow(Icons.timeline, achievedLog,
                        color: BeColors.ink, valueStyle: true),
                    const SizedBox(height: BeSpacing.xxs),
                    const BeHairline(),
                    const SizedBox(height: BeSpacing.xxs),
                    _logRow(Icons.bolt, "+$xpGained XP",
                        color: BeColors.primary),
                  ],
                ),
              ),
              const Spacer(),

              // Tela de meta final: badge + botão de definir nova meta
              if (isFinalStep) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(BeSpacing.xs),
                  decoration: BoxDecoration(
                    color: BeColors.primary,
                    border: Border.all(color: BeColors.primary, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: BeColors.onPrimary, size: 32),
                      const SizedBox(height: 4),
                      Text("META ATINGIDA",
                          style: BeFonts.captionUppercase.copyWith(
                              color: BeColors.onPrimary,
                              letterSpacing: 1.4,
                              fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: BeSpacing.xs),
              ],

              SizedBox(
                width: double.infinity,
                child: BePrimaryButton(
                  label: isFinalStep ? "Definir Nova Meta" : "Próximo Passo",
                  icon: isFinalStep ? Icons.flag : Icons.arrow_forward,
                  onPressed: () => _goBackToTrail(context),
                ),
              ),
              const SizedBox(height: BeSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logRow(IconData icon, String text,
      {required Color color, bool valueStyle = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: BeSpacing.xxs),
        Expanded(
          child: Text(
            text,
            style: valueStyle
                ? BeFonts.bodyMdInk.copyWith(fontSize: 15)
                : BeFonts.bodyMd.copyWith(color: BeColors.ink),
          ),
        ),
      ],
    );
  }
}