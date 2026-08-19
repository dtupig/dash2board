import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../surface_card.dart';

/// Moldura comum de todo gráfico do Dash2Board: título, subtítulo, ação
/// opcional no canto, altura fixa e o cartão de superfície por baixo.
///
/// Nenhum painel deve desenhar um gráfico fora de um [ChartFrame] - é aqui
/// que vive a alternativa textual acessível (regra de acessibilidade D do
/// prompt): quando [onShowTable] é fornecido, um botão "Ver dados" abre a
/// mesma informação em uma tabela, para quem usa leitor de tela.
class ChartFrame extends StatelessWidget {
  const ChartFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.height = 240,
    this.onShowTable,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final double height;
  final Widget child;

  /// Constrói a tabela de dados exibida na folha modal "Ver dados".
  final WidgetBuilder? onShowTable;

  void _openTable(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: onShowTable!(sheetContext),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(height: height, child: child),
          if (onShowTable != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openTable(context),
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                label: const Text('Ver dados'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Estado de carregamento de um gráfico: esqueleto com brilho sutil.
class ChartLoading extends StatefulWidget {
  const ChartLoading({super.key});

  @override
  State<ChartLoading> createState() => _ChartLoadingState();
}

class _ChartLoadingState extends State<ChartLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: 'Carregando dados do gráfico.',
      container: true,
      excludeSemantics: true,
      child: reduceMotion
          ? _skeleton(scheme, 0.55)
          : AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double alpha = 0.35 + (0.35 * _controller.value);
                return _skeleton(scheme, alpha);
              },
            ),
    );
  }

  Widget _skeleton(ColorScheme scheme, double alpha) {
    const List<double> barHeights = <double>[0.55, 0.85, 0.4, 0.7, 0.6];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (int i = 0; i < barHeights.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FractionallySizedBox(
                  heightFactor: barHeights[i] * math.max(0.4, alpha),
                  alignment: Alignment.bottomCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant
                          .withValues(alpha: alpha * 0.35),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Estado vazio de um gráfico: mensagem + o que fazer.
class ChartEmpty extends StatelessWidget {
  const ChartEmpty({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: message,
      container: true,
      excludeSemantics: true,
      child: Center(
        // `SingleChildScrollView` é uma rede de segurança: a altura do
        // `ChartFrame` é fixa, mas o tamanho da mensagem não é (varia por
        // idioma e pelo texto de `AppFailure`) - rola em vez de estourar.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.insert_chart_outlined_rounded,
                color: scheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (actionLabel != null && onAction != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado de erro de um gráfico: mensagem segura + "tentar de novo".
class ChartError extends StatelessWidget {
  const ChartError({super.key, required this.message, required this.onRetry});

  /// Mensagem já segura para exibição (ex.: `AppFailure.message`) - nunca um
  /// detalhe interno do backend.
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '$message Botão tentar de novo disponível.',
      container: true,
      excludeSemantics: true,
      child: Center(
        // Ver nota em `ChartEmpty` sobre `SingleChildScrollView` como rede
        // de segurança para mensagens mais longas que a altura do frame.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.error_outline_rounded, color: scheme.error, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
