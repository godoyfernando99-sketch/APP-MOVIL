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
    // Guardado automático al cargar la página
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoSave());
  }

  Future<void> _autoSave() async {
    if (!mounted) return;
    if (widget.payload is! ScanResult) return;
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
      debugPrint('Auto-save failed: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    // 1. Validación de seguridad
    if (widget.payload is! ScanResult) {
      return FarmBackgroundScaffold(
        title: 'Sin Resultados',
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('No se recibieron datos del escaneo.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.menu),
                    child: const Text('Volver al Menú'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final result = widget.payload as ScanResult;
    final animal = AnimalsCatalog.byId(result.animalId);

    // Colores según estado de salud
    final Color statusColor = result.healthStatus == 'buena' 
        ? Colors.green 
        : (result.healthStatus == 'regular' ? Colors.orange : Colors.red);

    return FarmBackgroundScaffold(
      title: 'Análisis de ${animal.name}',
      child: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECCIÓN DE FOTOS (Carrusel horizontal)
            if (result.photosBase64.isNotEmpty)
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: result.photosBase64.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.dividerColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.memory(
                          base64Decode(result.photosBase64[i]),
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 16),

            // CABECERA DE ESTADO
            _StatusCard(status: result.healthStatus, color: statusColor),

            const SizedBox(height: 16),

            // TARJETA DE DETALLES MÉDICOS
            Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informe Veterinario', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const Divider(height: 24),
                    
                    _InfoRow(label: 'Especie', value: animal.name, icon: Icons.pets),
                    
                    if (result.microchipNumber != null) 
                      _InfoRow(label: 'Microchip', value: result.microchipNumber!, icon: Icons.nfc),

                    _InfoRow(
                      label: 'Enfermedad', 
                      value: (result.diseaseName == null || result.diseaseName!.isEmpty) ? 'Ninguna detectada' : result.diseaseName!,
                      icon: Icons.medical_information,
                    ),

                    _InfoRow(
                    label: 'Lesión/Fractura', 
                    value: result.fractureDescription!, 
                    icon: Icons.personal_injury, // <-- Aquí el cambio
                     color: Colors.red,
                    ),

                    _InfoRow(
                      label: 'Gestación', 
                      value: result.isPregnant == true ? 'SÍ (${result.pregnancyWeeks ?? "?"} semanas)' : 'NO detectada',
                      icon: Icons.pregnant_woman,
                      color: result.isPregnant == true ? Colors.pink : null,
                    ),

                    const Divider(height: 24),
                    
                    Text('Tratamiento y Cuidados', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Medicamento', value: result.medicationName ?? 'No requiere', icon: Icons.medication),
                    _InfoRow(label: 'Dosis Sugerida', value: result.medicationDose ?? 'N/A', icon: Icons.science),
                    _InfoRow(label: 'Alimentación', value: result.foodRecommendation ?? 'Dieta estándar', icon: Icons.restaurant),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // INDICADOR DE AUTO-GUARDADO
            if (_isSaving)
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
            else if (_isSaved)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_done, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Guardado automáticamente en Historial', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // BOTONES DE ACCIÓN
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.menu),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Volver al Inicio'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.history),
              icon: const Icon(Icons.history_rounded),
              label: const Text('Ver mi Historial'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusCard({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(status == 'buena' ? Icons.check_circle : (status == 'regular' ? Icons.warning : Icons.error), color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Salud General', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _InfoRow({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
