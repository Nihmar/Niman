@echo off
rem Niman dev helper for Windows hosts: terse output, full logs under
rem %TEMP%\niman. Mirrors scripts/niman.sh and adds the windows build,
rem which cannot be cross-built from Linux.
rem Commands: analyze, test, check, apk [beta], windows.
setlocal enabledelayedexpansion

where flutter >nul 2>&1
if errorlevel 1 (
  echo error: flutter not found - add the Flutter SDK bin directory to PATH 1>&2
  exit /b 1
)

set "cmd=%~1"
rem The apk command's optional product flavor (beta = the testing build).
set "flavor=%~2"
set "logdir=%TEMP%\niman"
if not exist "%logdir%" mkdir "%logdir%"
set "log=%logdir%\niman-%cmd%.log"

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
if "%flavor%"=="beta" (
  rem The testing build (issue #106): the release pipeline plus the
  rem flavor's separate application ID; APP_CHANNEL marks the Dart side,
  rem which hides and skips update management.
  call flutter build apk --release --flavor beta --dart-define=APP_CHANNEL=testing >"%log%" 2>&1
) else (
  rem The official APK (issue #106): AGP drops the no-flavor variant
  rem once the channel dimension has a flavor, so the official build
  rem is the explicit "official" flavor (no application ID suffix).
  call flutter build apk --release --flavor official >"%log%" 2>&1
)
set "status=%errorlevel%"
powershell -NoProfile -Command "Get-Content -Tail 3 '%log%'"
set "name=official"
if "%flavor%"=="beta" set "name=beta"
if "%status%"=="0" echo artifact: build\app\outputs\flutter-apk\app-%name%-release.apk
exit /b %status%

:linux
echo error: the linux build needs a Linux host 1>&2
exit /b 1

:windows
call flutter build windows --release >"%log%" 2>&1
set "status=%errorlevel%"
powershell -NoProfile -Command "Get-Content -Tail 3 '%log%'"
if "%status%"=="0" echo artifact: build\windows\x64\runner\Release\niman.exe
exit /b %status%

:usage
echo usage: scripts\niman.bat ^<analyze^|test^|check^|apk [beta]^|windows^>
echo   analyze  flutter analyze --fatal-infos (issue lines + summary only)
echo   test     flutter test (tail only)
echo   check    analyze + test; use before committing
echo   apk      flutter build apk --release
echo            (beta: the testing build, app ID dev.niman.niman.beta)
echo   windows  flutter build windows --release
echo Full logs: %%TEMP%%\niman\niman-^<cmd^>.log
exit /b 1
