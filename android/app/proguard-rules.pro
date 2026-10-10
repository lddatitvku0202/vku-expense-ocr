# R8 / minify rules for the release build (see docs/SIGNING.md and D-073).

# google_mlkit_text_recognition mentions the Chinese, Japanese, Korean and
# Devanagari recognizers in TextRecognizer.initialize(), but the app only
# bundles the Latin model (D-013) and always asks for TextRecognitionScript
# .latin, so those branches are never reached. Without these rules R8 stops
# the build with "Missing classes detected".
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit loads its internal components (CommonComponentRegistrar,
# VisionCommonRegistrar, TextRegistrar) by reflection from class names in
# the manifest. R8 sees no caller, strips their public no-argument
# constructors and the release app then logs "NoSuchMethodException:
# ...Registrar.<init> []"; the first OCR call fails with a NullPointerException
# in InputImage.fromFilePath. Keeping the constructors is enough.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    <init>();
}
