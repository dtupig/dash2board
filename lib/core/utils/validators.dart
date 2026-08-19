/// Validações de formulário reutilizáveis (mensagens em pt-BR).
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]"
    r'(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  /// Comprimento mínimo alinhado ao NIST SP 800-63B (12 caracteres).
  static const int minPasswordLength = 12;

  static String? email(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Informe seu e-mail corporativo.';
    }
    if (!_emailPattern.hasMatch(input)) {
      return 'E-mail inválido.';
    }
    return null;
  }

  static String? password(String? value) {
    final String input = value ?? '';
    if (input.isEmpty) {
      return 'Informe sua senha.';
    }
    if (input.length < minPasswordLength) {
      return 'A senha deve ter ao menos $minPasswordLength caracteres.';
    }
    return null;
  }

  /// Validação usada apenas no login: não revela a política de senha,
  /// somente exige que o campo esteja preenchido.
  static String? passwordPresence(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Informe sua senha.';
    }
    return null;
  }

  static String? required(String? value, {String field = 'Este campo'}) {
    if ((value ?? '').trim().isEmpty) {
      return '$field é obrigatório.';
    }
    return null;
  }
}
