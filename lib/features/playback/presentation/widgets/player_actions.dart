import 'package:flutter/material.dart';

class PlayerActions extends StatefulWidget {
  final VoidCallback? onQueueTap;

  const PlayerActions({super.key, this.onQueueTap});

  @override
  State<PlayerActions> createState() => _PlayerActionsState();
}

class _PlayerActionsState extends State<PlayerActions> {
  bool _liked = false;
  int _likes = 203;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Like
          GestureDetector(
            onTap: () {
              setState(() {
                _liked = !_liked;
                _likes += _liked ? 1 : -1;
              });
            },
            child: Row(
              children: [
                Icon(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? const Color(0xFFFF5500) : Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 5),
                Text(
                  '$_likes',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Comment
          GestureDetector(
            onTap: () {},
            child: Row(
              children: const [
                Icon(Icons.chat_bubble_outline,
                    color: Colors.white70, size: 20),
                SizedBox(width: 5),
                Text(
                  '7',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Share
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.share_outlined,
                color: Colors.white70, size: 22),
          ),

          // Queue
          GestureDetector(
            onTap: widget.onQueueTap,
            child: const Icon(Icons.queue_music,
                color: Colors.white70, size: 22),
          ),

          // More
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.more_vert,
                color: Colors.white70, size: 22),
          ),
        ],
      ),
    );
  }
}