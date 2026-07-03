# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_local_notifications (uses Gson reflection for scheduled payloads)
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# home_widget receivers
-keep class es.antonborri.home_widget.** { *; }

# Firebase / Google Play services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Wear OS data layer listener
-keep class com.lune.app.WearLogRequestListenerService { *; }
-keep class com.google.android.gms.wearable.** { *; }

# Kotlin metadata for reflection-based plugins
-keepattributes *Annotation*, InnerClasses, EnclosingMethod, Signature
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep generic type info used by Gson TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation class * extends com.google.gson.reflect.TypeToken

# Play Core is not bundled; Flutter references it for deferred components.
-dontwarn com.google.android.play.core.**
