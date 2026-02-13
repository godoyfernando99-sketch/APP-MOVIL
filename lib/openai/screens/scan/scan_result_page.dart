Aquí tienes el código de ScanResultPage corregido y optimizado. He añadido el manejo de errores para el caso de "No es un animal" que definimos en el servicio de IA y he corregido la lógica de visualización para que sea más limpia.

Dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:scanneranimal/app/auth/auth_controller.dart'; 
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

  void _shareResult(ScanResult result, String breedDisplay) {
    final String textToShare = '''
🐾 *REPORTE VETERINARIO IA* 🐾
Especie/Raza: $breedDisplay
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

  Future<void> _saveFinalResult() async {
    final baseResult = widget.payload as ScanResult;
    final finalResult = baseResult.copyWith(observations: _userObservations);
    
    final historyController = context.read<HistoryController>();
    final authController = context.read<AuthController>();

    setState(() => _isSaving = true);
    try {
      await historyController.add(finalResult);
      // El método useFreeScan ya debería manejar si el usuario es PRO o no internamente
      await authController.useFreeScan();
    } catch (e) {
      debugPrint("Error al finalizar el proceso: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Manejo de error si la IA dice que no es un animal
    if (widget.payload is String && widget.payload.toString().contains('VALIDATION_ERROR')) {
      return FarmBackgroundScaffold(
        title: 'ERROR DE ESCANEO',
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent)
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "¡OBJETO NO IDENTIFICADO!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "La IA no ha detectado un animal en la fotografía. Por favor, asegúrate de que el animal sea claramente visible.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text("REINTENTAR"),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (widget.payload is! ScanResult) {
      return const Scaffold(body: Center(child: Text("No hay datos disponibles")));
    }

    final result = widget.payload as ScanResult;
    final manualAnimal = AnimalsCatalog.byId(result.animalId);
    final String displayBreed = result.detectedBreed ?? manualAnimal.name;
    
    // Colores dinámicos según el estado de salud
    final String health = result.healthStatus.toLowerCase();
    final Color statusColor = health.contains('buen') 
        ? Colors.greenAccent 
        : (health.contains('critico') || health.contains('mal') ? Colors.redAccent : Colors.orangeAccent);

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
                    health.contains('buen') ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: statusColor, size: 70
                  ),
                  const SizedBox(height: 10),
                  Text(result.healthStatus.toUpperCase(), 
                    style: TextStyle(color: statusColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  
                  const Divider(height: 40, color: Colors.white24),

                  _buildResultRow(
                    'Raza / Especie:', 
                    displayBreed, 
                    result.detectedBreed != null ? Icons.auto_awesome : Icons.pets, 
                    valueColor: result.detectedBreed != null ? Colors.amberAccent : Colors.white
                  ),

                  if (result.isPregnant == true)
                    _buildResultRow('GESTACIÓN:', '${result.pregnancyWeeks} Semanas', Icons.auto_awesome, 
                      valueColor: Colors.blueAccent, isHighlight: true),

                  if (result.diseaseName != null && result.diseaseName!.toLowerCase() != 'ninguna')
                    _buildResultRow('Enfermedad:', result.diseaseName!, Icons.bug_report, valueColor: Colors.redAccent),

                  _buildResultRow('Medicamento:', result.medicationName ?? 'No requerido', Icons.medication),
                  _buildResultRow('Dosis:', result.medicationDose ?? 'N/A', Icons.colorize, valueColor: Colors.yellowAccent),

                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("RECOMENDACIÓN:", 
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 5),
                  Text(result.foodRecommendation ?? "Consultar veterinario para más detalles.",
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),

                  const SizedBox(height: 35),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareResult(result, displayBreed),
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
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                              )
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
