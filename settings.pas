unit Settings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls;

type

  { TfmSettings }

  TfmSettings = class(TForm)
    btnSave: TButton;
    btnCancel: TButton;
    cbUseSSL: TCheckBox;
    cbConnectOnStart: TCheckBox;
    cbAutoReConnect: TCheckBox;
    edControllerID: TLabeledEdit;
    edMfgCode: TLabeledEdit;
    edServerName: TLabeledEdit;
    edServerPort: TLabeledEdit;
    edSuperKey: TLabeledEdit;
    edUserKey: TLabeledEdit;
    Label1: TLabel;
    PageControl1: TPageControl;
    tsSecurity: TTabSheet;
    tsGeneral: TTabSheet;
    procedure btnSaveClick(Sender: TObject);
    procedure edConfigChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fmSettings: TfmSettings;
//ConfIni: Tinifile;

implementation

{$R *.lfm}

uses
  main;

// save the settings to the ini file

{ TfmSettings }

procedure TfmSettings.btnSaveClick(Sender: TObject);
begin
  ConfIni.WriteString('Default', 'MCUID', edControllerID.Text);
  ConfIni.WriteString('Default', 'MfgCode', edMfgCode.Text);
  ConfIni.WriteString('Default', 'ServerName', edServerName.Text);
  ConfIni.WriteString('Default', 'ServerPort', edServerPort.Text);
  //ConfIni.WriteBool('Default', 'RestoreStatus', cbRestoreStatus.Checked);
  ConfIni.WriteBool('Default', 'UseSSL', cbUseSSL.Checked);
  ConfIni.WriteBool('Default', 'AutoReConnect', cbAutoReConnect.Checked);
  ConfIni.WriteBool('Default', 'ConnectOnStart', cbConnectOnStart.Checked);
  ConfIni.WriteString('Default', 'SuperKey', edSuperKey.Text);
  ConfIni.WriteString('Default', 'UserKey', edUserKey.Text);
end;

procedure TfmSettings.edConfigChange(Sender: TObject);
begin
  fmMain.NeedReload := True;
end;


procedure TfmSettings.FormShow(Sender: TObject);
begin
  // load ini values
  edControllerID.Text := ConfIni.ReadString('Default', 'MCUID', '');
  edMfgCode.Text := ConfIni.ReadString('Default', 'MfgCode', '');
  edServerName.Text := ConfIni.ReadString('Default', 'ServerName', '');
  edServerPort.Text := ConfIni.ReadString('Default', 'ServerPort', '');
  cbUseSSL.Checked := ConfIni.ReadBool('Default', 'UseSSL', True);
  cbAutoReConnect.Checked := ConfIni.ReadBool('Default', 'AutoReConnect', True);
  cbConnectOnStart.Checked := ConfIni.ReadBool('Default', 'ConnectOnStart', True);
 // cbRestoreStatus.Checked := ConfIni.ReadBool('Default', 'RestoreStatus', True);
  edSuperKey.Text := ConfIni.ReadString('Default', 'SuperKey', '90909090');
  edUserKey.Text := ConfIni.ReadString('Default', 'UserKey', '10101010');

end;


end.

