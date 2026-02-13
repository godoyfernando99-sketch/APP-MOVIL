import 'package:flutter/material.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class VipSupportPage extends StatefulWidget {
  const VipSupportPage({super.key});

  @override
  State<VipSupportPage> createState() => _VipSupportPageState();
}

class _VipSupportPageState extends State<VipSupportPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text': '¡Hola! Bienvenido al soporte VIP de ScannerAnimal. Soy el Dr. Julián, ¿en qué puedo ayudarte con tus animales hoy?',
      'time': '10:00 AM'
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isMe': true,
        'text': _messageController.text,
        'time': '10:05 AM',
      });
      _messageController.clear();
    });
    
    // Aquí podrías integrar una respuesta automática de IA o conectar con Firebase
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackgroundScaffold(
      title: 'SOPORTE VETERINARIO VIP',
      backgroundColor: Colors.transparent,
      actions: [
        const Icon(Icons.circle, color: Colors.greenAccent, size: 12),
        const SizedBox(width: 8),
        const Center(child: Text("EN LÍNEA  ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
      ],
      child: Column(
        children: [
          // Área de Chat
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
                );
              },
            ),
          ),

          // Barra de Entrada de Texto
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
              onPressed: () {}, // Aquí conectarías con image_picker
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

  const _ChatBubble({required this.isMe, required this.text, required this.time});

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
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
