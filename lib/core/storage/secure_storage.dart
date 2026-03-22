import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  // الثوابت الثابتة للمفاتيح لضمان عدم الخطأ في التسمية
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<bool> containsKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }

  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }

  // دالة مريحة لمسح بيانات الدخول فقط عند تسجيل الخروج أو انتهاء الجلسة
  Future<void> clearAuthData() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
  }
}
