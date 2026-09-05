import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/persona_visuals.dart';
import 'onboarding_content.dart';
import 'onboarding_page_layout.dart';

/// Introdução de 3 telas mostrada só no primeiro acesso de cada persona a
/// seu painel - pulável, nunca obrigatória, e nunca reaparece depois que
/// [onDone] é chamado (a persistência é responsabilidade de quem usa este
/// widget, ver `OnboardingGate`).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.role, required this.onDone});

  final UserRole role;
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next(int pageCount) {
    if (_page == pageCount - 1) {
      widget.onDone();
      return;
    }
    _pageController.nextPage(
      duration: AppDuration.normal,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = widget.role.accent;
    final List<OnboardingPageData> pages = onboardingPagesFor(widget.role);

    if (pages.isEmpty) {
      // Sem conteúdo para esta persona (ex.: `pending`, que nunca chega
      // num dashboard) - não bloqueia nada, só sai.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return const SizedBox.shrink();
    }

    final bool isLastPage = _page == pages.length - 1;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Pular'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (int index) => setState(() => _page = index),
                itemBuilder: (BuildContext context, int index) {
                  final OnboardingPageData page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: OnboardingPageLayout(page: page, accent: accent),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Semantics(
                label: 'Tela ${_page + 1} de ${pages.length}.',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < pages.length; i++)
                        AnimatedContainer(
                          duration: AppDuration.fast,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxs,
                          ),
                          width: i == _page ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page ? accent : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: FilledButton(
                onPressed: () => _next(pages.length),
                child: Text(isLastPage ? 'Começar' : 'Avançar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
