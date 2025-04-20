import 'package:flutter/material.dart';
import 'Core/model/cart_item.dart';
import 'Core/model/product.dart';
import 'Core/services/carrito_service.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final CarritoService _carritoService = CarritoService();
  int? _idCarrito;
  double _totalDesdeBackend = 0.0;
  DateTime? _fecha;
  String? _estado;

  List<CartItem> get items => _items;
  int? get idCarrito => _idCarrito;
  double get total => _totalDesdeBackend;
  DateTime? get fecha => _fecha;
  String? get estado => _estado;

  void setItems(List<CartItem> nuevosItems, {int? idCarrito}) {
    _items
      ..clear()
      ..addAll(nuevosItems);
    if (idCarrito != null) _idCarrito = idCarrito;
    notifyListeners();
  }

  final List<Product> _productosCompletos = [];

  void setProductosCompletos(List<Product> productos) {
    _productosCompletos
      ..clear()
      ..addAll(productos);
  }

  int getInventarioProducto(int idProducto) {
    final producto = _productosCompletos.firstWhere(
      (p) => p.id == idProducto,
      orElse: () => Product(id: 0, nombre: '', marca: '', categoria: '', precio: 0),
    );
    return producto.inventario;
  }

  Future<void> addProduct(Product product, int cantidad) async {
    if (_idCarrito == null) {
      _idCarrito = await _carritoService.crearCarrito();
      if (_idCarrito == null) return;
    }

    final idDetalle = await _carritoService.guardarDetalle(
      idCarrito: _idCarrito!,
      producto: product,
      cantidad: cantidad,
    );

    _items.add(CartItem(producto: product, cantidad: cantidad, idDetalle: idDetalle));
    await _actualizarDatosBackend();
    notifyListeners();
  }

  Future<void> updateCantidad(CartItem item, int nuevaCantidad) async {
    if (_idCarrito == null) {
      _idCarrito = await _carritoService.crearCarrito();
      if (_idCarrito == null) return;
    }

    if (nuevaCantidad <= 0) {
      await removeItem(item);
      return;
    }

    if (item.idDetalle != null) {
      await _carritoService.guardarDetalle(
        idCarrito: _idCarrito!,
        producto: item.producto,
        cantidad: nuevaCantidad,
        idDetalle: item.idDetalle,
      );
    }

    item.cantidad = nuevaCantidad;
    await _actualizarDatosBackend();
    notifyListeners();
  }

  Future<void> removeItem(CartItem item) async {
    if (_idCarrito == null) {
      _idCarrito = await _carritoService.crearCarrito();
      if (_idCarrito == null) return;
    }

    if (item.idDetalle != null) {
      await _carritoService.eliminarDetalle(item.idDetalle!);
    }

    _items.remove(item);
    await _actualizarDatosBackend();
    notifyListeners();
  }

  Future<void> cargarDesdeBackend() async {
    final carrito = await _carritoService.getCarritoActualCompleto();

    if (carrito != null) {
      _idCarrito = carrito['id_carrito'];
      _fecha = DateTime.tryParse(carrito['fecha']) ?? DateTime.now();
      _estado = carrito['estado'];
      _totalDesdeBackend = (carrito['total'] as num).toDouble();
      final detalles = await _carritoService.getDetallesDelCarrito(_idCarrito!);
      setItems(detalles);
    } else {
      _idCarrito = null;
      _fecha = null;
      _estado = null;
      _totalDesdeBackend = 0.0;
      _items.clear();
      notifyListeners();
    }
  }

  Future<void> _actualizarDatosBackend() async {
    final data = await _carritoService.getCarritoActualCompleto();
    if (data != null) {
      _totalDesdeBackend = (data['total'] as num).toDouble();
      _estado = data['estado'];
      _fecha = DateTime.tryParse(data['fecha']);
    }
  }
}
