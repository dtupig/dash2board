import 'package:elytron_dash2board/features/reports/domain/finding_severity.dart';
import 'package:elytron_dash2board/features/reports/domain/material_fact.dart';
import 'package:elytron_dash2board/features/reports/domain/material_fact_evaluator.dart';
import 'package:elytron_dash2board/features/reports/domain/models/pentest_finding.dart';
import 'package:elytron_dash2board/features/reports/domain/models/pentest_report.dart';
import 'package:flutter_test/flutter_test.dart';

import 'material_fact_fixtures.dart';

void main() {
  group('businessContinuityRisk', () {
    test('positivo: ameaça explícita dispara', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        incidentReport(businessContinuityThreatened: true),
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.businessContinuityRisk),
        isTrue,
      );
    });

    test('negativo: sem ameaça, não dispara', () {
      final List<MaterialFact> facts =
          MaterialFactEvaluator.evaluate(incidentReport(), now: now);
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.businessContinuityRisk),
        isFalse,
      );
    });
  });

  group('financialExposureThreshold', () {
    test('positivo: exposição acima do limite do tenant dispara', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        pentestReport(estimatedExposureValue: 1000000),
        tenantRevenueThreshold: 500000,
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.financialExposureThreshold),
        isTrue,
      );
    });

    test('negativo: sem limite do tenant configurado, não dispara', () {
      final List<MaterialFact> facts =
          MaterialFactEvaluator.evaluate(pentestReport(), now: now);
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.financialExposureThreshold),
        isFalse,
      );
    });
  });

  group('criticalSupplierRisk', () {
    test('positivo: fornecedor crítico sem tratativa dispara', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        thirdPartyReport(criticalSuppliers: const <String>['Fornecedor X']),
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.criticalSupplierRisk),
        isTrue,
      );
    });

    test('negativo: sem fornecedor crítico, não dispara', () {
      final List<MaterialFact> facts =
          MaterialFactEvaluator.evaluate(thirdPartyReport(), now: now);
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.criticalSupplierRisk),
        isFalse,
      );
    });
  });

  group('leakedCorporateCredentials', () {
    test('positivo: credencial em vazamento dispara', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        defenseReport(
            credentialsFoundInLeaks: const <String>['user@empresa.com']),
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.leakedCorporateCredentials),
        isTrue,
      );
    });

    test('negativo: sem credencial vazada, não dispara', () {
      final List<MaterialFact> facts =
          MaterialFactEvaluator.evaluate(defenseReport(), now: now);
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.leakedCorporateCredentials),
        isFalse,
      );
    });
  });

  test(
      'determinismo: mesmo relatório avaliado duas vezes dá o mesmo '
      'resultado', () {
    final PentestReport report = pentestReport(
      findings: <PentestFinding>[
        finding(severity: FindingSeverity.critical, containsPersonalData: true),
      ],
    );
    final List<MaterialFact> first =
        MaterialFactEvaluator.evaluate(report, now: now);
    final List<MaterialFact> second =
        MaterialFactEvaluator.evaluate(report, now: now);
    expect(first, equals(second));
  });

  test(
      'um único achado pode disparar múltiplos gatilhos simultâneos '
      '(caso real validado em D-27)', () {
    final PentestReport report = pentestReport(
      findings: <PentestFinding>[
        finding(
          severity: FindingSeverity.critical,
          containsPersonalData: true,
          indicatesActiveAbuse: true,
        ),
      ],
    );
    final List<MaterialFactTrigger> triggers =
        MaterialFactEvaluator.evaluate(report, now: now)
            .map((MaterialFact f) => f.trigger)
            .toList();
    expect(triggers, contains(MaterialFactTrigger.criticalInternetFacing));
    expect(triggers, contains(MaterialFactTrigger.personalDataExposure));
    expect(triggers, contains(MaterialFactTrigger.confirmedCompromise));
  });
}
