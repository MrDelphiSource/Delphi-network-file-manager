unit RenameFileForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button2Click(Sender: TObject);

  private
    { Private declarations }

  public
    { Public declarations }
   OldFileName : string;
  end;

var
  Form2: TForm2;

implementation
 uses Unit1;

{$R *.dfm}


procedure TForm2.FormCreate(Sender: TObject);
begin
 //
end;

procedure TForm2.FormShow(Sender: TObject);
begin
 Edit1.Text := OldFileName;
end;

procedure TForm2.Button1Click(Sender: TObject);
var
  NewName: string;
  FindCap: TListItem;
  i: Integer;
begin
  if
   Button1.Tag = 1    //// - create folder
  then
   begin
    if
      (Edit1.Text <> EmptyStr) and (Form1.CurrentClient <> nil)
    then
     begin
      NewName := Edit1.Text;
      for i := 1 to Length(NewName) do
      begin
        if (NewName[i] in ['.', '\', '|', '/', '*', '?', '<', '>', ',', '"', ':']) then
        begin
          Winapi.Windows.MessageBox(Handle, PChar('Name contains invalid characters! Specify a new name without characters - ''. , * ? < > / | \ " :'''), PChar(Form1.Caption + ' - error create new folder'), MB_ICONWARNING + MB_OK);
          NewName := EmptyStr;
          Edit1.Clear;
          Edit1.SetFocus;
          Exit;
        end
      end;

      if Length(NewName) > 128 then
      begin
        Winapi.Windows.MessageBox(Handle, PChar('Name is too long, maximum 128 characters!'), PChar(Form2.Caption + ' - error create new folder'), MB_ICONWARNING + MB_OK);
        NewName := EmptyStr;
        Edit1.Clear;
        Edit1.SetFocus;
        Exit;
      end;
      FindCap := Form1.ListView1.FindCaption(0, NewName, False, True, True);
      if FindCap <> nil then
      begin
        Winapi.Windows.MessageBox(Handle, PChar('Folder with the same name already exists, please enter a different name!'), PChar(Form1.Caption + ' - error create new folder'), MB_ICONWARNING + MB_OK);
        FreeAndNil(FindCap);
        NewName := EmptyStr;
        Edit1.Clear;
        Edit1.SetFocus;
        Form1.Edit1.Clear;
        Form1.ListView1.Items.Clear;
        Form1.ServerSocket.ExecCommand(Form1.CurrentClient, 0, BytesOf('LISTDIR|' + Form1.CurrentDir), False);
        Exit;
      end;
      FreeAndNil(FindCap);
      Form1.ServerSocket.ExecCommand(Form1.CurrentClient, 0, BytesOf('CREATE_FOLDER|' + Form1.CurrentDir + NewName), False);
      Form2.Close;
      Exit;
     end
    else
     begin
      Winapi.Windows.MessageBox(Handle, PChar('No name entered! Enter a name or exit this menu'), PChar(Form1.Caption + ' - error create new folder'), MB_ICONWARNING + MB_OK);
      NewName := EmptyStr;
      Edit1.Clear;
      Exit;
     end;
   end;

  if
   Button1.Tag = 2    ///// - rename folder
  then
   begin
    if
     (Edit1.Text <> EmptyStr) and (Form1.CurrentClient <> nil)
    then
     begin
      NewName := Edit1.Text;
      for i := 1 to Length(NewName) do
      begin
        if (NewName[i] in ['\', '|', '/', '*', '?', '<', '>', ',', '"', ':']) then
        begin
          Winapi.Windows.MessageBox(Handle, PChar('Name contains invalid characters! Specify a new name without characters - ''. , * ? < > / | \ " :'''), PChar(Form1.Caption + ' - error rename folder '), MB_ICONWARNING + MB_OK);
          Edit1.Text := OldFileName;
          Edit1.SetFocus;
          Exit;
        end
      end;

      if Length(NewName) > 128 then
      begin
        Winapi.Windows.MessageBox(Handle, PChar('Name is too long, maximum 128 characters!'), PChar(Form1.Caption + ' - error rename folder '), MB_ICONWARNING + MB_OK);
        NewName := EmptyStr;
        Edit1.Text := OldFileName;
        Edit1.SetFocus;
        Exit;
      end;

      FindCap := Form1.ListView1.FindCaption(0, NewName, False, True, True);
      if FindCap <> nil then
      begin
        Winapi.Windows.MessageBox(Handle, PChar('Folder with the same name already exists, please enter a different name!'), PChar(Form1.Caption + ' - error rename folder'), MB_ICONWARNING + MB_OK);
        FreeAndNil(FindCap);
        NewName := EmptyStr;
        Edit1.Text := OldFileName;
        Edit1.SetFocus;
        Form1.Edit1.Clear;
        Form1.ListView1.Items.Clear;
        Form1.ServerSocket.ExecCommand(Form1.CurrentClient, 0, BytesOf('LISTDIR|' + Form1.CurrentDir), False);
        Exit;
      end;
       FreeAndNil(FindCap);
       Form1.ServerSocket.ExecCommand(Form1.CurrentClient, 0, BytesOf('RENAME_FOLDER|' + Form1.CurrentDir + OldFileName + '|' + Form1.CurrentDir + NewName), False);
      Form2.Close;
      Exit;
     end
    else
     begin
      Winapi.Windows.MessageBox(Handle, PChar('No name entered! Enter a name or exit this menu'), PChar(Form1.Caption + ' - error rename folder'), MB_ICONWARNING + MB_OK);
      NewName := EmptyStr;
      Edit1.Text := OldFileName;
      Edit1.SetFocus;
      Exit;
     end;
   end;

  if
   Button1.Tag = 3    ///// - rename file
  then
   begin
    if
     (Edit1.Text <> EmptyStr) and (Form1.CurrentClient <> nil)
    then
     begin
      NewName := Edit1.Text;
      for i := 1 to Length(NewName) do
      begin
        if (NewName[i] in ['\', '|', '/', '*', '?', '<', '>', ',', '"', ':']) then
        begin
          Winapi.Windows.MessageBox(Handle, PChar('Name contains invalid characters! Specify a new name without characters - ''. , * ? < > / | \ " :'''), PChar(Form1.Caption + ' - rename file'), MB_ICONWARNING + MB_OK);
          NewName := EmptyStr;
          Edit1.Text := OldFileName;
          Edit1.SetFocus;
          Exit;
        end
      end;

      if Length(NewName) > 128 then
      begin
        Winapi.Windows.MessageBox(Handle, PChar('Name is too long, maximum 128 characters!'), PChar(Form1.Caption + ' - rename file'), MB_ICONWARNING + MB_OK);
        NewName := EmptyStr;
        Edit1.Text := OldFileName;
        Edit1.SetFocus;
        Exit;
      end;

      FindCap := Form1.ListView1.FindCaption(0, NewName, False, True, True);
      if FindCap <> nil then
      begin
        Winapi.Windows.MessageBox(Handle, PChar('File with the same name already exists, please enter a different name!'), PChar(Form1.Caption + ' - rename file'), MB_ICONWARNING + MB_OK);
        FreeAndNil(FindCap);
        Edit1.Text := OldFileName;
        Edit1.SetFocus;
        Form1.Edit1.Clear;
        Form1.ListView1.Items.Clear;
        Form1.ServerSocket.ExecCommand(Form1.CurrentClient, 0, BytesOf('LISTDIR|' + Form1.CurrentDir), False);
        Exit;
      end;
      FreeAndNil(FindCap);
      Form1.ServerSocket.ExecCommand(Form1.CurrentClient, 0, BytesOf('RENAME_FILE|' + Form1.CurrentDir + OldFileName + '|' + Form1.CurrentDir + NewName), False);
      Form2.Close;
      Exit;
     end
    else
     begin
      Winapi.Windows.MessageBox(Handle, PChar('No name entered! Enter a name or exit this menu'), PChar(Form1.Caption + ' - rename file'), MB_ICONWARNING + MB_OK);
      NewName := EmptyStr;
      Edit1.Text := OldFileName;
      Edit1.SetFocus;
      Exit;
     end;
   end;

end;


procedure TForm2.Button2Click(Sender: TObject);
begin
  Close;
end;

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action := caFree;
 Form2 := nil;
end;






end.
