import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/services_providers.dart';
import '../../domain/request_urgency.dart';
import '../../domain/service_offering.dart';
import 'wizard_draft.dart';
import 'wizard_persistence.dart';

/// Resultado do envio final do wizard - a tela só precisa decidir o que
/// mostrar, não como montar a solicitação.
enum WizardSubmitResult { success, noSession, failure }

/// Monta e envia a [ServiceRequest] a partir do [draft] preenchido, e limpa
/// o rascunho persistido em caso de sucesso. Isolado de
/// `request_wizard_screen.dart` para manter aquele arquivo abaixo do limite
/// de 250 linhas.
Future<WizardSubmitResult> submitWizardRequest({
  required WidgetRef ref,
  required ServiceOffering offering,
  required WizardDraft draft,
  required String prefsKey,
}) async {
  final String? tenantId = ref.read(appUserProvider).value?.tenantId;
  final String? uid = ref.read(appUserProvider).value?.uid;
  final String name = ref.read(appUserProvider).value?.firstName ?? '';
  final String? roleWire = ref.read(appUserProvider).value?.role.wireValue;
  if (tenantId == null || uid == null || roleWire == null) {
    return WizardSubmitResult.noSession;
  }
  try {
    await ref.read(servicesRepositoryProvider).createRequest(
          tenantId: tenantId,
          serviceKey: offering.serviceKey,
          requestedByUid: uid,
          requestedByName: name,
          openerRoleWire: roleWire,
          urgency: draft.urgency ?? RequestUrgency.planned,
          driver: draft.driver!,
          scopeSummary: draft.useCaseDescription.trim(),
          scopeAssets: draft.scopeAssets,
          businessJustification: draft.justification.trim(),
          desiredWindow: draft.desiredWindow ?? DateTime.now(),
        );
    await discardWizardDraft(prefsKey);
    return WizardSubmitResult.success;
  } catch (_) {
    return WizardSubmitResult.failure;
  }
}
