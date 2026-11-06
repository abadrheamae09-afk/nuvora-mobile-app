// ============================================================
// mockup_theme.dart
// Shared colors, text styles, and decorators for all mockup screens.
// The buyer app's primary brand color is a rich purple/plum (0xFF542261).
// All mockup screens import this file instead of using inline hex values.
// ============================================================

import 'package:flutter/material.dart';

/// Nuvora Buyer brand palette.
class MColors {
  MColors._();

  // ── Brand ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF542261);
  static const Color primaryDark = Color(0xFF3A1544);
  static const Color primaryDeep = Color(0xFF200B26);
  static const Color primaryLight = Color(0xFF7B3E94);
  static const Color primarySoft = Color(0xFFF5EEF8);
  static const Color accent = Color(0xFFAB47BC);

  // ── Neutrals ───────────────────────────────────────────────
  static const Color background = Color(0xFFF9F6FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1A0A1E);
  static const Color muted = Color(0xFF7A6882);
  static const Color border = Color(0xFFE8DFF0);
  static const Color divider = Color(0xFFF0E8F6);

  // ── Status ─────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFE7F6EC);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3E2);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFDECEC);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFE6EEFF);

  // ── Header gradient stops ──────────────────────────────────
  static const Color headerTop = Color(0xFF3A1544);
  static const Color headerBottom = Color(0xFF7B3E94);

  // ── Misc ───────────────────────────────────────────────────
  static const Color starGold = Color(0xFFFBBC05);
  static const Color shimmerBase = Color(0xFFEFE8F3);
  static const Color shimmerHighlight = Color(0xFFFAF6FC);
}

/// Shared text styles.
class MTextStyles {
  MTextStyles._();

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: MColors.ink,
    letterSpacing: -0.3,
  );

  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: MColors.ink,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: MColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: MColors.ink,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: MColors.muted,
  );

  static const TextStyle price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: MColors.primary,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: MColors.primary,
  );

  static const TextStyle tag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );
}

/// Reusable box decoration helpers.
class MDecorations {
  MDecorations._();

  static BoxDecoration card({double radius = 14}) => BoxDecoration(
    color: MColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: MColors.border),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration primaryGradient({double radius = 16}) => BoxDecoration(
    gradient: const LinearGradient(
      colors: [MColors.headerTop, MColors.headerBottom],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
  );

  static BoxDecoration pill({Color color = MColors.primarySoft}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      );
}

/// Standard spacing constants to keep the UI consistent.
class MSpacing {
  MSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(14);
}
