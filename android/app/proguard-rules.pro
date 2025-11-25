# Flutter and Dart
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.platform.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.util.** { *; }
-dontwarn io.flutter.embedding.engine.FlutterJNI

# Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# OneSignal
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**
-keep interface com.onesignal.OSNotificationOpenedResult { *; }
-keep interface com.onesignal.OSInAppMessageAction { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Play Core (split install)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# OkHttp / Retrofit / Dio
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# Keep generated model classes (json_serializable, etc.)
-keep class **$$JsonAdapter { *; }
-keep class **$$JsonSerializer { *; }
-keep class **$$JsonDeserializer { *; }
-keep class com.squareup.moshi.** { *; }
-dontwarn com.squareup.moshi.**

# Glide / Image loaders
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# Prevent obfuscation of classes referenced via reflection
-keep class com.proplinq.** { *; }

# AppsFlyer
-keep class com.appsflyer.** { *; }
-dontwarn com.appsflyer.**
-keep class kotlin.jvm.internal.** { *; }
-dontwarn kotlin.jvm.internal.**
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions


