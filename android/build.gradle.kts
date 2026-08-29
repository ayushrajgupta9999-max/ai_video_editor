pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val propertiesFile = java.io.File(settingsDir, "local.properties")
        if (propertiesFile.exists()) {
            propertiesFile.reader(Charsets.UTF_8).use { properties.load(it) }
        }
        val sdkPath = properties.getProperty("flutter.sdk")
        require(sdkPath != null) { "flutter.sdk not set in local.properties" }
        sdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}

include(":app")
