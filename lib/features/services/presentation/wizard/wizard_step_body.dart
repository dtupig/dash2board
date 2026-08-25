import 'package:flutter/material.dart';

import '../../domain/service_offering.dart';
import 'steps/justification_step.dart';
import 'steps/review_step.dart';
import 'steps/scope_step.dart';
import 'steps/urgency_step.dart';
import 'steps/use_case_step.dart';
import 'wizard_draft.dart';

/// Escolhe qual dos 5 passos renderizar - isolado de
/// `request_wizard_screen.dart` para manter aquele arquivo abaixo do limite
/// de 250 linhas.
class WizardStepBody extends StatelessWidget {
  const WizardStepBody({
    super.key,
    required this.step,
    required this.offering,
    required this.draft,
    required this.onChanged,
    required this.showErrors,
    required this.useCaseController,
    required this.assetsController,
    required this.volumeController,
    required this.justificationController,
    required this.onPickWindow,
    required this.onEditStep,
    required this.submitLabel,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final int step;
  final ServiceOffering offering;
  final WizardDraft draft;
  final ValueChanged<WizardDraft> onChanged;
  final bool showErrors;
  final TextEditingController useCaseController;
  final TextEditingController assetsController;
  final TextEditingController volumeController;
  final TextEditingController justificationController;
  final Future<void> Function() onPickWindow;
  final ValueChanged<int> onEditStep;
  final String submitLabel;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 0:
        return UseCaseStep(
          draft: draft,
          onChanged: onChanged,
          showErrors: showErrors,
          descriptionController: useCaseController,
        );
      case 1:
        return ScopeStep(
          offering: offering,
          showErrors: showErrors,
          assetsController: assetsController,
          volumeController: volumeController,
          hasContent: offering.requiresScopeAssets
              ? assetsController.text.trim().isNotEmpty
              : volumeController.text.trim().isNotEmpty,
        );
      case 2:
        return UrgencyStep(
          draft: draft,
          onChanged: onChanged,
          showErrors: showErrors,
          onPickWindow: onPickWindow,
        );
      case 3:
        return JustificationStep(
          controller: justificationController,
          showErrors: showErrors,
        );
      default:
        return ReviewStep(
          offering: offering,
          draft: draft,
          onEditStep: onEditStep,
          submitLabel: submitLabel,
          onSubmit: onSubmit,
          isSubmitting: isSubmitting,
        );
    }
  }
}
