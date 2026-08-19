import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/compliance_control.dart';

/// Visual de cada [ControlStatus]: cor de estado + ícone.
///
/// Vive na camada de apresentação (não em `compliance_control.dart`, que é
/// domínio puro sem Flutter) - mesmo padrão de `persona_visuals.dart`. As
/// cores são semânticas (`AppColors.success`/`warning`/`danger`), não cores
/// de série: `compliant` é bom, `gap` é ruim, e o produto já tem esse
/// vocabulário estabelecido.
extension ControlStatusVisuals on ControlStatus {
  Color get color => switch (this) {
        ControlStatus.compliant => AppColors.success,
        ControlStatus.partial => AppColors.warning,
        ControlStatus.gap => AppColors.danger,
      };

  IconData get icon => switch (this) {
        ControlStatus.compliant => Icons.check_circle_outline_rounded,
        ControlStatus.partial => Icons.remove_circle_outline_rounded,
        ControlStatus.gap => Icons.highlight_off_rounded,
      };
}
