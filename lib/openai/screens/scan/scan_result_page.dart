import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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

  /// Genera un PDF profesional incluyendo el Microchip
  Future<void> _shareAsProfessionalPDF(ScanResult result, String breedDisplay) async {
    final pdf = pw.Document();
    
    pw.MemoryImage? animalImage;
    if (result.photosBase64.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(result.photosBase64.first);
        animalImage = pw.MemoryImage(bytes);
      } catch (e) {
        debugPrint("Error decodificando imagen para PDF: $e");
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ScannerAnimal IA - Reporte Oficial", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Text("ID: ${result.id.substring(0,8)}"),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 15),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (animalImage != null)
                    pw.Container(
                      width: 120,
                      height: 120,
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10))),
                      child: pw.ClipRRect(borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)), child: pw.Image(animalImage, fit: pw.BoxFit.cover)),
                    ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("DATOS DE IDENTIFICACIÓN", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 5),
                        _pdfRow("Especie:", result.detectedSpecies ?? "N/A"),
                        _pdfRow("Raza:", breedDisplay),
                        _pdfRow("Microchip:", result.microchipNumber ?? "No detectado", isBold: result.microchipNumber != null),
                        _pdfRow("Estado:", result.healthStatus.toUpperCase()),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Text("DIAGNÓSTICO Y TRATAMIENTO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue900)),
              pw.Divider(color: PdfColors.blue100),

              pw.SizedBox(height: 10),
              _pdfRow("Hallazgo:", result.diseaseName ?? 'Sano'),
              _pdfRow("Plan Terapéutico:", result.medicationName ?? 'N/A'),
              _pdfRow("Dosificación:", result.medicationDose ?? 'Consultar Veterinario', isBold: true),
              _pdfRow("Nutrición:", result.foodRecommendation ?? "Dieta habitual"),

              if (result.isPregnant == true) ...[
                 pw.SizedBox(height: 10),
                 pw.Container(
                   padding: const pw.EdgeInsets.all(5),
                   color: PdfColors.pink50,
                   child: _pdfRow("ESTADO GESTACIONAL:", result.gestationWeeks ?? "Confirmado", isBold: true),
                 )
              ],

              pw.SizedBox(height: 20),
              pw.Text("OBSERVACIONES TÉCNICAS:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(result.observations ?? "Analizado mediante visión artificial Vertex AI.", style: const pw.TextStyle(fontSize: 9)),

              pw.Spacer(),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
                child: pw.Text(
                  "AVISO: Este documento es un informe preliminar generado por IA. No sustituye el juicio clínico de un médico veterinario colegiado. Las dosis son sugerencias basadas en promedios.",
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/ScannerAnimal_${result.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Informe Veterinario - ${result.detectedBreed}');
  }

  pw.Widget _pdfRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal))),
        ],
      ),
    );
  }

  // --- Lógica de persistencia ---

  Future<void> _showObservationsAndSave() async {
    if (!mounted || widget.payload is! ScanResult) return;
    
    final resultText = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final controller = TextEditingController(text: _userObservations);
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Colors.white10)),
          title: const Text("Notas de Campo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Ej: Se observó mejoría tras la dosis...",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, ""), child: const Text("SALTAR", style: TextStyle(color: Colors.white38))),
            ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("GUARDAR")),
          ],
        );
      },
    );

    if (resultText != null) {
      _userObservations = resultText;
      await _saveFinalResult();
      if (mounted) context.go(AppRoutes.menu);
    }
  }

  Future<void> _saveFinalResult() async {
    final baseResult = widget.payload as ScanResult;
    final finalResult = baseResult.copyWith(observations: _userObservations);
    setState(() => _isSaving = true);
    try {
      await context.read<HistoryController>().add(finalResult);
      await context.read<AuthController>().useFreeScan();
    } catch (e) {
      debugPrint("Error guardando: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload is! ScanResult) return _buildGeneralErrorState();

    final result = widget.payload as ScanResult;
    final bool hasMicrochip = result.microchipNumber != null;
    final Color statusColor = result.healthStatus.toLowerCase().contains('buen') ? Colors.greenAccent : Colors.orangeAccent;

    return FarmBackgroundScaffold(
      title: 'ANÁLISIS COMPLETADO',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // TARJETA DE MICROCHIP (Nueva sección destacada)
            if (hasMicrochip)
              _buildMicrochipBanner(result.microchipNumber!),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
              ),
              child: Column(
                children: [
                  _buildHeader(result, statusColor),
                  const Divider(color: Colors.white10, height: 40),
                  
                  _buildResultRow('Identidad:', result.detectedBreed, Icons.info_outline),
                  _buildResultRow('Categoría:', result.detectedSpecies, Icons.pets),
                  
                  if (result.isPregnant == true)
                    _buildResultRow('Gestación:', result.gestationWeeks, Icons.auto_awesome, valueColor: Colors.pinkAccent),
                  
                  _buildResultRow('Hallazgo:', result.diseaseName, Icons.healing_outlined),
                  _buildResultRow('Prescripción:', result.medicationName, Icons.medication_liquid_rounded),
                  _buildResultRow('Dosis:', result.medicationDose, Icons.straighten_rounded, valueColor: Colors.greenAccent),
                  
                  const SizedBox(height: 25),
                  _buildNutritionalBox(result.foodRecommendation),
                  
                  const SizedBox(height: 35),
                  _buildActionButtons(result),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrochipBanner(String id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.nfc_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("MICROCHIP DETECTADO", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(id, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ScanResult result, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.analytics_outlined, color: color, size: 50),
        ),
        const SizedBox(height: 15),
        Text("ESTADO: ${result.healthStatus.toUpperCase()}", 
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildNutritionalBox(String? text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("RECOMENDACIÓN NUTRICIONAL", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
          child: Text(text ?? "Sin dieta específica.", style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ScanResult result) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () => _shareAsProfessionalPDF(result, result.detectedBreed),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text("COMPARTIR"),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _showObservationsAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text("FINALIZAR", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String? value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent.withOpacity(0.7), size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(value ?? 'N/A', style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildGeneralErrorState() {
    return FarmBackgroundScaffold(title: 'ERROR', child: Center(child: ElevatedButton(onPressed: () => context.pop(), child: const Text("REINTENTAR"))));
  }
}
