import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/contracted_service.dart';
import '../domain/service_request.dart';

/// Funções de mapeamento Firestore -> domínio do módulo de serviços,
/// isoladas de `firestore_services_repository.dart` para manter aquele
/// arquivo abaixo do limite de 250 linhas. Único ponto que converte
/// `Timestamp` para [DateTime]; o domínio não conhece o Firestore.
DateTime mapFirestoreTimestamp(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

ContractedService mapContractedServiceDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final Map<String, dynamic> data = doc.data();
  return ContractedService.fromMap(<String, Object?>{
    ...data,
    'serviceKey': data['serviceKey'] ?? doc.id,
    'startedAt': mapFirestoreTimestamp(data['startedAt']),
    'endsAt': mapFirestoreTimestamp(data['endsAt']),
    'lastDeliveryAt': data['lastDeliveryAt'] == null
        ? null
        : mapFirestoreTimestamp(data['lastDeliveryAt']),
  });
}

ServiceRequest mapServiceRequestQueryDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) =>
    mapServiceRequestData(doc.id, doc.data());

ServiceRequest mapServiceRequestDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) =>
    mapServiceRequestData(doc.id, doc.data() ?? const <String, dynamic>{});

ServiceRequest mapServiceRequestData(String id, Map<String, dynamic> data) {
  final List<dynamic> timelineRaw =
      data['timeline'] as List<dynamic>? ?? const <dynamic>[];
  return ServiceRequest.fromMap(<String, Object?>{
    ...data,
    'id': id,
    'createdAt': mapFirestoreTimestamp(data['createdAt']),
    'desiredWindow': mapFirestoreTimestamp(data['desiredWindow']),
    'scopeAssets': (data['scopeAssets'] as List<dynamic>?)
            ?.map((Object? e) => e as String)
            .toList(growable: false) ??
        const <String>[],
    'approval': data['approval'] == null
        ? null
        : _mapApprovalData(data['approval'] as Map<String, dynamic>),
    'timeline': <Map<String, Object?>>[
      for (final dynamic event in timelineRaw)
        _mapTimelineData(event as Map<String, dynamic>),
    ],
  });
}

Map<String, Object?> _mapApprovalData(Map<String, dynamic> data) {
  return <String, Object?>{
    ...data,
    'decidedAt': mapFirestoreTimestamp(data['decidedAt']),
  };
}

Map<String, Object?> _mapTimelineData(Map<String, dynamic> data) {
  return <String, Object?>{
    ...data,
    'occurredAt': mapFirestoreTimestamp(data['occurredAt']),
  };
}
