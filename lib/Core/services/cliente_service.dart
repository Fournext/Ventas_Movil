import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class ClienteService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  // 🔁 Devuelve todos los datos del cliente
  Future<Map<String, dynamic>?> getClienteDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return null;

    final decodedToken = JwtDecoder.decode(token);
    final idUsuario = decodedToken['id']; // asegúrate que sea 'id'

    final response = await http.get(Uri.parse('$baseUrl/cliente/getcliente_Usuario/$idUsuario'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }

  // 📌 Obtiene solo el nombre completo
  Future<String?> getNombreCliente() async {
    final data = await getClienteDatos();
    return data?['nombre_completo'];
  }

  // 📌 Obtiene solo el ID del cliente
  Future<int?> getIdCliente() async {
    final data = await getClienteDatos();
    return data?['id_cliente'];
  }

  // (Opcional) 📌 También puedes obtener dirección, teléfono, etc.
  Future<String?> getTelefonoCliente() async {
    final data = await getClienteDatos();
    return data?['telefono'];
  }

  Future<String?> getDireccionCliente() async {
    final data = await getClienteDatos();
    return data?['direccion'];
  }
}
