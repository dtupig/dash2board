import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../domain/user_role.dart';
import '../persona_visuals.dart';

/// Vitrine das três personas atendidas pelo produto, na `WelcomeScreen`.
/// Isolado para manter aquele arquivo abaixo do limite de 250 linhas.
class PersonaShowcase extends StatefulWidget {
  const PersonaShowcase({super.key});

  @override
  State<PersonaShowcase> createState() => _PersonaShowcaseState();
}

class _PersonaShowcaseState extends State<PersonaShowcase> {
  static const List<UserRole> _personas = <UserRole>[
    UserRole.operational,
    UserRole.strategic,
    UserRole.board,
  ];

  int _selected = 1; // CISO em destaque: é o público primário do produto.

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final UserRole active = _personas[_selected];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'FEITO PARA TRÊS NÍVEIS DE DECISÃO',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            for (int i = 0; i < _personas.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PersonaTab(
                  role: _personas[i],
                  selected: i == _selected,
                  onTap: () => setState(() => _selected = i),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSize(
          duration: AppDuration.normal,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: SurfaceCard(
            key: ValueKey<UserRole>(active),
            accent: active.accent,
            semanticLabel: 'Entregas do painel ${active.label}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(active.icon, size: 20, color: active.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        active.label,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  active.audienceTag,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: active.accent.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  active.valueProposition,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final String item in active.highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            item,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PersonaTab extends StatelessWidget {
  const PersonaTab({
    super.key,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Ver o painel de ${role.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.buttonRadius,
        child: AnimatedContainer(
          duration: AppDuration.fast,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.buttonRadius,
            color: selected
                ? role.accent.withValues(alpha: 0.14)
                : scheme.surfaceContainerLow.withValues(alpha: 0.65),
            border: Border.all(
              color: selected
                  ? role.accent.withValues(alpha: 0.75)
                  : scheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                role.icon,
                size: 18,
                color: selected ? role.accent : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                role.shortLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
