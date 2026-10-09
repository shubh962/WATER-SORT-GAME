# android/app/proguard-rules.pro

# WorkManager / Room / AndroidX Startup (stripping these caused the WorkDatabase startup crash)
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.startup.** { *; }
-keep class * extends androidx.startup.Initializer

# Flutter <-> HTML game bridge (JavaScript channel inside the WebView)
-keepattributes JavascriptInterface
-keepclassmembers class * { @android.webkit.JavascriptInterface <methods>; }
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Flutter engine references Play Core classes it does not ship
-dontwarn com.google.android.play.core.**
