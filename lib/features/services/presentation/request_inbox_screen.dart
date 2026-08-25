import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/charts/chart_frame.dart';
import '../data/services_providers.dart';
import '../domain/approval_record.dart';
import '../domain/request_status.dart';
import '../domain/service_catalog.dart';
import '../domain/service_request.dart';
import 'widgets/approval_dialogs.dart';
import 'widgets/request_card.dart';

/// Fila de solicitações - `/servicos/solicitacoes`. O que cada persona vê
/// aqui é filtro de dado (`servicesRepositoryProvider`), mas as ações
/// disponíveis (aprovar/rejeitar) só aparecem para `strategic`.
class RequestInboxScreen extends ConsumerWidget {
  const RequestInboxScreen({super.key});

  Future<void> _approve(
      WidgetRef ref, BuildContext context, ServiceRequest r) async {
    final String label =
        ServiceCatalog.byKey(r.serviceKey)?.label ?? r.serviceKey;
    if (!await showApproveConfirmation(context, label)) {
      return;
    }
    await _decide(ref, r, ApprovalDecision.approved, '');
  }

  Future<void> _reject(
      WidgetRef ref, BuildContext context, ServiceRequest r) async {
    final String label =
        ServiceCatalog.byKey(r.serviceKey)?.label ?? r.serviceKey;
    final String? note = await showRejectDialog(context, label);
    if (note == null) {
      return;
    }
    await _decide(ref, r, ApprovalDecision.rejected, note);
  }

  Future<void> _decide(
    WidgetRef ref,
    ServiceRequest request,
    ApprovalDecision decision,
    String note,
  ) async {
    final String? tenantId = ref.read(appUserProvider).value?.tenantId;
    final String? uid = ref.read(appUserProvider).value?.uid;
    final String name = ref.read(appUserProvider).value?.firstName ?? '';
    if (tenantId == null || uid == null) {
      return;
    }
    await ref.read(servicesRepositoryProvider).decideApproval(
          tenantId: tenantId,
          requestId: request.id,
          decision: decision,
          decidedByUid: uid,
          decidedByName: name,
          note: note,
        );
    ref.invalidate(serviceRequestsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String roleWire =
        ref.watch(appUserProvider).value?.role.wireValue ?? 'pending';
    final AsyncValue<List<ServiceRequest>> requestsAsync =
        ref.watch(serviceRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitações')),
      body: SafeArea(
        child: requestsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: ChartFrame(
              title: 'Solicitações',
              height: 240,
              child: ChartLoading(),
            ),
          ),
          error: (Object error, StackTrace stackTrace) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ChartFrame(
              title: 'Solicitações',
              height: 200,
              child: ChartError(
                message: 'Não foi possível carregar as solicitações agora.',
                onRetry: () => ref.invalidate(serviceRequestsProvider),
              ),
            ),
          ),
          data: (List<ServiceRequest> requests) =>
              _body(context, ref, roleWire, requests),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    String roleWire,
    List<ServiceRequest> requests,
  ) {
    if (roleWire == 'board') {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: ChartEmpty(
          message: 'O board é informado apenas quando uma solicitação vira '
              'fato relevante - nenhuma pendência aqui hoje.',
        ),
      );
    }

    if (roleWire != 'strategic') {
      return _RequestList(requests: requests);
    }

    final List<ServiceRequest> pending = requests
        .where((ServiceRequest r) => r.status == RequestStatus.pendingApproval)
        .toList(growable: false);
    final List<ServiceRequest> inProgress = requests
        .where((ServiceRequest r) => <RequestStatus>{
              RequestStatus.approved,
              RequestStatus.sentToElytron,
              RequestStatus.proposalReceived,
              RequestStatus.contracted,
            }.contains(r.status))
        .toList(growable: false);
    final List<ServiceRequest> history = requests
        .where((ServiceRequest r) => <RequestStatus>{
              RequestStatus.rejected,
              RequestStatus.delivered,
              RequestStatus.cancelled,
            }.contains(r.status))
        .toList(growable: false);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: <Widget>[
              Tab(text: 'Aguardando (${pending.length})'),
              const Tab(text: 'Em andamento'),
              const Tab(text: 'Histórico'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _RequestList(
                  requests: pending,
                  onApprove: (ServiceRequest r) => _approve(ref, context, r),
                  onReject: (ServiceRequest r) => _reject(ref, context, r),
                ),
                _RequestList(requests: inProgress),
                _RequestList(requests: history),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({required this.requests, this.onApprove, this.onReject});

  final List<ServiceRequest> requests;
  final ValueChanged<ServiceRequest>? onApprove;
  final ValueChanged<ServiceRequest>? onReject;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: ChartEmpty(message: 'Nada por aqui no momento.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (BuildContext context, int index) {
        final ServiceRequest request = requests[index];
        return RequestCard(
          request: request,
          onApprove: onApprove == null ? null : () => onApprove!(request),
          onReject: onReject == null ? null : () => onReject!(request),
        );
      },
    );
  }
}
