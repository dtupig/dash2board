import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../data/onboarding_repository.dart';
import 'onboarding_screen.dart';

/// Envolve o dashboard de uma persona: mostra a introdução de 3 telas por
/// cima dele na primeira vez, e nunca mais depois disso.
///
/// O dashboard já é construído por baixo desde o primeiro quadro (sem tela
/// em branco enquanto o repositório resolve) - a introdução aparece como uma
/// sobreposição assim que sabemos que ainda não foi vista. Enquanto
/// `tenantId`/`uid` não estiverem resolvidos (usuário ainda carregando), não
/// mostra nada - a introdução precisa saber de quem é a flag.
class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({super.key, required this.role, required this.child});

  final UserRole role;
  final Widget child;

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate> {
  bool _showOnboarding = false;
  String? _checkedForUid;

  void _maybeCheck(AppUser? user) {
    if (user == null || user.uid.isEmpty || _checkedForUid == user.uid) {
      return;
    }
    _checkedForUid = user.uid;
    unawaited(_checkFirstVisit(user));
  }

  Future<void> _checkFirstVisit(AppUser user) async {
    final bool seen = await ref.read(onboardingRepositoryProvider).hasSeen(
          widget.role,
          tenantId: user.tenantId,
          uid: user.uid,
        );
    if (!mounted || seen) {
      return;
    }
    setState(() => _showOnboarding = true);
  }

  Future<void> _dismiss() async {
    final AppUser? user = ref.read(appUserProvider).value;
    if (user != null) {
      await ref.read(onboardingRepositoryProvider).markSeen(
            widget.role,
            tenantId: user.tenantId,
            uid: user.uid,
          );
    }
    if (!mounted) {
      return;
    }
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUser?>>(
      appUserProvider,
      (AsyncValue<AppUser?>? previous, AsyncValue<AppUser?> next) =>
          _maybeCheck(next.value),
    );
    _maybeCheck(ref.read(appUserProvider).value);

    return Stack(
      children: <Widget>[
        widget.child,
        if (_showOnboarding)
          OnboardingScreen(role: widget.role, onDone: _dismiss),
      ],
    );
  }
}
