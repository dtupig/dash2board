import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Níveis de severidade exibidos por [SeverityChip].
///
/// Alinhado a CVSS v3.1/v4.0, igual à paleta em `AppColors.severity*` - a
/// cor de estado é reusada, nunca redeclarada (ver `chart_tokens.dart`).
enum ChartSeverityLevel { critical, high, medium, low }

/// Visual de cada nível: cor de estado, ícone e rótulo em pt-BR.
extension ChartSeverityLevelVisuals on ChartSeverityLevel {
  Color get color => switch (this) {
        ChartSeverityLevel.critical => AppColors.severityCritical,
        ChartSeverityLevel.high => AppColors.severityHigh,
        ChartSeverityLevel.medium => AppColors.severityMedium,
        ChartSeverityLevel.low => AppColors.severityLow,
      };

  IconData get icon => switch (this) {
        ChartSeverityLevel.critical => Icons.report_rounded,
        ChartSeverityLevel.high => Icons.warning_amber_rounded,
        ChartSeverityLevel.medium => Icons.info_outline_rounded,
        ChartSeverityLevel.low => Icons.check_circle_outline_rounded,
      };

  String get label => switch (this) {
        ChartSeverityLevel.critical => 'Crítico',
        ChartSeverityLevel.high => 'Alto',
        ChartSeverityLevel.medium => 'Médio',
        ChartSeverityLevel.low => 'Baixo',
      };
}

/// Chip de estado: ícone + texto + cor de estado.
///
/// A cor de estado tinge o ícone e o fundo, nunca o texto - o texto sempre
/// usa um token de texto do tema (regra 6 de `chart_tokens.dart`), para que
/// o contraste não dependa da luminosidade da cor escolhida.
///
/// Cobre dois usos: severidade CVSS ([SeverityChip.new], com
/// [ChartSeverityLevel]) e qualquer outro estado de três ou mais valores que
/// precise do mesmo desenho visual (ex.: status de compliance), via
/// [SeverityChip.custom] - sem duplicar o widget para cada taxonomia nova.
class SeverityChip extends StatelessWidget {
  const SeverityChip({super.key, required ChartSeverityLevel level})
      : _level = level,
        icon = null,
        color = null,
        label = null;

  /// Constrói um chip do mesmo desenho visual para um estado que não é uma
  /// severidade CVSS (ex.: `ControlStatus` de compliance).
  const SeverityChip.custom({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
  }) : _level = null;

  final ChartSeverityLevel? _level;
  final IconData? icon;
  final Color? color;
  final String? label;

  IconData get _resolvedIcon => _level?.icon ?? icon!;
  Color get _resolvedColor => _level?.color ?? color!;
  String get _resolvedLabel => _level?.label ?? label!;
  String get _semanticLabel =>
      _level != null ? 'Severidade ${_level.label}' : _resolvedLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color statusColor = _resolvedColor;

    return Semantics(
      label: _semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.14),
          borderRadius: AppRadius.buttonRadius,
          border: Border.all(color: statusColor.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(_resolvedIcon, size: 14, color: statusColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _resolvedLabel,
                style: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
