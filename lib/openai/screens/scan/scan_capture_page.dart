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

  Future<void> _pickImageSource() async {
    if (_photos.length >= 3) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.greenAccent),
                title: const Text("Cámara", style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _processPicker(ImageSource.camera); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
                title: const Text("Galería", style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _processPicker(ImageSource.gallery); },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPicker(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 35,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() => _photos.add(bytes));
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _processDiagnosis() async {
    if (_photos.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      const service = AiDiagnosisService();
      final result = await service.diagnose(
        animalId: widget.animalId,
        animalCategory: widget.animalId,
        mode: widget.mode,
        photos: _photos,
      );

      if (mounted) context.push(AppRoutes.scanResult, extra: result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANTE: Quitamos el Scaffold interno que puede estar causando la capa blanca
    // y dejamos que FarmBackgroundScaffold maneje la estructura.
    return FarmBackgroundScaffold(
      title: 'Captura',
      child: Container(
        // Forzamos que este contenedor sea transparente
        color: Colors.transparent, 
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Análisis de ${widget.animalId}",
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2))
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 15, 
                  mainAxisSpacing: 15
                ),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final hasPhoto = index < _photos.length;
                  return GestureDetector(
                    onTap: hasPhoto ? null : _pickImageSource,
                    child: Container(
                      decoration: BoxDecoration(
                        // Fondo oscuro muy sutil para que los iconos resalten sobre la granja
                        color: Colors.black.withOpacity(0.2), 
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: hasPhoto ? Colors.greenAccent : Colors.white38, 
                          width: 2
                        ),
                      ),
                      child: hasPhoto 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: Stack(
                              children: [
                                Positioned.fill(child: Image.memory(_photos[index], fit: BoxFit.cover)),
                                Positioned(
                                  top: 8, right: 8, 
                                  child: GestureDetector(
                                    onTap: () => setState(() => _photos.removeAt(index)), 
                                    child: const CircleAvatar(
                                      radius: 14, 
                                      backgroundColor: Colors.red, 
                                      child: Icon(Icons.close, size: 18, color: Colors.white)
                                    )
                                  )
                                ),
                              ],
                            ),
                          )
                        : const Icon(Icons.add_a_photo, color: Colors.white, size: 45),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const Column(
                children: [
                  CircularProgressIndicator(color: Colors.greenAccent),
                  SizedBox(height: 15),
                  Text(
                    "IA Analizando...", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _photos.isNotEmpty ? _processDiagnosis : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      disabledBackgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 10,
                    ),
                    child: const Text(
                      "ANALIZAR AHORA", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
