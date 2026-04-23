import '../entities/realtime_message_event_entity.dart';

abstract class MessagingRealtimeRepository {
  Stream<RealtimeMessageEventEntity> get eventsStream;

  Future<void> connect();

  Future<void> disconnect();
}