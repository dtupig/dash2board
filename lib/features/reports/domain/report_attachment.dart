import 'report_classification.dart';

/// Um anexo referenciado por um relatório - nunca o dado bruto em si.
///
/// Decisão D-05: o app guarda ponteiro e hash, nunca a evidência bruta.
/// `storagePath` aponta para o cofre forense/documental, fora do Firestore.
class ReportAttachment {
  const ReportAttachment({
    required this.label,
    required this.storagePath,
    required this.sizeBytes,
    required this.sha256,
    required this.classification,
  });

  final String label;
  final String storagePath;
  final int sizeBytes;
  final String sha256;
  final ReportClassification classification;

  factory ReportAttachment.fromMap(Map<String, Object?> map) {
    return ReportAttachment(
      label: map['label'] as String? ?? '',
      storagePath: map['storagePath'] as String? ?? '',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      sha256: map['sha256'] as String? ?? '',
      classification: ReportClassification.fromWire(map['classification']),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'label': label,
        'storagePath': storagePath,
        'sizeBytes': sizeBytes,
        'sha256': sha256,
        'classification': classification.wireValue,
      };

  @override
  bool operator ==(Object other) {
    return other is ReportAttachment &&
        other.label == label &&
        other.storagePath == storagePath &&
        other.sizeBytes == sizeBytes &&
        other.sha256 == sha256 &&
        other.classification == classification;
  }

  @override
  int get hashCode =>
      Object.hash(label, storagePath, sizeBytes, sha256, classification);
}
