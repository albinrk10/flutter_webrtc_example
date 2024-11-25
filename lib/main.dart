import 'dart:math';
import 'package:flutter/material.dart';
import 'screens/join_screen.dart';
import 'services/signalling.service.dart';

void main() {
  // Ejecuta la aplicación llamando a la clase principal `VideoCallApp`.
  runApp(VideoCallApp());
}

class VideoCallApp extends StatelessWidget {
  VideoCallApp({super.key});

  // URL del servidor de señalización (websocket).
  final String websocketUrl = "https://2685-38-25-18-97.ngrok-free.app"; //http://192.168.56.1:3000

  // Genera un ID único aleatorio para identificar al usuario local.
  // Esto se usa como el `callerID` del usuario actual.
  final String selfCallerID =
      Random().nextInt(999999).toString().padLeft(6, '0');

  @override
  Widget build(BuildContext context) {
     // Inicializa el servicio de señalización con la URL del servidor y el ID local.
    SignallingService.instance.init(
      websocketUrl: websocketUrl, // URL del servidor de señalización.
      selfCallerID: selfCallerID, // ID único generado para el usuario local.
    );

    // return material app
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(),
      ),
      themeMode: ThemeMode.dark,
      home: JoinScreen(selfCallerId: selfCallerID),// Pantalla inicial.
    );
  }
}
