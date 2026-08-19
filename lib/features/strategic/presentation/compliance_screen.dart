import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/charts/chart_frame.dart';
import '../../../core/widgets/charts/kpi_tile.dart';
import '../../../core/widgets/charts/severity_chip.dart';
import '../../../core/widgets/charts/stacked_status_bar.dart';
import '../data/strategic_providers.dart';
import '../domain/compliance_control.dart';
import '../domain/security_domain.dart';
import 'compliance_filter_controller.dart';
import 'compliance_formatting.dart';
import 'compliance_visuals.dart';
import 'control_detail_sheet.dart';

/// Tela de compliance do CISO: o número (percentual e lacunas) e o caminho
/// até a evidência que sustenta esse número perante auditoria e comitê.
///
/// Acessível de `/estrategia/compliance`, com `?framework=` e `?domain=`
/// opcionais para o drill-down vindo do painel de postura.
class ComplianceScreen extends ConsumerStatefulWidget {
  const ComplianceScreen({
    super.key,
    this.initialFrameworkWire,
    this.initialDomainWire,
  });

  final String? initialFrameworkWire;
  final String? initialDomainWire;

  @override
  ConsumerState<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends ConsumerState<ComplianceScreen> {
  @override
  void initState() {
    super.initState();
    // Uma única vez, logo após o primeiro quadro: reflete o drill-down vindo
    // da URL. Não pode rodar dentro do próprio `initState` - o Riverpod
    // proíbe modificar um provider durante a construção da árvore de
    // widgets (build/initState/dispose/didChangeDependencies).
    Future<void>(() {
      if (!mounted) {
        return;
      }
      ref.read(complianceFilterProvider.notifier).applyFromRoute(
            frameworkWire: widget.initialFrameworkWire,
            domainWire: widget.initialDomainWire,
          );
    });
  }

  static int _statusRank(ControlStatus status) => switch (status) {
        ControlStatus.gap => 0,
        ControlStatus.partial => 1,
        ControlStatus.compliant => 2,
      };

  List<ComplianceControl> _applyFilter(
    List<ComplianceControl> controls,
    ComplianceFilterState filter,
  ) {
    return controls.where((ComplianceControl c) {
      if (filter.framework != null && c.framework != filter.framework) {
        return false;
      }
      if (filter.status != null && c.status != filter.status) {
        return false;
      }
      if (filter.domain != null && c.domain != filter.domain) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  List<ComplianceControl> _sorted(List<ComplianceControl> controls) {
    final List<ComplianceControl> sorted = List<ComplianceControl>.of(controls);
    sorted.sort((ComplianceControl a, ComplianceControl b) {
      final int rank = _statusRank(a.status).compareTo(_statusRank(b.status));
      if (rank != 0) {
        return rank;
      }
      return a.lastReviewedAt.compareTo(b.lastReviewedAt);
    });
    return sorted;
  }

  String _csvEscape(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _buildCsv(List<ComplianceControl> controls) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('framework;controlId;titulo;status;responsavel;ultima_revisao');
    for (final ComplianceControl c in controls) {
      buffer.writeln(
        <String>[
          c.framework.wireValue,
          c.controlId,
          _csvEscape(c.title),
          c.status.wireValue,
          _csvEscape(c.ownerName),
          formatDatePtBr(c.lastReviewedAt),
        ].join(';'),
      );
    }
    return buffer.toString();
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<ComplianceControl> controls,
  ) async {
    final String csv = _buildCsv(controls);
    final Uint8List bytes = Uint8List.fromList(utf8.encode(csv));
    final String filename =
        'compliance_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    // `Printing.sharePdf` chegou junto do briefing executivo (prompt 6) e,
    // apesar do nome, compartilha QUALQUER byte com o nome de arquivo dado -
    // a plataforma nativa (Android/iOS/macOS) grava o arquivo com esse nome
    // e abre a folha de compartilhamento do sistema, sem exigir que o
    // conteúdo seja de fato um PDF. Reaproveitamos o mesmo caminho para o
    // CSV em vez de só mostrar o caminho no disco em um SnackBar.
    bool shared = true;
    try {
      shared = await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (_) {
      shared = false;
    }

    if (!context.mounted || shared) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível compartilhar o CSV agora.'),
      ),
    );
  }

  void _openDetail(BuildContext context, ComplianceControl control) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (BuildContext sheetContext) =>
            ControlDetailSheet(control: control),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ComplianceControl>> complianceAsync =
        ref.watch(complianceProvider);
    final ComplianceFilterState filter = ref.watch(complianceFilterProvider);
    final ComplianceFilterNotifier filterNotifier =
        ref.read(complianceFilterProvider.notifier);

    // Mantém a URL do drill-down em sincronia com o filtro em uso, para que
    // o link seja compartilhável. `ComplianceFilterState` tem `==` por
    // valor, então um `applyFromRoute` que não muda nada não reemite aqui.
    ref.listen<ComplianceFilterState>(complianceFilterProvider, (
      ComplianceFilterState? previous,
      ComplianceFilterState next,
    ) {
      final Uri current = GoRouterState.of(context).uri;
      final Uri updated = Uri(
        path: current.path,
        queryParameters: <String, String>{
          if (next.framework != null) 'framework': next.framework!.wireValue,
          if (next.domain != null) 'domain': next.domain!.wireValue,
        },
      );
      if (updated.toString() != current.toString()) {
        context.go(updated.toString());
      }
    });

    final List<ComplianceControl>? loaded = complianceAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance'),
        actions: <Widget>[
          Tooltip(
            message: 'Exportar CSV do filtro atual',
            child: IconButton(
              icon: const Icon(Icons.file_download_outlined),
              onPressed: loaded == null
                  ? null
                  : () => unawaited(
                        _exportCsv(context, _applyFilter(loaded, filter)),
                      ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: complianceAsync.when(
          loading: () => const _ComplianceLoadingBody(),
          error: (Object error, StackTrace stackTrace) => _ComplianceErrorBody(
            onRetry: () => ref.invalidate(complianceProvider),
          ),
          data: (List<ComplianceControl> controls) => _ComplianceBody(
            allControls: controls,
            filter: filter,
            filterNotifier: filterNotifier,
            applyFilter: _applyFilter,
            sort: _sorted,
            onOpenDetail: (ComplianceControl c) => _openDetail(context, c),
          ),
        ),
      ),
    );
  }
}

class _ComplianceLoadingBody extends StatelessWidget {
  const _ComplianceLoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const <Widget>[
        ChartFrame(
          title: 'Resumo por framework',
          height: 140,
          child: ChartLoading(),
        ),
        SizedBox(height: AppSpacing.xl),
        ChartFrame(
          title: 'Controles',
          height: 240,
          child: ChartLoading(),
        ),
      ],
    );
  }
}

class _ComplianceErrorBody extends StatelessWidget {
  const _ComplianceErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ChartFrame(
        title: 'Compliance',
        height: 240,
        child: ChartError(
          message:
              'Não foi possível carregar os controles de compliance agora.',
          onRetry: onRetry,
        ),
      ),
    );
  }
}

class _ComplianceBody extends StatelessWidget {
  const _ComplianceBody({
    required this.allControls,
    required this.filter,
    required this.filterNotifier,
    required this.applyFilter,
    required this.sort,
    required this.onOpenDetail,
  });

  final List<ComplianceControl> allControls;
  final ComplianceFilterState filter;
  final ComplianceFilterNotifier filterNotifier;
  final List<ComplianceControl> Function(
    List<ComplianceControl>,
    ComplianceFilterState,
  ) applyFilter;
  final List<ComplianceControl> Function(List<ComplianceControl>) sort;
  final ValueChanged<ComplianceControl> onOpenDetail;

  int _overdueCount(List<ComplianceControl> controls) {
    final DateTime now = DateTime.now();
    return controls
        .where((ComplianceControl c) => isReviewOverdue(c.lastReviewedAt, now))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    if (allControls.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const <Widget>[
          ChartFrame(
            title: 'Compliance',
            height: 200,
            child: ChartEmpty(
              message: 'Nenhum controle de compliance cadastrado ainda.',
            ),
          ),
        ],
      );
    }

    final int totalGaps = allControls
        .where((ComplianceControl c) => c.status == ControlStatus.gap)
        .length;
    final List<ComplianceControl> filtered = applyFilter(allControls, filter);
    final List<ComplianceControl> sorted = sort(filtered);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: KpiTile(label: 'Lacunas abertas', value: '$totalGaps'),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KpiTile(
                label: 'Revisão vencida',
                value: '${_overdueCount(allControls)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: Text(
            'Resumo por framework',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 296,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final ComplianceFramework framework
                    in ComplianceFramework.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: _FrameworkSummaryCard(
                      framework: framework,
                      controls: allControls
                          .where(
                              (ComplianceControl c) => c.framework == framework)
                          .toList(growable: false),
                      selected: filter.framework == framework,
                      onTap: () => filterNotifier.setFramework(
                        filter.framework == framework ? null : framework,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _FilterRow(filter: filter, notifier: filterNotifier),
        const SizedBox(height: AppSpacing.lg),
        if (filtered.isEmpty)
          ChartEmpty(
            message: 'Nenhum controle encontrado com esse filtro.',
            actionLabel: 'Limpar filtros',
            onAction: filterNotifier.clearAll,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length,
            itemBuilder: (BuildContext context, int index) {
              final ComplianceControl control = sorted[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _ControlListItem(
                  control: control,
                  onTap: () => onOpenDetail(control),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _FrameworkSummaryCard extends StatelessWidget {
  const _FrameworkSummaryCard({
    required this.framework,
    required this.controls,
    required this.selected,
    required this.onTap,
  });

  final ComplianceFramework framework;
  final List<ComplianceControl> controls;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int compliant = controls
        .where((ComplianceControl c) => c.status == ControlStatus.compliant)
        .length;
    final int partial = controls
        .where((ComplianceControl c) => c.status == ControlStatus.partial)
        .length;
    final int gap = controls
        .where((ComplianceControl c) => c.status == ControlStatus.gap)
        .length;
    final int total = controls.length;
    final int percent = total == 0 ? 0 : ((compliant / total) * 100).round();

    return SizedBox(
      width: 240,
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: ChartFrame(
            title: framework.label,
            subtitle: '$percent% conforme · $gap lacuna${gap == 1 ? '' : 's'}',
            height: 110,
            action: selected
                ? Icon(Icons.check_circle_rounded,
                    color: scheme.primary, size: 18)
                : null,
            onShowTable: (BuildContext sheetContext) => _frameworkTable(
              sheetContext,
              framework: framework,
              compliant: compliant,
              partial: partial,
              gap: gap,
            ),
            child: StackedStatusBar(
              compliantCount: compliant,
              partialCount: partial,
              gapCount: gap,
              height: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _frameworkTable(
    BuildContext context, {
    required ComplianceFramework framework,
    required int compliant,
    required int partial,
    required int gap,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 220,
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          ListTile(title: Text(framework.label, style: textTheme.titleMedium)),
          ListTile(title: const Text('Conforme'), trailing: Text('$compliant')),
          ListTile(title: const Text('Parcial'), trailing: Text('$partial')),
          ListTile(title: const Text('Lacuna'), trailing: Text('$gap')),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.notifier});

  final ComplianceFilterState filter;
  final ComplianceFilterNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final ComplianceFramework framework
              in ComplianceFramework.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilterChip(
                label: Text(framework.label),
                selected: filter.framework == framework,
                onSelected: (bool selected) => notifier.setFramework(
                  selected ? framework : null,
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.md),
          for (final ControlStatus status in ControlStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilterChip(
                label: Text(status.label),
                selected: filter.status == status,
                onSelected: (bool selected) => notifier.setStatus(
                  selected ? status : null,
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.md),
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
              borderRadius: AppRadius.fieldRadius,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SecurityDomain?>(
                value: filter.domain,
                hint: const Text('Domínio'),
                onChanged: notifier.setDomain,
                items: <DropdownMenuItem<SecurityDomain?>>[
                  const DropdownMenuItem<SecurityDomain?>(
                    child: Text('Todos os domínios'),
                  ),
                  for (final SecurityDomain domain in SecurityDomain.values)
                    DropdownMenuItem<SecurityDomain?>(
                      value: domain,
                      child: Text(domain.label),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlListItem extends StatelessWidget {
  const _ControlListItem({required this.control, required this.onTap});

  final ComplianceControl control;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Semantics(
      button: true,
      label: '${control.controlId}, ${control.title}, status '
          '${control.status.label}, responsável ${control.ownerName}, '
          'revisado em ${formatDatePtBr(control.lastReviewedAt)}.',
      excludeSemantics: true,
      child: Material(
        color: const Color(0x00000000),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.fieldRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 60,
                    child: Text(
                      control.controlId,
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          control.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${control.ownerName} · revisado em '
                          '${formatDatePtBr(control.lastReviewedAt)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SeverityChip.custom(
                    icon: control.status.icon,
                    color: control.status.color,
                    label: control.status.label,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
