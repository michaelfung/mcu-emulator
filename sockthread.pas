unit sockthread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, blcksock, synsock;

type
  TDoLogEvent = procedure(Status: Ansistring) of object;
  TConnectedEvent = procedure of object;

  TSockThread = class(TThread)
  private
    fStatusText: String;
    FOnDoLog: TDoLogEvent;
    FOnConnected: TConnectedEvent;
    mysock: TTCPBlockSocket;
    UseSSL: Boolean;
    procedure DoLog;
    procedure DoConnected;
    procedure MyLog(AString: String);
  public
    constructor Create(ASock: TTCPBlockSocket; EnableSSL: Boolean);
    destructor Destroy; override;
    procedure Execute; override;
    property OnDoLog: TDoLogEvent read FOnDoLog write FOnDoLog;
    property OnConnected: TConnectedEvent read FOnConnected write FOnConnected;
  end;

  EMyException = class(Exception)

  end;

implementation

uses main;

constructor Tsockthread.Create(ASock: TTCPBlockSocket; EnableSSL: Boolean);
begin
  mysock := ASock;
  UseSSL := EnableSSL;
  FreeONTerminate := False;

  // set property defaults:
  inherited Create(True);  // CreateSuspended: Boolean

  Mylog('Sock thread created');
end;

destructor Tsockthread.Destroy;
begin
  Mylog('Sock thread terminated');
  inherited Destroy;
end;

procedure Tsockthread.MyLog(AString: String);
begin
  fStatusText := Astring;
  Synchronize(@DoLog);
end;

procedure Tsockthread.DoLog;
begin
  if Assigned(FOnDoLog) then
  begin
    FOnDoLog(fStatusText);
  end;
end;

procedure Tsockthread.DoConnected;
begin
  if Assigned(FOnConnected) then
  begin
    FOnConnected;
  end;
end;

procedure Tsockthread.Execute;
begin
  try
    mysock.Connect(ServerName, ServerPort);
    if UseSSL then
      mysock.SSLDoConnect;
    if mysock.LastError <> 0 then
    begin
      mylog('Connection failed');
      raise EMyException.Create('Connection failed');
    end;

    if UseSSL then
    begin
      mylog('SSL Peer Cert Subject:' + mysock.SSL.GetPeerSubject);
      if (mysock.SSL.GetVerifyCert = 0) then
      begin
        mylog('SSL Peer Verify OK.');
      end
      else
      begin
        mysock.SSLDoShutdown;
        mysock.SSL.Free;
        raise EMyException.Create('SSL Cert verify failed');
      end;
    end;

    // fire up connected event
    Synchronize(@DoConnected);
  except
    on E: Exception do
    begin
      mylog('Connection failed with Exception:' + E.Message);
    end;
  end;

end;


end.

