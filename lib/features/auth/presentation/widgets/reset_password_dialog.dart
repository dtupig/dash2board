import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Diálogo de "esqueci minha senha" da `SignInScreen`. Retorna o e-mail
/// confirmado (ou `null` se cancelado). Isolado para manter aquele arquivo
/// abaixo do limite de 250 linhas.
class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({super.key, required this.initialEmail});

  final String initialEmail;

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialEmail);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      title: const Text('Redefinir senha'),
      content: Form(
        key: _formKey,
        child: AppTextField(
          controller: _controller,
          label: 'E-mail corporativo',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: Validators.email,
          onFieldSubmitted: (_) => _confirm(),
          autofocus: true,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
