import 'approval_record.dart';
import 'request_driver.dart';
import 'request_status.dart';
import 'request_urgency.dart';

/// Um evento da linha do tempo de uma solicitação - cada mudança de estado
/// vira um item aqui, na ordem em que aconteceu.
class RequestTimelineEvent {
  const RequestTimelineEvent({
    required this.status,
    required this.occurredAt,
    this.note = '',
  });

  final RequestStatus status;
  final DateTime occurredAt;
  final String note;

  factory RequestTimelineEvent.fromMap(Map<String, Object?> map) {
    return RequestTimelineEvent(
      status: RequestStatus.fromWire(map['status']),
      occurredAt: map['occurredAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      note: map['note'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'status': status.wireValue,
        'occurredAt': occurredAt,
        'note': note,
      };

  @override
  bool operator ==(Object other) {
    return other is RequestTimelineEvent &&
        other.status == status &&
        other.occurredAt == occurredAt &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(status, occurredAt, note);
}

/// Uma solicitação de serviço (RFS) - transforma uma intenção em algo com
/// escopo suficiente para virar proposta comercial. Não é ordem de serviço
/// dentro de contrato (decisão já tomada do prompt 10).
///
/// Espelha `/tenants/{tenantId}/service_requests/{requestId}`.
class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.tenantId,
    required this.serviceKey,
    required this.requestedByUid,
    required this.requestedByName,
    required this.createdAt,
    required this.urgency,
    required this.driver,
    required this.scopeSummary,
    required this.scopeAssets,
    required this.businessJustification,
    required this.desiredWindow,
    required this.status,
    required this.timeline,
    this.approval,
  });

  final String id;
  final String tenantId;
  final String serviceKey;
  final String requestedByUid;
  final String requestedByName;
  final DateTime createdAt;
  final RequestUrgency urgency;
  final RequestDriver driver;

  /// Frase livre de "por que está pedindo" (passo 1 do wizard).
  final String scopeSummary;

  /// Alvos (domínios, aplicações, repositórios, faixas de IP, contas de
  /// nuvem) quando `ServiceOffering.requiresScopeAssets` é verdadeiro; vazio
  /// quando o serviço pede volume/abrangência em vez de alvos.
  final List<String> scopeAssets;

  final String businessJustification;
  final DateTime desiredWindow;
  final RequestStatus status;
  final ApprovalRecord? approval;
  final List<RequestTimelineEvent> timeline;

  factory ServiceRequest.fromMap(Map<String, Object?> map) {
    return ServiceRequest(
      id: map['id'] as String? ?? '',
      tenantId: map['tenantId'] as String? ?? '',
      serviceKey: map['serviceKey'] as String? ?? '',
      requestedByUid: map['requestedByUid'] as String? ?? '',
      requestedByName: map['requestedByName'] as String? ?? '',
      createdAt: map['createdAt'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      urgency: RequestUrgency.fromWire(map['urgency']),
      driver: RequestDriver.fromWire(map['driver']),
      scopeSummary: map['scopeSummary'] as String? ?? '',
      scopeAssets: (map['scopeAssets'] as List<dynamic>?)
              ?.map((Object? e) => e as String)
              .toList(growable: false) ??
          const <String>[],
      businessJustification: map['businessJustification'] as String? ?? '',
      desiredWindow: map['desiredWindow'] as DateTime? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: RequestStatus.fromWire(map['status']),
      approval: map['approval'] == null
          ? null
          : ApprovalRecord.fromMap(map['approval'] as Map<String, Object?>),
      timeline: (map['timeline'] as List<dynamic>?)
              ?.map((Object? e) =>
                  RequestTimelineEvent.fromMap(e as Map<String, Object?>))
              .toList(growable: false) ??
          const <RequestTimelineEvent>[],
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'tenantId': tenantId,
        'serviceKey': serviceKey,
        'requestedByUid': requestedByUid,
        'requestedByName': requestedByName,
        'createdAt': createdAt,
        'urgency': urgency.wireValue,
        'driver': driver.wireValue,
        'scopeSummary': scopeSummary,
        'scopeAssets': scopeAssets,
        'businessJustification': businessJustification,
        'desiredWindow': desiredWindow,
        'status': status.wireValue,
        'approval': approval?.toMap(),
        'timeline': <Map<String, Object?>>[
          for (final RequestTimelineEvent event in timeline) event.toMap(),
        ],
      };

  ServiceRequest copyWith({
    RequestStatus? status,
    ApprovalRecord? approval,
    List<RequestTimelineEvent>? timeline,
  }) {
    return ServiceRequest(
      id: id,
      tenantId: tenantId,
      serviceKey: serviceKey,
      requestedByUid: requestedByUid,
      requestedByName: requestedByName,
      createdAt: createdAt,
      urgency: urgency,
      driver: driver,
      scopeSummary: scopeSummary,
      scopeAssets: scopeAssets,
      businessJustification: businessJustification,
      desiredWindow: desiredWindow,
      status: status ?? this.status,
      approval: approval ?? this.approval,
      timeline: timeline ?? this.timeline,
    );
  }

  @override
  bool operator ==(Object other) => other is ServiceRequest && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServiceRequest($id, $serviceKey, ${status.wireValue})';
}
