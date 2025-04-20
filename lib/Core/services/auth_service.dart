import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/usuario/login'); // o el endpoint que uses
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token']; // asegúrate que tu API devuelve 'token'

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);

      return true;
    } else {
      return false;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<String?> getTipoUsuario(String username) async {
  final url = Uri.parse('$baseUrl/usuario/tipo_usuario/$username');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['tipo_usuario']; // asegúrate de que la API devuelve algo como: { "tipo": "cliente" }
  } else {
    return null;
  }
}

}
