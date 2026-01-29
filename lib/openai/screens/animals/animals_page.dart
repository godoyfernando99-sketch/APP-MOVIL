import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class AnimalsPage extends StatefulWidget {
  const AnimalsPage({super.key});

  @override
  State<AnimalsPage> createState() => _AnimalsPageState();
}

class _AnimalsPageState extends State<AnimalsPage> {
  String _category = AnimalCategory.home;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final params = GoRouterState.of(context).uri.queryParameters;
    final initial = params['category'];
    if (initial == AnimalCategory.farm || initial == AnimalCategory.home) {
      _category = initial!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = (String key) => AppStrings.of(context, key);

    final animals =
        AnimalsCatalog.animals.where((a) => a.category == _category).toList();

    return FarmBackgroundScaffold(
      title: _category == AnimalCategory.home
          ? strings('homeAnimals')
          : strings('farmAnimals'),
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.horizontalLg,
            child: Row(
              children: [
                Expanded(
                  child: _ChoiceCard(
                    selected: _category == AnimalCategory.home,
                    title: strings('homeAnimals'),
                    icon: Icons.home_rounded,
                    onTap: () =>
                        setState(() => _category = AnimalCategory.home),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ChoiceCard(
                    selected: _category == AnimalCategory.farm,
                    title: strings('farmAnimals'),
                    icon: Icons.agriculture_rounded,
                    onTap: () =>
                        setState(() => _category = AnimalCategory.farm),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: GridView.builder(
              padding: AppSpacing.paddingLg,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemCount: animals.length,
              itemBuilder: (context, i) {
                final a = animals[i];
                return _AnimalCard(
                  animal: a,
                  onTap: () => context.push('${AppRoutes.animal}/${a.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard(
      {required this.selected,
      required this.title,
      required this.icon,
      required this.onTap});
  final bool selected;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: selected
            ? cs.primaryContainer.withValues(alpha: 0.7)
            : cs.surface.withValues(alpha: 0.55),
        border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.35)
                : cs.outline.withValues(alpha: 0.18)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          highlightColor: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? cs.onPrimaryContainer : cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal, required this.onTap});
  final Animal animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Material(
      color: cs.surface.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        highlightColor: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(animal.assetImage, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: cs.outline.withValues(alpha: 0.18)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              animal.id == 'pig'
                                  ? Icons.cruelty_free_rounded
                                  : Icons.pets_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(animal.name,
                  style: t.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Toca para escanear', style: t.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
