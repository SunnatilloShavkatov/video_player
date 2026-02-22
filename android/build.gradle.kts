plugins {
    id("com.android.library")
    id("kotlin-android")
}

group = "uz.shs.video_player"
version = "1.0-SNAPSHOT"

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.13.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

android {
    namespace = "uz.shs.video_player"
    compileSdk = 36

    defaultConfig {
        minSdk = 26
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    sourceSets["main"].java.srcDirs("src/main/kotlin")
    sourceSets["main"].res.srcDirs("src/main/res")

    androidResources {
        noCompress += "mp4"
    }

    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    // Media3
    val media3Version = "1.9.2"
    implementation("androidx.media3:media3-ui:$media3Version")
    implementation("androidx.media3:media3-exoplayer:$media3Version")
    implementation("androidx.media3:media3-exoplayer-hls:$media3Version")

    // Multidex
    val multidexVersion = "2.0.1"
    implementation("androidx.multidex:multidex:$multidexVersion")

    // JSON parsing (used in VideoPlayerPlugin for configuration deserialization)
    implementation("com.google.code.gson:gson:2.13.2")

    // UI
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("com.google.android.material:material:1.13.0")
}
