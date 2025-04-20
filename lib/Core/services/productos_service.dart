import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/product.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductosService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<List<Product>> getProductos() async {
    final response = await http.get(Uri.parse("$baseUrl/producto/getProductosFiltro"));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Product> productos = [];

      for (var jsonProducto in data) {
        final producto = Product.fromJson(jsonProducto);
        producto.imagenUrl = await _getImagenUrl(producto.id);
        producto.inventario = await _fetchInventario(producto.id);
        productos.add(producto);
      }

      return productos;
    } else {
      throw Exception("Error al cargar productos");
    }
  }

  Future<String> _getImagenUrl(int idProducto) async {
    final response = await http.get(Uri.parse("$baseUrl/producto/getImagen/$idProducto"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['url'] ?? '';
    } else {
      return '';
    }
  }

  Future<int> _fetchInventario(int idProducto) async {
    final response = await http.get(Uri.parse('$baseUrl/inventario/getInventarioProducto/$idProducto'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['cantidad'] ?? 0;
    }
    return 0;
  }
}
