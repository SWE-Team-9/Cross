import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Register core services
  getIt.registerSingleton<DioClient>(
    DioClient(baseUrl: const String.fromEnvironment('API_URL')),
  );

  // Feature dependencies will be added here as we build them
}
