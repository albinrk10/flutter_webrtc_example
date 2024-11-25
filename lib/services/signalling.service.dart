import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart';

class SignallingService {
  // Instancia de Socket.IO para comunicarse con el servidor de señalización.
  Socket? socket;

  // Constructor privado para implementar el patrón singleton.
  SignallingService._();

  // Instancia estática única de la clase (patrón singleton).
  static final instance = SignallingService._();

  // Método para inicializar el servicio de señalización.
  init({required String websocketUrl, required String selfCallerID}) {
    // Inicializa la conexión al servidor de señalización mediante Socket.IO.
    socket = io(websocketUrl, {
      // Configura el transporte usando websockets.
      "transports": ['websocket'],
      // Envía el ID del usuario como consulta al servidor.
      "query": {"callerId": selfCallerID}
    });

    // Escucha el evento de conexión exitosa al servidor.
    socket!.onConnect((data) {
      log("Socket connected !!"); // Muestra un mensaje cuando se establece la conexión.
    });

    // Escucha el evento de error al intentar conectar con el servidor.
    socket!.onConnectError((data) {
      log("Connect Error $data"); // Registra el error en los logs.
    });

    // Establece la conexión al servidor de señalización.
    socket!.connect();
  }
}
