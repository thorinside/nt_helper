#define MyAppVersion GetEnv("VERSION")
#if MyAppVersion == ""
  #define MyAppVersion "0.0.0"
#endif

[Setup]
AppId={{A6729FC5-2109-41BC-BF6D-6291C48BB178}
AppName=NT Helper
AppVersion={#MyAppVersion}
AppPublisher=No Such
DefaultDirName={localappdata}\Programs\NT Helper
DefaultGroupName=NT Helper
DisableProgramGroupPage=yes
OutputDir=..\..\build\windows\x64\installer
OutputBaseFilename=nt_helper-{#MyAppVersion}-windows-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\nt_helper.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\NT Helper"; Filename: "{app}\nt_helper.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall NT Helper"; Filename: "{uninstallexe}"
Name: "{autodesktop}\NT Helper"; Filename: "{app}\nt_helper.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\nt_helper.exe"; WorkingDir: "{app}"; Description: "{cm:LaunchProgram,NT Helper}"; Flags: nowait postinstall skipifsilent
