import 'package:flutter/material.dart';

import '../../domain/entities/comment_entity.dart';

class CommentTile extends StatelessWidget {
  final CommentEntity comment;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onReplySubmitted;
  final VoidCallback? onTapTimestamp;

  const CommentTile({
    super.key,
    required this.comment,
    this.onDelete,
    this.onReplySubmitted,
    this.onTapTimestamp,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final replyController = TextEditingController();

    return Container(
      margin: EdgeInsets.only(
        left: comment.isReply ? 44 : 12,
        right: 12,
        top: 6,
        bottom: 6,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white12,
                backgroundImage: comment.userAvatarUrl != null
                    ? NetworkImage(comment.userAvatarUrl!)
                    : null,
                child: comment.userAvatarUrl == null
                    ? Text(
                        comment.userDisplayName.isNotEmpty
                            ? comment.userDisplayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  comment.userDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (comment.timestampSeconds != null)
                GestureDetector(
                  onTap: onTapTimestamp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFF5500),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0x66FF5500),
                      ),
                    ),
                    child: Text(
                      _formatTime(comment.timestampSeconds!),
                      style: const TextStyle(
                        color: Color(0xFFFF5500),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (onReplySubmitted != null)
                TextButton(
                  onPressed: () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF121212),
                          title: const Text(
                            'Reply',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: TextField(
                            controller: replyController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Write a reply...',
                              hintStyle: TextStyle(color: Colors.white38),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(
                                context,
                                replyController.text.trim(),
                              ),
                              child: const Text('Send'),
                            ),
                          ],
                        );
                      },
                    );

                    if (result != null && result.isNotEmpty) {
                      onReplySubmitted!(result);
                    }
                  },
                  child: const Text('Reply'),
                ),
              if (onDelete != null)
                TextButton(
                  onPressed: onDelete,
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}