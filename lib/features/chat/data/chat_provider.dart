import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'chat_model.dart';

class ChatProvider extends ChangeNotifier {
  final _api = ApiClient();
  
  List<ChatThread> _threads = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ChatThread> get threads => _threads;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchChatList() async {
    // Avoid multiple concurrent requests
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.chatList);
    
    if (response.success && response.data != null) {
      final List<dynamic> data = response.data!['threads'] ?? [];
      _threads = data.map((json) => ChatThread.fromJson(json)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMessages(int threadId) async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.chatMessages, params: {'thread_id': threadId.toString()});
    
    if (response.success && response.data != null) {
      final List<dynamic> data = response.data!['messages'] ?? [];
      _messages = data.map((json) => ChatMessage.fromJson(json)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMessage(int threadId, String message) async {
    final response = await _api.post(ApiConstants.chatSend, {
      'thread_id': threadId,
      'message': message,
    });

    if (response.success && response.data != null) {
      final newMessage = ChatMessage.fromJson(response.data!['message']);
      _messages.add(newMessage);
      notifyListeners();
      return true;
    }
    
    _error = response.message;
    return false;
  }

  void addLocalMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
}
