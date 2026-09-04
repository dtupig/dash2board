import 'package:elytron_dash2board/features/auth/domain/user_role.dart';
import 'package:elytron_dash2board/features/reports/domain/report_access_policy.dart';
import 'package:elytron_dash2board/features/reports/domain/report_classification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canOpen', () {
    test('strategic abre qualquer classificação', () {
      for (final ReportClassification c in ReportClassification.values) {
        expect(
          ReportAccessPolicy.canOpen(UserRole.strategic, c,
              isMaterialFact: false),
          isTrue,
          reason: c.wireValue,
        );
      }
    });

    test('operational abre tudo menos secret', () {
      expect(
        ReportAccessPolicy.canOpen(
            UserRole.operational, ReportClassification.confidential,
            isMaterialFact: false),
        isTrue,
      );
      expect(
        ReportAccessPolicy.canOpen(
            UserRole.operational, ReportClassification.secret,
            isMaterialFact: false),
        isFalse,
      );
    });

    test('board só abre com fato relevante ou publicInternal', () {
      expect(
        ReportAccessPolicy.canOpen(
            UserRole.board, ReportClassification.confidential,
            isMaterialFact: true),
        isTrue,
      );
      expect(
        ReportAccessPolicy.canOpen(
            UserRole.board, ReportClassification.publicInternal,
            isMaterialFact: false),
        isTrue,
      );
      expect(
        ReportAccessPolicy.canOpen(
            UserRole.board, ReportClassification.confidential,
            isMaterialFact: false),
        isFalse,
      );
      expect(
        ReportAccessPolicy.canOpen(UserRole.board, ReportClassification.secret,
            isMaterialFact: false),
        isFalse,
      );
    });

    test('pending nunca abre', () {
      for (final ReportClassification c in ReportClassification.values) {
        expect(
          ReportAccessPolicy.canOpen(UserRole.pending, c, isMaterialFact: true),
          isFalse,
          reason: c.wireValue,
        );
      }
    });
  });

  group('canSeeSection - board', () {
    test('board vê narrative', () {
      expect(
        ReportAccessPolicy.canSeeSection(UserRole.board,
            ReportClassification.confidential, SectionSensitivity.narrative),
        isTrue,
      );
    });

    test(
        'board NUNCA vê exploitProof, personalData nem chainOfCustody, em '
        'nenhuma classificação', () {
      for (final ReportClassification c in ReportClassification.values) {
        expect(
          ReportAccessPolicy.canSeeSection(
              UserRole.board, c, SectionSensitivity.exploitProof),
          isFalse,
          reason: c.wireValue,
        );
        expect(
          ReportAccessPolicy.canSeeSection(
              UserRole.board, c, SectionSensitivity.personalData),
          isFalse,
          reason: c.wireValue,
        );
        expect(
          ReportAccessPolicy.canSeeSection(
              UserRole.board, c, SectionSensitivity.chainOfCustody),
          isFalse,
          reason: c.wireValue,
        );
      }
    });

    test('board NÃO vê nem technical - visão dele é só narrativa', () {
      expect(
        ReportAccessPolicy.canSeeSection(UserRole.board,
            ReportClassification.confidential, SectionSensitivity.technical),
        isFalse,
      );
    });
  });

  group('canSeeSection - operational', () {
    test('operational vê technical em qualquer classificação não secret', () {
      expect(
        ReportAccessPolicy.canSeeSection(UserRole.operational,
            ReportClassification.restricted, SectionSensitivity.technical),
        isTrue,
      );
    });

    test(
        'operational vê exploitProof em restricted/confidential, nunca em '
        'secret', () {
      expect(
        ReportAccessPolicy.canSeeSection(UserRole.operational,
            ReportClassification.restricted, SectionSensitivity.exploitProof),
        isTrue,
      );
      expect(
        ReportAccessPolicy.canSeeSection(UserRole.operational,
            ReportClassification.confidential, SectionSensitivity.exploitProof),
        isTrue,
      );
      expect(
        ReportAccessPolicy.canSeeSection(UserRole.operational,
            ReportClassification.secret, SectionSensitivity.exploitProof),
        isFalse,
      );
    });

    test('operational NÃO vê personalData nem chainOfCustody', () {
      for (final ReportClassification c in ReportClassification.values) {
        expect(
          ReportAccessPolicy.canSeeSection(
              UserRole.operational, c, SectionSensitivity.personalData),
          isFalse,
          reason: c.wireValue,
        );
        expect(
          ReportAccessPolicy.canSeeSection(
              UserRole.operational, c, SectionSensitivity.chainOfCustody),
          isFalse,
          reason: c.wireValue,
        );
      }
    });
  });

  group('canSeeSection - strategic', () {
    test('strategic vê tudo, em toda classificação', () {
      for (final ReportClassification c in ReportClassification.values) {
        for (final SectionSensitivity s in SectionSensitivity.values) {
          expect(
            ReportAccessPolicy.canSeeSection(UserRole.strategic, c, s),
            isTrue,
            reason: '${c.wireValue} / ${s.wireValue}',
          );
        }
      }
    });
  });

  group('canDownload', () {
    test('strategic sempre baixa', () {
      for (final ReportClassification c in ReportClassification.values) {
        expect(ReportAccessPolicy.canDownload(UserRole.strategic, c), isTrue);
      }
    });

    test('operational baixa tudo menos secret', () {
      expect(
        ReportAccessPolicy.canDownload(
            UserRole.operational, ReportClassification.confidential),
        isTrue,
      );
      expect(
        ReportAccessPolicy.canDownload(
            UserRole.operational, ReportClassification.secret),
        isFalse,
      );
    });

    test('board nunca baixa', () {
      for (final ReportClassification c in ReportClassification.values) {
        expect(
          ReportAccessPolicy.canDownload(UserRole.board, c),
          isFalse,
          reason: c.wireValue,
        );
      }
    });
  });

  group('requiresReadReceipt', () {
    test('só secret exige registro de leitura', () {
      expect(
        ReportAccessPolicy.requiresReadReceipt(ReportClassification.secret),
        isTrue,
      );
      expect(
        ReportAccessPolicy.requiresReadReceipt(
            ReportClassification.confidential),
        isFalse,
      );
    });
  });

  group('redactionNotice', () {
    test('toda persona tem uma explicação não vazia', () {
      for (final UserRole role in UserRole.values) {
        expect(ReportAccessPolicy.redactionNotice(role), isNotEmpty);
      }
    });
  });
}
