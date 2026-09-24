import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// La clé de publication vit hors du dépôt. android/key.properties, ignoré
// par git, dit où la trouver et avec quel mot de passe. Sans lui, la
// version de publication est signée avec la clé de débogage : assez pour
// essayer, pas pour distribuer, car une application ne se met à jour que
// par-dessus une version signée de la même clé.
val proprietesCle = Properties().apply {
    val fichier = rootProject.file("key.properties")
    if (fichier.exists()) fichier.inputStream().use { load(it) }
}
val clePresente = proprietesCle.containsKey("storeFile")

// La démo est une application à part : autre identifiant, autre nom, pour
// qu'elle s'installe à côté de la vraie sans la remplacer. Flutter passe
// les --dart-define à Gradle, encodés en base64 et séparés par des
// virgules : DEMO=true suffit à tout basculer.
val definitions = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.map { String(Base64.getDecoder().decode(it)) }
    ?: emptyList()
val demo = "DEMO=true" in definitions

android {
    namespace = "fr.bevannes.bevannes"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Pour le nom de l'application, qui change avec la démo.
    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Les rappels planifiés (flutter_local_notifications) s'appuient sur java.time.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "fr.bevannes.bevannes"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Tirés de « version: » dans pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        if (demo) applicationIdSuffix = ".demo"
        resValue("string", "app_name", if (demo) "BeVannes démo" else "BeVannes")
    }

    signingConfigs {
        if (clePresente) {
            create("publication") {
                storeFile = file(proprietesCle.getProperty("storeFile"))
                storePassword = proprietesCle.getProperty("storePassword")
                keyAlias = proprietesCle.getProperty("keyAlias")
                keyPassword = proprietesCle.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (clePresente) "publication" else "debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
