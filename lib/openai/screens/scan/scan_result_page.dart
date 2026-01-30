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
    // Intentamos obtener el animal del catálogo, si falla usamos uno genérico
    final animal = AnimalsCatalog.byId(result.animalId);

    return FarmBackgroundScaffold(
      title: 'Resultado del Análisis',
      child: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          children: [
            // SECCIÓN DE FOTOS
            if (result.photosBase64.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: result.photosBase64.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(result.photosBase64[i]),
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 16),

            // TARJETA DE DATOS
            Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Datos del escaneo', 
                      style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    _Line(label: 'Animal', value: animal.name),
                    _Line(label: 'Estado de salud', value: result.healthStatus),
                    if (result.microchipNumber != null) 
                      _Line(label: 'Microchip', value: result.microchipNumber!),
                    _Line(label: 'Enfermedad', 
                      value: (result.diseaseName == null || result.diseaseName!.isEmpty) ? 'No detectada' : result.diseaseName!),
                    _Line(label: 'Gestación', 
                      value: result.isPregnant == true ? 'Sí' : 'No'),
                    
                    const Divider(height: 32),
                    
                    // ESTADO DE GUARDADO
                    if (_isSaving)
                      const Center(child: CircularProgressIndicator())
                    else if (_isSaved)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text('Guardado en historial', 
                            style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                        ],
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // BOTONES DE ACCIÓN
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.menu),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Volver al menú principal'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.history),
                        icon: const Icon(Icons.history_rounded),
                        label: const Text('Ver historial'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          SizedBox(
            width: 120, 
            child: Text(label, style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700))
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: t.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
