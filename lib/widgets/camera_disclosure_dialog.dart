import 'package:flutter/material.dart';

class CameraDisclosure {
  static void show(BuildContext context, VoidCallback onAccept) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Colors.blueAccent, width: 0.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.camera_alt_rounded, color: Colors.blueAccent),
            SizedBox(width: 12),
            Text('USO DE LA CÁMARA', 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Para que ScannerAnimal funcione correctamente, necesitamos acceso a su cámara.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Este permiso se utilizará para:\n'
              '• Identificar especies de animales.\n'
              '• Escanear microchips.\n'
              '• Analizar el estado del animal.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('AHORA NO', style: TextStyle(color: Colors.white38)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onAccept();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }
}
