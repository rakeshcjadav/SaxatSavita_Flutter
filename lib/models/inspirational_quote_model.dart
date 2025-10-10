class InspirationalQuote {
  final String quote;
  final String author;
  final int partNumber;
  final int kiranIndex;

  InspirationalQuote({
    required this.quote,
    required this.author,
    required this.partNumber,
    required this.kiranIndex,
  });

  // Convert from JSON
  factory InspirationalQuote.fromJson(Map<String, dynamic> json) {
    return InspirationalQuote(
      quote: json['quote'] as String,
      author: json['author'] as String,
      partNumber: json['partNumber'] as int,
      kiranIndex: json['kiranIndex'] as int,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'quote': quote,
      'author': author,
      'partNumber': partNumber,
      'kiranIndex': kiranIndex,
    };
  }

  // Copy with method for immutable updates
  InspirationalQuote copyWith({
    String? quote,
    String? author,
    int? partNumber,
    int? kiranIndex,
  }) {
    return InspirationalQuote(
      quote: quote ?? this.quote,
      author: author ?? this.author,
      partNumber: partNumber ?? this.partNumber,
      kiranIndex: kiranIndex ?? this.kiranIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InspirationalQuote &&
        other.quote == quote &&
        other.author == author &&
        other.partNumber == partNumber &&
        other.kiranIndex == kiranIndex;
  }

  @override
  int get hashCode {
    return quote.hashCode ^
        author.hashCode ^
        partNumber.hashCode ^
        kiranIndex.hashCode;
  }

  @override
  String toString() {
    return 'InspirationalQuote(quote: $quote, author: $author, partNumber: $partNumber, kiranIndex: $kiranIndex)';
  }
}
