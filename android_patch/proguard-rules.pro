# Keep rules for release builds (R8). The Ads and Billing SDKs ship their own
# consumer rules, so this file stays small.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-dontwarn com.google.android.gms.**
-dontwarn javax.annotation.**
# WebView JavaScript channels created by webview_flutter
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
