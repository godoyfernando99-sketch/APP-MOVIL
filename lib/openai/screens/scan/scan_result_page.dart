import 'package:flutter/material.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
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

    // 3. Seguimiento Estándar
    _scheduleNotification(
      title: "🔍 Seguimiento de Evolución",
      body: "Es momento de realizar un nuevo escaneo para monitorear a tu ${result.animalType}.",
      daysFromNow: result.rescanInterval,
    );
  }

  void _scheduleNotification({required String title, required String body, required int daysFromNow}) {
    print("🔔 Alerta Programada: $title | $body | T+$daysFromNow días");
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

            if (result.isPregnant == true) _buildPregnancyCard(result),

            const SizedBox(height: 15),

            // AHORA ESTE MÉTODO SÍ EXISTE ABAJO
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

  // --- MÉTODOS QUE FALTABAN ---

  Widget _buildFollowUpCard(ScanResult res) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10)
      ),
      child: Column(
        children: [
          _followUpRow(Icons.calendar_today_rounded, "Próximo escaneo:", "En ${res.rescanInterval} días"),
          if (res.isPregnant == true)
            _followUpRow(Icons.auto_awesome_motion, "Estado de gestación:", "Monitoreo activo"),
          _followUpRow(Icons.security_update_good_rounded, "Protocolo IA:", "Seguimiento activado"),
        ],
      ),
    );
  }

  Widget _followUpRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ScanResult r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(r.animalType.toUpperCase(), 
            style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 5),
          Text(r.healthStatus.toUpperCase(), 
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.black)),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, List<String> items, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.left(color: accentColor, width: 4),
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

  // --- RESTO DE WIDGETS YA DEFINIDOS ---

  Widget _buildPregnancyCard(ScanResult res) {
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
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
              SizedBox(width: 8),
              Text("DETALLES DE GESTACIÓN", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dataCol("Crías", res.offspringCount ?? "---", Icons.pets),
              _dataCol("Semanas", res.gestationWeeks ?? "---", Icons.timer),
              _dataCol("Días rest.", "${res.daysUntilDelivery ?? '---'}", Icons.event),
            ],
          ),
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
    return ElevatedButton(
      onPressed: () {
        _setAutomatedReminders(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚀 Seguimiento IA activado")),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent.shade700,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text("ACTIVAR SEGUIMIENTO IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}