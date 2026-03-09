import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart'; 

class VipSupportPage extends StatefulWidget {
  const VipSupportPage({super.key});

  @override
  State<VipSupportPage> createState() => _VipSupportPageState();
}

class _VipSupportPageState extends State<VipSupportPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;
  late final GenerativeModel _model;

  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text': '¡Hola! Soy el Dr. Julián, tu asistente veterinario VIP. 🐾 Estoy listo para ayudarte con tus dudas médicas, análisis de síntomas o consejos de crianza. ¿En qué puedo apoyarte hoy?',
      'time': DateFormat('hh:mm a').format(DateTime.now()),
      'image': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-1.5-flash',
    );
  }

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
    if (!mounted) return;
    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      GenerateContentResponse response;
      final prompt = "Eres el Dr. Julián, un veterinario experto, empático y profesional. Responde a la siguiente consulta: $userText";

      if (imageFile != null) {
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final content = [
          Content.multi([
            TextPart(prompt),
            InlineDataPart('image/jpeg', imageBytes),
          ])
        ];
        response = await _model.generateContent(content);
      } else {
        response = await _model.generateContent([Content.text(prompt)]);
      }

      if (response.text != null) {
        _addMessage(false, response.text!.trim(), null);
      }
    } catch (e) {
      _addMessage(false, "Lo siento, mi conexión con la clínica está saturada. Inténtalo de nuevo en unos segundos.", null);
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      File imageFile = File(image.path);
      _addMessage(true, "Doctor, ¿puede revisar esta imagen?", imageFile);
      _getAiResponse("Analiza detalladamente esta imagen veterinaria.", imageFile);
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
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Dr. Julián está analizando...", 
                style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontStyle: FontStyle.italic)),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_camera, color: Colors.greenAccent),
              onPressed: _isTyping ? null : _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Escribe tu consulta al experto...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _isTyping ? null : _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.greenAccent.shade700,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
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
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2E7D32) : Colors.white12,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null) Image.file(image!, height: 200),
            Text(text, style: const TextStyle(color: Colors.white)),
            Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}