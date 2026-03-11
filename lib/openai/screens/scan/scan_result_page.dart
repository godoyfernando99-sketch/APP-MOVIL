import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/app/history/history_controller.dart';
import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/openai/services/pdf_service.dart';
import 'package:scanneranimal/app_services/notification_service.dart';

class ScanResultPage extends StatefulWidget {
  final dynamic payload;
  const ScanResultPage({super.key, this.payload});

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  final TextEditingController _notesController = TextEditingController();
  bool _showUrgentAlert = false;

  @override
  void initState() {
    super.initState();
    if (widget.payload is ScanResult) {
      final res = widget.payload as ScanResult;
      // Activa la alerta si es de alto riesgo
      if (res.isHighRisk) setState(() => _showUrgentAlert = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.payload as ScanResult;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(res.timestamp);

    return Scaffold(
      appBar: AppBar(title: const Text("RESULTADOS DEL ANÁLISIS")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Fecha del Escaneo: $dateStr", style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),

                // --- SECCIÓN: INFORMACIÓN BÁSICA ---
                _buildInfoItem("Tipo de Animal", res.animalType),
                _buildInfoItem("Raza/Especie", res.breed ?? "Mestizo"),
                // Muestra el ID del Microchip si existe
                if (res.microchipId != null && res.microchipId!.isNotEmpty)
                  _buildInfoItem("ID de Microchip", res.microchipId!),

                // --- SECCIÓN: GESTACIÓN (Si aplica) ---
                if (res.isPregnant) ...[
                  const SizedBox(height: 15),
                  const Text("📦 DETALLES DE GESTACIÓN", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                  _buildInfoItem("Estado", "Positivo"),
                  _buildInfoItem("Tiempo", res.gestationWeeks ?? "N/A"),
                  _buildInfoItem("Crías Estimadas", res.offspringCount ?? "Pendiente"),
                  _buildInfoItem("Días para el Parto", "${res.daysUntilDelivery ?? 0} días"),
                ],

                const SizedBox(height: 15),
                const Text("🩺 INFORME VETERINARIO DETALLADO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),

                // --- SECCIÓN: SALUD Y TRATAMIENTO (Usa campos de ScanResult) ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(res.healthStatus, style: const TextStyle(fontSize: 15)),
                      const Divider(color: Colors.grey),
                      const Text("PLAN DE ADMINISTRACIÓN:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 5),

                      // CAMPOS SOLICITADOS APLICADOS
                      _buildMedicineDetail("Dosis recomendada", res.medicationDosage),
                      _buildMedicineDetail("Vía de administración", res.medicationRoute),
                      _buildMedicineDetail("Lugar de aplicación", res.applicationSite),
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                _buildInfoItem("Alimento Sugerido", res.suggestedFoodName),
                if (res.foodRecommendation != null)
                  _buildInfoItem("Guía Nutricional", res.foodRecommendation!),

                const SizedBox(height: 20),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: "MIS ANOTACIONES ADICIONALES",
                    border: OutlineInputBorder(),
                    hintText: "Ej: El animal presentó fiebre por la mañana..."
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 25),
                _buildActionButtons(res),
              ],
            ),
          ),

          // Ventana emergente de ALERTA URGENTE
          if (_showUrgentAlert) _buildHighRiskPopup(res),
        ],
      ),
    );
  }

  // Widget para detalles de medicina (Dosis, Vía, Lugar)
  Widget _buildMedicineDetail(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text("• $label: $value", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ScanResult res) {
    return Column(
      children: [
        // BOTÓN DE SEGUIMIENTO VETERINARIO
        ElevatedButton.icon(
          onPressed: () {
            NotificationService.programarAlertasSegunResultado(res);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("🔔 Seguimiento y recordatorios activados"))
            );
          },
          icon: const Icon(Icons.alarm_on_rounded),
          label: const Text("ACTIVAR SEGUIMIENTO VETERINARIO"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: Colors.white
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // BOTÓN PDF - CORREGIDO PARA EVITAR "MEMBER NOT FOUND"
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => PdfService.generateAndSharePdf(res),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text("COMPARTIR PDF"),
              ),
            ),
            const SizedBox(width: 10),
            // BOTÓN GUARDAR
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final finalResult = res.copyWith(notes: _notesController.text);
                  await context.read<HistoryController>().saveScan(finalResult);
                  await context.read<AuthController>().useFreeScan();
                  if (mounted) {
                    // Navegación limpia al Menú Principal
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
                child: const Text("GUARDAR Y SALIR"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighRiskPopup(ScanResult res) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text("ALTO RIESGO", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Se han detectado signos de una afección grave (posible tumor o infección severa). Se recomienda acudir al veterinario de inmediato.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => setState(() => _showUrgentAlert = false),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("HE LEÍDO LA ADVERTENCIA", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}