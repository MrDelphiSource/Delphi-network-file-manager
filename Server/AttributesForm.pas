unit AttributesForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TForm3 = class(TForm)
    Panel1: TPanel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    Label1: TLabel;
    Button1: TButton;
    Button2: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure CheckBox3Click(Sender: TObject);
    procedure CheckBox4Click(Sender: TObject);
    procedure CheckBox5Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }

   FAttrib, FFileName : string;
  end;

var
  Form3: TForm3;

implementation
 uses Unit1;

{$R *.dfm}


procedure TForm3.FormShow(Sender: TObject);
begin
 Label1.Caption := ('File: "' + ExtractFileName(FFileName) + '"');

 if
  Pos('R',FAttrib) <> 0
 then
  CheckBox1.Checked := True;
 if
  Pos('H',FAttrib) <> 0
 then
  CheckBox2.Checked := True;
 if
  Pos('S',FAttrib) <> 0
 then
  CheckBox3.Checked := True;
 if
  Pos('A',FAttrib) <> 0
 then
  CheckBox4.Checked := True;
 if
  (FAttrib = EmptyStr) or (FAttrib = 'Normal')
 then
  CheckBox5.Checked := True;
end;

procedure TForm3.CheckBox1Click(Sender: TObject);
begin
 if
  CheckBox1.Checked
 then
  CheckBox5.Checked := False;
end;


procedure TForm3.CheckBox2Click(Sender: TObject);
begin
 if
  CheckBox2.Checked
 then
  CheckBox5.Checked := False;
end;

procedure TForm3.CheckBox3Click(Sender: TObject);
begin
 if
  CheckBox3.Checked
 then
  CheckBox5.Checked := False;
end;

procedure TForm3.CheckBox4Click(Sender: TObject);
begin
 if
  CheckBox4.Checked
 then
  CheckBox5.Checked := False;
end;

procedure TForm3.CheckBox5Click(Sender: TObject);
begin
 if
  CheckBox5.Checked
 then
  begin
   CheckBox1.Checked := False;
   CheckBox2.Checked := False;
   CheckBox3.Checked := False;
   CheckBox4.Checked := False;
  end;
end;

procedure TForm3.Button1Click(Sender: TObject);
 var
  SAttrib : string;
begin
 if
  CheckBox1.Checked = True
 then
  SAttrib := ('R');
 if
  CheckBox2.Checked = True
 then
  SAttrib := SAttrib + ('H');
 if
  CheckBox3.Checked = True
 then
  SAttrib := SAttrib + ('S');
 if
  CheckBox4.Checked = True
 then
  SAttrib := SAttrib + ('A');
 if
  CheckBox5.Checked = True
 then
  SAttrib := ('N');

 Form1.ServerSocket.ExecCommand(Form1.CurrentClient, 0, BytesOf('CHMOD_FILE|' + FFileName + '|' + SAttrib), False);
 Form3.Close;
 Exit;
end;

procedure TForm3.Button2Click(Sender: TObject);
begin
 Close;
end;


procedure TForm3.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action := caFree;
 Form3 := nil;
end;



end.
