import 'package:shared_preferences/shared_preferences.dart';

import 'wizard_draft.dart';

/// Persistência do rascunho do wizard em `shared_preferences`, por
/// `serviceKey` - isolado de `request_wizard_screen.dart` para manter aquele
/// arquivo abaixo do limite de 250 linhas.
String wizardDraftPrefsKey(String serviceKey) => 'wizard_draft_$serviceKey';

Future<WizardDraft?> loadWizardDraft(String prefsKey) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? saved = prefs.getString(prefsKey);
  return saved == null ? null : WizardDraft.fromJson(saved);
}

Future<void> persistWizardDraft(String prefsKey, WizardDraft draft) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(prefsKey, draft.toJson());
}

Future<void> discardWizardDraft(String prefsKey) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(prefsKey);
}
