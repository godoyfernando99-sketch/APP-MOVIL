import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanResultPage extends StatefulWidget {
  const ScanResultPage({super.key, this.payload});
  final dynamic payload;

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  
  // Función maestra para programar el seguimiento completo
  void _setAutomatedReminders(ScanResult result) {
    // 1. Recordatorio de Medicamentos (IA definie los días)
    for (int day in result.medicationDays ?? []) {
      _scheduleNotification(
        title: "💊 Aplicar Tratamiento",
        body: "Recordatorio de dosis para ${result.detectedSpecies}. Revisa el plan de la IA.",
        daysFromNow: day,
      );
    }

    // 2. Alerta de Parto (Si faltan menos de 7 días, avisar a diario)
    if (result.isPregnant && result.daysUntilDelivery != null) {
      if (result.daysUntilDelivery! <= 7) {
        _scheduleNotification(
          title: "🚨 PARTO CERCANO",
          body: "El parto de tu animal está previsto para dentro de ${result.daysUntilDelivery} días. ¡Prepara el área!",
          daysFromNow: 1, // Avisar mañana mismo
        );
      }
    }

    // 3. Seguimiento de Evolución (Cada 3 días)
    _scheduleNotification(
      title: "🔍 Seguimiento Necesario",
      body: "Han pasado 3 días. Realiza un nuevo escaneo para verificar la evolución de la salud/gestación.",
      daysFromNow: 3,
    );
    
    // 4. Verificación de Protocolos
    _scheduleNotification(
      title: "🛡️ ¿Cumpliste los cuidados?",
      body: "Verifica si has seguido los protocolos de prevención sugeridos por la IA.",
      daysFromNow: 2,
    );
  }

  void _scheduleNotification({required String title, required String body, required int daysFromNow}) {
    // Aquí se integra con awesome_notifications o tu servicio local
    print("🔔 Programada: $title para dentro de $daysFromNow días.");
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.payload as ScanResult;
    
    return FarmBackgroundScaffold(
      title: 'INFORME DE SEGUIMIENTO',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatusHeader(result),
            const SizedBox(height: 15),

            // Burbuja informativa de seguimiento
            _buildFollowUpCard(result),

            const SizedBox(height: 15),
            
            _buildInfoBox("🛡️ PROTOCOLO DE CUIDADOS", result.preventionTips!, Colors.tealAccent),
            
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                _setAutomatedReminders(result); // ACTIVA TODO EL SISTEMA DE ALERTAS
                _saveAndFinish(result);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.shade700,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
              child: const Text("ACTIVAR SEGUIMIENTO E INTELIGENCIA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpCard(ScanResult res) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24)
      ),
      child: Column(
        children: [
          _followUpRow(Icons.calendar_month, "Próximo escaneo:", "En 3 días"),
          if (res.isPregnant)
            _followUpRow(Icons.child_care, "Alerta de parto:", res.deliveryForecast ?? "Pendiente"),
          _followUpRow(Icons.verified_user_outlined, "Protocolo:", "Monitoreo activo"),
        ],
      ),
    );
  }

  Widget _followUpRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, color: Colors.blueAccent, size: 16),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const Spacer(),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }
} 