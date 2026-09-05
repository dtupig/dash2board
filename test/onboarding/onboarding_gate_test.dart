import 'package:elytron_dash2board/app/providers.dart';
import 'package:elytron_dash2board/core/theme/app_theme.dart';
import 'package:elytron_dash2board/features/auth/domain/app_user.dart';
import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/onboarding/data/onboarding_repository.dart';
import 'package:elytron_dash2board/features/onboarding/presentation/onboarding_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositório em memória - equivalente de teste ao Firestore real, sem
/// exigir emulador. Chave por `uid` + papel, igual ao documento de produção.
class _InMemoryOnboardingRepository implements OnboardingRepository {
  final Set<String> _seen = <String>{};

  static String _key(String uid, UserRole role) => '$uid:${role.wireValue}';

  @override
  Future<bool> hasSeen(
    UserRole role, {
    required String tenantId,
    required String uid,
  }) async {
    return _seen.contains(_key(uid, role));
  }

  @override
  Future<void> markSeen(
    UserRole role, {
    required String tenantId,
    required String uid,
  }) async {
    _seen.add(_key(uid, role));
  }
}

void main() {
  const AppUser testUser = AppUser(
    uid: 'ciso-demo',
    email: 'ciso@demo.elytron',
    role: UserRole.strategic,
    tenantId: 'tenant-demo',
  );

  Widget harness(OnboardingRepository repository) {
    return ProviderScope(
      overrides: [
        appUserProvider.overrideWith(
          (Ref ref) => Stream<AppUser?>.value(testUser),
        ),
        onboardingRepositoryProvider.overrideWith((Ref ref) => repository),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const OnboardingGate(
          role: UserRole.strategic,
          child: Scaffold(body: Center(child: Text('Painel do CISO'))),
        ),
      ),
    );
  }

  testWidgets('na primeira visita, mostra a introdução por cima do painel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(harness(_InMemoryOnboardingRepository()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sua postura, de relance'), findsOneWidget);
    // O painel já está construído por baixo, só coberto pela introdução.
    expect(find.text('Painel do CISO'), findsOneWidget);
  });

  testWidgets('pular marca como visto e não aparece de novo', (
    WidgetTester tester,
  ) async {
    final _InMemoryOnboardingRepository repository =
        _InMemoryOnboardingRepository();

    await tester.pumpWidget(harness(repository));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Pular'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sua postura, de relance'), findsNothing);

    // Reabrindo o painel (nova árvore, mesmo repositório) - a introdução
    // não deve reaparecer, pois já foi marcada como vista para este `uid`.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(harness(repository));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sua postura, de relance'), findsNothing);
    expect(find.text('Painel do CISO'), findsOneWidget);
  });

  testWidgets('já visto anteriormente, não mostra a introdução', (
    WidgetTester tester,
  ) async {
    final _InMemoryOnboardingRepository repository =
        _InMemoryOnboardingRepository();
    await repository.markSeen(
      UserRole.strategic,
      tenantId: testUser.tenantId,
      uid: testUser.uid,
    );

    await tester.pumpWidget(harness(repository));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Sua postura, de relance'), findsNothing);
    expect(find.text('Painel do CISO'), findsOneWidget);
  });
}
