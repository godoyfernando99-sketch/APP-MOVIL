import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class AnimalDetailPage extends StatelessWidget {
  const AnimalDetailPage({super.key, required this.animalId});
  final String animalId;

  @override
  Widget build(BuildContext context) {
    final animal = AnimalsCatalog.byId(animalId);
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);

    return FarmBackgroundScaffold(
      title: animal.name,
      child: Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Image.asset(animal.assetImage, height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Selecciona el tipo de escaneo', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push('${AppRoutes.scanCapture}/${animal.id}/chip'),
                        icon: Icon(Icons.nfc_rounded, color: t.colorScheme.onPrimary),
                        label: Text(strings('scanWithChip'), style: TextStyle(color: t.colorScheme.onPrimary)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('${AppRoutes.scanCapture}/${animal.id}/nochip'),
                        icon: Icon(Icons.camera_alt_rounded, color: t.colorScheme.primary),
                        label: Text(strings('scanWithoutChip'), style: TextStyle(color: t.colorScheme.primary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
