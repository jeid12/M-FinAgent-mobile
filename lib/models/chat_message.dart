class ChatMessage {
  ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Supports both local cache format and server history format
    final role = json['role'] as String?;
    final fromUser = role != null ? role == 'user' : (json['fromUser'] as bool? ?? true);
    final text = (json['content'] ?? json['text'] ?? '') as String;
    return ChatMessage(text: text, fromUser: fromUser);
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'fromUser': fromUser,
      };
}
