import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const secureStorage = FlutterSecureStorage();

class SecureSessionStorage extends LocalStorage {
  static const _key = 'kin.auth.session';
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async =>
      await secureStorage.containsKey(key: _key);
  @override
  Future<String?> accessToken() => secureStorage.read(key: _key);
  @override
  Future<void> removePersistedSession() => secureStorage.delete(key: _key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      secureStorage.write(key: _key, value: persistSessionString);
}

class SecurePkceStorage extends GotrueAsyncStorage {
  @override
  Future<String?> getItem({required String key}) =>
      secureStorage.read(key: 'kin.pkce.$key');
  @override
  Future<void> removeItem({required String key}) =>
      secureStorage.delete(key: 'kin.pkce.$key');
  @override
  Future<void> setItem({required String key, required String value}) =>
      secureStorage.write(key: 'kin.pkce.$key', value: value);
}
