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
; The .md association below (#41): Explorer re-reads it on install and
; uninstall.
ChangesAssociations=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "mdassoc"; Description: "{cm:AssocFileExtension,Niman,.md}"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Markdown files open in Niman (#41). Per user, like the rest of the
; install (PrivilegesRequired=lowest). Niman is added to the files' "Open
; with" list; Windows keeps the choice of default app to the user, so it
; becomes the default only when nothing else claims .md, or when picked.
[Registry]
Root: HKCU; Subkey: "Software\Classes\Niman.Markdown"; ValueType: string; ValueName: ""; ValueData: "Markdown document"; Flags: uninsdeletekey; Tasks: mdassoc
Root: HKCU; Subkey: "Software\Classes\Niman.Markdown\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\niman.exe,0"; Tasks: mdassoc
Root: HKCU; Subkey: "Software\Classes\Niman.Markdown\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\niman.exe"" ""%1"""; Tasks: mdassoc
Root: HKCU; Subkey: "Software\Classes\.md\OpenWithProgids"; ValueType: string; ValueName: "Niman.Markdown"; ValueData: ""; Flags: uninsdeletevalue; Tasks: mdassoc
Root: HKCU; Subkey: "Software\Classes\.markdown\OpenWithProgids"; ValueType: string; ValueName: "Niman.Markdown"; ValueData: ""; Flags: uninsdeletevalue; Tasks: mdassoc
Root: HKCU; Subkey: "Software\Classes\Applications\niman.exe\SupportedTypes"; ValueType: string; ValueName: ".md"; ValueData: ""; Flags: uninsdeletekey; Tasks: mdassoc
Root: HKCU; Subkey: "Software\Classes\Applications\niman.exe\SupportedTypes"; ValueType: string; ValueName: ".markdown"; ValueData: ""; Tasks: mdassoc

[Icons]
Name: "{autoprograms}\Niman"; Filename: "{app}\niman.exe"
Name: "{autodesktop}\Niman"; Filename: "{app}\niman.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\niman.exe"; Description: "{cm:LaunchProgram,Niman}"; Flags: nowait postinstall skipifsilent
