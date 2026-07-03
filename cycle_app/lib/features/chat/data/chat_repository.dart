import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ai/ai_gateway.dart';
import '../../../core/ai/ai_gateway_exception.dart';
import '../../../core/ai/models/ai_turn.dart';
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

  /// Number of recent messages passed to the model as multi-turn context.
  static const _historyWindow = 12;

  Future<String> requestAiReply({
    required String message,
    required Map<String, dynamic> cycleContext,
    bool analyzeMode = false,
    String mode = 'chat',
    String? personality,
    List<ChatMessage> history = const [],
  }) async {
    final reply = await _gateway.request(
      message: message,
      context: cycleContext,
      analyzeMode: analyzeMode,
      mode: mode,
      personality: personality,
      history: _toAiTurns(history),
    );
    if (reply != null && reply.isNotEmpty) return reply;
    throw const AiGatewayException('server_error');
  }

  /// Streaming variant of [requestAiReply] — yields partial text chunks
  /// for use in chat UIs that want token-by-token rendering.
  Stream<String> streamAiReply({
    required String message,
    required Map<String, dynamic> cycleContext,
    String mode = 'chat',
    String? personality,
    List<ChatMessage> history = const [],
  }) {
    return _gateway.stream(
      message: message,
      context: cycleContext,
      mode: mode,
      personality: personality,
      history: _toAiTurns(history),
    );
  }

  /// Converts saved chat messages into the trimmed [AiTurn] list passed
  /// to the AI gateway. The most recent [_historyWindow] turns are kept.
  List<AiTurn> _toAiTurns(List<ChatMessage> history) {
    if (history.isEmpty) return const [];
    final recent = history.length > _historyWindow
        ? history.sublist(history.length - _historyWindow)
        : history;
    return recent
        .map(
          (m) => m.isUser
              ? AiTurn.user(m.text)
              : AiTurn.model(m.text),
        )
        .toList();
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
