class ChatMessage {
  final String id;
  final int senderId;
  final int receiverId;
  final String content;
  final bool isAiGenerated;
  final String messageType;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isAiGenerated,
    required this.messageType,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as int,
      receiverId: json['receiverId'] as int,
      content: json['content'] as String,
      isAiGenerated: json['aiGenerated'] as bool? ?? false,
      messageType: json['messageType'] as String? ?? "TEXT",
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
