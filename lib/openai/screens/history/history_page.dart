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
    // Usamos context.watch para reaccionar a cambios en el historial
    final historyController = context.watch<HistoryController>();
    final items = historyController.history; // CORREGIDO: Usamos .history en lugar de .items

    return FarmBackgroundScaffold(
      title: 'HISTORIAL DE REPORTES',
      backgroundColor: Colors.transparent,
      child: RefreshIndicator(
        onRefresh: () => context.read<HistoryController>().refresh(),
        child: items.isEmpty 
          ? const _EmptyHistory()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              // +1 para el header
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                if (i == 0) return _buildHeader();
                final item = items[i - 1];
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
        'REGISTROS MÉDICOS GUARDADOS', 
        style: TextStyle(
          color: Colors.white70, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 1.2, 
          fontSize: 11,
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
    final dateLabel = DateFormat('dd MMM, yyyy').format(item.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          // CORREGIDO: isUrgent ahora detecta HighRisk automáticamente por el modelo
          color: item.isUrgent ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          width: 1.5
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailPopup(context),
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
                        item.isUrgent ? "🚨 URGENTE: ${item.animalType.toUpperCase()}" : item.animalType.toUpperCase(),
                        style: TextStyle(
                          color: item.isUrgent ? Colors.redAccent : Colors.white, 
                          fontWeight: FontWeight.w900, 
                          fontSize: 14
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(item.breed ?? 'Especie detectada', 
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(dateLabel, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Uint8List? bytes) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 60, height: 60,
          child: bytes != null 
            ? Image.memory(bytes, fit: BoxFit.cover)
            : Container(color: Colors.white10, child: const Icon(Icons.pets, color: Colors.white24)),
        ),
      ),
    );
  }

  void _showDetailPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: HistoryDetailPopup(item: item),
      ),
    );
  }
}

class HistoryDetailPopup extends StatelessWidget {
  const HistoryDetailPopup({super.key, required this.item});
  final ScanResult item;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMMM, yyyy').format(item.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del Popup
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white.withOpacity(0.03),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("INFORME MÉDICO IA", 
                        style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                      Text("DETALLE DE DIAGNÓSTICO", style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Contenido escroleable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (item.isUrgent) _buildUrgentBox(),
                    if (item.isUrgent) const SizedBox(height: 20),

                    if (item.photos.isNotEmpty) _buildPhotoGallery(item.photos),
                    const SizedBox(height: 24),

                    _buildSectionTitle("DATOS DEL PACIENTE"),
                    _DetailRow(label: 'Fecha:', value: dateLabel),
                    _DetailRow(label: 'Animal:', value: item.animalType),
                    _DetailRow(label: 'Raza:', value: item.breed ?? 'Detectada por IA', isAccent: true),
                    
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle("HALLAZGOS Y DIAGNÓSTICO"),
                    Text(item.healthStatus, 
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),

                    const SizedBox(height: 20),

                    _buildSectionTitle("NOTAS DE CAMPO (PERSONAL)"),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        // CORREGIDO: Ya no es dynamic, usamos el campo del modelo
                        (item.notes == null || item.notes!.isEmpty) 
                            ? "Sin notas adicionales guardadas." 
                            : item.notes!,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildSectionTitle("ALIMENTACIÓN SUGERIDA"),
                    Text(item.suggestedFoodName.isEmpty ? "DIETA GENERAL" : item.suggestedFoodName.toUpperCase(), 
                      style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(item.foodRecommendation ?? "Siga las instrucciones del profesional.", 
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),

                    const SizedBox(height: 30),
                    
                    // Botón para cerrar
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("CERRAR INFORME", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  Widget _buildUrgentBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
          SizedBox(width: 10),
          Text("ALTO RIESGO DETECTADO", 
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(List<Uint8List> photos) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (ctx, i) => Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
            image: DecorationImage(image: MemoryImage(photos[i]), fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isAccent;
  const _DetailRow({required this.label, required this.value, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(value, 
              textAlign: TextAlign.right,
              style: TextStyle(color: isAccent ? Colors.tealAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 60, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          const Text('HISTORIAL VACÍO', 
            style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14)
          ),
          const SizedBox(height: 8),
          const Text('Los informes que guardes aparecerán aquí.', 
            style: TextStyle(color: Colors.white10, fontSize: 12)
          ),
        ],
      )
    );
  }
}