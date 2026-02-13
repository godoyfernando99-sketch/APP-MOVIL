import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:scanneranimal/app/auth/auth_controller.dart'; // IMPORTANTE: Para descontar escaneos
import 'package:scanneranimal/app/history/history_controller.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class ScanResultPage extends StatefulWidget {
  const ScanResultPage({super.key, this.payload});
  final dynamic payload;

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  bool _isSaving = false;
  String? _userObservations;

  void _shareResult(ScanResult result, dynamic animal) {
    final String textToShare = '''
🐾 *REPORTE VETERINARIO IA* 🐾
Especie: ${animal.name}
Salud: ${result.healthStatus.toUpperCase()}
Enfermedad: ${result.diseaseName ?? 'Ninguna'}
Medicamento: ${result.medicationName ?? 'N/A'}
Dosis: ${result.medicationDose ?? 'N/A'}
Embarazo: ${result.isPregnant == true ? 'SÍ (${result.pregnancyWeeks} sem)' : 'No detectado'}
Observaciones: ${_userObservations ?? 'Sin notas adicionales'}
    ''';
    Share.share(textToShare);
  }

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
              const Text("¿Deseas agregar algún detalle extra sobre el animal antes de guardar?", 
                style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Ej: Se aplicó la inyección correctamente...",
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
              child: const Text("GUARDAR Y SALIR")
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

  // MÉTODO ACTUALIZADO: Guarda historial y resta escaneo
  Future<void> _saveFinalResult() async {
    final auth = context.read<AuthController>();
    final history = context.read<HistoryController>();
    
    final baseResult = widget.payload as ScanResult;
    final finalResult = baseResult.copyWith(observations: _userObservations);
    
    setState(() => _isSaving = true);
    try {
      // 1. Guardar en el historial de Firebase
      await history.add(finalResult);
      
      // 2. DESCONTAR ESCANEO DE BIENVENIDA (Lógica Pro vs Free dentro del controlador)
      await auth.useFreeScan();
      
    } catch (e) {
      debugPrint("Error al finalizar el proceso: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload is! ScanResult) {
      return const Scaffold(body: Center(child: Text("No hay datos")));
    }

    final result = widget.payload as ScanResult;
    final animal = AnimalsCatalog.byId(result.animalId);
    
    final Color statusColor = result.healthStatus.toLowerCase() == 'buena' 
        ? Colors.greenAccent 
        : (result.healthStatus.toLowerCase() == 'mala' ? Colors.redAccent : Colors.orangeAccent);

    return FarmBackgroundScaffold(
      title: 'RESULTADO DEL ESCANEO',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: statusColor.withOpacity(0.4), width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    result.healthStatus.toLowerCase() == 'buena' ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: statusColor, size: 70
                  ),
                  const SizedBox(height: 10),
                  Text(result.healthStatus.toUpperCase(), 
                    style: TextStyle(color: statusColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  
                  const Divider(height: 40, color: Colors.white24),

                  _buildResultRow('Especie:', animal.name, Icons.pets),

                  if (result.isPregnant == true)
                    _buildResultRow('GESTACIÓN:', '${result.pregnancyWeeks} Semanas', Icons.auto_awesome, 
                      valueColor: Colors.blueAccent, isHighlight: true),

                  if (result.diseaseName != null && result.diseaseName != 'Ninguna')
                    _buildResultRow('Enfermedad:', result.diseaseName!, Icons.bug_report, valueColor: Colors.redAccent),

                  _buildResultRow('Medicamento:', result.medicationName ?? 'No requerido', Icons.medication),
                  _buildResultRow('Dosis:', result.medicationDose ?? 'N/A', Icons.colorize, valueColor: Colors.yellowAccent),

                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("CUIDADOS Y ALIMENTACIÓN:", 
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 5),
                  Text(result.foodRecommendation ?? "Consultar veterinario.",
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),

                  const SizedBox(height: 35),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareResult(result, animal),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text("COMPARTIR"),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _showObservationsAndSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(vertical: 15)
                          ),
                          child: _isSaving 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text("FINALIZAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, {Color? valueColor, bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: isHighlight ? const EdgeInsets.all(10) : null,
      decoration: isHighlight ? BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)) : null,
      child: Row(
        children: [
          Icon(icon, color: valueColor ?? Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
          const Spacer(),
          Expanded(
            child: Text(value, textAlign: TextAlign.end,
              style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
