import 'package:flutter/material.dart';

import '../../auth/domain/user_role.dart';

/// Uma tela da introdução de 3 telas de uma persona.
class OnboardingPageData {
  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

/// As 3 telas de introdução de cada persona - o que o painel dela entrega,
/// não uma lista de recursos genérica.
///
/// Operação ainda é um painel de demonstração (as telas reais chegam num
/// próximo prompt): a cópia é honesta sobre isso em vez de prometer uma
/// capacidade que ainda não existe.
List<OnboardingPageData> onboardingPagesFor(UserRole role) {
  return switch (role) {
    UserRole.strategic => const <OnboardingPageData>[
        OnboardingPageData(
          icon: Icons.trending_up_rounded,
          title: 'Sua postura, de relance',
          description:
              'Um índice de segurança consolidado, a tendência dos últimos '
              '12 meses e como sua empresa se compara à mediana do setor.',
        ),
        OnboardingPageData(
          icon: Icons.fact_check_outlined,
          title: 'Compliance com evidência',
          description:
              'O percentual de conformidade por framework (ISO 27001, NIST '
              'CSF, LGPD, PCI DSS) e, para cada controle, a evidência que '
              'sustenta esse número perante auditoria.',
        ),
        OnboardingPageData(
          icon: Icons.picture_as_pdf_outlined,
          title: 'Pronto para a reunião',
          description:
              'Insights curados pela Elytron, pesquisas com pares do seu '
              'setor e um briefing executivo de uma página, pronto para '
              'compartilhar em PDF.',
        ),
      ],
    UserRole.board => const <OnboardingPageData>[
        OnboardingPageData(
          icon: Icons.savings_outlined,
          title: 'Um número, não cem',
          description:
              'A exposição financeira estimada do risco cibernético do '
              'negócio, em Real, e como percentual da receita anual.',
        ),
        OnboardingPageData(
          icon: Icons.account_tree_outlined,
          title: 'Por unidade de negócio',
          description:
              'Onde o risco pesa mais, e o nome do executivo responsável por '
              'cada unidade - risco sem dono nomeado não gera decisão.',
        ),
        OnboardingPageData(
          icon: Icons.gavel_outlined,
          title: 'Decida direto daqui',
          description:
              'Aceite um risco ou peça um plano de mitigação ao time de '
              'segurança, com justificativa registrada na trilha de '
              'auditoria.',
        ),
      ],
    UserRole.operational => const <OnboardingPageData>[
        OnboardingPageData(
          icon: Icons.local_fire_department_outlined,
          title: 'Sua fila, em breve aqui',
          description:
              'Este painel vai reunir incidentes abertos por severidade, '
              'dono e tempo em aberto, atualizados em tempo real. Por '
              'enquanto, você está vendo uma prévia do que está por vir.',
        ),
        OnboardingPageData(
          icon: Icons.bug_report_outlined,
          title: 'Vulnerabilidades priorizadas',
          description:
              'Quando estiver pronto, este espaço vai cruzar exploração '
              'ativa com a criticidade do ativo, para você saber o que '
              'corrigir primeiro.',
        ),
        OnboardingPageData(
          icon: Icons.checklist_rtl_outlined,
          title: 'Ainda uma demonstração',
          description:
              'Os cartões que você vê agora mostram de onde cada dado vai '
              'vir - nenhum incidente real está sendo lido ainda. Fale com a '
              'Elytron para saber quando essa parte entra no ar.',
        ),
      ],
    UserRole.pending => const <OnboardingPageData>[],
  };
}
