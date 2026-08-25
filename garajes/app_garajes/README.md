# GarajeUCB - Cliente Móvil (Flutter)

## Descripción

Aplicación móvil multiplataforma desarrollada en Flutter para gestionar la interacción de los usuarios con el sistema GarajeUCB. Permite registrarse, buscar garajes, gestionar perfiles de arrendador o arrendatario, realizar reservas, chatear y administrar la billetera financiera de forma intuitiva y robusta.

## Objetivo General

Proveer una interfaz de usuario atractiva, eficiente y reactiva mediante el sistema de gestión de estados Riverpod, consumiendo la API REST centralizada y manejando comunicación en tiempo real vía WebSockets para los eventos de chat.

## Objetivos Específicos

- Consumo de API REST utilizando librerías estandarizadas y manejo unificado de excepciones.
- Gestión de estado global y local utilizando el ecosistema Riverpod para garantizar la inmutabilidad y la reactividad de la UI.
- Implementación de flujos de autenticación segura (JWT) y redirecciones automáticas en la aplicación.
- Construcción modular basada en funcionalidades (Features).
- Integración de la pasarela de cámara para envío de evidencias KYC, Check-In y Check-Out.
- Conexión persistente mediante Socket.io para el sistema de soporte y chat entre pares.

## Alcance Frontend

**Funcionalidades del Sistema:**
- Subsistema de Autenticación: Login, Registro, Integración con Google Sign-In y Flujos de Verificación de Identidad (KYC).
- Dashboard Bimodal: Alternancia de interfaz dependiendo del rol en tiempo de ejecución (Arrendatario o Dueño).
- Listado y filtrado avanzado de establecimientos utilizando servicios de geolocalización o parámetros temporales.
- Flujo interactivo de Reserva y pasarela de Check-out/Check-in fotográfica.
- Panel Administrativo de Billetera Virtual (historial de movimientos, solicitudes de retiro).
- Chat interactivo que soporta multimedia y persiste estado en la capa de datos.

## Stack Tecnológico

| Tecnología | Función |
|---|---|
| Flutter / Dart | Framework Principal UI / Lenguaje de Programación |
| Riverpod | Inyección de Dependencias y Gestión de Estado Reactivo |
| Dio | Cliente HTTP para consumo de Endpoints REST |
| Socket.io Client | Infraestructura de WebSockets (Chat P2P) |
| Image Picker | Manejo local de fotografías y evidencias |
| GoRouter / AutoRoute | Sistema jerárquico de navegación y deep linking |

## Arquitectura de Proyecto

El código está organizado siguiendo los principios de la arquitectura modular (separado por Features), donde cada Feature (por ejemplo: `auth`, `booking`, `profile`) incluye sus propias capas de interés:

```text
lib/
  ├── core/            # Servicios transversales (red, constantes, utilidades)
  ├── features/        # Módulos de la aplicación
  │    ├── auth/       # Autenticación y Perfilamiento
  │    ├── booking/    # Operaciones de Reserva
  │    ├── chat/       # Mensajería instantánea
  │    └── home/       # Listado principal y búsqueda
  └── main.dart        # Punto de entrada de inicialización de Riverpod
```

- **Domain/Modelos:** Entidades de conversión JSON y lógica pura (Data Classes).
- **Data/Repository:** Adaptadores y comunicación directa con API externa.
- **Providers:** Interacción entre estado estático UI y estado lógico (Cubit/Notifier).
- **Screens/UI:** Módulos de vistas organizados para presentación pura, sin lógica de negocio fuerte.

## 🚀 Instalación y Despliegue

Siga estos pasos para configurar el entorno de desarrollo y ejecutar la aplicación en su dispositivo o simulador.

### Requisitos Previos

- **Flutter SDK**: ^3.7.2 (Canal Stable)
- **Dart SDK**: ^3.0.0
- **Android Studio / Xcode**: Para compilación en dispositivos móviles.
- **Herramientas de línea de comandos**: Git y un terminal compatible.

### Pasos de Configuración

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/GaboMV/AppGaraje.git
   cd app_garajes
   ```

2. **Configurar Variables de Entorno**
   Asegúrese de que el archivo `.env` en la raíz del proyecto esté presente. Este archivo contiene las claves de API y URLs necesarias para el funcionamiento del sistema:
   ```env
   API_BASE_URL=https://garaje-backend-api.onrender.com
   GOOGLE_CLIENT_ID=TU_CLIENT_ID_DE_GOOGLE
   ```

3. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

4. **Generación de Código**
   Este proyecto utiliza generadores para Riverpod y modelos de datos. Ejecute el siguiente comando para generar los archivos necesarios:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Ejecutar la Aplicación**
   Para iniciar la aplicación en modo desarrollo:
   ```bash
   flutter run
   ```

---

> [!NOTE]
> Para pruebas en el **Emulador de Android**, recuerde que `localhost` se mapea a `10.0.2.2`. Si utiliza un dispositivo físico, el dispositivo y el servidor deben estar en la misma red local.

