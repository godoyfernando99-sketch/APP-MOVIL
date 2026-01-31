
import 'dart:convert';
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
    final animal = AnimalsCatalog.byId(widget.animalId);
    final auth = context.watch<AuthController>();
    final hasScans = auth.currentUser?.hasScansAvailable ?? false;

    if (!hasScans) {
      return FarmBackgroundScaffold(
        title: 'Límite alcanzado',
        backgroundColor: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
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
                const SizedBox(height: 24),
                const Text('Sin escaneos disponibles', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.menu),
                  child: const Text('VOLVER'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FarmBackgroundScaffold(
      title: 'ANÁLISIS DE ${animal.name.toUpperCase()}',
      backgroundColor: Colors.transparent,
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Toma 3 fotos de diferentes ángulos',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ..._photos.map((b) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(b, width: 90, height: 90, fit: BoxFit.cover),
                    )),
                    if (_photos.length < 3)
                      GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, dashPattern: const [5, 5]),
                          ),
                          child: const Icon(Icons.add_a_photo, color: Colors.white54),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                if (widget.mode == 'chip') ...[
                  TextField(
                    controller: _chipCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Número de Microchip',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _photos.length == 3 ? _analyze : null,
                    child: const Text('ANALIZAR AHORA'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
