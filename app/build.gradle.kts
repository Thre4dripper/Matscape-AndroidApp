import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "com.ByteMechanics.matscape"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.ByteMechanics.matscape"
        minSdk = 29
        targetSdk = 37
        versionCode = 17
        versionName = "1.0-e46aa9a"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            val localProps = Properties().apply {
                val localPropsFile = rootProject.file("local.properties")
                if (localPropsFile.exists()) {
                    localPropsFile.inputStream().use { load(it) }
                }
            }

            fun getEnvOrLocalProp(key: String): String? =
                System.getenv(key) ?: localProps.getProperty(key)

            val keystorePath = getEnvOrLocalProp("RELEASE_KEYSTORE_PATH")
            if (keystorePath != null) {
                storeFile = rootProject.file(keystorePath)
                storePassword = getEnvOrLocalProp("RELEASE_STORE_PASSWORD")
                keyAlias = getEnvOrLocalProp("RELEASE_KEY_ALIAS")
                keyPassword = getEnvOrLocalProp("RELEASE_KEY_PASSWORD")
            } else {
                println("⚠️ RELEASE_KEYSTORE_PATH is missing — skipping release signing")
            }
        }
    }

    buildTypes {
        debug {
            versionNameSuffix = "-debug"
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        release {
            isMinifyEnabled = true
            signingConfig = signingConfigs.getByName("release")
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
}

dependencies {
    implementation(libs.appcompat)
    implementation(libs.material)
    implementation(libs.constraintlayout)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.espresso.core)
}




