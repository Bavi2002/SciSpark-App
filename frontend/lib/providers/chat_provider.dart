import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => _messages;

  void addMessage(String text, {required bool isUser}) {
    _messages.add(ChatMessage(text: text, isUser: isUser));
    notifyListeners();
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
}