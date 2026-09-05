import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/firestore_paths.dart';
import '../../auth/domain/user_role.dart';

/// Guarda, por persona, se o usuário já viu a introdução de 3 telas do
/// painel dela.
///
/// `tenantId`/`uid` são explícitos (regra do projeto: nenhum acesso a dado
/// de cliente sem tenant explícito), mas a implementação de demonstração os
/// ignora - ver [SharedPreferencesOnboardingRepository].
abstract interface class OnboardingRepository {
  Future<bool> hasSeen(
    UserRole role, {
    required String tenantId,
    required String uid,
  });

  Future<void> markSeen(
    UserRole role, {
    required String tenantId,
    required String uid,
  });
}

/// Implementação de demonstração: chave por papel e por *dispositivo*, não
/// por conta. Usada só em `AppConfig.useMockData` - lá não há sessão real
/// entre plataformas para persistir, e simplifica testar cada persona sem
/// Firestore.
class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  static String _key(UserRole role) => 'onboarding_seen_${role.wireValue}';

  @override
  Future<bool> hasSeen(
    UserRole role, {
    required String tenantId,
    required String uid,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(role)) ?? false;
  }

  @override
  Future<void> markSeen(
    UserRole role, {
    required String tenantId,
    required String uid,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(role), true);
  }
}

/// Implementação de produção: um campo por papel no documento de
/// preferências do usuário (`/tenants/{tenantId}/preferences/{uid}`), para
/// que "já visto" valha em qualquer plataforma na mesma conta - mobile e
/// web compartilham o mesmo documento.
class FirestoreOnboardingRepository implements OnboardingRepository {
  FirestoreOnboardingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _fieldPrefix = 'onboardingSeen';

  @override
  Future<bool> hasSeen(
    UserRole role, {
    required String tenantId,
    required String uid,
  }) async {
    final DocumentSnapshot<Map<String, Object?>> snapshot =
        await _firestore.doc(FirestorePaths.preferences(tenantId, uid)).get();
    final Map<String, Object?>? seenByRole =
        snapshot.data()?[_fieldPrefix] as Map<String, Object?>?;
    return seenByRole?[role.wireValue] == true;
  }

  @override
  Future<void> markSeen(
    UserRole role, {
    required String tenantId,
    required String uid,
  }) async {
    await _firestore.doc(FirestorePaths.preferences(tenantId, uid)).set(
      <String, Object?>{
        _fieldPrefix: <String, Object?>{role.wireValue: true},
      },
      SetOptions(merge: true),
    );
  }
}

final Provider<OnboardingRepository> onboardingRepositoryProvider =
    Provider<OnboardingRepository>((ref) {
  if (AppConfig.useMockData) {
    return SharedPreferencesOnboardingRepository();
  }
  return FirestoreOnboardingRepository();
});
