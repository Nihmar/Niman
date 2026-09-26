# Issue #63: the WebView PDF writer lives in `android.print` because the
# print adapter's layout and write callbacks have package-private
# constructors — only a class in that package may subclass them. R8's
# default obfuscation keeps package names, but `-repackageclasses` would
# move the class and break the print with an access error at runtime, not
# at build time. Pin it.
-keeppackagenames android.print
-keep class android.print.NimanPdfWriter { *; }
