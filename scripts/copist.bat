@echo off
rem Copist dev helper for Windows hosts: terse output, full logs under
rem %TEMP%\copist. Mirrors scripts/copist.sh and adds the windows build,
rem which cannot be cross-built from Linux.
rem Commands: analyze, test, check, apk, windows.
setlocal enabledelayedexpansion

where flutter >nul 2>&1
if errorlevel 1 (
  echo error: flutter not found - add the Flutter SDK bin directory to PATH 1>&2
  exit /b 1
)

set "cmd=%~1"
set "logdir=%TEMP%\copist"
if not exist "%logdir%" mkdir "%logdir%"
set "log=%logdir%\copist-%cmd%.log"

if "%cmd%"=="analyze" goto :analyze
if "%cmd%"=="test" goto :test
if "%cmd%"=="check" goto :check
if "%cmd%"=="apk" goto :apk
if "%cmd%"=="linux" goto :linux
if "%cmd%"=="windows" goto :windows
goto :usage

:analyze
call flutter analyze --fatal-infos >"%log%" 2>&1
set "status=%errorlevel%"
powershell -NoProfile -Command "Select-String -Path '%log%' -Pattern '^\s+(error|warning|info) - ' | Select-Object -First 30 | ForEach-Object { $_.Line }"
powershell -NoProfile -Command "Get-Content -Tail 2 '%log%'"
exit /b %status%

:test
call flutter test >"%log%" 2>&1
set "status=%errorlevel%"
powershell -NoProfile -Command "Get-Content -Tail 8 '%log%'"
exit /b %status%

:check
call "%~f0" analyze
if errorlevel 1 exit /b 1
call "%~f0" test
exit /b %errorlevel%

:apk
rem A security agent that watches the temp directory (Trend Micro here)
rem blocks the unix-domain socket the JVM opens there for every Selector,
rem and Gradle then dies with "Unable to establish loopback connection"
rem before compiling anything. Moving those sockets under the profile
rem fixes it and is inert where nothing blocks them.
if not exist "%USERPROFILE%\.javasock" mkdir "%USERPROFILE%\.javasock"
if not defined JAVA_TOOL_OPTIONS set "JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=%USERPROFILE%\.javasock"
call flutter build apk --release >"%log%" 2>&1
set "status=%errorlevel%"
powershell -NoProfile -Command "Get-Content -Tail 3 '%log%'"
if "%status%"=="0" echo artifact: build\app\outputs\flutter-apk\app-release.apk
exit /b %status%

:linux
echo error: the linux build needs a Linux host 1>&2
exit /b 1

:windows
call flutter build windows --release >"%log%" 2>&1
set "status=%errorlevel%"
powershell -NoProfile -Command "Get-Content -Tail 3 '%log%'"
if "%status%"=="0" echo artifact: build\windows\x64\runner\Release\copist.exe
exit /b %status%

:usage
echo usage: scripts\copist.bat ^<analyze^|test^|check^|apk^|windows^>
echo   analyze  flutter analyze --fatal-infos (issue lines + summary only)
echo   test     flutter test (tail only)
echo   check    analyze + test; use before committing
echo   apk      flutter build apk --release
echo   windows  flutter build windows --release
echo Full logs: %%TEMP%%\copist\copist-^<cmd^>.log
exit /b 1
