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

// IMPORTANTE: Asegúrate de que esta ruta sea la correcta para tu servicio de PDF
// import 'package:scanneranimal/services/pdf_service.dart'; 

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);
    final history = context.watch<HistoryController>();

    return FarmBackgroundScaffold(
      title: strings('history'),
      backgroundColor: Colors.transparent,
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
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final ScanResult item;

  @override
  Widget build(BuildContext context) {
    final animal = AnimalsCatalog.byId(item.animalId);
    final dateLabel = DateFormat('dd MMM, yyyy • HH:mm').format(item.createdAt);
    final thumbBytes = item.photosBase64.isNotEmpty ? base64Decode(item.photosBase64.first) : null;

    final Color healthColor = item.healthStatus.toLowerCase().contains('buen') 
        ? Colors.greenAccent 
        : (item.healthStatus.toLowerCase().contains('regu') ? Colors.orangeAccent : Colors.redAccent);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: item.isPregnant == true ? Colors.pinkAccent.withOpacity(0.4) : Colors.white.withOpacity(0.1),
          width: item.isPregnant == true ? 1.5 : 1,
        ),
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
                _buildThumbnail(thumbBytes, animal, healthColor),
                const SizedBox(width: 16),
                Expanded(child: _buildInfo(animal, dateLabel, healthColor)),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Uint8List? thumbBytes, dynamic animal, Color healthColor) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 70, height: 70,
            child: thumbBytes == null 
              ? Image.asset(animal.assetImage, fit: BoxFit.cover) 
              : Image.memory(thumbBytes, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 4, top: 4,
          child: Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              color: item.isPregnant == true ? Colors.pinkAccent : healthColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Icon(
              item.isPregnant == true ? Icons.favorite : Icons.circle,
              size: 8, color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(dynamic animal, String dateLabel, Color healthColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${animal.name}${item.isPregnant == true ? ' ❤️' : ''}", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)
        ),
        Text(dateLabel, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: healthColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: Text((item.diseaseName ?? 'SANO').toUpperCase(), style: TextStyle(color: healthColor, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
            if (item.medicationName != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.medication_rounded, size: 12, color: Colors.white38),
            ]
          ],
        ),
      ],
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
    final animal = AnimalsCatalog.byId(item.animalId);
    final dateLabel = DateFormat('dd MMMM, yyyy - HH:mm').format(item.createdAt);
    final photos = item.photosBase64.map((b) { try { return base64Decode(b); } catch (_) { return null; } }).whereType<Uint8List>().toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, animal, dateLabel),
            const SizedBox(height: 24),
            _buildPhotoGallery(photos, animal),
            const SizedBox(height: 24),
            
            if (item.observations?.isNotEmpty ?? false)
              _DetailSection(title: 'NOTAS DEL USUARIO', icon: Icons.edit_note_rounded, color: Colors.orangeAccent, children: [
                Text(item.observations!, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5))
              ]),

            _DetailSection(title: 'DIAGNÓSTICO IA', icon: Icons.analytics_outlined, color: Colors.cyanAccent, children: [
              _DetailRow(label: 'Estado General', value: item.healthStatus.toUpperCase()),
              if (item.diseaseName != null) _DetailRow(label: 'Hallazgo', value: item.diseaseName!),
              if (item.detectedBreed != null) _DetailRow(label: 'Raza / Especie', value: item.detectedBreed!),
            ]),

            _DetailSection(title: 'REPRODUCCIÓN', icon: Icons.favorite_rounded, color: Colors.pinkAccent, children: [
              _DetailRow(label: 'Gestación', value: item.isPregnant == true ? 'DETECTADA' : 'NO'),
              if (item.isPregnant == true) _DetailRow(label: 'Tiempo', value: item.gestationWeeks ?? 'N/A'),
            ]),

            _DetailSection(title: 'TRATAMIENTO RECOMENDADO', icon: Icons.medication_liquid_rounded, color: Colors.greenAccent, children: [
              _DetailRow(label: 'Medicamento', value: item.medicationName ?? 'N/A'),
              _DetailRow(label: 'Dosis Sugerida', value: item.medicationDose ?? 'N/A', isBold: true),
              const SizedBox(height: 12),
              const Text("DIETA Y CUIDADOS:", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(item.foodRecommendation ?? "Sin instrucciones específicas.", style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic)),
            ]),

            _buildLegalDisclaimer(),
            const SizedBox(height: 24),
            _buildBackButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic animal, String dateLabel) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.history_edu_rounded, color: Colors.blueAccent),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(animal.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(dateLabel, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ])),
        // BOTÓN PDF CON NUEVA CONFIGURACIÓN DE ACCIÓN
        IconButton.filledTonal(
          onPressed: () => _handlePdfExport(context),
          icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
        ),
      ],
    );
  }

  void _handlePdfExport(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.blueAccent,
        content: Row(children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          SizedBox(width: 12),
          Text("Preparando Reporte PDF..."),
        ]),
      ),
    );

    try {
      // AQUÍ LLAMAS A TU SERVICIO DE PDF
      // await PdfService.generateAndShare(item); 
      print("Exportando PDF de: ${item.id}");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al generar PDF")));
    }
  }

  Widget _buildPhotoGallery(List<Uint8List> photos, dynamic animal) {
    if (photos.isEmpty) {
      return ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset(animal.assetImage, height: 200, fit: BoxFit.cover));
    }
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.memory(photos[i], fit: BoxFit.cover)),
        ),
      ),
    );
  }

  Widget _buildLegalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12)),
      child: const Text(
        "Este historial es un registro informativo. Debe ser validado por un profesional veterinario antes de iniciar tratamientos.",
        style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return FilledButton(
      onPressed: () => Navigator.pop(context),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white10, foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text('CERRAR'),
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
  final ThemeData t;
  const _EmptyHistory({required this.t});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.auto_fix_off_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
      const SizedBox(height: 16),
      const Text('SIN REGISTROS', style: TextStyle(color: Colors.white30, fontWeight: FontWeight.bold, letterSpacing: 2)),
    ]));
  }
}
