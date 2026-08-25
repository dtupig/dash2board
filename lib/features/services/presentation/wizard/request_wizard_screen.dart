import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/service_catalog.dart';
import '../../domain/service_offering.dart';
import 'wizard_draft.dart';
import 'wizard_exit_dialog.dart';
import 'wizard_footer.dart';
import 'wizard_persistence.dart';
import 'wizard_step_body.dart';
import 'wizard_submit.dart';

/// Wizard de demanda em 5 passos - `/servicos/demanda/:serviceKey`.
class RequestWizardScreen extends ConsumerStatefulWidget {
  const RequestWizardScreen({super.key, required this.serviceKey});

  final String serviceKey;

  @override
  ConsumerState<RequestWizardScreen> createState() =>
      _RequestWizardScreenState();
}

class _RequestWizardScreenState extends ConsumerState<RequestWizardScreen> {
  static const int _stepCount = 5;

  int _step = 0;
  bool _showErrors = false;
  bool _submitting = false;
  WizardDraft _draft = const WizardDraft();

  final TextEditingController _useCaseController = TextEditingController();
  final TextEditingController _assetsController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _justificationController =
      TextEditingController();

  late final String _prefsKey = wizardDraftPrefsKey(widget.serviceKey);

  @override
  void initState() {
    super.initState();
    _useCaseController.addListener(
      () => _updateDraft(
        _draft.copyWith(useCaseDescription: _useCaseController.text),
      ),
    );
    _assetsController.addListener(
      () => _updateDraft(
        _draft.copyWith(scopeAssetsText: _assetsController.text),
      ),
    );
    _volumeController.addListener(
      () => _updateDraft(
        _draft.copyWith(volumeDescription: _volumeController.text),
      ),
    );
    _justificationController.addListener(
      () => _updateDraft(
        _draft.copyWith(justification: _justificationController.text),
      ),
    );
    unawaited(_loadDraft());
  }

  @override
  void dispose() {
    _useCaseController.dispose();
    _assetsController.dispose();
    _volumeController.dispose();
    _justificationController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final WizardDraft? saved = await loadWizardDraft(_prefsKey);
    if (saved == null || !mounted) {
      return;
    }
    setState(() {
      _draft = saved;
      _useCaseController.text = saved.useCaseDescription;
      _assetsController.text = saved.scopeAssetsText;
      _volumeController.text = saved.volumeDescription;
      _justificationController.text = saved.justification;
    });
  }

  void _updateDraft(WizardDraft next) {
    setState(() => _draft = next);
    unawaited(persistWizardDraft(_prefsKey, next));
  }

  void _goNext(ServiceOffering offering) {
    if (!_draft.isValidForStep(
      _step,
      requiresScopeAssets: offering.requiresScopeAssets,
    )) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _showErrors = false;
      _step = (_step + 1).clamp(0, _stepCount - 1);
    });
  }

  Future<void> _goBackOrExit() async {
    if (_step > 0) {
      setState(() => _step -= 1);
      return;
    }
    if (await _tryExit() && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _tryExit() => confirmWizardExit(
        context,
        onSave: () => persistWizardDraft(_prefsKey, _draft),
        onDiscard: () => discardWizardDraft(_prefsKey),
      );

  Future<void> _pickWindow() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _draft.desiredWindow ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      _updateDraft(_draft.copyWith(desiredWindow: picked));
    }
  }

  Future<void> _submit(ServiceOffering offering) async {
    setState(() => _submitting = true);
    final WizardSubmitResult result = await submitWizardRequest(
      ref: ref,
      offering: offering,
      draft: _draft,
      prefsKey: _prefsKey,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (result == WizardSubmitResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação enviada.')),
      );
      context.go('/servicos/solicitacoes');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível enviar a solicitação agora.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ServiceOffering? offering = ServiceCatalog.byKey(widget.serviceKey);
    if (offering == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Serviço não encontrado')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Este serviço não existe no catálogo. Volte e escolha outro.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final bool isStrategic =
        ref.watch(appUserProvider).value?.role.wireValue == 'strategic';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        if (await _tryExit() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(offering.label)),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              LinearProgressIndicator(value: (_step + 1) / _stepCount),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: WizardStepBody(
                    step: _step,
                    offering: offering,
                    draft: _draft,
                    onChanged: _updateDraft,
                    showErrors: _showErrors,
                    useCaseController: _useCaseController,
                    assetsController: _assetsController,
                    volumeController: _volumeController,
                    justificationController: _justificationController,
                    onPickWindow: _pickWindow,
                    onEditStep: (int step) => setState(() {
                      _showErrors = false;
                      _step = step;
                    }),
                    submitLabel: isStrategic
                        ? 'Enviar para a Elytron'
                        : 'Enviar para aprovação do CISO',
                    onSubmit: () => unawaited(_submit(offering)),
                    isSubmitting: _submitting,
                  ),
                ),
              ),
              if (_step < 4)
                WizardFooter(
                  onBack: () => unawaited(_goBackOrExit()),
                  onNext: () => _goNext(offering),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
