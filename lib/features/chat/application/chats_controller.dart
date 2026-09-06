import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/chat/domain/chat_thread.dart';

/// Conversations of the current user.
///
class ChatsController extends Notifier<List<ChatThread>> {
  var _nextThreadId = 1;
  var _nextMessageId = 1;

  @override
  List<ChatThread> build() {
    if (AppConfig.hasPocketBaseUrl) {
      unawaited(Future<void>.microtask(_loadFromServer));
    }
    return const [];
  }

  Future<void> _loadFromServer() async {
    try {
      final client = ref.read(pocketBaseProvider);
      final response = await client.send<Map<String, dynamic>>(
        '/api/app/chats/mine',
      );
      final currentId = client.authStore.record?.id;
      final items = response['items'];
      if (!ref.mounted || items is! List) return;
      state = items
          .whereType<Map>()
          .map((raw) {
            final item = Map<String, dynamic>.from(raw);
            final peer = Map<String, dynamic>.from(item['peer'] as Map);
            final messages = (item['messages'] as List? ?? const [])
                .whereType<Map>()
                .map((rawMessage) {
                  final message = Map<String, dynamic>.from(rawMessage);
                  return ChatMessage(
                    id: message['id'] as String,
                    text: message['text'] as String? ?? '',
                    sentAt: DateTime.parse(message['created_at'] as String),
                    fromMe: message['sender_id'] == currentId,
                  );
                })
                .toList(growable: false);
            return ChatThread(
              id: item['id'] as String,
              peerId: peer['id'] as String,
              peerName: peer['name'] as String? ?? '',
              tripId: item['trip_id'] as String?,
              messages: messages,
            );
          })
          .toList(growable: false);
    } catch (_) {
      // The existing empty state remains usable and is refreshed on rebuild.
    }
  }

  ChatThread? findById(String id) {
    for (final thread in state) {
      if (thread.id == id) return thread;
    }
    return null;
  }

  /// Opens the conversation with a person, creating it on the first message —
  /// the same thread is reused afterwards.
  String openThread({
    required String peerId,
    required String peerName,
    String? peerAvatarAsset,
    String? tripId,
  }) {
    for (final thread in state) {
      if (thread.peerId == peerId && thread.tripId == tripId) return thread.id;
    }
    final thread = ChatThread(
      id: 'chat_${_nextThreadId++}',
      peerId: peerId,
      peerName: peerName,
      peerAvatarAsset: peerAvatarAsset,
      tripId: tripId,
    );
    state = [...state, thread];
    return thread.id;
  }

  /// Sends a message; empty text is ignored.
  void send(String threadId, String text, {DateTime? now}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final thread = findById(threadId);
    if (thread == null) return;
    if (AppConfig.hasPocketBaseUrl) {
      unawaited(_sendToServer(threadId, trimmed));
      return;
    }
    final message = ChatMessage(
      id: 'message_${_nextMessageId++}',
      text: trimmed,
      sentAt: now ?? DateTime.now(),
      fromMe: true,
    );
    state = [
      for (final item in state)
        if (item.id == threadId)
          item.copyWith(messages: [...item.messages, message])
        else
          item,
    ];
  }

  Future<void> _sendToServer(String threadId, String text) async {
    try {
      final response = await ref
          .read(pocketBaseProvider)
          .send<Map<String, dynamic>>(
            '/api/app/chats/$threadId/messages',
            method: 'POST',
            body: {
              'text': text,
              'client_message_id':
                  'flutter_${DateTime.now().microsecondsSinceEpoch}',
            },
          );
      final raw = response['message'];
      if (!ref.mounted || raw is! Map) return;
      final message = Map<String, dynamic>.from(raw);
      final thread = findById(threadId);
      if (thread == null) return;
      state = [
        for (final item in state)
          if (item.id == threadId)
            item.copyWith(
              messages: [
                ...item.messages,
                ChatMessage(
                  id: message['id'] as String,
                  text: message['text'] as String? ?? text,
                  sentAt: DateTime.parse(message['created_at'] as String),
                  fromMe: true,
                ),
              ],
            )
          else
            item,
      ];
    } catch (_) {
      // The composer stays available; a later realtime refresh can reconcile.
    }
  }
}

final chatsProvider = NotifierProvider<ChatsController, List<ChatThread>>(
  ChatsController.new,
);

/// Threads with something in them, newest activity first — what «Чаты» lists.
final chatThreadsProvider = Provider<List<ChatThread>>((ref) {
  final threads = [
    for (final thread in ref.watch(chatsProvider))
      if (thread.messages.isNotEmpty) thread,
  ];
  threads.sort(
    (a, b) => b.lastMessage!.sentAt.compareTo(a.lastMessage!.sentAt),
  );
  return threads;
});
