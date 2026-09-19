class KiranQuizQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String sourceHint;

  const KiranQuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
    this.sourceHint = '',
  });

  factory KiranQuizQuestion.fromMap(Map<String, dynamic> map) {
    return KiranQuizQuestion(
      id: (map['id'] as String? ?? '').trim(),
      prompt: (map['prompt'] as String? ?? '').trim(),
      options:
          (map['options'] as List<dynamic>? ?? [])
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(),
      correctIndex: _readInt(map['correctIndex']),
      explanation: (map['explanation'] as String? ?? '').trim(),
      sourceHint: (map['sourceHint'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'prompt': prompt,
    'options': options,
    'correctIndex': correctIndex,
    if (explanation.isNotEmpty) 'explanation': explanation,
    if (sourceHint.isNotEmpty) 'sourceHint': sourceHint,
  };

  bool get isValid =>
      id.isNotEmpty &&
      prompt.isNotEmpty &&
      options.length >= 2 &&
      correctIndex >= 0 &&
      correctIndex < options.length;
}

class KiranQuiz {
  final int part;
  final int kiranIndex;
  final int version;
  final String locale;
  final List<KiranQuizQuestion> questions;

  const KiranQuiz({
    required this.part,
    required this.kiranIndex,
    this.version = 1,
    this.locale = 'gu',
    this.questions = const [],
  });

  String get docId => '${part}_$kiranIndex';

  factory KiranQuiz.fromMap(Map<String, dynamic> map) {
    return KiranQuiz(
      part: _readInt(map['part']),
      kiranIndex: _readInt(map['kiranIndex']),
      version: _readInt(map['version'], 1),
      locale: (map['locale'] as String? ?? 'gu').trim(),
      questions:
          (map['questions'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map(
                (item) =>
                    KiranQuizQuestion.fromMap(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.isValid)
              .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'part': part,
    'kiranIndex': kiranIndex,
    'version': version,
    'locale': locale,
    'questions': questions.map((item) => item.toMap()).toList(),
  };
}

class KiranQuizResult {
  final int part;
  final int kiranIndex;
  final int score;
  final int total;
  final DateTime completedAt;
  final int quizVersion;
  final List<String> rewardIds;
  final int pointsAwarded;

  const KiranQuizResult({
    required this.part,
    required this.kiranIndex,
    required this.score,
    required this.total,
    required this.completedAt,
    this.quizVersion = 1,
    this.rewardIds = const [],
    this.pointsAwarded = 0,
  });

  String get docId => '${part}_$kiranIndex';

  bool get isPerfect => total > 0 && score == total;

  bool get isScored => pointsAwarded > 0 || rewardIds.isNotEmpty || score >= 0;

  factory KiranQuizResult.fromJson(Map<String, dynamic> json) {
    return KiranQuizResult(
      part: _readInt(json['part']),
      kiranIndex: _readInt(json['kiranIndex']),
      score: _readInt(json['score']),
      total: _readInt(json['total']),
      completedAt:
          DateTime.tryParse(json['completedAt']?.toString() ?? '') ??
          DateTime.now(),
      quizVersion: _readInt(json['quizVersion'], 1),
      rewardIds:
          (json['rewardIds'] as List<dynamic>? ?? [])
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList(),
      pointsAwarded: _readInt(json['pointsAwarded']),
    );
  }

  Map<String, dynamic> toJson() => {
    'part': part,
    'kiranIndex': kiranIndex,
    'score': score,
    'total': total,
    'completedAt': completedAt.toIso8601String(),
    'quizVersion': quizVersion,
    'rewardIds': rewardIds,
    'pointsAwarded': pointsAwarded,
  };
}

int _readInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
