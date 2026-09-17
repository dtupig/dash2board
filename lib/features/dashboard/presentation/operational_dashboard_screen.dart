import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/surface_card.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/persona_visuals.dart';
import '../../shell/persona_scaffold.dart';
import 'placeholder_panel.dart';

/// Persona 1 - time técnico operacional e tático.
///
/// **Ainda um painel de demonstração**: os 3 blocos abaixo são
/// `PlaceholderPanel` ("Em breve") porque não existe hoje, em lugar nenhum
/// do app (mobile incluso), fila de incidente, priorização de
/// vulnerabilidade nem triagem real - é conteúdo pendente de um módulo
/// próprio, não uma composição de tela larga que esta história possa
/// resolver sozinha. O mockup web da Fase 1 mostra os mesmos 3 blocos com
/// dado de exemplo numa grade de 3 colunas - reproduzido aqui **na
/// disposição**, não no conteúdo: continuar honesto sobre o que é
/// demonstração pesa mais do que bater o mockup ao pé da letra.
class OperationalDashboardScreen extends StatelessWidget {
  const OperationalDashboardScreen({super.key});

  void _openServices(BuildContext context) {
    // Caminho literal em vez de importar `app/router.dart` (evita import
    // circular entre o roteador e as telas que ele registra). `push`, não
    // `go` - preserva o dashboard na pilha, senão a tela de destino fica
    // sem botão de voltar (achado de teste manual, 04/09/2026).
    context.push('/servicos');
  }

  @override
  Widget build(BuildContext context) {
    const UserRole role = UserRole.operational;
    final bool isLarge = LayoutSize.of(context) == LayoutSize.large;

    final List<Widget> panels = <Widget>[
      PlaceholderPanel(
        title: 'Incidentes ativos',
        description:
            'Fila por severidade, dono e tempo em aberto, com atualização em '
            'tempo real via snapshots do Firestore.',
        accent: role.accent,
        icon: Icons.local_fire_department_outlined,
      ),
      PlaceholderPanel(
        title: 'Vulnerabilidades priorizadas',
        description:
            'CVEs com exploração ativa cruzadas com criticidade do ativo e '
            'exposição na internet.',
        accent: role.accent,
        icon: Icons.bug_report_outlined,
      ),
      PlaceholderPanel(
        title: 'Fila do turno',
        description:
            'Tarefas táticas atribuídas ao analista logado, com prazo e '
            'origem (detecção, auditoria ou pedido do CISO).',
        accent: role.accent,
        icon: Icons.checklist_rtl_outlined,
      ),
    ];

    return PersonaScaffold(
      role: role,
      title: 'Operação de Segurança',
      subtitle:
          'O que está aberto, o que está estourando SLA e o que precisa de você agora.',
      children: <Widget>[
        SurfaceCard(
          accent: role.accent,
          onTap: () => _openServices(context),
          semanticLabel: 'Serviços. Relatórios contratados e catálogo para '
              'demandar um novo serviço à Elytron.',
          child: const ExcludeSemantics(
            child: Row(
              children: <Widget>[
                Icon(Icons.design_services_outlined),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text('Serviços - relatórios e demanda de RFS'),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isLarge)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < panels.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: AppSpacing.lg),
                  Expanded(child: panels[i]),
                ],
              ],
            ),
          )
        else
          ...panels,
      ],
    );
  }
}
