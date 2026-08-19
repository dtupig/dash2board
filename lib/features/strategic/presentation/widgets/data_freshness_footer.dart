import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/strategic_providers.dart';
import '../../domain/posture_index.dart';

String _formatDateTimePtBr(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String hour = date.hour.toString().padLeft(2, '0');
  final String minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} às $hour:$minute';
}

/// Bloco 5 do painel do CISO: data/hora da última atualização e a origem
/// do dado, quando em modo de demonstração.
///
/// Não tem estado de carregamento/erro próprio: é um rodapé informativo
/// sobre o mesmo dado que `PostureHeadline` já resolve logo acima - duplicar
/// um esqueleto/erro aqui seria ruído, não informação nova. Enquanto o
/// índice não está disponível, o rodapé simplesmente não aparece.
class DataFreshnessFooter extends ConsumerWidget {
  const DataFreshnessFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PostureIndex> indexAsync = ref.watch(postureIndexProvider);
    final DateTime? capturedAt = indexAsync.value?.capturedAt;

    if (capturedAt == null) {
      return const SizedBox.shrink();
    }

    const String origin = AppConfig.mockMode ? ' · dados de demonstração' : '';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        'Dados de ${_formatDateTimePtBr(capturedAt)}$origin',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
