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

  /// Genera un PDF profesional con la foto, datos del diagnóstico y Disclaimer
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
              // Encabezado Profesional
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ScannerAnimal IA", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Text("FECHA: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}"),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 20),

              // Ficha del Animal
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (animalImage != null)
                    pw.Container(
                      width: 130,
                      height: 130,
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                      child: pw.Image(animalImage, fit: pw.BoxFit.cover),
                    ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("IDENTIFICACIÓN", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.SizedBox(height: 5),
                        pw.Text("Especie: ${result.detectedSpecies ?? result.animalCategory}"),
                        pw.Text("Raza: $breedDisplay"),
                        pw.Text("Estado: ${result.healthStatus.toUpperCase()}"),
                        if (result.isPregnant == true)
                          pw.Text("Gestación: ${result.gestationWeeks}", style: pw.TextStyle(color: PdfColors.pink700, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 25),
              pw.Text("TRATAMIENTO Y PRESCRIPCIÓN SUGERIDA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue900)),
              pw.Divider(color: PdfColors.blue100),

              // Detalles Médicos con los nuevos campos
              pw.SizedBox(height: 10),
              _pdfRow("Diagnóstico:", result.diseaseName ?? 'Ninguna detectada'),
              _pdfRow("Medicamento:", result.medicationName ?? 'N/A'),
              _pdfRow("Dosis Sugerida:", result.medicationDose ?? 'N/A', isBold: true),
              _pdfRow("Alimentación:", result.foodRecommendation ?? "Sin dieta específica"),

              pw.SizedBox(height: 20),
              pw.Text("NOTAS ADICIONALES:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(_userObservations ?? result.observations ?? "Sin observaciones."),

              pw.Spacer(),
              
              // DISCLAIMER LEGAL OBLIGATORIO
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  border: pw.Border.all(color: PdfColors.red900, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))
                ),
                child: pw.Column(
                  children: [
                    pw.Text("DESCARGO DE RESPONSABILIDAD LEGAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red900)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Este reporte es una guía informativa generada por IA. Las dosis y medicamentos mencionados son sugerencias referenciales. Es OBLIGATORIO consultar a un veterinario antes de cualquier administración. El usuario asume toda la responsabilidad del uso de esta información.",
                      textAlign: pw.TextAlign.justify,
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Reporte_${result.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte Veterinario IA - ScannerAnimal');
  }

  pw.Widget _pdfRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal))),
        ],
      ),
    );
  }

  // --- MÉTODOS DE GUARDADO Y DIÁLOGOS (Se mantienen igual) ---

  Future<void> _showObservationsAndSave() async {
    if (!mounted || widget.payload is! ScanResult) return;
    
    final resultText = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final controller = TextEditingController(text: _userObservations);
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Notas Finales", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("¿Deseas agregar algún detalle extra sobre el animal?", 
                style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Ej: Se aplicó la inyección...",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ""), 
              child: const Text("SIN NOTAS", style: TextStyle(color: Colors.white54))
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text), 
              child: const Text("GUARDAR")
            ),
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
    if (widget.payload is! ScanResult) return;
    final baseResult = widget.payload as ScanResult;
    final finalResult = baseResult.copyWith(observations: _userObservations);
    
    final historyController = context.read<HistoryController>();
    final authController = context.read<AuthController>();

    setState(() => _isSaving = true);
    try {
      await historyController.add(finalResult);
      await authController.useFreeScan();
    } catch (e) {
      debugPrint("Error al finalizar: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload is String && widget.payload.toString().contains('no es una imagen de un animal')) {
      return _buildErrorState(widget.payload.toString());
    }

    if (widget.payload is! ScanResult) {
      return _buildGeneralErrorState();
    }

    final result = widget.payload as ScanResult;
    final String health = (result.healthStatus).toString().toLowerCase();
    final String displayBreed = result.detectedBreed ?? "No identificada";
    
    Color statusColor = Colors.orangeAccent;
    IconData statusIcon = Icons.warning;

    if (health.contains('buen')) {
      statusColor = Colors.greenAccent;
      statusIcon = Icons.check_circle;
    } else if (health.contains('mal') || health.contains('crit') || health.contains('enfer')) {
      statusColor = Colors.redAccent;
      statusIcon = Icons.error;
    }

    return FarmBackgroundScaffold(
      title: 'RESULTADO IA',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: statusColor.withOpacity(0.4), width: 2),
          ),
          child: Column(
            children: [
              Icon(statusIcon, color: statusColor, size: 70),
              const SizedBox(height: 10),
              Text(result.healthStatus.toUpperCase(), 
                style: TextStyle(color: statusColor, fontSize: 24, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24, height: 40),
              
              _buildResultRow('Especie:', result.detectedSpecies ?? 'Animal', Icons.pets),
              _buildResultRow('Raza:', displayBreed, Icons.category),
              
              if (result.isPregnant == true)
                _buildResultRow('Gestación:', result.gestationWeeks ?? 'Detectada', Icons.favorite, valueColor: Colors.pinkAccent),
              
              _buildResultRow('Enfermedad:', result.diseaseName ?? 'Ninguna', Icons.bug_report),
              _buildResultRow('Medicamento:', result.medicationName ?? 'N/A', Icons.medication),
              _buildResultRow('Dosis:', result.medicationDose ?? 'N/A', Icons.colorize, valueColor: Colors.greenAccent),
              
              const SizedBox(height: 20),
              
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("RECOMENDACIÓN NUTRICIONAL:", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.foodRecommendation ?? "Sin recomendaciones adicionales",
                  style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 13, height: 1.4)
                ),
              ),
              
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareAsProfessionalPDF(result, displayBreed),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text("PDF / WHATSAPP"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _showObservationsAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor.withOpacity(0.8),
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: _isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                        : const Text("FINALIZAR"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white60)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralErrorState() {
    return FarmBackgroundScaffold(
      title: 'ERROR',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 80),
            const SizedBox(height: 16),
            const Text("Error de interpretación", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.pop(), child: const Text("REINTENTAR"))
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return FarmBackgroundScaffold(
      title: 'AVISO',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography, color: Colors.redAccent, size: 80),
            const SizedBox(height: 16),
            const Text("Imagen no válida", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.pop(), child: const Text("VOLVER A INTENTAR"))
          ],
        ),
      ),
    );
  }
}
