import '../../auth/domain/user_role.dart';
import 'report_classification.dart';

/// Uma seção nomeada de um relatório - a unidade que `ReportAccessPolicy`
/// libera ou suprime, uma a uma.
class ReportSection {
  const ReportSection({
    required this.key,
    required this.title,
    required this.minimumRole,
    required this.sensitivity,
    required this.body,
  });

  final String key;
  final String title;

  /// A persona mais restrita que pode ver esta seção - usada como filtro
  /// rápido antes mesmo de consultar `ReportAccessPolicy.canSeeSection`.
  final UserRole minimumRole;
  final SectionSensitivity sensitivity;
  final String body;

  factory ReportSection.fromMap(Map<String, Object?> map) {
    return ReportSection(
      key: map['key'] as String? ?? '',
      title: map['title'] as String? ?? '',
      minimumRole: UserRole.fromWire(map['minimumRole']),
      sensitivity: SectionSensitivity.fromWire(map['sensitivity']),
      body: map['body'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'key': key,
        'title': title,
        'minimumRole': minimumRole.wireValue,
        'sensitivity': sensitivity.wireValue,
        'body': body,
      };

  @override
  bool operator ==(Object other) {
    return other is ReportSection &&
        other.key == key &&
        other.title == title &&
        other.minimumRole == minimumRole &&
        other.sensitivity == sensitivity &&
        other.body == body;
  }

  @override
  int get hashCode => Object.hash(key, title, minimumRole, sensitivity, body);
}
