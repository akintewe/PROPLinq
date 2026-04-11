import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class AiChatOption {
  final int id;
  final String label;
  AiChatOption({required this.id, required this.label});
}

class AiChatResponse {
  final String text;
  final String? title;
  final String? instruction;
  final List<AiChatOption> options;
  final bool requiresUserType;
  final String? conversationId;

  AiChatResponse({
    required this.text,
    this.title,
    this.instruction,
    this.options = const [],
    this.requiresUserType = false,
    this.conversationId,
  });
}

class AiChatService {
  static final AiChatService _instance = AiChatService._internal();
  factory AiChatService() => _instance;
  AiChatService._internal();

  final StorageService _storageService = StorageService();

  String? _conversationId;

  void resetConversation() {
    _conversationId = null;
  }

  Future<AiChatResponse> sendMessage(String message) async {
    final token = await _storageService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final payload = <String, dynamic>{'query': message};
    if (_conversationId != null) {
      payload['conversation_id'] = _conversationId;
    }

    final body = jsonEncode(payload);
    final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.aiChat}');

    debugPrint('🤖 [AiChat] POST $url');
    debugPrint('🤖 [AiChat] body: $body');

    final response = await http.post(url, headers: headers, body: body);

    debugPrint('🤖 [AiChat] status: ${response.statusCode}');
    debugPrint('🤖 [AiChat] body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      return _parseResponse(json);
    } else {
      String errorMsg = 'AI service error (${response.statusCode})';
      try {
        final json = jsonDecode(response.body);
        if (json is Map) errorMsg = json['message']?.toString() ?? errorMsg;
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }

  AiChatResponse _parseResponse(dynamic json) {
    if (json is! Map) {
      return AiChatResponse(text: json.toString());
    }

    final data = json['data'];
    final bool requiresUserType = data?['requires_user_type'] == true;
    final String? convId = data?['conversation_id']?.toString();

    // Persist conversation ID for follow-up messages
    if (convId != null) _conversationId = convId;

    final responseObj = data?['response'];
    if (responseObj is Map) {
      final title = responseObj['title']?.toString();
      final question = responseObj['question']?.toString();
      final instruction = responseObj['instruction']?.toString();
      final reply = responseObj['reply']?.toString() ??
          responseObj['message']?.toString() ??
          responseObj['answer']?.toString() ??
          responseObj['text']?.toString();

      // Parse options array
      final rawOptions = responseObj['options'];
      final options = <AiChatOption>[];
      if (rawOptions is List) {
        for (final o in rawOptions) {
          if (o is Map) {
            final id = int.tryParse(o['id']?.toString() ?? '');
            final label = o['label']?.toString();
            if (id != null && label != null) {
              options.add(AiChatOption(id: id, label: label));
            }
          }
        }
      }

      // Build display text: prefer question, fallback to reply or title
      final displayText = question ?? reply ?? title ?? json['message']?.toString() ?? '';

      return AiChatResponse(
        text: displayText,
        title: title,
        instruction: instruction,
        options: options,
        requiresUserType: requiresUserType,
        conversationId: convId,
      );
    }

    // Flat response — check top-level reply/message
    final topReply = data?['reply']?.toString() ??
        data?['message']?.toString() ??
        data?['answer']?.toString() ??
        json['message']?.toString() ??
        '';

    return AiChatResponse(
      text: topReply,
      requiresUserType: requiresUserType,
      conversationId: convId,
    );
  }
}
