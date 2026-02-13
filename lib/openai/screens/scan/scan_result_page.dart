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
Observaciones: ${_userObservations ?? 'Sin notas'}
''';
    Share.share(textToShare);
  }

  Future<void> _askForObservations() async {
    if (!mounted || widget.payload is! ScanResult) return;
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Observaciones", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: "Ej: No ha comido..."),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("SALTAR")),
            ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("GUARDAR")),
          ],
        );
      },
    );
    setState(() => _userObservations = result);
    _saveFinalResult();
  }

  Future<void> _saveFinalResult() async {
    if (!mounted || widget.payload is! ScanResult) return;
    final baseResult = widget.payload as ScanResult;
    final finalResult = baseResult.copyWith(observations: _userObservations);
    setState(() => _isSaving = true);
    try {
      await context.read<HistoryController>().add(finalResult);
      setState(() { _isSaved = true; _isSaving = false; });
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload is! ScanResult) return const Center(child: Text("Error de carga"));
    final result = widget.payload as ScanResult;
    final animal = AnimalsCatalog.byId(result.animalId);
    final Color statusColor = result.healthStatus == 'buena' ? Colors.greenAccent : Colors.orangeAccent;

    return FarmBackgroundScaffold(
      title: 'RESULTADO',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildResultRow('Especie:', animal.name, Icons.pets),
              _buildResultRow('Salud:', result.healthStatus, Icons.favorite, valueColor: statusColor),
              if (result.diseaseName != null) _buildResultRow('Enfermedad:', result.diseaseName!, Icons.bug_report),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => context.go(AppRoutes.menu), child: const Text("VOLVER")),
            ],
          ),
        ),
      ),
    );
  }

  // ESTE ES EL MÉTODO QUE TE FALTABA
  Widget _buildResultRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
