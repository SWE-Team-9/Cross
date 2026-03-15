import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Write a value
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Read a value
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  // Delete a value
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  // Check if key exists
  Future<bool> containsKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }

  // Get all keys
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  // Clear all storage
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
