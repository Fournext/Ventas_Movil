import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:login/Core/model/product.dart';
import 'package:login/cart_provider.dart';
import '../model/cart_item.dart';
import '../services/cliente_service.dart';

class CarritoService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';
  final ClienteService _clienteService = ClienteService();

  Future<int?> crearCarrito() async {
    final idCliente = await _clienteService.getIdCliente();
    if (idCliente == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/cliente/guardarCarrito'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_cliente': idCliente,
        'total': 0,
        'fecha': DateTime.now().toIso8601String().split('T').first,
        'estado': 'Pendiente',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final idStr = data['id_carrito'];
      return int.tryParse(idStr.toString());
    } else {
      return null;
    }
  }

  Future<int?> guardarDetalle({
    required int idCarrito,
    required Product producto,
    required int cantidad,
    int? idDetalle,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cliente/guardarDetalleCarrito'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_carrito': idCarrito,
        'id_producto': producto.id,
        'cantidad': cantidad,
        'precio_unitario': producto.precio,
        'subtotal': producto.precio * cantidad,
        if (idDetalle != null) 'id_detalle': idDetalle,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id_detalle'];
    } else {
      return null;
    }
  }

  Future<void> eliminarDetalle(int idDetalle) async {
    await http.delete(Uri.parse('$baseUrl/cliente/eliminarDetalleCarrito/$idDetalle'));
  }

  Future<Map<String, dynamic>?> getCarritoActualCompleto() async {
    final idCliente = await _clienteService.getIdCliente();
    if (idCliente == null) return null;

    final response = await http.get(Uri.parse('$baseUrl/cliente/getCarritoCliente/$idCliente'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data; // Contiene id_carrito, total, fecha, estado
    }
    return null;
  }

  Future<List<CartItem>> getDetallesDelCarrito(int idCarrito) async {
    final response = await http.get(Uri.parse('$baseUrl/cliente/getDetalleCarritoCliente/$idCarrito'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> data = jsonData['detalles'];

      return data.map((item) {
        return CartItem(
          idDetalle: item['id_detalle'],
          producto: Product(
            id: item['id_producto'] ?? 0,
            nombre: item['descripcion_producto'],
            precio: (item['precio_unitario'] as num).toDouble(),
            imagenUrl: '',
            marca: 'Desconocida',
            categoria: 'General',
          ),
          cantidad: item['cantidad'],
        );
      }).toList();
    }

    return [];
  }

  Future<void> cargarCarritoAlProvider(CartProvider carritoProvider) async {
    final data = await getCarritoActualCompleto();
    if (data == null) return;

    final detalles = await getDetallesDelCarrito( data['id_carrito']);
    carritoProvider.setItems(detalles, idCarrito: data['id_carrito']);
  }
}
