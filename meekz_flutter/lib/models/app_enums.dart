enum AdultRole {
  parent,
  teacher,
  schoolCounselor,
  supportPersonnel,
  admin,
}

enum LanguageCode {
  ms,
  en,
  zh,
}

enum ScreeningDomain {
  literacy,
  numeracy,
  attention,
}

enum ScreeningSessionStatus {
  notStarted,
  inProgress,
  completed,
  invalid,
  repeatRecommended,
}

enum IndicatorLevel {
  low,
  moderate,
  high,
  inconclusive,
}

enum ReliabilityFlag {
  valid,
  caution,
  invalid,
}

enum SummaryGenerator {
  ruleBased,
  template,
}

extension AdultRoleFirestore on AdultRole {
  String get value {
    switch (this) {
      case AdultRole.parent:
        return 'parent';
      case AdultRole.teacher:
        return 'teacher';
      case AdultRole.schoolCounselor:
        return 'school_counselor';
      case AdultRole.supportPersonnel:
        return 'support_personnel';
      case AdultRole.admin:
        return 'admin';
    }
  }

  static AdultRole fromValue(String value) {
    return AdultRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => AdultRole.parent,
    );
  }
}

extension LanguageCodeFirestore on LanguageCode {
  String get value => name;

  static LanguageCode fromValue(String value) {
    return LanguageCode.values.firstWhere(
      (language) => language.value == value,
      orElse: () => LanguageCode.en,
    );
  }
}

extension ScreeningDomainFirestore on ScreeningDomain {
  String get value => name;

  static ScreeningDomain fromValue(String value) {
    return ScreeningDomain.values.firstWhere(
      (domain) => domain.value == value,
      orElse: () => ScreeningDomain.literacy,
    );
  }
}

extension ScreeningSessionStatusFirestore on ScreeningSessionStatus {
  String get value {
    switch (this) {
      case ScreeningSessionStatus.notStarted:
        return 'not_started';
      case ScreeningSessionStatus.inProgress:
        return 'in_progress';
      case ScreeningSessionStatus.completed:
        return 'completed';
      case ScreeningSessionStatus.invalid:
        return 'invalid';
      case ScreeningSessionStatus.repeatRecommended:
        return 'repeat_recommended';
    }
  }

  static ScreeningSessionStatus fromValue(String value) {
    return ScreeningSessionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ScreeningSessionStatus.notStarted,
    );
  }
}

extension IndicatorLevelFirestore on IndicatorLevel {
  String get value {
    switch (this) {
      case IndicatorLevel.low:
        return 'low';
      case IndicatorLevel.moderate:
        return 'moderate';
      case IndicatorLevel.high:
        return 'high';
      case IndicatorLevel.inconclusive:
        return 'inconclusive';
    }
  }

  static IndicatorLevel fromValue(String value) {
    return IndicatorLevel.values.firstWhere(
      (indicator) => indicator.value == value,
      orElse: () => IndicatorLevel.inconclusive,
    );
  }
}

extension ReliabilityFlagFirestore on ReliabilityFlag {
  String get value {
    switch (this) {
      case ReliabilityFlag.valid:
        return 'valid';
      case ReliabilityFlag.caution:
        return 'caution';
      case ReliabilityFlag.invalid:
        return 'invalid';
    }
  }

  static ReliabilityFlag fromValue(String value) {
    return ReliabilityFlag.values.firstWhere(
      (flag) => flag.value == value,
      orElse: () => ReliabilityFlag.invalid,
    );
  }
}

extension SummaryGeneratorFirestore on SummaryGenerator {
  String get value {
    switch (this) {
      case SummaryGenerator.ruleBased:
        return 'rule_based';
      case SummaryGenerator.template:
        return 'template';
    }
  }

  static SummaryGenerator fromValue(String value) {
    return SummaryGenerator.values.firstWhere(
      (generator) => generator.value == value,
      orElse: () => SummaryGenerator.template,
    );
  }
}
