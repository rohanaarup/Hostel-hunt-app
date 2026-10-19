# R8 rules for the release build (shrinking is on). Flutter and its plugins ship their own rules; these cover
# the Razorpay checkout, which looks up its payment callbacks by name at run time.
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
    public void onPayment*(...);
}
