unit FinCalMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ComCtrls, Vcl.StdCtrls, Math,
  VCLTee.TeEngine, VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart, ShellAPI, Vcl.Imaging.pngimage, System.Win.Registry;

type
  TForm20 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    amountDeposit_Edit: TEdit;
    Label1: TLabel;
    percentEdit_Deposit: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    evryday_choose_point: TRadioButton;
    everymonth_choose_point: TRadioButton;
    everyyer_choose_point: TRadioButton;
    Label4: TLabel;
    Label5: TLabel;
    Memo_Deposit: TMemo;
    ButtonDeposit: TButton;
    Label6: TLabel;
    Edit_Time: TEdit;
    Chart1: TChart;
    Series1: TLineSeries;
    Image_Deposit: TImage;
    ButtonCredit: TButton;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    EditAmountCredit: TEdit;
    percentEdit_Credit: TEdit;
    evryday_choose_point_Credit: TRadioButton;
    everymonth_choose_point_Credit: TRadioButton;
    everyyer_choose_point_Credit: TRadioButton;
    Edit_Time_Credit: TEdit;
    Memo_Credit: TMemo;
    Image_Credit: TImage;
    Coupon_Bonds_Edit: TEdit;
    N_Price_Edit: TEdit;
    R_Price_Edit: TEdit;
    Label11: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Image_Bonds: TImage;
    Label15: TLabel;
    RadioButton_Year: TRadioButton;
    RadioButton_Month: TRadioButton;
    RadioButton_Quarter: TRadioButton;
    RadioButton_HY: TRadioButton;
    Memo_Bonds: TMemo;
    Button_Bonds: TButton;
    Button_NPV: TButton;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Edit_FI_NPV: TEdit;
    Edit_AOP_NPV: TEdit;
    Edit_IFP_NPV: TEdit;
    Edit_LOI_NPV: TEdit;
    Image_NPV: TImage;
    Memo_NPV: TMemo;
    MainMenu: TMainMenu;
    File1: TMenuItem;
    File2: TMenuItem;
    SaveDialog1: TSaveDialog;
    Label20: TLabel;
    YBP_bonds_Edit: TEdit;
    procedure ButtonDepositClick(Sender: TObject);
    procedure ButtonCreditClick(Sender: TObject);
    procedure Button_BondsClick(Sender: TObject);
    procedure Button_NPVClick(Sender: TObject);
    procedure File2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form20: TForm20;

implementation

{$R *.dfm}

// Folder of the project (the one that contains Deposit_R\plot.R), with '\' at the end.
// The program is started from Win32\Debug (or similar), so we go up folder by folder.
function ProjectDir: string;
var
  Dir, Parent: string;
  i: Integer;
begin
  Dir := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  for i := 1 to 5 do
  begin
    if FileExists(Dir + '\Deposit_R\plot.R') then
      Exit(IncludeTrailingPathDelimiter(Dir));
    Parent := ExtractFileDir(Dir);
    if (Parent = '') or (Parent = Dir) then
      Break;
    Dir := Parent;
  end;
  // not found: use the folder of the .exe
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

// file for data (Delphi writes it, R reads it)
function CsvPath: string;
begin
  Result := ProjectDir + 'CSV_files\data.csv';
end;

// picture (R writes it, Delphi shows it)
function ChartPath: string;
begin
  Result := ProjectDir + 'Deposit_R\chart.png';
end;

// Arguments for Rscript: script, input csv, output png.
// Quotes are needed because a path can contain spaces.
function PlotArguments: string;
begin
  Result := AnsiQuotedStr(ProjectDir + 'Deposit_R\plot.R', '"') + ' ' +
            AnsiQuotedStr(CsvPath, '"') + ' ' +
            AnsiQuotedStr(ChartPath, '"');
end;

// Folder where R is installed, read from the Windows registry ('' if not found)
function ReadRInstallPath(RootKey: HKEY): string;
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY);
  try
    Reg.RootKey := RootKey;
    if Reg.OpenKeyReadOnly('SOFTWARE\R-core\R') then
      if Reg.ValueExists('InstallPath') then
        Result := Reg.ReadString('InstallPath');
  finally
    Reg.Free;
  end;
end;

// Full path to Rscript.exe. If R is not found in the registry,
// we hope that Rscript.exe is in PATH.
function FindRscript: string;
var
  InstallPath: string;
begin
  InstallPath := ReadRInstallPath(HKEY_LOCAL_MACHINE);
  if InstallPath = '' then
    InstallPath := ReadRInstallPath(HKEY_CURRENT_USER);
  if InstallPath <> '' then
  begin
    Result := IncludeTrailingPathDelimiter(InstallPath) + 'bin\Rscript.exe';
    if FileExists(Result) then
      Exit;
  end;
  Result := 'Rscript.exe';
end;

function RunAndWait(const ExePath, Params: string): Boolean;
var
  SEI: TShellExecuteInfo;
begin
  FillChar(SEI, SizeOf(SEI), 0);
  SEI.cbSize := SizeOf(SEI);
  SEI.fMask := SEE_MASK_NOCLOSEPROCESS;
  SEI.lpVerb := 'open';
  SEI.lpFile := PChar(ExePath);    // action file
  SEI.lpParameters := PChar(Params); // arguements for this file
  SEI.nShow := SW_HIDE;
  Result := ShellExecuteEx(@SEI);
  if Result then
  begin
    WaitForSingleObject(SEI.hProcess, 30000);
    CloseHandle(SEI.hProcess);
  end;
end;

procedure TForm20.Button_NPVClick(Sender: TObject);
var NPV, i_0, CF_year, CFn, Inflation, income_com: Real;
n, i_1: Integer;
csv_list_outputs: TStringList; //for csv list
line_csv: String; //lines for csv
begin
  Series1.Clear; //clear delphi graphics
  Memo_NPV.Lines.Clear;

  csv_list_outputs := TStringList.Create; //create csv

  i_0 := StrToFloat(Edit_FI_NPV.Text);
  n := StrToInt(Edit_AOP_NPV.Text);
  CF_year := StrToFloat(Edit_IFP_NPV.Text);
  Inflation := StrToFloat(Edit_LOI_NPV.Text);

  try

  csv_list_outputs.Add('period;balance'); // head for csv

    for I_1 := 1 to n do
      begin

      income_com := I_1 * (CF_year / Power(1 + Inflation / 100, n));
      NPV := -1 * i_0 + income_com;

      Series1.AddXY(I_1, NPV); //delphi graphics

      // for csv
      //create csv
      line_csv := FloatToStr(NPV);
      line_csv := StringReplace(line_csv, ',', '.', []); //change , for . in money
      csv_list_outputs.Add(IntToStr(I_1) + ';' + line_csv); // add line
      end;
    csv_list_outputs.SaveToFile(CsvPath, TEncoding.UTF8);
  finally
    csv_list_outputs.Free; // clean csv
  end;

  Memo_NPV.Lines.Add(FloatToStr(Round(NPV)) + 'EUR');

  //open R
  if RunAndWait(FindRscript, PlotArguments) then
    Image_NPV.Picture.LoadFromFile(ChartPath)
  else
    ShowMessage('Checking R');
end;



procedure TForm20.File2Click(Sender: TObject);
var b: Boolean;
begin
  b := SaveDialog1.Execute;
  if b = True then
    begin
    ShowMessage('save successful');
      if Length(Memo_Deposit.Text) > 0 then
        Memo_Deposit.Lines.SaveToFile(SaveDialog1.Filename + '.txt');
      if Length(Memo_Credit.Text) > 0 then
        Memo_Credit.Lines.SaveToFIle(SaveDialog1.Filename + '.txt');
      if Length(Memo_Bonds.Text) > 0 then
        Memo_Bonds.Lines.SaveToFile(SaveDialog1.Filename + '.txt');
      if Length(Memo_NPV.Text) > 0 then
        Memo_NPV.Lines.SaveToFile(SaveDialog1.Filename + '.txt');
    end
  else
    ShowMessage('unsuccessful :(');
end;

procedure TForm20.ButtonCreditClick(Sender: TObject);
var n, time: Integer;
ED, EM, EY: Boolean;
percent_for_period, amount_money, percent, percent_all, output, amount_m_grph, i1, i2: Real;
csv_list_outputs: TStringList; //for csv list
line_csv: String; //lines for csv
begin
  Series1.Clear; //clear delphi graphics
  Memo_Credit.Lines.Clear;

  csv_list_outputs := TStringList.Create; //create csv

  try
    csv_list_outputs.Add('period;balance'); // head for csv

    amount_money := StrToFloat(EditAmountCredit.Text);
    percent := StrToFloat(percentEdit_Credit.Text);
    time := StrToInt(Edit_Time_Credit.Text);

    ED := evryday_choose_point_Credit.Checked;
    EM := everymonth_choose_point_Credit.Checked;
    EY := everyyer_choose_point_Credit.Checked;

    if ED then // percent for one day
      begin
      percent_for_period := Power(1 + percent / 100, 1 / 365) - 1;
      end;
    if EM then // percent for one month
      begin
      percent_for_period := Power(1 + percent / 100, 1 / 12) - 1;
      end;
    if EY then // percent for one year
      begin
      percent_for_period := Power(1 + percent / 100, 1) - 1;
      end;

    // percent all time
    percent_all := Power(1 + percent_for_period, time);

    //output
    i1 := percent_for_period * percent_all;
    i2 := percent_all - 1;
    output := amount_money * i1 / i2;
    Memo_Credit.Lines.Add((FloatToStr(Round(output))) + ' Eur every period');

    //draw graphics
    for n := 1 to time do
      begin
      percent_all := Power(1 + percent_for_period, n);
      amount_m_grph := (amount_money * percent_all)
                     - output * (percent_all - 1) / percent_for_period;
      Series1.AddXY(n, amount_m_grph); //delphi graphics

      // for csv
      //create csv
      line_csv := FloatToStr(amount_m_grph);
      line_csv := StringReplace(line_csv, ',', '.', []); //change , for . in money
      csv_list_outputs.Add(IntToStr(n) + ';' + line_csv); // add line
      end;

    csv_list_outputs.SaveToFile(CsvPath, TEncoding.UTF8);
  finally
    csv_list_outputs.Free; // clean csv
  end;

  //open R
  if RunAndWait(FindRscript, PlotArguments) then
    Image_Credit.Picture.LoadFromFile(ChartPath)
  else
    ShowMessage('Checking R');

end;



procedure TForm20.ButtonDepositClick(Sender: TObject);
var n, time: Integer;
ED, EM, EY: Boolean;
percent_for_period, amount_money, percent, percent_all, output, amount_m_grph: Real;
csv_list_outputs: TStringList; //for csv list
line_csv: String; //lines for csv

begin
  Series1.Clear; //clear delphi graphics
  Memo_Deposit.Lines.Clear;

  csv_list_outputs := TStringList.Create; //create csv

  try
    csv_list_outputs.Add('period;balance'); // head for csv

    amount_money := StrToFloat(amountDeposit_Edit.Text);
    percent := StrToFloat(percentEdit_Deposit.Text);
    time := StrToInt(Edit_Time.Text);

    ED := evryday_choose_point.Checked;
    EM := everymonth_choose_point.Checked;
    EY := everyyer_choose_point.Checked;

    if ED then // percent for one day
      begin
      percent_for_period := Power(1 + percent / 100, 1 / 365);
      end;
    if EM then // percent for one month
      begin
      percent_for_period := Power(1 + percent / 100, 1 / 12);
      end;
    if EY then // percent for one year
      begin
      percent_for_period := Power(1 + percent / 100, 1);
      end;
    // percent all time
    percent_all := Power(percent_for_period, time);

    //output
    output := amount_money * percent_all;
    Memo_Deposit.Lines.Add(FloatToStr(Round(output)) + ' EUR');

    //draw graphics
    for n := 1 to time do
      begin
      amount_m_grph := amount_money * Power(percent_for_period, n);
      Series1.AddXY(n, amount_m_grph); //delphi graphics

      // for csv
      //create line
      line_csv := FloatToStr(amount_m_grph);
      line_csv := StringReplace(line_csv, ',', '.', []); //change , for . in money
      csv_list_outputs.Add(IntToStr(n) + ';' + line_csv); // add line
      end;

    csv_list_outputs.SaveToFile(CsvPath, TEncoding.UTF8);
  finally
    csv_list_outputs.Free; // clean csv
  end;


  //open R
  if RunAndWait(FindRscript, PlotArguments) then
    Image_Deposit.Picture.LoadFromFile(ChartPath)
  else
    ShowMessage('Checking R');
end;


procedure TForm20.Button_BondsClick(Sender: TObject);
var c, n_p, r_p, ytm, YBP, amount_graph_money: Real;
i: Integer;
Y_Bonds, M_Bonds, Q_Bonds, HY_Bonds: Boolean;
csv_list_outputs: TStringList; //for csv list
line_csv: String; //lines for csv
begin
  Series1.Clear; //clear delphi graphics
  Memo_Bonds.Lines.Clear;

  csv_list_outputs := TStringList.Create; //create csv

  try
    csv_list_outputs.Add('period;balance'); // head for csv

    c := StrToFloat(Coupon_Bonds_Edit.Text);
    n_p := StrToFloat(N_Price_Edit.Text);
    r_p := StrToFloat(R_Price_Edit.Text);
    YBP := StrToFloat(YBP_bonds_Edit.Text);

    Y_Bonds := RadioButton_Year.Checked;
    M_Bonds := RadioButton_Month.Checked;
    Q_Bonds := RadioButton_Quarter.Checked;
    HY_Bonds := RadioButton_HY.Checked;

    if Y_Bonds then // find cupon income for year
    Begin
      c := c * 1;
    End;

    if M_Bonds then
    Begin
      c := c * 12;
    End;

    if Q_Bonds then
    Begin
      c := c * 4;
    End;

    if HY_Bonds then
    Begin
      c := c * 2;
    End;

    //output
    ytm := ((c + ((n_p - r_p) / YBP)) / ((n_p + r_p) / 2)) * 100;
    Memo_Bonds.Lines.Add(FloatToStr(Round(ytm)) + '%');

    for I := 1 to Round(YBP) do
      begin
       amount_graph_money := ((n_p + r_p) / 2) * Power(1 + (ytm / 100), i);

       Series1.AddXY(i, amount_graph_money); //delphi graphics

       // for csv
       //create line
       line_csv := FloatToStr(amount_graph_money);
       line_csv := StringReplace(line_csv, ',', '.', []); //change , for . in money
       csv_list_outputs.Add(IntToStr(i) + ';' + line_csv); // add line
      end;

    csv_list_outputs.SaveToFile(CsvPath, TEncoding.UTF8); // save once, after the loop
  finally
    csv_list_outputs.Free; // clean csv
  end;

  //open R
  if RunAndWait(FindRscript, PlotArguments) then
    Image_Bonds.Picture.LoadFromFile(ChartPath)
  else
    ShowMessage('Checking R');
end;

end.
