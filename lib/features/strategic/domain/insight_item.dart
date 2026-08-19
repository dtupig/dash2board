/// Insight, tendência ou pesquisa curada pela Elytron para a persona
/// estratégica.
///
/// Espelha `insights/{id}` (`docs/01_MODELO_DADOS_FIRESTORE.md`). A
/// conversão de `Timestamp` para [DateTime] acontece na camada de dados.
class InsightItem {
  const InsightItem({
    required this.id,
    required this.topic,
    required this.title,
    required this.summary,
    required this.publishedAt,
    required this.sourceName,
    required this.sourceUrl,
    required this.isBenchmark,
  });

  final String id;
  final String topic;
  final String title;
  final String summary;
  final DateTime publishedAt;
  final String sourceName;
  final String sourceUrl;

  /// Verdadeiro quando o insight compara o tenant com pares do mesmo setor.
  final bool isBenchmark;

  factory InsightItem.fromMap(Map<String, Object?> map) {
    return InsightItem(
      id: map['id'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      title: map['title'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      publishedAt: map['publishedAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sourceName: map['sourceName'] as String? ?? '',
      sourceUrl: map['sourceUrl'] as String? ?? '',
      isBenchmark: map['isBenchmark'] as bool? ?? false,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'topic': topic,
        'title': title,
        'summary': summary,
        'publishedAt': publishedAt,
        'sourceName': sourceName,
        'sourceUrl': sourceUrl,
        'isBenchmark': isBenchmark,
      };

  InsightItem copyWith({
    String? id,
    String? topic,
    String? title,
    String? summary,
    DateTime? publishedAt,
    String? sourceName,
    String? sourceUrl,
    bool? isBenchmark,
  }) {
    return InsightItem(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      publishedAt: publishedAt ?? this.publishedAt,
      sourceName: sourceName ?? this.sourceName,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isBenchmark: isBenchmark ?? this.isBenchmark,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InsightItem &&
        other.id == id &&
        other.topic == topic &&
        other.title == title &&
        other.summary == summary &&
        other.publishedAt == publishedAt &&
        other.sourceName == sourceName &&
        other.sourceUrl == sourceUrl &&
        other.isBenchmark == isBenchmark;
  }

  @override
  int get hashCode => Object.hash(
        id,
        topic,
        title,
        summary,
        publishedAt,
        sourceName,
        sourceUrl,
        isBenchmark,
      );

  @override
  String toString() => 'InsightItem($id, $title)';
}
