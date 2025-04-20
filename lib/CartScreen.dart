import 'package:flutter/material.dart';
import 'package:login/Core/services/cliente_service.dart';
import 'package:login/PasarelaPagoScreen.dart';
import 'package:login/cart_provider.dart';
import 'package:provider/provider.dart';
import '../Core/model/cart_item.dart';
import 'package:login/ProductListScreen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? nombreCliente;
  bool _cargando = true;
  late CartProvider _carritoProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carritoProvider = Provider.of<CartProvider>(context);
  }

  @override
  void initState() {
    super.initState();
    _inicializarPantalla();
  }

  Future<void> _inicializarPantalla() async {
    await _cargarCliente();
    await _carritoProvider.cargarDesdeBackend();
    setState(() {
      _cargando = false;
    });
  }

  Future<void> _cargarCliente() async {
    final service = ClienteService();
    final nombre = await service.getNombreCliente();
    setState(() {
      nombreCliente = nombre ?? "Cliente no encontrado";
    });
  }

  @override
  Widget build(BuildContext context) {
    final double totalConDescuento = _carritoProvider.total;
    final DateTime fecha = _carritoProvider.fecha ?? DateTime.now();
    final String estado = _carritoProvider.estado ?? "Pendiente";

    final double subtotalSimulado = _carritoProvider.items.fold(
      0.0,
      (sum, item) => sum + (item.producto.precio * item.cantidad),
    );

    final double descuento = subtotalSimulado - totalConDescuento;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Carrito de Compras"),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ProductListScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: _carritoProvider.items.isEmpty
                  ? const Center(child: Text("El carrito está vacío."))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Cliente: \${nombreCliente ?? 'Cargando...'}", style: const TextStyle(fontSize: 16)),
                        Text("Fecha: \${fecha.toLocal().toString().split(' ')[0]}", style: const TextStyle(fontSize: 16)),
                        Text("Estado: \$estado", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        const Text("Productos:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _carritoProvider.items.length,
                            itemBuilder: (context, index) {
                              final CartItem item = _carritoProvider.items[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(item.producto.nombre),
                                  subtitle: Text(
                                    "Cantidad: \${item.cantidad} x Bs.\${item.producto.precio.toStringAsFixed(2)}\nSubtotal: Bs.\${item.subtotal.toStringAsFixed(2)}",
                                  ),
                                  isThreeLine: true,
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          _carritoProvider.updateCantidad(item, item.cantidad - 1);
                                        },
                                      ),
                                      Text('\${item.cantidad}'),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          final inventario = _carritoProvider.getInventarioProducto(item.producto.id);

                                          if (item.cantidad < inventario) {
                                            _carritoProvider.updateCantidad(item, item.cantidad + 1);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("No puedes agregar más, inventario insuficiente"),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          await _carritoProvider.removeItem(item);
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Producto eliminado del carrito"),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Subtotal sin descuento: Bs.\${subtotalSimulado.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                "Descuento aplicado: -Bs.\${descuento.toStringAsFixed(2)}",
                                style: TextStyle(fontSize: 16, color: descuento > 0 ? Colors.green : Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Total con descuento: Bs.\${totalConDescuento.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PasarelaPagoScreen(
                                        total: totalConDescuento,
                                        nombreCliente: nombreCliente ?? '',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.payment),
                                label: const Text("Pagar"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
