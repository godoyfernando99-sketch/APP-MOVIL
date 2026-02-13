import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

// --- IMPORTS RELATIVOS CORREGIDOS PARA GITHUB ---
import '../../../app/auth/auth_controller.dart'; 
import '../../../app/history/history_controller.dart';
import '../../../app/history/scan_models.dart';
import '../../../../data/animals.dart';
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
      // Descontamos el escaneo si no es PRO
      await authController.useFreeScan();
    } catch (e) {
      debugPrint("Error al finalizar: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload is String && widget.payload.toString().contains('VALIDATION_ERROR')) {
      return _buildErrorState();
    }

    if (widget.payload is! ScanResult) {
      return const Scaffold(body: Center(child: Text("No hay datos")));
    }

    final result = widget.payload as ScanResult;
    final manualAnimal = AnimalsCatalog.byId(result.animalId);
    final String displayBreed = result.detectedBreed ?? manualAnimal.name;
    final String health = result.healthStatus.toLowerCase();
    
    final Color statusColor = health.contains('buen') 
        ? Colors.greenAccent 
        : (health.contains('mal') || health.contains('crit') ? Colors.redAccent : Colors.orangeAccent);

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
              Icon(health.contains('buen') ? Icons.check_circle : Icons.warning, color: statusColor, size: 70),
              const SizedBox(height: 10),
              Text(result.healthStatus.toUpperCase(), 
                style: TextStyle(color: statusColor, fontSize: 24, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24, height: 40),
              
              _buildResultRow('Especie/Raza:', displayBreed, Icons.pets),
              
              if (result.isPregnant == true)
                _buildResultRow('Gestación:', '${result.pregnancyWeeks} Sem', Icons.favorite, valueColor: Colors.pinkAccent),
              
              _buildResultRow('Enfermedad:', result.diseaseName ?? 'Ninguna', Icons.bug_report),
              _buildResultRow('Dosis:', result.medicationDose ?? 'N/A', Icons.colorize),
              
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(result.foodRecommendation ?? "Sin recomendaciones adicionales",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 13)),
              ),
              
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareResult(result, displayBreed),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text("COMPARTIR"),
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
                        fontWeight: FontWeight.bold,
                      ),
                      child: _isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
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

  Widget _buildErrorState() {
    return FarmBackgroundScaffold(
      title: 'ERROR',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography, color: Colors.redAccent, size: 80),
            const SizedBox(height: 16),
            const Text("No se detectó un animal", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Intenta tomar la foto más cerca.", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.pop(), child: const Text("REINTENTAR"))
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white60)),
          const Spacer(),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
