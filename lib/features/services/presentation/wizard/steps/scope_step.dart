import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/service_offering.dart';

/// Passo 2 - escopo. Muda conforme `offering.requiresScopeAssets`: lista de
/// alvos, ou volume/abrangência quando o serviço não pede alvos.
class ScopeStep extends StatelessWidget {
  const ScopeStep({
    super.key,
    required this.offering,
    required this.showErrors,
    required this.assetsController,
    required this.volumeController,
    required this.hasContent,
  });

  final ServiceOffering offering;
  final bool showErrors;
  final TextEditingController assetsController;
  final TextEditingController volumeController;
  final bool hasContent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool missing = showErrors && !hasContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Qual é o escopo?', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          offering.requiresScopeAssets
              ? 'Liste os alvos - domínios, aplicações, repositórios, faixas '
                  'de IP ou contas de nuvem. Um por linha, ou cole uma lista.'
              : 'Este serviço não tem um alvo técnico único - descreva o '
                  'volume ou a abrangência.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: offering.requiresScopeAssets
              ? assetsController
              : volumeController,
          maxLines: offering.requiresScopeAssets ? 6 : 3,
          decoration: InputDecoration(
            hintText: offering.requiresScopeAssets
                ? 'app.empresa.com\napi.empresa.com\n203.0.113.0/24'
                : 'Ex.: 120 colaboradores, 8 fornecedores críticos',
            border: const OutlineInputBorder(),
            errorText: missing ? 'Informe ao menos um item.' : null,
          ),
        ),
      ],
    );
  }
}
