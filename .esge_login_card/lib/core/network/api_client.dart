import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String? token;
  Future<Map<String, dynamic>> get(String path) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: _headers,
    );
    return _decode(response);
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  Map<String, dynamic> _decode(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Erreur serveur');
    }
    return data;
  }
}
