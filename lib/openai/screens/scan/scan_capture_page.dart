
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
      imageQuality: 70, // Optimizado para la IA
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _photos.add(bytes));
    }
  }

  Future<void> _processDiagnosis() async {
    if (_photos.length < 1) return;

    setState(() => _isProcessing = true);

    try {
      const service = AiDiagnosisService();
      // El servicio ahora retorna un objeto ScanResult compatible
      final result = await service.diagnose(
        animalId: widget.animalId,
        animalCategory: 'vaca', // O la categoría dinámica que manejes
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "Captura hasta 3 fotos del animal",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final hasPhoto = index < _photos.length;
                  return GestureDetector(
                    onTap: hasPhoto ? null : _takePhoto,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(16),
                        // CORRECCIÓN: Eliminado dashPattern que causaba el error en Codemagic
                        border: Border.all(
                          color: Colors.white24, 
                          width: 2,
                        ),
                      ),
                      child: hasPhoto
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(_photos[index], fit: BoxFit.cover),
                            )
                          : const Icon(Icons.add_a_photo, color: Colors.white, size: 40),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const CircularProgressIndicator(color: Colors.green)
            else
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _photos.isNotEmpty ? _processDiagnosis : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("ANALIZAR CON IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
