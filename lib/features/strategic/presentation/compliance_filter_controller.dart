import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/compliance_control.dart';
import '../domain/security_domain.dart';

/// Filtro ativo da tela de compliance.
///
/// As três dimensões são independentes: framework (ISO 27001 etc.), status
/// (`compliant`/`partial`/`gap`) e domínio de segurança.
class ComplianceFilterState {
  const ComplianceFilterState({this.framework, this.status, this.domain});

  final ComplianceFramework? framework;
  final ControlStatus? status;
  final SecurityDomain? domain;

  bool get isEmpty => framework == null && status == null && domain == null;

  @override
  bool operator ==(Object other) {
    return other is ComplianceFilterState &&
        other.framework == framework &&
        other.status == status &&
        other.domain == domain;
  }

  @override
  int get hashCode => Object.hash(framework, status, domain);
}

/// Controla o filtro da tela de compliance.
///
/// Cada dimensão tem seu próprio método de troca (em vez de um `copyWith`
/// genérico) para que "limpar o framework" seja inequívoco: um `copyWith`
/// com parâmetros nulos por padrão não consegue distinguir "não mexer" de
/// "voltar a nulo".
class ComplianceFilterNotifier extends Notifier<ComplianceFilterState> {
  @override
  ComplianceFilterState build() => const ComplianceFilterState();

  void setFramework(ComplianceFramework? value) {
    state = ComplianceFilterState(
      framework: value,
      status: state.status,
      domain: state.domain,
    );
  }

  void setStatus(ControlStatus? value) {
    state = ComplianceFilterState(
      framework: state.framework,
      status: value,
      domain: state.domain,
    );
  }

  void setDomain(SecurityDomain? value) {
    state = ComplianceFilterState(
      framework: state.framework,
      status: state.status,
      domain: value,
    );
  }

  void clearAll() {
    state = const ComplianceFilterState();
  }

  /// Aplica os parâmetros de consulta da URL (drill-down do painel).
  ///
  /// Só sobrescreve as dimensões presentes na URL: se o usuário já tiver
  /// ajustado o status dentro da tela e a URL for atualizada de volta (para
  /// refletir o filtro), o status escolhido não é perdido.
  void applyFromRoute({String? frameworkWire, String? domainWire}) {
    state = ComplianceFilterState(
      framework: frameworkWire != null
          ? ComplianceFramework.fromWire(frameworkWire)
          : state.framework,
      status: state.status,
      domain: domainWire != null
          ? SecurityDomain.fromWire(domainWire)
          : state.domain,
    );
  }
}

final NotifierProvider<ComplianceFilterNotifier, ComplianceFilterState>
    complianceFilterProvider =
    NotifierProvider<ComplianceFilterNotifier, ComplianceFilterState>(
  ComplianceFilterNotifier.new,
);
