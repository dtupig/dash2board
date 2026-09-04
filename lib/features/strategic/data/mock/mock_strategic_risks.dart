import '../../domain/risk_item.dart';
import '../../domain/security_domain.dart';
import 'mock_strategic_dates.dart';

List<RiskItem> buildInitialRisks(DateTime anchor) {
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
      reviewDueAt: daysAfter(anchor, 30),
    ),
    RiskItem(
      id: 'risk-ecommerce-ddos',
      title: 'Indisponibilidade do e-commerce por ataque de negação de serviço',
      businessUnit: 'Varejo',
      domain: SecurityDomain.cloud,
      inherentScore: 70,
      residualScore: 40,
      annualLossExpectancy: 1800000,
      currency: 'BRL',
      treatment: RiskTreatment.mitigate,
      acceptance: RiskAcceptance.accepted,
      reviewDueAt: daysAfter(anchor, 90),
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
      reviewDueAt: daysAfter(anchor, 45),
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
      reviewDueAt: daysAfter(anchor, 60),
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
      reviewDueAt: daysAfter(anchor, 120),
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
      reviewDueAt: daysAfter(anchor, 180),
    ),
  ];
}
