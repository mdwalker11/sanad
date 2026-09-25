# قواعد R8/ProGuard لنسخة الإصدار.
#
# كان build.gradle.kts يشير إلى هذا الملف دون وجوده، فيفشل
# minifyReleaseWithR8 ويتعذر إنتاج أي نسخة release.

# Flutter — يُحمّل عبر JNI فلا يراه R8.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# نقطة دخول التطبيق.
-keep class ly.sanad.sanad.** { *; }

# Supabase/Ktor يعتمدان على الانعكاس في فك تشفير JSON.
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**
-keepattributes *Annotation*, InnerClasses, Signature, Exceptions

# kotlinx.serialization — الحقول تُقرأ انعكاسياً.
-keepclassmembers class **$$serializer { *; }
-keepclasseswithmembers class * {
    kotlinx.serialization.KSerializer serializer(...);
}

# لا تُزل أسماء الاستثناءات، وإلا صارت تقارير الأعطال بلا معنى.
-keepattributes SourceFile,LineNumberTable

# مكتبات اختيارية قد لا تكون موجودة وقت البناء.
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
