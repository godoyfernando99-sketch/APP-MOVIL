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
    // Guardado automático al entrar
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
      debugPrint("Error guardando resultado: $e");
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // CASO 1: SIN DATOS
    if (widget.payload is! ScanResult) {
      return _buildErrorState();
    }

    final result = widget.payload as ScanResult;
    final animal = AnimalsCatalog.byId(result.animalId);

    // Lógica de colores según estado
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
                  // Cabecera con Icono
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

                  // Sección 1: Datos Generales
                  _buildSectionTitle('INFORMACIÓN GENERAL'),
                  _buildResultRow('Especie:', animal.name, Icons.pets),
                  _buildResultRow('Salud:', result.healthStatus.toUpperCase(), Icons.favorite, valueColor: statusColor),
                  _buildResultRow('ID Animal:', result.animalId, Icons.badge),
                  
                  const Divider(color: Colors.white10, height: 32),

                  // Sección 2: Hallazgos Médicos (Dinámico)
                  _buildSectionTitle('HALLAZGOS MÉDICOS'),
                  if (result.diseaseName != null) 
                    _buildResultRow('Enfermedad:', result.diseaseName!, Icons.bug_report),
                  if (result.fractureDescription != null)
                    _buildResultRow('Lesión:', result.fractureDescription!, Icons.healing),
                  
                  // Sección 3: Gestación (Si aplica)
                  if (result.isPregnant == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: _buildResultRow('Gestación:', '${result.pregnancyWeeks} Semanas', Icons.child_care, valueColor: Colors.pinkAccent),
                    ),
                  ],

                  const SizedBox(height: 20),
                  
                  // Sección 4: Recomendación
                  _buildSectionTitle('RECOMENDACIÓN IA'),
                  Text(
                    result.foodRecommendation ?? "Sin recomendaciones específicas.",
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
                  ),

                  const SizedBox(height: 32),
                  
                  // Estado de guardado y Botón
                  Center(
                    child: Text(
                      _isSaving ? "Guardando en historial..." : (_isSaved ? "✓ Guardado automáticamente" : ""),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text('Error al procesar diagnóstico', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.go(AppRoutes.menu), child: const Text('VOLVER')),
            ],
          ),
        ),
      ),
    );
  }
}
