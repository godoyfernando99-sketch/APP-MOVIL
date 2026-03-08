import 'package:flutter/material.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';
import 'package:scanneranimal/app_services/notification_service.dart';

class ScanResultPage extends StatefulWidget {
  const ScanResultPage({super.key, this.payload});
  final dynamic payload;

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usamos el cast seguro para evitar errores de dynamic
      if (widget.payload is ScanResult) {
        final result = widget.payload as ScanResult;
        if (result.isUrgent) {
          NotificationService.programarAlertasSegunResultado(result);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Verificación de seguridad del objeto recibido
    if (widget.payload is! ScanResult) {
      return const Scaffold(body: Center(child: Text("Error: Datos no encontrados")));
    }
    
    final result = widget.payload as ScanResult;

    return FarmBackgroundScaffold(
      title: 'INFORME VETERINARIO IA',
      child: SingleChildScrollView(
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

            const SizedBox(height: 30),

            _buildActionButtons(result),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(ScanResult r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // AJUSTE: Usamos animalType ya que breed podría no estar en el modelo
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
          if (r.isUrgent)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text("ATENCIÓN MÉDICA INMEDIATA", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ... (El resto de métodos _buildNfcCard, _buildMedicationCard, etc. se mantienen igual)
  // Asegúrate de que los campos coincidan con ScanResult:
  // medicationDosage, medicationRoute, applicationSite, offspringCount, gestationWeeks, daysUntilDelivery
  
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

  Widget _buildActionButtons(ScanResult result) {
    return ElevatedButton(
      onPressed: () async {
        await NotificationService.programarAlertasSegunResultado(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text("🚀 Seguimiento IA activado: Recordatorios cada 3 días configurados"),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent.shade700,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text("ACTIVAR SEGUIMIENTO IA", 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}