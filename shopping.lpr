program shopping;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazcontrols, uMain, uTranzaction, uBuy
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.CreateForm(TfTranzactie, fTranzactie);
  Application.CreateForm(TfCumparatura, fCumparatura);
  Application.Run;
end.

