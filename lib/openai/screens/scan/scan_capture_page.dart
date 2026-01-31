
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
  final String mode;

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
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _photos.add(bytes));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al abrir la cámara.')));
    }
  }

  Future<void> _analyze() async {
    if (_photos.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes tomar 3 fotografías.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthController>();
      final animal = AnimalsCatalog.byId(widget.animalId);
      const service = AiDiagnosisService();
      
      final result = await service.diagnose(
        animalId: animal.id,
        animalCategory: animal.category,
        mode: widget.mode,
        microchipNumber: widget.mode == 'chip' ? _chipCtrl.text.trim() : null,
        photos: _photos,
      );

      await auth.decrementScans();
      if (!mounted) return;
      context.push(AppRoutes.scanResult, extra: result).then((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión con la IA.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final animal = AnimalsCatalog.byId(widget.animalId);
    final auth = context.watch<AuthController>();
    final hasScans = auth.currentUser?.hasScansAvailable ?? false;
    final scansRemaining = auth.currentUser?.scansRemaining ?? 0;

    // PANTALLA SIN ESCANEOS DISPONIBLES
    if (!hasScans) {
      return FarmBackgroundScaffold(
        title: 'Límite alcanzado',
        backgroundColor: Colors.transparent,
        child: Center(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_photography_rounded, size: 80, color: Colors.redAccent),
                  const SizedBox(height:
