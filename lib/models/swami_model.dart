class SwamiKiranRef {
  final int index;
  final String role;
  final List<String> questions;

  const SwamiKiranRef({
    required this.index,
    required this.role,
    this.questions = const [],
  });

  factory SwamiKiranRef.fromMap(Map<String, dynamic> map) {
    return SwamiKiranRef(
      index: (map['index'] as num?)?.toInt() ?? 0,
      role: (map['role'] as String? ?? 'mentioned').trim(),
      questions:
          (map['questions'] as List<dynamic>? ?? [])
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(),
    );
  }
}

class SwamiItem {
  final String name;
  final int count;
  final List<SwamiKiranRef> kirans;

  const SwamiItem({
    required this.name,
    required this.count,
    required this.kirans,
  });

  int get questionCount => kirans.where((ref) => ref.role == 'question').length;

  int get mentionedCount =>
      kirans.where((ref) => ref.role == 'mentioned').length;

  bool get hasQuestion => questionCount > 0;

  bool get hasMentioned => mentionedCount > 0;

  List<String> get questions => [for (final ref in kirans) ...ref.questions];

  int get roleTypeCount =>
      [hasQuestion, hasMentioned].where((flag) => flag).length;

  factory SwamiItem.fromMap(Map<String, dynamic> map) {
    final kirans =
        (map['kirans'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map(
              (item) => SwamiKiranRef.fromMap(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.index > 0)
            .toList();
    return SwamiItem(
      name: (map['name'] as String? ?? '').trim(),
      count: (map['count'] as num?)?.toInt() ?? kirans.length,
      kirans: kirans,
    );
  }
}

class SwamiIndex {
  final List<SwamiItem> list;
  final Map<String, String> aliases;

  const SwamiIndex({required this.list, this.aliases = const {}});

  factory SwamiIndex.fromMap(Map<String, dynamic> map) {
    final aliases = <String, String>{};
    final rawAliases = map['aliases'];
    if (rawAliases is Map) {
      for (final entry in rawAliases.entries) {
        final key = entry.key.toString().trim();
        final value = entry.value.toString().trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          aliases[key] = value;
        }
      }
    }
    return SwamiIndex(
      aliases: aliases,
      list:
          (map['list'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((item) => SwamiItem.fromMap(Map<String, dynamic>.from(item)))
              .where((item) => item.name.isNotEmpty)
              .toList(),
    );
  }
}
