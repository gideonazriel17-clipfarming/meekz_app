import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_enums.dart';
import '../../services/game_result_service.dart';
import '../../services/screening_session_service.dart';
import '../../classification/risk_classification_service.dart';
import '../../services/app_providers.dart';
import '../../widgets/meekz_theme.dart';
import '../../widgets/shared_widgets.dart';

// ─── Inline game question data (mirrors the RN prototype game data) ─────────
class _Question {
  const _Question({
    required this.id,
    required this.prompt,
    required this.visual,
    required this.options,
    required this.correctOption,
    this.isRepeated = false,
  });

  final String id;
  final String prompt;
  final String visual;
  final List<String> options;
  final String correctOption;
  final bool isRepeated;
}

class _Answer {
  const _Answer({
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.skipped,
  });

  final String questionId;
  final String? selectedOption;
  final bool isCorrect;
  final int responseTimeMs;
  final bool skipped;
}

// Minimal game datasets per domain — sufficient to compute all backend metrics
List<_Question> _questionsFor(ScreeningDomain domain) {
  switch (domain) {
    case ScreeningDomain.literacy:
      return [
        const _Question(
          id: 'l1',
          prompt: 'Which letter makes the /b/ sound?',
          visual: 'b   d   p   q',
          options: ['b', 'd', 'p', 'q'],
          correctOption: 'b',
        ),
        const _Question(
          id: 'l2',
          prompt: 'Which word rhymes with "cat"?',
          visual: '🐱',
          options: ['bat', 'cup', 'dog', 'sun'],
          correctOption: 'bat',
        ),
        const _Question(
          id: 'l3',
          prompt: 'Which letter is different from the others?',
          visual: 'b   b   d   b',
          options: ['1st b', '2nd b', 'd', '4th b'],
          correctOption: 'd',
        ),
        const _Question(
          id: 'l4',
          prompt: 'Point to the letter "p"',
          visual: 'b   p   d   q',
          options: ['b', 'p', 'd', 'q'],
          correctOption: 'p',
        ),
        const _Question(
          id: 'l5',
          prompt: 'Which word starts with the /s/ sound?',
          visual: '🌞 🐕 🌊 🍎',
          options: ['sun', 'dog', 'apple', 'moon'],
          correctOption: 'sun',
        ),
        const _Question(
          id: 'l1r',
          prompt: 'Which letter makes the /b/ sound?',
          visual: 'b   d   p   q',
          options: ['b', 'd', 'p', 'q'],
          correctOption: 'b',
          isRepeated: true,
        ),
      ];

    case ScreeningDomain.numeracy:
      return [
        const _Question(
          id: 'n1',
          prompt: 'How many stars are there?',
          visual: '⭐ ⭐ ⭐',
          options: ['2', '3', '4', '5'],
          correctOption: '3',
        ),
        const _Question(
          id: 'n2',
          prompt: 'What comes after 5?',
          visual: '5 → ?',
          options: ['4', '6', '7', '8'],
          correctOption: '6',
        ),
        const _Question(
          id: 'n3',
          prompt: 'Which group has more?',
          visual: '🍎🍎🍎  vs  🍊🍊',
          options: ['Apples', 'Oranges', 'Same'],
          correctOption: 'Apples',
        ),
        const _Question(
          id: 'n4',
          prompt: '2 + 3 = ?',
          visual: '🌟🌟 + 🌟🌟🌟',
          options: ['4', '5', '6', '7'],
          correctOption: '5',
        ),
        const _Question(
          id: 'n5',
          prompt: 'Which number is the biggest?',
          visual: '7   3   9   1',
          options: ['7', '3', '9', '1'],
          correctOption: '9',
        ),
        const _Question(
          id: 'n1r',
          prompt: 'How many stars are there?',
          visual: '⭐ ⭐ ⭐',
          options: ['2', '3', '4', '5'],
          correctOption: '3',
          isRepeated: true,
        ),
      ];

    case ScreeningDomain.attention:
      return [
        const _Question(
          id: 'a1',
          prompt: 'Tap the RED shape',
          visual: '🔵 🔴 🟡 🟢',
          options: ['Blue', 'Red', 'Yellow', 'Green'],
          correctOption: 'Red',
        ),
        const _Question(
          id: 'a2',
          prompt: 'Which animal is different?',
          visual: '🐱 🐱 🐶 🐱',
          options: ['1st cat', '2nd cat', 'dog', '4th cat'],
          correctOption: 'dog',
        ),
        const _Question(
          id: 'a3',
          prompt: 'Tap the shape that does NOT belong',
          visual: '🔺 🔺 🔺 ⬜',
          options: ['Triangle 1', 'Triangle 2', 'Triangle 3', 'Square'],
          correctOption: 'Square',
        ),
        const _Question(
          id: 'a4',
          prompt: 'What colour is missing? 🟦 🟥 __ 🟩',
          visual: 'Blue, Red, ?, Green',
          options: ['Blue', 'Yellow', 'Red', 'Green'],
          correctOption: 'Yellow',
        ),
        const _Question(
          id: 'a5',
          prompt: 'Tap when you see a star ⭐',
          visual: '🌙   ⭐   ☁️   ⭐',
          options: ['Moon', 'Star', 'Cloud', 'No star'],
          correctOption: 'Star',
        ),
        const _Question(
          id: 'a1r',
          prompt: 'Tap the RED shape',
          visual: '🔵 🔴 🟡 🟢',
          options: ['Blue', 'Red', 'Yellow', 'Green'],
          correctOption: 'Red',
          isRepeated: true,
        ),
      ];
  }
}

// ─── Game Screen ─────────────────────────────────────────────────────────────
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    required this.childId,
    required this.sessionId,
    required this.domain,
  });

  final String childId;
  final String sessionId;
  final String domain;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late final List<_Question> _questions;
  late final ScreeningDomain _domain;
  final List<_Answer> _answers = [];

  int _index = 0;
  bool _hasStarted = false;
  bool _submitting = false;

  DateTime? _questionStartedAt;
  int _inactivityCount = 0;
  Timer? _inactivityTimer;

  // Flash animation
  late final AnimationController _flashCtrl;
  bool? _lastAnswerCorrect;

  static const _inactivityThresholdSeconds = 10;

  @override
  void initState() {
    super.initState();
    _domain = ScreeningDomainFirestore.fromValue(widget.domain);
    _questions = _questionsFor(_domain);
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _flashCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _hasStarted = true;
      _questionStartedAt = DateTime.now();
    });
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(
      const Duration(seconds: _inactivityThresholdSeconds),
      () {
        if (mounted) {
          setState(() => _inactivityCount++);
          _startInactivityTimer();
        }
      },
    );
  }

  void _answerQuestion(String? selected) {
    _inactivityTimer?.cancel();
    final now = DateTime.now();
    final responseMs = _questionStartedAt != null
        ? now.difference(_questionStartedAt!).inMilliseconds
        : 0;

    final q = _questions[_index];
    final isCorrect = selected == q.correctOption;
    _answers.add(_Answer(
      questionId: q.id,
      selectedOption: selected,
      isCorrect: isCorrect,
      responseTimeMs: responseMs,
      skipped: selected == null,
    ));

    // Flash feedback
    setState(() => _lastAnswerCorrect = isCorrect);
    Future.delayed(const Duration(milliseconds: 600),
        () => setState(() => _lastAnswerCorrect = null));

    if (_index == _questions.length - 1) {
      _finishGame();
      return;
    }

    setState(() {
      _index++;
      _questionStartedAt = DateTime.now();
    });
    _startInactivityTimer();
  }

  Future<void> _finishGame() async {
    setState(() => _submitting = true);

    try {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) throw Exception('Not signed in');

      // Compute metrics
      final totalQ = _answers.length;
      final correct = _answers.where((a) => a.isCorrect).length;
      final incorrect =
          _answers.where((a) => !a.isCorrect && !a.skipped).length;
      final avgMs = totalQ > 0
          ? (_answers.fold<int>(0, (s, a) => s + a.responseTimeMs) ~/ totalQ)
          : 0;
      final repeatedAnswers = _answers
          .where((a) =>
              _questions.firstWhere((q) => q.id == a.questionId).isRepeated)
          .toList();
      final repeatedErrors = repeatedAnswers.where((a) => !a.isCorrect).length;

      // Identify random response pattern: if first answer same as repeated answer
      final firstAnswers = _answers.where((a) =>
          !_questions.firstWhere((q) => q.id == a.questionId).isRepeated);
      final pairedAnswers = _answers.where(
          (a) => _questions.firstWhere((q) => q.id == a.questionId).isRepeated);

      bool randomFlag = false;
      // Pattern 1: repeated invalid patterns / mismatched original-repeated selections
      for (final rep in pairedAnswers) {
        final originalId = rep.questionId.replaceAll('r', '');
        final original = firstAnswers.where((a) => a.questionId == originalId);
        if (original.isNotEmpty &&
            original.first.selectedOption != rep.selectedOption) {
          randomFlag = true;
          break;
        }
      }

      // Pattern 2: 3 or more responses below 500ms
      final fastAnswersCount =
          _answers.where((a) => a.responseTimeMs < 500).length;
      if (fastAnswersCount >= 3) {
        randomFlag = true;
      }

      // Missed prompts: no response within 8 seconds or manual skips
      final missedPrompts =
          _answers.where((a) => a.skipped || a.responseTimeMs >= 8000).length;

      // Calculate completion rate: completed scorable items / assigned scorable items
      final scorableQuestions = _questions.where((q) => !q.isRepeated).toList();
      final scorableAnswers = _answers.where((a) =>
          !_questions.firstWhere((q) => q.id == a.questionId).isRepeated);
      final scorableCompletedCount = scorableAnswers
          .where((a) => !a.skipped && a.responseTimeMs < 8000)
          .length;
      final scorableTotalCount = scorableQuestions.length;
      final completionRate = scorableTotalCount > 0
          ? scorableCompletedCount / scorableTotalCount
          : 0.0;

      // Calculate consistency score: fraction of repeated questions matching originals
      double consistencyScore = 1.0;
      int matchCount = 0;
      int repeatedCount = pairedAnswers.length;
      for (final rep in pairedAnswers) {
        final originalId = rep.questionId.replaceAll('r', '');
        final original = firstAnswers.where((a) => a.questionId == originalId);
        if (original.isNotEmpty &&
            original.first.selectedOption == rep.selectedOption) {
          matchCount++;
        }
      }
      if (repeatedCount > 0) {
        consistencyScore = matchCount / repeatedCount;
      }

      // Save game result
      final gameResultService = GameResultService();
      await gameResultService.saveGameResult(
        userId: uid,
        sessionId: widget.sessionId,
        childId: widget.childId,
        domain: _domain,
        gameType: _domain.value,
        totalQuestions: totalQ,
        correctAnswers: correct,
        incorrectAnswers: incorrect,
        averageResponseTimeMs: avgMs,
        missedPrompts: missedPrompts,
        inactivityCount: _inactivityCount,
        repeatedErrors: repeatedErrors,
        randomResponseFlag: randomFlag,
        completed: true,
        completionRate: completionRate,
        consistencyScore: consistencyScore,
      );

      // Update session
      final sessionService = ScreeningSessionService();
      final existingSession = await sessionService.getSession(
        userId: uid,
        sessionId: widget.sessionId,
      );
      final updatedDomains =
          {...existingSession.domainsCompleted, _domain}.toList();
      await sessionService.updateDomainsCompleted(
        userId: uid,
        sessionId: widget.sessionId,
        domainsCompleted: updatedDomains,
      );

      // Generate risk classification
      await RiskClassificationService().generateClassification(
        userId: uid,
        sessionId: widget.sessionId,
      );

      if (mounted) {
        context.pop(); // back to assessment menu
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving result: $e'),
          backgroundColor: MeekzColors.danger,
        ));
        setState(() => _submitting = false);
      }
    }
  }

  Color get _domainAccent => switch (_domain) {
        ScreeningDomain.literacy => MeekzColors.literacy,
        ScreeningDomain.numeracy => MeekzColors.numeracy,
        ScreeningDomain.attention => MeekzColors.attention,
      };

  Color get _domainBg => switch (_domain) {
        ScreeningDomain.literacy => MeekzColors.literacyBg,
        ScreeningDomain.numeracy => MeekzColors.numeracyBg,
        ScreeningDomain.attention => MeekzColors.attentionBg,
      };

  String get _domainEmoji => switch (_domain) {
        ScreeningDomain.literacy => '📚',
        ScreeningDomain.numeracy => '🔢',
        ScreeningDomain.attention => '🎯',
      };

  String get _domainLabel => switch (_domain) {
        ScreeningDomain.literacy => 'Literacy',
        ScreeningDomain.numeracy => 'Numeracy',
        ScreeningDomain.attention => 'Attention',
      };

  @override
  Widget build(BuildContext context) {
    if (_submitting) {
      return const Scaffold(body: LoadingBody(message: 'Saving results…'));
    }

    if (!_hasStarted) {
      return _InstructionScreen(
        domain: _domain,
        domainLabel: _domainLabel,
        domainAccent: _domainAccent,
        questionCount: _questions.length,
        onStart: _startGame,
        onBack: () => context.pop(),
      );
    }

    final q = _questions[_index];
    final flashBg = _lastAnswerCorrect == null
        ? MeekzColors.surface
        : (_lastAnswerCorrect!
            ? const Color(0xFFDDF1E2)
            : const Color(0xFFFFE0DE));

    return Scaffold(
      backgroundColor: flashBg,
      appBar: AppBar(
        backgroundColor: flashBg,
        title: Row(
          children: [
            Text(_domainEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('$_domainLabel — Q${_index + 1} / ${_questions.length}'),
          ],
        ),
        leading: const SizedBox.shrink(),
        actions: [
          TextButton(
            onPressed: () => _showExitDialog(),
            child: Text('Exit',
                style: GoogleFonts.quicksand(color: MeekzColors.muted)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Thick domain-coloured progress bar ────────────────────────
          LinearProgressIndicator(
            value: (_index + 1) / _questions.length,
            minHeight: 10,
            backgroundColor: _domainBg,
            valueColor: AlwaysStoppedAnimation(_domainAccent),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // ── Prompt ─────────────────────────────────────────────
                  Text(
                    q.prompt,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: MeekzColors.ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Visual — coloured domain card ─────────────────────
                  Container(
                    constraints: const BoxConstraints(minHeight: 130),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _domainBg,
                      borderRadius: BorderRadius.circular(MeekzRadius.xl),
                      border: Border.all(
                          color: _domainAccent.withValues(alpha: 0.45),
                          width: 2),
                    ),
                    child: Center(
                      child: Text(
                        q.visual,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: MeekzColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Options ────────────────────────────────────────────
                  ...q.options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OptionButton(
                        label: option,
                        accentColor: _domainAccent,
                        onTap: () => _answerQuestion(option),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Skip ───────────────────────────────────────────────
                  TextButton(
                    onPressed: () => _answerQuestion(null),
                    child: Text(
                      'Skip this question',
                      style: GoogleFonts.quicksand(
                          color: MeekzColors.muted, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeekzRadius.xl)),
        title: Text('Exit game?',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w800)),
        content: Text(
          'Progress for this domain will not be saved.',
          style: GoogleFonts.quicksand(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Exit', style: TextStyle(color: MeekzColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) context.pop();
  }
}

class _InstructionScreen extends StatelessWidget {
  const _InstructionScreen({
    required this.domain,
    required this.domainLabel,
    required this.domainAccent,
    required this.questionCount,
    required this.onStart,
    required this.onBack,
  });

  final ScreeningDomain domain;
  final String domainLabel;
  final Color domainAccent;
  final int questionCount;
  final VoidCallback onStart;
  final VoidCallback onBack;

  String get _instructions => switch (domain) {
        ScreeningDomain.literacy =>
          'You will see letters and words. Help the child pick the correct answer by tapping the button. Take your time — there is no rush.',
        ScreeningDomain.numeracy =>
          'You will see numbers and groups of objects. Help the child pick the correct answer. Read each question aloud if needed.',
        ScreeningDomain.attention =>
          'You will see shapes and colours. Ask the child to tap the correct answer as quickly as they can. Watch for hesitation or random tapping.',
      };

  // Background colour behind the instruction screen header card
  Color get _domainBg => switch (domain) {
        ScreeningDomain.literacy => MeekzColors.literacyBg,
        ScreeningDomain.numeracy => MeekzColors.numeracyBg,
        ScreeningDomain.attention => MeekzColors.attentionBg,
      };

  String get _domainEmoji => switch (domain) {
        ScreeningDomain.literacy => '📚',
        ScreeningDomain.numeracy => '🔢',
        ScreeningDomain.attention => '🎯',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeekzColors.background,
      appBar: AppBar(
        title: Text(domainLabel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colourful hero card — catches children's attention
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _domainBg,
                borderRadius: BorderRadius.circular(MeekzRadius.xl),
                border: Border.all(
                    color: domainAccent.withValues(alpha: 0.4), width: 2),
              ),
              child: Column(
                children: [
                  Text(_domainEmoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    'Ready to begin?',
                    style: GoogleFonts.quicksand(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: MeekzColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$questionCount questions · Tap the best answer for the child',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                        fontSize: 13, color: MeekzColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Instructions box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: MeekzColors.surface,
                borderRadius: BorderRadius.circular(MeekzRadius.lg),
                border: Border.all(
                    color: domainAccent.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Text(
                _instructions,
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  color: MeekzColors.ink,
                  height: 1.65,
                ),
              ),
            ),
            const Spacer(),
            MeekzButton(
              label: 'Start Activity',
              onPressed: onStart,
              icon: Icons.play_arrow_rounded,
            ),
            const SizedBox(height: 12),
            MeekzButton(
              label: 'Back',
              onPressed: onBack,
              variant: MeekzButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatefulWidget {
  const _OptionButton({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.reverse(),
      onTapUp: (_) {
        _scaleCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: MeekzColors.surface,
            borderRadius: BorderRadius.circular(MeekzRadius.lg),
            border: Border.all(color: MeekzColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: MeekzColors.ink.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left accent stripe — domain colour always visible
              Container(
                width: 4,
                height: 36,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: MeekzColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
