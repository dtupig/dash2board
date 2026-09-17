import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Hook automático do `flutter_test` (roda antes de toda a suíte, sem
/// import explícito em nenhum arquivo).
///
/// Sem isso, `GoogleFonts.archivo()`/`ibmPlexSans()`/`ibmPlexMono()`
/// tentam baixar a fonte pela rede a cada teste que monta uma tela -
/// dependência de rede que o projeto evita de propósito em toda a suíte
/// (Firestore/Auth já rodam contra emulador, nunca contra serviço real).
/// Com `allowRuntimeFetching = false`, cai na fonte padrão do sistema em
/// teste - o texto renderiza, só a família visual muda, o que não afeta
/// nenhuma asserção de conteúdo/estrutura da suíte.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
