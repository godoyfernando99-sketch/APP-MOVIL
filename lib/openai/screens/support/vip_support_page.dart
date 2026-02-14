import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:scanneranimal/openai/openai_config.dart';

class VipSupportPage extends StatefulWidget {
  const VipSupportPage({super.key});

  @override
  State<VipSupportPage> createState() => _VipSupportPageState();
}

class _VipSupportPageState extends State<VipSupportPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Para auto-scroll
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;
  
  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text': '¡Hola! Soy el Dr. Julián, tu asistente veterinario VIP. 🐾 Estoy listo para ayudarte. ¿Qué animalito te preocupa hoy?',
      'time': DateFormat('hh:mm a').format(DateTime.now()),
      'image': null,
    },
  ];

  // Desplazar hacia abajo al recibir/enviar mensaje
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _getAiResponse(String userText, File? imageFile) async {
    setState(() => _isTyping = true);
    _scrollToBottom();
    
    final String apiKey = OpenAiConfig.apiKey;
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');

    try {
      final List<Map<String, dynamic>> parts = [
        {"text": "Eres el Dr. Julián, un veterinario experto y empático. Responde de forma concisa a: $userText"}
      ];

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        parts.add({
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": base64Encode(bytes)
          }
        });
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": parts}],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 400,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['candidates'][0]['content']['parts'][0]['text'];
        _addMessage(false, aiText.trim(), null);
      } else {
        _addMessage(false, "Lo siento, hubo un error de red. (Código: ${response.statusCode})", null);
      }
    } catch (e) {
      _addMessage(false, "No pude conectar con el asistente. Revisa tu internet.", null);
    } finally {
      if (mounted) setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final userText = _messageController.text;
    _addMessage(true, userText, null);
    _messageController.clear();
    _getAiResponse(userText, null);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      File imageFile = File(image.path);
      _addMessage(true, "He subido una foto para consulta.", imageFile);
      _getAiResponse("Analiza esta imagen y dime si ves algo inusual.", imageFile);
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
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackgroundScaffold(
      title: 'SOPORTE VETERINARIO VIP',
      actions: [
        if (_isTyping) const Center(child: Text("ESCRIBIENDO...  ", style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold))),
        const Icon(Icons.circle, color: Colors.greenAccent, size: 12),
        const SizedBox(width: 8),
      ],
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _ChatBubble(
                isMe: _messages[index]['isMe'],
                text: _messages[index]['text'],
                time: _messages[index]['time'],
                image: _messages[index]['image'],
              ),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.amber),
              onPressed: _isTyping ? null : _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Tu consulta VIP...",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: _isTyping ? Colors.grey : Colors.amber.shade700,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.black),
                onPressed: _isTyping ? null : _sendMessage,
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent.withOpacity(0.9) : Colors.grey[850]!.withOpacity(0.95),
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
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(image!, fit: BoxFit.cover),
                ),
              ),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 12, color: Colors.white38),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
