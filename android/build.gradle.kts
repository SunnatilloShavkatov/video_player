plugins {
    id("com.android.library")
}

group = "uz.plugin.video_player"
version = "3.8.0"

android {
    namespace = "uz.plugin.video_player"
    compileSdk = 37

    defaultConfig {
        minSdk = 26
        consumerProguardFiles("consumer-rules.pro")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    androidResources {
        noCompress += "mp4"
    }

    buildFeatures {
        viewBinding = true
    }
}

// No Kotlin plugin id on purpose: AGP 9 compiles Kotlin itself (android.builtInKotlin=true), and when the app turns
// that off the Flutter Gradle plugin applies kotlin-android to this project. Both end up with this extension.
kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    // Media3
    val media3Version = "1.11.1"
    implementation("androidx.media3:media3-common:$media3Version")
    implementation("androidx.media3:media3-datasource:$media3Version")
    implementation("androidx.media3:media3-extractor:$media3Version")
    implementation("androidx.media3:media3-ui:$media3Version")
    implementation("androidx.media3:media3-exoplayer:$media3Version")
    implementation("androidx.media3:media3-exoplayer-hls:$media3Version")

    // UI
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("androidx.core:core-ktx:1.18.0")
    implementation("androidx.lifecycle:lifecycle-common:2.9.4")
    implementation("com.google.android.material:material:1.13.0")

    // Unit tests (pure JVM)
    testImplementation("junit:junit:4.13.2")
}
