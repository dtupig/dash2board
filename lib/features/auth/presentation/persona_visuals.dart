import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/user_role.dart';

/// Camada de apresentação das personas.
///
/// O enum [UserRole] permanece livre de Flutter (domínio puro); tudo que é
/// visual vive aqui. Assim a mesma identidade de cor e ícone é reaproveitada
/// entre a tela de boas-vindas, o cabeçalho do dashboard e os relatórios.
extension PersonaVisuals on UserRole {
  Color get accent => switch (this) {
        UserRole.operational => AppColors.personaOperational,
        UserRole.strategic => AppColors.personaStrategic,
        UserRole.board => AppColors.personaBoard,
        UserRole.pending => AppColors.severityInfo,
      };

  IconData get icon => switch (this) {
        UserRole.operational => Icons.radar_outlined,
        UserRole.strategic => Icons.shield_moon_outlined,
        UserRole.board => Icons.insights_outlined,
        UserRole.pending => Icons.hourglass_top_outlined,
      };

  /// Etiqueta curta usada no cartão da persona.
  String get audienceTag => switch (this) {
        UserRole.operational => 'SOC · IR · VULN MGMT',
        UserRole.strategic => 'CISO · GRC · SEC STRATEGY',
        UserRole.board => 'C-LEVEL · UNIDADES DE NEGÓCIO',
        UserRole.pending => 'AGUARDANDO PROVISIONAMENTO',
      };

  /// Três entregas concretas do painel daquela persona.
  List<String> get highlights => switch (this) {
        UserRole.operational => const <String>[
            'Incidentes abertos e SLA em tempo real',
            'Vulnerabilidades priorizadas por exploração ativa',
            'Fila tática do turno com dono e prazo',
          ],
        UserRole.strategic => const <String>[
            'Postura consolidada e tendência de 12 meses',
            'Risco por domínio, compliance e maturidade',
            'Evidência pronta para comitê e auditoria',
          ],
        UserRole.board => const <String>[
            'Exposição financeira estimada do ciber-risco',
            'Impacto por unidade de negócio, sem jargão',
            'Três decisões que dependem do board',
          ],
        UserRole.pending => const <String>[
            'Seu administrador precisa atribuir um perfil',
            'O acesso é liberado sem reinstalar o aplicativo',
            'Você receberá um e-mail quando estiver pronto',
          ],
      };
}
