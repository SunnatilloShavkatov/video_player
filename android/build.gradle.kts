plugins {
    id("com.android.library")
}

group = "uz.plugin.video_player"
version = "3.6.0"

android {
    namespace = "uz.plugin.video_player"
    compileSdk = 37

    defaultConfig {
        minSdk = 26
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
    val media3Version = "1.11.1"
    implementation("androidx.media3:media3-ui:$media3Version")
    implementation("androidx.media3:media3-exoplayer:$media3Version")
    implementation("androidx.media3:media3-exoplayer-hls:$media3Version")

    // UI
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("com.google.android.material:material:1.13.0")

    // Unit tests (pure JVM)
    testImplementation("junit:junit:4.13.2")
}
