import 'package:flutter/material.dart';
import 'tokens.dart';

/// Componentes reutilizáveis do BeRough derivados de `DESIGN.md`.
///
/// Regras do design system (resumidas):
/// - CTAs: Rosso Corsa, sharp corners (0px), uppercase + 1.4px tracking, 48px altura.
/// - Cards: canvas-elevated, sharp corners, 1px hairline.
/// - Badges: pill (full radius), uppercase caption.
/// - Inputs: canvas dark, sharp/sm radius 4px, 1px hairline, 48px altura.
/// - SEM drop shadows — profundidade via brightness-step + hairline.

/// CTA primário Rosso Corsa. Sharp corners, uppercase tracking.
class BePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double minWidth;

  const BePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.minWidth = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(color: BeColors.onPrimary, strokeWidth: 2),
          )
        : (icon == null)
            ? Text(label, style: BeFonts.button)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: BeColors.onPrimary, size: 18),
                  const SizedBox(width: BeSpacing.xxs),
                  Text(label, style: BeFonts.button),
                ],
              );

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: BeColors.primary,
          foregroundColor: BeColors.onPrimary,
          disabledBackgroundColor: BeColors.primaryActive,
          disabledForegroundColor: BeColors.onPrimary,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: BeSpacing.sm, vertical: 14),
          minimumSize: const Size(0, 48),
        ),
        child: child,
      ),
    );
  }
}

/// CTA outline transparente (sobre fundo escuro). 1px ink border, sharp corners.
class BeOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool onLight;

  const BeOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.onLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = onLight ? BeColors.bodyOnLight : BeColors.ink;
    final TextStyle style = BeFonts.button.copyWith(color: fg);

    final Widget child = icon == null
        ? Text(label, style: style)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: BeSpacing.xxs),
              Text(label, style: style),
            ],
          );

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: Colors.transparent,
        elevation: 0,
        side: BorderSide(color: fg, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 31, vertical: 13),
        minimumSize: const Size(0, 48),
      ),
      child: child,
    );
  }
}

/// Card elevado padrão: canvas-elevated, sharp corners, 1px hairline.
class BeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;

  const BeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BeSpacing.sm),
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? BeColors.canvasElevated,
        borderRadius: BorderRadius.circular(borderRadius ?? BeRadii.none),
        border: Border.all(color: borderColor ?? BeColors.hairline, width: 1),
      ),
      child: child,
    );
  }
}

/// Badge em pílula (único lugar onde radius full é permitido).
class BeBadgePill extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? foreground;

  const BeBadgePill({
    super.key,
    required this.label,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? BeColors.canvasElevated,
        borderRadius: BorderRadius.circular(BeRadii.full),
        border: Border.all(color: BeColors.hairline, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: BeFonts.captionUppercase.copyWith(color: foreground ?? BeColors.ink),
      ),
    );
  }
}

/// Section label — caption uppercase (11px / 600 / 1.1px).
class BeSectionLabel extends StatelessWidget {
  final String label;
  final Color? color;
  const BeSectionLabel(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: BeFonts.captionUppercase.copyWith(color: color ?? BeColors.body),
    );
  }
}

/// Hairline divider 1px na cor do token (quebra editorial sem sombra).
class BeHairline extends StatelessWidget {
  final Color? color;
  final double thickness;
  const BeHairline({super.key, this.color, this.thickness = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: thickness,
      width: double.infinity,
      color: color ?? BeColors.hairline,
    );
  }
}

/// Input de formulário dark: canvas, sharp/sm radius, hairline border, 48px altura.
/// Note: focus state usa Rosso Corsa.
InputDecoration beInputDecoration({
  required String hint,
  String? label,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: BeFonts.bodyMd.copyWith(color: BeColors.muted),
    hintText: hint,
    hintStyle: BeFonts.bodyMd.copyWith(color: BeColors.muted),
    floatingLabelStyle: BeFonts.bodyMd.copyWith(color: BeColors.ink),
    filled: true,
    fillColor: BeColors.canvas,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    isDense: false,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(BeRadii.sm),
      borderSide: const BorderSide(color: BeColors.hairline, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(BeRadii.sm),
      borderSide: const BorderSide(color: BeColors.primary, width: 1),
    ),
    suffixIcon: suffix,
  );
}

/// Helper para TextStyle com cor flexível.
TextStyle beBodyMdInk = BeFonts.bodyMd.copyWith(color: BeColors.ink);
TextStyle beTitleMdInk = BeFonts.titleMd.copyWith(color: BeColors.ink);