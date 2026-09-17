# ─── Flutter Engine ───────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }
-dontwarn io.flutter.embedding.**

# ─── Flutter Plugin Registrant ────────────────────────────────────────────────
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class com.maintix.app.MainActivity { *; }

# ─── Kotlin ───────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ─── Kotlin Coroutines ────────────────────────────────────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# ─── Supabase / Ktor / OkHttp ─────────────────────────────────────────────────
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.github.jan.supabase.**
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okio.** { *; }

# ─── Gson / JSON serialization ────────────────────────────────────────────────
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ─── Razorpay ─────────────────────────────────────────────────────────────────
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keep class proguard.annotation.Keep
-keep class proguard.annotation.KeepClassMembers
-keepclassmembers class * {
    @proguard.annotation.Keep *;
}

# ─── Stripe (suppress warnings from unused dependency) ────────────────────────
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
-keep class com.stripe.** { *; }

# ─── Google Play Core / In-App Updates ────────────────────────────────────────
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# ─── AndroidX / Jetpack ───────────────────────────────────────────────────────
-keep class androidx.** { *; }
-dontwarn androidx.**
-keep class android.** { *; }

# ─── Shared Preferences ───────────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ─── URL Launcher ─────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }

# ─── Permission Handler ───────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }

# ─── Geolocator / Location ────────────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }

# ─── Image Picker ─────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.imagepicker.** { *; }

# ─── Connectivity Plus ────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# ─── Flutter Local Notifications ──────────────────────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ─── Cached Network Image / HTTP ──────────────────────────────────────────────
-keep class com.squareup.okhttp3.** { *; }

# ─── Reflection / Annotations ─────────────────────────────────────────────────
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile
-keepattributes LineNumberTable

# ─── Prevent stripping of native methods ──────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ─── Enums ────────────────────────────────────────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ─── Parcelable ───────────────────────────────────────────────────────────────
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# ─── Serializable ─────────────────────────────────────────────────────────────
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}