import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // IMPORTANTE PARA VIBRACIÓN
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app/auth/auth_controller.dart'; 
import '../../../app/history/history_controller.dart';
import '../../../app/history/scan_models.dart';
import '../../../../nav.dart';
import '../../../../widgets/farm_background_scaffold.dart';

class ScanResultPage extends StatefulWidget {
  const ScanResultPage({super.key, this.payload});
  final dynamic payload;

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  bool _isSaving = false;
  String? _userObservations;

  @override
  void initState() {
    super.initState();
    // Iniciar vibración si es emergencia al cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForEmergencyVibration();
    });
  }

  void _checkForEmergencyVibration() {
    if (widget.payload is ScanResult) {
      final result = widget.payload as ScanResult;
      if (result.healthStatus.toUpperCase().contains("URGENTE")) {
        _vibrateAlert();
      }
    }
  }

  Future<void> _vibrateAlert() async {
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains("URGENTE")) return Colors.redAccent;
    if (s.contains("REGULAR")) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  // --- Lógica de PDF con Alerta ---
  Future<void> _shareAsProfessionalPDF(ScanResult result) async {
    final pdf = pw.Document();
    final bool isUrgent = result.healthStatus.contains("URGENTE");

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("ScannerAnimal IA - Reporte Oficial", 
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, 
              color: isUrgent ? PdfColors.red800 : PdfColors.blue800)),
            pw.Divider(thickness: 2, color: isUrgent ? PdfColors.red800 : PdfColors.blue800),
            pw.SizedBox(height: 10),
            _pdfRow("Estado:", result.healthStatus.toUpperCase(), isBold: true),
            _pdfRow("Especie/Raza:", "${result.animalType} / ${result.breed}"),
            _pdfRow("Microchip:", result.microchipNumber ?? "N/A"),
            pw.SizedBox(height: 15),
            pw.Text("DIAGNÓSTICO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(result.diseaseName ?? "Sano"),
            pw.SizedBox(height: 10),
            pw.Text("TRATAMIENTO Y DOSIS:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(result.medicationDose ?? "N/A"),
            pw.SizedBox(height: 10),
            pw.Text("OBSERVACIONES:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(result.observations ?? ""),
          ]
        );
      }
    ));

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Reporte_${result.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)]);
  }

  pw.Widget _pdfRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload is! ScanResult) return _buildGeneralErrorState();

    final result = widget.payload as ScanResult;
    final bool isEmergency = result.healthStatus.toUpperCase().contains("URGENTE");
    final Color statusColor = _getStatusColor(result.healthStatus);

    return FarmBackgroundScaffold(
      title: 'ANÁLISIS COMPLETADO',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            if (result.microchipNumber != null) _buildMicrochipBanner(result.microchipNumber!),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isEmergency ? Colors.red.withOpacity(0.15) : Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isEmergency ? Colors.redAccent : statusColor.withOpacity(0.3), width: isEmergency ? 2 : 1),
              ),
              child: Column(
                children: [
                  _buildHeader(result, statusColor, isEmergency),
                  const Divider(color: Colors.white10, height: 40),
                  _buildResultRow('Especie/Raza:', result.breed, Icons.pets, valueColor: Colors.cyanAccent),
                  if (result.isPregnant) _buildResultRow('Gestación:', result.gestationWeeks ?? 'Si', Icons.auto_awesome, valueColor: Colors.pinkAccent),
                  _buildResultRow('Hallazgo:', result.diseaseName, Icons.healing),
                  _buildResultRow('Dosis y Aplicación:', result.medicationDose, Icons.medication, valueColor: isEmergency ? Colors.redAccent : Colors.greenAccent),
                  const SizedBox(height: 20),
                  _buildNutritionalBox(result),
                  const SizedBox(height: 30),
                  _buildActionButtons(result),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ScanResult result, Color color, bool isEmergency) {
    return Column(children: [
      Icon(isEmergency ? Icons.warning_amber_rounded : Icons.analytics_outlined, color: color, size: 60),
      const SizedBox(height: 10),
      Text(result.healthStatus.toUpperCase(), textAlign: TextAlign.center, 
        style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.black)),
    ]);
  }

  Widget _buildResultRow(String label, String? value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const Spacer(),
        Flexible(child: Text(value ?? 'N/A', textAlign: TextAlign.right, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _buildNutritionalBox(ScanResult result) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(result.suggestedFoodName.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(result.foodRecommendation ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _buildActionButtons(ScanResult result) {
    return Row(children: [
      Expanded(child: TextButton.icon(onPressed: () => _shareAsProfessionalPDF(result), icon: const Icon(Icons.share), label: const Text("PDF"), style: TextButton.styleFrom(foregroundColor: Colors.white))),
      const SizedBox(width: 10),
      Expanded(child: ElevatedButton(onPressed: _isSaving ? null : _showObservationsAndSave, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("FINALIZAR"))),
    ]);
  }

  Widget _buildMicrochipBanner(String id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.shade900, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        const Icon(Icons.nfc, color: Colors.white),
        const SizedBox(width: 10),
        Text("MICROCHIP: $id", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // Métodos de guardado se mantienen igual...
  Future<void> _showObservationsAndSave() async {
    final result = await showDialog<String>(context: context, builder: (c) => AlertDialog(title: const Text("Notas"), content: const TextField(), actions: [TextButton(onPressed: () => Navigator.pop(c, ""), child: const Text("OK"))]));
    if (result != null) {
      setState(() => _isSaving = true);
      await context.read<HistoryController>().add((widget.payload as ScanResult).copyWith(observations: result));
      await context.read<AuthController>().useFreeScan();
      if (mounted) context.go(AppRoutes.menu);
    }
  }

  Widget _buildGeneralErrorState() => FarmBackgroundScaffold(title: 'ERROR', child: const Center(child: Text("Error de datos")));
}