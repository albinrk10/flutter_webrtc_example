import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signalling.service.dart';

class CallScreen extends StatefulWidget {
  final String callerId, calleeId; // Identificadores del llamador y receptor.
  final dynamic offer; // Oferta SDP para llamadas entrantes.
  const CallScreen({
    super.key,
    this.offer, // Se proporciona solo en llamadas entrantes.
    required this.callerId, // ID del usuario que realiza la llamada.
    required this.calleeId, // ID del usuario que recibe la llamada.
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  // Instancia del servidor de señalización.
  final socket = SignallingService.instance.socket;

  // Renderizador de video para el usuario local.
  final _localRTCVideoRenderer = RTCVideoRenderer();

  // Renderizador de video para el usuario remoto.
  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  // Flujo de medios del usuario local.
  MediaStream? _localStream;

  // Conexión RTC para establecer comunicación P2P.
  RTCPeerConnection? _rtcPeerConnection;

  // Lista para almacenar candidatos ICE generados localmente.
  List<RTCIceCandidate> rtcIceCadidates = [];

  // Estados de medios: audio, video y selección de cámara (frontal o trasera).
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;

  @override
  void initState() {
    // Inicializa los renderizadores de video.
    _localRTCVideoRenderer.initialize();
    _remoteRTCVideoRenderer.initialize();

    // Configura la conexión P2P.
    _setupPeerConnection();
    super.initState();
  }

  @override
  void setState(fn) {
    // Asegura que el estado se actualice solo si el widget está montado.
    if (mounted) {
      super.setState(fn);
    }
  }

  // Configura la conexión RTC para comunicación P2P.
  _setupPeerConnection() async {
    // Crea una conexión RTC con servidores STUN configurados.
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          // Servidores STUN para resolver IP pública/privada.
          'urls': [
            'stun:stun1.l.google.com:19302', // Servidor STUN de Google.
            'stun:stun2.l.google.com:19302',
          ],
        },
        {
          // Servidor TURN para retransmitir datos si STUN falla.
          'urls':
              'turn:your.turn.server:3478', // Reemplaza con tu servidor TURN.
          'username': 'your-username', // Usuario del servidor TURN.
          'credential': 'your-password', // Contraseña del servidor TURN.
        },
      ],
    });

    // Escucha eventos de medios (tracks) del usuario remoto.
    _rtcPeerConnection!.onTrack = (event) {
      // Asigna el flujo del usuario remoto al renderizador correspondiente.
      _remoteRTCVideoRenderer.srcObject = event.streams[0];
      setState(() {}); // Actualiza la interfaz para mostrar el video remoto.
    };
    // Obtiene el flujo de medios locales (audio y video).
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio':
          isAudioOn, // Habilita o deshabilita el audio según el estado actual.
      'video': isVideoOn // Configura la cámara frontal o trasera.
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });

    // Agrega las pistas de medios locales a la conexión RTC.
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    // Asigna el flujo local al renderizador de video local.
    _localRTCVideoRenderer.srcObject = _localStream;
    setState(() {});

    // Manejo de llamadas entrantes.
    if (widget.offer != null) {
      // Escucha candidatos ICE del usuario remoto enviados por el servidor de señalización.
      socket!.on("IceCandidate", (data) {
        String candidate =
            data["iceCandidate"]["candidate"]; // Dirección del candidato ICE.
        String sdpMid = data["iceCandidate"]["id"]; // ID del SDP.
        int sdpMLineIndex =
            data["iceCandidate"]["label"]; // Índice de línea SDP.

        // Agrega el candidato ICE recibido a la conexión RTC.
        _rtcPeerConnection!.addCandidate(RTCIceCandidate(
          candidate,
          sdpMid,
          sdpMLineIndex,
        ));
      });

      // Configura la oferta SDP como descripción remota.
      await _rtcPeerConnection!.setRemoteDescription(
        RTCSessionDescription(widget.offer["sdp"], widget.offer["type"]),
      );

      // Crea una respuesta SDP para aceptar la conexión.
      RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();

      // Configura la respuesta SDP como descripción local.
      _rtcPeerConnection!.setLocalDescription(answer);

      // Envía la respuesta SDP al usuario remoto mediante el servidor de señalización.
      socket!.emit("answerCall", {
        "callerId": widget.callerId,
        "sdpAnswer": answer.toMap(),
      });
    } else {
      // Llamadas salientes: escucha candidatos ICE generados localmente.
      _rtcPeerConnection!.onIceCandidate =
          (RTCIceCandidate candidate) => rtcIceCadidates.add(candidate);

      // Escucha cuando el receptor responde a la llamada.
      socket!.on("callAnswered", (data) async {
        // Configura la respuesta SDP recibida como descripción remota.
        await _rtcPeerConnection!.setRemoteDescription(
          RTCSessionDescription(
            data["sdpAnswer"]["sdp"],
            data["sdpAnswer"]["type"],
          ),
        );

        // Envía candidatos ICE generados al receptor mediante el servidor.
        for (RTCIceCandidate candidate in rtcIceCadidates) {
          socket!.emit("IceCandidate", {
            "calleeId": widget.calleeId,
            "iceCandidate": {
              "id": candidate.sdpMid,
              "label": candidate.sdpMLineIndex,
              "candidate": candidate.candidate
            }
          });
        }
      });

      // Genera y envía una oferta SDP para iniciar la llamada.
      RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();
      await _rtcPeerConnection!.setLocalDescription(offer);

      socket!.emit('makeCall', {
        "calleeId": widget.calleeId, // ID del receptor.
        "sdpOffer": offer.toMap(), // Oferta SDP.
      });
    }
  }

  // Finaliza la llamada.
  _leaveCall() {
    Navigator.pop(context); // Cierra la pantalla de llamada.
  }

  // Habilita o deshabilita el micrófono.
  _toggleMic() {
    isAudioOn = !isAudioOn; // Cambia el estado del audio.
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn; // Activa o desactiva las pistas de audio.
    });
    setState(() {});
  }

  // Habilita o deshabilita la cámara.
  _toggleCamera() {
    isVideoOn = !isVideoOn; // Cambia el estado del video.
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn; // Activa o desactiva las pistas de video.
    });
    setState(() {});
  }

  // Cambia entre la cámara frontal y trasera.
  _switchCamera() {
    // Cambia el estado de la cámara.
    isFrontCameraSelected = !isFrontCameraSelected;

    _localStream?.getVideoTracks().forEach((track) {
      // Cambia la cámara activa.
      track.switchCamera();
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("P2P Call App"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(children: [
                RTCVideoView(
                  _remoteRTCVideoRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: SizedBox(
                    height: 150,
                    width: 120,
                    child: RTCVideoView(
                      _localRTCVideoRenderer,
                      mirror: isFrontCameraSelected,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                )
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(isAudioOn ? Icons.mic : Icons.mic_off),
                    onPressed: _toggleMic,
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end),
                    iconSize: 30,
                    onPressed: _leaveCall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cameraswitch),
                    onPressed: _switchCamera,
                  ),
                  IconButton(
                    icon: Icon(isVideoOn ? Icons.videocam : Icons.videocam_off),
                    onPressed: _toggleCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Libera los recursos de los renderizadores y la conexión RTC.
    _localRTCVideoRenderer.dispose();
    _remoteRTCVideoRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();
    super.dispose();
  }
}
