/// Configuração estática do aplicativo.
///
/// Valores sensíveis (chaves, ids de projeto) NÃO ficam aqui: eles vêm de
/// `firebase_options.dart` (gerado pelo FlutterFire CLI e ignorado no git) ou
/// de `--dart-define` no build.
abstract final class AppConfig {
  static const String appName = 'Elytron Dash2Board';
  static const String companyName = 'Elytron Security';
  static const String supportEmail = 'suporte@elytronsecurity.com';
  static const String privacyUrl = 'https://elytronsecurity.com/privacidade';
  static const String termsUrl = 'https://elytronsecurity.com/termos';

  /// Ambiente atual: `dev`, `staging` ou `prod`.
  /// Uso: `flutter run --dart-define=ENV=staging`
  static const String environment =
      String.fromEnvironment('ENV', defaultValue: 'dev');

  static bool get isProduction => environment == 'prod';

  /// Habilita o botão de SSO corporativo na tela de login.
  /// Uso: `flutter run --dart-define=ENABLE_SSO=true`
  static const bool ssoEnabled = bool.fromEnvironment('ENABLE_SSO');

  /// Tempo máximo de espera por uma operação de rede antes de falhar.
  static const Duration networkTimeout = Duration(seconds: 20);

  // -------------------------------------------------------------------------
  // Modo de demonstração
  // -------------------------------------------------------------------------

  /// Quando verdadeiro, o app roda 100% offline, sem inicializar o Firebase.
  /// Uso: `flutter run --dart-define=MOCK=true`
  ///
  /// Serve para desenvolver e demonstrar a interface sem depender de projeto
  /// Firebase, faturamento, seed ou rede.
  static const bool mockMode = bool.fromEnvironment('MOCK');

  /// Origem dos dados: `auto`, `mock` ou `firestore`.
  /// `auto` segue [mockMode]. Uso:
  /// `flutter run --dart-define=DATA_SOURCE=firestore`
  static const String dataSource =
      String.fromEnvironment('DATA_SOURCE', defaultValue: 'auto');

  /// Regra única que decide a implementação de repositório a usar.
  static bool get useMockData =>
      dataSource == 'mock' || (dataSource == 'auto' && mockMode);

  /// Contas de demonstração, uma por persona. A senha é qualquer string com
  /// [minDemoPasswordLength] caracteres ou mais.
  static const Map<String, String> demoAccounts = <String, String>{
    'operacao@demo.elytron': 'operational',
    'ciso@demo.elytron': 'strategic',
    'board@demo.elytron': 'board',
  };

  static const String demoTenantId = 'tenant-demo';
  static const int minDemoPasswordLength = 12;
}
