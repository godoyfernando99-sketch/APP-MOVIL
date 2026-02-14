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

  // CAMBIO CLAVE AQUÍ: Optimización de peso de imagen
  Future<void> _processPicker(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Calidad optimizada
        maxWidth: 800,    // Reducimos el ancho máximo de 1024 a 800
        maxHeight: 800,   // Reducimos el alto máximo para asegurar ligereza
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
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
      
      debugPrint("Iniciando diagnóstico para animalId: ${widget.animalId} en modo: ${widget.mode}");

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
      debugPrint("ERROR CRÍTICO EN DIAGNÓSTICO: $e");
      
      if (mounted) {
        String errorMessage = "Error: ${e.toString()}"; 
        
        if (e.toString().contains('VALIDATION_ERROR')) {
          errorMessage = "⚠️ La IA no detectó un animal claro en la imagen.";
        } else if (e.toString().contains('404')) {
          errorMessage = "Error de conexión con el modelo de IA (404).";
        } else if (e.toString().contains('400')) {
          errorMessage = "Error 400: La imagen es muy pesada o el formato no es compatible.";
        } else if (e.toString().contains('429')) {
          errorMessage = "Has agotado el límite de intentos, espera un momento.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.white, fontSize: 12)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
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
              "Captura hasta 3 fotos del animal",
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
