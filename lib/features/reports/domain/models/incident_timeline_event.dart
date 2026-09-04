/// Um evento na linha do tempo de um incidente.
class IncidentTimelineEvent {
  const IncidentTimelineEvent({
    required this.occurredAt,
    required this.description,
  });

  final DateTime occurredAt;
  final String description;

  factory IncidentTimelineEvent.fromMap(Map<String, Object?> map) {
    return IncidentTimelineEvent(
      occurredAt: map['occurredAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'occurredAt': occurredAt,
        'description': description,
      };
}
