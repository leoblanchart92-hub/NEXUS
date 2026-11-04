plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nexus.nexus"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.nexus.nexus"
        // llama.cpp a besoin d'Android 9 (API 28) minimum.
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // llama.cpp ne fournit que arm64-v8a et x86_64 : on retire les ABI
        // héritées de Flutter (armeabi-v7a) avant de fixer les deux nôtres.
        ndk {
            abiFilters.clear()
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    // Clé de signature stable, versionnée dans le dépôt (base64) et décodée
    // par la CI. C'est elle qui permet à Android d'installer une mise à jour
    // par-dessus la version en place : avec la clé debug d'avant, régénérée à
    // chaque build, Android répondait « paquet en conflit ».
    signingConfigs {
        create("release") {
            storeFile = file("key.jks")
            storePassword = "nexus-release"
            keyAlias = "nexus"
            keyPassword = "nexus-release"
        }
    }

    buildTypes {
        release {
            // Sans clé locale (clone neuf), on retombe sur la clé debug pour
            // que `flutter build apk` fonctionne quand même.
            signingConfig = if (file("key.jks").exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    // FileProvider : nécessaire pour confier l'APK téléchargé au programme
    // d'installation d'Android (mise à jour depuis l'application).
    implementation("androidx.core:core-ktx:1.13.1")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
