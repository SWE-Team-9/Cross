import '../entities/message_entity.dart';
import '../repositories/messaging_repository.dart';

class SendTextMessageUseCase {
  final MessagingRepository repository;

  SendTextMessageUseCase(this.repository);

  Future<MessageEntity> call({
    required String receiverId,
    required String text,
  }) {
    return repository.sendTextMessage(
      receiverId: receiverId,
      text: text,
    );
  }
}