import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/data/mock_auth_repository.dart';
import '../features/auth/domain/app_user.dart';

/// Repositório de autenticação (substituível em testes com `overrideWith`).
///
/// Este é o ÚNICO ponto do app que sabe se estamos em modo de demonstração.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
  if (AppConfig.useMockData) {
    final MockAuthRepository repository = MockAuthRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  return FirebaseAuthRepository();
});

/// Usuário autenticado e resolvido (papel + tenant). `null` = deslogado.
final StreamProvider<AppUser?> appUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).watchCurrentUser(),
);

/// Modo de tema escolhido pelo usuário. O produto é dark-first, portanto o
/// valor inicial é [ThemeMode.dark] e não [ThemeMode.system].
final NotifierProvider<ThemeModeController, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  void updateMode(ThemeMode mode) => state = mode;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
