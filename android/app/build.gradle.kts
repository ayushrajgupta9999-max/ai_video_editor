plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android") version "1.9.20" apply false
}

android {
    namespace = "com.aivideo.ai_video_editor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.aivideo.ai_video_editor"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        // FFmpegKitNext requires these
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            isDebuggable = true
        }
    }

    // FFmpegKitNext packaging options
    packaging {
        resources {
            pickFirsts += listOf(
                "lib/armeabi-v7a/libffmpeg.so",
                "lib/arm64-v8a/libffmpeg.so",
                "lib/x86_64/libffmpeg.so",
                "META-INF/LICENSE",
                "META-INF/NOTICE"
            )
        }
        jniLibs {
            pickFirsts += listOf(
                "lib/armeabi-v7a/libffmpeg.so",
                "lib/arm64-v8a/libffmpeg.so",
                "lib/x86_64/libffmpeg.so"
            )
            keepDebugSymbols += listOf(
                "lib/armeabi-v7a/libffmpeg.so",
                "lib/arm64-v8a/libffmpeg.so",
                "lib/x86_64/libffmpeg.so"
            )
        }
    }

    aaptOptions {
        noCompress = listOf("tflite", "lite", "bin")
    }

    // Split per ABI for smaller APKs
    splits {
        abi {
            enable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            universalApk = false
        }
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.0")
    implementation("androidx.activity:activity-ktx:1.9.0")
    // FFmpegKitNext will be added via Flutter plugin
}