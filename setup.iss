[Setup]
AppName=Донатон Таймер
AppVersion=2.0.3
DefaultDirName={pf}\DTimer
DefaultGroupName=Донатон
OutputBaseFilename=DTimer Setup
Compression=lzma
SolidCompression=yes
SetupIconFile=Донатон Таймер.ico
WizardStyle=modern

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Донатон Таймер"; Filename: "{app}\donat_timer.exe";
Name: "{group}\Удалить Донатон Таймер"; Filename: "{app}\unins000.exe";
Name: "{userdesktop}\Донатон Таймер"; Filename: "{app}\donat_timer.exe"

[Run]
Filename: "{app}\donat_timer.exe"; Description: "Запустить Таймер Донатона"; Flags: nowait postinstall skipifsilent

[Code]
var
  DeleteSettingsAndFiles: Boolean;

procedure InitializeUninstallProgressForm();
begin
  DeleteSettingsAndFiles := False;
  if MsgBox(ExpandConstant('{cm:DeleteSettingsPrompt}'), mbConfirmation, MB_YESNO) = IDYES then
  begin
    DeleteSettingsAndFiles := True;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if (CurUninstallStep = usPostUninstall) and DeleteSettingsAndFiles then
  begin
    DelTree(ExpandConstant('{userappdata}\MjKey Studio'), True, True, True);
    DelTree(ExpandConstant('{app}'), True, True, True);
  end;
end;

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[CustomMessages]
ru.SetupWindowTitle=Установка Донатон Таймера
ru.DeleteSettingsPrompt=Вы хотите удалить настройки и все файлы программы?
en.SetupWindowTitle=Installation of Donathon Timer
en.DeleteSettingsPrompt=Do you want to delete settings and all program files?