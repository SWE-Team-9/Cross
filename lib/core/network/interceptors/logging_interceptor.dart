import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  // ← Changed from ErrorInterceptor to LoggingInterceptor
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('Request: ${options.method} ${options.path}');
    print('Headers: ${options.headers}');
    if (options.data != null) {
      print('Data: ${options.data}');
    }
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('Response: ${response.statusCode} ${response.requestOptions.path}');
    print('Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('Error: ${err.message}');
    print('Status Code: ${err.response?.statusCode}');
    print('Response: ${err.response?.data}');
    handler.next(err);
  }
}
