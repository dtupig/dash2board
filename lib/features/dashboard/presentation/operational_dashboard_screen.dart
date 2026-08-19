import 'package:flutter/material.dart';

import '../../auth/domain/user_role.dart';
import '../../auth/presentation/persona_visuals.dart';
import '../../shell/persona_scaffold.dart';
import 'placeholder_panel.dart';

/// Persona 1 - time técnico operacional e tático.
class OperationalDashboardScreen extends StatelessWidget {
  const OperationalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const UserRole role = UserRole.operational;

    return PersonaScaffold(
      role: role,
      title: 'Operação de Segurança',
      subtitle:
          'O que está aberto, o que está estourando SLA e o que precisa de você agora.',
      children: <Widget>[
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
      ],
    );
  }
}
