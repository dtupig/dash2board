import 'package:elytron_dash2board/features/services/domain/request_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Map<RequestStatus, Set<RequestStatus>> expectedValidTransitions =
      <RequestStatus, Set<RequestStatus>>{
    RequestStatus.draft: <RequestStatus>{
      RequestStatus.pendingApproval,
      RequestStatus.cancelled,
    },
    RequestStatus.pendingApproval: <RequestStatus>{
      RequestStatus.approved,
      RequestStatus.rejected,
      RequestStatus.cancelled,
    },
    RequestStatus.approved: <RequestStatus>{RequestStatus.sentToElytron},
    RequestStatus.rejected: <RequestStatus>{},
    RequestStatus.sentToElytron: <RequestStatus>{
      RequestStatus.proposalReceived,
    },
    RequestStatus.proposalReceived: <RequestStatus>{RequestStatus.contracted},
    RequestStatus.contracted: <RequestStatus>{RequestStatus.delivered},
    RequestStatus.delivered: <RequestStatus>{},
    RequestStatus.cancelled: <RequestStatus>{},
  };

  test('toda transição declarada como válida passa sem lançar', () {
    for (final RequestStatus from in RequestStatus.values) {
      for (final RequestStatus to in expectedValidTransitions[from]!) {
        expect(() => from.canTransitionTo(to), returnsNormally);
      }
    }
  });

  test('toda transição NÃO declarada lança StateError', () {
    for (final RequestStatus from in RequestStatus.values) {
      final Set<RequestStatus> valid = expectedValidTransitions[from]!;
      for (final RequestStatus to in RequestStatus.values) {
        if (valid.contains(to)) {
          continue;
        }
        expect(
          () => from.canTransitionTo(to),
          throwsStateError,
          reason: '$from -> $to deveria lançar',
        );
      }
    }
  });

  test('estados terminais não têm nenhuma transição de saída', () {
    for (final RequestStatus terminal in <RequestStatus>[
      RequestStatus.rejected,
      RequestStatus.delivered,
      RequestStatus.cancelled,
    ]) {
      expect(terminal.isTerminal, isTrue);
      expect(terminal.validNextStates, isEmpty);
    }
  });

  test('fromWire desconhecido, nulo ou de tipo errado cai em draft', () {
    expect(RequestStatus.fromWire('estado-novo'), RequestStatus.draft);
    expect(RequestStatus.fromWire(null), RequestStatus.draft);
    expect(RequestStatus.fromWire(7), RequestStatus.draft);
  });
}
