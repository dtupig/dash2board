import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import 'bootstrap_error_screen.dart';
import 'providers.dart';
import 'router.dart';

/// Raiz do aplicativo.
///
/// Locale padrão pt-BR; o texto do usuário nunca é escalado além de 1.4x
/// para não quebrar os painéis densos, nem abaixo de 0.9x para não ferir
/// acessibilidade.
class ElytronApp extends ConsumerWidget {
  const ElytronApp({super.key, this.bootstrapError});

  /// Falha ocorrida antes de `runApp` (tipicamente Firebase não configurado).
  /// Quando presente, o app sobe numa tela de erro acionável em vez de ficar
  /// em branco.
  final Object? bootstrapError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    if (bootstrapError != null) {
      return MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: BootstrapErrorScreen(error: bootstrapError!),
      );
    }

    final GoRouter router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (BuildContext context, Widget? child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.4,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
