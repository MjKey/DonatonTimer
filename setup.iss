; DonatonTimer v3.0.1 Setup Script
; Автор: MjKey (https://mjkey.ru)
; Проект: https://github.com/MjKey/DonatonTimer
; Inno Setup 6.2+

#define MyAppName "DonatonTimer"
#define MyAppVersion "3.0.1"
#define MyAppPublisher "MjKey"
#define MyAppURL "https://github.com/MjKey/DonatonTimer"
#define MyAppExeName "donaton_timer.exe"
#define MyAppCopyright "Copyright (C) 2025 MjKey"

[Setup]
AppId={{8F4E9A2B-3C5D-4E6F-A7B8-9C0D1E2F3A4B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} v{#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
AppCopyright={#MyAppCopyright}

DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=installer
OutputBaseFilename=DonatonTimer_v{#MyAppVersion}_Setup

; Сжатие
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

; Внешний вид
WizardStyle=modern
WizardSizePercent=120
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

; Права
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; Прочее
AllowNoIcons=yes
DisableProgramGroupPage=yes
Uninstallable=yes
CreateUninstallRegKey=yes

; Версия
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Setup
VersionInfoCopyright={#MyAppCopyright}
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[CustomMessages]
english.LaunchApp=Launch {#MyAppName}
english.CreateDesktopIcon=Create a &desktop shortcut
english.DeleteUserData=Delete user settings and data
english.DeleteUserDataDesc=Remove all saved settings, statistics, and timer data
russian.LaunchApp=Запустить {#MyAppName}
russian.CreateDesktopIcon=Создать ярлык на &рабочем столе
russian.DeleteUserData=Удалить пользовательские данные
russian.DeleteUserDataDesc=Удалить все сохранённые настройки, статистику и данные таймера

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "sound\*"; DestDir: "{app}\sound"; Flags: ignoreversion recursesubdirs createallsubdirs skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchApp}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\sound"
Type: filesandordirs; Name: "{app}\logs.txt"

[Code]
var
  DeleteUserDataCheckBox: TNewCheckBox;

procedure InitializeUninstallProgressForm();
begin
  DeleteUserDataCheckBox := TNewCheckBox.Create(UninstallProgressForm);
  DeleteUserDataCheckBox.Parent := UninstallProgressForm;
  DeleteUserDataCheckBox.Caption := ExpandConstant('{cm:DeleteUserData}');
  DeleteUserDataCheckBox.Hint := ExpandConstant('{cm:DeleteUserDataDesc}');
  DeleteUserDataCheckBox.ShowHint := True;
  DeleteUserDataCheckBox.Left := ScaleX(20);
  DeleteUserDataCheckBox.Top := UninstallProgressForm.StatusLabel.Top + UninstallProgressForm.StatusLabel.Height + ScaleY(20);
  DeleteUserDataCheckBox.Width := UninstallProgressForm.ClientWidth - ScaleX(40);
  DeleteUserDataCheckBox.Checked := False;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  AppDataPath: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    if DeleteUserDataCheckBox.Checked then
    begin
      AppDataPath := ExpandConstant('{userappdata}\MerryJoyKeyStudio\DonatonTimer');
      if DirExists(AppDataPath) then
        DelTree(AppDataPath, True, True, True);
      AppDataPath := ExpandConstant('{userappdata}\MerryJoyKeyStudio');
      RemoveDir(AppDataPath);
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  AppDataPath: String;
begin
  if CurStep = ssPostInstall then
  begin
    AppDataPath := ExpandConstant('{userappdata}\MerryJoyKeyStudio\DonatonTimer');
    if not DirExists(AppDataPath) then
      ForceDirectories(AppDataPath);
  end;
end;
