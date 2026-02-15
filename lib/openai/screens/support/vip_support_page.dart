import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart'; // SDK Oficial

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
  
  // Usamos el modelo 2.0 que ya habilitamos en Google Cloud
  late final GenerativeModel _model;

  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text': '¡Hola! Soy el Dr. Julián, tu asistente veterinario VIP. 🐾 Estoy listo para ayudarte con tus dudas. ¿En qué puedo apoyarte hoy?',
      'time': DateFormat('hh:mm a').format(DateTime.now()),
      'image': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Inicializamos el motor de IA de Firebase
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.0-flash',
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
    setState(() => _isTyping = true);
    _scrollToBottom();
    
    try {
      final List<Content> content = [];
      final List<Part> parts = [TextPart("Eres el Dr. Julián, un veterinario experto. Responde como un profesional médico a la siguiente consulta de forma clara y amable: $userText")];

      if (imageFile != null) {
        final Uint8List imageBytes = await imageFile.readAsBytes();
        parts.add(InlineDataPart('image/jpeg', imageBytes));
      }

      content.add(Content.multi(parts));

      // Llamada oficial a Firebase Vertex AI
      final response = await _model.generateContent(content);

      if (response.text != null) {
        _addMessage(false, response.text!.trim(), null);
      } else {
        _addMessage(false, "No pude procesar la respuesta. Intenta de nuevo.", null);
      }
    } catch (e) {
      debugPrint("Error en Chat VIP: $e");
      _addMessage(false, "El servicio VIP está experimentando una alta demanda. Por favor, reintenta en un momento.", null);
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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      File imageFile = File(image.path);
      _addMessage(true, "Consulta sobre esta imagen.", imageFile);
      _getAiResponse("Analiza detalladamente esta imagen veterinaria y dime qué observas.", imageFile);
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
        if (_isTyping) const Center(child: Text("DR. JULIÁN PENSANDO...  ", style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold))),
        const Icon(Icons.verified_user, color: Colors.blueAccent, size: 18),
        const SizedBox(width: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)]
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt_rounded, color: Colors.greenAccent),
              onPressed: _isTyping ? null : _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Escribe tu consulta aquí...",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isTyping ? null : _sendMessage,
              child: CircleAvatar(
                radius: 25,
                backgroundColor: _isTyping ? Colors.grey : Colors.greenAccent.shade700,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isMe 
              ? Colors.greenAccent.shade700.withOpacity(0.9) 
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          border: Border.all(color: Colors.white10, width: 0.5)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null) 
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(image!, fit: BoxFit.cover),
                ),
              ),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
            const SizedBox(height: 8),
            Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
