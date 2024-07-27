[Setup]
AppName=Донатон Таймер
AppVersion=2.0.1
DefaultDirName={pf}\DTimer
DefaultGroupName=Донатон
OutputBaseFilename=DTimer Setup
Compression=lzma
SolidCompression=yes
SetupIconFile=Донатон Таймер.ico

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Донатон Таймер"; Filename: "{app}\donat_timer.exe";
Name: "{group}\Удалить Донатон Таймер"; Filename: "{app}\unins000.exe";
Name: "{userdesktop}\Донатон Таймер"; Filename: "{app}\donat_timer.exe"

[Run]
Filename: "{app}\donat_timer.exe"; Description: "Запустить Таймер Донатона"; Flags: nowait postinstall skipifsilent

