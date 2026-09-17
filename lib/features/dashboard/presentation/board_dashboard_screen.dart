import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/charts/chart_frame.dart';
import '../../../core/widgets/surface_card.dart';
import '../../auth/domain/user_role.dart';
import '../../shell/persona_scaffold.dart';
import '../../strategic/data/strategic_providers.dart';
import '../../strategic/domain/risk_item.dart';
import '../../strategic/domain/tenant_profile.dart';
import 'widgets/board_business_unit_section.dart';
import 'widgets/board_exposure_card.dart';
import 'widgets/board_pending_decisions_section.dart';
import 'widgets/board_wide_layout.dart';

/// Persona 3 - Board e executivos C-Level das unidades de negócio.
///
/// A regra que governa esta tela: zero jargão. Se um termo técnico é
/// indispensável, ele vem explicado na mesma linha, em linguagem de
/// negócio. Nada de índice de postura, domínio de controle, framework de
/// compliance, CVE, incidente ou nome de ferramenta - se o board quiser
/// detalhe técnico, ele chama o CISO.
///
/// Os 3 blocos (exposição, unidades de negócio, decisões pendentes) vivem
/// em `widgets/board_*.dart` - extraídos daqui para reaproveitar tanto na
/// composição empilhada (`compact`/`medium`/`expanded`) quanto na de
/// `large` (`BoardWideLayout`, HU-W-14), e para manter este arquivo abaixo
/// do limite de 250 linhas (era o maior arquivo do Bucket B, 672 linhas).
class BoardDashboardScreen extends ConsumerWidget {
  const BoardDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const UserRole role = UserRole.board;
    final AsyncValue<List<RiskItem>> risksAsync = ref.watch(allRisksProvider);
    final AsyncValue<TenantProfile> profileAsync =
        ref.watch(tenantProfileProvider);

    void retryAll() {
      ref.invalidate(allRisksProvider);
      ref.invalidate(tenantProfileProvider);
    }

    Widget body;
    // `hasError` vem ANTES de `isLoading`: um `AsyncValue` pode carregar os
    // dois ao mesmo tempo (Riverpod preserva o erro anterior durante um novo
    // carregamento) - checar `isLoading` primeiro deixaria uma falha logo no
    // primeiro carregamento presa no esqueleto para sempre, sem nunca
    // mostrar "tentar de novo".
    if (risksAsync.hasError || profileAsync.hasError) {
      body = _BoardErrorBody(onRetry: retryAll);
    } else if (risksAsync.isLoading || profileAsync.isLoading) {
      body = const _BoardLoadingBody();
    } else {
      body = _BoardBody(
        risks: risksAsync.requireValue,
        profile: profileAsync.requireValue,
      );
    }

    return PersonaScaffold(
      role: role,
      title: 'Risco Cibernético do Negócio',
      subtitle:
          'Três números, uma tendência e as decisões que dependem do board.',
      children: <Widget>[body],
    );
  }
}

class _BoardLoadingBody extends StatelessWidget {
  const _BoardLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        ChartFrame(
          title: 'Exposição financeira estimada',
          height: 120,
          child: ChartLoading(),
        ),
        SizedBox(height: AppSpacing.xl),
        ChartFrame(
          title: 'Impacto por unidade de negócio',
          height: 220,
          child: ChartLoading(),
        ),
      ],
    );
  }
}

class _BoardErrorBody extends StatelessWidget {
  const _BoardErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ChartFrame(
      title: 'Risco do negócio',
      height: 220,
      child: ChartError(
        message: 'Não foi possível carregar os números de risco agora.',
        onRetry: onRetry,
      ),
    );
  }
}

class _BoardBody extends StatelessWidget {
  const _BoardBody({required this.risks, required this.profile});

  final List<RiskItem> risks;
  final TenantProfile profile;

  Map<String, double> _aleByBusinessUnit() {
    final Map<String, double> byBu = <String, double>{};
    for (final RiskItem risk in risks) {
      byBu[risk.businessUnit] =
          (byBu[risk.businessUnit] ?? 0) + risk.annualLossExpectancy;
    }
    return byBu;
  }

  @override
  Widget build(BuildContext context) {
    if (risks.isEmpty) {
      return const ChartFrame(
        title: 'Risco do negócio',
        height: 200,
        child: ChartEmpty(
          message: 'Nenhum risco de negócio cadastrado ainda.',
        ),
      );
    }

    final Map<String, double> aleByBu = _aleByBusinessUnit();
    final double totalAle =
        aleByBu.values.fold(0.0, (double sum, double v) => sum + v);
    final double percentOfRevenue = profile.annualRevenue <= 0
        ? 0
        : (totalAle / profile.annualRevenue) * 100;
    final double quarterlyDelta = totalAle - profile.previousQuarterAle;
    final List<RiskItem> pending = risks
        .where((RiskItem r) => r.acceptance == RiskAcceptance.pending)
        .toList(growable: false)
      ..sort(
          (RiskItem a, RiskItem b) => a.reviewDueAt.compareTo(b.reviewDueAt));

    final Widget exposureCard = BoardExposureCard(
      totalAle: totalAle,
      percentOfRevenue: percentOfRevenue,
      quarterlyDelta: quarterlyDelta,
    );
    final Widget businessUnitSection = BoardBusinessUnitSection(
      risks: risks,
      profile: profile,
      aleByBusinessUnit: aleByBu,
    );
    final Widget pendingHeading = Semantics(
      header: true,
      child: Text(
        'Decisões pendentes do board',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
    final Widget servicesShortcut = SurfaceCard(
      // `push`, não `go` - senão a tela de destino fica sem botão de
      // voltar (achado de teste manual, 04/09/2026).
      onTap: () => context.push('/servicos'),
      semanticLabel: 'Serviços. Você é informado quando uma solicitação '
          'vira fato relevante. Toque para abrir.',
      child: const ExcludeSemantics(
        child: Row(
          children: <Widget>[
            Icon(Icons.design_services_outlined),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Text('Serviços - só fato relevante')),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );

    final bool isLarge = LayoutSize.of(context) == LayoutSize.large;
    String ownerNameFor(String bu) => profile.ownerFor(bu);

    if (isLarge) {
      return BoardWideLayout(
        exposureCard: exposureCard,
        businessUnitSection: businessUnitSection,
        pendingHeading: pendingHeading,
        pendingSection: BoardPendingDecisionsSection(
          pending: pending,
          ownerNameFor: ownerNameFor,
          wide: true,
        ),
        servicesShortcut: servicesShortcut,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        exposureCard,
        const SizedBox(height: AppSpacing.xl),
        businessUnitSection,
        const SizedBox(height: AppSpacing.xl),
        pendingHeading,
        const SizedBox(height: AppSpacing.sm),
        BoardPendingDecisionsSection(
          pending: pending,
          ownerNameFor: ownerNameFor,
        ),
        const SizedBox(height: AppSpacing.xl),
        servicesShortcut,
      ],
    );
  }
}
