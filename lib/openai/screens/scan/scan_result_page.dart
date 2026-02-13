import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // Importante para la función de compartir

import 'package:scanneranimal/app/history/history_controller.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
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
    // Iniciamos el flujo preguntando por observaciones
    WidgetsBinding.instance.addPostFrameCallback((_) => _askForObservations());
  }

  // 1. Lógica para compartir el reporte con formato limpio
  void _shareResult(ScanResult result, dynamic animal) {
    final String textToShare = '''
🐾 *REPORTE VETERINARIO IA - SCANNER ANIMAL* 🐾

📊 *DATOS GENERALES:*
• Especie: ${animal.name}
• Estado de Salud: ${result.healthStatus.toUpperCase()}
• ID Animal: ${result.animalId}

🏥 *HALLAZGOS MÉDICOS:*
${result.diseaseName != null ? '• Enfermedad: ${result.diseaseName}' : ''}
${result.fractureDescription != null ? '• Lesión: ${result.fractureDescription}' : ''}
${result.isPregnant == true ? '• Gestación: ${result.pregnancyWeeks} semanas' : ''}

📝 *OBSERVACIONES DEL USUARIO:*
${(_userObservations != null && _userObservations!.isNotEmpty) ? _userObservations : 'Sin observaciones adicionales.'}

🍎 *RECOMENDACIÓN:*
${result.foodRecommendation ?? 'Consultar con un profesional.'}

⚠️ *AVISO:* Este reporte es referencial generado por IA y no sustituye la consulta veterinaria profesional.
''';

    Share.share(textToShare, subject: 'Análisis de ${animal.name}');
  }

  // 2. Diálogo para capturar observaciones manuales
  Future<void> _askForObservations() async {
    if (!mounted || widget.payload is! ScanResult) return;

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final TextEditingController _textController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("¿Agregar observaciones?", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "¿Deseas añadir alguna nota o síntoma adicional visto manualmente?",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _textController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Ej: No ha comido, está decaído...",
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("NO, GUARDAR ASÍ", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              onPressed: () => Navigator.pop(context, _textController.text),
              child: const Text("SÍ, AGREGAR", style: TextStyle(color: Colors.black87)),
            ),
          ],
        );
      },
    );

    setState(() => _userObservations = result);
    _saveFinalResult(); 
  }

  // 3. Guardado en la base de datos local
  Future<void> _saveFinalResult() async {
    if (!mounted || widget.payload is! ScanResult) return;
    final result = widget.payload as ScanResult;
    
    setState(() => _isSaving = true);
    try {
      // Aquí el controlador de historial guarda el objeto
      await context.read<HistoryController>().add(result);
      if (!mounted) return;
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
    } catch (e) {
      debugPrint("Error guardando resultado: $e");
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload is! ScanResult) return _buildErrorState();

    final result = widget.payload as ScanResult;
    final animal = AnimalsCatalog.byId(result.animalId);
    final Color statusColor = result.healthStatus == 'buena' 
        ? Colors.greenAccent 
        : (result.healthStatus == 'regular' ? Colors.orangeAccent : Colors.redAccent);

    return FarmBackgroundScaffold(
      title: 'RESULTADO DEL EXAMEN',
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: statusColor.withOpacity(0.3)),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.analytics_outlined, color: statusColor, size: 48),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ANÁLISIS VETERINARIO IA',
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('INFORMACIÓN GENERAL'),
                  _buildResultRow('Especie:', animal.name, Icons.pets),
                  _buildResultRow('Salud:', result.healthStatus.toUpperCase(), Icons.favorite, valueColor: statusColor),
                  
                  if (_userObservations != null && _userObservations!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSectionTitle('MIS OBSERVACIONES'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        _userObservations!,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],

                  const Divider(color: Colors.white10, height: 32),

                  _buildSectionTitle('HALLAZGOS MÉDICOS'),
                  if (result.diseaseName != null) 
                    _buildResultRow('Enfermedad:', result.diseaseName!, Icons.bug_report),
                  if (result.fractureDescription != null)
                    _buildResultRow('Lesión:', result.fractureDescription!, Icons.healing),
                  
                  if (result.isPregnant == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: _buildResultRow('Gestación:', '${result.pregnancyWeeks} Semanas', Icons.child_care, valueColor: Colors.pinkAccent),
                    ),
                  ],

                  const SizedBox(height: 20),
                  _buildSectionTitle('RECOMENDACIÓN IA'),
                  Text(
                    result.foodRecommendation ?? "Sin recomendaciones específicas.",
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
                  ),

                  const SizedBox(height: 32),

                  // BOTÓN COMPARTIR
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: BorderSide(color: statusColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _shareResult(result, animal),
                      icon: const Icon(Icons.share, color: Colors.white, size: 20),
                      label: const Text('COMPARTIR INFORME', style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 12),
                  
                  // BOTÓN INICIO
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => context.go(AppRoutes.menu),
                      icon: const Icon(Icons.home),
                      label: const Text('VOLVER AL INICIO'),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      _isSaving ? "Guardando en historial..." : (_isSaved ? "✓ Guardado correctamente" : ""),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent.withOpacity(0.7), size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return FarmBackgroundScaffold(
      title: 'ERROR',
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(28)),
          child: Column(
