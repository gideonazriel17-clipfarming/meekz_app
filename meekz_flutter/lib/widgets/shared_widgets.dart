import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_enums.dart';
import 'meekz_theme.dart';

// ─── MeekzButton ─────────────────────────────────────────────────────────────
enum MeekzButtonVariant { primary, secondary, danger, ghost }

class MeekzButton extends StatelessWidget {
  const MeekzButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MeekzButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final MeekzButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (variant == MeekzButtonVariant.secondary) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      );
    }

    Color bg;
    Color fg;
    switch (variant) {
      case MeekzButtonVariant.danger:
        bg = MeekzColors.danger;
        fg = Colors.white;
        break;
      case MeekzButtonVariant.ghost:
        bg = Colors.transparent;
        fg = MeekzColors.primary;
        break;
      default:
        bg = MeekzColors.primary;
        fg = Colors.white;
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        // 56 px — large accessible touch target for children.
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeekzRadius.pill)),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: fg,
              ),
            )
          : Text(
              label,
              style: GoogleFonts.quicksand(
                  fontSize: 16, fontWeight: FontWeight.w700, color: fg),
            ),
    );
  }
}

// ─── IndicatorPill ───────────────────────────────────────────────────────────
// Labels are always text-visible so colour is never the sole status signal.
class IndicatorPill extends StatelessWidget {
  const IndicatorPill({super.key, required this.indicator});

  final IndicatorLevel indicator;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg, icon) = switch (indicator) {
      IndicatorLevel.low => (
          'Low',
          MeekzColors.indicatorLow,
          MeekzColors.indicatorLowBg,
          Icons.check_circle_outline_rounded,
        ),
      IndicatorLevel.moderate => (
          'Moderate',
          MeekzColors.indicatorModerate,
          MeekzColors.indicatorModerateBg,
          Icons.info_outline_rounded,
        ),
      IndicatorLevel.high => (
          'High',
          MeekzColors.indicatorHigh,
          MeekzColors.indicatorHighBg,
          Icons.warning_amber_rounded,
        ),
      IndicatorLevel.inconclusive => (
          'Inconclusive',
          MeekzColors.indicatorNone,
          MeekzColors.indicatorNoneBg,
          Icons.help_outline_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MeekzRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DomainChip ──────────────────────────────────────────────────────────────
// Emojis used as decorative support only — text label always present.
// Domain colours: Literacy=blue, Numeracy=green, Attention=coral.
class DomainChip extends StatelessWidget {
  const DomainChip({super.key, required this.domain});

  final ScreeningDomain domain;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg, emoji) = switch (domain) {
      ScreeningDomain.literacy => (
          'Literacy',
          MeekzColors.literacy,
          MeekzColors.literacyBg,
          '📚',
        ),
      ScreeningDomain.numeracy => (
          'Numeracy',
          MeekzColors.numeracy,
          MeekzColors.numeracyBg,
          '🔢',
        ),
      ScreeningDomain.attention => (
          'Attention',
          MeekzColors.attention,
          MeekzColors.attentionBg,
          '🎯',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MeekzRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MeekzCard ───────────────────────────────────────────────────────────────
// Rounded, soft-shadow card — the primary content container.
class MeekzCard extends StatelessWidget {
  const MeekzCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? MeekzColors.surface,
      borderRadius: BorderRadius.circular(MeekzRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MeekzRadius.xl),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MeekzRadius.xl),
            border: Border.all(color: MeekzColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E2D2A).withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── SectionHeader ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: MeekzColors.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    color: MeekzColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── MeekzTextField ──────────────────────────────────────────────────────────
class MeekzTextField extends StatelessWidget {
  const MeekzTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: GoogleFonts.quicksand(fontSize: 15, color: MeekzColors.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        counterText: '',
      ),
    );
  }
}

// ─── DisclaimerBanner ────────────────────────────────────────────────────────
// Styled clearly but not alarmingly. Warm cream background, amber icon.
// The exact disclaimer text is always passed from cls.disclaimer — never
// hardcoded here, to preserve the single source of truth.
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MeekzColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(MeekzRadius.lg),
        border: Border.all(
            color: MeekzColors.warning.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: MeekzColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.quicksand(
                fontSize: 12,
                color: MeekzColors.warning,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ReliabilityBanner ───────────────────────────────────────────────────────
// Adult-facing labels: "Incomplete" (invalid) / "Review needed" (caution).
// Valid flag renders nothing — no unnecessary noise for parents.
class ReliabilityBanner extends StatelessWidget {
  const ReliabilityBanner({super.key, required this.flag});

  final ReliabilityFlag flag;

  @override
  Widget build(BuildContext context) {
    if (flag == ReliabilityFlag.valid) return const SizedBox.shrink();

    final (heading, body, color, bg, icon) = flag == ReliabilityFlag.invalid
        ? (
            'Incomplete',
            'Not all domains were completed. This result should be repeated before interpretation.',
            MeekzColors.warning,
            MeekzColors.surfaceContainerLow,
            Icons.hourglass_empty_rounded,
          )
        : (
            'Review needed',
            'Some task patterns may have affected reliability. Consider repeating the activities.',
            MeekzColors.warning,
            MeekzColors.surfaceContainerLow,
            Icons.refresh_rounded,
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MeekzRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    color: color,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LoadingBody ─────────────────────────────────────────────────────────────
class LoadingBody extends StatelessWidget {
  const LoadingBody({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: MeekzColors.primary,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 18),
            Text(
              message!,
              style: GoogleFonts.quicksand(color: MeekzColors.muted, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── ErrorBody ───────────────────────────────────────────────────────────────
class ErrorBody extends StatelessWidget {
  const ErrorBody({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MeekzSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MeekzColors.indicatorHighBg,
                borderRadius: BorderRadius.circular(MeekzRadius.xl),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: MeekzColors.danger, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              'Something went wrong',
              style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MeekzColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(color: MeekzColors.muted, fontSize: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: MeekzButton(
                  label: 'Try Again',
                  onPressed: onRetry,
                  icon: Icons.refresh_rounded,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
