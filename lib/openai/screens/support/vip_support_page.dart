import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';
import 'package:intl/intl.dart';
// IMPORT CORRECTO PARA EL BUILD
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

  // --- MENSAJE INICIAL DEL DR. JULIÁN ---
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
    // INICIALIZACIÓN TÉCNICA CORREGIDA
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

  // --- LÓGICA DE RESPUESTA DEL DR. JULIÁN ---
  Future<void> _getAiResponse(String userText, File? imageFile) async {
    if (!mounted) return;
    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      GenerateContentResponse response;

      if (imageFile != null) {
        final Uint8List imageBytes = await imageFile.readAsBytes();
        
        final content = [
          Content.multi([
            TextPart("Eres el Dr. Julián, un veterinario experto de campo. Responde de forma profesional, directa y amable a esta consulta: $userText"),
            InlineDataPart('image/jpeg', imageBytes),
          ])
        ];
        response = await _model.generateContent(content);
      } else {
        response = await _model.generateContent([
          Content.text("Eres el Dr. Julián, un veterinario experto. Responde de forma profesional y amable: $userText")
        ]);
      }

      if (response.text != null) {
        _addMessage(false, response.text!.trim(), null);
      } else {
        _addMessage(false, "Lo siento, no pude procesar la respuesta. ¿Podrías repetirme la consulta?", null);
      }

    } catch (e) {
      debugPrint("🚨 Error en Chat VIP: $e");
      _addMessage(false, "El servicio VIP está experimentando mucha demanda. Reintenta en un momento, por favor.", null);
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
      _addMessage(true, "Consulta sobre esta imagen.", imageFile);
      _getAiResponse("Analiza esta imagen veterinaria y dime qué observas como experto.", imageFile);
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
              child: Text("Dr. Julián está escribiendo...", 
                style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontStyle: FontStyle.italic)),
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
              icon: const Icon(Icons.image_outlined, color: Colors.greenAccent),
              onPressed: _isTyping ? null : _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Escribe tu consulta...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _isTyping ? null : _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: _isTyping ? Colors.grey : Colors.greenAccent.shade700,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
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
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1B5E20) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null) 
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(image!, fit: BoxFit.cover),
                ),
              ),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(time, style: const TextStyle(color: Colors.white38, fontSize: 9)),
            ),
          ],
        ),
      ),
    );
  }
}