
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/openai/ai_diagnosis_service.dart';
import 'package:scanneranimal/openai/openai_config.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class ScanCapturePage extends StatefulWidget {
  const ScanCapturePage({super.key, required this.animalId, required this.mode});
  final String animalId;
  final String mode; // chip | nochip

  @override
  State<ScanCapturePage> createState() => _ScanCapturePageState();
}

class _ScanCapturePageState extends State<ScanCapturePage> {
  final _picker = ImagePicker();
  final _chipCtrl = TextEditingController();

  final List<Uint8List> _photos = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _chipCtrl.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_photos.length >= 3) return;
    try {
      // Reducir calidad para evitar problemas de almacenamiento
      final file = await _picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 50, // Reducido de 80 a 50
        maxWidth: 800,    // Limitar ancho máximo
        maxHeight: 800,   // Limitar alto máximo
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _photos.add(bytes));
    } catch (e) {
      debugPrint('pickImage failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la cámara en este entorno.')));
    }
  }

  Future<void> _analyze() async {
    if (_photos.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes tomar 3 fotografías.')));
      return;
    }
    if (widget.mode == 'chip' && _chipCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el número de microchip.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthController>();
      await auth.decrementScans();
      
      final animal = AnimalsCatalog.byId(widget.animalId);
      final service = const AiDiagnosisService();
      final result = await service.diagnose(
        animalId: animal.id,
        animalCategory: animal.category,
        mode: widget.mode,
        microchipNumber: widget.mode == 'chip' ? _chipCtrl.text.trim() : null,
        photos: _photos,
      );
      if (!mounted) return;

      context.push(AppRoutes.scanResult, extra: result); // 'result' debe ser tipo ScanResult
      
      // Navegar directamente a resultados, go_router manejará la pila correctamente
      context.go(AppRoutes.scanResult, extra: result);
    } catch (e) {
      debugPrint('AI diagnose failed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo completar el escaneo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final animal = AnimalsCatalog.byId(widget.animalId);
    final auth = context.watch<AuthController>();
    final hasScans = auth.currentUser?.hasScansAvailable ?? false;
    final scansRemaining = auth.currentUser?.scansRemaining ?? 0;

    if (!hasScans) {
      return FarmBackgroundScaffold(
        title: 'Escaneo • ${animal.name}',
        child: Center(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Card(
              child: Padding(
                padding: AppSpacing.paddingXl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.no_photography_rounded, size: 64, color: t.colorScheme.error),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Sin escaneos disponibles',
                      style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Has agotado tus escaneos gratuitos. Adquiere un plan para continuar escaneando.',
                      style: t.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.subscriptions),
                      icon: Icon(Icons.star_rounded, color: t.colorScheme.onPrimary),
                      label: Text('Ver Planes', style: TextStyle(color: t.colorScheme.onPrimary)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FarmBackgroundScaffold(
      title: 'Escaneo • ${animal.name}',
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Toma 3 fotos en diferentes ángulos', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    if (widget.mode == 'chip')
                      TextField(
                        controller: _chipCtrl,
                        decoration: const InputDecoration(labelText: 'Número de microchip', prefixIcon: Icon(Icons.nfc_rounded)),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _takePhoto,
                            icon: Icon(Icons.camera_alt_rounded, color: t.colorScheme.onPrimary),
                            label: Text('Tomar foto (${_photos.length}/3)', style: TextStyle(color: t.colorScheme.onPrimary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() => _photos.clear());
                                  },
                            icon: Icon(Icons.restart_alt_rounded, color: t.colorScheme.onSecondaryContainer),
                            label: Text('Reiniciar', style: TextStyle(color: t.colorScheme.onSecondaryContainer)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: 3,
                itemBuilder: (context, i) {
                  final has = i < _photos.length;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      color: t.colorScheme.surface.withValues(alpha: 0.55),
                      child: has
                          ? Image.memory(_photos[i], fit: BoxFit.cover)
                          : Center(child: Icon(Icons.add_a_photo_rounded, color: t.colorScheme.onSurfaceVariant)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _analyze,
                icon: _isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: t.colorScheme.onPrimary),
                      )
                    : Icon(Icons.auto_awesome_rounded, color: t.colorScheme.onPrimary),
                label: Text('Analizar con IA', style: TextStyle(color: t.colorScheme.onPrimary)),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    OpenAiConfig.isConfigured
                        ? 'IA activa (OpenAI).'
                        : 'IA en modo DEMO: para IA real, configura OpenAI (variables de entorno en Dreamflow).',
                    style: t.textTheme.bodySmall,
                  ),
                ),
                if (auth.currentUser?.subscriptionPlan != 'pro')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Escaneos: $scansRemaining',
                      style: t.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
