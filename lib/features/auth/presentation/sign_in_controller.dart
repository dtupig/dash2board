import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Estado das ações de autenticação disparadas pela UI.
///
/// `AsyncValue<void>`:
/// * `AsyncData` -> ocioso ou concluído com sucesso;
/// * `AsyncLoading` -> requisição em andamento (bloqueia o botão);
/// * `AsyncError` -> contém um `AppFailure` com mensagem segura em pt-BR.
final AsyncNotifierProvider<SignInController, void> signInControllerProvider =
    AsyncNotifierProvider<SignInController, void>(SignInController.new);

class SignInController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue<void>.loading();
    final AsyncValue<void> result = await AsyncValue.guard<void>(() async {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);
    });
    state = result;
    return !result.hasError;
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue<void>.loading();
    final AsyncValue<void> result = await AsyncValue.guard<void>(() async {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
    });
    state = result;
    return !result.hasError;
  }

  Future<void> signOut() async {
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard<void>(() async {
      await ref.read(authRepositoryProvider).signOut();
    });
  }

  /// Reavalia os custom claims - usado na tela de "acesso pendente".
  Future<void> refreshClaims() async {
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard<void>(() async {
      await ref.read(authRepositoryProvider).refreshClaims();
    });
  }
}
