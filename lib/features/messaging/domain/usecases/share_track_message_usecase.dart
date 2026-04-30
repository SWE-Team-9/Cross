import '../entities/message_entity.dart';
import '../repositories/messaging_repository.dart';

class ShareTrackMessageUseCase {
  final MessagingRepository repository;

  ShareTrackMessageUseCase(this.repository);

  Future<MessageEntity> call({
    required String receiverId,
    required String trackId,
    String? text,
  }) {
    return repository.shareTrack(
      receiverId: receiverId,
      trackId: trackId,
      text: text,
    );
  }
}
