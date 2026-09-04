import '../../domain/insight_item.dart';
import 'mock_strategic_dates.dart';

InsightItem _insight({
  required DateTime anchor,
  required String id,
  required String topic,
  required String title,
  required String summary,
  required int publishedDaysAgo,
  required bool isBenchmark,
}) {
  return InsightItem(
    id: id,
    topic: topic,
    title: title,
    summary: summary,
    publishedAt: daysBefore(anchor, publishedDaysAgo),
    sourceName: 'Elytron Threat Intelligence',
    sourceUrl: 'https://insights.elytronsecurity.com/$id',
    isBenchmark: isBenchmark,
  );
}

List<InsightItem> buildInsights(DateTime anchor) {
  InsightItem insight({
    required String id,
    required String topic,
    required String title,
    required String summary,
    required int publishedDaysAgo,
    required bool isBenchmark,
  }) =>
      _insight(
        anchor: anchor,
        id: id,
        topic: topic,
        title: title,
        summary: summary,
        publishedDaysAgo: publishedDaysAgo,
        isBenchmark: isBenchmark,
      );

  return <InsightItem>[
    insight(
      id: 'ransomware-varejo-2026',
      topic: 'Ameaças',
      title:
          'Aumento de 35% em ataques de ransomware contra o varejo brasileiro',
      summary:
          'Grupos de ransomware miram cadeias de suprimento do varejo com dupla extorsão.',
      publishedDaysAgo: 5,
      isBenchmark: true,
    ),
    insight(
      id: 'orcamento-ciso-2026',
      topic: 'Estratégia',
      title: 'Como CISOs de médio porte estão priorizando orçamento em 2026',
      summary:
          'Pesquisa com 200 CISOs mostra prioridade para identidade e segurança de aplicações.',
      publishedDaysAgo: 10,
      isBenchmark: true,
    ),
    insight(
      id: 'benchmark-resposta-incidentes',
      topic: 'Benchmark',
      title: 'Benchmark setorial: maturidade de resposta a incidentes',
      summary:
          'Comparativo de MTTA e MTTR entre empresas do mesmo porte e segmento.',
      publishedDaysAgo: 15,
      isBenchmark: true,
    ),
    insight(
      id: 'anpd-notificacao',
      topic: 'Regulatório',
      title: 'Nova resolução da ANPD sobre notificação de incidentes',
      summary:
          'Prazo e formato de comunicação de incidentes de segurança à autoridade nacional.',
      publishedDaysAgo: 20,
      isBenchmark: false,
    ),
    insight(
      id: 'checklist-pci-dss-4',
      topic: 'Compliance',
      title: 'Checklist: preparando o comitê para a auditoria de PCI DSS 4.0',
      summary:
          'Os requisitos que mais geram lacuna nas auditorias do último ano.',
      publishedDaysAgo: 25,
      isBenchmark: false,
    ),
    insight(
      id: 'terceiros-notificacao-tardia',
      topic: 'Terceiros',
      title:
          'Pesquisa Elytron: 60% dos incidentes em fornecedores não são notificados a tempo',
      summary:
          'Levantamento aponta lacunas em cláusulas contratuais de notificação de incidente.',
      publishedDaysAgo: 30,
      isBenchmark: false,
    ),
    insight(
      id: 'appsec-shift-left',
      topic: 'AppSec',
      title: 'Tendência: adoção de segurança de aplicações (AppSec) shift-left',
      summary:
          'Empresas que testam segurança no pipeline reduzem o custo de correção em até 6x.',
      publishedDaysAgo: 35,
      isBenchmark: false,
    ),
    insight(
      id: 'panorama-ot-2026',
      topic: 'Ameaças',
      title: 'Panorama de ameaças para o setor industrial (OT) em 2026',
      summary:
          'Convergência OT/IT amplia a superfície de ataque em plantas industriais.',
      publishedDaysAgo: 40,
      isBenchmark: false,
    ),
  ];
}
