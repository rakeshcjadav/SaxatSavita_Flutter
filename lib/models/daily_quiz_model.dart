class DailyQuizQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int part;
  final int kiranIndex;

  const DailyQuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.part,
    required this.kiranIndex,
    this.explanation = '',
  });

  factory DailyQuizQuestion.fromMap(Map<String, dynamic> map) {
    return DailyQuizQuestion(
      id: (map['id'] as String? ?? '').trim(),
      prompt: (map['prompt'] as String? ?? '').trim(),
      options:
          (map['options'] as List<dynamic>? ?? [])
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(),
      correctIndex: _readInt(map['correctIndex']),
      explanation: (map['explanation'] as String? ?? '').trim(),
      part: _readInt(map['part']),
      kiranIndex: _readInt(map['kiranIndex']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'prompt': prompt,
    'options': options,
    'correctIndex': correctIndex,
    if (explanation.isNotEmpty) 'explanation': explanation,
    'part': part,
    'kiranIndex': kiranIndex,
  };

  bool get isValid =>
      id.isNotEmpty &&
      prompt.isNotEmpty &&
      options.length >= 2 &&
      correctIndex >= 0 &&
      correctIndex < options.length &&
      part >= 1 &&
      kiranIndex >= 1;
}

class DailyQuizPack {
  final String id;
  final List<DailyQuizQuestion> questions;

  const DailyQuizPack({required this.id, this.questions = const []});

  factory DailyQuizPack.fromMap(Map<String, dynamic> map) {
    return DailyQuizPack(
      id: (map['id'] as String? ?? '').trim(),
      questions:
          (map['questions'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map(
                (item) =>
                    DailyQuizQuestion.fromMap(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.isValid)
              .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'questions': questions.map((item) => item.toMap()).toList(),
  };

  bool get isValid => id.isNotEmpty && questions.length >= 5;

  List<DailyQuizQuestion> get scoredQuestions => questions.take(5).toList();
}

class DailyQuizBank {
  final int version;
  final String locale;
  final List<DailyQuizPack> packs;

  const DailyQuizBank({
    this.version = 1,
    this.locale = 'gu',
    this.packs = const [],
  });

  factory DailyQuizBank.fromMap(Map<String, dynamic> map) {
    return DailyQuizBank(
      version: _readInt(map['version'], 1),
      locale: (map['locale'] as String? ?? 'gu').trim(),
      packs:
          (map['packs'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map(
                (item) =>
                    DailyQuizPack.fromMap(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.isValid)
              .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'version': version,
    'locale': locale,
    'packs': packs.map((item) => item.toMap()).toList(),
  };

  bool get isEmpty => packs.isEmpty;
}

class DailyQuizResult {
  final String dateKey;
  final String packId;
  final int score;
  final int total;
  final DateTime completedAt;
  final int pointsAwarded;
  final List<int> answers;
  final List<String> questionIds;

  const DailyQuizResult({
    required this.dateKey,
    required this.packId,
    required this.score,
    required this.total,
    required this.completedAt,
    this.pointsAwarded = 0,
    this.answers = const [],
    this.questionIds = const [],
  });

  String get docId => dateKey;

  bool get isPerfect => total > 0 && score == total;

  factory DailyQuizResult.fromJson(Map<String, dynamic> json) {
    return DailyQuizResult(
      dateKey: (json['dateKey'] as String? ?? '').trim(),
      packId: (json['packId'] as String? ?? '').trim(),
      score: _readInt(json['score']),
      total: _readInt(json['total']),
      completedAt:
          DateTime.tryParse(json['completedAt']?.toString() ?? '') ??
          DateTime.now(),
      pointsAwarded: _readInt(json['pointsAwarded']),
      answers:
          (json['answers'] as List<dynamic>? ?? [])
              .map((item) => _readInt(item))
              .toList(),
      questionIds:
          (json['questionIds'] as List<dynamic>? ?? [])
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey,
    'packId': packId,
    'score': score,
    'total': total,
    'completedAt': completedAt.toIso8601String(),
    'pointsAwarded': pointsAwarded,
    'answers': answers,
    'questionIds': questionIds,
  };
}

int _readInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
