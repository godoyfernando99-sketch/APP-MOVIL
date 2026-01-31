import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoSave());
  }

  Future<void> _autoSave() async {
    if (!mounted || widget.payload is! ScanResult) return;
    final result = widget.payload as ScanResult;
    
    setState(() => _isSaving = true);
    try {
      await context.read<HistoryController>().add(result);
      if (!mounted) return;
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payload is! ScanResult) {
      return FarmBackgroundScaffold(
        title: 'ERROR',
        backgroundColor: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text('Sin datos del escaneo', 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.menu),
                  child: const Text('VOLVER AL MENÚ'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final result = widget.payload as ScanResult;
    final animal = AnimalsCatalog.byId(result.animalId);

    final Color statusColor = result.healthStatus.toLowerCase() == 'buena' 
        ? Colors.greenAccent 
        : (result.healthStatus.toLowerCase() == 'regular' ? Colors.orangeAccent : Colors.redAccent);

    return FarmBackgroundScaffold(
      title: 'RESULTADO DEL ANÁLISIS',
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_user_outlined, color: statusColor, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'REPORTE GENERADO',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // FILAS DE DATOS
                  _buildResultRow('Especie:', animal.name, Icons.pets),
                  _buildResultRow('Estado:', result.healthStatus.toUpperCase(), Icons.favorite, valueColor: statusColor),
                  
                  if (result.diseaseName != null && result.diseaseName!.isNotEmpty)
                    _buildResultRow('Hallazgo:', result.diseaseName!, Icons.warning_amber_rounded, valueColor: Colors.redAccent),

                  _buildResultRow('Fecha:', result.createdAt.toString().substring(0, 16), Icons.calendar_today),
                  
                  if (result.foodRecommendation != null && result.foodRecommendation!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: Colors.white10),
                    ),
                    const Text('RECOMENDACIÓN:', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(result.foodRecommendation!, 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 14)),
                  ],

                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () => context.go(AppRoutes.menu),
                      child: const Text('FINALIZAR', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildResultRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent.withOpacity(0.7), size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
