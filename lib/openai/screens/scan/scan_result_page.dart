import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _isSaved = false;
  bool _isSaving = false;
  String? _userObservations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askForObservations());
  }

  void _shareResult(ScanResult result, dynamic animal) {
    final String textToShare = '''
🐾 *REPORTE VETERINARIO IA* 🐾
Especie: ${animal.name}
Salud: ${result.healthStatus.toUpperCase()}
Enfermedad: ${result.diseaseName ?? 'Ninguna'}
Medicamento: ${result.medicationName ?? 'N/A'}
Dosis: ${result.medicationDose ?? 'N/A'}
Embarazo: ${result.isPregnant == true ? 'SÍ (${result.pregnancyWeeks} sem)' : 'No detectado'}
Notas: ${_userObservations ?? 'Sin notas'}
    ''';
    Share.share(textToShare);
  }

  Future<void> _askForObservations() async {
    if (!mounted || widget.payload is! ScanResult) return;
    
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Observaciones del Dueño", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Ej: No ha comido bien hoy...",
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("SALTAR", style: TextStyle(color: Colors.white54))
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text), 
              child: const Text("GUARDAR NOTA")
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => _userObservations = result);
    }
    _saveFinalResult();
  }

  Future<void> _saveFinalResult() async {
    if (!mounted || widget.payload is! ScanResult) return;
    final baseResult = widget.payload as ScanResult;
    final finalResult = baseResult.copyWith(observations: _userObservations);
    
    setState(() => _isSaving = true);
    try {
      await context.read<HistoryController>().add(finalResult);
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload is! ScanResult) {
      return const Scaffold(body: Center(child: Text("No se recibieron datos")));
    }

    final result = widget.payload as ScanResult;
    final animal = AnimalsCatalog.byId(result.animalId);
    
    // Lógica de colores por estado
    Color statusColor;
    if (result.healthStatus.toLowerCase() == 'buena') {
      statusColor = Colors.greenAccent;
    } else if (result.healthStatus.toLowerCase() == 'mala') {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.orangeAccent;
    }

    return FarmBackgroundScaffold(
      title: 'INFORME DE SALUD',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    result.healthStatus.toLowerCase() == 'buena' ? Icons.check_circle : Icons.warning_amber_rounded, 
                    color: statusColor, 
                    size: 60
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.healthStatus.toUpperCase(), 
                    style: TextStyle(color: statusColor, fontSize: 22, fontWeight: FontWeight.bold)
                  ),
                  const Divider(height: 30, color: Colors.white24),
                  
                  _buildResultRow('Animal:', animal.name, Icons.pets),
                  
                  if (result.isPregnant == true)
                    _buildResultRow(
                      'GESTACIÓN:', 
                      '${result.pregnancyWeeks} Semanas', 
                      Icons.auto_awesome, 
                      valueColor: Colors.blueAccent, // Color azul para resaltar embarazo
                      isHighlight: true
                    ),

                  if (result.diseaseName != null && result.diseaseName != 'Ninguna')
                    _buildResultRow('Enfermedad:', result.diseaseName!, Icons.bug_report, valueColor: Colors.redAccent),

                  if (result.medicationName != null)
                    _buildResultRow('Tratamiento:', result.medicationName!, Icons.medication_liquid),

                  if (result.medicationDose != null)
                    _buildResultRow('Dosis/Inyección:', result.medicationDose!, Icons.colorize, valueColor: Colors.yellowAccent),

                  const Divider(height: 30, color: Colors.white24),
                  
                  // SECCIÓN DE RECOMENDACIONES
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("RECOMENDACIONES VETERINARIAS:", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.foodRecommendation ?? "Sin recomendaciones específicas.",
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
                  ),

                  const SizedBox(height: 30),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareResult(result, animal),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text("REPORTAR"),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.menu),
                          style: ElevatedButton.styleFrom(backgroundColor: statusColor.withOpacity(0.7)),
                          child: const Text("FINALIZAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
      padding: isHighlight ? const EdgeInsets.all(8) : null,
      decoration: isHighlight ? BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)) : null
