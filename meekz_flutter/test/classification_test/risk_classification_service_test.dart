import 'package:flutter_test/flutter_test.dart';
import 'package:meekz/meekz_backend.dart';

void main() {
  GameResult result({
    required ScreeningDomain domain,
    required double accuracy,
    bool completed = true,
    int missedPrompts = 0,
    int inactivityCount = 0,
    int repeatedErrors = 0,
    bool randomResponseFlag = false,
    int totalQuestions = 10,
  }) {
    final correctAnswers = (totalQuestions * accuracy).round();

    return GameResult(
      resultId: '${domain.value}_result',
      sessionId: 'session_1',
      childId: 'child_1',
      userId: 'user_1',
      domain: domain,
      gameType: '${domain.value}_prototype_task',
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      incorrectAnswers: totalQuestions - correctAnswers,
      accuracy: accuracy,
      averageResponseTimeMs: 2500,
      missedPrompts: missedPrompts,
      inactivityCount: inactivityCount,
      repeatedErrors: repeatedErrors,
      randomResponseFlag: randomResponseFlag,
      completed: completed,
      createdAt: DateTime.utc(2026),
    );
  }

  // ── Chapter 3 point-based scoring ─────────────────────────────────────────

  group('Chapter 3 point-based scoring model', () {
    test('stable low case: all domains >= 80% accuracy, no flags → low + valid',
        () {
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(domain: ScreeningDomain.literacy, accuracy: 0.9),
          result(domain: ScreeningDomain.numeracy, accuracy: 0.8),
          result(domain: ScreeningDomain.attention, accuracy: 1.0),
        ],
      );

      expect(draft.literacyIndicator, IndicatorLevel.low);
      expect(draft.numeracyIndicator, IndicatorLevel.low);
      expect(draft.attentionIndicator, IndicatorLevel.low);
      expect(draft.overallIndicator, IndicatorLevel.low);
      expect(draft.reliabilityFlag, ReliabilityFlag.valid);
      expect(draft.reasonCodes, contains('CHAPTER_3_POINT_BASED_SCORING'));
    });

    test('70% accuracy alone gives 1 accuracy point → remains low', () {
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(domain: ScreeningDomain.literacy, accuracy: 0.7),
          result(domain: ScreeningDomain.numeracy, accuracy: 0.85),
          result(domain: ScreeningDomain.attention, accuracy: 0.9),
        ],
      );

      // 70% accuracy → 1 pt (ACCURACY_MODERATE), total 1 pt → low
      expect(draft.literacyIndicator, IndicatorLevel.low);
      expect(draft.overallIndicator, IndicatorLevel.low);
      expect(draft.reasonCodes, contains('ACCURACY_MODERATE'));
    });

    test('moderate case: 3–5 point total produces moderate indicator', () {
      // 50% accuracy → 2 pts (ACCURACY_LOW) + 2 missed prompts → 1 pt = 3 pts
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(
            domain: ScreeningDomain.literacy,
            accuracy: 0.5,
            missedPrompts: 2,
          ),
          result(domain: ScreeningDomain.numeracy, accuracy: 0.9),
          result(domain: ScreeningDomain.attention, accuracy: 0.9),
        ],
      );

      expect(draft.literacyIndicator, IndicatorLevel.moderate);
      expect(draft.overallIndicator, IndicatorLevel.moderate);
      expect(draft.reasonCodes, contains('ACCURACY_LOW'));
      expect(draft.reasonCodes, contains('MISSED_PROMPTS_MODERATE'));
    });

    test('high case: 6 or more points produces high indicator', () {
      // 30% accuracy → 3 pts + randomResponseFlag → 2+2 = 4 pts = 7 pts total
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(
            domain: ScreeningDomain.literacy,
            accuracy: 0.3,
            randomResponseFlag: true,
          ),
          result(domain: ScreeningDomain.numeracy, accuracy: 0.9),
          result(domain: ScreeningDomain.attention, accuracy: 0.9),
        ],
      );

      expect(draft.literacyIndicator, IndicatorLevel.high);
      expect(draft.overallIndicator, IndicatorLevel.high);
      expect(draft.reliabilityFlag, ReliabilityFlag.caution);
      expect(draft.reasonCodes, contains('ACCURACY_VERY_LOW'));
      expect(draft.reasonCodes, contains('RANDOM_RESPONSE_PATTERN'));
    });

    test('randomResponseFlag alone produces 4 points → moderate, not high', () {
      // 90% accuracy → 0 pts + randomResponseFlag → 2 consistency + 2 random
      // total 4 pts → moderate
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(
            domain: ScreeningDomain.attention,
            accuracy: 0.9,
            randomResponseFlag: true,
          ),
          result(domain: ScreeningDomain.literacy, accuracy: 0.9),
          result(domain: ScreeningDomain.numeracy, accuracy: 0.9),
        ],
      );

      expect(draft.attentionIndicator, IndicatorLevel.moderate);
      expect(draft.attentionIndicator, isNot(IndicatorLevel.high));
      expect(draft.overallIndicator, IndicatorLevel.moderate);
      expect(draft.reliabilityFlag, ReliabilityFlag.caution);
      expect(draft.reasonCodes, contains('CONSISTENCY_LOW'));
      expect(draft.reasonCodes, contains('RANDOM_RESPONSE_PATTERN'));
    });

    test('missing required domains produce inconclusive + caution', () {
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(domain: ScreeningDomain.literacy, accuracy: 0.8),
        ],
      );

      expect(draft.literacyIndicator, IndicatorLevel.low);
      expect(draft.numeracyIndicator, IndicatorLevel.inconclusive);
      expect(draft.attentionIndicator, IndicatorLevel.inconclusive);
      expect(draft.reliabilityFlag, ReliabilityFlag.caution);
      expect(draft.reasonCodes, contains('PARTIAL_SCREENING_RESULT'));
      expect(draft.reasonCodes, contains('DOMAIN_NOT_ASSESSED'));
    });
  });

  // ── Overall aggregation rules ─────────────────────────────────────────────

  group('Overall aggregation rules', () {
    test('any high domain → overall high', () {
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(
            domain: ScreeningDomain.literacy,
            accuracy: 0.3,
            randomResponseFlag: true,
          ),
          result(domain: ScreeningDomain.numeracy, accuracy: 0.9),
          result(domain: ScreeningDomain.attention, accuracy: 0.9),
        ],
      );

      expect(draft.literacyIndicator, IndicatorLevel.high);
      expect(draft.overallIndicator, IndicatorLevel.high);
    });

    test('two or more moderate domains → overall moderate', () {
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(
            domain: ScreeningDomain.literacy,
            accuracy: 0.5,
            missedPrompts: 2,
          ),
          result(
            domain: ScreeningDomain.numeracy,
            accuracy: 0.5,
            missedPrompts: 2,
          ),
          result(domain: ScreeningDomain.attention, accuracy: 0.9),
        ],
      );

      expect(draft.literacyIndicator, IndicatorLevel.moderate);
      expect(draft.numeracyIndicator, IndicatorLevel.moderate);
      expect(draft.overallIndicator, IndicatorLevel.moderate);
    });

    test('all low domains → overall low', () {
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(domain: ScreeningDomain.literacy, accuracy: 0.9),
          result(domain: ScreeningDomain.numeracy, accuracy: 0.85),
          result(domain: ScreeningDomain.attention, accuracy: 0.95),
        ],
      );

      expect(draft.literacyIndicator, IndicatorLevel.low);
      expect(draft.numeracyIndicator, IndicatorLevel.low);
      expect(draft.attentionIndicator, IndicatorLevel.low);
      expect(draft.overallIndicator, IndicatorLevel.low);
    });

    test('inconclusive required domain → reliability caution', () {
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(domain: ScreeningDomain.literacy, accuracy: 0.9),
          result(domain: ScreeningDomain.numeracy, accuracy: 0.9),
        ],
      );

      expect(draft.attentionIndicator, IndicatorLevel.inconclusive);
      expect(draft.reliabilityFlag, ReliabilityFlag.caution);
      expect(draft.reasonCodes, contains('PARTIAL_SCREENING_RESULT'));
      expect(draft.reasonCodes, contains('DOMAIN_NOT_ASSESSED'));
    });
  });

  // ── Reliability flag mapping ──────────────────────────────────────────────

  group('Reliability flag mapping', () {
    test('all domains complete and stable → valid + completed status', () {
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(domain: ScreeningDomain.literacy, accuracy: 0.9),
          result(domain: ScreeningDomain.numeracy, accuracy: 0.9),
          result(domain: ScreeningDomain.attention, accuracy: 0.9),
        ],
      );

      expect(draft.reliabilityFlag, ReliabilityFlag.valid);
      expect(
        RiskClassificationService.recommendedSessionStatusFor(
          draft.reliabilityFlag,
        ),
        ScreeningSessionStatus.completed,
      );
    });

    test('review patterns → caution + repeat recommended status', () {
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(
            domain: ScreeningDomain.literacy,
            accuracy: 0.9,
            randomResponseFlag: true,
          ),
          result(domain: ScreeningDomain.numeracy, accuracy: 0.9),
          result(domain: ScreeningDomain.attention, accuracy: 0.9),
        ],
      );

      expect(draft.reliabilityFlag, ReliabilityFlag.caution);
      expect(
        RiskClassificationService.recommendedSessionStatusFor(
          draft.reliabilityFlag,
        ),
        ScreeningSessionStatus.repeatRecommended,
      );
    });

    test('missing domains → caution + PARTIAL_SCREENING_RESULT', () {
      final draft = RiskClassificationService.calculateClassification(
        userId: 'user_1',
        childId: 'child_1',
        sessionId: 'session_1',
        gameResults: [
          result(domain: ScreeningDomain.literacy, accuracy: 0.9),
        ],
      );

      expect(draft.reliabilityFlag, ReliabilityFlag.caution);
      expect(draft.reasonCodes, contains('PARTIAL_SCREENING_RESULT'));
    });

    test('Firestore enum values use valid/caution/invalid', () {
      expect(ReliabilityFlag.valid.value, 'valid');
      expect(ReliabilityFlag.caution.value, 'caution');
      expect(ReliabilityFlag.invalid.value, 'invalid');
    });
  });

  // ── Disclaimer ────────────────────────────────────────────────────────────

  test('disclaimer contains required non-diagnostic wording', () {
    final draft = RiskClassificationService.calculateClassification(
      userId: 'user_1',
      childId: 'child_1',
      sessionId: 'session_1',
      gameResults: [
        result(domain: ScreeningDomain.literacy, accuracy: 0.9),
        result(domain: ScreeningDomain.numeracy, accuracy: 0.9),
        result(domain: ScreeningDomain.attention, accuracy: 0.9),
      ],
    );

    expect(
      draft.disclaimer,
      contains('preliminary screening indicator only'),
    );
    expect(
      draft.disclaimer,
      contains('not a diagnosis'),
    );
  });
}
