# Security-focused ProGuard Rules

# Keep source file names and line numbers for stack traces
-keepattributes SourceFile,LineNumberTable

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Encrypt strings
-adaptclassstrings
-adaptresourcefilenames
-adaptresourcefilecontents

# Remove kotlin metadata
-keepattributes *Annotation*
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Security configurations
-keep class com.example.security.** { *; }
-keepclassmembers class com.example.security.** { *; }

# Keep security-related attributes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# SSL/TLS Security
-keep class javax.net.ssl.** { *; }
-keep class javax.net.** { *; }
-keep class javax.security.** { *; }
-keep class java.security.** { *; }
-keep class org.apache.http.** { *; }
-keep class org.apache.james.mime4j.** { *; }
-keep class javax.activation.** { *; }
-keep class com.sun.activation.registries.** { *; }

# Cryptography
-keep class javax.crypto.** { *; }
-keep class javax.crypto.spec.** { *; }
-keep class sun.security.** { *; }

# Keep OkHttp and SSL classes
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class sun.security.ssl.** { *; }
-keep class sun.security.x509.** { *; }

# Keep security-sensitive Android components
-keep class android.security.** { *; }
-keep class android.keystore.** { *; }
-keep class androidx.security.** { *; }

# Keep biometric authentication classes
-keep class androidx.biometric.** { *; }
-keep class android.hardware.biometrics.** { *; }

# Keep SafetyNet attestation
-keep class com.google.android.gms.safetynet.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep root detection related classes
-keep class com.scottyab.rootbeer.** { *; }

# Keep certificate pinning classes
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-keep class okhttp3.CertificatePinner { *; }

# Keep encryption related classes
-keep class javax.crypto.Cipher { *; }
-keep class javax.crypto.spec.SecretKeySpec { *; }
-keep class javax.crypto.spec.IvParameterSpec { *; }
-keep class javax.crypto.SecretKey { *; }

# Keep secure random number generation
-keep class java.security.SecureRandom { *; }

# Keep security exception classes
-keep class java.security.cert.CertificateException { *; }
-keep class javax.net.ssl.SSLHandshakeException { *; }
-keep class javax.net.ssl.SSLPeerUnverifiedException { *; }
-keep class javax.net.ssl.SSLException { *; }

# Keep security provider classes
-keep class org.conscrypt.** { *; }
-keep class org.bouncycastle.** { *; }

# Keep WebView security classes
-keep class android.webkit.** { *; }
-keep class com.google.android.webview.** { *; }

# Keep deep link handling classes
-keep class android.app.Activity { *; }
-keepclassmembers class * extends android.app.Activity {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep security-sensitive SharedPreferences
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$Editor { *; }

# Keep security configuration classes
-keep class android.security.keystore.KeyGenParameterSpec$Builder { *; }
-keep class android.security.keystore.KeyProperties { *; }

# Keep security-related manifest attributes
-keepattributes SecurityPermissions
-keepattributes SystemPermissions
-keepattributes RequiresPermission
-keepattributes RequiresFeature

# Keep security annotations
-keep @interface android.annotation.SuppressLint
-keep @interface androidx.annotation.RequiresPermission
-keep @interface androidx.annotation.RequiresApi

# Keep security-related resource files
-keep class **.R$raw { *; }
-keep class **.R$xml { *; }

# Keep security configuration files
-keep class **.R$xml {
    public static final int network_security_config;
    public static final int security_settings;
}

# Optimization settings
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Additional security measures
-dontskipnonpubliclibraryclasses
-dontskipnonpubliclibraryclassmembers
-repackageclasses 'com.security.app'
-flattenpackagehierarchy 'com.security.app'
