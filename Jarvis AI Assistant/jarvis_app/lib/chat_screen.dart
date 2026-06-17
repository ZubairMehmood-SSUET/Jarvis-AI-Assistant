import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web; // 1. File Picker ka import add kiya
import 'jarvis_call_screen.dart';
import 'login_screen.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  final List<Map<String, dynamic>> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    List<Map<String, dynamic>>? messages,
  }) : messages = messages ?? [];
}

// ─────────────────────────────────────────────
// CHAT SCREEN
// ─────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ── Profile ──────────────────────────────────
  String _name = "Master";
  String? _imgUrl;

  // ── Sessions (history) ───────────────────────
  final List<ChatSession> _sessions = [];
  late ChatSession _activeSession;
  bool _sidebarOpen = true;

  // ── Messaging ────────────────────────────────
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final String _backendUrl = "http://localhost:8000/api/chat";

  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadProfile();
    _createNewSession(); // Start with a fresh session
  }

  void _loadProfile() {
    setState(() {
      _name = web.window.localStorage.getItem('user_name') ?? "Master";
      _imgUrl = web.window.localStorage.getItem('user_picture');
    });
  }

  // ── Session helpers ──────────────────────────

  void _createNewSession() {
    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "New Session",
      createdAt: DateTime.now(),
    );
    setState(() {
      _sessions.insert(0, session);
      _activeSession = session;
    });
  }

  void _switchSession(ChatSession session) {
    setState(() => _activeSession = session);
  }

  void _deleteSession(ChatSession session) {
    setState(() {
      _sessions.remove(session);
      if (_sessions.isEmpty) {
        _createNewSession();
      } else if (_activeSession == session) {
        _activeSession = _sessions.first;
      }
    });
  }

  // Derive a short title from the first user message
  String _deriveTitle(String text) {
    final words = text.trim().split(' ');
    return words.take(5).join(' ') + (words.length > 5 ? '…' : '');
  }

  // ── File Attachment Function ──────────────────
  Future<void> _attachFileOrPhoto() async {
    try {
      // Pure web code jo browser ka native file picker kholta hai
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();
      uploadInput.accept = '*/*'; // Har kisam ki file accept karne ke liye
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final html.File file = files[0];
          final String fileName = file.name;

          // Auto-title handling
          if (_activeSession.messages.isEmpty) {
            final String shortTitle = fileName.length > 15
                ? '${fileName.substring(0, 15)}…'
                : fileName;
            _activeSession.title = "File: $shortTitle";
          }

          setState(() {
            _activeSession.messages.add({
              "sender": "user",
              "text": "📎 Attached File: $fileName",
              "type": "text",
            });
          });

          _scrollToBottom();
        }
      });
    } catch (e) {
      debugPrint("File picking exception: $e");
    }
  }

  // ── Voice Mic Action Trigger ──────────────────
  void _triggerVoiceListening() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Com-Link Mic Activated. Listening for vocal command...'),
        duration: Duration(seconds: 2),
      ),
    );
    // Future Note: Yahan aap speech_to_text laga kar _messageController ko value assign kar sakte hain
  }

  // ── Messaging ────────────────────────────────

  Future<void> _sendMessage({String? customMessage}) async {
    final text = customMessage ?? _messageController.text.trim();
    if (text.isEmpty) return;

    // Auto-title the session from the first message
    if (_activeSession.messages.isEmpty) {
      _activeSession.title = _deriveTitle(text);
    }

    setState(() {
      _activeSession.messages.add({
        "sender": "user",
        "text": text,
        "type": "text",
      });
      _isLoading = true;
    });
    if (customMessage == null) _messageController.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": "Shayan_Sir", "user_message": text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["reply"] ?? "No response, sir.";
        final type = data["type"] ?? "text";
        setState(() {
          _activeSession.messages.add({
            "sender": "jarvis",
            "text": reply,
            "type": type,
          });
        });
      } else {
        _addError("Systems are offline, sir.");
      }
    } catch (_) {
      _addError("Connection link broken, sir.");
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _addError(String msg) {
    setState(
      () => _activeSession.messages.add({
        "sender": "jarvis",
        "text": msg,
        "type": "text",
      }),
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

  // ── Logout ───────────────────────────────────

  void _logout() {
    web.window.localStorage.removeItem('session_token');
    web.window.localStorage.removeItem('user_name');
    web.window.localStorage.removeItem('user_picture');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const JarvisLoginScreen()),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1F),
      body: Row(
        children: [
          // ── SIDEBAR ──────────────────────────
          if (_sidebarOpen && !isMobile) _buildSidebar(),

          // ── MAIN AREA ────────────────────────
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isMobile),
                Expanded(child: _buildMessageList()),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  ),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),

      // Mobile: drawer-style sidebar
      drawer: isMobile ? Drawer(child: _buildSidebar()) : null,
    );
  }

  // ─────────────────────────────────────────────
  // SIDEBAR
  // ─────────────────────────────────────────────

  Widget _buildSidebar() {
    // Group sessions by date
    final today = <ChatSession>[];
    final yesterday = <ChatSession>[];
    final older = <ChatSession>[];
    final now = DateTime.now();

    for (final s in _sessions) {
      final diff = now.difference(s.createdAt).inDays;
      if (diff == 0) {
        today.add(s);
      } else if (diff == 1) {
        yesterday.add(s);
      } else {
        older.add(s);
      }
    }

    return Container(
      width: 260,
      color: const Color(0xFF0D1526),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.all_inclusive,
                  color: Colors.cyanAccent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  "J.A.R.V.I.S.",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _sidebarOpen = false),
                  tooltip: "Collapse sidebar",
                ),
              ],
            ),
          ),

          // New chat button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: InkWell(
              onTap: _createNewSession,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.35),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.cyanAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "New Session",
                      style: TextStyle(color: Colors.cyanAccent, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),

          // Session list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (today.isNotEmpty) ...[
                  _sectionLabel("Today"),
                  ...today.map((s) => _sessionTile(s)),
                ],
                if (yesterday.isNotEmpty) ...[
                  _sectionLabel("Yesterday"),
                  ...yesterday.map((s) => _sessionTile(s)),
                ],
                if (older.isNotEmpty) ...[
                  _sectionLabel("Older"),
                  ...older.map((s) => _sessionTile(s)),
                ],
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Profile row at bottom
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: _imgUrl != null
                      ? NetworkImage(_imgUrl!)
                      : null,
                  backgroundColor: Colors.blueGrey.shade800,
                  child: _imgUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.white54,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _name,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  onPressed: _logout,
                  tooltip: "Logout",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _sessionTile(ChatSession session) {
    final isActive = session.id == _activeSession.id;
    return InkWell(
      onTap: () => _switchSession(session),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.cyanAccent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: Colors.cyanAccent.withValues(alpha: 0.25))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 14,
              color: isActive ? Colors.cyanAccent : Colors.white38,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                session.title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white60,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Delete button (only on hover / active)
            if (isActive)
              GestureDetector(
                onTap: () => _deleteSession(session),
                child: const Icon(Icons.close, size: 14, color: Colors.white38),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────

  Widget _buildTopBar(bool isMobile) {
    return Container(
      height: 56,
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Sidebar toggle (desktop) or hamburger (mobile)
          IconButton(
            icon: Icon(
              _sidebarOpen && !isMobile ? Icons.menu_open : Icons.menu,
              color: Colors.cyanAccent,
            ),
            onPressed: () {
              if (isMobile) {
                Scaffold.of(context).openDrawer();
              } else {
                setState(() => _sidebarOpen = !_sidebarOpen);
              }
            },
          ),
          const SizedBox(width: 4),
          Text(
            _activeSession.title,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          // Voice call button
          IconButton(
            icon: const Icon(Icons.blur_on_outlined, color: Colors.cyanAccent),
            tooltip: "Voice Com-Link",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JarvisCallScreen()),
              );
              if (result is String && result.isNotEmpty) {
                _sendMessage(customMessage: result);
              }
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MESSAGE LIST
  // ─────────────────────────────────────────────

  Widget _buildMessageList() {
    final messages = _activeSession.messages;

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.all_inclusive, color: Colors.cyanAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              "Good day, $_name.\nHow may I assist you?",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isUser = msg["sender"] == "user";
        final isImage = msg["type"] == "image";

        if (isImage) {
          final viewId = 'img-id-${_activeSession.id}-$index';
          ui.platformViewRegistry.registerViewFactory(viewId, (int _) {
            final img =
                web.document.createElement('img') as web.HTMLImageElement;
            img.src = msg["text"].toString();
            img.style.border = 'none';
            img.style.width = '100%';
            img.style.height = '100%';
            img.style.objectFit = 'cover';
            return img;
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
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 2),
                bottomRight: Radius.circular(isUser ? 2 : 14),
              ),
              border: Border.all(
                color: isUser
                    ? Colors.cyanAccent.withValues(alpha: 0.25)
                    : Colors.transparent,
              ),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            child: Text(
              msg["text"],
              style: TextStyle(
                color: isUser ? Colors.white : Colors.cyanAccent,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // INPUT BAR (UPDATED INLINE STYLE WITH PICKER & MIC)
  // ─────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      color: const Color(0xFF0F172A),
      child: Row(
        children: [
          // 1. ADD/CLIP ICON BUTTON (Left side of Input)
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.cyanAccent,
              size: 26,
            ),
            tooltip: "Attach File / Photos",
            onPressed: _attachFileOrPhoto,
          ),
          const SizedBox(width: 4),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "Ask Jarvis or request an image...",
                  hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. MICROPHONE ICON BUTTON (Right side before send)
          IconButton(
            icon: const Icon(
              Icons.mic_none_rounded,
              color: Colors.cyanAccent,
              size: 26,
            ),
            tooltip: "Vocal Input",
            onPressed: _triggerVoiceListening,
          ),
          const SizedBox(width: 4),

          // 3. SEND BUTTON
          InkWell(
            onTap: () => _sendMessage(),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(Icons.send, color: Colors.cyanAccent, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
