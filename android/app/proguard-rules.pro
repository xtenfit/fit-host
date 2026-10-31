# Flutter Framework
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Dart JNI & Native Assets
-keep class com.github.dart_lang.jni.** { *; }
-dontwarn com.github.dart_lang.jni.**

# Drift & SQLite
-keep class org.sqlite.** { *; }
-keep class com.simonoid.** { *; }
-keep class io.requery.android.database.** { *; }
-dontwarn org.sqlite.**
-dontwarn io.requery.android.database.**

# Google ML Kit & Mobile Scanner
-keep class dev.moraz.mobile_scanner.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Flutter Local Notifications & Alarm Receivers
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Home Widget
-keep class es.antonborri.home_widget.** { *; }
-keep class com.fithost.fit_host.FitHostWidgetProvider { *; }

# Camera, Image Picker & Image Compression
-keep class io.flutter.plugins.camera.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.example.flutter_image_compress.** { *; }
-dontwarn io.flutter.plugins.camera.**
-dontwarn io.flutter.plugins.imagepicker.**

# Health Connect & Pedometer
-keep class androidx.health.connect.client.** { *; }
-keep class cachet.plugins.health.** { *; }
-dontwarn androidx.health.connect.client.**
-dontwarn cachet.plugins.health.**

# Audioplayers & Record
-keep class xyz.luan.audioplayers.** { *; }
-keep class com.llfbandit.record.** { *; }
-dontwarn xyz.luan.audioplayers.**
-dontwarn com.llfbandit.record.**

# Google Sign In
-keep class com.google.android.gms.auth.api.signin.** { *; }
-dontwarn com.google.android.gms.auth.api.signin.**

# AndroidX Startup, WorkManager & Room
-keep class androidx.startup.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.work.impl.WorkDatabase { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keepclassmembers class * extends androidx.room.RoomDatabase {
    public void clearAllTables();
    <init>();
}
-keep class * extends androidx.room.migration.Migration
-keep class * implements androidx.room.RoomDatabase$*
-keep class androidx.room.** { *; }
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# Desugaring & Kotlin Coroutines
-dontwarn java.lang.invoke.**
-dontwarn kotlinx.coroutines.**

# Firebase & Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# PostHog
-keep class com.posthog.** { *; }
-dontwarn com.posthog.**

