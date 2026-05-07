import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pages/sales_page.dart';
import 'services/app_logger.dart';
import 'services/sales_remote_service.dart';
import 'services/sales_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    AppLogger.info('Firebase inicializado');
  } catch (e) {
    AppLogger.error('Error inicializando Firebase', error: e);
  }

  final remoteService = SalesRemoteService();
  final repository = SalesRepository(remoteService: remoteService);

  runApp(SalesApp(repository: repository));
}

class SalesApp extends StatelessWidget {
  final SalesRepository repository;

  const SalesApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Registro de Ventas',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: SalesPage(repository: repository),
    );
  }
}