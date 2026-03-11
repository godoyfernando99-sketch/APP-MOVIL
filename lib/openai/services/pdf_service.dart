import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:scanneranimal/app/history/scan_models.dart';

class PdfService {
  const PdfService();

  // Método estático para que funcione la llamada directa desde ResultPage
  static Future<void> generateAndSharePdf(ScanResult result) async {
    const service = PdfService();
    final bytes = await service.generateScanReport(result);
    await Printing.sharePdf(
      bytes: bytes, 
      filename: 'Reporte_${result.animalType}_${result.id.substring(0, 5)}.pdf'
    );
  }

  Future<Uint8List> generateScanReport(ScanResult result) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // --- ENCABEZADO ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("SCANNER ANIMAL",
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900)),
                    pw.Text("Reporte Clínico de Inteligencia Artificial",
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Fecha: ${result.timestamp.day}/${result.timestamp.month}/${result.timestamp.year}"),
                    pw.Text("ID Escaneo: ${result.id.substring(0, 8)}"),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 20),

            // --- INFORMACIÓN DEL ANIMAL ---
            pw.Text("INFORMACIÓN GENERAL",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              data: <List<String>>[
                ['Especie', 'Raza Detectada', 'Chip / ID'],
                [
                  result.animalType.toUpperCase(),
                  result.breed ?? 'No detectada',
                  result.microchipId ?? 'No provisto'
                ],
              ],
            ),
            pw.SizedBox(height: 25),

            // --- RESULTADOS MÉDICOS ---
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("DIAGNÓSTICO Y TRATAMIENTO",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          color: PdfColors.blue900)),
                  pw.SizedBox(height: 10),
                  // CORRECCIÓN: Se cambió 'result.isUrgent' por 'result.isHighRisk' (que es el nombre correcto en tu modelo)
                  _buildResultRow("Estado de Salud:", result.healthStatus.toUpperCase(), isBold: result.isHighRisk),
                  if (result.isPregnant)
                    _buildResultRow("Gestación:", "CONFIRMADA (${result.gestationWeeks})"),
                  pw.Divider(color: PdfColors.blue200, thickness: 0.5),
                  _buildResultRow("Dosis Sugerida:", result.medicationDosage ?? "N/A"),
                  _buildResultRow("Vía de Admin.:", result.medicationRoute ?? "N/A"),
                  _buildResultRow("Nutrición:", result.suggestedFoodName, isBold: true),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // --- NUEVO: NOTAS DE CAMPO ---
            pw.Text("NOTAS DE CAMPO Y OBSERVACIONES:", 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 5),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Text(
                result.notes ?? "Sin observaciones adicionales registradas.", 
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900)
              ),
            ),

            pw.Spacer(),

            // --- DISCLAIMER LEGAL ---
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.red900, width: 0.5),
                color: PdfColors.red50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    "DESCARGO DE RESPONSABILIDAD LEGAL",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        color: PdfColors.red900),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    "La información generada por Scanner Animal proviene de un análisis de Inteligencia Artificial y tiene fines exclusivamente informativos. Las dosis de medicamentos son sugerencias referenciales. Es OBLIGATORIO que un médico veterinario valide la prescripción antes de administrar cualquier tratamiento.",
                    textAlign: pw.TextAlign.justify,
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.black),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildResultRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 140, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
            child: pw.Text(value, 
              style: pw.TextStyle(
                fontSize: 10, 
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isBold && label.contains("Salud") ? PdfColors.red900 : PdfColors.black
              )
            )
          ),
        ],
      ),
    );
  }
}