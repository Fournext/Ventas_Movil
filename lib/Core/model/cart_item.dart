import 'product.dart';

class CartItem {
  final int? idDetalle; // ID del detalle en la base de datos
  final Product producto;
  int cantidad;

  CartItem({
    required this.producto,
    required this.cantidad,
    this.idDetalle,
  });

  double get subtotal => cantidad * producto.precio;
}
