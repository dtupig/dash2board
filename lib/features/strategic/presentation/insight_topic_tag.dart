import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Selo de tópico do insight (ex.: "Ameaças", "Compliance"), reusado no
/// card do feed e no detalhe em tela cheia.
class TopicTag extends StatelessWidget {
  const TopicTag({super.key, required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          topic,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
        ),
      ),
    );
  }
}
