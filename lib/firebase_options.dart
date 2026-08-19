// ---------------------------------------------------------------------------
// PLACEHOLDER - substitua rodando o FlutterFire CLI:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure \
//     --project=<SEU_PROJETO_FIREBASE> \
//     --platforms=ios,android \
//     --ios-bundle-id=com.elytronsecurity.dash2board \
//     --android-package-name=com.elytronsecurity.dash2board
//
// O comando sobrescreve este arquivo com as opções reais do seu projeto.
// Enquanto isso, o app compila e o `flutter analyze` passa, mas qualquer
// tentativa de inicializar o Firebase falha com uma mensagem explícita.
// ---------------------------------------------------------------------------

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Opções de inicialização do Firebase por plataforma.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Elytron Dash2Board é um produto mobile (iOS/Android). '
        'A plataforma web não é suportada.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'firebase_options.dart ainda é um placeholder. '
          'Rode `flutterfire configure` para gerar as opções reais do '
          'projeto Firebase antes de executar o aplicativo.',
        );
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Plataforma não suportada: $defaultTargetPlatform',
        );
    }
  }
}
