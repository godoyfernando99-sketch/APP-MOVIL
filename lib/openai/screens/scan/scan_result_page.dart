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
    // Al cargar la página, pedimos observaciones opcionales
    WidgetsBinding.instance.addPostFrameCallback((_) => _askForObservations());
  }

  // Método para compartir el reporte
  void _shareResult(ScanResult result, dynamic animal) {
    final String textToShare = '''
🐾 *REPORTE VETERINARIO IA* 🐾
Especie: ${animal.name}
Estado de Salud: ${result.healthStatus.toUpperCase()}
Enfermedad detectada: ${result.diseaseName ?? 'Ninguna'}
Observaciones: ${_userObservations ?? 'Sin notas adicionales'}
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
          title: const Text("Observaciones", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Ej: El animal presenta poco apetito...",
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
    final Color statusColor = result.healthStatus.toLowerCase() == 'buena' 
        ? Colors.greenAccent 
        : Colors.orangeAccent;

    return FarmBackgroundScaffold(
      title: 'ANÁLISIS COMPLETADO',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 60),
                  const SizedBox(height: 16),
                  const Text("Análisis de IA Finalizado", 
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 32, color: Colors.white24),
                  
                  _buildResultRow('Especie:', animal.name, Icons.pets),
                  _buildResultRow('Salud:', result.healthStatus, Icons.favorite, valueColor: statusColor),
                  
                  if (result.diseaseName != null)
                    _buildResultRow('Diagnóstico:', result.diseaseName!, Icons.medication),
                  
                  if (result.fractureDescription != null)
                    _buildResultRow('Lesión:', result.fractureDescription!, Icons.healing),

                  if (result.pregnancyWeeks != null)
                    _buildResultRow('Gestación:', '${result.pregnancyWeeks} Semanas', Icons.child_care, valueColor: Colors.pinkAccent),

                  const SizedBox(height: 24),
                  
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.menu),
                          child: const Text("FINALIZAR"),
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

  // MÉTODO QUE FALTABA Y CAUSABA EL ERROR
  Widget _buildResultRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          const Spacer(),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
