import '../entities/message_entity.dart';
import '../repositories/messaging_repository.dart';

class SharePlaylistMessageUseCase {
  final MessagingRepository repository;

  SharePlaylistMessageUseCase(this.repository);

  Future<MessageEntity> call({
    required String receiverId,
    required String playlistId,
    String? text,
  }) {
    return repository.sharePlaylist(
      receiverId: receiverId,
      playlistId: playlistId,
      text: text,
    );
  }
}
