class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.systemId,
    this.tag,
    this.payload,
  });

  final String id;
  final int? systemId;
  final String? tag;
  final String title;
  final String body;
  final String? payload;
  final DateTime receivedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'systemId': systemId,
    'tag': tag,
    'title': title,
    'body': body,
    'payload': payload,
    'receivedAt': receivedAt.toIso8601String(),
  };

  factory InboxNotification.fromJson(Map<String, dynamic> json) {
    final receivedRaw = json['receivedAt'];
    final received =
        receivedRaw is String
            ? DateTime.tryParse(receivedRaw) ?? DateTime.now()
            : DateTime.now();
    return InboxNotification(
      id: json['id'] as String? ?? '',
      systemId: json['systemId'] as int?,
      tag: json['tag'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      payload: json['payload'] as String?,
      receivedAt: received,
    );
  }
}
