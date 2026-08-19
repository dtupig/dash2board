import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/aurora_backdrop.dart';
import '../../../core/widgets/elytron_logo.dart';

/// Tela exibida enquanto a sessão e os custom claims são resolvidos.
///
/// Não decide nada: quem redireciona é o `redirect` do GoRouter. Aqui só
/// garantimos que o usuário nunca veja um dashboard antes do papel estar
/// confirmado (comportamento *fail-closed*).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // "Reduzir movimento": a indicação indeterminada do Flutter anima para
    // sempre enquanto está na árvore. Com o pedido ativo, mostramos uma
    // barra estática (mesma leitura de "processando", sem animação
    // contínua) em vez de tentar pausar uma animação que não é nossa.
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(theme.brightness),
      child: Scaffold(
        body: AuroraBackdrop(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const ElytronLogo(size: 88),
                const SizedBox(height: AppSpacing.xl),
                const ElytronWordmark(),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: AppRadius.fieldRadius,
                    child: LinearProgressIndicator(
                      value: reduceMotion ? 0.6 : null,
                      minHeight: 3,
                      color: theme.colorScheme.primary,
                      backgroundColor:
                          theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Verificando credenciais e perfil de acesso…',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
