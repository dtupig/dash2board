import '../../auth/domain/user_role.dart';
import 'report_classification.dart';

/// Regra de autorização de leitura de relatório - classe pura, testável,
/// sem Flutter e sem Firebase. **Nenhuma tela reimplementa isto.** Se um
/// widget precisa saber se mostra um botão ou um conteúdo, ele pergunta
/// aqui.
///
/// Regras, e elas são duras (docs/prompts/11_RELATORIOS_ESPECIALISTAS.md):
/// - `board` nunca vê seção `exploitProof`, `personalData` nem
///   `chainOfCustody`, em nenhuma classificação, sob nenhuma condição.
/// - `board` só abre relatório quando `isMaterialFact == true` OU a
///   classificação é `publicInternal`.
/// - `operational` vê `technical` e `exploitProof`, mas apenas em
///   relatórios `restricted`/`confidential` - nunca em `secret`, e nunca
///   `personalData`/`chainOfCustody` (reservados a `strategic`).
/// - `strategic` vê tudo, e leitura de `secret` exige `readReceipt`
///   gravado em `audit_logs` antes de renderizar o conteúdo.
abstract final class ReportAccessPolicy {
  /// Pode abrir o relatório (a tela inteira), antes de olhar seção alguma.
  static bool canOpen(
    UserRole role,
    ReportClassification classification, {
    required bool isMaterialFact,
  }) {
    switch (role) {
      case UserRole.strategic:
        return true;
      case UserRole.operational:
        return classification != ReportClassification.secret;
      case UserRole.board:
        return isMaterialFact ||
            classification == ReportClassification.publicInternal;
      case UserRole.pending:
        return false;
    }
  }

  /// Pode ver o conteúdo de uma seção específica, já dentro de um relatório
  /// que [canOpen] liberou.
  static bool canSeeSection(
    UserRole role,
    ReportClassification classification,
    SectionSensitivity sensitivity,
  ) {
    switch (role) {
      case UserRole.board:
        return sensitivity == SectionSensitivity.narrative;
      case UserRole.operational:
        switch (sensitivity) {
          case SectionSensitivity.narrative:
          case SectionSensitivity.technical:
            return true;
          case SectionSensitivity.exploitProof:
            return classification == ReportClassification.restricted ||
                classification == ReportClassification.confidential;
          case SectionSensitivity.personalData:
          case SectionSensitivity.chainOfCustody:
            return false;
        }
      case UserRole.strategic:
        return true;
      case UserRole.pending:
        return false;
    }
  }

  /// Pode exportar/baixar o relatório. `board` nunca baixa relatório
  /// técnico - o que ele precisa já está na visão executiva do app.
  static bool canDownload(UserRole role, ReportClassification classification) {
    switch (role) {
      case UserRole.strategic:
        return true;
      case UserRole.operational:
        return classification != ReportClassification.secret;
      case UserRole.board:
      case UserRole.pending:
        return false;
    }
  }

  /// `secret` exige registro de leitura antes de renderizar o conteúdo -
  /// nunca depois.
  static bool requiresReadReceipt(ReportClassification classification) {
    return classification == ReportClassification.secret;
  }

  /// Frase explicando por que uma seção está suprimida - nunca some em
  /// silêncio (a diferença entre redação e engano).
  static String redactionNotice(UserRole role) {
    return switch (role) {
      UserRole.board =>
        'Conteúdo técnico não é mostrado ao board. Fale com o time de '
            'segurança para detalhes.',
      UserRole.operational =>
        'Esta seção é restrita a uma persona ou classificação diferente da '
            'sua.',
      UserRole.strategic =>
        'Esta seção exige um registro de leitura antes de ser exibida.',
      UserRole.pending => 'Seu acesso ainda não permite ver este conteúdo.',
    };
  }
}
