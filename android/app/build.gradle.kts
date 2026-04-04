import org.gradle.api.tasks.Copy

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.lanthanum89.binaryclock"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.lanthanum89.binaryclock"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
}

val syncWebAssets by tasks.registering(Copy::class) {
    val sourceDir = file("../../web")
    val targetDir = file("src/main/assets/web")

    from(sourceDir)
    into(targetDir)

    doFirst {
        if (!sourceDir.exists()) {
            throw GradleException("Expected web assets at ../../web but that folder was not found.")
        }
    }
}

tasks.named("preBuild") {
    dependsOn(syncWebAssets)
}
