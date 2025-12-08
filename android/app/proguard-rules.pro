# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Flutter native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Dio HTTP client
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-dontwarn java.nio.file.*
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement

# Keep model classes (for JSON serialization)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# media_kit
-keep class com.alexmercerind.** { *; }
-keep class dev.nicgordon.** { *; }

# video_player
-keep class io.flutter.plugins.videoplayer.** { *; }

# cached_network_image
-keep class com.bumptech.glide.** { *; }
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule {
 <init>(...);
}
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
  **[] $VALUES;
  public *;
}

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Prevent R8 from removing classes used via reflection
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
