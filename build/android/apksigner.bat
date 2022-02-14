@echo off
set path=%cd%\OpenJDK\bin
%path%\java.exe -jar apksigner.jar sign -verbose --ks debug.keystore --ks-pass pass:android --ks-key-alias androiddebugkey --key-pass pass:android --out tmp\signed.apk tmp\aligned.apk
%path%\java.exe -jar apksigner.jar verify -verbose tmp\signed.apk
pause