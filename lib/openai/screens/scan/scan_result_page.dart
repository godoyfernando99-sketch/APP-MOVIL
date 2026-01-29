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
  const ScanResultPage({super.key, required this.payload});
  final Object? payload;

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
    if (widget.payload is! ScanResult) {
      return const FarmBackgroundScaffold(title: 'Resultado', child: Center(child: Text('Sin datos de resultado.')));
    }
    final result = widget.payload as ScanResult;
    final animal = AnimalsCatalog.byId(result.animalId);
    final t = Theme.of(context);

    final photos = result.photosBase64.take(3).map((b64) => base64Decode(b64)).toList();

    return FarmBackgroundScaffold(
      title: 'Resultados • ${animal.name}',
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          SizedBox(
            height: 180,
            child: Row(
              children: [
                for (final bytes in photos)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Image.memory(bytes, fit: BoxFit.cover),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos del escaneo', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  _Line(label: 'Categoría', value: result.animalCategory == AnimalCategory.home ? 'Casa' : 'Granja'),
                  if (result.microchipNumber != null) _Line(label: 'Microchip', value: result.microchipNumber!),
                  _Line(label: 'Estado de salud', value: result.healthStatus),
                  _Line(label: 'Enfermedad', value: (result.diseaseName == null || result.diseaseName!.isEmpty) ? 'No detectada' : result.diseaseName!),
                  _Line(label: 'Fractura', value: (result.fractureDescription == null || result.fractureDescription!.isEmpty) ? 'No detectada' : result.fractureDescription!),
                  _Line(label: 'Medicamento', value: (result.medicationName == null || result.medicationName!.isEmpty) ? 'N/A' : result.medicationName!),
                  _Line(label: 'Dosis', value: (result.medicationDose == null || result.medicationDose!.isEmpty) ? 'N/A' : result.medicationDose!),
                  _Line(
                    label: 'Gestación',
                    value: result.isPregnant == true
                        ? 'Sí (${result.pregnancyWeeks ?? 0} semanas)'
                        : (result.isPregnant == false ? 'No' : 'Desconocido'),
                  ),
                  if (result.foodRecommendation != null && result.foodRecommendation!.isNotEmpty)
                    _Line(label: 'Alimento recomendado', value: result.foodRecommendation!),
                  const SizedBox(height: 14),
                  if (_isSaving)
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: t.colorScheme.primary),
                          const SizedBox(height: 8),
                          Text('Guardando en historial...', style: t.textTheme.bodySmall),
                        ],
                      ),
                    )
                  else if (_isSaved)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '✓ Guardado automáticamente en historial',
                              style: t.textTheme.bodyMedium?.copyWith(color: Colors.green[800], fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No se pudo guardar automáticamente',
                              style: t.textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.menu),
                      icon: Icon(Icons.home_rounded, color: t.colorScheme.onPrimary),
                      label: Text('Volver al menú principal', style: TextStyle(color: t.colorScheme.onPrimary)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.history),
                      icon: Icon(Icons.history_rounded, color: t.colorScheme.primary),
                      label: Text('Ver historial', style: TextStyle(color: t.colorScheme.primary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: t.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
