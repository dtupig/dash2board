import '../features/auth/domain/user_role.dart';

/// Rotas nomeadas do aplicativo. Isolado de `router.dart` para manter aquele
/// arquivo abaixo do limite de 250 linhas.
abstract final class AppRoute {
  static const String splash = '/';
  static const String welcome = '/boas-vindas';
  static const String signIn = '/entrar';
  static const String pendingAccess = '/aguardando-acesso';
  static const String operational = '/operacao';
  static const String strategic = '/estrategia';
  static const String board = '/board';

  /// Bifurcação do módulo de serviços - relatórios ou demanda de RFS.
  /// Acessível pelas três personas, fora da árvore de nenhum dashboard.
  static const String services = '/servicos';
  static const String servicesCatalog = '/servicos/catalogo';
  static const String servicesInbox = '/servicos/solicitacoes';

  /// Lista de relatórios recebidos - agrupada por serviço contratado.
  static const String reportsList = '/relatorios';

  /// Compliance por framework, com evidência - filha de [strategic].
  /// Aceita `?framework=` e `?domain=` para o drill-down do painel.
  static const String strategicCompliance = '/estrategia/compliance';

  /// Feed de insights, tendências e pesquisas - filha de [strategic].
  static const String strategicInsights = '/estrategia/insights';

  /// Briefing executivo de uma página, pronto para compartilhar - filha de
  /// [strategic].
  static const String strategicBriefing = '/estrategia/briefing';

  /// Galeria de gráficos - só existe quando `AppConfig.mockMode` é
  /// verdadeiro. Nunca referenciada fora de contexto de demonstração.
  static const String devChartGallery = '/dev/graficos';

  /// Rotas acessíveis sem sessão autenticada.
  static const Set<String> publicRoutes = <String>{
    splash,
    welcome,
    signIn,
  };

  /// Rotas de "entrada" das quais um usuário já liberado deve sair.
  static const Set<String> entryRoutes = <String>{
    splash,
    welcome,
    signIn,
    pendingAccess,
  };

  static String forRole(UserRole role) => role.landingRoute;
}
