import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/charts/chart_frame.dart';
import '../../../core/widgets/charts/delta_badge.dart';
import '../../../core/widgets/charts/kpi_tile.dart';
import '../../../core/widgets/elytron_logo.dart';
import '../data/strategic_providers.dart';
import '../domain/compliance_control.dart';
import '../domain/posture_index.dart';
import '../domain/posture_snapshot.dart';
import '../domain/risk_item.dart';
import '../domain/security_domain.dart';
import 'briefing_copy.dart';
import 'briefing_data.dart';
import 'briefing_formatting.dart';
import 'briefing_pdf_builder.dart';

/// Briefing executivo de uma página - `/estrategia/briefing`.
///
/// Mostra o documento renderizado em Flutter primeiro; só o botão
/// "compartilhar" gera o PDF de fato (regra D do prompt: ninguém envia ao
/// board um arquivo que não viu).
class ExecutiveBriefingScreen extends ConsumerStatefulWidget {
  const ExecutiveBriefingScreen({super.key});

  @override
  ConsumerState<ExecutiveBriefingScreen> createState() =>
      _ExecutiveBriefingScreenState();
}

class _ExecutiveBriefingScreenState
    extends ConsumerState<ExecutiveBriefingScreen> {
  bool _sharing = false;

  Future<void> _share(BriefingData data) async {
    setState(() => _sharing = true);
    try {
      final Uint8List bytes = await BriefingPdfBuilder.build(data);
      final String stamp =
          '${data.generatedAt.year}${data.generatedAt.month.toString().padLeft(2, '0')}'
          '${data.generatedAt.day.toString().padLeft(2, '0')}-'
          '${data.generatedAt.hour.toString().padLeft(2, '0')}'
          '${data.generatedAt.minute.toString().padLeft(2, '0')}';
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'briefing-executivo-$stamp.pdf',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível gerar o PDF do briefing agora.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PostureIndex> postureIndexAsync =
        ref.watch(postureIndexProvider);
    final AsyncValue<List<PostureSnapshot>> postureHistoryAsync =
        ref.watch(postureHistoryProvider);
    final AsyncValue<List<ComplianceControl>> complianceAsync =
        ref.watch(complianceProvider);
    final AsyncValue<List<RiskItem>> risksAsync = ref.watch(topRisksProvider);
    final String tenantId = ref.watch(appUserProvider).value?.tenantId ?? '';

    final List<AsyncValue<Object?>> all = <AsyncValue<Object?>>[
      postureIndexAsync,
      postureHistoryAsync,
      complianceAsync,
      risksAsync,
    ];

    void retryAll() {
      ref.invalidate(postureIndexProvider);
      ref.invalidate(postureHistoryProvider);
      ref.invalidate(complianceProvider);
      ref.invalidate(topRisksProvider);
    }

    Widget body;
    if (all.any((AsyncValue<Object?> v) => v.isLoading)) {
      body = const _BriefingLoadingBody();
    } else if (all.any((AsyncValue<Object?> v) => v.hasError)) {
      body = _BriefingErrorBody(onRetry: retryAll);
    } else {
      final PostureIndex postureIndex = postureIndexAsync.requireValue;
      final List<PostureSnapshot> postureHistory =
          postureHistoryAsync.requireValue;
      // O índice de "hoje" sozinho não conta a história de 12 meses que a
      // seção 1 do briefing promete - sem o histórico mensal, o documento
      // ficaria com uma seção pela metade em vez de recusar a gerar.
      final bool hasEssentialData =
          postureIndex.capturedAt.millisecondsSinceEpoch > 0 &&
              postureIndex.byDomain.isNotEmpty &&
              postureHistory.isNotEmpty;

      if (!hasEssentialData) {
        body = _BriefingInsufficientDataBody(onRetry: retryAll);
      } else {
        final BriefingData data = BriefingData.build(
          postureIndex: postureIndex,
          postureHistory: postureHistory,
          complianceControls: complianceAsync.requireValue,
          risks: risksAsync.requireValue,
          isMockData: AppConfig.useMockData,
          tenantId: tenantId,
          generatedAt: DateTime.now(),
        );
        body = _BriefingPreview(data: data);
      }
    }

    final BriefingData? shareableData =
        (body is _BriefingPreview) ? body.data : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Briefing executivo')),
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: shareableData == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: FilledButton.icon(
                  onPressed: _sharing ? null : () => _share(shareableData),
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_rounded, size: 18),
                  label: Text(_sharing ? 'Gerando PDF...' : 'Compartilhar PDF'),
                ),
              ),
            ),
    );
  }
}

class _BriefingLoadingBody extends StatelessWidget {
  const _BriefingLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: ChartFrame(
        title: 'Briefing executivo',
        height: 400,
        child: ChartLoading(),
      ),
    );
  }
}

class _BriefingErrorBody extends StatelessWidget {
  const _BriefingErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ChartFrame(
        title: 'Briefing executivo',
        height: 240,
        child: ChartError(
          message: 'Não foi possível carregar os dados do briefing agora.',
          onRetry: onRetry,
        ),
      ),
    );
  }
}

/// Estado específico quando falta dado essencial para montar o documento
/// (regra "Estados" do prompt: explica o que falta, nunca gera um PDF com
/// buracos).
class _BriefingInsufficientDataBody extends StatelessWidget {
  const _BriefingInsufficientDataBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.fact_check_outlined,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ainda não é possível gerar o briefing',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Falta o índice de postura por domínio deste tenant. Assim que '
              'os snapshots mensais de postura existirem, o briefing pode '
              'ser gerado - não geramos um PDF com seções em branco.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pré-visualização do documento, em Flutter - deliberadamente com paleta
/// clara fixa (`AppTheme.light`), porque o briefing é "impresso e
/// projetado": a prévia precisa se parecer com o PDF que ela antecede, não
/// com o tema atual do app (que pode estar no modo escuro).
class _BriefingPreview extends StatelessWidget {
  const _BriefingPreview({required this.data});

  final BriefingData data;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: ColoredBox(
        color: AppColors.lightBackground,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            Row(
              children: <Widget>[
                const ElytronLogo(size: 32, showGlow: false),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'ELYTRON DASH2BOARD',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.2,
                              color: AppColors.lightTextSecondary,
                            ),
                      ),
                      Text(
                        'Briefing executivo de segurança',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _Section(
              number: '1',
              title: 'Índice de postura de segurança',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  KpiTile(
                    label: 'Índice consolidado',
                    value: '${data.overallScore}',
                    unit: 'de 100 pontos',
                    delta: DeltaBadge(
                      value: data.delta,
                      unitLabel: 'pontos',
                      periodLabel: 'em 12 meses',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    data.overallScore >= data.peerMedian
                        ? 'Acima da mediana do setor (empresas do mesmo '
                            'porte e segmento), hoje em ${data.peerMedian} '
                            'pontos.'
                        : 'Abaixo da mediana do setor (empresas do mesmo '
                            'porte e segmento), hoje em ${data.peerMedian} '
                            'pontos.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            _Section(
              number: '2',
              title: 'Domínios que mais precisam de atenção',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final MapEntry<SecurityDomain, int> entry
                      in data.weakestDomains)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: <InlineSpan>[
                            TextSpan(
                              text: '${entry.key.label} (${entry.value} '
                                  'pontos): ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: entry.key.briefingConsequence),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _Section(
              number: '3',
              title:
                  'Maiores exposições financeiras (perda anual esperada, ou '
                  'ALE)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final RiskItem risk in data.topExposures)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${risk.title} (${risk.businessUnit})',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            formatCurrencyBrl(risk.annualLossExpectancy),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _Section(
              number: '4',
              title: 'Situação de compliance por framework',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final ComplianceFramework framework
                      in ComplianceFramework.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  framework.briefingFullName,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                data.compliancePercentByFramework[framework] ==
                                        null
                                    ? 'sem dados'
                                    : '${data.compliancePercentByFramework[framework]}% conforme',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value:
                                  (data.compliancePercentByFramework[framework] ??
                                          0) /
                                      100,
                              minHeight: 6,
                              backgroundColor: AppColors.lightSurfaceHighest,
                              color: AppColors.brandGreenDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _Section(
              number: '5',
              title: 'Decisões que dependem do comitê',
              child: data.pendingDecisions.isEmpty
                  ? Text(
                      'Nenhuma decisão de risco pendente no momento.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final RiskItem risk in data.pendingDecisions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Text(
                              '• ${risk.title} (${risk.businessUnit}) - '
                              'tratamento proposto: ${risk.treatment.label}, '
                              'exposição de '
                              '${formatCurrencyBrl(risk.annualLossExpectancy)} '
                              'por ano.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '6. Gerado em ${_formatDateTime(data.generatedAt)} · Fonte: '
              '${data.isMockData ? 'dados de demonstração (modo mock)' : 'Cloud Firestore, agregados pré-calculados por Cloud Functions'}, '
              'tenant "${data.tenantId}".',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.number, required this.title, required this.child});

  final String number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              '$number. $title',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.lightTextPrimary,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
