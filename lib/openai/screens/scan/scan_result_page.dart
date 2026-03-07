import 'package:flutter/material.dart';
import 'package:scanneranimal/app/history/scan_models.dart'; // Importante
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class ScanResultPage extends StatefulWidget {
  const ScanResultPage({super.key, this.payload});
  final dynamic payload;

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {

  void _setAutomatedReminders(ScanResult result) {
    // 1. Recordatorio de Medicamentos
    for (int day in result.medicationDays) {
      _scheduleNotification(
        title: "💊 Aplicar Tratamiento",
        body: "Dosis programada para ${result.animalType}. Revisa el plan de cuidados.",
        daysFromNow: day,
      );
    }

    // 2. Alerta de Parto Crítica
    if (result.isPregnant == true && result.daysUntilDelivery != null) {
      if (result.daysUntilDelivery! <= 7) {
        _scheduleNotification(
          title: "🚨 PARTO INMINENTE",
          body: "Faltan aprox. ${result.daysUntilDelivery} días. Prepara el nido y contacta a tu veterinario.",
          daysFromNow: 1,
        );
      }
    }

    // 3. Seguimiento Estándar (3 días)
    _scheduleNotification(
      title: "🔍 Seguimiento de Evolución",
      body: "Es momento de realizar un nuevo escaneo para monitorear a tu ${result.animalType}.",
      daysFromNow: result.rescanInterval,
    );
  }

  void _scheduleNotification({required String title, required String body, required int daysFromNow}) {
    // Integración futura con AwesomeNotifications.instance.createNotification(...)
    print("🔔 Alerta Programada: $title | $body | T+$daysFromNow días");
  }

  @override
  Widget build(BuildContext context) {
    // Cast seguro del objeto ScanResult
    final result = widget.payload as ScanResult;

    return FarmBackgroundScaffold(
      title: 'INFORME DE SEGUIMIENTO',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatusHeader(result),
            const SizedBox(height: 15),

            // Nueva sección: Card de Gestación Avanzada
            if (result.isPregnant == true) _buildPregnancyCard(result),

            const SizedBox(height: 15),
            
            // Sección de Seguimiento y Próximos Pasos
            _buildFollowUpCard(result),

            const SizedBox(height: 15),

            if (result.preventionTips.isNotEmpty)
              _buildInfoBox("🛡️ PROTOCOLO DE CUIDADOS", result.preventionTips, Colors.tealAccent),

            const SizedBox(height: 30),

            _buildActionButtons(result),
          ],
        ),
      ),
    );
  }

  Widget _buildPregnancyCard(ScanResult res) {
    // Si faltan pocos días, usamos un color de alerta (Ambar/Rojo)
    final bool isUrgent = (res.daysUntilDelivery ?? 100) <= 7;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUrgent 
            ? [Colors.orange.withOpacity(0.2), Colors.red.withOpacity(0.1)]
            : [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isUrgent ? Colors.orangeAccent : Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              Text("DETALLES DE GESTACIÓN", 
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dataCol("Crías estimadas", res.offspringCount ?? "---", Icons.pets),
              _dataCol("Semanas", res.gestationWeeks ?? "---", Icons.timer),
              _dataCol("Días restantes", "${res.daysUntilDelivery ?? '---'}", Icons.event),
            ],
          ),
          if (res.deliveryForecast != null) ...[
            const Divider(color: Colors.white12, height: 30),
            Text(res.deliveryForecast!, 
              style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic)),
          ]
        ],
      ),
    );
  }

  Widget _dataCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 18),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildActionButtons(ScanResult result) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            _setAutomatedReminders(result);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("🚀 Inteligencia de seguimiento activada")),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent.shade700,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, color: Colors.amber),
              SizedBox(width: 10),
              Text("ACTIVAR SEGUIMIENTO IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  // --- Widgets de apoyo omitidos por brevedad pero asumiendo su existencia ---
  Widget _buildStatusHeader(ScanResult r) => Text(r.healthStatus, style: const TextStyle(color: Colors.white, fontSize: 20));
  Widget _buildInfoBox(String t, List<String> items, Color c) => Column(children: items.map((i) => Text(i)).toList());
}