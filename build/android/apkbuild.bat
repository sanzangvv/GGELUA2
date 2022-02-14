@echo off
set path=%cd%\OpenJDK\bin
%path%\java.exe -jar apktool.jar build tmp\output --force-all -output tmp\rebuild.apk
pause