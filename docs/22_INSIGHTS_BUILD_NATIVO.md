# Insights — da build de simulação à distribuição real

Documento de apoio à decisão do PO sobre o item 3 do
`docs/21_BACKLOG_ACHADOS_TECNICOS.md` (S2 — job de build na CI). Registra o
que a CI passou a validar em 04/09/2026, o que ela **não** valida, e o
caminho prático até um build de verdade instalável por um tester.

## O que a CI valida agora

Dois jobs novos em `.github/workflows/ci.yaml`:

- **`build-android`** (`ubuntu-latest`): `flutter build apk --debug`. Usa a
  assinatura de debug já configurada em `android/app/build.gradle.kts`
  ("Signing with the debug keys for now, so `flutter run --release` works")
  — não exige keystore nem secret de CI.
- **`build-ios`** (`macos-latest`, obrigatório para build iOS): `flutter
  build ios --simulator --no-codesign`. Compila o projeto Xcode sem exigir
  certificado de distribuição nem provisioning profile.

Isso prova que o **código compila nativamente** nas duas plataformas a cada
PR — o que faltava (ver `docs/20_RETOMADA_SESSAO.md`, seção Ambiente: "a CI
tem 3 jobs e nenhum roda `flutter build`"). Já pegou um bug real ao ser
implementado: `ios/Podfile.lock` estava travado em `Firebase/CoreOnly
12.17.0`, incompatível com a versão que `firebase_core` exige hoje
(12.18.0) — o build iOS estava quebrado em `main` sem que nenhum dos 3 jobs
antigos detectasse.

## O que a CI **não** valida

Nenhum dos dois artefatos (`.apk` de debug, `.app` de simulador) é
instalável por um tester real fora da própria máquina de build:

- O `.apk` de debug roda em qualquer emulador/aparelho Android com "fontes
  desconhecidas" habilitado, mas não pode ser distribuído pela Play Store
  nem pela maioria das ferramentas de distribuição interna (Firebase App
  Distribution aceita debug, mas é o limite).
- O `.app` de simulador iOS **só roda no simulador**, nunca num iPhone
  físico — arquitetura e assinatura são diferentes de um build de
  dispositivo real.

## Caminho até um build real (signed) — Android

1. **Gerar uma upload keystore** (`keytool -genkey -v -keystore
   upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias
   upload`) — chave própria da Elytron, não a de debug do repositório.
2. **`android/key.properties`** (gitignored) apontando para essa keystore,
   e `signingConfigs.release` em `build.gradle.kts` lendo esse arquivo em
   vez de reusar `signingConfigs.getByName("debug")` como hoje.
3. **Play App Signing** (recomendado pelo próprio Google): a keystore acima
   vira só a "chave de upload" — o Google guarda e usa a chave final de
   assinatura, reduzindo o risco de uma keystore perdida inviabilizar
   atualizações futuras do app.
4. **Google Play Console**: criar o app, preencher a declaração de
   segurança de dados (obrigatória, e o app lida com dado de cliente sobre
   incidentes de segurança — vale revisão jurídica antes de submeter),
   escolher a trilha (`internal testing` é o ponto de partida natural para
   a Elytron testar com o próprio time antes de qualquer cliente).
5. **CI**: só faz sentido automatizar a assinatura quando existir uma
   cadência real de distribuição (ver "Quando investir" abaixo) — a
   keystore vira secret do GitHub Actions (base64) e o job troca `flutter
   build apk --debug` por `flutter build appbundle --release` com as
   variáveis de assinatura.

## Caminho até um build real (signed) — iOS

1. **Apple Developer Program** (US$ 99/ano) — pré-requisito para qualquer
   distribuição além do simulador, mesmo interna.
2. **Certificado de distribuição + App ID + provisioning profile** — via
   Xcode (assinatura automática, mais simples para começar) ou via
   `fastlane match` (recomendado assim que mais de uma pessoa/máquina
   precisar assinar, porque centraliza o certificado num repositório
   privado em vez de espalhar `.p12` por máquina).
3. **App Store Connect**: criar o registro do app, subir o primeiro build
   (via Xcode Organizer ou `fastlane`), e usar o **TestFlight** para
   distribuição de beta — é o equivalente iOS do "internal testing" do
   Android, e não exige aprovação da App Store para instalar em
   dispositivos de teste.
4. **CI**: assinatura automatizada exige guardar como secret o certificado
   `.p12` (base64) + senha, o provisioning profile, e idealmente uma chave
   de API do App Store Connect (para upload automático ao TestFlight via
   `fastlane pilot` ou `xcrun altool`/`notarytool`).

## Quando investir em assinatura na CI — ponto de decisão

Assinar builds na CI (Android e iOS) só compensa quando existir uma
**cadência real de distribuição** — por exemplo, "toda sexta sobe um build
para o TestFlight/trilha interna dos stakeholders acompanharem". Sem essa
cadência, assinar manualmente a cada demo importante é mais barato do que
manter segredos de assinatura na CI (superfície de ataque a mais, e
certificados/keystores expiram e precisam de rotação).

**Pergunta para o PO:** existe uma data-alvo para o app começar a ser
instalado por alguém fora do time de engenharia (piloto com cliente,
demonstração com um dispositivo físico em vez de simulador/emulador)? Se
sim, vale planejar Apple Developer Program + Play Console com antecedência
(o cadastro do Developer Program da Apple pode levar dias para ser
aprovado). Se não há data definida, os dois jobs de build de simulação já
entregues são suficientes por ora — o próximo passo natural é revisitar
este documento quando a distribuição real virar prioridade.
