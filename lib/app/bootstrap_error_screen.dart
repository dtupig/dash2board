import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Tela exibida quando a inicialização do Firebase falha.
///
/// Existe por um motivo específico: se `main()` lançar antes de `runApp`, o
/// usuário vê uma tela em branco e nenhuma pista do que aconteceu. Aqui o app
/// SEMPRE sobe, e o erro vira uma instrução acionável.
class BootstrapErrorScreen extends StatelessWidget {
  const BootstrapErrorScreen({super.key, required this.error});

  final Object error;

  bool get _looksLikePlaceholder =>
      error.toString().contains('firebase_options.dart');

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.cloud_off_outlined, size: 44, color: scheme.error),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Firebase não inicializou',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _looksLikePlaceholder
                        ? 'O arquivo lib/firebase_options.dart ainda é o '
                            'placeholder. Rode `flutterfire configure` para '
                            'gerar as opções reais do projeto.'
                        : 'A conexão com o projeto Firebase falhou na '
                            'inicialização do aplicativo.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Para trabalhar na interface agora, rode em modo de '
                    'demonstração:',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: AppRadius.fieldRadius,
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: SelectableText(
                      'flutter run --dart-define=MOCK=true',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Detalhe técnico', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  SelectableText(
                    error.toString(),
                    style: theme.textTheme.bodySmall,
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
