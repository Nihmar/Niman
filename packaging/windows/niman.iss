; Niman Windows installer script for Inno Setup 6.
; Built by CI (.github/workflows/release.yml) on every v* tag — run from the
; repo root so the relative paths below resolve:
;   iscc packaging\windows\niman.iss /DAppVersion=1.2.3
; Local build first: scripts\niman.bat windows

#define FallbackVersion "1.0.0"
#ifndef AppVersion
  #define AppVersion FallbackVersion
#endif

[Setup]
AppId={{5d97e92e-e092-4dca-ab38-6c0f44765bf9}
AppName=Niman
AppVersion={#AppVersion}
AppVerName=Niman {#AppVersion}
AppPublisher=Niman contributors
AppPublisherURL=https://github.com/Nihmar/Niman
AppSupportURL=https://github.com/Nihmar/Niman/issues
DefaultDirName={autopf}\Niman
DefaultGroupName=Niman
OutputDir=..\..\dist
OutputBaseFilename=niman-{#AppVersion}-windows-x64-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
UninstallDisplayName=Niman
DisableProgramGroupPage=yes
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\niman.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Niman"; Filename: "{app}\niman.exe"
Name: "{autodesktop}\Niman"; Filename: "{app}\niman.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\niman.exe"; Description: "{cm:LaunchProgram,Niman}"; Flags: nowait postinstall skipifsilent
