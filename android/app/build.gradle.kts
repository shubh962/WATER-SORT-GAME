import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// -----------------------------------------------------------------------------
// Release signing configuration
// -----------------------------------------------------------------------------

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.shubham.watersort"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // -------------------------------------------------------------------------
    // Java
    // -------------------------------------------------------------------------

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // -------------------------------------------------------------------------
    // Signing configurations
    // -------------------------------------------------------------------------

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storePassword = keystoreProperties["storePassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
            }
        }
    }

    // -------------------------------------------------------------------------
    // Default application configuration
    // -------------------------------------------------------------------------

    defaultConfig {
        applicationId = "com.shubham.watersort"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ---------------------------------------------------------------------
        // AdMob App ID
        // ---------------------------------------------------------------------

        manifestPlaceholders["admobAppId"] =
            project.findProperty("admobAppId")?.toString()
                ?: "ca-app-pub-2427221337462218~1343049941"
    }

    // -------------------------------------------------------------------------
    // Build types
    // -------------------------------------------------------------------------

    buildTypes {
        release {
            // Use the real release/upload keystore.
            signingConfig = signingConfigs.getByName("release")

            // Smaller app: R8 removes unused code, shrinkResources removes unused resources.
            // The WorkManager/Room keep rules (the old startup crash) live in proguard-rules.pro.
            // If a release test still crashes, set both flags back to false.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// -----------------------------------------------------------------------------
// Kotlin
// -----------------------------------------------------------------------------

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// -----------------------------------------------------------------------------
// Flutter
// -----------------------------------------------------------------------------

flutter {
    source = "../.."
}