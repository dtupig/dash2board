import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_route.dart';
import '../../app/providers.dart';

/// Botão de voltar que nunca deixa a pessoa presa numa tela.
///
/// Várias rotas (`/servicos`, `/servicos/solicitacoes`,
/// `/estrategia/insights`, `/estrategia/briefing`, `/estrategia/compliance`)
/// são hoje alcançadas a partir do dashboard com `context.go`, que troca a
/// pilha de navegação inteira em vez de empilhar - por isso o botão de
/// voltar padrão do `AppBar` (que só aparece quando há algo para dar `pop`)
/// não aparece, e a pessoa fica sem saída (achado de teste manual,
/// 04/09/2026). Este botão cobre os dois casos: se houver histórico, volta
/// nele; senão, vai para o painel da própria persona - nunca fica preso.
class BackOrHomeButton extends ConsumerWidget {
  const BackOrHomeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Voltar',
      onPressed: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        final role = ref.read(appUserProvider).value?.role;
        context.go(role == null ? AppRoute.welcome : AppRoute.forRole(role));
      },
    );
  }
}
