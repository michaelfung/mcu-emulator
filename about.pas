unit about;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls;

type

  { TfmAbout }

  TfmAbout = class(TForm)
    btnOk: TButton;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lblVersion: TLabel;
    lblProtocol: TLabel;
    Panel1: TPanel;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fmAbout: TfmAbout;

implementation

{$R *.lfm}

{ TfmAbout }

end.

