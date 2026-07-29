import 'package:flutter/material.dart';

/// Design tokens do BeRough, extraídos de `DESIGN.md` (sistema visual Ferrari).
///
/// Princípios:
/// - Canvas é **near-black** `#181818` (nunca preto puro).
/// - Único accent: Rosso Corsa `#da291c`, usado **raramente**.
/// - Cantos sharp (`rounded.none` 0px) em CTAs, cards e bands. Pílula só em badges.
/// - Display weight 500 (nunca bold); body 400; CTA 700 uppercase + 1.4px tracking.
/// - Profundidade via brightness-step + hairline 1px — **sem drop shadows**.
/// - Escala de espaços: 4/8/16/24/32/48/64/96/128 (token ladder 8px).

class BeColors {
  BeColors._();

  // Brand
  static const Color primary = Color(0xFFDA291C);       // Rosso Corsa
  static const Color primaryActive = Color(0xFFB01E0A); // press
  static const Color primaryHover = Color(0xFF9D2211);  // documented, not used

  // Hypersail accents (out of scope — não usar em BeRough)
  static const Color accentYellow = Color(0xFFF6E500);

  // Canvas / surfaces
  static const Color canvas = Color(0xFF181818);        // base near-black
  static const Color canvasElevated = Color(0xFF303030);// cards / driver card
  static const Color canvasLight = Color(0xFFFFFFFF);   // editorial bands
  static const Color surfaceCard = Color(0xFF303030);
  static const Color surfaceSoftLight = Color(0xFFF7F7F7);
  static const Color surfaceStrongLight = Color(0xFFEBEBEB);

  // Hairlines
  static const Color hairline = Color(0xFF303030);      // 1px on dark
  static const Color hairlineOnLight = Color(0xFFD2D2D2);
  static const Color hairlineSoft = Color(0xFFEBEBEB);

  // Text
  static const Color ink = Color(0xFFFFFFFF);           // display / emphasis on dark
  static const Color body = Color(0xFF969696);           // default running text
  static const Color bodyStrong = Color(0xFFFFFFFF);
  static const Color bodyOnLight = Color(0xFF181818);
  static const Color muted = Color(0xFF666666);
  static const Color mutedSoft = Color(0xFF8F8F8F);

  // On colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onLight = Color(0xFF181818);

  // Semantic
  static const Color semanticInfo = Color(0xFF4C98B9);
  static const Color semanticSuccess = Color(0xFF03904A);
  static const Color semanticWarning = Color(0xFFF13A2C);
}

class BeRadii {
  BeRadii._();

  static const double none = 0;     // default angular para CTA/card/band
  static const double xs = 2;       // tight badges (raro)
  static const double sm = 4;        // form inputs
  static const double md = 6;        // compact cards (raro)
  static const double lg = 8;        // mobile-only collapse cards
  static const double xl = 12;      // modal/dialog corners (raro)
  static const double full = 9999;  // avatar / badge pill
}

class BeSpacing {
  BeSpacing._();

  static const double xxxs = 4;
  static const double xxs = 8;
  static const double xs = 16;
  static const double sm = 24;
  static const double md = 32;
  static const double lg = 48;
  static const double xl = 64;
  static const double xxl = 96;
  static const double superSpace = 128;

  // Section padding helpers
  static const double section = xxl;     // 96 — major bands
  static const double heroDepth = superSpace; // 128 — hero band
}

class BeFonts {
  BeFonts._();

  /// Substituto open-source de FerrariSans.
  static const String family = 'Inter';

  // Text styles — display weight 500 (nunca bold), body 400, CTA 700 uppercase.
  static const TextStyle displayMega = TextStyle(
    fontFamily: family,
    fontSize: 80,
    fontWeight: FontWeight.w500,
    height: 1.05,
    letterSpacing: -1.6,
    color: BeColors.ink,
  );

  static const TextStyle displayXl = TextStyle(
    fontFamily: family,
    fontSize: 56,
    fontWeight: FontWeight.w500,
    height: 1.1,
    letterSpacing: -1.12,
    color: BeColors.ink,
  );

  static const TextStyle displayLg = TextStyle(
    fontFamily: family,
    fontSize: 36,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.36,
    color: BeColors.ink,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: family,
    fontSize: 26,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.195,
    color: BeColors.ink,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    color: BeColors.ink,
  );

  static const TextStyle titleSm = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.08,
    color: BeColors.ink,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: BeColors.body,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: BeColors.body,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
    color: BeColors.body,
  );

  static const TextStyle captionUppercase = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 1.1,
    color: BeColors.ink,
  );

  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 1.4,
    color: BeColors.onPrimary,
  );

  static const TextStyle navLink = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.65,
    color: BeColors.ink,
  );

  static const TextStyle numberDisplay = TextStyle(
    fontFamily: family,
    fontSize: 80,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -1.6,
    color: BeColors.ink,
  );

  // Variações utilitárias (com cor já injetada) — const para uso em const contexts.
  static const TextStyle bodyMdInk = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: BeColors.ink,
  );

  static const TextStyle bodyMdOnLight = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: BeColors.bodyOnLight,
  );
}