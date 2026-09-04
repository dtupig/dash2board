import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/domain/user_role.dart';
import '../data/reports_providers.dart';
import '../domain/report.dart';
import '../domain/report_access_policy.dart';
import '../domain/report_classification.dart';
import '../domain/report_section.dart';
import 'widgets/board_report_view.dart';
import 'widgets/sections_list_view.dart';

/// Visualizador de relatório - `/relatorios/:reportId`. Um relatório, três
/// profundidades: a mesma leitura do banco vira três telas diferentes,
/// conforme a persona.
class ReportViewerScreen extends ConsumerStatefulWidget {
  const ReportViewerScreen({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends ConsumerState<ReportViewerScreen> {
  bool _receiptRecorded = false;
  bool _recordingReceipt = false;
  bool _receiptFailed = false;

  Future<void> _recordReceipt(String tenantId, UserRole role) async {
    setState(() {
      _recordingReceipt = true;
      _receiptFailed = false;
    });
    final String uid = ref.read(appUserProvider).value?.uid ?? '';
    try {
      await ref.read(reportsRepositoryProvider).recordReadReceipt(
            tenantId: tenantId,
            reportId: widget.reportId,
            uid: uid,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _receiptRecorded = true;
        _recordingReceipt = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _recordingReceipt = false;
        _receiptFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ServiceReport?> reportAsync =
        ref.watch(reportProvider(widget.reportId));
    final UserRole role =
        ref.watch(appUserProvider).value?.role ?? UserRole.pending;
    final String tenantId = ref.watch(appUserProvider).value?.tenantId ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Relatório')),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => const _ErrorState(
            message: 'Não foi possível carregar o relatório.'),
        data: (ServiceReport? report) {
          if (report == null) {
            return const _ErrorState(
              message: 'Relatório não encontrado ou removido.',
            );
          }

          final bool canOpen = ReportAccessPolicy.canOpen(
            role,
            report.classification,
            isMaterialFact: report.hasMaterialFact,
          );
          if (!canOpen) {
            return _ErrorState(
              message: ReportAccessPolicy.redactionNotice(role),
            );
          }

          final bool needsReceipt =
              ReportAccessPolicy.requiresReadReceipt(report.classification);
          if (needsReceipt && !_receiptRecorded) {
            return _ReadReceiptGate(
              recording: _recordingReceipt,
              failed: _receiptFailed,
              onContinue: () => _recordReceipt(tenantId, role),
            );
          }

          if (role == UserRole.board) {
            return BoardReportView(report: report);
          }

          final AsyncValue<List<ReportSection>> sectionsAsync =
              ref.watch(reportSectionsProvider(widget.reportId));
          return sectionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stackTrace) => const _ErrorState(
              message: 'Não foi possível carregar as seções do relatório.',
            ),
            data: (List<ReportSection> sections) => SectionsListView(
              report: report,
              sections: sections,
              role: role,
            ),
          );
        },
      ),
    );
  }
}

class _ReadReceiptGate extends StatelessWidget {
  const _ReadReceiptGate({
    required this.recording,
    required this.failed,
    required this.onContinue,
  });

  final bool recording;
  final bool failed;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.gpp_maybe_outlined,
                size: 40, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Este relatório é sigiloso (${ReportClassification.secret.label}).',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ao continuar, o acesso é registrado na trilha de auditoria '
              'antes de o conteúdo ser exibido.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (failed) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Não foi possível registrar a leitura. Verifique sua conexão '
                'e tente novamente.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: recording ? null : onContinue,
              child: Text(
                recording ? 'Registrando...' : 'Continuar e registrar leitura',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
