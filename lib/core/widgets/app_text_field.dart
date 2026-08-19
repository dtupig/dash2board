import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

/// Campo de formulário padrão do Dash2Board.
///
/// A decoração é aplicada localmente (e não via `inputDecorationTheme`) para
/// manter o tema livre de classes que estão em processo de deprecation no
/// Flutter e para permitir estados de erro/foco com a cor de acento correta.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    OutlineInputBorder border(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: AppRadius.fieldRadius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          enabled: enabled,
          autofocus: autofocus,
          inputFormatters: inputFormatters,
          autocorrect: false,
          enableSuggestions: !obscureText,
          style: theme.textTheme.bodyLarge,
          cursorColor: scheme.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
            ),
            filled: true,
            fillColor: scheme.surfaceContainer.withValues(alpha: 0.85),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 20, color: scheme.onSurfaceVariant),
            suffixIcon: suffixIcon,
            border: border(scheme.outline, 1),
            enabledBorder: border(scheme.outline.withValues(alpha: 0.7), 1),
            focusedBorder: border(scheme.primary, 1.6),
            errorBorder: border(scheme.error, 1),
            focusedErrorBorder: border(scheme.error, 1.6),
            disabledBorder: border(
              scheme.outline.withValues(alpha: 0.35),
              1,
            ),
            errorStyle: theme.textTheme.bodySmall?.copyWith(
              color: scheme.error,
            ),
          ),
        ),
      ],
    );
  }
}
