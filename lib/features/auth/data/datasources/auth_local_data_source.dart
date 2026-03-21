import '../../../../core/storage/secure_storage.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({required String access, required String refresh});
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorage secureStorage;

  AuthLocalDataSourceImpl(this.secureStorage);

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    await secureStorage.write(SecureStorage.accessTokenKey, access);
    await secureStorage.write(SecureStorage.refreshTokenKey, refresh);
  }

  @override
  Future<String?> getAccessToken() async {
    return await secureStorage.read(SecureStorage.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(SecureStorage.refreshTokenKey);
  }

  @override
  Future<void> clearAll() async {
    await secureStorage.clearAuthData();
  }
}