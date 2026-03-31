import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../constants/api_constants.dart';

class AiChatService {
  static final AiChatService _instance = AiChatService._internal();
  factory AiChatService() => _instance;
  AiChatService._internal();

  PusherChannelsFlutter? _pusher;
  String? _currentConversationId;
  Function(Map<String, dynamic>)? _onMessage;

  bool get isConnected => _pusher != null;

  /// Connect to a conversation's AI chat channel.
  /// [onMessage] is called with the raw event data map each time a response arrives.
  Future<void> connect({
    required String conversationId,
    required Function(Map<String, dynamic>) onMessage,
  }) async {
    // Disconnect any existing connection first
    if (_pusher != null) await disconnect();

    _currentConversationId = conversationId;
    _onMessage = onMessage;

    try {
      _pusher = PusherChannelsFlutter.getInstance();

      await _pusher!.init(
        apiKey: ApiConstants.reverbAppKey,
        cluster: 'mt1',
        useTLS: ApiConstants.reverbUseTLS,
        onConnectionStateChange: (currentState, previousState) {
          debugPrint('🔌 [AiChatService] Connection: $previousState → $currentState');
        },
        onError: (message, code, error) {
          debugPrint('❌ [AiChatService] Error $code: $message');
        },
      );

      await _pusher!.subscribe(
        channelName: 'ai-chat.$conversationId',
        onEvent: (event) {
          if (event.eventName == 'ai.chat.response') {
            try {
              final data = jsonDecode(event.data as String) as Map<String, dynamic>;
              _onMessage?.call(data);
            } catch (e) {
              debugPrint('❌ [AiChatService] Failed to parse event data: $e');
            }
          }
        },
      );

      await _pusher!.connect();
      debugPrint('✅ [AiChatService] Connected to ai-chat.$conversationId');
    } catch (e) {
      debugPrint('❌ [AiChatService] Failed to connect: $e');
      _pusher = null;
      rethrow;
    }
  }

  /// Disconnect and clean up.
  Future<void> disconnect() async {
    try {
      if (_currentConversationId != null) {
        await _pusher?.unsubscribe(channelName: 'ai-chat.$_currentConversationId');
      }
      await _pusher?.disconnect();
    } catch (e) {
      debugPrint('⚠️ [AiChatService] Error during disconnect: $e');
    } finally {
      _pusher = null;
      _currentConversationId = null;
      _onMessage = null;
    }
  }
}
