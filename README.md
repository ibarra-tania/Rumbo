# 🧭 Rumbo — Localizador de Puntos de Interés

App Flutter de la **Práctica Guiada Semana 10 · Geolocalización y Mapas** (Desarrollo Móvil Integral, UTXJ · IDGS).

| Requisito del reto | Dónde está |
|---|---|
| 1. Ubicación actual: centrar cámara en el usuario al iniciar | `MapScreen._onMapCreated → _centerOnMe` |
| 2. Marcador dinámico al tocar el mapa | `GoogleMap.onTap → _addPoi` (pines numerados, arrastrables) |
| 3. Distancia en vivo usuario ↔ destino | `Geolocator.distanceBetween` en `LocationService.distance` |
| 4. Dirección postal (calle y colonia) | `placemarkFromCoordinates` en `GeocodingService.reverse` |
| GPS en tiempo real + permisos | `Geolocator.getPositionStream` (distanceFilter 10 m) + `GateScreen` |
| Ciclo de vida | `dispose()` cancela el `StreamSubscription` y libera el `GoogleMapController` |
| API Key protegida | `android/local.properties` → Gradle → `manifestPlaceholders` (ignorado por Git) |

**Extras:** 3 estilos de mapa (Nocturno, Claro, Satélite), línea de trayecto, círculo de precisión GPS, rumbo/brújula, tiempo a pie, modo seguimiento, lista de puntos ordenada por cercanía (desliza para borrar) y copiar coordenadas.

---

## ▶️ Cómo ejecutarla

Requisitos: Flutter **3.29 o superior** (`flutter --version`), Android Studio o VS Code, y un dispositivo con Google Play Services.

```bash
cd rumbo

# 1) Genera los archivos de plataforma que faltan (íconos, gradlew, proyecto Xcode…).
#    NO sobrescribe los archivos ya configurados de este proyecto.
flutter create . --org com.utxj --project-name rumbo --platforms android,ios

# 2) Dependencias
flutter pub get

# 3) Ejecutar
flutter run
```

> Si `flutter create` genera un `android/app/build.gradle` (Groovy) además del `build.gradle.kts`, borra el de Groovy: tu Flutter es anterior a 3.29.

### 🔑 La API Key
- **Android:** `android/local.properties` → `maps.apikey=TU_LLAVE` (usa `local.properties.example` como plantilla).
- **iOS:** `ios/Flutter/Secrets.xcconfig` → `MAPS_API_KEY=TU_LLAVE`, luego `cd ios && pod install`.

Ambos archivos están en `.gitignore`, así que **nunca llegan a GitHub**.

---

## 🌿 Subir a GitHub (rama `feature/maps-geolocation`)

```bash
git init
git checkout -b feature/maps-geolocation
git add .
git status            # verifica que NO aparezca local.properties ni Secrets.xcconfig
git commit -m "feat: módulo de geolocalización y mapas"
git remote add origin https://github.com/TU_USUARIO/rumbo.git
git push -u origin feature/maps-geolocation
```

Comprobación rápida: `git check-ignore -v android/local.properties` debe responder con la regla del `.gitignore`.

---

## 🗂 Estructura

```
lib/
├── main.dart                     # Arranque y tema
├── app/theme.dart                # Paleta, tipografías (Space Grotesk + JetBrains Mono)
├── screens/
│   ├── gate_screen.dart          # Bienvenida, validación de GPS y permisos
│   └── map_screen.dart           # Mapa, stream GPS, marcadores, distancia
├── services/
│   ├── location_service.dart     # geolocator: permisos, stream, distanceBetween
│   └── geocoding_service.dart    # geocoding: coordenadas → calle/colonia (con caché)
├── map/
│   ├── map_styles.dart           # Estilos JSON propios del mapa
│   └── marker_factory.dart       # Pines dibujados en Canvas
├── models/                       # PointOfInterest, Address
├── widgets/                      # Paneles, chips, botones, radar
└── utils/format.dart             # Formato de distancias, coordenadas y rumbo
```
