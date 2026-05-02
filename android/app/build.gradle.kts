plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.SWETeam9.my_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.SWETeam9.my_app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        // default — بيتغير per buildType تحت
        manifestPlaceholders["appHost"] = "dev.iqa3.tech"
    }

    buildTypes {
        debug {
            manifestPlaceholders["appHost"] = "dev.iqa3.tech"
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
            // ── غير ده لما تروح production ──
            manifestPlaceholders["appHost"] = "dev.iqa3.tech"
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}