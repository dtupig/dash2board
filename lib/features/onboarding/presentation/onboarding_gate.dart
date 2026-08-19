import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/user_role.dart';
import '../data/onboarding_repository.dart';
import 'onboarding_screen.dart';

/// Envolve o dashboard de uma persona: mostra a introdução de 3 telas por
/// cima dele na primeira vez, e nunca mais depois disso.
///
/// O dashboard já é construído por baixo desde o primeiro quadro (sem tela
/// em branco enquanto `shared_preferences` resolve) - a introdução aparece
/// como uma sobreposição assim que sabemos que ainda não foi vista.
class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({super.key, required this.role, required this.child});

  final UserRole role;
  final Widget child;

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate> {
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkFirstVisit();
  }

  Future<void> _checkFirstVisit() async {
    final bool seen =
        await ref.read(onboardingRepositoryProvider).hasSeen(widget.role);
    if (!mounted || seen) {
      return;
    }
    setState(() => _showOnboarding = true);
  }

  Future<void> _dismiss() async {
    await ref.read(onboardingRepositoryProvider).markSeen(widget.role);
    if (!mounted) {
      return;
    }
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child,
        if (_showOnboarding)
          OnboardingScreen(role: widget.role, onDone: _dismiss),
      ],
    );
  }
}
