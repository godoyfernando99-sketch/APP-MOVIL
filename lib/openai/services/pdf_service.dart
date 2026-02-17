import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:scanneranimal/app/history/scan_models.dart';

class PdfService {
  const PdfService();

  Future<Uint8List> generateScanReport(ScanResult result) async {
    final pdf = pw.Document();

    // Imagen de cabecera (Opcional: Si tienes un logo en assets)
    // final netImage = await spacing.networkImage('assets/icons/logo_app.png');

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
                    pw.Text("Fecha: ${result.createdAt.day}/${result.createdAt.month}/${result.createdAt.year}"),
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
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              data: <List<String>>[
                ['Categoría', 'Raza Detectada', 'Chip / ID'],
                [
                  result.animalCategory.toUpperCase(),
                  result.detectedBreed,
                  result.microchipNumber ?? 'No provisto'
                ],
              ],
            ),
            pw.SizedBox(height: 25),

            // --- RESULTADOS MÉDICOS (LA PARTE CLAVE) ---
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
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
                  _buildResultRow("Estado de Salud:", result.healthStatus.toUpperCase()),
                  _buildResultRow("Enfermedad:", result.diseaseName),
                  if (result.isPregnant)
                    _buildResultRow("Gestación:", "SÍ (${result.gestationWeeks})"),
                  pw.Divider(color: PdfColors.blue200),
                  _buildResultRow("Medicamento Sugerido:", result.medicationName),
                  _buildResultRow("Dosis Referencial:", result.medicationDose, isBold: true),
                  _buildResultRow("Dieta Recomendada:", result.foodRecommendation),
                ],
              ),
            ),

            pw.SizedBox(height: 20),
            pw.Text("OBSERVACIONES:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(result.observations, textAlign: pw.TextAlign.justify),

            pw.Spacer(),

            // --- DISCLAIMER LEGAL (PROTECCIÓN) ---
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
                    "La información generada por Scanner Animal proviene de un análisis de Inteligencia Artificial y tiene fines exclusivamente informativos. Las dosis de medicamentos (ml, cc, mg) son sugerencias referenciales basadas en promedios literarios. Es OBLIGATORIO que un médico veterinario verifique el peso exacto del animal y valide la prescripción antes de administrar cualquier tratamiento. El desarrollador no se hace responsable por el uso inadecuado de esta información.",
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

  // Widget auxiliar para las filas de resultados
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
                color: isBold ? PdfColors.green900 : PdfColors.black
              )
            )
          ),
        ],
      ),
    );
  }

  // Función para guardar y compartir el PDF
  Future<void> saveAndSharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
  }
}
