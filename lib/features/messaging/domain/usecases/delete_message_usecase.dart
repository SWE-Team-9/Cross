import '../repositories/messaging_repository.dart';

class DeleteMessageUseCase {
  final MessagingRepository repository;

  DeleteMessageUseCase(this.repository);

  Future<void> call(String messageId) {
    return repository.deleteMessage(messageId);
  }
}
