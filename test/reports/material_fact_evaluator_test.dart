import 'package:elytron_dash2board/features/reports/domain/finding_severity.dart';
import 'package:elytron_dash2board/features/reports/domain/material_fact.dart';
import 'package:elytron_dash2board/features/reports/domain/material_fact_evaluator.dart';
import 'package:elytron_dash2board/features/reports/domain/models/pentest_finding.dart';
import 'package:flutter_test/flutter_test.dart';

import 'material_fact_fixtures.dart';

void main() {
  group('confirmedCompromise', () {
    test('positivo: IncidentResponseReport com IOC dispara', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        incidentReport(iocs: const <String>['185.0.0.1']),
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.confirmedCompromise),
        isTrue,
      );
    });

    test(
        'positivo: pentest com indicatesActiveAbuse dispara mesmo sem '
        'confissão formal (critério explícito de D-27)', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        pentestReport(
          findings: <PentestFinding>[finding(indicatesActiveAbuse: true)],
        ),
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.confirmedCompromise),
        isTrue,
      );
    });

    test('negativo: sem IOC nem indício de abuso, não dispara', () {
      final List<MaterialFact> facts =
          MaterialFactEvaluator.evaluate(incidentReport(), now: now);
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.confirmedCompromise),
        isFalse,
      );
    });
  });

  group('personalDataExposure', () {
    test('positivo: affectedDataSubjects não vazio dispara', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        incidentReport(affectedDataSubjects: const <String>['titular-1']),
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.personalDataExposure),
        isTrue,
      );
    });

    test('positivo: achado de pentest com dado pessoal dispara', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        pentestReport(
          findings: <PentestFinding>[finding(containsPersonalData: true)],
        ),
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.personalDataExposure),
        isTrue,
      );
    });

    test('negativo: sem dado pessoal, não dispara', () {
      final List<MaterialFact> facts =
          MaterialFactEvaluator.evaluate(incidentReport(), now: now);
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.personalDataExposure),
        isFalse,
      );
    });
  });

  group('criticalInternetFacing', () {
    test('positivo: achado crítico dispara', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        pentestReport(
          findings: <PentestFinding>[
            finding(severity: FindingSeverity.critical)
          ],
        ),
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.criticalInternetFacing),
        isTrue,
      );
    });

    test('negativo: só achado baixo, não dispara', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        pentestReport(findings: <PentestFinding>[finding()]),
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.criticalInternetFacing),
        isFalse,
      );
    });
  });

  group('regulatoryDeadlineRisk', () {
    test('positivo: prazo em 30 dias dispara', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        governanceReport(
            regulatoryDeadlines: <DateTime>[now.add(const Duration(days: 30))]),
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.regulatoryDeadlineRisk),
        isTrue,
      );
    });

    test('negativo: prazo em 200 dias não dispara', () {
      final List<MaterialFact> facts = MaterialFactEvaluator.evaluate(
        governanceReport(regulatoryDeadlines: <DateTime>[
          now.add(const Duration(days: 200))
        ]),
        now: now,
      );
      expect(
        facts.any((MaterialFact f) =>
            f.trigger == MaterialFactTrigger.regulatoryDeadlineRisk),
        isFalse,
      );
    });
  });
}
