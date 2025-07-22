plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rafizuddin.sheetroutine"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Add signingConfigs at the android level
    signingConfigs {
        create("release") {
            storeFile = file("key.jks")
            storePassword = "rafizuddin"
            keyAlias = "upload"
            keyPassword = "rafizuddin"
        }
    }

    defaultConfig {
        applicationId = "com.rafizuddin.sheetroutine"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Assign the signing config to the release build type
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}