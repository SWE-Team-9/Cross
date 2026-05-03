[Setup]
AppName=Cross
AppVersion={#AppVersion}
AppPublisher=SWE-Team-9
DefaultDirName={autopf}\Cross
DefaultGroupName=Cross
OutputDir=installer-output
OutputBaseFilename=Cross-windows-setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\..\windows\runner\resources\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Cross"; Filename: "{app}\cross.exe"
Name: "{userdesktop}\Cross"; Filename: "{app}\cross.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\cross.exe"; Description: "Launch Cross"; Flags: nowait postinstall skipifsilent
