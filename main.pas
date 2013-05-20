unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ActnList, Menus, DateUtils, fpjson, jsonparser, blcksock, synsock,
  ssl_openssl, StrUtils, fptimer, typinfo, readthread, sockthread, MMSystem, LResources,
  Inifiles, Settings, About, Windows;

type

  { TfmMain }

  TfmMain = class(TForm)
    acQuit: TAction;
    acPowerControlOn: TAction;
    acPowerControlOff: TAction;
    acResetContactSensor: TAction;
    acArmAlarm: TAction;
    acDisarmAlarm: TAction;
    acAbout: TAction;
    acPowerOffMCU: TAction;
    acPowerOnMCU: TAction;
    acSendStatus: TAction;
    acShowSettingsForm: TAction;
    acSaveSettings: TAction;
    acInjectFrame: TAction;
    acManPowerControlOff: TAction;
    acManPowerControlOn: TAction;
    acManArmAlarm: TAction;
    acManDisarmAlarm: TAction;
    acClearLog: TAction;
    acViewStats: TAction;
    acViewLog: TAction;
    acToggleLogKeepalive: TAction;
    acToggleAutoReconnect: TAction;
    acTriggerContactSensor: TAction;
    alMain: TActionList;
    imgMCU: TImage;
    imgSirenSound: TImage;
    imgNetErr: TImage;
    imgAlarm: TImage;
    imgConnection: TImage;
    imgBurglar: TImage;
    imgHouse: TImage;
    lblMCUID: TLabel;
    lblMCUKey: TLabel;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem20: TMenuItem;
    MenuItem21: TMenuItem;
    MenuItem22: TMenuItem;
    miLogKeepalive: TMenuItem;
    miOptions: TMenuItem;
    miSep3: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    miSep2: TMenuItem;
    miExit: TMenuItem;
    miHelp: TMenuItem;
    miTest: TMenuItem;
    miFile: TMenuItem;
    menuMain: TMainMenu;
    moLog: TMemo;
    timerKeepConnect: TTimer;
    //timerKeepAlive: TTimer;
    procedure acAboutExecute(Sender: TObject);
    procedure acArmAlarmExecute(Sender: TObject);
    procedure acClearLogExecute(Sender: TObject);
    procedure acPowerOnMCUExecute(Sender: TObject);
    procedure acPowerOnMCUUpdate(Sender: TObject);
    procedure acDisarmAlarmExecute(Sender: TObject);
    procedure acPowerOffMCUExecute(Sender: TObject);
    procedure acPowerOffMCUUpdate(Sender: TObject);
    procedure acEnableAutoReConnectExecute(Sender: TObject);
    procedure acInjectFrameExecute(Sender: TObject);
    procedure acManArmAlarmExecute(Sender: TObject);
    procedure acManDisarmAlarmExecute(Sender: TObject);
    procedure acManPowerControlOffExecute(Sender: TObject);
    procedure acManPowerControlOnExecute(Sender: TObject);
    procedure acShowSettingsFormExecute(Sender: TObject);
    procedure acPowerControlOffExecute(Sender: TObject);
    procedure acPowerControlOnExecute(Sender: TObject);
    procedure acQuitExecute(Sender: TObject);
    procedure acResetContactSensorExecute(Sender: TObject);
    procedure acSendStatusExecute(Sender: TObject);
    procedure acToggleLogKeepaliveExecute(Sender: TObject);
    procedure acTriggerContactSensorExecute(Sender: TObject);
    procedure acViewLogExecute(Sender: TObject);
    procedure acViewStatsExecute(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure timerKeepConnectTimer(Sender: TObject);

  private
    { private declarations }
    fSockConnected: Boolean;
    fPowerControl1: Boolean;
    fContactSensor1: Boolean;
    fAlarmArmed: Boolean;
    fAlarmFired: Boolean;

    procedure SetSockConnected(AState: Boolean);
    procedure SetPowerControl1(AState: Boolean);
    procedure SetContactSensor1(AState: Boolean);
    procedure SetAlarmArmed(AState: Boolean);
  public
    { public declarations }
    fMCUID: String;
    fMfgCode: String;
    NeedReload: Boolean;
    UseSSL: Boolean;
    procedure mylog(msg: String);
    procedure LoadConfig;
    procedure ProcessRequest(Request: String);
    procedure SoundAlarm(AState: Boolean);
    procedure CheckSockStatus(Sender: TObject; Reason: THookSocketReason;
      const Value: Ansistring);
    procedure SendStatus(RequestCode: String);
    procedure SendAuthRequest;
    procedure SetupSock;
    procedure DoOnConnected;
    procedure DoReadReq(parsed: Tjsonobject);
    procedure DoSetReq(parsed: Tjsonobject);
    procedure DoVerifyKeyReq(parsed: Tjsonobject);
    procedure DoSetKeyReq(parsed: Tjsonobject);

    function GetStatus: TJSONArray;

    property SockConnected: Boolean read fSockConnected write SetSockConnected;
    // devices:
    property PowerControl1: Boolean read fPowerControl1 write SetPowerControl1;
    property ContactSensor1: Boolean read fContactSensor1 write SetContactSensor1;
    property AlarmArmed: Boolean read fAlarmArmed write SetAlarmArmed;

  end;

{ functions }
function DoConnect: Boolean;
function GetUnixTimeStamp: Int64;

{ procedures }
procedure DoDisconnect;
procedure DoSend(msg: String);

var
  fmMain: TfmMain;
  mysock: TTCPBlockSocket;
  ConfIni: Tinifile;
  LogFilePath: String;
  INIFilePath: String;

  ServerName: String;
  ServerPort: String;
  SuperKey: String;
  UserKey: String;
  HasSuperKey: Boolean = False;
  myReadThread: TReadThread;
  mySockThread: TSockThread;
  AutoReConnect: Boolean = True;
  ConnectOnStart: Boolean = False;
  LogKeepalive: Boolean = True;
  timerKeepAlive: TFPTimer;
  IsMCUPowerOn: Boolean = False;

const
  AppModel = 'Win32EMU';
  AppVersion = '0.7';
  AppProtocol = 3;

  KeepAlivePing = 'PING';
  KeepAlivePong = 'PONG';

implementation


{$R *.lfm}

{ TfmMain }

procedure TfmMain.mylog(msg: String);
begin
  // control memory usage of moLog
  if (moLog.Lines.Count > 5000) then
    moLog.Lines.Delete(0);
  moLog.Lines.Append('[' + DateTimeToStr(NOW()) + '] ' + msg);
end;

procedure TfmMain.LoadConfig;
begin
  // Read Params from INI file
  ConfIni := Tinifile.Create(INIFilePath);
  fMCUID := ConfIni.ReadString('Default', 'MCUID', 'To-Be-Set');
  fMfgCode := ConfIni.ReadString('Default', 'MfgCode', '12345678');
  ServerName := ConfIni.ReadString('Default', 'ServerName', 'localhost');
  ServerPort := ConfIni.ReadString('Default', 'ServerPort', '9123');
  UseSSL := ConfIni.ReadBool('Default', 'UseSSL', True);
  //AutoReConnect := ConfIni.ReadBool('Default', 'AutoReConnect', False);
  ConnectOnStart := ConfIni.ReadBool('Default', 'ConnectOnStart', False);
  SuperKey := ConfIni.ReadString('Default', 'SuperKey', '90909090');
  UserKey := ConfIni.ReadString('Default', 'UserKey', '10101010');
end;

function TfmMain.GetStatus: TJSONArray;
begin
  //Result := TJsonObject.Create;
  try
    Result := TJSONArray.Create(
      [TJSONObject.Create(['type', 'power_control', 'device_id', '1',
      'power', TJSONBoolean.Create(PowerControl1)]),
      TJSONObject.Create(['type', 'contact_sensor', 'device_id',
      '2', 'contact', TJSONBoolean.Create(ContactSensor1)]),
      TJSONObject.Create(['type', 'alarm', 'device_id', '3', 'arm',
      TJSONBoolean.Create(AlarmArmed), 'fire', TJSONBoolean.Create(fAlarmFired)])]);

  except
    Result.Free;
  end;

end;

procedure TfmMain.SetSockConnected(AState: Boolean);
begin
  fSockConnected := AState;
  imgNetErr.Visible := not AState;
end;

procedure TfmMain.SoundAlarm(AState: Boolean);
begin
  if AState then
  begin
    mylog('Sounding Alarm RRR...RRR...RRR...');
    imgSirenSound.Visible := True;
    fAlarmFired := True;
    sndPlaySound('burglar-alarm.wav', SND_NODEFAULT or SND_ASYNC or SND_LOOP);
  end
  else
  begin
    mylog('Alarm silenced.');
    imgSirenSound.Visible := False;
    fAlarmFired := False;
    sndPlaySound(nil, 0); // Stops the sound
  end;

end;

procedure TfmMain.SetPowerControl1(AState: Boolean);
begin
  if fPowerControl1 = AState then
    exit;

  fPowerControl1 := AState;
  // switch room image
  if AState then
    //imgHouse.Picture.LoadFromFile('room.png')
    imgHouse.Picture.LoadFromLazarusResource('room')
  else
    //imgHouse.Picture.LoadFromFile('room-dark.png');
    imgHouse.Picture.LoadFromLazarusResource('room-dark');
end;

procedure TfmMain.SetContactSensor1(AState: Boolean);
begin
  if fContactSensor1 = AState then
    exit;

  // false: contact opened, sensor triggered
  // true: contact closed
  fContactSensor1 := AState;
  // switch burglar image
  if not AState then
  begin
    imgBurglar.Visible := True;
    if AlarmARmed then
    begin
      // sound siren
      imgSirenSound.Visible := True;
      SoundAlarm(True);
    end;
  end
  else
  begin
    imgBurglar.Visible := False;
    //imgAlarm.Picture.LoadFromLazarusResource('alarm-armed');
  end;
end;

procedure TfmMain.SetAlarmArmed(AState: Boolean);
begin
  if fAlarmArmed = AState then
    exit;

  fAlarmArmed := AState;

  // switch alarm image
  if AState then
  begin
    // arm
    imgAlarm.Picture.LoadFromLazarusResource('alarm-armed');
    if (not ContactSensor1) then
    begin
      // sound the alarm if sensor already triggered
      SoundAlarm(True);
    end;
  end
  else
  begin
    // disarm
    imgAlarm.Picture.LoadFromLazarusResource('alarm-disarmed');
    SoundAlarm(False);
  end;
end;

procedure TfmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  DoDisconnect;
  { Save a copy of the molog to disk as mcu.log }
  mylog('=== Application Terminates ===');
  // moLog.Lines.SaveToFile(GetAppConfigDir(False) + 'mcu.log');
  moLog.Lines.SaveToFile(LogFilePath);

  mySockThread.Free;
  ConfIni.Free;
  mysock.Free;
  CloseAction := caFree;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  // set properties defaults
  fAlarmArmed := False;
  fContactSEnsor1 := True;
  fPowerControl1 := False;
  imgHouse.Picture.LoadFromLazarusResource('room-dark');
  imgAlarm.Picture.LoadFromLazarusResource('alarm-disarmed');
  SockConnected := False;
  LogFilePath := GetAppConfigDir(False) + 'mcu.log';
  INIFilePath := GetAppConfigDir(False) + 'mcu.ini';

  // Read Params from INI file
  LoadConfig;

  // setup network connection
  SetupSock;
  timerKeepConnect.Enabled := True; // always true

  // create objects
  mySockThread := TSockThread.Create(mysock, UseSSL);
  mySockThread.OnDoLog := @fmMain.mylog;
  mysockThread.OnConnected := @fmMain.DoOnConnected;

  mylog('=== Application Starts ===');
  // mylog('LogFilePath: ' +  LogFilePath); // debug

end;

procedure TfmMain.SetupSock;
begin
  FreeAndNil(mysock);

  if (UseSSL) then
  begin
    mysock := TTCPBlockSocket.CreateWithSSL(TSSLOpenSSL);
    mysock.SSL.CertCAFile := 'cacert.pem';
  end
  else
  begin
    mysock := TTCPBlockSocket.Create;
  end;
  mysock.OnStatus := (@CheckSockStatus);
end;

procedure TfmMain.FormActivate(Sender: TObject);
begin
  // setup visual components
  //miAutoReconnect.Checked := AutoReconnect;
  miTest.Enabled := False;
  miLogKeepalive.Checked := LogKeepalive;
  lblMCUID.Caption := 'MCU ID: ' + fMCUID;
  lblMCUKey.Caption := 'Super Key: ' + SuperKey;

  if (ConnectOnStart) then
  begin
    acPowerOnMCU.Execute;
  end;

end;

procedure TfmMain.acQuitExecute(Sender: TObject);
begin
  acPowerOffMCU.Execute;
  Close;
end;

procedure TfmMain.acResetContactSensorExecute(Sender: TObject);
begin
  ContactSensor1 := True;
  SendStatus('');
end;

procedure TfmMain.acSendStatusExecute(Sender: TObject);
begin
  SendStatus('');
end;

procedure TfmMain.acToggleLogKeepaliveExecute(Sender: TObject);
begin
  LogKeepalive := not LogKeepalive;
  miLogKeepalive.Checked := LogKeepalive;
  if assigned(myReadThread) then
    myReadThread.LogKeepalive := LogKeepalive;
end;

procedure TfmMain.acTriggerContactSensorExecute(Sender: TObject);
begin
  ContactSensor1 := False;
  SendStatus('');
end;

procedure TfmMain.acViewLogExecute(Sender: TObject);
begin
  moLog.Lines.SaveToFile(LogFilePath);
  ShellExecute(0, nil, PChar('notepad'), PChar(LogFilePath), nil, 1);
end;

procedure TfmMain.acViewStatsExecute(Sender: TObject);
begin
  // Show the statistics form
end;

procedure TfmMain.acPowerControlOnExecute(Sender: TObject);
var
  request: String;
begin
  request := '{ "id" : 1, "layer":"app", "op" : "set", "mcu_id" : "' +
    fMCUID + '", "devices" : [ {"device_id":"1", "power":true} ] }';
  ProcessRequest(request);
end;

procedure TfmMain.acPowerControlOffExecute(Sender: TObject);
var
  request: String;
begin
  request := '{ "id" : 1, "layer":"app", "op" : "set", "mcu_id" : "' +
    fMCUID + '", "devices" : [ {"device_id":"1", "power":false} ] }';
  ProcessRequest(request);
end;

procedure TfmMain.acArmAlarmExecute(Sender: TObject);
var
  request: String;
begin
  request := '{ "id" : 1, "layer":"app", "op" : "set", "mcu_id" : "' +
    fMCUID + '", "devices" : [ {"device_id":"3", "arm":true} ] }';
  ProcessRequest(request);
end;

procedure TfmMain.acClearLogExecute(Sender: TObject);
begin
  moLog.Lines.Clear;
end;

procedure TfmMain.acPowerOnMCUExecute(Sender: TObject);
begin
  if ((fmMain.fMCUID = 'To-Be-Set') or (fmMain.fMCUID = '')) then
  begin
    MessageDlg('Please contact us to get a valid MCU ID.',
      mtInformation, [mbOK], 0);
    exit;
  end;

  IsMCUPowerOn := True;
  miTest.Enabled := True;
  imgMCU.Picture.LoadFromLazarusResource('mcu-on');
  DoConnect;
  // timerKeepConnect.Enabled := True;
end;

procedure TfmMain.acPowerOnMCUUpdate(Sender: TObject);
begin
  acPowerOnMCU.Enabled := not IsMCUPowerOn;
end;

procedure TfmMain.acAboutExecute(Sender: TObject);
var
  myAbout: TfmAbout;
begin
  // show the about window
  myAbout := TfmAbout.Create(nil);
  try
    myAbout.lblVersion.Caption := AppVersion;
    myAbout.lblProtocol.Caption := IntToStr(AppProtocol);
    myAbout.ShowModal;

  finally
    FreeAndNil(myAbout);
  end;
end;

procedure TfmMain.acDisarmAlarmExecute(Sender: TObject);
var
  request: String;
begin
  request := '{ "id" : 1, "layer":"app", "op" : "set", "mcu_id" : "' +
    fMCUID + '", "devices" : [ {"device_id":"3", "arm":false} ] }';
  ProcessRequest(request);
end;

procedure TfmMain.acPowerOffMCUExecute(Sender: TObject);
begin
  // disconnect
  IsMCUPowerOn := False;
  miTest.Enabled := False;
  imgMCU.Picture.LoadFromLazarusResource('mcu-off');
  DoDisconnect;
end;

procedure TfmMain.acPowerOffMCUUpdate(Sender: TObject);
begin
  acPowerOffMCU.Enabled := IsMCUPowerOn;
end;

procedure TfmMain.acEnableAutoReConnectExecute(Sender: TObject);
begin
  //  AutoReConnect := True;
  //  miAutoReConnect.Checked:= true;
end;

procedure TfmMain.acInjectFrameExecute(Sender: TObject);
var
  Frame: String;
begin
  // open dialog to get a line of json text
  Frame := '{"id":1,"layer":"app","op":"noop"}';
  if InputQuery('Inject Frame', 'Enter JSON String', Frame) then
    ProcessRequest(Frame);
end;

procedure TfmMain.acManArmAlarmExecute(Sender: TObject);
begin
  AlarmArmed := True;
  SendStatus('');
end;

procedure TfmMain.acManDisarmAlarmExecute(Sender: TObject);
begin
  AlarmArmed := False;
  SendStatus('');
end;

procedure TfmMain.acManPowerControlOffExecute(Sender: TObject);
begin
  PowerControl1 := False;
  SendStatus('');
end;

procedure TfmMain.acManPowerControlOnExecute(Sender: TObject);
begin
  PowerControl1 := True;
  SendStatus('');
end;


procedure TfmMain.acShowSettingsFormExecute(Sender: TObject);
begin
  // open the options form in modal
  if ((fmSettings.ShowModal = mrOk) and NeedReload) then
  begin
    // disconnect and reload config
    acPowerOffMCU.Execute;
    LoadConfig;
    lblMCUID.Caption := 'MCU ID: ' + fmMain.fMCUID;
    lblMCUKey.Caption := 'Super Key: ' + SuperKey;
    // reset NeedReload
    NeedReload := False;
    if MessageDlg('Restart MCU with new settings?', mtConfirmation,
      [mbYes, mbNo], 0) = mrYes then
    begin
      acPowerOnMCU.Execute;
    end;
  end;
end;


procedure TfmMain.timerKeepConnectTimer(Sender: TObject);
begin
  if (SockConnected or (not IsMCUPowerOn)) then
    exit;

  timerKeepConnect.Enabled := False;
  DoConnect;
  timerKeepConnect.Enabled := True;
end;

procedure TfmMain.SendAuthRequest;
var
  J: TJSONObject;
begin
  // return if disconnected
  if not SockConnected then
    exit;

  // generate JSON string
  J := TJSONObject.Create;
  try
    J.Add('id', 1);
    J.Add('date', TJSONInt64Number.Create(GetUnixTimeStamp));
    J.Add('layer', 'ssn');
    J.Add('op', 'auth');
    //J.Add('type', 'q');
    J.Add('params', TJSONObject.Create(['mcu_id', fMCUID, 'mfg_code',
      fMfgCode, 'model', AppModel, 'version', AppVersion, 'protocol',
      AppProtocol, 'super_key', SuperKey, 'user_key', UserKey]));

    mylog('Send:' + J.AsJSON);

    // return if disconnected
    // if not SockConnected then exit;

    // Send using mysock
    mysock.SendString(J.AsJSON + CRLF);

  finally
    J.Free;

  end;
end;

procedure TfmMain.SendStatus(RequestCode: String);
var
  J: TJSONObject;
begin
  // return if disconnected
  if not SockConnected then
    exit;

  // generate JSON string
  J := TJSONObject.Create;
  try
    if (RequestCode <> '') then
      J.Add('id', RequestCode);

    J.Add('date', TJSONInt64Number.Create(GetUnixTimeStamp));
    J.Add('layer', 'app');
    J.Add('op', 'status');
    J.Add('mcu_id', fMCUID);
    J.Add('devices', GetStatus);


    // boolean may be replaced by TJSONIntegerNumber in future

    mylog('Send:' + J.AsJSON);

    // return if disconnected
    // if not SockConnected then exit;

    // Send using mysock
    mysock.SendString(J.AsJSON + CRLF);

  finally
    J.Free;

  end;
end;

//class procedure MyCallback.Status(Sender: TObject; Reason: THookSocketReason; const Value: string);
procedure TfmMain.CheckSockStatus(Sender: TObject; Reason: THookSocketReason;
  const Value: Ansistring);
var
  v: String;
begin
  // ignore these states:
  if (reason = hr_readcount) or (reason = hr_writecount) or
    (reason = hr_canread) or ((reason = HR_Error) and AnsiStartsText('10060', Value))
  then  //timeout
    exit;

  // try to detect disconnect
  if (reason = HR_SocketClose) then
  begin
    SockConnected := False;
    if assigned(myReadThread) then
      myReadThread.terminate;
  end;

  //// reset the socket
  //if (reason = HR_Error) and AnsiStartsText('10056', Value) then
  //begin
  //     SockConnected := False;
  //  if assigned(myReadThread) then
  //    myReadThread.terminate;
  //     mysock.CloseSocket;
  //end;

  if (reason = HR_Error) then
  begin
    SockConnected := False;
    if assigned(myReadThread) then
      myReadThread.terminate;
    mysock.CloseSocket;

  end;

  v := getEnumName(typeinfo(THookSocketReason), Integer(Reason)) + ':' + Value;
  mylog('Sock Status:' + v);
end;

procedure TfmMain.DoOnConnected;
begin
  SockConnected := True;
  SendAuthRequest;
  SendStatus('');
  myReadThread := TReadThread.Create(mysock);
  myReadThread.KeepaliveInterval := 50;
  myReadThread.LogKeepalive := LogKeepalive;
  myReadThread.OnDoLog := @fmMain.mylog;
  myReadThread.OnRequest := @fmMain.ProcessRequest;
end;

function DoConnect(): Boolean;
begin
  Result := False;

  if fmMain.SockConnected then
  begin
    fmMain.mylog('Already connected!');
    Result := True;
    exit;
  end;

  // start the Sockthread if not started
  if (mysockthread.Suspended) then
  begin
    mysockthread.Execute;
  end;

end;

procedure DoDisconnect();
begin
  if fmMain.SockConnected then
  begin
    { tell server to clean up and disconnect }
    mysock.SendString('QUIT' + CRLF);
    mysock.CloseSocket;
  end;
end;

procedure DoSend(msg: String);
begin
  mysock.SendString(msg + CRLF);
end;

function GetUnixTimeStamp: Int64;
begin
  { TODO : Fix 'DateTimeToUnix not locale aware' problem }
  Result := DateTimeToUnix(Now) - (8 * 3600);
end;

procedure TfmMain.DoReadReq(parsed: Tjsonobject);
begin
  // generate result envelope header
  parsed.Add('result', Tjsonboolean.Create(True));
  parsed.Int64s['date'] := GetUnixTimeStamp;

  // append the data
  parsed.Add('devices', fmMain.GetStatus);
  // send it
  mylog('Send:' + parsed.AsJSON);
  mysock.SendString(parsed.AsJSON + CRLF);
end;

procedure TfmMain.DoSetReq(parsed: Tjsonobject);
var
  devices: TJSONArray;
  i: Integer;
begin

  // require superkey for these operations
  //if (not HasSuperKey) then
  //  raise EMyException.Create('Access Denied: Super Key required.');

  //devices := TJSONArray(parsed.Elements['devices']);
  devices := parsed.Arrays['devices'];
  for i := 0 to devices.Count - 1 do
  begin
    with tjsonobject(devices.Items[i]) do
    begin

      // so set the device
      if (Strings['device_id'] = '1') then  // power control on/off
      begin
        PowerControl1 := Booleans['power'];
        mylog('ProcessRequest: device ID: ' + Strings['device_id'] +
          ' set to: ' + Strings['power']);
      end;
      if (Strings['device_id'] = '3') then // alarm on/off
      begin
        AlarmArmed := Booleans['arm'];
        mylog('ProcessRequest: device ID: ' + Strings['device_id'] +
          ' set to: ' + Strings['arm']);
      end;
    end;
  end;
  SendStatus(parsed.Strings['id']);
end;

procedure TfmMain.DoVerifyKeyReq(parsed: Tjsonobject);
var
  privilege: String;
begin
  if (HasSuperKey) then
    privilege := 'super'
  else
    privilege := 'user';

  parsed.Add('result', Tjsonboolean.Create(True));
  parsed.Add('params', Tjsonobject.Create(['privilege', privilege]));

  // send it
  mylog('Send:' + parsed.AsJSON);
  mysock.SendString(parsed.AsJSON + CRLF);
end;

procedure TfmMain.DoSetKeyReq(parsed: Tjsonobject);
var
  params: Tjsonobject;
begin
  { TODO : Remove security sensitive info in error messages. }
  if (not HasSuperKey) then
    raise EMyException.Create('Access Denied: Super Key required.');

  if (parsed.IndexOfName('params') = -1) then
    raise EMyException.Create('Missing parameters.');

  params := parsed.Objects['params'];

  if (params.IndexOfName('super_key') <> -1) then
  begin
    SuperKey := params.Strings['super_key'];
    ConfIni.WriteString('Default', 'SuperKey', SuperKey);
  end;

  if (params.IndexOfName('user_key') <> -1) then
  begin
    Userkey := params.Strings['user_key'];
    ConfIni.WriteString('Default', 'UserKey', Userkey);
  end;

  // reply result
  parsed.Add('result', True);
  mylog('Send:' + parsed.AsJSON);
  mysock.SendString(parsed.AsJSON + CRLF);
end;

procedure TfmMain.ProcessRequest(Request: String);
var
  p: TJSONParser;
  ValidJSON: Boolean;
  parsed: TJSONObject;
  params: TJSONObject;
begin

  ValidJSON := False;
  // do the parse , do nothing and exit if exception
  try
    p := TJSONParser.Create(Request);
    try
      parsed := TJSONObject(p.Parse);
      ValidJSON := True;

      // handle 'noop' method
      if (parsed.Strings['op'] = 'noop') then
      begin
        // no op, do nothing
        mylog('ProcessRequest: noop');
        exit;
      end;

      // for layer = session
      if (parsed.Strings['layer'] = 'ssn') then
      begin
        // supported session op: 'auth', 'config'
        // - config
        if (parsed.Strings['op'] = 'config') then
        begin
          params := parsed.Objects['params'];
          if (params.Integers['keepalive_interval'] > 0) then
            myReadThread.KeepaliveInterval := params.Integers['keepalive_interval'];
          if (params.Integers['protocol_major'] > AppProtocol) then
          begin
            // we are not compatible, terminate app
            MessageDlg('This version is obsoleted. Please upgrade.',
              mtInformation, [mbOK], 0);
            Close;
          end;
        end;

        // - auth fail
        if ((parsed.Strings['op'] = 'auth') and
          (not parsed.Booleans['result'])) then
        begin
          MessageDlg('Please contact us to get a valid MCU ID.',
            mtError, [mbOK], 0);
        end;
        exit;
      end;

      // for layer = application
      if (parsed.Strings['layer'] = 'app') then
      begin

        // validate controller id
        if (fMCUID <> parsed.Strings['mcu_id']) then
          raise EMyException.Create('MCU ID mismatch:' +
            parsed.Strings['mcu_id']);

        // validate key , raise exception if invalid
        // raise EMyException.Create('Access Denied: Invalid Key');
        if (parsed.Strings['key'] = SuperKey) then
        begin
          HasSuperKey := True;
        end
        else if (parsed.Strings['key'] = UserKey) then
        begin
          HasSuperKey := False;
        end
        else
          raise EMyException.Create('Access Denied: Invalid Key');

        // - 'read' method
        if (parsed.Strings['op'] = 'read') then
        begin
          DoReadReq(parsed);
          exit;
        end;

        // - 'set' method
        if (parsed.Strings['op'] = 'set') then
        begin
          DoSetReq(parsed);
          exit;
        end;

        // - 'verify_key' method
        if (parsed.Strings['op'] = 'verify_key') then
        begin
          DoVerifyKeyReq(parsed);
          exit;
        end;

        // - 'set_key' method
        if (parsed.Strings['op'] = 'set_key') then
        begin
          DoSetKeyReq(parsed);
          exit;
        end;


        // handle other methods = invalid
        raise EMyException.Create('Invalid operation: ' + parsed.Strings['op']);

      end;

      // supported layers
      raise EMyException.Create('Invalid frame layer:' + parsed.Strings['layer']);

    except
      on E: Exception do
      begin
        mylog('ProcessRequest: Error: ' + E.Message);
        if ValidJSON then
        begin
          parsed.Add('result', False);
          parsed.Add('message', E.Message);
          // send it
          mylog('Send:' + parsed.AsJSON);
          mysock.SendString(parsed.AsJSON + CRLF);
        end;
      end;
    end;
  finally
    FreeAndNil(p);
  end;

end;

initialization

{$I images.lrs}
{ # The images.lrs file created by:
E:\mydoc\LazarusProjects\SmartHomeEmu>e:\tools\lazres.exe images.lrs @imglist.txt

# imglist.txt contains:
img\room.png
img\room-dark.png
img\alarm-armed.png
img\alarm-disamrmed.png

}

finalization

end.