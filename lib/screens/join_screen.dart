import 'package:flutter/material.dart';
import 'call_screen.dart';
import '../services/signalling.service.dart';

class JoinScreen extends StatefulWidget {
  final String selfCallerId; // ID único del usuario local.
   // Constructor que recibe el ID único del usuario.
  const JoinScreen({super.key, required this.selfCallerId}) ;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  // Variable para almacenar la oferta SDP de una llamada entrante.
  dynamic incomingSDPOffer;
   // Controlador para el campo de texto del ID del usuario remoto.
  final remoteCallerIdTextEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

     // Escucha eventos de llamadas entrantes desde el servidor de señalización.
    SignallingService.instance.socket!.on("newCall", (data) {
      if (mounted) {
        // Establece la oferta SDP de la llamada entrante.
        setState(() => incomingSDPOffer = data);
      }
    });
  }

  // Método para unirse a una llamada (saliente o entrante).
  _joinCall({
    required String callerId, // ID del llamador.
    required String calleeId, // ID del receptor.
    dynamic offer, // Oferta SDP opcional.
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Navega hacia la pantalla de llamada con los parámetros.
        builder: (_) => CallScreen(
          callerId: callerId,
          calleeId: calleeId,
          offer: offer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("P2P Call App"),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Muestra el Caller ID del usuario local.
                    TextField(
                      controller: TextEditingController(
                        text: widget.selfCallerId,
                      ),
                      readOnly: true,
                      textAlign: TextAlign.center,
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        labelText: "Your Caller ID",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remoteCallerIdTextEditingController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "Remote Caller ID",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                      ),
                      child: const Text(
                        "Invite",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        // Llama al método _joinCall con los IDs correspondientes.
                        _joinCall(
                           callerId: widget.selfCallerId, // ID del usuario local.
                          calleeId: remoteCallerIdTextEditingController.text, // ID del remoto.
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Si hay una oferta SDP entrante, muestra la UI de llamada entrante.
            if (incomingSDPOffer != null)
              Positioned(
                child: ListTile(
                  title: Text(
                    "Incoming Call from ${incomingSDPOffer["callerId"]}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call_end),
                        color: Colors.redAccent,
                        onPressed: () {
                          setState(() => incomingSDPOffer = null);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.call),
                        color: Colors.greenAccent,
                        onPressed: () {
                           // Navega a la pantalla de llamada con los datos de la oferta SDP.
                          _joinCall(
                              callerId: incomingSDPOffer["callerId"]!, // ID del llamador.
                            calleeId: widget.selfCallerId, // ID del usuario local.
                            offer: incomingSDPOffer["sdpOffer"], // Oferta SDP.
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
