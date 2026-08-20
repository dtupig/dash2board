import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // O Dash2Board é um app de leitura executiva: retrato apenas mantém a
  // densidade dos painéis previsível em iOS e Android.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Em modo de demonstração o Firebase NÃO é inicializado: o app roda offline,
  // com dados em memória. É o que permite abrir a interface antes de existir
  // um projeto Firebase configurado.
  //   flutter run --dart-define=MOCK=true
  Object? bootstrapError;

  if (!AppConfig.useMockData) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // `firebase emulators:start` (Fase C do plano de retomada) — precisa vir
      // antes de qualquer leitura/escrita no Firestore ou Auth.
      if (AppConfig.useEmulator) {
        FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      }

      // Cache offline: o executivo abre o app no avião/elevador e ainda vê o
      // último estado conhecido. O tamanho é limitado para não crescer sem fim.
      // Contra o emulador, cache local só esconde dado obsoleto entre reinícios.
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: !AppConfig.useEmulator,
        cacheSizeBytes: 40 * 1024 * 1024,
      );
    } on Object catch (error) {
      // NUNCA deixe `main` morrer antes de `runApp`: isso produz uma tela em
      // branco sem nenhuma pista para quem está desenvolvendo. O app sobe e
      // explica o que aconteceu.
      bootstrapError = error;
    }
  }

  runApp(
    ProviderScope(
      child: ElytronApp(bootstrapError: bootstrapError),
    ),
  );
}
