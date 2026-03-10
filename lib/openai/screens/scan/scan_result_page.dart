import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Asegúrate de tener provider
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/app/history/history_controller.dart'; // Importante para el guardado
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';
import 'package:scanneranimal/app_services/notification_service.dart';
import 'package:scanneranimal/openai/services/pdf_service.dart';

class ScanResultPage extends StatefulWidget {
  const ScanResultPage({super.key, this.payload});
  final dynamic payload;

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  final TextEditingController _notesController = TextEditingController();
  bool _showUrgentAlert = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.payload is ScanResult) {
        final result = widget.payload as ScanResult;
        // SINCRONIZADO: Ahora verifica tanto isHighRisk como isUrgent
        if (result.isHighRisk || result.isUrgent) {
          setState(() => _showUrgentAlert = true); 
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
                // SINCRONIZADO: Mostramos la tarjeta médica si hay datos de tratamiento
                if (result.medicationDosage != null || result.healthStatus.contains("PLAN MÉDICO")) 
                  _buildMedicationCard(result),
                const SizedBox(height: 15),
                if (result.preventionTips.isNotEmpty)
                  _buildInfoBox("🛡️ PROTOCOLO Y PREVENCIÓN", result.preventionTips, Colors.tealAccent),
                const SizedBox(height: 15),
                _buildInfoBox("🍎 NUTRICIÓN RECOMENDADA", 
                  [
                    result.suggestedFoodName ?? "Alimento sugerido", 
                    result.foodRecommendation ?? "Dieta balanceada estándar"
                  ], 
                  Colors.orangeAccent),

                const SizedBox(height: 20),
                _buildNotesField(),
                const SizedBox(height: 30),
                _buildActionButtons(result),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // SINCRONIZADO: Ventana Emergente para Alto Riesgo (Tumores/Cáncer)
          if (_showUrgentAlert && (result.isHighRisk || result.isUrgent)) 
            _buildProfessionalPopup(result.healthStatus),
        ],
      ),
    );
  }

  Widget _buildProfessionalPopup(String statusText) {
    return Container(
      color: Colors.black87, 
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.redAccent, width: 2),
          boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => setState(() => _showUrgentAlert = false),
              ),
            ),
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 60),
            const SizedBox(height: 15),
            const Text("ALERTA DE ALTO RIESGO", 
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
            const SizedBox(height: 15),
            Text(
              "SE REQUIERE ATENCIÓN VETERINARIA INMEDIATA.\n\nEL ANÁLISIS DETECTÓ CONDICIONES CRÍTICAS:\n${statusText.split('\n').first.toUpperCase()}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _showUrgentAlert = false),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

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

  Widget _buildActionButtons(ScanResult result) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () async { 
                  await PdfService.generateAndSharePdf(result); 
                },
                icon: const Icon(Icons.share_outlined, color: Colors.white70),
                label: const Text("COMPARTIR", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  // AGREGADO: Lógica de guardado real y redirección
                  final resultConNotas = result.copyWith(notes: _notesController.text);
                  
                  try {
                    await context.read<HistoryController>().saveScan(resultConNotas);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text("✅ Guardado. Redirigiendo al menú...")
                        ),
                      );
                      // REDIRECCIÓN AL MENÚ PRINCIPAL
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: Colors.red, content: Text("Error al guardar: $e")),
                    );
                  }
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
        ElevatedButton(
          onPressed: () async {
            await NotificationService.programarAlertasSegunResultado(result);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.blueAccent,
                  content: Text("🚀 Seguimiento IA activado (Cada 3 días)"),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3B8A),
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
          Text(r.healthStatus.split('\n').first.toUpperCase(), 
            textAlign: TextAlign.center,
            style: TextStyle(
              color: (r.isHighRisk || r.isUrgent) ? Colors.redAccent : Colors.white, 
              fontSize: 22, 
              fontWeight: FontWeight.w900
            )),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(ScanResult res) {
    return _buildCustomCard(
      title: "PLAN MÉDICO Y DOSIFICACIÓN",
      icon: Icons.medical_services_outlined,
      accentColor: Colors.greenAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Si el healthStatus contiene el plan detallado de la IA, lo mostramos
          if (res.healthStatus.contains("PLAN MÉDICO"))
            Text(
              res.healthStatus.split("PLAN MÉDICO / VACUNAS:").last.trim(),
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            )
          else ...[
            _dataRow("Dosis sugerida:", res.medicationDosage ?? "Ver detalles"),
            _dataRow("Vía de admin.:", res.medicationRoute ?? "Consultar"),
            _dataRow("Lugar de aplicación:", res.applicationSite ?? "General"),
          ],
        ],
      ),
    );
  }

  // --- El resto de los widgets de soporte (_buildPregnancyCard, _buildCustomCard, etc.) se mantienen igual que tu código original ---
  // ... (puedes mantener tus widgets _buildPregnancyCard, _dataRow, _buildInfoBox exactamente como los tenías)
}