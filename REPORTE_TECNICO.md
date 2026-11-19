# Reporte técnico — Geolocalización y Mapas en Flutter

**Alumno:** ______________________  **Grupo:** IDGS 10° ___  **Fecha:** ___________
**Repositorio:** https://github.com/____________/rumbo/tree/feature/maps-geolocation

---

## 1. Restricción de la API Key (Google Cloud Platform)

| Paso | Configuración aplicada | Evidencia |
|---|---|---|
| APIs habilitadas | Maps SDK for Android, Maps SDK for iOS, Geocoding API | Captura: *APIs y servicios › APIs habilitadas* |
| Restricción de aplicación | **Apps de Android** — paquete `com.utxj.rumbo` + huella **SHA-1** | Captura: *Credenciales › tu clave* |
| Restricción de API | Solo: Maps SDK for Android, Maps SDK for iOS, Geocoding API | Captura |
| Cuotas | Tope diario de solicitudes configurado en *Cuotas y límites del sistema* | Captura |

**Obtener la SHA-1 de depuración**

```bash
# Opción A (dentro del proyecto)
cd android && ./gradlew signingReport        # en Windows: gradlew signingReport

# Opción B (keytool)
keytool -list -v -alias androiddebugkey -storepass android -keypass android \
  -keystore ~/.android/debug.keystore         # Windows: %USERPROFILE%\.android\debug.keystore
```

SHA-1 registrada: `__:__:__:__:__:__:__:__:__:__:__:__:__:__:__:__:__:__:__:__`

> Una clave solo admite **un tipo** de restricción de aplicación. Si también se compila para iOS, se recomienda una segunda clave restringida por **Bundle ID** (`com.utxj.rumbo`).

## 2. Protección de la credencial en el repositorio

1. La llave vive en `android/local.properties` (`maps.apikey=…`), incluido en `.gitignore`.
2. `android/app/build.gradle.kts` lee la propiedad y crea `manifestPlaceholders["MAPS_API_KEY"]`.
3. `AndroidManifest.xml` usa `android:value="${MAPS_API_KEY}"`; el valor se resuelve al compilar.
4. En iOS: `Secrets.xcconfig` (ignorado) → `Info.plist` (`$(MAPS_API_KEY)`) → `GMSServices.provideAPIKey` en `AppDelegate.swift`.

Verificación: `git check-ignore -v android/local.properties` y búsqueda de `AIza` en GitHub sin resultados.

## 3. Pruebas de funcionamiento

| # | Prueba | Resultado esperado | Resultado | Captura |
|---|---|---|---|---|
| 1 | Abrir la app con GPS apagado | Aviso "El GPS está apagado" y botón *Activar GPS* | ☐ OK | |
| 2 | Negar el permiso | Mensaje "Permiso rechazado" con reintento | ☐ OK | |
| 3 | Conceder permiso | El mapa se abre y la cámara se centra en el usuario | ☐ OK | |
| 4 | Caminar > 10 m | Coordenadas, precisión y velocidad se actualizan en vivo | ☐ OK | |
| 5 | Tocar el mapa | Se crea un pin numerado y se selecciona | ☐ OK | |
| 6 | Ver distancia | Metros/km entre usuario y destino (`Geolocator.distanceBetween`) | ☐ OK | |
| 7 | Ver dirección | Calle y colonia del destino por geocodificación inversa | ☐ OK | |
| 8 | Arrastrar un pin | Se recalculan distancia y dirección | ☐ OK | |
| 9 | Salir del mapa | `dispose()` cancela el stream de posición | ☐ OK | |

## 4. Eficiencia
- `distanceFilter: 10` evita actualizaciones redundantes y ahorra batería.
- La dirección del usuario solo se re-consulta si se movió más de 40 m; resultados en caché.
- `dispose()` cancela el `StreamSubscription<Position>` y libera el `GoogleMapController`.

## 5. Conclusiones
_______________________________________________________________________
