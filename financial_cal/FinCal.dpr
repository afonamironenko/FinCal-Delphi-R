program FinCal;

uses
  Vcl.Forms,
  FinCalMain in 'FinCalMain.pas' {Form20};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm20, Form20);
  Application.Run;
end.
