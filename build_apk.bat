@echo off
cd /d F:\Recent\pay_request
echo ==== FLUTTER BUILD APK RELEASE NO-SHRINK ====
c:\flutter\bin\flutter.bat build apk --release --no-shrink > F:\Recent\pay_request\build_output.txt 2>&1
echo EXIT CODE: %ERRORLEVEL% >> F:\Recent\pay_request\build_output.txt
echo ==== DONE ====
