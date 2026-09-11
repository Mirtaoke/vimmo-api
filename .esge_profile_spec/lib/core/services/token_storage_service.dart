import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
  static const _key = 'esge_access_token';
  Future<void> save(String token) async =>
      (await SharedPreferences.getInstance()).setString(_key, token);
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
