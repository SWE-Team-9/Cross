import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioClient dioClient;
  late MockSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockSecureStorage();

    when(() => mockSecureStorage.read(any())).thenAnswer((_) async => null);

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '.';
      }
      return null;
    });

    dioClient = DioClient(
      baseUrl: 'https://api.test.com',
      secureStorage: mockSecureStorage,
    );
  });

  group('DioClient initialization', () {
    test('should initialize with correct base options', () {
      expect(dioClient.dio.options.baseUrl, 'https://api.test.com');
      expect(dioClient.dio.options.connectTimeout, const Duration(seconds: 30));
      expect(dioClient.dio.options.receiveTimeout, const Duration(seconds: 30));
      expect(dioClient.dio.options.headers['Content-Type'], isNull);
    });

    test('Dio instance should be initialized with interceptors', () {
      expect(dioClient.dio, isNotNull);
      expect(dioClient.dio.interceptors, isNotEmpty);
    });

    test('get request should use the correct baseUrl', () {
      expect(dioClient.dio.options.baseUrl, 'https://api.test.com');
    });
  });
}
