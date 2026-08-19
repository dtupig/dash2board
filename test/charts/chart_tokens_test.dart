import 'package:elytron_dash2board/core/theme/app_colors.dart';
import 'package:elytron_dash2board/core/theme/chart_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a lista categórica tem exatamente 3 cores', () {
    expect(ChartTokens.categorical.length, 3);
  });

  test('nenhuma cor de severidade aparece na lista categórica', () {
    const List<Color> reserved = <Color>[
      AppColors.severityCritical,
      AppColors.severityHigh,
      AppColors.severityMedium,
      AppColors.severityLow,
    ];

    for (final Color reservedColor in reserved) {
      expect(ChartTokens.categorical.contains(reservedColor), isFalse);
    }
  });

  test('as rampas sequenciais têm 5 passos', () {
    expect(ChartTokens.sequentialDark.length, 5);
    expect(ChartTokens.sequentialLight.length, 5);
  });

  test('sequentialFor escolhe a rampa certa por brilho', () {
    expect(
      ChartTokens.sequentialFor(Brightness.dark),
      ChartTokens.sequentialDark,
    );
    expect(
      ChartTokens.sequentialFor(Brightness.light),
      ChartTokens.sequentialLight,
    );
  });

  test('a rampa clara não é apenas o espelho invertido da escura', () {
    final List<Color> invertedDark =
        ChartTokens.sequentialDark.reversed.toList(growable: false);
    expect(ChartTokens.sequentialLight, isNot(equals(invertedDark)));
  });
}
