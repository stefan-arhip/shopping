unit uBuy;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel,
  StdCtrls, Spin;

type

  { TfCumparatura }

  TfCumparatura = class(TForm)
    ButtonPanel1: TButtonPanel;
    cbCategory: TComboBox;
    cbItem: TComboBox;
    cbMeasurement: TComboBox;
    fseAmount: TFloatSpinEdit;
    fsePrice: TFloatSpinEdit;
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
  fCumparatura: TfCumparatura;

implementation

{$R *.lfm}

end.
