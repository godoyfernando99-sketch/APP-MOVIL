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
      title: 'HISTORIAL DE REPORTES',
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
          color: item.isUrgent ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          width: 1.5
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailPopup(context), // Abre la ventana emergente
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
                        item.isUrgent ? "URGENTE: ${item.animalType.toUpperCase()}" : item.animalType.toUpperCase(),
                        style: TextStyle(
                          color: item.isUrgent ? Colors.redAccent : Colors.white, 
                          fontWeight: FontWeight.w900, 
                          fontSize: 14
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(item.breed ?? 'Raza no detectada', 
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("FICHA TÉCNICA IA", 
                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                      Text(dateLabel, style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
                    _DetailRow(label: 'Animal:', value: item.animalType),
                    _DetailRow(label: 'Raza / Especie:', value: item.breed ?? 'Atigrado Europeo', isAccent: true),
                    _DetailRow(label: 'Hallazgo:', value: 'Sano'),
                    _DetailRow(label: 'Prescripción:', value: 'N/A'),

                    const SizedBox(height: 20),

                    _buildSectionTitle("NOTAS DE CAMPO"),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        (item as dynamic).notes ?? "Sin notas adicionales.",
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildSectionTitle("RECOMENDACIÓN NUTRICIONAL"),
                    Text(item.suggestedFoodName.toUpperCase(), 
                      style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(item.foodRecommendation ?? "Dieta balanceada sugerida.", 
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    
                    const SizedBox(height: 20),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
      child: Text("🚨 ${item.healthStatus.toUpperCase()}", 
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildPhotoGallery(List<Uint8List> photos) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (ctx, i) => Container(
          width: 100,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: TextStyle(color: isAccent ? Colors.tealAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
          Icon(Icons.history_rounded, size: 50, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('NO HAY REGISTROS GUARDADOS', 
            style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)
          ),
        ],
      )
    );
  }
}