import 'package:flutter/material.dart';

import 'screens/search_screen.dart';
import 'services/cptec_service.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PrevisaoApp());
}

class PrevisaoApp extends StatefulWidget {
  const PrevisaoApp({super.key});

  @override
  State<PrevisaoApp> createState() => _PrevisaoAppState();
}

class _PrevisaoAppState extends State<PrevisaoApp> {
  final _service = CptecService();
  final _storage = StorageService();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Previsão do Tempo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1976D2),
      ),
      home: SearchScreen(service: _service, storage: _storage),
    );
  }
}
