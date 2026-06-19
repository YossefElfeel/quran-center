# قواعد ProGuard/R8 لبناء الإصدار (release). معظم المكتبات بتجيب قواعدها (consumer
# rules) — دي إضافات/احتياطات للـ plugins اللي عندنا.

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Google ML Kit — التعرّف على النص (OCR للرقم القومي).
# لغات النص الاختيارية مش متبنّاة، فبنسكت تحذيراتها عشان R8 ما يفشلش.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**

# sqlite3 (drift / sqlite3_flutter_libs)
-dontwarn org.sqlite.**

# Play Core (يستخدمه Flutter للـ deferred components — احتياطي)
-dontwarn com.google.android.play.core.**
