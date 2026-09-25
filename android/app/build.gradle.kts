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

            // -----------------------------------------------------------------
            // CRASH FIX / DIAGNOSTIC
            //
            // The production build is crashing during AndroidX Startup ->
            // WorkManager -> WorkDatabase initialization.
            //
            // Keep Android R8/minification and resource shrinking OFF while
            // validating the production build.
            // -----------------------------------------------------------------

            isMinifyEnabled = false
            isShrinkResources = false
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