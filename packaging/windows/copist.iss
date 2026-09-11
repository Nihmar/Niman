; Copist Windows installer script for Inno Setup 6.
; Built by CI (.github/workflows/release.yml) on every v* tag — run from the
; repo root so the relative paths below resolve:
;   iscc packaging\windows\copist.iss /DAppVersion=1.2.3
; Local build first: scripts\copist.bat windows

#define FallbackVersion "1.0.0"
#ifndef AppVersion
  #define AppVersion FallbackVersion
#endif

[Setup]
AppId={{5d97e92e-e092-4dca-ab38-6c0f44765bf9}
AppName=Copist
AppVersion={#AppVersion}
AppVerName=Copist {#AppVersion}
AppPublisher=Copist contributors
AppPublisherURL=https://github.com/Nihmar/Copist
AppSupportURL=https://github.com/Nihmar/Copist/issues
DefaultDirName={autopf}\Copist
DefaultGroupName=Copist
OutputDir=..\..\dist
OutputBaseFilename=copist-{#AppVersion}-windows-x64-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
UninstallDisplayName=Copist
DisableProgramGroupPage=yes
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\copist.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Copist"; Filename: "{app}\copist.exe"
Name: "{autodesktop}\Copist"; Filename: "{app}\copist.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\copist.exe"; Description: "{cm:LaunchProgram,Copist}"; Flags: nowait postinstall skipifsilent
