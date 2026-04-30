import 'package:flutter/material.dart';

import '../messaging_theme.dart';

class MessageComposer extends StatefulWidget {
  final bool isSending;
  final ValueChanged<String> onSend;

  const MessageComposer({
    super.key,
    required this.isSending,
    required this.onSend,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;

    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MessagingTheme.background,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: MessagingTheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: MessagingTheme.border),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: const InputDecoration(
                    hintText: 'Write a message...',
                    hintStyle: TextStyle(color: MessagingTheme.textMuted),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: MessagingTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: widget.isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
