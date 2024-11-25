# Flutter WebRTC Example

Este proyecto es una aplicación de videollamadas punto a punto (P2P) utilizando **Flutter** y **WebRTC**. Incluye soporte para servidores STUN y la capacidad de extenderlo con un servidor TURN. Se basa en un servidor de señalización para intercambiar información inicial entre los usuarios.

---

## Características

- Videollamadas P2P en tiempo real.
- Manejo de audio, video y cambio de cámara (frontal/trás).
- Uso de servidores STUN para la negociación de conexión.
- Configurable con un servidor TURN para redes más restrictivas.
- Implementación de servidor de señalización con Socket.IO.

---

## Requisitos previos

### 1. **Instalación de Flutter**
- Asegúrate de tener Flutter instalado. Consulta la [documentación oficial](https://docs.flutter.dev/get-started/install) para más detalles.

### 2. **Servidor de señalización**
- Este proyecto requiere un servidor de señalización que soporte **Socket.IO**. Puedes usar un servidor Node.js básico o uno que ya tengas configurado.

### 3. **Servidor STUN/TURN (opcional)**
- Este ejemplo utiliza servidores STUN de Google configurados en el proyecto.
- Para redes más restrictivas, puedes configurar tu propio servidor TURN.
  ![b03f697f-320e-4146-b8a0-f463e6c07703](https://github.com/user-attachments/assets/9c153d2c-3d35-44bd-ac04-7a0c0f316a75)


---

## Configuración

### 1. **Clonar el repositorio**
Clona el proyecto en tu máquina local:
```bash
git clone https://github.com/albinrk10/flutter_webrtc_example.git
cd flutter_webrtc_example
