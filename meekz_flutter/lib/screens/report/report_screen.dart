import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/app_enums.dart';
import '../../models/risk_classification.dart';
import '../../models/result_summary.dart';
import '../../services/result_summary_service.dart';
import '../../classification/risk_classification_service.dart';
import '../../services/app_providers.dart';
import '../../services/app_router.dart';
import '../../widgets/meekz_theme.dart';
import '../../widgets/shared_widgets.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({
    super.key,
    required this.childId,
    required this.sessionId,
  });

  final String childId;
  final String sessionId;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  RiskClassification? _classification;
  ResultSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) throw Exception('Not signed in');
      final lang = ref.read(selectedLanguageProvider);

      // Get or generate classification
      var classification = await RiskClassificationService()
          .getClassificationForSession(
              userId: uid, sessionId: widget.sessionId);

      classification ??=
          await RiskClassificationService().generateClassification(
        userId: uid,
        sessionId: widget.sessionId,
      );

      // Get or generate template summary
      var summary = await ResultSummaryService()
          .getSummaryForSession(userId: uid, sessionId: widget.sessionId);

      summary ??= await ResultSummaryService().generateTemplateSummary(
        userId: uid,
        sessionId: widget.sessionId,
        classificationId: classification.classificationId,
        language: lang,
      );

      setState(() {
        _classification = classification;
        _summary = summary;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingBody(message: 'Generating report…'));
    }
    if (_error != null) {
      return Scaffold(body: ErrorBody(message: _error!, onRetry: _load));
    }

    final cls = _classification!;
    final summary = _summary!;

    return Scaffold(
      backgroundColor: MeekzColors.background,
      appBar: AppBar(
        title: const Text('Screening Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(MeekzRoutes.dashboard),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
        children: [
          const SizedBox(height: 20),

          // ── Overall indicator banner ───────────────────────────────────
          _OverallBanner(classification: cls),
          const SizedBox(height: 16),

          // ── Reliability notice ────────────────────────────────
          ReliabilityBanner(flag: cls.reliabilityFlag),
          const SizedBox(height: 16),

          // ── Domain breakdown ──────────────────────────────────────────
          SectionHeader(
            title: 'Domain Indicators',
            subtitle: 'Based on completed activities',
          ),
          const SizedBox(height: 14),
          _DomainBreakdown(classification: cls),
          const SizedBox(height: 24),

          // ── Summary ───────────────────────────────────────────────────
          SectionHeader(title: 'What the results suggest'),
          const SizedBox(height: 12),
          MeekzCard(
            child: Text(
              summary.explanationText,
              style: GoogleFonts.quicksand(
                fontSize: 15,
                color: MeekzColors.ink,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Recommendations ───────────────────────────────────────────
          SectionHeader(title: 'Recommended next steps'),
          const SizedBox(height: 12),
          MeekzCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: MeekzColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    summary.recommendationText,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      color: MeekzColors.ink,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Generation date ───────────────────────────────────────────
          if (summary.createdAt != null)
            Center(
              child: Text(
                'Generated on ${DateFormat('d MMM yyyy').format(summary.createdAt!)}',
                style:
                    GoogleFonts.quicksand(fontSize: 12, color: MeekzColors.muted),
              ),
            ),
          const SizedBox(height: 24),

          // ── Disclaimer (always visible) ───────────────────────────────
          DisclaimerBanner(text: cls.disclaimer),
          const SizedBox(height: 28),

          // ── Actions ───────────────────────────────────────────────────
          MeekzButton(
            label: 'Back to Dashboard',
            onPressed: () => context.go(MeekzRoutes.dashboard),
            variant: MeekzButtonVariant.secondary,
            icon: Icons.home_rounded,
          ),
        ],
      ),
    );
  }
}

// ─── Overall indicator banner ─────────────────────────────────────────────────
class _OverallBanner extends StatelessWidget {
  const _OverallBanner({required this.classification});
  final RiskClassification classification;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg, icon) = switch (classification.overallIndicator) {
      IndicatorLevel.low => (
          'Low Indicator',
          MeekzColors.indicatorLow,
          MeekzColors.indicatorLowBg,
          Icons.check_circle_outline_rounded,
        ),
      IndicatorLevel.moderate => (
          'Moderate Indicator',
          MeekzColors.indicatorModerate,
          MeekzColors.indicatorModerateBg,
          Icons.info_outline_rounded,
        ),
      IndicatorLevel.high => (
          'High Indicator',
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall',
                  style: GoogleFonts.quicksand(
                      fontSize: 12, color: color, fontWeight: FontWeight.w600),
                ),
                Text(
                  label,
                  style: GoogleFonts.quicksand(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
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

// ─── Domain breakdown ─────────────────────────────────────────────────────────
class _DomainBreakdown extends StatelessWidget {
  const _DomainBreakdown({required this.classification});
  final RiskClassification classification;

  @override
  Widget build(BuildContext context) {
    final domains = [
      (
        ScreeningDomain.literacy,
        classification.literacyIndicator,
        '📚 Literacy',
        MeekzColors.literacy,
        MeekzColors.literacyBg,
      ),
      (
        ScreeningDomain.numeracy,
        classification.numeracyIndicator,
        '🔢 Numeracy',
        MeekzColors.numeracy,
        MeekzColors.numeracyBg,
      ),
      (
        ScreeningDomain.attention,
        classification.attentionIndicator,
        '🎯 Attention',
        MeekzColors.attention,
        MeekzColors.attentionBg,
      ),
    ];

    return Column(
      children: domains.map((entry) {
        final (domain, indicator, label, color, bg) = entry;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MeekzColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MeekzColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(
                      label.split(' ')[0],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label.split(' ').sublist(1).join(' '),
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MeekzColors.ink,
                    ),
                  ),
                ),
                IndicatorPill(indicator: indicator),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
