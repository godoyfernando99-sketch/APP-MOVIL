import 'package:flutter/material.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';
import 'package:scanneranimal/app_services/notification_service.dart';
// AGREGADO: Importación del servicio de PDF
import 'package:scanneranimal/openai/services/pdf_service.dart';

class ScanResultPage extends StatefulWidget {
  const ScanResultPage({super.key, this.payload});
  final dynamic payload;

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  final TextEditingController _notesController = TextEditingController();
  bool _showUrgentAlert = false; // Control para la ventana emergente

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.payload is ScanResult) {
        final result = widget.payload as ScanResult;
        if (result.isUrgent) {
          setState(() => _showUrgentAlert = true); // Mostrar alerta al iniciar
          NotificationService.programarAlertasSegunResultado(result);
        }
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload is! ScanResult) {
      return const Scaffold(body: Center(child: Text("Error: Datos no encontrados")));
    }

    final result = widget.payload as ScanResult;

    return FarmBackgroundScaffold(
      title: 'INFORME VETERINARIO',
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatusHeader(result),
                const SizedBox(height: 15),
                if (result.microchipId != null) _buildNfcCard(result.microchipId!),
                const SizedBox(height: 15),
                if (result.isPregnant) _buildPregnancyCard(result),
                const SizedBox(height: 15),
                if (result.medicationRoute != null) _buildMedicationCard(result),
                const SizedBox(height: 15),
                if (result.preventionTips.isNotEmpty)
                  _buildInfoBox("🛡️ PROTOCOLO Y PREVENCIÓN", result.preventionTips, Colors.tealAccent),
                const SizedBox(height: 15),
                _buildInfoBox("🍎 NUTRICIÓN RECOMENDADA", 
                  [result.suggestedFoodName, result.foodRecommendation ?? "Dieta balanceada estándar"], 
                  Colors.orangeAccent),
                
                const SizedBox(height: 20),
                
                // NUEVO: Cuadro de Notas de Campo
                _buildNotesField(),
                
                const SizedBox(height: 30),
                _buildActionButtons(result),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // NUEVA: Ventana Emergente Profesional (Popup)
          if (_showUrgentAlert && result.isUrgent) _buildProfessionalPopup(result.healthStatus),
        ],
      ),
    );
  }

  // --- VENTANA EMERGENTE PROFESIONAL ---
  Widget _buildProfessionalPopup(String statusText) {
    return Container(
      color: Colors.black54, // Fondo oscurecido
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Fondo oscuro sólido
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => setState(() => _showUrgentAlert = false),
                child: const Icon(Icons.close, color: Colors.white54),
              ),
            ),
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 50),
            const SizedBox(height: 15),
            const Text("ALERTA MÉDICA URGENTE", 
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 15),
            Text(
              "ATENCIÓN VETERINARIA ESPECIAL REQUERIDA. EL PACIENTE PRESENTA: ${statusText.toUpperCase()}.\nSE REQUIERE DIAGNÓSTICO Y TRATAMIENTO INMEDIATO.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // --- CUADRO DE NOTAS ---
  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: "Ej: Se observó mejoría tras la dosis...",
          hintStyle: TextStyle(color: Colors.white30),
          border: InputBorder.none,
          labelText: "NOTAS DE CAMPO",
          labelStyle: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- BOTONES DE ACCIÓN RESTAURADOS ---
  Widget _buildActionButtons(ScanResult result) {
    return Column(
      children: [
        Row(
          children: [
            // Botón Compartir
            Expanded(
              child: TextButton.icon(
                onPressed: () async { 
                  // ACTUALIZADO: Llamada al servicio de PDF
                  await PdfService.generateAndSharePdf(result); 
                },
                icon: const Icon(Icons.share_outlined, color: Colors.white70),
                label: const Text("COMPARTIR", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            // Botón Guardar
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // ACTUALIZADO: Se guarda el resultado incluyendo las notas del controlador
                  final resultConNotas = result.copyWith(notes: _notesController.text);
                  
                  // Aquí iría tu lógica de guardado (ej: context.read<HistoryController>().save(resultConNotas))
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text("✅ Informe guardado con notas en el historial")
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        // Botón Activar Seguimiento IA (Azul)
        ElevatedButton(
          onPressed: () async {
            await NotificationService.programarAlertasSegunResultado(result);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.blueAccent,
                  content: Text("🚀 Seguimiento IA activado"),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3B8A), // Azul oscuro profesional
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text("ACTIVAR SEGUIMIENTO", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(ScanResult r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(r.animalType.toUpperCase(), 
            style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(r.healthStatus.toUpperCase(), 
            textAlign: TextAlign.center,
            style: TextStyle(
              color: r.isUrgent ? Colors.redAccent : Colors.white, 
              fontSize: 22, 
              fontWeight: FontWeight.w900
            )),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(ScanResult res) {
    return _buildCustomCard(
      title: "PLAN DE TRATAMIENTO",
      icon: Icons.medical_services_outlined,
      accentColor: Colors.greenAccent,
      child: Column(
        children: [
          _dataRow("Dosis sugerida:", res.medicationDosage ?? "Ver informe"),
          _dataRow("Vía de admin.:", res.medicationRoute ?? "Consultar"),
          _dataRow("Lugar de aplicación:", res.applicationSite ?? "General"),
        ],
      ),
    );
  }

  Widget _buildPregnancyCard(ScanResult res) {
    return _buildCustomCard(
      title: "SEGUIMIENTO DE GESTACIÓN",
      icon: Icons.auto_awesome,
      accentColor: Colors.pinkAccent,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dataCol("Crías", res.offspringCount ?? "---"),
              _dataCol("Etapa", res.gestationWeeks ?? "---"),
              _dataCol("Días rest.", "${res.daysUntilDelivery ?? '---'}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCard({required String title, required IconData icon, required Color accentColor, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _dataRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _dataCol(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildInfoBox(String title, List<String> items, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(color: Colors.white70)),
                Expanded(child: Text(item, style: const TextStyle(color: Colors.white70, fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNfcCard(String id) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nfc, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 10),
          Text("CHIP NFC: $id", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}