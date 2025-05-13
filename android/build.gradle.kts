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
        classpath("com.android.tools.build:gradle:8.1.4")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
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
    compileSdk = 35

    defaultConfig {
        minSdk = 24
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = false
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets["main"].java.srcDirs("src/main/kotlin")
    sourceSets["main"].res.srcDirs("src/main/res")

    androidResources {
        noCompress += "mp4"
    }
}

dependencies {
    // Media3
    val media3Version = "1.6.1"
    implementation("androidx.media3:media3-ui:$media3Version")
    implementation("androidx.media3:media3-exoplayer:$media3Version")
    implementation("androidx.media3:media3-exoplayer-hls:$media3Version")

    // Multidex
    val multidexVersion = "2.0.1"
    implementation("androidx.multidex:multidex:$multidexVersion")

    // Retrofit
    val retrofitVersion = "2.11.0"
    implementation("com.google.code.gson:gson:2.12.0")
    implementation("com.squareup.retrofit2:retrofit:$retrofitVersion")
    implementation("com.squareup.retrofit2:converter-gson:$retrofitVersion")

    // Cronet
    implementation("org.checkerframework:checker-qual:3.42.0")
    implementation("com.google.android.gms:play-services-cronet:18.1.0")

    // UI
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.github.bumptech.glide:glide:4.15.1")
    implementation("com.google.android.material:material:1.12.0")
}
