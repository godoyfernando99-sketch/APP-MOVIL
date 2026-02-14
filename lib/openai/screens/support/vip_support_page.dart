import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Asegúrate de tener esta dependencia
import 'dart:io';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';
import 'package:intl/intl.dart';

class VipSupportPage extends StatefulWidget {
  const VipSupportPage({super.key});

  @override
  State<VipSupportPage> createState() => _VipSupportPageState();
}

class _VipSupportPageState extends State<VipSupportPage> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  // Lista de mensajes (ahora soporta imágenes opcionales)
  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text': '¡Hola! Soy el Dr. Julián, tu asistente veterinario VIP. 🐾 Estoy aquí para ayudarte. Puedes enviarme una foto de cualquier síntoma para darte una orientación rápida. ¿En qué puedo ayudarte hoy?',
      'time': DateFormat('hh:mm a').format(DateTime.now()),
      'image': null,
    },
  ];

  // Función para enviar mensaje de texto
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userText = _messageController.text;
    _addMessage(true, userText, null);
    _messageController.clear();

    // Simular respuesta del Dr. Julián después de 1 segundo
    Future.delayed(const Duration(seconds: 1), () {
      _addMessage(false, "Entiendo. Estoy analizando tu consulta sobre '$userText'. ¿Podrías darme más detalles o enviarme una foto?", null);
    });
  }

  // Función para enviar imagen
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _addMessage(true, "He enviado una foto para revisión.", File(image.path));
      
      // Respuesta automática al recibir imagen
      Future.delayed(const Duration(seconds: 2), () {
        _addMessage(false, "Gracias por la imagen. La estoy revisando detalladamente...", null);
      });
    }
  }

  void _addMessage(bool isMe, String text, File? image) {
    setState(() {
      _messages.add({
        'isMe': isMe,
        'text': text,
        'time': DateFormat('hh:mm a').format(DateTime.now()),
        'image': image,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackgroundScaffold(
      title: 'SOPORTE VETERINARIO VIP',
      actions: [
        const Icon(Icons.circle, color: Colors.greenAccent, size: 12),
        const SizedBox(width: 8),
        const Center(child: Text("EN LÍNEA  ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
      ],
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _ChatBubble(
                  isMe: msg['isMe'],
                  text: msg['text'],
                  time: msg['time'],
                  image: msg['image'],
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.amber),
              onPressed: _pickImage, // AHORA SÍ TIENE FUNCIÓN
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Escribe tu consulta...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.amber.shade700,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.black),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String time;
  final File? image;

  const _ChatBubble({required this.isMe, required this.text, required this.time, this.image});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent.withOpacity(0.8) : Colors.grey[800]?.withOpacity(0.9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null) 
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(image!, fit: BoxFit.cover),
              ),
            if (image != null) const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
