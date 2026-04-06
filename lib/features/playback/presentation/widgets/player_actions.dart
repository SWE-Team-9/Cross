import 'package:flutter/material.dart';

class PlayerActions extends StatelessWidget {
  const PlayerActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.favorite_border, color: Colors.white70),
              SizedBox(width: 6),
              Text(
                "727",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Row(
            children: const [
              Icon(Icons.chat_bubble_outline, color: Colors.white70),
              SizedBox(width: 6),
              Text(
                "1",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const Icon(Icons.share, color: Colors.white70),
          const Icon(Icons.playlist_play, color: Colors.white70),
          const Icon(Icons.more_vert, color: Colors.white70),
        ],
      ),
    );
  }
}
