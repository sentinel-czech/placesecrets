# R8/ProGuard keep rules for release shrinking.
# Most Flutter plugins ship their own consumer rules; these cover libraries that
# are known to need extra keeps or that are accessed reflectively.

# Flutter engine / embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# flutter_background_geolocation (TransistorSoft) — accessed reflectively.
-keep class com.transistorsoft.** { *; }
-dontwarn com.transistorsoft.**

# Firebase / FCM
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# just_audio / ExoPlayer (media3)
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**

# Keep annotations and generic signatures used by JSON/reflection.
-keepattributes Signature,*Annotation*,EnclosingMethod
