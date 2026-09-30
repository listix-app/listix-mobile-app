plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val basePackageName: String = System.getenv("PACKAGE_NAME")
    ?.takeIf { it.isNotBlank() }
    ?: (project.findProperty("PACKAGE_NAME") as? String)?.takeIf { it.isNotBlank() }
    ?: "com.nmenag.listix"

android {
    namespace = "com.nmenag.listix"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = basePackageName
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "default"

    productFlavors {
        create("dev") {
            dimension = "default"
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appName"] = "Listix Dev"
        }
        create("preview") {
            dimension = "default"
            applicationIdSuffix = ".preview"
            manifestPlaceholders["appName"] = "Listix Preview"
        }
        create("prod") {
            dimension = "default"
            manifestPlaceholders["appName"] = "Listix"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
