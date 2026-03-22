import 'dart:convert';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/repositories/profile_repository.dart';
import '../dto/profile_dto.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileDto> getProfile(String handle);
  Future<ProfileDto> updateProfile(Map<String, dynamic> body);
  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  });
  Future<bool> checkHandleAvailable(String handle);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient _dioClient;

  const ProfileRemoteDataSourceImpl(this._dioClient);

  @override
  Future<ProfileDto> getProfile(String handle) async {
    try {
      // استخدمنا .dio.get لضمان عمل الدالة
      final response = await _dioClient.dio.get(
        '/api/v1/profiles/$handle',
      );

      // تأمين تحويل البيانات لو السيرفر رجعها كـ String
      final responseData = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;

      // أحياناً السيرفر بيرجع البيانات جوه مفتاح 'profile' أو 'data'
      final Map<String, dynamic> profileMap = responseData['profile'] ?? responseData['data'] ?? responseData;

      return ProfileDto.fromJson(profileMap);
    } catch (e) {
      // السطر ده هيطبع الإيرور الحقيقي في الـ Debug Console عشان لو حصل مشكلة تاني نعرفها فوراً
      print('🔥 Error in getProfile: $e');
      rethrow;
    }
  }

  @override
  Future<ProfileDto> updateProfile(Map<String, dynamic> body) async {
    try {
      final response = await _dioClient.dio.patch(
        '/api/v1/profiles/me',
        data: body,
      );
      
      final responseData = response.data is String ? jsonDecode(response.data) : response.data;
      final Map<String, dynamic> profileMap = responseData['profile'] ?? responseData['data'] ?? responseData;
      
      return ProfileDto.fromJson(profileMap);
    } catch (e) {
      print('🔥 Error in updateProfile: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadProfileImage({
    required ProfileImageType imageType,
    required String filePath,
  }) async {
    try {
      final typeString = imageType == ProfileImageType.AVATAR ? 'avatar' : 'cover';

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dioClient.dio.post(
        '/api/v1/profiles/me/images/$typeString',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final responseData = response.data is String ? jsonDecode(response.data) : response.data;
      return responseData['url'] as String;
    } catch (e) {
      print('🔥 Error in uploadProfileImage: $e');
      rethrow;
    }
  }

  @override
  Future<bool> checkHandleAvailable(String handle) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/v1/profiles/check-handle',
        queryParameters: {'handle': handle},
      );
      
      final responseData = response.data is String ? jsonDecode(response.data) : response.data;
      return responseData['available'] as bool;
    } catch (e) {
      print('🔥 Error in checkHandleAvailable: $e');
      rethrow;
    }
  }
}