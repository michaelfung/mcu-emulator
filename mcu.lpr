program mcu;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main, readthread, Settings, about, sockthread
  { you can add units after this };

{$R *.res}

begin
  Application.Title:='MCU Emulator';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmSettings, fmSettings);
  Application.Run;
end.

