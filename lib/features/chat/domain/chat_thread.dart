import 'package:flutter/foundation.dart';

/// One message in a conversation.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.fromMe,
  });

  final String id;
  final String text;
  final DateTime sentAt;

  /// `true` for what this user sent, `false` for the other side.
  final bool fromMe;
}

/// A conversation with one person, opened around a trip.
@immutable
class ChatThread {
  const ChatThread({
    required this.id,
    required this.peerId,
    required this.peerName,
    this.peerAvatarAsset,
    this.tripId,
    this.messages = const <ChatMessage>[],
  });

  final String id;
  final String peerId;
  final String peerName;
  final String? peerAvatarAsset;

  /// The trip the chat was opened around (`chats.trip_id`).
  final String? tripId;
  final List<ChatMessage> messages;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  ChatThread copyWith({List<ChatMessage>? messages}) {
    return ChatThread(
      id: id,
      peerId: peerId,
      peerName: peerName,
      peerAvatarAsset: peerAvatarAsset,
      tripId: tripId,
      messages: messages ?? this.messages,
    );
  }
}
