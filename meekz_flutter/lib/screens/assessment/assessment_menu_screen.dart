import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_enums.dart';
import '../../models/risk_classification.dart';
import '../../models/screening_session.dart';
import '../../classification/risk_classification_service.dart';
import '../../services/screening_session_service.dart';
import '../../services/app_providers.dart';
import '../../services/app_router.dart';
import '../../widgets/meekz_theme.dart';
import '../../widgets/shared_widgets.dart';

class AssessmentMenuScreen extends ConsumerStatefulWidget {
  const AssessmentMenuScreen({
    super.key,
    required this.childId,
    required this.sessionId,
  });

  final String childId;
  final String sessionId;

  @override
  ConsumerState<AssessmentMenuScreen> createState() =>
      _AssessmentMenuScreenState();
}

class _AssessmentMenuScreenState extends ConsumerState<AssessmentMenuScreen> {
  ScreeningSession? _session;
  RiskClassification? _classification;
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

      final session = await ScreeningSessionService().getSession(
        userId: uid,
        sessionId: widget.sessionId,
      );
      RiskClassification? classification;
      try {
        classification =
            await RiskClassificationService().getClassificationForSession(
          userId: uid,
          sessionId: widget.sessionId,
        );
      } catch (_) {
        // No classification yet — that's fine
      }

      setState(() {
        _session = session;
        _classification = classification;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeSession() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    try {
      await ScreeningSessionService().completeSession(
        userId: uid,
        sessionId: widget.sessionId,
      );
      if (mounted) {
        context.pushReplacement(
          MeekzRoutes.report
              .replaceAll(':childId', widget.childId)
              .replaceAll(':sessionId', widget.sessionId),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: MeekzColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingBody(message: 'Loading session…'));
    }
    if (_error != null) {
      return Scaffold(body: ErrorBody(message: _error!, onRetry: _load));
    }

    final session = _session!;
    final completed = session.domainsCompleted;
    final allDone = completed.length == ScreeningDomain.values.length;

    return Scaffold(
      backgroundColor: MeekzColors.background,
      appBar: AppBar(
        title: const Text('Assessment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(MeekzRoutes.dashboard),
        ),
        actions: [
          TextButton(
            onPressed: () => _abandonSession(),
            child: Text(
              'Exit',
              style: GoogleFonts.quicksand(
                  color: MeekzColors.danger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // ── Progress overview ──────────────────────────────────────────
          _ProgressHeader(
              completed: completed.length,
              total: ScreeningDomain.values.length),
          const SizedBox(height: 24),

          SectionHeader(
            title: 'Screening Domains',
            subtitle:
                'Complete all three activities to generate a full report.',
          ),
          const SizedBox(height: 16),

          // ── Domain cards ───────────────────────────────────────────────
          ...ScreeningDomain.values.map((domain) {
            final isDone = completed.contains(domain);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DomainCard(
                domain: domain,
                isDone: isDone,
                classification: _classification,
                onStart: () => _startGame(domain),
                onRedo: () => _startGame(domain),
              ),
            );
          }),

          const SizedBox(height: 16),

          // ── View Report CTA ────────────────────────────────────────────
          AnimatedOpacity(
            opacity: allDone ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: MeekzButton(
              label: 'View Full Report',
              onPressed: allDone ? _completeSession : null,
              icon: Icons.bar_chart_rounded,
            ),
          ),

          if (!allDone) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                '${ScreeningDomain.values.length - completed.length} domain(s) remaining',
                style:
                    GoogleFonts.quicksand(fontSize: 13, color: MeekzColors.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _startGame(ScreeningDomain domain) async {
    await context.push(
      MeekzRoutes.game
          .replaceAll(':childId', widget.childId)
          .replaceAll(':sessionId', widget.sessionId)
          .replaceAll(':domain', domain.value),
    );
    if (mounted) {
      _load();
    }
  }

  Future<void> _abandonSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeekzRadius.xl)),
        title: Text('Exit session?',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w800)),
        content: Text(
          'Progress will be saved, but this session will be closed. You can start a new session later.',
          style: GoogleFonts.quicksand(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Exit', style: TextStyle(color: MeekzColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid != null) {
        await ScreeningSessionService()
            .markSessionInvalid(userId: uid, sessionId: widget.sessionId);
      }
      if (mounted) context.go(MeekzRoutes.dashboard);
    }
  }
}

// ─── Progress header ──────────────────────────────────────────────────────────
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.completed, required this.total});
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = completed / total;
    // Colour the progress bar based on how far along the child is.
    final barColor = completed == total
        ? MeekzColors.indicatorLow
        : completed == 0
            ? MeekzColors.attention
            : MeekzColors.secondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Warm gradient matches the brand header on dashboard.
        gradient: LinearGradient(
          colors: [
            MeekzColors.primary.withValues(alpha: 0.90),
            MeekzColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MeekzRadius.xl),
        boxShadow: [
          BoxShadow(
            color: MeekzColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$completed of $total domains completed',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: GoogleFonts.quicksand(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Domain card ──────────────────────────────────────────────────────────────
class _DomainCard extends StatelessWidget {
  const _DomainCard({
    required this.domain,
    required this.isDone,
    required this.onStart,
    required this.onRedo,
    this.classification,
  });

  final ScreeningDomain domain;
  final bool isDone;
  final VoidCallback onStart;
  final VoidCallback onRedo;
  final RiskClassification? classification;

  String get _domainEmoji => switch (domain) {
        ScreeningDomain.literacy => '📚',
        ScreeningDomain.numeracy => '🔢',
        ScreeningDomain.attention => '🎯',
      };

  String get _domainLabel => switch (domain) {
        ScreeningDomain.literacy => 'Literacy',
        ScreeningDomain.numeracy => 'Numeracy',
        ScreeningDomain.attention => 'Attention',
      };

  String get _domainDescription => switch (domain) {
        ScreeningDomain.literacy =>
          'Reading patterns, phonics awareness, and letter recognition.',
        ScreeningDomain.numeracy =>
          'Number sense, counting, and basic arithmetic.',
        ScreeningDomain.attention =>
          'Sustained focus, impulse control, and task consistency.',
      };

  Color get _accentColor => switch (domain) {
        ScreeningDomain.literacy => MeekzColors.literacy,
        ScreeningDomain.numeracy => MeekzColors.numeracy,
        ScreeningDomain.attention => MeekzColors.attention,
      };

  Color get _accentBg => switch (domain) {
        ScreeningDomain.literacy => MeekzColors.literacyBg,
        ScreeningDomain.numeracy => MeekzColors.numeracyBg,
        ScreeningDomain.attention => MeekzColors.attentionBg,
      };

  IndicatorLevel? get _indicator => switch (domain) {
        ScreeningDomain.literacy => classification?.literacyIndicator,
        ScreeningDomain.numeracy => classification?.numeracyIndicator,
        ScreeningDomain.attention => classification?.attentionIndicator,
      };

  @override
  Widget build(BuildContext context) {
    return MeekzCard(
      child: Row(
        children: [
          // Coloured domain icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _accentBg,
              borderRadius: BorderRadius.circular(MeekzRadius.lg),
              border: Border.all(color: _accentColor.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(_domainEmoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),

          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _domainLabel,
                      style: GoogleFonts.quicksand(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: MeekzColors.ink,
                      ),
                    ),
                    if (isDone) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded,
                          color: MeekzColors.success, size: 17),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _domainDescription,
                  style: GoogleFonts.quicksand(
                      fontSize: 12, color: MeekzColors.muted, height: 1.4),
                ),
                if (isDone && _indicator != null) ...[
                  const SizedBox(height: 8),
                  IndicatorPill(indicator: _indicator!),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          // CTA button — uses domain accent when not done
          ElevatedButton(
            onPressed: isDone ? onRedo : onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDone ? _accentBg : _accentColor,
              foregroundColor: isDone ? _accentColor : Colors.white,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MeekzRadius.md),
                side: isDone
                    ? BorderSide(color: _accentColor, width: 1.5)
                    : BorderSide.none,
              ),
              elevation: 0,
            ),
            child: Text(
              isDone ? 'Redo' : 'Start',
              style:
                  GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
