unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqlite3conn, sqldb, FileUtil, ListFilterEdit, Forms,
  Controls, Graphics, Dialogs, ComCtrls, PairSplitter, Menus, StdCtrls, EditBtn,
  Spin, ExtCtrls, DateUtils, uTranzaction, uBuy, LCLVersion;

type

  { TfMain }

  TfMain = class(TForm)
    il: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lbAccounts: TListBox;
    lfeAccounts: TListFilterEdit;
    lvTransactions: TListView;
    ListView2: TListView;
    lvHistory: TListView;
    MenuItem1: TMenuItem;
    miOnlyWithOutput: TMenuItem;
    miAddAccount: TMenuItem;
    miEditAccount: TMenuItem;
    miRemoveAccount: TMenuItem;
    miAddItem: TMenuItem;
    miEditItem: TMenuItem;
    miRemoveItem: TMenuItem;
    miRemoveTransaction: TMenuItem;
    miEditTransaction: TMenuItem;
    miAddTransaction: TMenuItem;
    PageControl1: TPageControl;
    PairSplitter1: TPairSplitter;
    PairSplitter2: TPairSplitter;
    PairSplitterSide1: TPairSplitterSide;
    PairSplitterSide2: TPairSplitterSide;
    PairSplitterSide3: TPairSplitterSide;
    PairSplitterSide4: TPairSplitterSide;
    Panel1: TPanel;
    pmTransactions: TPopupMenu;
    pmItems: TPopupMenu;
    pmAccounts: TPopupMenu;
    seYear: TSpinEdit;
    sc: TSQLite3Connection;
    sq: TSQLQuery;
    stAbout: TStaticText;
    tr: TSQLTransaction;
    StatusBar1: TStatusBar;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure lbAccountsSelectionChange(Sender: TObject; User: boolean);
    procedure lvTransactionsSelectItem(Sender: TObject; Item: TListItem;
      Selected: boolean);
    procedure miAddAccountClick(Sender: TObject);
    procedure miAddItemClick(Sender: TObject);
    procedure miAddTransactionClick(Sender: TObject);
    procedure miEditAccountClick(Sender: TObject);
    procedure miEditItemClick(Sender: TObject);
    procedure miEditTransactionClick(Sender: TObject);
    procedure miOnlyWithOutputClick(Sender: TObject);
    procedure miRemoveAccountClick(Sender: TObject);
    procedure miRemoveItemClick(Sender: TObject);
    procedure miRemoveTransactionClick(Sender: TObject);
    procedure pmAccountsPopup(Sender: TObject);
    procedure pmTransactionsPopup(Sender: TObject);
    procedure pmItemsPopup(Sender: TObject);
    procedure seYearChange(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure SqlAccounts(cb1, cb2: TComboBox);
    procedure SqlItemsCategoriesAndMeasurements(cb1, cb2, cb3: TComboBox);
  end;

var
  fMain: TfMain;

  AppDir: string;

implementation

{$R *.lfm}

{ TfMain }

type
  TContainer = class
  private
    _Id: integer;
  public
    property Id: integer read _Id;
    constructor Create(const Id_: integer);
  end;

constructor TContainer.Create(const Id_: integer);
begin
  _Id := Id_;
end;

procedure TfMain.SqlAccounts(cb1, cb2: TComboBox);
begin
  sc.Connected := True;

  sq.Close;
  sq.SQL.Clear;
  sq.SQL.Add('Select Id,Name From Accounts');
  sq.SQL.Add('Order By Name;');
  sq.Open;

  cb1.Items.Clear;
  cb2.Items.Clear;

  while not sq.EOF do
  begin
    cb1.Items.AddObject(sq.FieldByName('Name').AsString,
      TObject(sq.FieldByName('Id')));
    cb2.Items.AddObject(sq.FieldByName('Name').AsString,
      TObject(sq.FieldByName('Id')));
    sq.Next;
  end;

  sc.Connected := False;
end;

procedure TfMain.SqlItemsCategoriesAndMeasurements(cb1, cb2, cb3: TComboBox);
var
  cb: TComboBox;
begin
  sc.Connected := True;

  sq.Close;
  sq.SQL.Clear;
  sq.SQL.Add('Select Id,Name,0 As Type From Items Union All');
  sq.SQL.Add('Select Id,Name,1 From Categories Union All');
  sq.SQL.Add('Select Id,Name,2 From Measurements');
  sq.SQL.Add('Order By Name;');
  sq.Open;

  cb1.Items.Clear;
  cb2.Items.Clear;
  cb3.Items.Clear;

  while not sq.EOF do
  begin
    case sq.FieldByName('Type').AsInteger of
      0:
        cb := cb1;
      1:
        cb := cb2;
      2:
        cb := cb3;
    end;
    cb.Items.AddObject(sq.FieldByName('Name').AsString,
      TObject(sq.FieldByName('Id')));
    sq.Next;
  end;

  sc.Connected := False;
end;

procedure TfMain.FormCreate(Sender: TObject);
var
  b: boolean;
  stUser: string;
  dtExeDate: TDateTime;
begin
  {$IfDef Windows}
  stUser := GetEnvironmentVariable('USERNAME');
  {$IfDef Win32}
  SQLiteLibraryName:=AppDir + 'x32-sqlite3.dll';
  {$Else IfDef Win64}
  SQLiteLibraryName:=AppDir + 'x64-sqlite3.dll';
  {$Endif}
  {$Else}
  stUser := GetEnvironmentVariable('USER');
  {$EndIf}
  dtExeDate := FileDateToDateTime(FileAge(Application.ExeName));
  stAbout.Caption := Format('User:'#9'%s', [stUser]) + #13 + 'Version:'#9 +
    FormatDateTime('yyyymmdd-hhnn', dtExeDate) + #13 +
    Format('Lazarus:'#9'%s', [lcl_version]) + #13 +
    Format('FPC:'#9'%s', [{$I %FPCVersion%}]) + #13 +
    Format('Target:'#9'%s', [{$I %FPCTarget%}]);

  PageControl1.TabIndex := 0; // Accounts

  b := FileExists(AppDir + 'shopping.sqlite');
  sc.DatabaseName := AppDir + 'shopping.sqlite';

  if not b then
  begin
    sc.ExecuteDirect('CREATE TABLE "Accounts" (' +
      '"Id" Integer PRIMARY KEY  NOT NULL ,"Name" Text DEFAULT (null) );');
    sc.ExecuteDirect('CREATE TABLE "Categories" ' +
      '("Id" INTEGER PRIMARY KEY  NOT NULL ,"Name" TEXT DEFAULT (null) );');
    sc.ExecuteDirect('CREATE TABLE "History" ' +
      '("Id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , ' +
      '"Date" DATETIME, "Change" TEXT);');
    sc.ExecuteDirect('CREATE TABLE "Items" ' +
      '("Id" INTEGER PRIMARY KEY  NOT NULL ,"Name" TEXT DEFAULT (null) ,' +
      '"IdCategory" INTEGER DEFAULT (null) );');
    sc.ExecuteDirect('CREATE TABLE "Measurements" ' +
      '("Id" Integer PRIMARY KEY  NOT NULL ,"Name" Text DEFAULT (null) );');
    sc.ExecuteDirect('CREATE TABLE "Shoppings" ' +
      '("Id" Integer PRIMARY KEY  NOT NULL ,' +
      '"IdTransaction" integer DEFAULT (null) ,"IdItem" INTEGER DEFAULT (null) ,' +
      '"IdCategory" INTEGER DEFAULT (null) ,"IdMeasurement" integer DEFAULT (null) ,' +
      '"Amount" REAL DEFAULT (null) ,"Price" REAL DEFAULT (null) ,' +
      '"Description" TEXT DEFAULT (null) );');
    sc.ExecuteDirect('CREATE TABLE "Stocks" ' +
      '("Id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , ' +
      '"Year" INTEGER, "IdAccount" INTEGER, "Amount" REAL);');
    sc.ExecuteDirect('CREATE TABLE "Transactions" ' +
      '("Id" Integer PRIMARY KEY  NOT NULL ,"Date" Date DEFAULT (null) ,' +
      '"IdSource" Integer DEFAULT (null) ,"Input" Real DEFAULT (null) ,' +
      '"Output" REAL DEFAULT (null) ,"IdDestination" Integer DEFAULT (null) ,' +
      '"Description" Text DEFAULT (null) );');

    tr.Active := True;
    tr.Commit;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('INSERT INTO History (Date,"Change") VALUES');
    sq.SQL.Add('(''2013-12-22 00:00:00'',''Start to develop application''),');
    sq.SQL.Add('(''2014-01-03 23:08:45'',''Insert icons theme into application''),');
    sq.SQL.Add('(''2014-01-07 07:40:25'',''Compile and test application under Windows 7''),');
    sq.SQL.Add('(''2014-01-07 21:51:39'',''Sorted list of transactions and items''),');
    sq.SQL.Add(
      '(''2014-01-07 22:46:55'',''Display only accounts with outputs in selected year''),');
    sq.SQL.Add('(''2014-01-07 23:40:24'',''Options for display only accounts with output''),');
    sq.SQL.Add('(''2014-01-07 23:09:12'',''Add, edit, remove account''),');
    sq.SQL.Add('(''2014-01-07 22:20:56'',''Development history included in database''),');
    sq.SQL.Add(
      '(''2019-04-11 15:00:00'',''Solved to insert correct description into new item''),');
    sq.SQL.Add(
      '(''2019-04-11 15:30:00'',''Display in About tab of current user, executable version and compiler version''),');
    sq.SQL.Add(
      '(''2024-01-20 20:59:26'',''Add feature to create database at startup if "shopping.sqlite" is missing'');');
    sq.ExecSQL;
    tr.Commit;
    sq.Close;
  end;

  sq.PacketRecords := -1;

  sc.Connected := True;

  sq.Close;
  sq.SQL.Clear;
  sq.SQL.Add('Select Id,Date,Change From History Order By Date;');
  sq.Open;

  lvHistory.Items.Clear;
  while not sq.EOF do
    with lvHistory.Items.Add do
    begin
      Caption := IntToStr(lvHistory.Items.Count);
      SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss',
        sq.FieldByName('Date').AsDateTime));
      SubItems.Add(sq.FieldByName('Change').AsString);
      sq.Next;
    end;
  lvHistory.ItemIndex := lvHistory.Items.Count - 1;

  sq.Close;
  sc.Connected := False;

  seYear.Value := YearOf(Today);
  seYearChange(Sender);
end;

procedure TfMain.lbAccountsSelectionChange(Sender: TObject; User: boolean);
var
  Node1: TListItem;
  s: string;
  i: integer;
begin
  if (lbAccounts.Items.Count = 0) or (lbAccounts.SelCount = 0) then
    Exit;

  sc.Connected := True;

  s := '';
  for i := 1 to lbAccounts.Items.Count do
    if lbAccounts.Selected[i - 1] then
      s := s + ',' + IntToStr(TContainer(lbAccounts.Items.Objects[i - 1]).Id);
  Delete(s, 1, 1);
  //ShowMessage(s);

  sq.Close;
  sq.SQL.Clear;
  sq.SQL.Add('Select Tr.Id,');
  sq.SQL.Add('Tr.Date,');
  sq.SQL.Add('A_S.Name As Source,');
  sq.SQL.Add('A_D.Name As Destination,');
  sq.SQL.Add('Tr.Input,');
  sq.SQL.Add('Tr.Output,');
  sq.SQL.Add('Tr.Description');
  sq.SQL.Add('From Transactions As Tr Left Outer Join');
  sq.SQL.Add('Accounts As A_S On A_S.Id=Tr.IdSource Left Outer Join');
  sq.SQL.Add('Accounts As A_D On A_D.Id=Tr.IdDestination');
  sq.SQL.Add('Where StrFTime(''%Y'',Tr.Date) =:Year And');
  sq.SQL.Add('A_S.Id In (' + s + ')');
  sq.SQL.Add('Order By Date Asc;');
  sq.ParamByName('Year').AsString := IntToStr(seYear.Value);
  //sq.ParamByName('IdAccount').AsInteger:= TContainer(lbAccounts.Items.Objects[lbAccounts.ItemIndex])._Id;
  //StatusBar1.Panels[0].Text:= IntToStr(TContainer(lbAccounts.Items.Objects[lbAccounts.ItemIndex]).Id);
  sq.Open;

  lvTransactions.Items.Clear;
  while not sq.EOF do
  begin
    Node1 := lvTransactions.Items.Add;
    Node1.Caption := IntToStr(lvTransactions.Items.Count);
    Node1.StateIndex := sq.FieldByName('Id').AsInteger;
    Node1.SubItems.Add(FormatDateTime('yyyy-mm-dd',
      sq.FieldByName('Date').AsDateTime));
    Node1.SubItems.Add(sq.FieldByName('Source').AsString);
    Node1.SubItems.Add(sq.FieldByName('Destination').AsString);
    Node1.SubItems.Add(Format('%.2f', [sq.FieldByName('Input').AsFloat]));
    Node1.SubItems.Add(Format('%.2f', [sq.FieldByName('Output').AsFloat]));
    Node1.SubItems.Add(sq.FieldByName('Description').AsString);
    sq.Next;
  end;

  sc.Connected := False;
end;

procedure TfMain.lvTransactionsSelectItem(Sender: TObject; Item: TListItem;
  Selected: boolean);
var
  IdTransaction: integer;
  Node2: TListItem;
begin
  if Assigned(lvTransactions.Selected) then
  begin
    IdTransaction := lvTransactions.Selected.StateIndex;

    sc.Connected := True;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Sh.Id,');
    sq.SQL.Add('It.Name As Item,');
    sq.SQL.Add('Ca.Name As Category,');
    sq.SQL.Add('Me.Name As Measurement,');
    sq.SQL.Add('Sh.Amount,');
    sq.SQL.Add('Sh.Price,');
    sq.SQL.Add('Sh.Amount*Sh.Price As Total,');
    sq.SQL.Add('Sh.Description');
    sq.SQL.Add('From Shoppings As Sh Left Outer Join');
    sq.SQL.Add('Items As It On It.Id=Sh.IdItem Left Outer Join');
    sq.SQL.Add('Measurements As Me On Me.Id=Sh.IdMeasurement Left Outer Join');
    sq.SQL.Add('Categories As Ca On Ca.Id=Sh.IdCategory');
    sq.SQL.Add('Where IdTransaction=:IdTransaction;');
    sq.ParamByName('IdTransaction').AsInteger := IdTransaction;
    sq.Open;
    ListView2.Items.Clear;

    while not sq.EOF do
    begin
      Node2 := ListView2.Items.Add;
      Node2.Caption := IntToStr(ListView2.Items.Count);
      Node2.StateIndex := sq.FieldByName('Id').AsInteger;
      Node2.SubItems.Add(sq.FieldByName('Item').AsString);
      Node2.SubItems.Add(sq.FieldByName('Category').AsString);
      Node2.SubItems.Add(sq.FieldByName('Measurement').AsString);
      Node2.SubItems.Add(Format('%.2f', [sq.FieldByName('Amount').AsFloat]));
      Node2.SubItems.Add(Format('%.2f', [sq.FieldByName('Price').AsFloat]));
      Node2.SubItems.Add(Format('%.2f', [sq.FieldByName('Total').AsFloat]));
      Node2.SubItems.Add(sq.FieldByName('Description').AsString);
      sq.Next;
    end;

    sc.Connected := False;
  end
  else
    ListView2.Items.Clear;
end;

procedure TfMain.miAddAccountClick(Sender: TObject);
var
  AccountName: string;
begin
  AccountName := '';
  if InputQuery('Add account', 'Add new account', False, AccountName) then
  begin
    sc.Connected := True;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Insert Into Accounts (Name)');
    sq.SQL.Add('Select :Account');
    sq.SQL.Add('Where Not Exists (Select 1 From Accounts Where Name=:Account);');
    sq.ParamByName('Account').AsString := AccountName;
    sq.ExecSQL;
    tr.Commit;

    sq.Close;
    sc.Connected := False;

    seYearChange(Sender);
  end;
end;

procedure TfMain.miAddItemClick(Sender: TObject);
var
  IdTransaction, IdItem, IdCategory, IdMeasurement: integer;
begin
  IdTransaction := lvTransactions.Selected.StateIndex;
  SqlItemsCategoriesAndMeasurements(fCumparatura.cbItem, fCumparatura.cbCategory,
    fCumparatura.cbMeasurement);

  fCumparatura.cbItem.Text := '';
  fCumparatura.cbCategory.Text := '';
  fCumparatura.cbMeasurement.Text := '';
  fCumparatura.fseAmount.Value := 0;
  fCumparatura.fsePrice.Value := 0;
  fCumparatura.meDescription.Clear;
  if fCumparatura.ShowModal = mrOk then
  begin
    sc.Connected := True;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Insert Into Items (Name)');
    sq.SQL.Add('Select :Item');
    sq.SQL.Add('Where Not Exists (Select 1 From Items Where Name=:Item);');
    sq.ParamByName('Item').AsString := fCumparatura.cbItem.Text;
    sq.ExecSQL;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Id From Items Where Name=:Item;');
    sq.ParamByName('Item').AsString := fCumparatura.cbItem.Text;
    sq.Open;
    IdItem := sq.FieldByName('Id').AsInteger;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Insert Into Categories (Name)');
    sq.SQL.Add('Select :Category');
    sq.SQL.Add('Where Not Exists (Select 1 From Categories Where Name=:Category);');
    sq.ParamByName('Category').AsString := fCumparatura.cbCategory.Text;
    sq.ExecSQL;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Id From Categories Where Name=:Category;');
    sq.ParamByName('Category').AsString := fCumparatura.cbCategory.Text;
    sq.Open;
    IdCategory := sq.FieldByName('Id').AsInteger;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Insert Into Measurements (Name)');
    sq.SQL.Add('Select :Measurement');
    sq.SQL.Add('Where Not Exists (Select 1 From Measurements Where Name=:Measurement);');
    sq.ParamByName('Measurement').AsString := fCumparatura.cbMeasurement.Text;
    sq.ExecSQL;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Id From Measurements Where Name=:Measurement;');
    sq.ParamByName('Measurement').AsString := fCumparatura.cbMeasurement.Text;
    sq.Open;
    IdMeasurement := sq.FieldByName('Id').AsInteger;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add(
      'Insert Into Shoppings (IdTransaction,IdItem,IdCategory,IdMeasurement,Amount,Price,Description)');
    sq.SQL.Add(
      'Values (:IdTransaction,:IdItem,:IdCategory,:IdMeasurement,:Amount,:Price,:Description);');
    sq.ParamByName('IdTransaction').AsInteger := IdTransaction;
    sq.ParamByName('IdItem').AsInteger := IdItem;
    sq.ParamByName('IdCategory').AsInteger := IdCategory;
    sq.ParamByName('IdMeasurement').AsInteger := IdMeasurement;
    sq.ParamByName('Amount').AsFloat := fCumparatura.fseAmount.Value;
    sq.ParamByName('Price').AsFloat := fCumparatura.fsePrice.Value;
    sq.ParamByName('Description').AsString := fCumparatura.meDescription.Text;
    sq.ExecSQL;
    tr.Commit;

    sc.Connected := False;

    lvTransactionsSelectItem(Sender, lvTransactions.Selected, True);
  end;
end;

procedure TfMain.miAddTransactionClick(Sender: TObject);
var
  IdSource, IdDestination: integer;
begin
  SqlAccounts(fTranzactie.cbSource, fTranzactie.cbDestination);

  fTranzactie.deDate.Date := Now();
  fTranzactie.cbSource.Text := '';
  fTranzactie.cbDestination.Text := '';
  fTranzactie.fseInput.Value := 0;
  fTranzactie.fseOutput.Value := 0;
  fTranzactie.meDescription.Clear;

  if fTranzactie.ShowModal = mrOk then
  begin
    sc.Connected := True;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Insert Into Accounts (Name)');
    sq.SQL.Add('Select :Account');
    sq.SQL.Add('Where Not Exists (Select 1 From Accounts Where Name=:Account);');
    sq.ParamByName('Account').AsString := fTranzactie.cbSource.Text;
    sq.ExecSQL;
    tr.Commit;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Id From Accounts Where Name=:Account;');
    sq.ParamByName('Account').AsString := fTranzactie.cbSource.Text;
    sq.Open;
    IdSource := sq.FieldByName('Id').AsInteger;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Insert Into Accounts (Name)');
    sq.SQL.Add('Select :Account');
    sq.SQL.Add('Where Not Exists (Select 1 From Accounts Where Name=:Account);');
    sq.ParamByName('Account').AsString := fTranzactie.cbDestination.Text;
    sq.ExecSQL;
    tr.Commit;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Id From Accounts Where Name=:Account;');
    sq.ParamByName('Account').AsString := fTranzactie.cbDestination.Text;
    sq.Open;
    IdDestination := sq.FieldByName('Id').AsInteger;

    sq.Close;
    sq.SQL.Clear;

    sq.SQL.Add(
      'Insert Into Transactions (Date,IdSource,Input,Output,IdDestination,Description)');
    sq.SQL.Add('Values (:Date,:IdSource,:Input,:Output,:IdDestination,:Description);');
    sq.ParamByName('Date').AsDate := fTranzactie.deDate.Date;
    sq.ParamByName('IdSource').AsInteger := IdSource;
    sq.ParamByName('Input').AsFloat := fTranzactie.fseInput.Value;
    sq.ParamByName('Output').AsFloat := fTranzactie.fseOutput.Value;
    sq.ParamByName('IdDestination').AsInteger := IdDestination;
    sq.ParamByName('Description').AsString := fTranzactie.meDescription.Text;

    sq.ExecSQL;
    tr.Commit;

    sc.Connected := False;

    //seYearChange(Sender);
    lbAccountsSelectionChange(Sender, True);
  end;
end;

procedure TfMain.miEditAccountClick(Sender: TObject);
var
  AccountName: string;
begin
  AccountName := lbAccounts.Items[lbAccounts.ItemIndex];
  if InputQuery('Edit account', 'Change account name?', False, AccountName) then
  begin
    sc.Connected := True;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Update Accounts Set Name=:Account');
    sq.SQL.Add('Where Id=:IdAccount;');
    sq.ParamByName('Account').AsString := AccountName;
    sq.ParamByName('IdAccount').AsInteger :=
      TContainer(lbAccounts.Items.Objects[lbAccounts.ItemIndex]).Id;
    sq.ExecSQL;
    tr.Commit;

    sq.Close;
    sc.Connected := False;

    seYearChange(Sender);
  end;
end;

procedure TfMain.miEditItemClick(Sender: TObject);
var
  IdTransaction, IdShopping, IdItem, IdCategory, IdMeasurement: integer;
begin
  IdTransaction := lvTransactions.Selected.StateIndex;
  IdShopping := ListView2.Selected.StateIndex;
  SqlItemsCategoriesAndMeasurements(fCumparatura.cbItem, fCumparatura.cbCategory,
    fCumparatura.cbMeasurement);

  sc.Connected := True;
  sq.Close;
  sq.SQL.Clear;
  sq.SQL.Add('Select Sh.Id,');
  sq.SQL.Add('It.Name As Item,');
  sq.SQL.Add('Ca.Name As Category,');
  sq.SQL.Add('Me.Name As Measurement,');
  sq.SQL.Add('Sh.Amount,');
  sq.SQL.Add('Sh.Price,');
  sq.SQL.Add('Sh.Description');
  sq.SQL.Add('From Shoppings As Sh Left Outer Join');
  sq.SQL.Add('Items As It On It.Id=Sh.IdItem Left Outer Join');
  sq.SQL.Add('Categories As Ca On Ca.Id=Sh.IdCategory Left Outer Join');
  sq.SQL.Add('Measurements As Me On Me.Id=Sh.IdMeasurement');
  sq.SQL.Add('Where Sh.Id=:IdShopping;');
  sq.ParamByName('IdShopping').AsInteger := IdShopping;
  sq.Open;

  fCumparatura.cbItem.Text := sq.FieldByName('Item').AsString;
  fCumparatura.cbCategory.Text := sq.FieldByName('Category').AsString;
  fCumparatura.cbMeasurement.Text := sq.FieldByName('Measurement').AsString;
  fCumparatura.fseAmount.Value := sq.FieldByName('Amount').AsFloat;
  fCumparatura.fsePrice.Value := sq.FieldByName('Price').AsFloat;
  fCumparatura.meDescription.Text := sq.FieldByName('Description').AsString;

  sc.Connected := False;

  if fCumparatura.ShowModal = mrOk then
  begin
    sc.Connected := True;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Insert Into Items (Name)');
    sq.SQL.Add('Select :Item');
    sq.SQL.Add('Where Not Exists (Select 1 From Items Where Name=:Item);');
    sq.ParamByName('Item').AsString := fCumparatura.cbItem.Text;
    sq.ExecSQL;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Id From Items Where Name=:Item;');
    sq.ParamByName('Item').AsString := fCumparatura.cbItem.Text;
    sq.Open;
    IdItem := sq.FieldByName('Id').AsInteger;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Insert Into Categories (Name)');
    sq.SQL.Add('Select :Category');
    sq.SQL.Add('Where Not Exists (Select 1 From Categories Where Name=:Category);');
    sq.ParamByName('Category').AsString := fCumparatura.cbCategory.Text;
    sq.ExecSQL;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Id From Categories Where Name=:Category;');
    sq.ParamByName('Category').AsString := fCumparatura.cbCategory.Text;
    sq.Open;
    IdCategory := sq.FieldByName('Id').AsInteger;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Insert Into Measurements (Name)');
    sq.SQL.Add('Select :Measurement');
    sq.SQL.Add('Where Not Exists (Select 1 From Measurements Where Name=:Measurement);');
    sq.ParamByName('Measurement').AsString := fCumparatura.cbMeasurement.Text;
    sq.ExecSQL;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Id From Measurements Where Name=:Measurement;');
    sq.ParamByName('Measurement').AsString := fCumparatura.cbMeasurement.Text;
    sq.Open;
    IdMeasurement := sq.FieldByName('Id').AsInteger;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Update Shoppings');
    sq.SQL.Add('Set IdTransaction=:IdTransaction,');
    sq.SQL.Add('IdItem=:IdItem,');
    sq.SQL.Add('IdCategory=:IdCategory,');
    sq.SQL.Add('IdMeasurement=:IdMeasurement,');
    sq.SQL.Add('Amount=:Amount,');
    sq.SQL.Add('Price=:Price,');
    sq.SQL.Add('Description=:Description');
    sq.SQL.Add('Where Id=:IdShopping;');
    sq.ParamByName('IdTransaction').AsInteger := IdTransaction;
    sq.ParamByName('IdItem').AsInteger := IdItem;
    sq.ParamByName('IdCategory').AsInteger := IdCategory;
    sq.ParamByName('IdMeasurement').AsInteger := IdMeasurement;
    sq.ParamByName('Amount').AsFloat := fCumparatura.fseAmount.Value;
    sq.ParamByName('Price').AsFloat := fCumparatura.fsePrice.Value;
    sq.ParamByName('Description').AsString := fCumparatura.meDescription.Text;
    sq.ParamByName('IdShopping').AsInteger := IdShopping;
    sq.ExecSQL;
    tr.Commit;

    sc.Connected := False;

    lvTransactionsSelectItem(Sender, lvTransactions.Selected, True);
  end;
end;

procedure TfMain.miEditTransactionClick(Sender: TObject);
var
  IdTransaction, IdSource, IdDestination: integer;
begin
  SqlAccounts(fTranzactie.cbSource, fTranzactie.cbDestination);
  IdTransaction := lvTransactions.Selected.StateIndex;

  sc.Connected := True;
  sq.Close;
  sq.SQL.Clear;
  sq.SQL.Add('Select Tr.Id,');
  sq.SQL.Add('Tr.Date,');
  sq.SQL.Add('A_S.Name As Source,');
  sq.SQL.Add('A_D.Name As Destination,');
  sq.SQL.Add('Tr.Input,');
  sq.SQL.Add('Tr.Output,');
  sq.SQL.Add('Tr.Description');
  sq.SQL.Add('From Transactions As Tr Left Outer Join');
  sq.SQL.Add('Accounts As A_S On A_S.Id=Tr.IdSource Left Outer Join');
  sq.SQL.Add('Accounts As A_D On A_D.Id=Tr.IdDestination');
  sq.SQL.Add('Where Tr.Id=:IdTransaction;');
  sq.ParamByName('IdTransaction').AsInteger := IdTransaction;
  sq.Open;
  IdTransaction := sq.FieldByName('Id').AsInteger;

  fTranzactie.deDate.Date := sq.FieldByName('Date').AsDateTime;
  fTranzactie.cbSource.Text := sq.FieldByName('Source').AsString;
  fTranzactie.cbDestination.Text := sq.FieldByName('Destination').AsString;
  fTranzactie.fseInput.Value := sq.FieldByName('Input').AsFloat;
  fTranzactie.fseOutput.Value := sq.FieldByName('Output').AsFloat;
  fTranzactie.meDescription.Text := sq.FieldByName('Description').AsString;

  sc.Connected := False;

  if fTranzactie.ShowModal = mrOk then
  begin
    sc.Connected := True;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Insert Into Accounts (Name)');
    sq.SQL.Add('Select :Account');
    sq.SQL.Add('Where Not Exists (Select 1 From Accounts Where Name=:Account);');
    sq.ParamByName('Account').AsString := fTranzactie.cbSource.Text;
    sq.ExecSQL;
    tr.Commit;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Id From Accounts Where Name=:Account;');
    sq.ParamByName('Account').AsString := fTranzactie.cbSource.Text;
    sq.Open;
    IdSource := sq.FieldByName('Id').AsInteger;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Insert Into Accounts (Name)');
    sq.SQL.Add('Select :Account');
    sq.SQL.Add('Where Not Exists (Select 1 From Accounts Where Name=:Account);');
    sq.ParamByName('Account').AsString := fTranzactie.cbDestination.Text;
    sq.ExecSQL;
    tr.Commit;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Id From Accounts Where Name=:Account;');
    sq.ParamByName('Account').AsString := fTranzactie.cbDestination.Text;
    sq.Open;
    IdDestination := sq.FieldByName('Id').AsInteger;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Update Transactions');
    sq.SQL.Add('Set Date=:Date,');
    sq.SQL.Add('IdSource=:IdSource,');
    sq.SQL.Add('Input=:Input,');
    sq.SQL.Add('Output=:Output,');
    sq.SQL.Add('IdDestination=:IdDestination,');
    sq.SQL.Add('Description=:Description');
    sq.SQL.Add('Where Id=:IdTransaction;');
    sq.ParamByName('IdTransaction').AsInteger := IdTransaction;
    sq.ParamByName('Date').AsDate := fTranzactie.deDate.Date;
    sq.ParamByName('IdSource').AsInteger := IdSource;
    sq.ParamByName('Input').AsFloat := fTranzactie.fseInput.Value;
    sq.ParamByName('Output').AsFloat := fTranzactie.fseOutput.Value;
    sq.ParamByName('IdDestination').AsInteger := IdDestination;
    sq.ParamByName('Description').AsString := fTranzactie.meDescription.Text;

    sq.ExecSQL;
    tr.Commit;

    sc.Connected := False;

    //seYearChange(Sender);
    lbAccountsSelectionChange(Sender, True);
  end;
end;

procedure TfMain.miOnlyWithOutputClick(Sender: TObject);
begin
  miOnlyWithOutput.Checked := not miOnlyWithOutput.Checked;
  seYearChange(Sender);
end;

procedure TfMain.miRemoveAccountClick(Sender: TObject);
var
  AccountName: string;
  AccountId: integer;
begin
  AccountName := lbAccounts.Items[lbAccounts.ItemIndex];
  AccountId := TContainer(lbAccounts.Items.Objects[lbAccounts.ItemIndex]).Id;
  if MessageDlg(Format('Remove account <%s>?', [AccountName]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    sc.Connected := True;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Select Count(*) As TCount From Transactions');
    sq.SQL.Add('Where IdSource=:IdAccount Or IdDestination=:IdAccount;');
    sq.ParamByName('IdAccount').AsInteger := AccountId;
    sq.Open;

    if sq.FieldByName('TCount').AsInteger = 0 then
    begin
      sq.Close;
      sq.SQL.Clear;
      sq.SQL.Add('Delete Accounts Where Id=:IdAccount);');
      sq.ParamByName('IdAccount').AsInteger := AccountId;
      sq.ExecSQL;
      tr.Commit;
    end
    else
      MessageDlg(Format('Account <%s> have %d transactions and could not be removed!',
        [AccountName, sq.FieldByName('TCount').AsInteger]),
        mtWarning, [mbOK], 0);
    sq.Close;
    sc.Connected := False;

    seYearChange(Sender);
  end;
end;

procedure TfMain.miRemoveItemClick(Sender: TObject);
var
  IdShopping: integer;
begin
  if MessageDlg('Se elimina cumparatura selectata?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
  begin
    IdShopping := ListView2.Selected.StateIndex;

    sc.Connected := True;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Delete From Shoppings Where Id=:IdShopping;');
    sq.ParamByName('IdShopping').AsInteger := IdShopping;
    sq.ExecSQL;
    tr.Commit;

    sc.Connected := False;

    lvTransactionsSelectItem(Sender, lvTransactions.Selected, True);
  end;
end;

procedure TfMain.miRemoveTransactionClick(Sender: TObject);
var
  IdTransaction: integer;
begin
  if MessageDlg('Se elimina tranzactia selectata?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
  begin
    IdTransaction := lvTransactions.Selected.StateIndex;

    sc.Connected := True;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Delete From Shoppings Where IdTransaction=:IdTransaction;');
    sq.ParamByName('IdTransaction').AsInteger := IdTransaction;
    sq.ExecSQL;

    sq.Close;
    sq.SQL.Clear;
    sq.SQL.Add('Delete From Transactions Where Id=:IdTransaction;');
    sq.ParamByName('IdTransaction').AsInteger := IdTransaction;
    sq.ExecSQL;
    tr.Commit;

    sc.Connected := False;

    //seYearChange(Sender);
    lbAccountsSelectionChange(Sender, True);
  end;
end;

procedure TfMain.pmAccountsPopup(Sender: TObject);
begin
  miEditAccount.Enabled := (lbAccounts.Items.Count > 0) and (lbAccounts.ItemIndex > -1);
  miRemoveAccount.Enabled := (lbAccounts.Items.Count > 0) and
    (lbAccounts.ItemIndex > -1);
end;

procedure TfMain.pmTransactionsPopup(Sender: TObject);
begin
  miEditTransaction.Enabled := Assigned(lvTransactions.Selected);
  miRemoveTransaction.Enabled := Assigned(lvTransactions.Selected);
end;

procedure TfMain.pmItemsPopup(Sender: TObject);
begin
  miAddItem.Enabled := Assigned(lvTransactions.Selected);
  miEditItem.Enabled := Assigned(ListView2.Selected);
  miRemoveItem.Enabled := Assigned(ListView2.Selected);
end;

procedure TfMain.seYearChange(Sender: TObject);
begin
  sc.Connected := True;

  sq.Close;
  sq.SQL.Clear;
  sq.SQL.Add('Select Distinct A.Id,A.Name');
  sq.SQL.Add('From Accounts As A Left Outer Join');
  sq.SQL.Add('Transactions As T On T.IdSource=A.Id');
  if miOnlyWithOutput.Checked then
  begin
    sq.SQL.Add('Where StrFTime(''%Y'',T.Date)=:Year');
    sq.ParamByName('Year').AsString := IntToStr(seYear.Value);
  end;
  sq.SQL.Add('Order By A.Name;');
  sq.Open;

  lfeAccounts.FilteredListbox := nil;
  lbAccounts.Items.Clear;
  while not sq.EOF do
  begin
    lbAccounts.Items.AddObject(sq.FieldByName('Name').AsString,
      TContainer.Create(sq.FieldByName('Id').AsInteger));
    sq.Next;
  end;
  lfeAccounts.FilteredListbox := lbAccounts;

  sq.Close;
  sc.Connected := False;

  if (lbAccounts.Items.Count > 0) and (lbAccounts.ItemIndex > -1) then
  begin
    lbAccounts.ItemIndex := 0;
    lbAccountsSelectionChange(Sender, True);
  end;
end;

initialization
  AppDir := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));
  ;

end.
