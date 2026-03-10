import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/app/history/history_controller.dart';
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
        // DETECCIÓN DE ALTO RIESGO O URGENCIA
        if (result.isHighRisk == true || result.isUrgent == true) {
          setState(() => _showUrgentAlert = true); 
          NotificationService.programarAlertasSegunResultado(result);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload is! ScanResult) return const Scaffold(body: Center(child: Text("Error")));
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
                if (result.isPregnant) _buildPregnancyCard(result),
                const SizedBox(height: 15),
                _buildMedicationCard(result),
                const SizedBox(height: 15),
                _buildNotesField(),
                const SizedBox(height: 30),
                _buildActionButtons(result),
              ],
            ),
          ),
          if (_showUrgentAlert) _buildProfessionalPopup(result.healthStatus),
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 50),
            const SizedBox(height: 15),
            const Text("🚨 ALTO RIESGO DETECTADO", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text(statusText.split('\n').first, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => setState(() => _showUrgentAlert = false), child: const Text("ENTENDIDO")),
          ],
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
              child: ElevatedButton(
                onPressed: () async {
                  // GUARDADO Y REDIRECCIÓN
                  final finalResult = result.copyWith(notes: _notesController.text);
                  await context.read<HistoryController>().saveScan(finalResult);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Guardado exitosamente")));
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                child: const Text("GUARDAR"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ... (Los demás widgets decorativos como _buildStatusHeader o _buildMedicationCard se mantienen)
  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: const InputDecoration(labelText: "NOTAS DE CAMPO", hintText: "Escribe observaciones..."),
    );
  }

  Widget _buildMedicationCard(ScanResult res) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
      child: Text(res.healthStatus, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  Widget _buildStatusHeader(ScanResult r) {
    return Text(r.healthStatus.split('\n').first.toUpperCase(), 
      textAlign: TextAlign.center, 
      style: TextStyle(color: (r.isHighRisk) ? Colors.redAccent : Colors.white, fontSize: 20, fontWeight: FontWeight.bold));
  }

  Widget _buildPregnancyCard(ScanResult res) {
    return Container(child: Text("Gestación: ${res.offspringCount} crías", style: TextStyle(color: Colors.pinkAccent)));
  }
}