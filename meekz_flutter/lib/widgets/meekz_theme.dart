import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colour tokens ────────────────────────────────────────────────────────────
// Design direction (Stitch UI): warm pinkish-cream background, soft pastels,
// child-friendly rounded shapes, non-alarming indicator palette.
class MeekzColors {
  MeekzColors._();

  // ── Base palette (Stitch UI) ─────────────────────────────────────────────
  /// Warm organic cream/pink background — feels soft and comfortable.
  static const background = Color(0xFFFFF8F6);

  /// Standard surfaces use the same warm background color or low-elevation colors.
  static const surface = Color(0xFFFFF8F6);

  /// Deep warm brown-black — highly readable, soft text color.
  static const ink = Color(0xFF2E150B);

  /// Muted purple-grey for secondary/helper text.
  static const muted = Color(0xFF4F434F);

  /// Muted purple-grey outline for borders.
  static const border = Color(0xFF817380);

  // ── Brand colours (Stitch UI) ────────────────────────────────────────────
  /// Soft Purple — clinical reliability meets childhood wonder.
  static const primary = Color(0xFF893B98);
  static const primaryDark = Color(0xFF702381);

  /// Mint Teal — fresh cooling secondary tone.
  static const secondary = Color(0xFF006A63);

  // ── Stitch Surface Container Tones ───────────────────────────────────────
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFFFF1EC);
  static const surfaceContainer = Color(0xFFFFE9E3);
  static const surfaceContainerHigh = Color(0xFFFFE2D9);
  static const surfaceContainerHighest = Color(0xFFFFDBCF);

  // ── Semantic utility colours ─────────────────────────────────────────────
  /// Used for error states and danger buttons (sign-out, exit).
  static const danger = Color(0xFFBA1A1A);

  /// Amber/warning tone — used in ReliabilityBanner "Review needed".
  static const warning = Color(0xFF805200);

  /// Calm green for positive/success states.
  static const success = Color(0xFF006A63);

  // ── Indicator colours (non-alarming, accessible) ─────────────────────────
  /// Low: calm mint-teal.
  static const indicatorLow = Color(0xFF006A63);
  static const indicatorLowBg = Color(0xFF8BF1E6);

  /// Moderate: warm amber.
  static const indicatorModerate = Color(0xFF805200);
  static const indicatorModerateBg = Color(0xFFFFDDB4);

  /// High: soft red.
  static const indicatorHigh = Color(0xFFBA1A1A);
  static const indicatorHighBg = Color(0xFFFFDAD6);

  /// Inconclusive: neutral purple-grey.
  static const indicatorNone = Color(0xFF4F434F);
  static const indicatorNoneBg = Color(0xFFD2C2D0);

  // ── Domain colours ───────────────────────────────────────────────────────
  /// Literacy: soft sky blue / periwinkle.
  static const literacy = Color(0xFF5C9EAD);
  static const literacyBg = Color(0xFFD8F0F5);

  /// Numeracy: fresh mint green / pastel yellow-green.
  static const numeracy = Color(0xFF4DAD7F);
  static const numeracyBg = Color(0xFFD8F5EA);

  /// Attention-related task behaviour: warm coral / soft orange.
  static const attention = Color(0xFFF08A5D);
  static const attentionBg = Color(0xFFFDE8D8);

  // ── Pastel decorative tones (onboarding slides, cards) ───────────────────
  static const pastelBlue = Color(0xFFFFF1EC);
  static const pastelGreen = Color(0xFFFFE9E3);
  static const pastelYellow = Color(0xFFFFE2D9);
  static const pastelCoral = Color(0xFFFFDBCF);
  static const pastelLavender = Color(0xFFFED6FF);
}

// ─── Spacing & Radius tokens ──────────────────────────────────────────────────
class MeekzSpacing {
  MeekzSpacing._();
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 30.0;
  static const xxl = 44.0;
}

class MeekzRadius {
  MeekzRadius._();
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const pill = 9999.0;
}

// ─── Theme builder ────────────────────────────────────────────────────────────
ThemeData buildMeekzTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MeekzColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: MeekzColors.primary,
      onPrimary: Colors.white,
      secondary: MeekzColors.secondary,
      surface: MeekzColors.surface,
      onSurface: MeekzColors.ink,
      outline: MeekzColors.border,
    ),
    scaffoldBackgroundColor: MeekzColors.background,
  );

  return base.copyWith(
    textTheme: GoogleFonts.quicksandTextTheme(base.textTheme).copyWith(
      // Body text uses Quicksand for a soft, rounded child-friendly tone.
      bodyMedium: GoogleFonts.quicksand(
        fontSize: 15,
        color: MeekzColors.ink,
      ),
      bodySmall: GoogleFonts.quicksand(
        fontSize: 13,
        color: MeekzColors.muted,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: MeekzColors.background,
      foregroundColor: MeekzColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.quicksand(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: MeekzColors.ink,
      ),
      iconTheme: const IconThemeData(color: MeekzColors.ink),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MeekzColors.primary,
        foregroundColor: Colors.white,
        // 56 px height — accessible large touch target for children and adults.
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeekzRadius.pill)),
        textStyle: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MeekzColors.primary,
        minimumSize: const Size(double.infinity, 56),
        side: const BorderSide(color: MeekzColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeekzRadius.pill)),
        textStyle: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MeekzColors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeekzRadius.md),
        borderSide: const BorderSide(color: MeekzColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeekzRadius.md),
        borderSide: const BorderSide(color: MeekzColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeekzRadius.md),
        borderSide: const BorderSide(color: MeekzColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeekzRadius.md),
        borderSide: const BorderSide(color: MeekzColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeekzRadius.md),
        borderSide: const BorderSide(color: MeekzColors.danger, width: 2),
      ),
      labelStyle: GoogleFonts.quicksand(color: MeekzColors.muted, fontSize: 14),
      hintStyle: GoogleFonts.quicksand(color: MeekzColors.muted, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: MeekzColors.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MeekzRadius.xl),
        side: const BorderSide(color: MeekzColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: MeekzColors.border,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeekzRadius.md)),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return MeekzColors.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: MeekzColors.border, width: 1.5),
    ),
  );
}
