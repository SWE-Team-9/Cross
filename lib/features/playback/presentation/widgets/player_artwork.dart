import 'package:flutter/material.dart';

class PlayerArtwork extends StatelessWidget {
  final String? url;

  const PlayerArtwork(this.url);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        image: url != null
            ? DecorationImage(
                image: NetworkImage(url!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: url == null
          ? const Icon(Icons.music_note, color: Colors.white, size: 80)
          : null,
    );
  }
}
