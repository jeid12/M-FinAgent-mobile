import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../state/app_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.state.chatMessages.isEmpty
              ? const Center(
                  child: Text(
                    'Ask: "How much did I spend on airtime this week?"',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.state.chatMessages.length,
                  itemBuilder: (context, index) {
                    final item = widget.state.chatMessages[index];
                    return _ChatBubble(message: item);
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask your AI coach...',
                      filled: true,
                      fillColor: const Color(0xFFF4F7FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final text = _controller.text;
                    _controller.clear();
                    await widget.state.sendQuestion(text);
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final align = message.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.fromUser ? const Color(0xFF003049) : const Color(0xFFE7EEF5);
    final textColor = message.fromUser ? Colors.white : Colors.black87;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(message.text, style: TextStyle(color: textColor)),
      ),
    );
  }
}
