import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/history/history_controller.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = (String key) => AppStrings.of(context, key);
    final history = context.watch<HistoryController>();

    return FarmBackgroundScaffold(
      title: strings('history'),
      backgroundColor: Colors.transparent,
      child: RefreshIndicator(
        onRefresh: () => context.read<HistoryController>().refresh(),
        child: history.items.isEmpty 
          ? const _EmptyHistory()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: history.items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _buildHeader(context);
                }
                final item = history.items[i - 1];
                return _HistoryCard(item: item);
              },
            ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Text(
        'ESCANEOS GUARDADOS', 
        style: TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 1.2, 
          fontSize: 13,
          shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))]
        )
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final ScanResult item;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMM, yyyy • HH:mm').format(item.createdAt);
    final thumbBytes = item.photosBase64.isNotEmpty ? base64Decode(item.photosBase64.first) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetail(context),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildThumbnail(thumbBytes),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Muestra Tipo de Animal y Raza directamente en la tarjeta
                      Text(
                        "${item.animalType ?? 'Animal'} - ${item.detectedBreed ?? 'Raza'}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(dateLabel, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                      const SizedBox(height: 6),
                      _buildStatusBadge(),
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

  Widget _buildThumbnail(Uint8List? bytes) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 65, height: 65,
        child: bytes != null 
          ? Image.memory(bytes, fit: BoxFit.cover)
          : Container(color: Colors.white10, child: const Icon(Icons.pets, color: Colors.white24)),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final bool isHealthy = item.healthStatus.toLowerCase().contains('buen') || item.diseaseName == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isHealthy ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6)
      ),
      child: Text(
        (item.diseaseName ?? 'SANO').toUpperCase(),
        style: TextStyle(
          color: isHealthy ? Colors.greenAccent : Colors.orangeAccent, 
          fontSize: 9, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (_) => HistoryDetailSheet(item: item),
    );
  }
}

class HistoryDetailSheet extends StatelessWidget {
  const HistoryDetailSheet({super.key, required this.item});
  final ScanResult item;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMMM, yyyy - HH:mm').format(item.createdAt);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDetailHeader(dateLabel),
            const SizedBox(height: 24),

            // SECCIÓN IDENTIFICACIÓN (Animal y Raza)
            _DetailSection(
              title: 'IDENTIFICACIÓN', 
              icon: Icons.pets_rounded, 
              color: Colors.cyanAccent, 
              children: [
                _DetailRow(label: 'Tipo de Animal', value: item.animalType ?? 'N/A'),
                _DetailRow(label: 'Raza / Especie', value: item.detectedBreed ?? 'N/A', isBold: true),
              ]
            ),

            // SECCIÓN SALUD
            _DetailSection(
              title: 'ESTADO DE SALUD', 
              icon: Icons.monitor_heart_rounded, 
              color: Colors.greenAccent, 
              children: [
                _DetailRow(label: 'Condición', value: item.healthStatus.toUpperCase()),
                if (item.diseaseName != null) _DetailRow(label: 'Diagnóstico', value: item.diseaseName!),
              ]
            ),

            // SECCIÓN NUTRICIÓN (Alimento Sugerido)
            _DetailSection(
              title: 'RECOMENDACIÓN NUTRICIONAL', 
              icon: Icons.restaurant_rounded, 
              color: Colors.orangeAccent, 
              children: [
                const Text("ALIMENTO SUGERIDO:", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  // Intenta extraer el nombre del alimento si está en el string, sino usa uno genérico
                  item.foodRecommendation?.split('.').first ?? "Alimento Balanceado Específico",
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  item.foodRecommendation ?? "Sin recomendaciones específicas.",
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ]
            ),

            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white10,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
              child: const Text('CERRAR'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHeader(String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("REPORTE IA", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        Text(date, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }
}

// WIDGETS DE SOPORTE PARA EL DISEÑO
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
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        ]),
        const Divider(color: Colors.white10, height: 24),
        ...children,
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.isBold = false});
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(
          color: isBold ? Colors.greenAccent : Colors.white, 
          fontSize: 13, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold
        ))),
      ]),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('NO HAY REGISTROS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 2))
    );
  }
}