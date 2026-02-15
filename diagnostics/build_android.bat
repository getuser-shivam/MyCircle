@echo off
set ANDROID_HOME=C:\Users\Work\AppData\Local\Android\Sdk
echo "Accepting licenses..."
(echo y & echo y & echo y & echo y & echo y & echo y & echo y) | "D:\Download\flutter_windows_3.38.9-stable\flutter\bin\flutter.bat" doctor --android-licenses
echo "Starting build..."
"D:\Download\flutter_windows_3.38.9-stable\flutter\bin\flutter.bat" build apk --debug -v > android_build_log.txt 2>&1
echo "Build finished."
