# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# sqflite
-keep class org.sqlite.** { *; }

# mobile_scanner / ML Kit
-dontwarn com.google.mlkit.**
-keep class com.google.mlkit.** { *; }

# QR generation
-keep class qr.** { *; }

# image library
-keep class image.** { *; }

# url_launcher
-dontwarn androidx.browser.

# Play Core (deferred components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.****

# Keep model classes
-keep class pay.request.** { *; }
-keep class * extends PaymentRequest
-keep class * extends Favorite

# Keep serialization
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
