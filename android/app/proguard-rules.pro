# Flutter Local Notifications - Keep notification receivers
-keep class com.dexterous.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }

# Keep AndroidX classes used by notifications
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.core.app.NotificationManagerCompat** { *; }

# Keep timezone data
-keep class org.threeten.** { *; }

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep raw resources (alarm sounds)
-keep class **.R$raw { *; }

# Gson (used by some Firebase libraries)
-keepattributes Signature
-keepattributes *Annotation*

