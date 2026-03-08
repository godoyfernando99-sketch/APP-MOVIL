import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/history/history_controller.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
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
                if (i == 0) return _buildHeader();
                final item = history.items[i - 1];
                return _HistoryCard(item: item);
              },
            ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Text(
        'ESCANEOS GUARDADOS', 
        style: TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 1.2, 
          fontSize: 13,
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
    // CORRECCIÓN: Usamos timestamp en lugar de createdAt
    final dateLabel = DateFormat('dd MMM, yyyy • HH:mm').format(item.timestamp);
    
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
                _buildThumbnail(item.photos.isNotEmpty ? item.photos.first : null),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${item.animalType} - ${item.breed ?? 'Raza desconocida'}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(dateLabel, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                      const SizedBox(height: 8),
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
    // CORRECCIÓN: Usamos healthStatus y evitamos diseaseName que no existe
    final bool isUrgent = item.isUrgent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isUrgent ? Colors.redAccent : Colors.greenAccent).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (isUrgent ? Colors.redAccent : Colors.greenAccent).withOpacity(0.3))
      ),
      child: Text(
        (isUrgent ? 'URGENTE' : 'ESTABLE').toUpperCase(),
        style: TextStyle(
          color: isUrgent ? Colors.redAccent : Colors.greenAccent, 
          fontSize: 9, 
          fontWeight: FontWeight.w900,
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
    // CORRECCIÓN: Usamos timestamp
    final dateLabel = DateFormat('dd MMMM, yyyy - HH:mm').format(item.timestamp);

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

            if (item.photos.isNotEmpty) _buildPhotoGallery(item.photos),
            const SizedBox(height: 24),

            _DetailSection(
              title: 'IDENTIFICACIÓN', 
              icon: Icons.pets_rounded, 
              color: Colors.cyanAccent, 
              children: [
                _DetailRow(label: 'Tipo de Animal', value: item.animalType.toUpperCase()),
                _DetailRow(label: 'Raza / Especie', value: item.breed ?? 'No detectado', isBold: true),
                // CORRECCIÓN: microchipId en lugar de microchipNumber
                if (item.microchipId != null)
                  _DetailRow(label: 'Microchip ID', value: item.microchipId!),
              ]
            ),

            _DetailSection(
              title: 'ESTADO DE SALUD IA', 
              icon: Icons.monitor_heart_rounded, 
              color: Colors.greenAccent, 
              children: [
                // CORRECCIÓN: healthStatus en lugar de diseaseName
                _DetailRow(label: 'Informe IA', value: item.healthStatus, isBold: item.isUrgent),
              ]
            ),

            _DetailSection(
              title: 'RECOMENDACIÓN NUTRICIONAL', 
              icon: Icons.restaurant_rounded, 
              color: Colors.orangeAccent, 
              children: [
                const Text("ALIMENTO RECOMENDADO:", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(item.suggestedFoodName.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 16),
                Text(item.foodRecommendation ?? "Sin instrucciones específicas.", style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]
            ),

            if (item.isPregnant)
              _DetailSection(
                title: 'ESTADO REPRODUCTIVO', 
                icon: Icons.favorite_rounded, 
                color: Colors.pinkAccent, 
                children: [
                  _DetailRow(label: 'Gestación', value: 'CONFIRMADA'),
                  _DetailRow(label: 'Crías Estimadas', value: item.offspringCount ?? 'N/A'),
                  _DetailRow(label: 'Etapa', value: item.gestationWeeks ?? 'N/A'),
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
              child: const Text('REGRESAR AL HISTORIAL', style: TextStyle(fontWeight: FontWeight.bold)),
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
        const Text("REPORTE DETALLADO", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
        const SizedBox(height: 4),
        Text(date, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }

  Widget _buildPhotoGallery(List<Uint8List> photos) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (ctx, i) => Container(
          width: 250,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
            image: DecorationImage(image: MemoryImage(photos[i]), fit: BoxFit.cover)
          ),
        ),
      ),
    );
  }
}

// Widgets de soporte _DetailSection, _DetailRow y _EmptyHistory se mantienen igual...
// (Omitidos por brevedad, pero asegúrate de no borrarlos de tu archivo original)