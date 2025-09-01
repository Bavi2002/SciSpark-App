import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../providers/chat_provider.dart';
import '../../services/api_service.dart';
import 'message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String experimentId;
  final String context;

  const ChatScreen({Key? key, required this.experimentId, required this.context}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSending = false;
  bool _isSpeaking = false;
  bool _isListening = false; // For STT
  bool _handsFreeMode = true; // For auto TTS playback
  String _selectedLanguage = 'en-US';
  List<String> _languages = ['en-US', 'es-ES', 'fr-FR'];
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
    _typingAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    // Clear chat history on open
    Provider.of<ChatProvider>(context, listen: false).clearMessages();
  }

  void _initTts() async {
    await _tts.setLanguage(_selectedLanguage);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => setState(() => _isListening = status == 'listening'),
      onError: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition error: $error')),
      ),
    );
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final trimmedMessage = message.trim();
    Provider.of<ChatProvider>(context, listen: false).addMessage(trimmedMessage, isUser: true);
    _controller.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      final response = await ApiService.askQuestion(widget.experimentId, trimmedMessage);
      Provider.of<ChatProvider>(context, listen: false).addMessage(response['reply'], isUser: false);
      if (_handsFreeMode) {
        setState(() => _isSpeaking = true);
        await _tts.speak(response['reply']);
      }
    } catch (e) {
      Provider.of<ChatProvider>(context, listen: false)
          .addMessage('Sorry, I encountered an issue. Please try again!', isUser: false);
    } finally {
      setState(() => _isSending = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _startListening() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    bool available = await _speech.initialize(
      onStatus: (status) => setState(() => _isListening = status == 'listening'),
      onError: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition error: $error')),
      ),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _sendMessage(result.recognizedWords);
            setState(() => _isListening = false);
          }
        },
        localeId: _selectedLanguage,
      );
    } else {
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleTts() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    }
  }

  void _changeLanguage(String? value) {
    if (value != null) {
      setState(() {
        _selectedLanguage = value;
        _tts.setLanguage(_selectedLanguage);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[50]!, Colors.white], // Enhanced with subtle gradient
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          fontFamily: 'ComicSans', // Added for consistency
                        ),
                      ),
                      Text(
                        'Ask me about your experiment',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'ComicSans',
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (_isSpeaking)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _typingAnimationController,
                              builder: (context, child) {
                                return Icon(
                                  Icons.volume_up,
                                  size: 16,
                                  color: Colors.green[700]!.withOpacity(
                                    0.5 + 0.5 * _typingAnimationController.value,
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Speaking...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                                fontFamily: 'ComicSans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedLanguage,
                      items: _languages
                          .map((lang) => DropdownMenuItem(
                                value: lang,
                                child: Text(
                                  lang,
                                  style: TextStyle(
                                    fontFamily: 'ComicSans',
                                    color: Colors.black,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: _changeLanguage,
                      style: TextStyle(
                        fontFamily: 'ComicSans',
                        color: Colors.black,
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (ctx, provider, _) {
                if (provider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Start a conversation!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontFamily: 'ComicSans',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ask me anything about your experiment',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: 'ComicSans',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: provider.messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == provider.messages.length && _isSending) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.smart_toy,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _typingAnimationController,
                                    builder: (context, child) {
                                      return Row(
                                        children: List.generate(3, (index) {
                                          double delay = index * 0.2;
                                          double animationValue = (_typingAnimationController.value - delay).clamp(0.0, 1.0);
                                          return Container(
                                            width: 8,
                                            height: 8,
                                            margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[500]!.withOpacity(
                                                0.3 + 0.7 * (1 - (animationValue - animationValue.floor())).abs(),
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Thinking...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      fontFamily: 'ComicSans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300),
                      child: MessageBubble(message: provider.messages[i]),
                    );
                  },
                );
              },
            ),
          ),

          // Input Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hands-Free Mode',
                        style: TextStyle(
                          fontFamily: 'ComicSans',
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      Switch(
                        value: _handsFreeMode,
                        onChanged: (value) => setState(() => _handsFreeMode = value),
                        activeColor: Colors.blueAccent,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_isSpeaking)
                        Container(
                          margin: EdgeInsets.only(right: 12),
                          child: Material(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: _toggleTts,
                              child: Container(
                                width: 48,
                                height: 48,
                                child: Icon(
                                  Icons.stop,
                                  color: Colors.red[600],
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            controller: _controller,
                            enabled: !_isSending,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Ask about the experiment...',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontFamily: 'ComicSans',
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(_controller.text),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Material(
                        color: _isListening ? Colors.red[600] : Colors.black,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _startListening,
                          child: Container(
                            width: 48,
                            height: 48,
                            child: Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Material(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _isSending ? null : () => _sendMessage(_controller.text),
                          child: Container(
                            width: 48,
                            height: 48,
                            child: _isSending
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}