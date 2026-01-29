import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/history/history_controller.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);
    final history = context.watch<HistoryController>();

    return FarmBackgroundScaffold(
      title: strings('history'),
      child: RefreshIndicator(
        onRefresh: () => context.read<HistoryController>().refresh(),
        child: ListView.separated(
          padding: AppSpacing.paddingLg,
          itemCount: history.items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Row(
                children: [
                  Expanded(child: Text('Escaneos guardados', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                  IconButton(
                    onPressed: () => context.read<HistoryController>().refresh(),
                    icon: Icon(Icons.refresh_rounded, color: t.colorScheme.primary),
                  ),
                ],
              );
            }
            final item = history.items[i - 1];
            return _HistoryCard(item: item);
          },
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final ScanResult item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final animal = AnimalsCatalog.byId(item.animalId);
    final dateLabel = DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt);
    final thumbBytes = item.photosBase64.isNotEmpty ? base64Decode(item.photosBase64.first) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        highlightColor: t.colorScheme.primary.withValues(alpha: 0.08),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          backgroundColor: t.colorScheme.surface,
          builder: (_) => HistoryDetailSheet(item: item),
        ),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: thumbBytes == null ? Image.asset(animal.assetImage, fit: BoxFit.cover) : Image.memory(thumbBytes, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${animal.name} • $dateLabel', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Salud: ${item.healthStatus}', style: t.textTheme.bodySmall),
                    if (item.diseaseName != null && item.diseaseName!.isNotEmpty) Text('Enfermedad: ${item.diseaseName}', style: t.textTheme.bodySmall),
                    if (item.fractureDescription != null && item.fractureDescription!.isNotEmpty) Text('Fractura: ${item.fractureDescription}', style: t.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryDetailSheet extends StatelessWidget {
  /// Full detail view for a saved scan (History).
  const HistoryDetailSheet({super.key, required this.item});
  final ScanResult item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final animal = AnimalsCatalog.byId(item.animalId);
    final dateLabel = DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt);

    final photos = item.photosBase64
        .map((b64) {
          try {
            return base64Decode(b64);
          } catch (_) {
            return null;
          }
        })
        .whereType<Uint8List>()
        .toList();

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.55,
        maxChildSize: 0.98,
        expand: false,
        builder: (context, controller) {
          return SingleChildScrollView(
            controller: controller,
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(animal.name, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(dateLabel, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.md),
                if (photos.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: PageView.builder(
                      itemCount: photos.length,
                      itemBuilder: (context, i) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Image.memory(photos[i], fit: BoxFit.cover),
                        );
                      },
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.asset(animal.assetImage, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                _DetailRow(label: 'Estado de salud', value: item.healthStatus),
                _DetailRow(label: 'Modo', value: item.mode),
                if ((item.microchipNumber ?? '').isNotEmpty) _DetailRow(label: 'Microchip', value: item.microchipNumber!),
                if ((item.diseaseName ?? '').isNotEmpty) _DetailRow(label: 'Enfermedad', value: item.diseaseName!),
                if ((item.fractureDescription ?? '').isNotEmpty) _DetailRow(label: 'Fractura', value: item.fractureDescription!),
                if ((item.medicationName ?? '').isNotEmpty) _DetailRow(label: 'Medicamento', value: item.medicationName!),
                if ((item.medicationDose ?? '').isNotEmpty) _DetailRow(label: 'Dosis', value: item.medicationDose!),
                if (item.isPregnant != null) _DetailRow(label: 'Embarazo', value: item.isPregnant! ? 'Sí' : 'No'),
                if (item.pregnancyWeeks != null) _DetailRow(label: 'Semanas', value: item.pregnancyWeeks.toString()),
                if ((item.foodRecommendation ?? '').isNotEmpty) _DetailRow(label: 'Alimentación recomendada', value: item.foodRecommendation!),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => context.pop(),
                  style: FilledButton.styleFrom(backgroundColor: t.colorScheme.primary),
                  child: Text('Cerrar', style: TextStyle(color: t.colorScheme.onPrimary)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: t.colorScheme.outline.withValues(alpha: 0.16)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(label, style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: Text(value, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
