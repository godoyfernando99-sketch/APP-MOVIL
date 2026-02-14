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
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                "Seleccionar foto del animal",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.greenAccent),
              title: const Text("Usar Cámara", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _processPicker(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
              title: const Text("Elegir de Galería", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _processPicker(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // OPTIMIZACIÓN EXTREMA: Para evitar Error 400 de Google
  Future<void> _processPicker(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 30, // Calidad baja (suficiente para IA)
        maxWidth: 500,    // Tamaño reducido para paquete de datos ligero
        maxHeight: 500,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        debugPrint("PESO DE IMAGEN: ${bytes.lengthInBytes / 1024} KB");
        setState(() => _photos.add(bytes));
      }
    } catch (e) {
      debugPrint("Error al capturar imagen: $e");
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

      if (mounted) {
        context.push(AppRoutes.scanResult, extra: result);
      }
    } catch (e) {
      debugPrint("ERROR CRÍTICO: $e");
      
      if (mounted) {
        String errorMessage = "Error: La imagen sigue siendo rechazada por el servidor.";
        
        if (e.toString().contains('400')) {
          errorMessage = "Error 400: Intenta con una foto más simple o de frente.";
        } else if (e.toString().contains('429')) {
          errorMessage = "Muchos intentos. Espera 1 minuto.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
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
      title: 'Captura de Fotos',
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Captura la foto para el diagnóstico",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                    onTap: hasPhoto ? null : _pickImageSource, 
                    child: Container(
                      decoration: BoxDecoration(
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
                              child: Stack(
                                children: [
                                  Positioned.fill(child: Image.memory(_photos[index], fit: BoxFit.cover)),
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _photos.removeAt(index)),
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close, size: 15, color: Colors.white),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, color: Colors.white70, size: 45),
                                SizedBox(height: 8),
                                Text("Agregar", style: TextStyle(color: Colors.white60)),
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
                  CircularProgressIndicator(color: Colors.greenAccent),
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
                    disabledBackgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    "ANALIZAR CON IA",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
