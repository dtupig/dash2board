import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/app_user.dart';
import 'app_route.dart';

/// A única guarda de navegação do app. *Fail-closed*: enquanto o estado do
/// usuário não estiver resolvido, o usuário fica no splash; qualquer
/// inconsistência leva de volta à tela de boas-vindas. Isolado de
/// `router.dart` para manter aquele arquivo abaixo do limite de 250 linhas.
String? Function(BuildContext, GoRouterState) buildRedirect(
  ValueNotifier<AsyncValue<AppUser?>> authState,
) {
  return (BuildContext context, GoRouterState state) {
    final AsyncValue<AppUser?> snapshot = authState.value;
    final String location = state.matchedLocation;

    // 1. Ainda resolvendo a sessão -> mantém o splash.
    if (snapshot.isLoading) {
      return location == AppRoute.splash ? null : AppRoute.splash;
    }

    // 2. Falha ao resolver a sessão -> volta para a entrada pública.
    final AppUser? user = snapshot.value;
    if (snapshot.hasError || user == null) {
      return AppRoute.publicRoutes.contains(location) &&
              location != AppRoute.splash
          ? null
          : AppRoute.welcome;
    }

    // 3. Autenticado, mas sem papel/tenant provisionado.
    if (!user.canEnterDashboard) {
      return location == AppRoute.pendingAccess ? null : AppRoute.pendingAccess;
    }

    // 4. Autenticado e liberado: sai das rotas de entrada.
    final String home = AppRoute.forRole(user.role);
    if (AppRoute.entryRoutes.contains(location)) {
      return home;
    }

    // 5. Impede acesso ao dashboard de outra persona - e a QUALQUER rota
    // filha dele (ex.: `/estrategia/compliance`), não só ao path exato.
    // Comparar por prefixo aqui é o que faz o guard valer para subrotas
    // futuras sem precisar listá-las uma a uma.
    const Set<String> dashboards = <String>{
      AppRoute.operational,
      AppRoute.strategic,
      AppRoute.board,
    };
    for (final String dashboard in dashboards) {
      final bool isUnderDashboard =
          location == dashboard || location.startsWith('$dashboard/');
      if (isUnderDashboard && dashboard != home) {
        return home;
      }
    }

    return null;
  };
}
