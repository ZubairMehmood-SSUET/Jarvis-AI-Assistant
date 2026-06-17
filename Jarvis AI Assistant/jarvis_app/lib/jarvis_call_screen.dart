import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:http/http.dart' as http; // ✅ Added for continuous backend sync
import 'dart:convert'; // ✅ Added for payload decoding

class JarvisCallScreen extends StatefulWidget {
  const JarvisCallScreen({super.key});

  @override
  State<JarvisCallScreen> createState() => _JarvisCallScreenState();
}

class _JarvisCallScreenState extends State<JarvisCallScreen>
    with SingleTickerProviderStateMixin {
  String _callStatus = "Tap Mic to activate secure audio relay.";
  bool _isListening = false;
  bool _isProcessing = false;
  late AnimationController _animationController;

  web.SpeechRecognition? _webSpeechRecognition;
  final String backendUrl = "http://localhost:8000/api/chat";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _initializeWebVoice();
  }

  void _initializeWebVoice() {
    try {
      _webSpeechRecognition = web.SpeechRecognition();
      _webSpeechRecognition!.continuous = false;
      _webSpeechRecognition!.interimResults = false;
      _webSpeechRecognition!.lang = 'en-US';

      _webSpeechRecognition!.addEventListener(
        'start',
        ((web.Event e) {
          setState(() {
            _isListening = true;
            _callStatus = "Listening actively... Speak now, Sir.";
          });
        }).toJS,
      );

      _webSpeechRecognition!.addEventListener(
        'end',
        ((web.Event e) {
          setState(() => _isListening = false);
        }).toJS,
      );

      _webSpeechRecognition!.addEventListener(
        'result',
        ((web.Event e) {
          final speechEvent = e as web.SpeechRecognitionEvent;
          if (speechEvent.results.length > 0) {
            final resultList = speechEvent.results.item(0);
            final alternative = resultList.item(0);
            final String transcript = alternative.transcript;

            if (transcript.isNotEmpty) {
              // ✅ REMOVED Navigator.pop -> Now triggers Live Core directly
              _sendToBackendAndSpeak(transcript);
            }
          }
        }).toJS,
      );

      _webSpeechRecognition!.addEventListener(
        'error',
        ((web.Event e) {
          setState(() {
            _callStatus = "Relay interrupted or mic access denied.";
            _isListening = false;
          });
        }).toJS,
      );
    } catch (e) {
      setState(
        () => _callStatus = "Voice link initiated on manual backup mode.",
      );
    }
  }

  // ✅ NEW LIVE CORE METHOD: Hits FastAPI and triggers browser Speech synthesis
  Future<void> _sendToBackendAndSpeak(String userQuery) async {
    setState(() {
      _isProcessing = true;
      _callStatus = "Sir: \"$userQuery\"\n\nJ.A.R.V.I.S: Thinking...";
    });

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": "Saad_Sir", "user_message": userQuery}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["reply"] ?? "No response sequence recorded, sir.";

        setState(() {
          _callStatus = "Sir: \"$userQuery\"\n\nJ.A.R.V.I.S: \"$reply\"";
          _isProcessing = false;
        });

        // 🔊 Dynamic Web Text-To-Speech Engine Execution
        final utterance = web.SpeechSynthesisUtterance();
        utterance.text = reply;
        utterance.pitch = 0.95; // Deep mechanical/AI voice pitch
        utterance.rate = 1.0; // Perfect natural transmission pace
        web.window.speechSynthesis.speak(utterance);
      } else {
        setState(() {
          _callStatus = "Core systems responded with an error, sir.";
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _callStatus = "Connection link to matrix broken, sir.";
        _isProcessing = false;
      });
    }
  }

  void _toggleVoiceListening() {
    if (_isProcessing) {
      return; // Prevent double trigger when Jarvis is speaking/thinking
    }

    if (_webSpeechRecognition == null) {
      _simulateVoiceInput();
      return;
    }

    if (_isListening) {
      _webSpeechRecognition!.stop();
    } else {
      try {
        _webSpeechRecognition!.start();
      } catch (e) {
        _simulateVoiceInput();
      }
    }
  }

  void _simulateVoiceInput() {
    // Live Presentation fallback
    _sendToBackendAndSpeak("hello jarvis status report");
  }

  @override
  void dispose() {
    // Stop speaking if screen is closed abruptly
    web.window.speechSynthesis.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                "NEURO-LINK SECURE",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ),

            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 140 + (20 * _animationController.value),
                  height: 140 + (20 * _animationController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? Colors.redAccent.withValues(alpha: 0.1)
                        : (_isProcessing
                              ? Colors.purpleAccent.withValues(alpha: 0.1)
                              : Colors.cyanAccent.withValues(alpha: 0.1)),
                    border: Border.all(
                      color: _isListening
                          ? Colors.redAccent
                          : (_isProcessing
                                ? Colors.purpleAccent
                                : Colors.cyanAccent),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isListening
                            ? Colors.redAccent
                            : (_isProcessing
                                  ? Colors.purpleAccent
                                  : Colors.cyanAccent),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isListening
                          ? Icons.settings_voice
                          : (_isProcessing
                                ? Icons.hourglass_empty_rounded
                                : Icons.blur_on_sharp),
                      color: _isListening
                          ? Colors.redAccent
                          : (_isProcessing
                                ? Colors.purpleAccent
                                : Colors.cyanAccent),
                      size: 60,
                    ),
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Text(
                    "J.A.R.V.I.S. COM-LINK",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Added a scroll view container to prevent text overflow during text streams
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Text(
                        _callStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: "mic_trigger_real",
                  onPressed: _toggleVoiceListening,
                  backgroundColor: _isListening
                      ? Colors.redAccent
                      : const Color(0xFF1E293B),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: _isListening ? Colors.white : Colors.cyanAccent,
                  ),
                ),
                const SizedBox(width: 40),
                FloatingActionButton(
                  heroTag: "end_link_real",
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
