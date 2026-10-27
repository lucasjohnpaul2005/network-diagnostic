/// Who a message is "from", from the local device's point of view.
/// `system` is used for connect/disconnect notices in the chat log.
enum MessageDirection { sent, received, system }

/// Plain data holder for one chat bubble.
class ChatMessage {
  final String id;
  final String senderName;
  final String text;
  final MessageDirection direction;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.direction,
    required this.timestamp,
  });
}
