import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Register SecureStorage first
  getIt.registerSingleton<SecureStorage>(SecureStorage());
  
  // Then register DioClient with secureStorage
  getIt.registerSingleton<DioClient>(
    DioClient(
      baseUrl: 'https://api.example.com',
      secureStorage: getIt<SecureStorage>(),  // ← Pass the registered instance!
    ),
  );
}