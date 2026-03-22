import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';
import 'package:flutter/services.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  // تهيئة الـ Binding ضرورية للتعامل مع الـ BinaryMessenger
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioClient dioClient;
  late MockSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockSecureStorage();

    // الطريقة الجديدة لإعداد الـ MockMethodCallHandler لتجنب الـ Deprecated warning
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '.'; // إرجاع المسار الحالي كمسار وهمي
      }
      return null;
    });

    dioClient = DioClient(
      baseUrl: 'https://api.test.com',
      secureStorage: mockSecureStorage,
    );
  });

  group('DioClient Integration Tests', () {
    test('Dio instance should be initialized with interceptors', () {
      expect(dioClient.dio, isNotNull);
      // التأكد من إضافة الـ interceptors الأساسية (Cookie, Auth, Error, Logging)
      expect(dioClient.dio.interceptors.length, isNot(0));
    });

    test('get request should use the correct baseUrl', () {
      expect(dioClient.dio.options.baseUrl, 'https://api.test.com');
    });
  });
}
