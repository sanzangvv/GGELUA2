@echo off
set path=%cd%\OpenJDK\bin
%path%\java.exe -jar apktool.jar decode GGELUA.apk --force-all -output tmp\output
pause