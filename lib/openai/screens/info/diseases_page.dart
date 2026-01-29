import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/data/diseases.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class DiseasesPage extends StatelessWidget {
  const DiseasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);
    final auth = context.watch<AuthController>();
    final isPro = auth.currentUser?.isPro ?? false;

    if (!isPro) {
      return FarmBackgroundScaffold(
        title: strings('diseases'),
        child: Center(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Card(
              child: Padding(
                padding: AppSpacing.paddingXl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 64, color: t.colorScheme.primary),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Contenido Exclusivo PRO',
                      style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'La lista completa de enfermedades está disponible solo para usuarios del Plan PRO.',
                      style: t.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.subscriptions),
                      icon: Icon(Icons.star_rounded, color: t.colorScheme.onPrimary),
                      label: Text('Ver Planes', style: TextStyle(color: t.colorScheme.onPrimary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FarmBackgroundScaffold(
      title: strings('diseases'),
      child: ListView.separated(
        padding: AppSpacing.paddingLg,
        itemCount: DiseasesCatalog.diseases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final d = DiseasesCatalog.diseases[i];
          return Card(
            child: InkWell(
              onTap: () => _showDiseaseDetail(context, d),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.asset(
                        d.imagePath,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: t.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.medical_services_rounded, color: t.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            d.description,
                            style: t.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDiseaseDetail(BuildContext context, Disease disease) {
    final t = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.asset(
                    disease.imagePath,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 200,
                      color: t.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.medical_services_rounded, size: 64, color: t.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(disease.name, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: AppSpacing.md),
                Text('Descripción', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: t.colorScheme.primary)),
                const SizedBox(height: 4),
                Text(disease.description, style: t.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                Text('Síntomas', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: t.colorScheme.primary)),
                const SizedBox(height: 4),
                Text(disease.symptoms, style: t.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                Text('Tratamiento', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: t.colorScheme.primary)),
                const SizedBox(height: 4),
                Text(disease.treatment, style: t.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cerrar', style: TextStyle(color: t.colorScheme.onPrimary)),
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
