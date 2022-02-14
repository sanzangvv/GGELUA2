@echo off
set path=%cd%\OpenJDK\bin
zipalign.exe -p -f -v 4 tmp\rebuild.apk tmp\aligned.apk
pause