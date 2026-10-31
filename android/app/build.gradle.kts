import com.posthog.android.PostHogCliExecTask
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.posthog.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.fithost.fit_host"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fithost.fit_host"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

val postHogEnv = Properties().apply {
    val envFile = rootProject.file("../.env")
    if (envFile.exists()) envFile.inputStream().use { load(it) }
}

tasks.withType<PostHogCliExecTask>().configureEach {
    isIgnoreExitValue = true
    (System.getenv("POSTHOG_CLI_API_KEY") ?: postHogEnv.getProperty("POSTHOG_CLI_API_KEY"))?.let { postHogApiKey.set(it) }
    (System.getenv("POSTHOG_CLI_PROJECT_ID") ?: postHogEnv.getProperty("POSTHOG_CLI_PROJECT_ID"))?.let { postHogProjectId.set(it) }
    (System.getenv("POSTHOG_CLI_HOST") ?: postHogEnv.getProperty("POSTHOG_CLI_HOST"))?.let { postHogHost.set(it) }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:35.1.0"))

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
}
