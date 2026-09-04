/// Prioridade de um item de ação de um relatório.
enum ActionPriority {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const ActionPriority(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        ActionPriority.low => 'Baixa',
        ActionPriority.medium => 'Média',
        ActionPriority.high => 'Alta',
        ActionPriority.critical => 'Crítica',
      };

  static ActionPriority fromWire(Object? value) {
    for (final ActionPriority p in ActionPriority.values) {
      if (p.wireValue == value) {
        return p;
      }
    }
    return ActionPriority.medium;
  }
}

/// Um item do plano de ação de um relatório - o que fazer, quem faz e até
/// quando.
class ActionItem {
  const ActionItem({
    required this.title,
    required this.ownerName,
    required this.dueAt,
    required this.effort,
    required this.priority,
  });

  final String title;
  final String ownerName;
  final DateTime dueAt;

  /// Estimativa de esforço em linguagem livre (ex.: "2 dias-pessoa") - o
  /// catálogo de serviços não padroniza uma unidade única entre disciplinas.
  final String effort;
  final ActionPriority priority;

  factory ActionItem.fromMap(Map<String, Object?> map) {
    return ActionItem(
      title: map['title'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      dueAt: map['dueAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      effort: map['effort'] as String? ?? '',
      priority: ActionPriority.fromWire(map['priority']),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'title': title,
        'ownerName': ownerName,
        'dueAt': dueAt,
        'effort': effort,
        'priority': priority.wireValue,
      };

  @override
  bool operator ==(Object other) {
    return other is ActionItem &&
        other.title == title &&
        other.ownerName == ownerName &&
        other.dueAt == dueAt &&
        other.effort == effort &&
        other.priority == priority;
  }

  @override
  int get hashCode => Object.hash(title, ownerName, dueAt, effort, priority);
}
