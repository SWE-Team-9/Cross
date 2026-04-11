import 'package:flutter/material.dart';

import '../../domain/entities/comment_entity.dart';

class CommentTile extends StatelessWidget {
  final CommentEntity comment;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onReplySubmitted;

  const CommentTile({
    super.key,
    required this.comment,
    this.onDelete,
    this.onReplySubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final replyController = TextEditingController();

    return Card(
      margin: EdgeInsets.only(
        left: comment.isReply ? 32 : 12,
        right: 12,
        top: 8,
        bottom: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.userDisplayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(comment.content),
            if (comment.timestampSeconds != null) ...[
              const SizedBox(height: 6),
              Text('at ${comment.timestampSeconds}s'),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (onReplySubmitted != null)
                  TextButton(
                    onPressed: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            title: const Text('Reply'),
                            content: TextField(
                              controller: replyController,
                              decoration: const InputDecoration(
                                hintText: 'Write a reply...',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, replyController.text.trim()),
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
                    child: const Text('Delete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}