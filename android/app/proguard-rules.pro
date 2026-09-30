# Proguard / R8 rules for Listix

# Flutter Wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Flutter Plugins
-keep class com.tekartik.sqflite.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.llfbandit.app_links.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.google.android.gms.ads.** { *; }

# App Package
-keep class com.nmenag.listix.** { *; }
