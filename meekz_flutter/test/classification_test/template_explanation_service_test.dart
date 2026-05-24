import 'package:flutter_test/flutter_test.dart';
import 'package:meekz/meekz_backend.dart';

void main() {
  RiskClassification classification({
    required IndicatorLevel overallIndicator,
    required ReliabilityFlag reliabilityFlag,
  }) {
    return RiskClassification(
      classificationId: 'classification_1',
      sessionId: 'session_1',
      childId: 'child_1',
      userId: 'user_1',
      literacyIndicator: overallIndicator,
      numeracyIndicator: overallIndicator,
      attentionIndicator: overallIndicator,
      overallIndicator: overallIndicator,
      reliabilityFlag: reliabilityFlag,
      reasonCodes: const ['PROTOTYPE_THRESHOLDS_NOT_VALIDATED'],
      disclaimer: meekzRequiredDisclaimer,
      createdAt: DateTime.utc(2026),
    );
  }

  test('returns safe templates for every language and indicator level', () {
    const service = TemplateExplanationService();

    for (final language in LanguageCode.values) {
      for (final level in IndicatorLevel.values) {
        final template = service.build(
          classification: classification(
            overallIndicator: level,
            reliabilityFlag: ReliabilityFlag.valid,
          ),
          language: language,
        );

        expect(template.explanationText, isNotEmpty);
        expect(template.recommendationText, isNotEmpty);
        expect(template.disclaimer, isNotEmpty);
        expect(
          TemplateExplanationService.containsForbiddenDiagnosticWording(
            template.explanationText,
          ),
          isFalse,
        );
        expect(
          TemplateExplanationService.containsForbiddenDiagnosticWording(
            template.recommendationText,
          ),
          isFalse,
        );
        expect(
          TemplateExplanationService.containsForbiddenDiagnosticWording(
            template.disclaimer,
          ),
          isFalse,
        );
      }
    }
  });

  test('returns safe caution and invalid templates for every language', () {
    const service = TemplateExplanationService();

    for (final language in LanguageCode.values) {
      for (final flag in [
        ReliabilityFlag.caution,
        ReliabilityFlag.invalid,
      ]) {
        final template = service.build(
          classification: classification(
            overallIndicator: IndicatorLevel.high,
            reliabilityFlag: flag,
          ),
          language: language,
        );

        expect(template.explanationText, isNotEmpty);
        expect(template.recommendationText, isNotEmpty);
        expect(
          TemplateExplanationService.containsForbiddenDiagnosticWording(
            '${template.explanationText} ${template.recommendationText}',
          ),
          isFalse,
        );
      }
    }
  });

  test('blocks forbidden result wording before display', () {
    expect(
      () => TemplateExplanationService.assertSafeText(
        'This text says dyslexia detected.',
      ),
      throwsA(isA<MeekzException>()),
    );
  });

  test('enum firestore values match the SRS vocabulary', () {
    expect(IndicatorLevel.low.value, 'low');
    expect(IndicatorLevel.moderate.value, 'moderate');
    expect(IndicatorLevel.high.value, 'high');
    expect(IndicatorLevel.inconclusive.value, 'inconclusive');

    expect(ReliabilityFlag.valid.value, 'valid');
    expect(ReliabilityFlag.caution.value, 'caution');
    expect(ReliabilityFlag.invalid.value, 'invalid');

    expect(ScreeningSessionStatus.notStarted.value, 'not_started');
    expect(ScreeningSessionStatus.inProgress.value, 'in_progress');
    expect(ScreeningSessionStatus.completed.value, 'completed');
    expect(ScreeningSessionStatus.invalid.value, 'invalid');
    expect(
      ScreeningSessionStatus.repeatRecommended.value,
      'repeat_recommended',
    );
  });

  // ── Exact disclaimer text ──────────────────────────────────────────────

  test('exact required disclaimer text exists', () {
    expect(
      meekzRequiredDisclaimer,
      'This result is a preliminary screening indicator only. '
      'It is not a diagnosis and should not replace professional '
      'assessment by qualified medical, psychological, or '
      'educational professionals.',
    );
  });

  // ── Safety filter: individual forbidden phrase tests ───────────────────

  group('Safety filter blocks specific forbidden phrases', () {
    test('"not a diagnosis" is allowed', () {
      expect(
        TemplateExplanationService.containsForbiddenDiagnosticWording(
          'This is not a diagnosis.',
        ),
        isFalse,
      );
    });

    test('"diagnosis confirmed" is blocked', () {
      expect(
        TemplateExplanationService.containsForbiddenDiagnosticWording(
          'The diagnosis confirmed the condition.',
        ),
        isTrue,
      );
    });

    test('"diagnosed with" is blocked', () {
      expect(
        TemplateExplanationService.containsForbiddenDiagnosticWording(
          'The child was diagnosed with a condition.',
        ),
        isTrue,
      );
    });

    test('"has dyslexia" is blocked', () {
      expect(
        TemplateExplanationService.containsForbiddenDiagnosticWording(
          'The child has dyslexia.',
        ),
        isTrue,
      );
    });

    test('"has dyscalculia" is blocked', () {
      expect(
        TemplateExplanationService.containsForbiddenDiagnosticWording(
          'The child has dyscalculia.',
        ),
        isTrue,
      );
    });

    test('"has ADHD" is blocked', () {
      expect(
        TemplateExplanationService.containsForbiddenDiagnosticWording(
          'The child has ADHD.',
        ),
        isTrue,
      );
    });

    test('"clinical result" is blocked', () {
      expect(
        TemplateExplanationService.containsForbiddenDiagnosticWording(
          'This is a clinical result.',
        ),
        isTrue,
      );
    });
  });
}
