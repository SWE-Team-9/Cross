import '../entities/realtime_message_event_entity.dart';
import '../repositories/messaging_realtime_repository.dart';

class ConnectMessagingSocketUseCase {
  final MessagingRealtimeRepository repository;

  ConnectMessagingSocketUseCase(this.repository);

  Stream<RealtimeMessageEventEntity> get eventsStream =>
      repository.eventsStream;

  Future<void> call() {
    return repository.connect();
  }

  Future<void> disconnect() {
    return repository.disconnect();
  }
}