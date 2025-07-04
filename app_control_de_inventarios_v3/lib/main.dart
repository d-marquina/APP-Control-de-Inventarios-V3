import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: InventoryApp(),
    theme: ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
    ),
  ));
}

class InventoryApp extends StatefulWidget {
  const InventoryApp({super.key});

  @override
  _InventoryAppState createState() => _InventoryAppState();
}

class _InventoryAppState extends State<InventoryApp> {
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  String _selectedAction = "add";

  final String scriptURL = "https://script.google.com/macros/s/AKfycbwhpBerodBbt5l0JEI8P1TGbyQpsLcdq0c-2VXLW9Vzpc9d90wNjz1XAlB8vCstv5FWKw/exec";

  Future<void> addItem() async {
    final modelo = _modeloController.text.trim();
    final marca = _marcaController.text.trim();
    final color = _colorController.text.trim();

    final body = jsonEncode({
      "action": "addItem",
      "modelo": modelo,
      "marca": marca,
      "color": color,
    });

    try {
      final response = await http.post(
        Uri.parse(scriptURL),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final bodyText = response.body.contains("Moved Temporarily")
          ? "🔁 Redireccionamiento activado"
          : response.body;

      print("📅 Respuesta final:\n$bodyText");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Item agregado")),
        );
      }
    } catch (e) {
      print("❌ Error al enviar datos: \$e");
    }
  }

  Future<void> scanCodeAndSend(String action) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          scriptURL: scriptURL,
          action: action,
        ),
      ),
    );
  }

  InputDecoration _customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.blueAccent.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📦 Control de Inventario"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📝 Registrar un producto", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: _modeloController,
              decoration: _customInputDecoration("Modelo"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _marcaController,
              decoration: _customInputDecoration("Marca"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _colorController,
              decoration: _customInputDecoration("Color"),
            ),
            const SizedBox(height: 16),
            Text("¿Qué acción deseas realizar?", style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedAction,
                  items: const [
                    DropdownMenuItem(value: "add", child: Text("📥 Ingresar")),
                    DropdownMenuItem(value: "remove", child: Text("📤 Retirar")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedAction = value;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: addItem,
                  icon: Icon(Icons.add_box),
                  label: Text("Agregar", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => scanCodeAndSend(_selectedAction),
                  icon: Icon(Icons.qr_code_scanner),
                  label: Text("Escanear", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  final String scriptURL;
  final String action;

  const QRScannerScreen({super.key, required this.scriptURL, required this.action});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleScan(String code) async {
    if (_scanned) return;
    _scanned = true;

    await controller.stop();

    final body = jsonEncode({
      "action": widget.action,
      "code": code,
    });

    try {
      final response = await http.post(
        Uri.parse(widget.scriptURL),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final isHtml = response.body.trim().toLowerCase().startsWith("<!doctype html") ||
          response.body.trim().toLowerCase().startsWith("<html");

      final mensaje = isHtml ? "🔁 Redireccionamiento activado" : response.body;

      if (mounted) {
        print("🔄 Código de estado: \${response.statusCode}");
        print("📅 Respuesta final:\n$mensaje");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        print("❌ Error: \$e");
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Escanear QR")),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final String? code = barcode.rawValue;
          if (code != null) {
            _handleScan(code);
          }
        },
      ),
    );
  }
}
