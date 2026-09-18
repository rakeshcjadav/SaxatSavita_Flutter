class HaribhaktKiranRef {
  final int index;
  final String role;

  const HaribhaktKiranRef({required this.index, required this.role});

  factory HaribhaktKiranRef.fromMap(Map<String, dynamic> map) {
    return HaribhaktKiranRef(
      index: (map['index'] as num?)?.toInt() ?? 0,
      role: (map['role'] as String? ?? 'reader').trim(),
    );
  }
}

class HaribhaktItem {
  final String name;
  final int count;
  final List<HaribhaktKiranRef> kirans;

  const HaribhaktItem({
    required this.name,
    required this.count,
    required this.kirans,
  });

  int get hostCount => kirans.where((ref) => ref.role == 'host').length;

  int get readerCount => kirans.where((ref) => ref.role == 'reader').length;

  int get mentionedCount =>
      kirans.where((ref) => ref.role == 'mentioned').length;

  bool get hasHost => hostCount > 0;

  bool get hasReader => readerCount > 0;

  bool get hasMentioned => mentionedCount > 0;

  int get roleTypeCount =>
      [hasHost, hasReader, hasMentioned].where((flag) => flag).length;

  factory HaribhaktItem.fromMap(Map<String, dynamic> map) {
    final kirans =
        (map['kirans'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map(
              (item) =>
                  HaribhaktKiranRef.fromMap(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.index > 0)
            .toList();
    return HaribhaktItem(
      name: (map['name'] as String? ?? '').trim(),
      count: (map['count'] as num?)?.toInt() ?? kirans.length,
      kirans: kirans,
    );
  }
}

class HaribhaktIndex {
  final List<HaribhaktItem> list;
  final Map<String, String> aliases;

  const HaribhaktIndex({required this.list, this.aliases = const {}});

  factory HaribhaktIndex.fromMap(Map<String, dynamic> map) {
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
    return HaribhaktIndex(
      aliases: aliases,
      list:
          (map['list'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map(
                (item) =>
                    HaribhaktItem.fromMap(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.name.isNotEmpty)
              .toList(),
    );
  }
}
