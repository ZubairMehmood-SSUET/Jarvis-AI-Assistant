import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'jarvis_call_screen.dart';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'login_screen.dart';

void main() {
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J.A.R.V.I.S.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0F1F),
        primaryColor: Colors.cyanAccent,
      ),

      home: const WebAuthWrapper(),
    );
  }
}

// 🔐 SECURITY WRAPPER: Yeh check karega ke user pehle se logged in hai ya nahi
class WebAuthWrapper extends StatelessWidget {
  const WebAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Browser ki local storage se session token uthaya
    final String? token = web.window.localStorage.getItem('session_token');

    if (token != null && token.isNotEmpty) {
      return const ChatScreen(); // Agar logged in hai toh seedha dashboard
    } else {
      return const JarvisLoginScreen();
    }
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  final String backendUrl = "http://localhost:8000/api/chat";

  Future<void> _sendMessage({String? customMessage}) async {
    final text = customMessage ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": text, "type": "text"});
      _isLoading = true;
    });
    if (customMessage == null) _messageController.clear();

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": "Shayan_Sir", "user_message": text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["reply"] ?? "No response, sir.";
        final type = data["type"] ?? "text";

        setState(() {
          _messages.add({"sender": "jarvis", "text": reply, "type": type});
        });
      } else {
        setState(() {
          _messages.add({
            "sender": "jarvis",
            "text": "Systems are offline, sir.",
            "type": "text",
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "sender": "jarvis",
          "text": "Connection link broken, sir.",
          "type": "text",
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "J.A.R.V.I.S.",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.blur_on_outlined, color: Colors.cyanAccent),
            onPressed: () async {
              final returnedVoiceText = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JarvisCallScreen(),
                ),
              );
              if (returnedVoiceText != null &&
                  returnedVoiceText is String &&
                  returnedVoiceText.isNotEmpty) {
                _sendMessage(customMessage: returnedVoiceText);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                final isImage = msg["type"] == "image";

                if (isImage) {
                  final String viewId = 'img-id-$index';

                  ui.platformViewRegistry.registerViewFactory(viewId, (
                    int viewId,
                  ) {
                    final htmlImage =
                        web.document.createElement('img')
                            as web.HTMLImageElement;
                    htmlImage.src = msg["text"].toString();
                    htmlImage.style.border = 'none';
                    htmlImage.style.width = '100%';
                    htmlImage.style.height = '100%';
                    htmlImage.style.objectFit = 'cover';
                    return htmlImage;
                  });

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📸 J.A.R.V.I.S. Visualizer:",
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: HtmlElementView(viewType: viewId),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUser
                            ? Colors.cyanAccent.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: Text(
                      msg["text"],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.cyanAccent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Ask Jarvis or ask to generate an image...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyanAccent),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
