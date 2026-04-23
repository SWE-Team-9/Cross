import '../../domain/entities/realtime_message_event_entity.dart';
import '../../domain/repositories/messaging_realtime_repository.dart';
import '../datasources/messaging_socket_data_source.dart';

class MessagingRealtimeRepositoryImpl implements MessagingRealtimeRepository {
  final MessagingSocketDataSource socketDataSource;

  MessagingRealtimeRepositoryImpl(this.socketDataSource);

  @override
  Stream<RealtimeMessageEventEntity> get eventsStream =>
      socketDataSource.eventsStream.map((event) => event.toEntity());

  @override
  Future<void> connect() => socketDataSource.connect();

  @override
  Future<void> disconnect() => socketDataSource.disconnect();
}