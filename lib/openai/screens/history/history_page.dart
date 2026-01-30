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
        child: history.items.isEmpty 
          ? _EmptyHistory(t: t)
          : ListView.separated(
              padding: AppSpacing.paddingLg,
              itemCount: history.items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: Text('Escaneos guardados', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                        IconButton(
                          onPressed: () => context.read<HistoryController>().refresh(),
                          icon: Icon(Icons.refresh_rounded, color: t.colorScheme.primary),
                        ),
                      ],
                    ),
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
    final dateLabel = DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt);
    final thumbBytes = item.photosBase64.isNotEmpty ? base64Decode(item.photosBase64.first) : null;

    // Lógica de color de salud consistente con ResultPage
    final Color healthColor = item.healthStatus == 'buena' 
        ? Colors.green 
        : (item.healthStatus == 'regular' ? Colors.orange : Colors.red);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: thumbBytes == null 
                        ? Image.asset(animal.assetImage, fit: BoxFit.cover) 
                        : Image.memory(thumbBytes, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: healthColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(animal.name, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(dateLabel, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      'Salud: ${item.healthStatus.toUpperCase()}', 
                      style: t.textTheme.labelSmall?.copyWith(color: healthColor, fontWeight: FontWeight.bold)
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
  }
}

class HistoryDetailSheet extends StatelessWidget {
  const HistoryDetailSheet({super.key, required this.item});
  final ScanResult item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final animal = AnimalsCatalog.byId(item.animalId);
    final dateLabel = DateFormat('dd MMMM, yyyy - HH:mm').format(item.createdAt);

    final photos = item.photosBase64
        .map((b64) {
          try { return base64Decode(b64); } catch (_) { return null; }
        })
        .whereType<Uint8List>()
        .toList();

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) {
          return SingleChildScrollView(
            controller: controller,
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: t.colorScheme.primaryContainer,
                      child: Icon(Icons.pets, color: t.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(animal.name, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                          Text(dateLabel, style: t.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                
                if (photos.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: photos.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Image.memory(photos[i], fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.asset(animal.assetImage, height: 200, fit: BoxFit.cover),
                  ),

                const SizedBox(height: AppSpacing.lg),
                
                _DetailSection(
                  title: 'Diagnóstico de Salud',
                  icon: Icons.analytics_rounded,
                  children: [
                    _DetailRow(label: 'Estado General', value: item.healthStatus.toUpperCase()),
                    if ((item.diseaseName ?? '').isNotEmpty) _DetailRow(label: 'Enfermedad', value: item.diseaseName!),
                    if ((item.fractureDescription ?? '').isNotEmpty) _DetailRow(label: 'Fractura/Lesión', value: item.fractureDescription!),
                  ],
                ),

                _DetailSection(
                  title: 'Gestación y Reproducción',
                  icon: Icons.favorite_rounded,
                  children: [
                    _DetailRow(label: 'Embarazo', value: item.isPregnant == true ? 'Detectado' : 'No detectable'),
                    if (item.pregnancyWeeks != null) _DetailRow(label: 'Semanas estimadas', value: item.pregnancyWeeks.toString()),
                  ],
                ),

                _DetailSection(
                  title: 'Plan de Cuidados',
                  icon: Icons.medication_rounded,
                  children: [
                    if ((item.medicationName ?? '').isNotEmpty) _DetailRow(label: 'Medicamento', value: item.medicationName!),
                    if ((item.medicationDose ?? '').isNotEmpty) _DetailRow(label: 'Dosis', value: item.medicationDose!),
                    if ((item.foodRecommendation ?? '').isNotEmpty) _DetailRow(label: 'Alimentación', value: item.foodRecommendation!),
                  ],
                ),

                if ((item.microchipNumber ?? '').isNotEmpty)
                  _DetailRow(label: 'Nº Microchip', value: item.microchipNumber!),

                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cerrar Detalle'),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: t.colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const Divider(),
        ...children,
        const SizedBox(height: 16),
      ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(label, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant))),
          const SizedBox(width: 8),
          Expanded(flex: 6, child: Text(value, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final ThemeData t;
  const _EmptyHistory({required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: t.colorScheme.outline),
          const SizedBox(height: 16),
          Text('No hay escaneos aún', style: t.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Tus análisis guardados aparecerán aquí.'),
        ],
      ),
    );
  }
}
