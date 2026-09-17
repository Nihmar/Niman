import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing key (T-M7-02): CI writes android/key.properties from the
// ANDROID_* secrets; without it the release build stays debug-signed so
// `flutter run --release` and unsigned CI artifacts keep working.
// key.properties and *.jks are gitignored and never enter the repo.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "dev.niman.niman"
    compileSdk = 37
    // whisper_ggml builds whisper.cpp with NDK 29; NDKs are backward
    // compatible, so the highest one any plugin asks for wins.
    ndkVersion = "29.0.13113456"

    // AGP requires every flavor to belong to a named dimension; the
    // testing build is the only one (issue #106).
    flavorDimensions += "channel"

    compileOptions {
        // Required by flutter_local_notifications (Java 8+ APIs in the
        // plugin's AAR need desugaring on Android).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.niman.niman"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 35
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        jniLibs {
            // 64-bit only (arm64-v8a, x86_64). minSdk 35 devices are
            // practically all 64-bit, and armeabi-v7a was the heaviest ABI
            // once whisper_ggml and its FFmpeg joined (55 MB of native code,
            // plain + NEON copies; see docs/dev/transcription.md).
            // ndk.abiFilters is not enough: the Flutter Gradle plugin adds
            // its own target platforms, so the ABI is dropped at packaging,
            // which every build path (scripts, CI, flutter run) goes through.
            excludes += "**/armeabi-v7a/**"
        }
    }

    // The two installs of issue #106, side by side on one device.
    // Once a flavor dimension has a flavor, AGP drops the no-flavor
    // variant, so the official app gets an explicit flavor of its
    // own: no suffix, no per-flavor manifest — the application ID
    // stays dev.niman.niman. Build it with
    // `flutter build apk --release --flavor official`; the testing
    // build is `--flavor beta --dart-define=APP_CHANNEL=testing`
    // (the define gates the Dart side: update management hidden and
    // skipped); keep both in step. AGP forbids flavor names starting
    // with "test" (reserved for test variants), hence "beta".
    productFlavors {
        create("official") {
            dimension = "channel"
        }
        create("beta") {
            dimension = "channel"
            applicationIdSuffix = ".beta"
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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

dependencies {
    // Core library desugaring runtime (see compileOptions above).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
