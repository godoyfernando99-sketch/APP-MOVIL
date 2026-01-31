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
      backgroundColor: Colors.transparent, // Fondo transparente
      child: RefreshIndicator(
        onRefresh: () => context.read<HistoryController>().refresh(),
        child: history.items.isEmpty 
          ? _EmptyHistory(t: t)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: history.items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ESCANEOS GUARDADOS', 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13)
                          )
                        ),
                        IconButton(
                          onPressed: () => context.read<HistoryController>().refresh(),
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
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
    final animal = AnimalsCatalog.byId(item.animalId);
    final dateLabel = DateFormat('dd MMM, yyyy • HH:mm').format(item.createdAt);
    final thumbBytes = item.photosBase64.isNotEmpty ? base64Decode(item.photosBase64.first) : null;

    final Color healthColor = item.healthStatus == 'buena' 
        ? Colors.greenAccent 
        : (item.healthStatus == 'regular' ? Colors.orangeAccent : Colors.redAccent);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65), // Efecto cristal
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            backgroundColor: const Color(0xFF0F0F0F), // Fondo oscuro para el modal
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            builder: (_) => HistoryDetailSheet(item: item),
          ),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: thumbBytes == null 
                          ? Image.asset(animal.assetImage, fit: BoxFit.cover) 
                          : Image.memory(thumbBytes, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: healthColor,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: healthColor.withOpacity(0.5), blurRadius: 4)],
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(animal.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(dateLabel, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: healthColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.healthStatus.toUpperCase(), 
                          style: TextStyle(color: healthColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
              ],
            ),
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
    final animal = AnimalsCatalog.byId(item.animalId);
    final dateLabel = DateFormat('dd MMMM, yyyy - HH:mm').format(item.createdAt);

    final photos = item.photosBase64
        .map((b64) {
          try { return base64Decode(b64); } catch (_) { return null; }
        })
        .whereType<Uint8List>()
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera Modal
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.history_edu_rounded, color: Colors.blueAccent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(animal.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        Text(dateLabel, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Fotos
              if (photos.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    itemCount: photos.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.memory(photos[i], fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(animal.assetImage, height: 200, fit: BoxFit.cover),
                ),

              const SizedBox(height: 24),
              
              // Secciones de Información
              _DetailSection(
                title: 'DIAGNÓSTICO',
                icon: Icons.analytics_outlined,
                color: Colors.cyanAccent,
                children: [
                  _DetailRow(label: 'Estado', value: item.healthStatus.toUpperCase()),
                  if ((item.diseaseName ?? '').isNotEmpty) _DetailRow(label: 'Enfermedad', value: item.diseaseName!),
                ],
              ),

              _DetailSection(
                title: 'REPRODUCCIÓN',
                icon: Icons.auto_awesome_rounded,
                color: Colors.pinkAccent,
                children: [
                  _DetailRow(label: 'Embarazo', value: item.isPregnant == true ? 'DETECTADO' : 'NO DETECTADO'),
                  if (item.pregnancyWeeks != null) _DetailRow(label: 'Semanas', value: item.pregnancyWeeks.toString()),
                ],
              ),

              _DetailSection(
                title: 'TRATAMIENTO',
                icon: Icons.medication_liquid_rounded,
                color: Colors.greenAccent,
                children: [
                  if ((item.medicationName ?? '').isNotEmpty) _DetailRow(label: 'Medicamento', value: item.medicationName!),
                  if ((item.foodRecommendation ?? '').isNotEmpty) _DetailRow(label: 'Dieta', value: item.foodRecommendation!),
                ],
              ),

              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('VOLVER', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.icon, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10, height: 1),
          ),
          ...children,
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
          Icon(Icons.auto_fix_off_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('HISTORIAL VACÍO', style: TextStyle(color: Colors.white30, fontWeight: FontWeight.bold, letterSpacing: 2)),
        ],
      ),
    );
  }
}
