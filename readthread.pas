unit readthread;

{$mode objfpc}

interface

uses
  Classes, SysUtils, StrUtils, blcksock, synsock;

type
  TDoLogEvent = procedure(Status: ansiString) of object;
  TProcessRequest = procedure(Request: ansiString) of object;

  TReadThread = class(TThread)
  private
    fStatusText: string;
    fRequest: string;
    FOnDoLog: TDoLogEvent;
    FOnRequest: TProcessRequest;
    sock: TTCPBlockSocket;
    FKeepaliveInterval: integer;
    FLogKeepalive: boolean;
    procedure DoLog;
    procedure ProcessRequest;
    procedure MyLog(AString: string);
  public
    constructor Create(ASock: TTCPBlockSocket);
    destructor Destroy; override;
    procedure Execute; override;
    property OnDoLog: TDoLogEvent read FOnDoLog write FOnDoLog;
    property OnRequest: TProcessRequest read FOnRequest write FOnRequest;
    property LogKeepalive: boolean read FLogKeepalive write FLogKeepalive;
    property KeepaliveInterval: integer read FKeepaliveInterval write FKeepaliveInterval;
  end;


implementation

uses main;

constructor Treadthread.Create(ASock: TTCPBlockSocket);
begin
  sock := ASock;
  FreeONTerminate := True;

  // set property defaults:
  LogKeepalive := True;
  KeepaliveInterval := 120; // to be set by owner

  Mylog('Read thread created');
  inherited Create(False);
end;

destructor Treadthread.Destroy;
begin
  //fStatusText := 'Read thread terminated';
  //Synchronize(@DoLog);
  Mylog('Read thread terminated');
  inherited Destroy;
end;

procedure Treadthread.DoLog;
begin
  if Assigned(FOnDoLog) then
  begin
    FOnDoLog(fStatusText);
  end;
end;

procedure Treadthread.ProcessRequest;
begin
  if Assigned(FOnRequest) then
  begin
    FOnRequest(fRequest);
  end;
end;



procedure Treadthread.MyLog(AString: string);
begin
  fStatusText := Astring;
  Synchronize(@DoLog);
end;

procedure Treadthread.Execute;
var
  S: string;
  KeepaliveTimeout: integer;
begin
  KeepaliveTimeout := 0;
  repeat
    if Terminated then
      break;

    S := sock.RecvString(1000);
    if (sock.Lasterror = 0) then
    begin
      KeepaliveTimeout := 0;
      // send ack if keepalive
      if AnsiStartsText(KeepAlivePing, S) then
      begin
        if LogKeepalive then
        begin
          MyLog('Recv:' + S);
          MyLog('Send:' + KeepAlivePong);
        end;
        sock.SendString(KeepAlivePong + CRLF);
        continue;
      end;
      // process the recv'd string (JSON)
      MyLog('Recv:' + S);
      fRequest := S;
      Synchronize(@ProcessRequest);
      continue;
    end
    else
    begin

      if sock.LastError = WSAETIMEDOUT then
        // no data, next loop
      begin
        KeepaliveTimeout := KeepaliveTimeout + 1;
        if (KeepaliveTimeout > KeepaliveInterval) then
        begin
            MyLog('Keepalive timeout, force disconnect');
            break;
        end else
            continue;
      end
      else
      begin
        // connection broken
        break;
      end;
    end;
  until (false);
  sock.CloseSocket;
end;

end.
