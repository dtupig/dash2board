import '../domain/compliance_control.dart';
import '../domain/insight_item.dart';
import '../domain/posture_index.dart';
import '../domain/posture_snapshot.dart';
import '../domain/risk_item.dart';
import '../domain/security_domain.dart';
import '../domain/survey.dart';
import '../domain/tenant_profile.dart';
import 'strategic_repository.dart';

/// Dados de demonstração da persona estratégica, 100% em memória.
///
/// Conta a história de uma empresa brasileira de médio porte: postura em
/// melhora constante, com um recuo pontual, terceiros e appsec como as áreas
/// que ainda pedem atenção, e uma carteira de risco plausível para comitê.
///
/// Nada aqui usa `Random()` ou `DateTime.now()`: todo dado nasce de uma data
/// de referência fixa ([_anchor]), para que a demonstração seja
/// **reproduzível** — duas execuções, no mesmo dia ou em dias diferentes,
/// produzem exatamente os mesmos valores.
class MockStrategicRepository implements StrategicRepository {
  static const Duration _streamDelay = Duration(milliseconds: 400);

  /// Data de referência da demonstração ("hoje" na narrativa do painel).
  static final DateTime _anchor = DateTime.utc(2026, 8, 1);

  static DateTime _monthsBefore(DateTime from, int months) =>
      DateTime.utc(from.year, from.month - months, from.day);

  static DateTime _daysBefore(DateTime from, int days) =>
      from.subtract(Duration(days: days));

  static DateTime _daysAfter(DateTime from, int days) =>
      from.add(Duration(days: days));

  /// Índice geral mês a mês, dos 12 meses anteriores até hoje. Melhora
  /// consistente (64 → 72), com um recuo nos meses 7 e 8 do período.
  static const List<int> _monthlyOverallScores = <int>[
    64,
    65,
    66,
    67,
    68,
    69,
    66,
    65,
    68,
    70,
    71,
    72,
  ];

  static const int _peerMedian = 68;

  static const Map<SecurityDomain, int> _byDomainToday = <SecurityDomain, int>{
    SecurityDomain.identity: 81,
    SecurityDomain.endpoint: 76,
    SecurityDomain.cloud: 63,
    SecurityDomain.appsec: 58,
    SecurityDomain.data: 74,
    SecurityDomain.thirdParty: 55,
  };

  /// Variação de cada domínio nos últimos 30 dias - histórico curto usado só
  /// no detalhe de domínio, não no gráfico de tendência (que é o índice
  /// geral). Appsec e terceiros pioraram no mês, mesmo com a média geral
  /// melhorando - é exatamente o tipo de contraste que justifica o
  /// drill-down por domínio em vez de só olhar o número geral.
  static const Map<SecurityDomain, int> _byDomainDelta30d =
      <SecurityDomain, int>{
    SecurityDomain.identity: 2,
    SecurityDomain.endpoint: 1,
    SecurityDomain.cloud: 3,
    SecurityDomain.appsec: -2,
    SecurityDomain.data: 1,
    SecurityDomain.thirdParty: -1,
  };

  /// Receita anual do tenant - empresa brasileira de médio porte, multi
  /// unidade de negócio (docs/02_PERSONAS.md).
  static const double _annualRevenue = 180000000;

  static const Map<String, String> _businessUnitOwners = <String, String>{
    'Varejo': 'Camila Duarte, VP de Varejo',
    'Indústria': 'Marcelo Andrade, VP de Indústria',
    'Serviços Financeiros': 'Beatriz Nogueira, VP de Serviços Financeiros',
    'Corporativo': 'Rafael Souza, CFO',
  };

  /// Soma de ALE um trimestre atrás - documenta a melhora (12,83 milhões
  /// hoje, contra 14,2 milhões), coerente com a narrativa de postura em
  /// melhora constante.
  static const double _previousQuarterAle = 14200000;

  @override
  Stream<PostureIndex> watchPostureIndex(String tenantId) {
    return _afterDelay(() {
      final int previousMonthScore =
          _monthlyOverallScores[_monthlyOverallScores.length - 2];
      return PostureIndex(
        overallScore: _monthlyOverallScores.last,
        previousScore: previousMonthScore,
        capturedAt: _anchor,
        byDomain: _byDomainToday,
        peerMedian: _peerMedian,
        byDomainDelta30d: _byDomainDelta30d,
      );
    });
  }

  @override
  Stream<List<PostureSnapshot>> watchPostureHistory(
    String tenantId, {
    int months = 12,
  }) {
    return _afterDelay(() {
      final int count = months.clamp(0, _monthlyOverallScores.length).toInt();
      final int start = _monthlyOverallScores.length - count;
      return <PostureSnapshot>[
        for (int i = start; i < _monthlyOverallScores.length; i++)
          PostureSnapshot(
            // A série é o índice GERAL mês a mês, não uma trilha por
            // domínio: o campo `domain` só existe porque o modelo espelha o
            // schema de `posture_snapshots` do Firestore. Marcamos com o
            // domínio que mais pesa na narrativa do período (appsec), sem
            // que a tela de tendência precise interpretar esse campo.
            domain: SecurityDomain.appsec,
            score: _monthlyOverallScores[i],
            capturedAt: _monthsBefore(
              _anchor,
              _monthlyOverallScores.length - 1 - i,
            ),
            peerMedian: _peerMedian,
            delta30d: i == 0
                ? 0
                : _monthlyOverallScores[i] - _monthlyOverallScores[i - 1],
          ),
      ];
    });
  }

  @override
  Stream<List<ComplianceControl>> watchCompliance(
    String tenantId, {
    ComplianceFramework? framework,
  }) {
    return _afterDelay(() {
      final List<ComplianceControl> all = _complianceControls();
      if (framework == null) {
        return all;
      }
      return all
          .where((ComplianceControl control) => control.framework == framework)
          .toList(growable: false);
    });
  }

  @override
  Stream<List<RiskItem>> watchTopRisks(String tenantId, {int limit = 5}) {
    return _afterDelay(() {
      final List<RiskItem> risks = _sortedByAleDesc(_riskItems);
      return risks.take(limit).toList(growable: false);
    });
  }

  @override
  Stream<List<RiskItem>> watchAllRisks(String tenantId) {
    return _afterDelay(() => _sortedByAleDesc(_riskItems));
  }

  List<RiskItem> _sortedByAleDesc(List<RiskItem> risks) {
    return List<RiskItem>.of(risks)
      ..sort((RiskItem a, RiskItem b) =>
          b.annualLossExpectancy.compareTo(a.annualLossExpectancy));
  }

  @override
  Stream<TenantProfile> watchTenantProfile(String tenantId) {
    return _afterDelay(
      () => const TenantProfile(
        annualRevenue: _annualRevenue,
        businessUnitOwners: _businessUnitOwners,
        previousQuarterAle: _previousQuarterAle,
      ),
    );
  }

  @override
  Future<void> recordRiskDecision({
    required String tenantId,
    required String riskId,
    required RiskAcceptance decision,
    required String actorUid,
    required String boardNote,
  }) async {
    await Future<void>.delayed(_streamDelay);
    final int index = _riskItems.indexWhere((RiskItem r) => r.id == riskId);
    if (index == -1) {
      return;
    }
    // Só os campos que `firestore.rules` libera para o papel `board` -
    // nenhum outro campo do risco muda aqui, nem no mock.
    _riskItems[index] = _riskItems[index].copyWith(acceptance: decision);
  }

  @override
  Stream<List<InsightItem>> watchInsights(String tenantId, {int limit = 10}) {
    return _afterDelay(() {
      final List<InsightItem> insights = _insights();
      return insights.take(limit).toList(growable: false);
    });
  }

  /// Estado dos riscos NESTA execução do app: começa com `_initialRisks()` e
  /// muda quando o board registra uma decisão. Em memória, como todo o
  /// resto do mock.
  late final List<RiskItem> _riskItems = _initialRisks();

  /// Respostas gravadas nesta execução do app, por uid. Deliberadamente só
  /// em memória: reinicia zerado a cada execução, como um mock deve ser.
  final Map<String, Map<String, String>> _surveyResponsesByUid =
      <String, Map<String, String>>{};

  /// Quantos CISOs de outros tenants já responderam, antes de qualquer
  /// resposta desta sessão - a prova social que o convite mostra de saída.
  static const int _baseRespondentCount = 214;

  static const String _activeSurveyId = 'seguranca-2027-prioridades';

  Survey _activeSurvey(String uid) {
    const List<SurveyQuestion> questions = <SurveyQuestion>[
      SurveyQuestion(
        id: 'maior-obstaculo',
        prompt:
            'Qual é o maior obstáculo para reduzir as lacunas de compliance '
            'na sua empresa hoje?',
        options: <String>[
          'Orçamento insuficiente',
          'Falta de pessoal especializado',
          'Prioridade concorrente com outras áreas de TI',
          'Dificuldade em obter evidência dos donos de cada controle',
        ],
        peerDistribution: <int>[34, 29, 21, 16],
      ),
      SurveyQuestion(
        id: 'prazo-reducao',
        prompt: 'Em quanto tempo você espera reduzir pela metade o número de '
            'lacunas abertas?',
        options: <String>[
          'Até 3 meses',
          'De 3 a 6 meses',
          'De 6 a 12 meses',
          'Mais de 12 meses',
        ],
        peerDistribution: <int>[9, 31, 42, 18],
      ),
      SurveyQuestion(
        id: 'domínio-investido',
        prompt: 'Qual domínio de segurança recebeu mais investimento da sua '
            'empresa no último ano?',
        options: <String>[
          'Identidade e Acesso',
          'Nuvem',
          'Segurança de Aplicações',
          'Terceiros',
        ],
        peerDistribution: <int>[38, 27, 24, 11],
      ),
    ];

    return Survey(
      id: _activeSurveyId,
      title: 'Prioridades de segurança para 2027',
      description:
          'Leva menos de um minuto. Ao final, veja como sua resposta se '
          'compara à de outros CISOs do seu setor.',
      questions: questions,
      respondentCount: _baseRespondentCount + _surveyResponsesByUid.length,
      yourAnswers: _surveyResponsesByUid[uid],
    );
  }

  @override
  Stream<Survey?> watchActiveSurvey(String tenantId, String uid) {
    return _afterDelay(() => _activeSurvey(uid));
  }

  @override
  Future<void> submitSurveyResponse({
    required String tenantId,
    required String surveyId,
    required String uid,
    required Map<String, String> answers,
  }) async {
    await Future<void>.delayed(_streamDelay);
    _surveyResponsesByUid[uid] = Map<String, String>.of(answers);
  }

  Stream<T> _afterDelay<T>(T Function() compute) async* {
    await Future<void>.delayed(_streamDelay);
    yield compute();
  }

  List<ComplianceControl> _complianceControls() {
    String evidenceFor(String controlId, ControlStatus status) {
      return status == ControlStatus.gap
          ? ''
          : 'https://evidencias.elytronsecurity.com/tenant-demo/$controlId';
    }

    ComplianceControl control({
      required ComplianceFramework framework,
      required String controlId,
      required String title,
      required ControlStatus status,
      required String ownerName,
      required int reviewedDaysAgo,
      required SecurityDomain domain,
    }) {
      final String url = evidenceFor(controlId, status);
      return ComplianceControl(
        framework: framework,
        controlId: controlId,
        title: title,
        status: status,
        ownerName: ownerName,
        lastReviewedAt: _daysBefore(_anchor, reviewedDaysAgo),
        domain: domain,
        evidenceUrl: url.isEmpty ? null : url,
      );
    }

    return <ComplianceControl>[
      // ISO 27001
      control(
        framework: ComplianceFramework.iso27001,
        controlId: 'A.5.1',
        title: 'Políticas de segurança da informação',
        status: ControlStatus.compliant,
        ownerName: 'Mariana Costa',
        reviewedDaysAgo: 20,
        domain: SecurityDomain.data,
      ),
      control(
        framework: ComplianceFramework.iso27001,
        controlId: 'A.8.1',
        title: 'Inventário de ativos de informação',
        status: ControlStatus.compliant,
        ownerName: 'Eduardo Lima',
        reviewedDaysAgo: 35,
        domain: SecurityDomain.endpoint,
      ),
      control(
        framework: ComplianceFramework.iso27001,
        controlId: 'A.9.2',
        title: 'Gestão de acesso de usuários',
        status: ControlStatus.partial,
        ownerName: 'Patrícia Alves',
        reviewedDaysAgo: 50,
        domain: SecurityDomain.identity,
      ),
      control(
        framework: ComplianceFramework.iso27001,
        controlId: 'A.12.6',
        title: 'Gestão de vulnerabilidades técnicas',
        status: ControlStatus.gap,
        ownerName: 'Fernando Rocha',
        reviewedDaysAgo: 65,
        domain: SecurityDomain.appsec,
      ),
      control(
        framework: ComplianceFramework.iso27001,
        controlId: 'A.16.1',
        title: 'Gestão de incidentes de segurança da informação',
        status: ControlStatus.compliant,
        ownerName: 'Juliana Prado',
        reviewedDaysAgo: 15,
        domain: SecurityDomain.endpoint,
      ),
      control(
        framework: ComplianceFramework.iso27001,
        controlId: 'A.5.23',
        title: 'Segurança da informação para uso de serviços em nuvem',
        status: ControlStatus.partial,
        ownerName: 'Rodrigo Teixeira',
        reviewedDaysAgo: 80,
        domain: SecurityDomain.cloud,
      ),
      // NIST CSF
      control(
        framework: ComplianceFramework.nistCsf,
        controlId: 'ID.AM-2',
        title: 'Inventário de plataformas e aplicações de software',
        status: ControlStatus.compliant,
        ownerName: 'Eduardo Lima',
        reviewedDaysAgo: 28,
        domain: SecurityDomain.endpoint,
      ),
      control(
        framework: ComplianceFramework.nistCsf,
        controlId: 'PR.AC-1',
        title: 'Identidades e credenciais gerenciadas para usuários',
        status: ControlStatus.compliant,
        ownerName: 'Mariana Costa',
        reviewedDaysAgo: 22,
        domain: SecurityDomain.identity,
      ),
      control(
        framework: ComplianceFramework.nistCsf,
        controlId: 'PR.DS-5',
        title: 'Proteção contra vazamento de dados',
        status: ControlStatus.partial,
        ownerName: 'Patrícia Alves',
        reviewedDaysAgo: 44,
        domain: SecurityDomain.data,
      ),
      control(
        framework: ComplianceFramework.nistCsf,
        controlId: 'DE.CM-8',
        title: 'Varredura contínua de vulnerabilidades',
        status: ControlStatus.gap,
        ownerName: 'Fernando Rocha',
        reviewedDaysAgo: 70,
        domain: SecurityDomain.appsec,
      ),
      control(
        framework: ComplianceFramework.nistCsf,
        controlId: 'RS.RP-1',
        title: 'Plano de resposta a incidentes executado',
        status: ControlStatus.compliant,
        ownerName: 'Juliana Prado',
        reviewedDaysAgo: 18,
        domain: SecurityDomain.endpoint,
      ),
      control(
        framework: ComplianceFramework.nistCsf,
        controlId: 'ID.SC-4',
        title: 'Fornecedores monitorados quanto ao risco introduzido',
        status: ControlStatus.gap,
        ownerName: 'Rodrigo Teixeira',
        reviewedDaysAgo: 90,
        domain: SecurityDomain.thirdParty,
      ),
      // LGPD
      control(
        framework: ComplianceFramework.lgpd,
        controlId: 'Art.6',
        title: 'Princípios do tratamento de dados pessoais observados',
        status: ControlStatus.compliant,
        ownerName: 'Patrícia Alves',
        reviewedDaysAgo: 30,
        domain: SecurityDomain.data,
      ),
      control(
        framework: ComplianceFramework.lgpd,
        controlId: 'Art.46',
        title: 'Medidas de segurança técnicas e administrativas',
        status: ControlStatus.compliant,
        ownerName: 'Mariana Costa',
        reviewedDaysAgo: 25,
        domain: SecurityDomain.data,
      ),
      control(
        framework: ComplianceFramework.lgpd,
        controlId: 'Art.48',
        title: 'Comunicação de incidente de segurança à ANPD',
        status: ControlStatus.partial,
        ownerName: 'Fernando Rocha',
        reviewedDaysAgo: 55,
        domain: SecurityDomain.endpoint,
      ),
      control(
        framework: ComplianceFramework.lgpd,
        controlId: 'Art.37',
        title: 'Registro das operações de tratamento de dados',
        status: ControlStatus.compliant,
        ownerName: 'Juliana Prado',
        reviewedDaysAgo: 40,
        domain: SecurityDomain.data,
      ),
      control(
        framework: ComplianceFramework.lgpd,
        controlId: 'Art.41',
        title: 'Encarregado de proteção de dados (DPO) formalizado',
        status: ControlStatus.compliant,
        ownerName: 'Eduardo Lima',
        reviewedDaysAgo: 60,
        domain: SecurityDomain.data,
      ),
      control(
        framework: ComplianceFramework.lgpd,
        controlId: 'Art.39',
        title: 'Contratos com operadores de dados revisados',
        status: ControlStatus.partial,
        ownerName: 'Rodrigo Teixeira',
        reviewedDaysAgo: 75,
        domain: SecurityDomain.thirdParty,
      ),
      // PCI DSS
      control(
        framework: ComplianceFramework.pciDss,
        controlId: 'Req.1',
        title: 'Firewall e segmentação de rede',
        status: ControlStatus.compliant,
        ownerName: 'Fernando Rocha',
        reviewedDaysAgo: 33,
        domain: SecurityDomain.cloud,
      ),
      control(
        framework: ComplianceFramework.pciDss,
        controlId: 'Req.3',
        title: 'Proteção de dados de titulares de cartão armazenados',
        status: ControlStatus.compliant,
        ownerName: 'Mariana Costa',
        reviewedDaysAgo: 27,
        domain: SecurityDomain.data,
      ),
      control(
        framework: ComplianceFramework.pciDss,
        controlId: 'Req.6',
        title: 'Desenvolvimento seguro de aplicações',
        status: ControlStatus.gap,
        ownerName: 'Patrícia Alves',
        reviewedDaysAgo: 85,
        domain: SecurityDomain.appsec,
      ),
      control(
        framework: ComplianceFramework.pciDss,
        controlId: 'Req.8',
        title: 'Identificação e autenticação de acesso',
        status: ControlStatus.compliant,
        ownerName: 'Juliana Prado',
        reviewedDaysAgo: 19,
        domain: SecurityDomain.identity,
      ),
      control(
        framework: ComplianceFramework.pciDss,
        controlId: 'Req.10',
        title: 'Rastreamento e monitoramento de todos os acessos',
        status: ControlStatus.partial,
        ownerName: 'Eduardo Lima',
        reviewedDaysAgo: 48,
        domain: SecurityDomain.identity,
      ),
      control(
        framework: ComplianceFramework.pciDss,
        controlId: 'Req.12',
        title: 'Avaliação de risco de fornecedores terceirizados',
        status: ControlStatus.gap,
        ownerName: 'Rodrigo Teixeira',
        reviewedDaysAgo: 95,
        domain: SecurityDomain.thirdParty,
      ),
    ];
  }

  List<RiskItem> _initialRisks() {
    return <RiskItem>[
      RiskItem(
        id: 'risk-thirdparty-payments',
        title:
            'Vazamento de dados de clientes por falha de segurança em processador de pagamentos terceirizado',
        businessUnit: 'Varejo',
        domain: SecurityDomain.thirdParty,
        inherentScore: 82,
        residualScore: 55,
        annualLossExpectancy: 4200000,
        currency: 'BRL',
        treatment: RiskTreatment.mitigate,
        acceptance: RiskAcceptance.pending,
        reviewDueAt: _daysAfter(_anchor, 30),
      ),
      RiskItem(
        id: 'risk-ecommerce-ddos',
        title:
            'Indisponibilidade do e-commerce por ataque de negação de serviço',
        businessUnit: 'Varejo',
        domain: SecurityDomain.cloud,
        inherentScore: 70,
        residualScore: 40,
        annualLossExpectancy: 1800000,
        currency: 'BRL',
        treatment: RiskTreatment.mitigate,
        acceptance: RiskAcceptance.accepted,
        reviewDueAt: _daysAfter(_anchor, 90),
      ),
      RiskItem(
        id: 'risk-ot-segmentation',
        title:
            'Falha de segregação de acesso entre sistemas corporativos e de manufatura (OT/IT)',
        businessUnit: 'Indústria',
        domain: SecurityDomain.endpoint,
        inherentScore: 75,
        residualScore: 50,
        annualLossExpectancy: 2600000,
        currency: 'BRL',
        treatment: RiskTreatment.mitigate,
        acceptance: RiskAcceptance.pending,
        reviewDueAt: _daysAfter(_anchor, 45),
      ),
      RiskItem(
        id: 'risk-ip-exposure',
        title:
            'Exposição de propriedade intelectual industrial por aplicação vulnerável',
        businessUnit: 'Indústria',
        domain: SecurityDomain.appsec,
        inherentScore: 68,
        residualScore: 48,
        annualLossExpectancy: 950000,
        currency: 'BRL',
        treatment: RiskTreatment.mitigate,
        acceptance: RiskAcceptance.pending,
        reviewDueAt: _daysAfter(_anchor, 60),
      ),
      RiskItem(
        id: 'risk-transaction-fraud',
        title: 'Fraude em transações digitais por falha de autenticação',
        businessUnit: 'Serviços Financeiros',
        domain: SecurityDomain.identity,
        inherentScore: 60,
        residualScore: 30,
        annualLossExpectancy: 3100000,
        currency: 'BRL',
        treatment: RiskTreatment.transfer,
        acceptance: RiskAcceptance.accepted,
        reviewDueAt: _daysAfter(_anchor, 120),
      ),
      RiskItem(
        id: 'risk-regulatory-delay',
        title:
            'Não conformidade regulatória por atraso na resposta a um ataque cibernético',
        businessUnit: 'Corporativo',
        domain: SecurityDomain.data,
        inherentScore: 45,
        residualScore: 25,
        annualLossExpectancy: 180000,
        currency: 'BRL',
        treatment: RiskTreatment.accept,
        acceptance: RiskAcceptance.accepted,
        reviewDueAt: _daysAfter(_anchor, 180),
      ),
    ];
  }

  List<InsightItem> _insights() {
    InsightItem insight({
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
        publishedAt: _daysBefore(_anchor, publishedDaysAgo),
        sourceName: 'Elytron Threat Intelligence',
        sourceUrl: 'https://insights.elytronsecurity.com/$id',
        isBenchmark: isBenchmark,
      );
    }

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
        title:
            'Tendência: adoção de segurança de aplicações (AppSec) shift-left',
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
}
