import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/app/history/history_controller.dart';
import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/openai/services/pdf_service.dart';
import 'package:scanneranimal/app_services/notification_service.dart';

class ScanResultPage extends StatefulWidget {
  final dynamic payload;
  const ScanResultPage({super.key, this.payload});

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  final TextEditingController _notesController = TextEditingController();
  bool _showUrgentAlert = false;

  @override
  void initState() {
    super.initState();
    if (widget.payload is ScanResult) {
      final res = widget.payload as ScanResult;
      if (res.isHighRisk) setState(() => _showUrgentAlert = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.payload as ScanResult;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(res.timestamp);

    return Scaffold(
      appBar: AppBar(title: const Text("RESULTADOS DEL ANÁLISIS")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Fecha: $dateStr", style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                _buildInfoItem("Tipo de Animal", res.animalType),
                _buildInfoItem("Raza/Especie", res.breed ?? "No identificada"),
                
                if (res.isPregnant) ...[
                  const SizedBox(height: 10),
                  const Text("EMBARAZO DETECTADO", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                  _buildInfoItem("Semanas/Meses", "${res.gestationWeeks} semanas"),
                  _buildInfoItem("Crías estimadas", res.offspringCount ?? "0"),
                  _buildInfoItem("Días para el parto", "${res.daysUntilDelivery} días"),
                ],

                const SizedBox(height: 10),
                const Text("INFORME MÉDICO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Text(res.healthStatus),
                ),

                _buildInfoItem("Alimento Sugerido", res.suggestedFoodName ?? "N/A"),
                _buildInfoItem("Guía Nutricional", res.foodRecommendation ?? "N/A"),

                const SizedBox(height: 15),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: "MIS NOTAS Y COMENTARIOS", border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 25),
                _buildActionButtons(res),
              ],
            ),
          ),
          if (_showUrgentAlert) _buildHighRiskPopup(res),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ScanResult res) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            NotificationService.programarAlertasSegunResultado(res);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ SEGUIMIENTO ACTIVADO")));
          },
          icon: const Icon(Icons.notifications_active),
          label: const Text("ACTIVAR SEGUIMIENTO VETERINARIO"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => PdfService.generateAndShare(res),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("COMPARTIR PDF"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final finalResult = res.copyWith(notes: _notesController.text);
                  await context.read<HistoryController>().saveScan(finalResult);
                  await context.read<AuthController>().useFreeScan();
                  if (mounted) {
                    // DIRECCIONA AL MENÚ PRINCIPAL Y LIMPIA RUTAS
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
                child: const Text("GUARDAR"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighRiskPopup(ScanResult res) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: AlertDialog(
        title: const Text("🚨 ALERTA DE ALTO RIESGO", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text("Se ha detectado una condición grave.\n\n${res.healthStatus.split('\n\n').first}"),
        actions: [
          ElevatedButton(onPressed: () => setState(() => _showUrgentAlert = false), child: const Text("ENTENDIDO"))
        ],
      ),
    );
  }
}