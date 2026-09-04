import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../surface_card.dart';

export 'chart_states.dart' show ChartEmpty, ChartError, ChartLoading;

/// Moldura comum de todo gráfico do Dash2Board: título, subtítulo, ação
/// opcional no canto, altura fixa e o cartão de superfície por baixo.
///
/// Nenhum painel deve desenhar um gráfico fora de um [ChartFrame] - é aqui
/// que vive a alternativa textual acessível (regra de acessibilidade D do
/// prompt): quando [onShowTable] é fornecido, um botão "Ver dados" abre a
/// mesma informação em uma tabela, para quem usa leitor de tela.
///
/// Os estados de carregamento/vazio/erro ([ChartLoading], [ChartEmpty],
/// [ChartError]) vivem em `chart_states.dart` e são reexportados aqui, para
/// manter este arquivo abaixo do limite de 250 linhas.
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
      // Sem isso, a folha modal trava a altura em ~9/16 da tela - o
      // conteúdo (altura fixa, ex. a tabela de "Onde está o risco") não
      // cabe nesse limite e a coluna interna do modal estoura por baixo
      // (achado de teste manual, 04/09/2026: "Bottom overflowed by 77
      // pixels"). Mesmo ajuste que as outras folhas do app já usam.
      isScrollControlled: true,
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
