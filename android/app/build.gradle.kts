import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter debe aplicarse después de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

// ─────────────────────────────────────────────────────────────
// Inyección segura de la API Key:
// 1) La llave vive en android/local.properties (ignorado por Git).
// 2) Gradle la lee y crea el manifestPlaceholder MAPS_API_KEY.
// 3) AndroidManifest.xml la resuelve al compilar: ${MAPS_API_KEY}
// ─────────────────────────────────────────────────────────────
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val mapsApiKey: String = localProperties.getProperty("maps.apikey") ?: ""

android {
    namespace = "com.utxj.rumbo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.utxj.rumbo"
        // google_maps_flutter y geolocator requieren 21+; usamos 23 por estabilidad.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
