import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nfc_manager/nfc_manager.dart'; 
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
  String? _detectedMicrochipId; 
  bool _isNfcSupported = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'microchip') {
      _startNfcSession();
    }
  }

  // Lógica CORREGIDA para NfcManager 4.x.x
  void _startNfcSession() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      if (mounted) setState(() => _isNfcSupported = false);
      return;
    }

    // 1. Añadimos pollingOptions (Obligatorio en 4.x.x)
    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        try {
          // 2. CORRECCIÓN: Convertimos tag.data a Map para poder usar el operador []
          final Map<String, dynamic> data = Map<String, dynamic>.from(tag.data);
          
          final nfcData = data['mifare'] ?? data['nfca'] ?? data['iso7816'];
          
          // El identificador suele venir como List<int> dentro de los datos del protocolo
          final List<int>? identifier = nfcData is Map ? nfcData['identifier'] : null;

          if (identifier != null) {
            if (mounted) {
              setState(() {
                _detectedMicrochipId = identifier
                    .map((e) => e.toRadixString(16).padLeft(2, '0'))
                    .join(':')
                    .toUpperCase();
              });
            }
            
            await NfcManager.instance.stopSession();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Microchip detectado correctamente"),
                  backgroundColor: Colors.blueAccent,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint("Error leyendo NFC: $e");
        }
      },
    );
  }

  @override
  void dispose() {
    // Detenemos la sesión de forma segura
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  // --- El resto del código se mantiene igual pero con limpiezas menores ---

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
        microchipId: _detectedMicrochipId, 
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
    bool isMicrochipMode = widget.mode == 'microchip';

    return FarmBackgroundScaffold(
      title: isMicrochipMode ? 'Identificación Microchip' : 'Captura IA',
      child: Container(
        color: Colors.transparent, 
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (isMicrochipMode) _buildNfcStatusIndicator(),
            const SizedBox(height: 20),
            Text(
              "Análisis de ${widget.animalId}",
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Captura 3 fotos para un análisis preciso",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15
                ),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final hasPhoto = index < _photos.length;
                  return GestureDetector(
                    onTap: hasPhoto ? null : _pickImageSource,
                    child: Container(
                      decoration: BoxDecoration(
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
                                      radius: 14, backgroundColor: Colors.red, 
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
                  Text("Analizando Identidad...", style: TextStyle(color: Colors.white)),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: (_photos.length >= 1) ? _processDiagnosis : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMicrochipMode ? Colors.blueAccent : Colors.greenAccent.shade700,
                      disabledBackgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: Text(
                      isMicrochipMode && _detectedMicrochipId == null 
                        ? "ESPERANDO MICROCHIP..." 
                        : "ANALIZAR AHORA", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfcStatusIndicator() {
    bool detected = _detectedMicrochipId != null;
    if (!_isNfcSupported) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.redAccent),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 15),
            Text("NFC no disponible en este equipo", style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: detected ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: detected ? Colors.blueAccent : Colors.orangeAccent),
      ),
      child: Row(
        children: [
          Icon(
            detected ? Icons.check_circle : Icons.sensors,
            color: detected ? Colors.blueAccent : Colors.orangeAccent,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detected ? "MICROCHIP IDENTIFICADO" : "BUSCANDO MICROCHIP...",
                  style: TextStyle(
                    color: detected ? Colors.blueAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12
                  ),
                ),
                if (detected)
                  Text("ID: $_detectedMicrochipId", style: const TextStyle(color: Colors.white, fontSize: 14)),
                if (!detected)
                  const Text("Acerque el dispositivo al animal", style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}