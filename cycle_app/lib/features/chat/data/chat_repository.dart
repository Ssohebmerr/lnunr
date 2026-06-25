import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ai/ai_gateway.dart';
import '../../../core/profile/local_profile.dart';
import '../../../core/storage/user_prefs.dart';
import 'chat_message.dart';

class ChatRepository {
  ChatRepository({
    FirebaseFirestore? firestore,
    AiGateway? gateway,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _gateway = gateway ?? AiGateway();

  final FirebaseFirestore _firestore;
  final AiGateway _gateway;

  static const _chatId = 'cycle_assistant';
  static const _localChatStorageKey = 'local_chat_messages_v1';
  static final _localUpdates = StreamController<void>.broadcast();

  static bool isLocalChatUid(String uid) =>
      uid == UserPrefs.localChatUid || uid == LocalProfile.localChatUid;

  CollectionReference<Map<String, dynamic>> _messagesRef(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('chats')
          .doc(_chatId)
          .collection('messages');

  Stream<List<ChatMessage>> watchMessages(String uid) async* {
    if (isLocalChatUid(uid)) {
      yield await _loadLocalMessages();
      await for (final _ in _localUpdates.stream) {
        yield await _loadLocalMessages();
      }
      return;
    }
    yield* _messagesRef(uid)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());
  }

  Future<void> saveMessage(String uid, ChatMessage message) async {
    if (isLocalChatUid(uid)) {
      final list = await _loadLocalMessages();
      list.add(message.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()));
      await _persistLocalMessages(list);
      _localUpdates.add(null);
      return;
    }
    await _messagesRef(uid).add(message.toMap());
  }

  /// Number of recent messages injected as conversation memory.
  static const _historyWindow = 12;

  Future<String> requestAiReply({
    required String message,
    required Map<String, dynamic> cycleContext,
    bool analyzeMode = false,
    String mode = 'chat',
    List<ChatMessage> history = const [],
    String? unavailableMessage,
  }) async {
    final reply = await _gateway.request(
      message: _withHistory(message, history),
      context: cycleContext,
      analyzeMode: analyzeMode,
      mode: mode,
    );
    if (reply != null && reply.isNotEmpty) return reply;

    return unavailableMessage ??
        'عذراً، المساعد غير متاح حالياً.\n'
        'فعّلي Firebase AI Logic من لوحة Firebase وسجّلي الدخول.\n\n'
        'AI unavailable — enable Firebase AI Logic and sign in.';
  }

  /// Prepends recent conversation turns so the assistant remembers context.
  /// Works with both the Cloud Function and the direct Gemini path, since
  /// both treat the message as free text.
  String _withHistory(String message, List<ChatMessage> history) {
    if (history.isEmpty) return message;

    final recent = history.length > _historyWindow
        ? history.sublist(history.length - _historyWindow)
        : history;

    final lines = recent
        .map((m) => '${m.isUser ? 'User' : 'Assistant'}: ${m.text}')
        .join('\n');

    return 'Recent conversation (for context only — do not repeat verbatim):\n'
        '$lines\n'
        '---\n'
        'Current user message (answer THIS message directly first):\n'
        '$message';
  }

  Future<List<ChatMessage>> _loadLocalMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localChatStorageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ChatMessage.fromLocalJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistLocalMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(messages.map((m) => m.toLocalJson()).toList());
    await prefs.setString(_localChatStorageKey, encoded);
  }

}
