plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Release settings come from the environment, never from a file in git ─────────────────────────
//   HH_APPLICATION_ID       the Play application id (cannot change after the first upload)
//   HH_KEYSTORE_PATH        full path to the upload keystore, kept outside this repository
//   HH_KEYSTORE_PASSWORD, HH_KEY_ALIAS, HH_KEY_PASSWORD
// See docs/ANDROID_RELEASE.md.
val placeholderApplicationId = "com.example.rohii_hostel_hunt"
val releaseApplicationId: String = System.getenv("HH_APPLICATION_ID")?.takeIf { it.isNotBlank() } ?: placeholderApplicationId
val keystorePath: String? = System.getenv("HH_KEYSTORE_PATH")?.takeIf { it.isNotBlank() }
val hasReleaseKey = keystorePath != null && file(keystorePath).isFile &&
    listOf("HH_KEYSTORE_PASSWORD", "HH_KEY_ALIAS", "HH_KEY_PASSWORD").all { !System.getenv(it).isNullOrBlank() }

android {
    // The code's package. It does not have to equal the application id, so changing the id needs no code move.
    namespace = "com.example.rohii_hostel_hunt"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = releaseApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keystorePath!!)
                storePassword = System.getenv("HH_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("HH_KEY_ALIAS")
                keyPassword = System.getenv("HH_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Without the variables a release APK is still signed with the debug key, so `flutter run --release`
            // keeps working on your own phone. The Play bundle cannot be built that way (see the check below).
            signingConfig = if (hasReleaseKey) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

// A bundle is what goes to Play, so it must never be built with the debug key or the placeholder id.
gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.startsWith("bundle") && it.name.endsWith("Release") }) {
        val problems = mutableListOf<String>()
        if (!hasReleaseKey) {
            problems += "No signing key: set HH_KEYSTORE_PATH (an existing file), HH_KEYSTORE_PASSWORD, HH_KEY_ALIAS and HH_KEY_PASSWORD."
        }
        if (releaseApplicationId.startsWith("com.example")) {
            problems += "The application id is still the placeholder: set HH_APPLICATION_ID to the id you chose for Play."
        }
        if (problems.isNotEmpty()) {
            throw GradleException("Cannot build a Play bundle:\n - " + problems.joinToString("\n - "))
        }
    }
}

flutter {
    source = "../.."
}
