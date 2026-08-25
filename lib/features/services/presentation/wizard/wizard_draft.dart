import 'dart:convert';

import '../../domain/request_driver.dart';
import '../../domain/request_urgency.dart';

/// Estado do wizard de demanda enquanto o usuário preenche, antes de virar
/// uma [ServiceRequest] de verdade.
///
/// Puramente de apresentação (não é o domínio persistido): existe só para
/// serializar em `shared_preferences`, por `serviceKey`, e sobreviver a uma
/// saída do wizard sem perder o que foi digitado.
class WizardDraft {
  const WizardDraft({
    this.driver,
    this.useCaseDescription = '',
    this.scopeAssetsText = '',
    this.volumeDescription = '',
    this.urgency,
    this.desiredWindow,
    this.justification = '',
  });

  final RequestDriver? driver;
  final String useCaseDescription;

  /// Uma linha por alvo (domínio, aplicação, repositório, faixa de IP,
  /// conta de nuvem) - texto bruto que o usuário digitou ou colou.
  final String scopeAssetsText;

  /// Usado quando o serviço não pede alvos: nº de pessoas, fornecedores,
  /// sistemas etc.
  final String volumeDescription;

  final RequestUrgency? urgency;
  final DateTime? desiredWindow;
  final String justification;

  /// Alvos como lista, uma linha por item, sem linhas vazias.
  List<String> get scopeAssets => scopeAssetsText
      .split('\n')
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .toList(growable: false);

  /// Valida um dos 4 primeiros passos do wizard (o 5º, revisão, não tem
  /// campo próprio para validar). [requiresScopeAssets] vem de
  /// `ServiceOffering` porque o passo de escopo pede alvos ou volume
  /// conforme o serviço.
  bool isValidForStep(int step, {required bool requiresScopeAssets}) {
    switch (step) {
      case 0:
        return driver != null && useCaseDescription.trim().isNotEmpty;
      case 1:
        return requiresScopeAssets
            ? scopeAssets.isNotEmpty
            : volumeDescription.trim().isNotEmpty;
      case 2:
        return urgency != null && desiredWindow != null;
      case 3:
        return justification.trim().isNotEmpty;
      default:
        return true;
    }
  }

  bool get isEmpty =>
      driver == null &&
      useCaseDescription.isEmpty &&
      scopeAssetsText.isEmpty &&
      volumeDescription.isEmpty &&
      urgency == null &&
      desiredWindow == null &&
      justification.isEmpty;

  WizardDraft copyWith({
    RequestDriver? driver,
    String? useCaseDescription,
    String? scopeAssetsText,
    String? volumeDescription,
    RequestUrgency? urgency,
    DateTime? desiredWindow,
    String? justification,
  }) {
    return WizardDraft(
      driver: driver ?? this.driver,
      useCaseDescription: useCaseDescription ?? this.useCaseDescription,
      scopeAssetsText: scopeAssetsText ?? this.scopeAssetsText,
      volumeDescription: volumeDescription ?? this.volumeDescription,
      urgency: urgency ?? this.urgency,
      desiredWindow: desiredWindow ?? this.desiredWindow,
      justification: justification ?? this.justification,
    );
  }

  factory WizardDraft.fromJson(String source) {
    final Map<String, dynamic> map = jsonDecode(source) as Map<String, dynamic>;
    return WizardDraft(
      driver:
          map['driver'] == null ? null : RequestDriver.fromWire(map['driver']),
      useCaseDescription: map['useCaseDescription'] as String? ?? '',
      scopeAssetsText: map['scopeAssetsText'] as String? ?? '',
      volumeDescription: map['volumeDescription'] as String? ?? '',
      urgency: map['urgency'] == null
          ? null
          : RequestUrgency.fromWire(map['urgency']),
      desiredWindow: map['desiredWindow'] == null
          ? null
          : DateTime.tryParse(map['desiredWindow'] as String),
      justification: map['justification'] as String? ?? '',
    );
  }

  String toJson() => jsonEncode(<String, Object?>{
        'driver': driver?.wireValue,
        'useCaseDescription': useCaseDescription,
        'scopeAssetsText': scopeAssetsText,
        'volumeDescription': volumeDescription,
        'urgency': urgency?.wireValue,
        'desiredWindow': desiredWindow?.toIso8601String(),
        'justification': justification,
      });
}
