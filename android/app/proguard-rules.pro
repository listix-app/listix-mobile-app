-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

-keep class com.tekartik.sqflite.** { *; }
-keep class com.llfbandit.app_links.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-keep class com.github.dart_lang.jni.** { *; }

-keepattributes InnerClasses
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

-keep class com.dexterous.** { *; }

-keep class androidx.startup.** { *; }
-keep class androidx.work.impl.** { *; }
-dontwarn com.google.android.gms.ads.**

-keep class com.nmenag.listix.MainActivity { *; }
