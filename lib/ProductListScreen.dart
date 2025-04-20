import 'package:flutter/material.dart';
import 'package:login/CartScreen.dart';
import 'package:login/Core/model/product.dart';
import 'package:login/Core/services/productos_service.dart';
import 'package:login/cart_provider.dart';
import 'package:provider/provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductosService _productosService = ProductosService();
  late Future<List<Product>> _futureProductos;

  @override
  void initState() {
    super.initState();
    _futureProductos = _productosService.getProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Productos"),
        backgroundColor: Colors.deepPurple,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          )
        ],
      ),
      backgroundColor: const Color(0xFFF1F1F1),
      endDrawer: _buildDrawer(context),
      body: FutureBuilder<List<Product>>(
        future: _futureProductos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }

          final productos = snapshot.data ?? [];
          Provider.of<CartProvider>(context, listen: false).setProductosCompletos(productos);


          if (productos.isEmpty) {
            return const Center(child: Text('No hay productos disponibles.'));
          }

          return Padding(
            padding: const EdgeInsets.all(10),
            child: GridView.builder(
              itemCount: productos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final product = productos[index];
                return GestureDetector(
                  onTap: () => _showAddToCartDialog(context, product),
                  child: _buildProductCard(product),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: product.imagenUrl.isEmpty
                  ? Image.asset('lib/Core/image/default_image.png', fit: BoxFit.cover)
                  : Image.network(
                      product.imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('lib/Core/image/default_image.png', fit: BoxFit.cover);
                      },
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              product.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          Text("Stock: ${product.inventario}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.green)),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Bs.${product.precio.toStringAsFixed(2)}",
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToCartDialog(BuildContext context, Product product) {
    final cantidadController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Añadir al carrito"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("¿Cuántas unidades de '${product.nombre}' desea añadir? (Máximo: ${product.inventario})"),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Cantidad"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final cantidad = int.tryParse(cantidadController.text) ?? 1;
              if (cantidad > product.inventario || cantidad <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Cantidad inválida. Stock disponible: ${product.inventario}")),
                );
                return;
              }
              Provider.of<CartProvider>(context, listen: false).addProduct(product, cantidad);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${product.nombre} añadido al carrito.")),
              );
            },
            child: const Text("Añadir"),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text('Menú de Opciones', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Carrito de Compras'),
            onTap: () async {
              await Provider.of<CartProvider>(context, listen: false).cargarDesdeBackend();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.filter_alt),
            title: const Text('Filtros'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}