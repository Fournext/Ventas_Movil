import 'package:flutter/material.dart';
import 'package:login/LoginScreen.dart';
import 'package:login/ProductListScreen.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:login/cart_provider.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ERP_Supermercado',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/products': (context) => ProductListScreen(),
      },
    );
  }
}
