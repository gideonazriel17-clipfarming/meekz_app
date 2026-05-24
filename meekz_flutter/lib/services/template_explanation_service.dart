import '../models/app_disclaimer.dart';
import '../models/app_enums.dart';
import '../models/risk_classification.dart';
import 'meekz_exception.dart';

class TemplateExplanation {
  const TemplateExplanation({
    required this.explanationText,
    required this.recommendationText,
    required this.disclaimer,
  });

  final String explanationText;
  final String recommendationText;
  final String disclaimer;
}

class TemplateExplanationService {
  const TemplateExplanationService();

  static const forbiddenDiagnosticTerms = [
    'diagnosis',
    'diagnoses',
    'diagnosed',
    'diagnostic',
    'detect',
    'detected',
    'detection',
    'confirm',
    'confirmed',
    'disorder',
    'dyslexia',
    'dyscalculia',
    'adhd',
    'learning disability',
  ];

  TemplateExplanation build({
    required RiskClassification classification,
    LanguageCode language = LanguageCode.en,
  }) {
    final explanationText = buildExplanationText(
      overallIndicator: classification.overallIndicator,
      reliabilityFlag: classification.reliabilityFlag,
      language: language,
    );
    final recommendationText = buildRecommendationText(
      overallIndicator: classification.overallIndicator,
      reliabilityFlag: classification.reliabilityFlag,
      language: language,
    );

    assertSafeText(explanationText);
    assertSafeText(recommendationText);
    assertSafeText(meekzRequiredDisclaimer);

    return TemplateExplanation(
      explanationText: explanationText,
      recommendationText: recommendationText,
      disclaimer: meekzRequiredDisclaimer,
    );
  }

  static String buildExplanationText({
    required IndicatorLevel overallIndicator,
    required ReliabilityFlag reliabilityFlag,
    LanguageCode language = LanguageCode.en,
  }) {
    if (reliabilityFlag == ReliabilityFlag.invalid ||
        overallIndicator == IndicatorLevel.inconclusive) {
      return switch (language) {
        LanguageCode.ms =>
          'Keputusan saringan awal ini belum muktamad kerana maklumat aktiviti belum mencukupi untuk ringkasan penuh.',
        LanguageCode.zh => '当前初步筛查结果尚不明确，因为已完成的活动资料不足以形成完整摘要。',
        LanguageCode.en =>
          'This preliminary screening result is inconclusive because there is not enough completed activity data for a full summary.',
      };
    }

    if (reliabilityFlag == ReliabilityFlag.caution) {
      return switch (language) {
        LanguageCode.ms =>
          'Keputusan saringan awal ini perlu dibaca dengan berhati-hati kerana corak semasa tugasan mungkin mempengaruhi kebolehpercayaan.',
        LanguageCode.zh => '当前初步筛查结果需要谨慎解读，因为任务过程中的表现模式可能影响可靠性。',
        LanguageCode.en =>
          'This preliminary screening result should be read with caution because task patterns may have affected reliability.',
      };
    }

    return switch (language) {
      LanguageCode.ms => switch (overallIndicator) {
          IndicatorLevel.low =>
            'Aktiviti yang selesai menunjukkan petunjuk berkaitan pembelajaran yang rendah dalam domain yang dinilai.',
          IndicatorLevel.moderate =>
            'Aktiviti yang selesai menunjukkan petunjuk berkaitan pembelajaran yang sederhana dalam domain yang dinilai.',
          IndicatorLevel.high =>
            'Aktiviti yang selesai menunjukkan petunjuk berkaitan pembelajaran yang tinggi dalam domain yang dinilai.',
          IndicatorLevel.inconclusive =>
            'Keputusan saringan awal ini belum muktamad kerana maklumat aktiviti belum mencukupi untuk ringkasan penuh.',
        },
      LanguageCode.zh => switch (overallIndicator) {
          IndicatorLevel.low => '已完成的活动显示，所评估领域中的学习相关指标较低。',
          IndicatorLevel.moderate => '已完成的活动显示，所评估领域中的学习相关指标为中等。',
          IndicatorLevel.high => '已完成的活动显示，所评估领域中的学习相关指标较高。',
          IndicatorLevel.inconclusive => '当前初步筛查结果尚不明确，因为已完成的活动资料不足以形成完整摘要。',
        },
      LanguageCode.en => switch (overallIndicator) {
          IndicatorLevel.low =>
            'Completed activities currently show low learning-related indicators across the assessed domains.',
          IndicatorLevel.moderate =>
            'Completed activities currently show moderate learning-related indicators across the assessed domains.',
          IndicatorLevel.high =>
            'Completed activities currently show high learning-related indicators across the assessed domains.',
          IndicatorLevel.inconclusive =>
            'This preliminary screening result is inconclusive because there is not enough completed activity data for a full summary.',
        },
    };
  }

  static String buildRecommendationText({
    required IndicatorLevel overallIndicator,
    required ReliabilityFlag reliabilityFlag,
    LanguageCode language = LanguageCode.en,
  }) {
    if (reliabilityFlag == ReliabilityFlag.invalid ||
        overallIndicator == IndicatorLevel.inconclusive) {
      return switch (language) {
        LanguageCode.ms =>
          'Lengkapkan atau ulang semua domain sebelum menggunakan ringkasan ini untuk perbincangan lanjut.',
        LanguageCode.zh => '请先完成或重新进行所有领域活动，再使用此摘要进行进一步讨论。',
        LanguageCode.en =>
          'Complete or repeat all domains before using this summary for further discussion.',
      };
    }

    if (reliabilityFlag == ReliabilityFlag.caution) {
      return switch (language) {
        LanguageCode.ms =>
          'Pertimbangkan untuk mengulang aktiviti apabila kanak-kanak sudah bersedia dan arahan difahami dengan jelas.',
        LanguageCode.zh => '可在孩子准备好并清楚理解指示后，考虑重新进行这些活动。',
        LanguageCode.en =>
          'Consider repeating the activities when the child is ready and the instructions are clearly understood.',
      };
    }

    return switch (language) {
      LanguageCode.ms => switch (overallIndicator) {
          IndicatorLevel.low =>
            'Teruskan aktiviti pembelajaran harian dan pantau perkembangan dari semasa ke semasa.',
          IndicatorLevel.moderate =>
            'Bincangkan petunjuk ini dengan ibu bapa, guru, kaunselor sekolah, atau kakitangan sokongan pendidikan.',
          IndicatorLevel.high =>
            'Pertimbangkan pemerhatian lanjut dan panduan daripada profesional yang berkelayakan jika kebimbangan berterusan.',
          IndicatorLevel.inconclusive =>
            'Lengkapkan atau ulang semua domain sebelum menggunakan ringkasan ini untuk perbincangan lanjut.',
        },
      LanguageCode.zh => switch (overallIndicator) {
          IndicatorLevel.low => '继续日常学习活动，并随时间观察孩子的发展。',
          IndicatorLevel.moderate => '可与家长、教师、学校辅导员或教育支持人员讨论这些指标。',
          IndicatorLevel.high => '如果疑虑持续，可考虑进一步观察并寻求合格专业人员的指导。',
          IndicatorLevel.inconclusive => '请先完成或重新进行所有领域活动，再使用此摘要进行进一步讨论。',
        },
      LanguageCode.en => switch (overallIndicator) {
          IndicatorLevel.low =>
            'Continue everyday learning activities and monitor progress over time.',
          IndicatorLevel.moderate =>
            'Discuss these indicators with a parent, teacher, school counselor, or educational support personnel.',
          IndicatorLevel.high =>
            'Consider further observation and guidance from a qualified professional if concerns continue.',
          IndicatorLevel.inconclusive =>
            'Complete or repeat all domains before using this summary for further discussion.',
        },
    };
  }

  static bool containsForbiddenDiagnosticWording(String text) {
    var normalized = text.toLowerCase();

    // Explicit exemption for the safe phrase "not a diagnosis"
    normalized = normalized.replaceAll('not a diagnosis', '');

    // List of forbidden diagnostic terms and unsafe phrases to block
    final forbiddenWithClaims = [
      ...forbiddenDiagnosticTerms,
      'clinical result',
      'clinical diagnosis',
      'diagnosed with',
      'diagnosis confirmed',
      'has dyslexia',
      'has dyscalculia',
      'has adhd',
      'detected disorder',
      'learning disability confirmed',
    ];

    return forbiddenWithClaims.any(normalized.contains);
  }

  static void assertSafeText(String text) {
    if (containsForbiddenDiagnosticWording(text)) {
      throw const MeekzException(
        'Unsafe result wording was blocked before display.',
      );
    }
  }
}
