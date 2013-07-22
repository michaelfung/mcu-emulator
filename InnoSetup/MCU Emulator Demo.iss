#define OutputFN "MCUEmulatorSetup-" + GetDateTimeString('yymmddhh','','')

[Setup]
ShowLanguageDialog=no
AppName=MCU Emulator for Domotics Application
AppVersion=0.8
AppCopyright=Copyright 2013 Michael Fung
PrivilegesRequired=none
AppId={{3D2C58A2-B014-47C8-8E3B-22296BB6D45C}
DefaultDirName={pf}\MCU Emulator
MinVersion=0,5.01sp3
AppPublisher=Michael Fung
OutputBaseFilename={#OutputFN}
DefaultGroupName=MCU Emulator

[Files]
Source: "..\burglar-alarm.wav"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\images.lrs"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\ssleay32.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\libeay32.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\mcu.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\mcu.ico"; DestDir: "{app}"
Source: ".\demo\mcu.ini"; DestDir: "{localappdata}\MCU Emulator"; Flags: onlyifdoesntexist
Source: ".\demo\mcu.log"; DestDir: "{localappdata}\MCU Emulator"; Flags: onlyifdoesntexist
Source: ".\demo\cacert.pem"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{userdesktop}\MCU Emulator"; Filename: "{app}\mcu.exe"; WorkingDir: "{app}"; IconFilename: "{app}\mcu.ico"; Tasks: DesktopIcon
Name: "{group}\MCU Emulator"; Filename: "{app}\mcu.exe"; WorkingDir: "{app}"; IconFilename: "{app}\mcu.ico"
Name: "{group}\View Debug Log"; Filename: "{localappdata}\MCU Emulator\mcu.log"; WorkingDir: "{app}"; 
Name: "{group}\Uninstall MCU Emulator"; Filename: "{uninstallexe}"; WorkingDir: "{app}"

[Tasks]
Name: "DesktopIcon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Dirs]
Name: "{localappdata}\MCU Emulator"
