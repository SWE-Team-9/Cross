import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/network/interceptors/auth_interceptor.dart';
import 'package:soundcloud_clone/core/network/interceptors/error_interceptor.dart';
import 'package:soundcloud_clone/core/network/interceptors/logging_interceptor.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late DioClient dioClient;
  late DioAdapter dioAdapter;
  late MockSecureStorage mockSecureStorage;

  const testBaseUrl = 'https://api.test.com';

  setUp(() {
    mockSecureStorage = MockSecureStorage();

    //  Setup default mock behavior
    when(() => mockSecureStorage.read(any())).thenAnswer((_) async => null);

    // Create DioClient with test URL
    dioClient = DioClient(
      baseUrl: testBaseUrl,
      secureStorage: mockSecureStorage,
    );

    // Create DioAdapter for mocking responses
    dioAdapter = DioAdapter(dio: dioClient.dio);
  });

  group('DioClient initialization', () {
    test('should initialize with correct base options', () {
      expect(dioClient.dio.options.baseUrl, testBaseUrl);
      expect(dioClient.dio.options.connectTimeout, const Duration(seconds: 30));
      expect(dioClient.dio.options.receiveTimeout, const Duration(seconds: 30));
      expect(dioClient.dio.options.headers['Content-Type'], 'application/json');
    });

    test('should have all interceptors registered', () {
      final interceptors = dioClient.dio.interceptors;

      expect(interceptors, isNotEmpty);
      expect(interceptors[interceptors.length - 3], isA<AuthInterceptor>());
      expect(interceptors[interceptors.length - 2], isA<ErrorInterceptor>());
      expect(interceptors[interceptors.length - 1], isA<LoggingInterceptor>());
    });
  });

  group('GET requests', () {
    test('should perform GET request successfully', () async {
      const path = '/test';
      const responseData = {'message': 'success'};

      dioAdapter.onGet(
        path,
        (server) => server.reply(200, responseData),
      );

      final response = await dioClient.get(path);

      expect(response.statusCode, 200);
      expect(response.data, responseData);
    });

    test('should throw mapped error on GET failure', () async {
      const path = '/test';

      dioAdapter.onGet(
        path,
        (server) => server.reply(404, {'message': 'Not found'}),
      );

      expect(
        () async => await dioClient.get(path),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('POST requests', () {
    test('should perform POST request successfully', () async {
      const path = '/test';
      const requestData = {'name': 'test'};
      const responseData = {'id': 1, 'name': 'test'};

      dioAdapter.onPost(
        path,
        (server) => server.reply(201, responseData),
        data: requestData,
      );

      final response = await dioClient.post(path, data: requestData);

      expect(response.statusCode, 201);
      expect(response.data, responseData);
    });
  });

  group('PUT requests', () {
    test('should perform PUT request successfully', () async {
      const path = '/test/1';
      const requestData = {'name': 'updated'};
      const responseData = {'id': 1, 'name': 'updated'};

      dioAdapter.onPut(
        path,
        (server) => server.reply(200, responseData),
        data: requestData,
      );

      final response = await dioClient.put(path, data: requestData);

      expect(response.statusCode, 200);
      expect(response.data, responseData);
    });
  });

  group('DELETE requests', () {
    test('should perform DELETE request successfully', () async {
      const path = '/test/1';

      dioAdapter.onDelete(
        path,
        (server) => server.reply(204, null),
      );

      final response = await dioClient.delete(path);

      expect(response.statusCode, 204);
    });
  });

  group('PATCH requests', () {
    test('should perform PATCH request successfully', () async {
      const path = '/test/1';
      const requestData = {'name': 'patched'};
      const responseData = {'id': 1, 'name': 'patched'};

      dioAdapter.onPatch(
        path,
        (server) => server.reply(200, responseData),
        data: requestData,
      );

      final response = await dioClient.patch(path, data: requestData);

      expect(response.statusCode, 200);
      expect(response.data, responseData);
    });
  });
}
