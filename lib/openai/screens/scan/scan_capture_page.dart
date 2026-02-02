import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/openai/ai_diagnosis_service.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class ScanCapturePage extends StatefulWidget {
  final String animalId;
  final String mode;

  const ScanCapturePage({
    super.key,
    required this.animalId,
    required this.mode,
  });

  @override
  State<ScanCapturePage> createState() => _ScanCapturePageState();
}

class _ScanCapturePageState extends State<ScanCapturePage> {
  final List<Uint8List> _photos = [];
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    if (_photos.length >= 3) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _photos.add(bytes));
    }
  }

  Future<void> _processDiagnosis() async {
    if (_photos.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      const service = AiDiagnosisService();
      final result = await service.diagnose(
        animalId: widget.animalId,
        animalCategory: 'vaca', 
        mode: widget.mode,
        photos: _photos,
      );

      if (mounted) {
        context.push(AppRoutes.scanResult, extra: result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en el análisis: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackgroundScaffold(
      title: 'Captura de Fotos',
      // CORRECCIÓN CLAVE: Forzar transparencia para ver el fondo de la granja
      backgroundColor: Colors.transparent, 
      child: Container(
        // Añadimos un ligero degradado oscuro superior para que el texto sea legible
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                "Captura hasta 3 fotos del animal",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [const Shadow(blurRadius: 5, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final hasPhoto = index < _photos.length;
                    return GestureDetector(
                      onTap: hasPhoto ? null : _takePhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          // Usamos un fondo semi-transparente oscuro en lugar de blanco
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasPhoto ? Colors.greenAccent : Colors.white30,
                            width: 2,
                          ),
                        ),
                        child: hasPhoto
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.memory(_photos[index], fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_rounded, color: Colors.white70, size: 45),
                                  const SizedBox(height: 8),
                                  Text("Foto ${index + 1}", style: const TextStyle(color: Colors.white60)),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_isProcessing)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 10),
                    Text("Analizando con IA...", style: TextStyle(color: Colors.white)),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _photos.isNotEmpty ? _processDiagnosis : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text(
                      "ANALIZAR CON IA", 
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)
                    ),
