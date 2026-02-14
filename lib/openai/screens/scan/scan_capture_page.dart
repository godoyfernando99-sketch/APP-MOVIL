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
              const SizedBox(height: 10),
              const Text("Subir Foto", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
        imageQuality: 35, // Peso pluma
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
        animalCategory: widget.animalId, // Enviamos el nombre directo (Perro, Vaca, etc)
        mode: widget.mode,
        photos: _photos,
      );

      if (mounted) context.push(AppRoutes.scanResult, extra: result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("IA: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackgroundScaffold(
      title: 'Captura',
      child: Container(
        color: Colors.transparent, // Asegura que el fondo sea visible
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Foto de tu ${widget.animalId}",
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final hasPhoto = index < _photos.length;
                  return GestureDetector(
                    onTap: hasPhoto ? null : _pickImageSource,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: hasPhoto ? Colors.greenAccent : Colors.white24),
                      ),
                      child: hasPhoto 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              children: [
                                Positioned.fill(child: Image.memory(_photos[index], fit: BoxFit.cover)),
                                Positioned(top: 5, right: 5, child: GestureDetector(onTap: () => setState(() => _photos.removeAt(index)), child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 15, color: Colors.white)))),
                              ],
                            ),
                          )
                        : const Icon(Icons.add_a_photo, color: Colors.white54, size: 40),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const CircularProgressIndicator(color: Colors.greenAccent)
            else
              Container(
                width: double.infinity,
                height: 60,
                margin: const EdgeInsets.only(bottom: 40),
                child: ElevatedButton(
                  onPressed: _photos.isNotEmpty ? _processDiagnosis : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800.withOpacity(0.85),
                    disabledBackgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text("ANALIZAR AHORA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
