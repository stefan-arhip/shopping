unit uTranzaction;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel,
  EditBtn, StdCtrls, Spin;

type

  { TfTranzactie }

  TfTranzactie = class(TForm)
    ButtonPanel1: TButtonPanel;
    cbSource: TComboBox;
    cbDestination: TComboBox;
    deDate: TDateEdit;
    fseInput: TFloatSpinEdit;
    fseOutput: TFloatSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    meDescription: TMemo;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fTranzactie: TfTranzactie;

implementation

{$R *.lfm}

end.
