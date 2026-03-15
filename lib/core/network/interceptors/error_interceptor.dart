import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log errors
    print('Dio Error: ${err.message}');
    print('Status Code: ${err.response?.statusCode}');
    print('Response: ${err.response?.data}');
    
    handler.next(err);
  }
}