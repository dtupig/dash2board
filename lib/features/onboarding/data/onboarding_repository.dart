import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/domain/user_role.dart';

/// Guarda, por persona, se o usuário já viu a introdução de 3 telas do
/// painel dela.
///
/// Uma chave por papel (não por uid): o mesmo dispositivo pode logar com
/// contas diferentes da mesma persona sem repetir a introdução, e a troca
/// de persona sempre mostra a introdução daquela persona pela primeira vez.
abstract interface class OnboardingRepository {
  Future<bool> hasSeen(UserRole role);
  Future<void> markSeen(UserRole role);
}

class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  static String _key(UserRole role) => 'onboarding_seen_${role.wireValue}';

  @override
  Future<bool> hasSeen(UserRole role) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(role)) ?? false;
  }

  @override
  Future<void> markSeen(UserRole role) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(role), true);
  }
}

final Provider<OnboardingRepository> onboardingRepositoryProvider =
    Provider<OnboardingRepository>((ref) {
  return SharedPreferencesOnboardingRepository();
});
