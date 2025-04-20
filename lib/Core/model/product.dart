class Product {
  final int id;
  final String nombre;
  final String marca;
  final String categoria;
  String imagenUrl;
  final double precio;
  int inventario;

  Product({
    required this.id,
    required this.nombre,
    required this.marca,
    required this.categoria,
    this.imagenUrl = '',
    required this.precio,
    this.inventario=0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      nombre: json['descripcion'],
      marca: json['marca'],
      categoria: json['categoria'],
      precio: (json['precio'] as num).toDouble(),
    );
  }
}
