import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:login/cart_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:provider/provider.dart';


class PasarelaPagoScreen extends StatefulWidget {
  final double total;
  final String nombreCliente;

  const PasarelaPagoScreen({
    super.key,
    required this.total,
    required this.nombreCliente,
  });

  @override
  State<PasarelaPagoScreen> createState() => _PasarelaPagoScreenState();
}

class _PasarelaPagoScreenState extends State<PasarelaPagoScreen> {
  String? metodoSeleccionado;

  final List<String> metodos = [
    'PayPal',
    'Transferencia bancaria',
    'Pago con QR',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pasarela de Pago"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: metodoSeleccionado == null
            ? _buildMetodoSeleccion()
            : _buildFormularioSegunMetodo(metodoSeleccionado!),
      ),
    );
  }

  Widget _buildMetodoSeleccion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Selecciona un método de pago:", style: TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        ...metodos.map((metodo) {
          return ListTile(
            leading: const Icon(Icons.payment),
            title: Text(metodo),
            onTap: () {
              setState(() {
                metodoSeleccionado = metodo;
              });
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFormularioSegunMetodo(String metodo) {
    switch (metodo) {
      case 'PayPal':
        return _buildPayPal();
      case 'Transferencia bancaria':
        return _buildTransferencia();
      case 'Pago con QR':
        return _buildQR();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPayPal() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'lib/Core/image/paypal_logo.png', 
          height: 60,
        ),
        const SizedBox(height: 20),
        const Text("Pagar con PayPal", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text("Cliente: ${widget.nombreCliente}", style: const TextStyle(fontSize: 16)),
        Text("Total: Bs.${widget.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
        const Text("Será redirigido a la pasarela segura de PayPal", textAlign: TextAlign.center),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _procesarPagoPayPal,
          icon: const Icon(Icons.lock_outline),
          label: const Text("Continuar con PayPal"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          ),
        ),
      ],
    );
  }


  Widget _buildTransferencia() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.account_balance, size: 60),
        const SizedBox(height: 20),
        const Text("Transferencia Bancaria", style: TextStyle(fontSize: 20)),
        const SizedBox(height: 10),
        Text("Total: Bs.${widget.total.toStringAsFixed(2)}"),
        const SizedBox(height: 20),
        const Text("Banco: BNB\nNro. Cuenta: 12345678\nTitular: Tu Empresa S.R.L."),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _confirmarPago(3), // 3: Transferencia Bancaria
          child: const Text("Ya he realizado la transferencia"),
        ),
      ],
    );
  }

  Widget _buildQR() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.qr_code, size: 35),
        const SizedBox(height: 20),
        const Text("Escanea el QR para pagar", style: TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        Image.asset('lib/Core/image/qr_simulado.png', height: 400),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _descargarQR,
          icon: const Icon(Icons.download),
          label: const Text("Descargar QR"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _confirmarPago(1), // 1: QR
          child: const Text("Confirmar pago"),
        ),
      ],
    );
  }

  void _procesarPagoPayPal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Procesando pago..."),
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Conectando con PayPal..."),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      _confirmarPago(2); // 2: PayPal
    });
  }


  Future<void> _descargarQR() async {
    // Para Android 13 (permiso específico para imágenes)
    final status = await Permission.photos.request(); // Android 13+
    final legacy = await Permission.storage.request(); // Android 12-

    if (!status.isGranted && !legacy.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permiso denegado para guardar la imagen")),
      );
      return;
    }

    try {
      final byteData = await rootBundle.load('lib/Core/image/qr_simulado.png');
      final Uint8List bytes = byteData.buffer.asUint8List();

      final directory = await getExternalStorageDirectory();
      final downloadsPath = directory!.path.replaceFirst("Android/data", "Download");

      final filePath = '$downloadsPath/qr_pago_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR guardado correctamente 📥")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar el QR 😓")),
      );
    }
  }


  Future<void> _confirmarPago(int metodoPago) async {
    final carritoProvider = Provider.of<CartProvider>(context, listen: false);

    await _registrarFactura(metodoPago);

    // 🔁 Actualizar carrito y sus detalles desde el backend
    await carritoProvider.cargarDesdeBackend();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pago procesado exitosamente 🎉"),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pushNamedAndRemoveUntil('/products', (route) => false);
  }




  Future<void> _registrarFactura(int metodoPago) async {
    final carritoProvider = Provider.of<CartProvider>(context, listen: false);
    final int? idCarrito = carritoProvider.idCarrito;

    if (idCarrito == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: no se encontró el carrito")),
      );
      return;
    }

    final baseUrl = dotenv.env['API_URL'] ?? '';
    final url = Uri.parse('$baseUrl/cliente/facturaCarrito');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "id_carrito": idCarrito,
        "id_metodo_pago": metodoPago,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Factura registrada con éxito ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar factura: ${response.body}")),
      );
    }
  }

}
