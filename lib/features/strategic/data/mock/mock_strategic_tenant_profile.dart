import '../../domain/tenant_profile.dart';

/// Receita anual do tenant - empresa brasileira de médio porte, multi
/// unidade de negócio (docs/02_PERSONAS.md).
const double _annualRevenue = 180000000;

const Map<String, String> _businessUnitOwners = <String, String>{
  'Varejo': 'Camila Duarte, VP de Varejo',
  'Indústria': 'Marcelo Andrade, VP de Indústria',
  'Serviços Financeiros': 'Beatriz Nogueira, VP de Serviços Financeiros',
  'Corporativo': 'Rafael Souza, CFO',
};

/// Soma de ALE um trimestre atrás - documenta a melhora (12,83 milhões
/// hoje, contra 14,2 milhões), coerente com a narrativa de postura em
/// melhora constante.
const double _previousQuarterAle = 14200000;

TenantProfile buildTenantProfile() => const TenantProfile(
      annualRevenue: _annualRevenue,
      businessUnitOwners: _businessUnitOwners,
      previousQuarterAle: _previousQuarterAle,
    );
