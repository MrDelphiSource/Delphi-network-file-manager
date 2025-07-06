unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Samples.Spin, ncSources,
  Vcl.ExtCtrls, Vcl.Menus, System.ImageList, Vcl.ImgList, PngImageList, System.NetEncoding,
  Vcl.AppEvnts, RenameFileForm, AttributesForm;

type
  TTransferMode = (tmNone, tmSending, tmReceiving);

type
  TForm1 = class(TForm)
    ServerSocket: TncServerSource;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Label1: TLabel;
    SpinEdit1: TSpinEdit;
    Button1: TButton;
    ListView1: TListView;
    Panel3: TPanel;
    ProgressBar1: TProgressBar;
    Label2: TLabel;
    Panel4: TPanel;
    Label3: TLabel;
    Edit1: TEdit;
    PopupMenu1: TPopupMenu;
    DownloadFile: TMenuItem;
    PngImageList1: TPngImageList;
    Button2: TButton;
    ApplicationEvents1: TApplicationEvents;
    UploadFile1: TMenuItem;
    PopupMenu2: TPopupMenu;
    N1: TMenuItem;
    RenameFile: TMenuItem;
    ChangeFileAttributes: TMenuItem;
    ExecuteFile: TMenuItem;
    DeleteFile: TMenuItem;
    RenameFolder: TMenuItem;
    CreateNewFolder1: TMenuItem;
    DeleteFolder: TMenuItem;
    ExecuteFileHidden: TMenuItem;
    N2: TMenuItem;
    RefreshList1: TMenuItem;
    N3: TMenuItem;
    RefreshList2: TMenuItem;
    N4: TMenuItem;
    UploadFile2: TMenuItem;
    PopupMenu3: TPopupMenu;
    UploadFile3: TMenuItem;
    RefreshList3: TMenuItem;
    CreateNewFolder2: TMenuItem;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ServerSocketConnected(Sender: TObject; aLine: TncLine);
    procedure ServerSocketDisconnected(Sender: TObject; aLine: TncLine);
    function ServerSocketHandleCommand(Sender: TObject; aLine: TncLine; aCmd: Integer;
      const aData: TBytes; aRequiresResult: Boolean; const aSenderComponent,
      aReceiverComponent: string): TBytes;
    procedure FormDestroy(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure DownloadFileClick(Sender: TObject);
    procedure ListView1Change(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure Button2Click(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure UploadFile1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure RenameFileClick(Sender: TObject);
    procedure ChangeFileAttributesClick(Sender: TObject);
    procedure ExecuteFileClick(Sender: TObject);
    procedure ExecuteFileHiddenClick(Sender: TObject);
    procedure DeleteFileClick(Sender: TObject);
    procedure RenameFolderClick(Sender: TObject);
    procedure CreateNewFolder1Click(Sender: TObject);
    procedure DeleteFolderClick(Sender: TObject);
    procedure RefreshList1Click(Sender: TObject);
    procedure RefreshList2Click(Sender: TObject);
    procedure UploadFile2Click(Sender: TObject);
    procedure UploadFile3Click(Sender: TObject);
    procedure RefreshList3Click(Sender: TObject);
    procedure CreateNewFolder2Click(Sender: TObject);


  private
    { Private declarations }

    FM_UP_DOWN_FileName : string;
    FMFS : TFileStream;
    FMFileSize, FMTransferredBytes : Int64;
    FMTransferMode : TTransferMode;
    FMStop : Boolean;

    procedure SendFileChunk;
    procedure CleanupTransfer;
    procedure FM_UpdateProgress;
  public
    { Public declarations }

    CurrentClient : Pointer;
    CurrentDir : string;
  end;

const
 FCaption : string = ('File Manager - Server (created by MrDelphiSource) 2025');

var
  Form1: TForm1;

implementation

{$R *.dfm}


procedure TForm1.SendFileChunk;
var                                  //Testing
  Buffer: array[0..1020000] of Byte; // 4095 // 8191 // 16383 // 32767 // 65535  // 131071 // 262143 // 524287
  BytesToSend, BytesRead: Integer;
begin
  if
   (FMTransferMode <> tmSending) or (not Assigned(FMFS))
  then
    Exit;

  if
   FMStop
  then
   begin
    FM_UpdateProgress;
    ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('FILE_TF_CANCEL|'), False);
    Exit;
   end;

  try
    // Determine how many bytes to send in this chunk
    BytesToSend := SizeOf(Buffer); //FM_CHUNK_SIZE;
    if
     FMTransferredBytes + BytesToSend > FMFileSize
    then
     BytesToSend := FMFileSize - FMTransferredBytes;

    if
     BytesToSend <= 0
    then
     begin
      // We're done sending the file
      //lblStatus.Caption := 'File sent successfully!';
      CleanupTransfer;
      Exit;
     end;

    // Read from file
    BytesRead := FMFS.Read(Buffer, BytesToSend);
    if
     BytesRead > 0
    then
     begin

      var ChunkData: TBytes;
      SetLength(ChunkData, BytesRead);
      Move(Buffer[0], ChunkData[0], BytesRead);
      // Send chunk to server
      ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('UP_CHUNK_DATA|' + IntToStr(BytesToSend) + '|') + ChunkData , False);                                   //ClientSocket1.Socket.SendBuf(Buffer, BytesRead);

      // Update progress
      Inc(FMTransferredBytes, BytesRead);

      FM_UpdateProgress;
       // Application.ProcessMessages;
      // Use Windows message to allow UI to update

     end;
  except
   CleanupTransfer;
  end;
 Exit;
end;

procedure TForm1.CleanupTransfer;
begin
  if
   Assigned(FMFS)
  then
   FreeAndNil(FMFS);
  FM_UP_DOWN_FileName := EmptyStr;
  FMFileSize := 0;
  FMTransferredBytes := 0;
  ProgressBar1.Position := 0;
  FMTransferMode := tmNone;
  FMStop := False;
  Button2.Enabled := False;
 Exit;
end;

procedure TForm1.FM_UpdateProgress;
var
  PercentComplete: Integer;
begin
  if
   FMFileSize > 0
  then
   begin
    PercentComplete := Round((FMTransferredBytes / FMFileSize) * 100);
    ProgressBar1.Position := PercentComplete;

    if
     FMTransferMode = tmSending
    then
      Label2.Caption := Format('Uploading file: %s (%d%%)',[FM_UP_DOWN_FileName, PercentComplete])
    else
     if
      FMTransferMode = tmReceiving
     then
      Label2.Caption := Format('Downloading file: "%s" (%d%%)',[FM_UP_DOWN_FileName, PercentComplete]);

     if
      FMStop
     then
      begin
       if
        FMTransferMode = tmSending
       then
        begin
         Label2.Caption := ('File ''' + (FM_UP_DOWN_FileName) + ''' upload canceled!');
         CleanupTransfer; //// Reset transfer
         // Create a thread just for the delay
          TThread.CreateAnonymousThread(
           procedure
            begin
              Sleep(1500); // Wait 1 second

              // Then update UI from main thread
              TThread.Synchronize(nil,
                procedure
                 begin
                  if
                   ServerSocket.Active
                  then
                   if
                    CurrentClient <> nil
                   then
                    Label2.Caption := ('Client connected!')
                   else
                    Label2.Caption := ('Server enabled');
                 end);
            end).Start;

        end
       else
       if
        FMTransferMode = tmReceiving
       then
        begin
         Label2.Caption := ('File ''' + (FM_UP_DOWN_FileName) + ''' download canceled!');
         CleanupTransfer; //// Reset transfer
         // Create a thread just for the delay
          TThread.CreateAnonymousThread(
           procedure
            begin
              Sleep(1500); // Wait 1 second

              // Then update UI from main thread
              TThread.Synchronize(nil,
                procedure
                 begin
                  if
                   ServerSocket.Active
                  then
                   if
                    CurrentClient <> nil
                   then
                    Label2.Caption := ('Client connected!')
                   else
                    Label2.Caption := ('Server enabled');
                 end);
            end).Start;
        end;
       Exit;
      end;

    // Check if the transfer is complete
    if
     FMTransferredBytes >= FMFileSize
    then
     begin
      if
       FMTransferMode = tmSending
      then
       begin
        Label2.Caption := ('File ''' + (FM_UP_DOWN_FileName) + ''' uploaded successfully!');
        CleanupTransfer; //// Reset transfer
        // Create a thread just for the delay
          TThread.CreateAnonymousThread(
           procedure
            begin
              Sleep(1500); // Wait 1 second

              // Then update UI from main thread
              TThread.Synchronize(nil,
                procedure
                 begin
                  if
                   ServerSocket.Active
                  then
                   if
                    CurrentClient <> nil
                   then
                    begin
                     Edit1.Text := CurrentDir;
                     ListView1.Items.Clear;
                     ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('LISTDIR|' + CurrentDir), False);
                     Label2.Caption := ('Client connected!');
                    end
                   else
                    Label2.Caption := ('Server enabled');
                 end);
            end).Start;
       end
      else
       if
        FMTransferMode = tmReceiving
       then
        begin
         Label2.Caption := ('File ''' + (FM_UP_DOWN_FileName) + ''' downloaded successfully!');
         CleanupTransfer; //// Reset transfer
         // Create a thread just for the delay
          TThread.CreateAnonymousThread(
           procedure
            begin
              Sleep(1500); // Wait 1 second

              // Then update UI from main thread
              TThread.Synchronize(nil,
                procedure
                 begin
                  if
                   ServerSocket.Active
                  then
                   if
                    CurrentClient <> nil
                   then
                    Label2.Caption := ('Client connected!')
                   else
                    Label2.Caption := ('Server enabled');
                 end);
            end).Start;
        end;
     end;
   end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if
  Assigned(Form2)
 then
  Form2.Close;

 if
  Assigned(Form3)
 then
  Form3.Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 Form1.Caption := FCaption;
 CleanupTransfer;
 CurrentClient := nil;
 CurrentDir := EmptyStr;
 Button1.Tag := 0;
 Button1.Caption := ('Enable server');
 Label2.Caption := ('Ready');
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
 CleanupTransfer;
 if
  Assigned(Form2)
 then
  Form2.Close;
end;

procedure TForm1.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
begin
 HideCaret(Edit1.Handle);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 if
  Button1.Tag = 0
 then
  begin
   if
    ServerSocket.Active
   then
    ServerSocket.Active := False;
   CurrentClient := nil;
   SpinEdit1.Enabled := False;
   ServerSocket.Port := SpinEdit1.Value;
   ServerSocket.Active := True;
   Label2.Caption := ('Server enabled');
   Button1.Tag := 1;
   Button1.Caption := ('Disable server');
  end
 else
  if
   Button1.Tag = 1
  then
   begin
    if
     ServerSocket.Active
    then
     ServerSocket.Active := False;
    CurrentClient := nil;
    SpinEdit1.Enabled := True;
    Label2.Caption := ('Server disabled');
    Button1.Tag := 0;
    Button1.Caption := ('Enable server');
   end;
end;

procedure TForm1.Button2Click(Sender: TObject); //// Cancel transfer file
begin
 if
  FMTransferMode <> tmNone
 then
  FMStop := True;
end;

procedure TForm1.DownloadFileClick(Sender: TObject);  //// Download file
begin
 if (ListView1.Selected = nil) or (CurrentClient = nil) then Exit;
 if
  FMTransferMode <> tmNone
 then
  begin
   Winapi.Windows.MessageBox(Handle, PChar('It is not possible to start the file transfer at this time because the transfer is still in progress!'), PChar(Form1.Caption + ' - file transfer now'),MB_OK+MB_ICONWARNING);
   Exit;
  end;

 if
   (ListView1.Selected <> nil) and (ListView1.Selected.SubItems[0] = ('File'))
 then
  begin
   FM_UP_DOWN_FileName := ListView1.Selected.Caption;
   ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('DW_FILE|' + CurrentDir + FM_UP_DOWN_FileName), False);
  end;
end;

procedure TForm1.UploadFile1Click(Sender: TObject);   //// Upload file - file popup
begin
 if CurrentClient = nil then Exit;
 if
  FMTransferMode <> tmNone
 then
  begin
   Winapi.Windows.MessageBox(Handle, PChar('It is not possible to start the file transfer at this time because the transfer is still in progress!'), PChar(Form1.Caption + ' - file transfer now'),MB_OK+MB_ICONWARNING);
   Exit;
  end;

 if
  OpenDialog1.Execute
 then
  begin
   FM_UP_DOWN_FileName := ExtractFileName(OpenDialog1.FileName);
   FMFS := TFileStream.Create(OpenDialog1.FileName, fmOpenRead or fmShareDenyWrite);
   FMFileSize := FMFS.Size;
   ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('UP_FILE|' + CurrentDir + FM_UP_DOWN_FileName + '|' + IntToStr(FMFileSize)), False);
  end;
end;

procedure TForm1.UploadFile2Click(Sender: TObject);  //// Upload file - folder popup
begin
  if CurrentClient = nil then Exit;
 if
  FMTransferMode <> tmNone
 then
  begin
   Winapi.Windows.MessageBox(Handle, PChar('It is not possible to start the file transfer at this time because the transfer is still in progress!'), PChar(Form1.Caption + ' - file transfer now'),MB_OK+MB_ICONWARNING);
   Exit;
  end;

 if
  OpenDialog1.Execute
 then
  begin
   FM_UP_DOWN_FileName := ExtractFileName(OpenDialog1.FileName);
   FMFS := TFileStream.Create(OpenDialog1.FileName, fmOpenRead or fmShareDenyWrite);
   FMFileSize := FMFS.Size;
   ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('UP_FILE|' + CurrentDir + FM_UP_DOWN_FileName + '|' + IntToStr(FMFileSize)), False);
  end;
end;

procedure TForm1.UploadFile3Click(Sender: TObject); //// Upload file - empty selected popup
begin
  if CurrentClient = nil then Exit;
 if
  FMTransferMode <> tmNone
 then
  begin
   Winapi.Windows.MessageBox(Handle, PChar('It is not possible to start the file transfer at this time because the transfer is still in progress!'), PChar(Form1.Caption + ' - file transfer now'),MB_OK+MB_ICONWARNING);
   Exit;
  end;

 if
  OpenDialog1.Execute
 then
  begin
   FM_UP_DOWN_FileName := ExtractFileName(OpenDialog1.FileName);
   FMFS := TFileStream.Create(OpenDialog1.FileName, fmOpenRead or fmShareDenyWrite);
   FMFileSize := FMFS.Size;
   ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('UP_FILE|' + CurrentDir + FM_UP_DOWN_FileName + '|' + IntToStr(FMFileSize)), False);
  end;
end;

procedure TForm1.RenameFileClick(Sender: TObject);  //// Rename file
begin
 if (ListView1.Selected <> nil) and (ListView1.Selected.SubItems[0] = ('File')) then
  begin
   if
    CurrentClient <> nil
   then
    begin
     Form2 := TForm2.Create(Self);
     Form2.Caption := Form1.Caption + (' - rename file ');
     Form2.Label1.Caption := ('Rename file ');
     Form2.OldFileName := ListView1.Selected.Caption;
     Form2.Button1.Tag := 3;
     Form2.ShowModal;
    end;
  end;
end;

procedure TForm1.RenameFolderClick(Sender: TObject); //// Rename folder
begin
 if (ListView1.Selected <> nil) and (ListView1.Selected.SubItems[0] = ('Folder')) then
  begin
   if
    CurrentClient <> nil
   then
    begin
     Form2 := TForm2.Create(Self);
     Form2.Caption := Form1.Caption + (' - rename folder ');
     Form2.Label1.Caption := ('Rename folder ');
     Form2.OldFileName := ListView1.Selected.Caption;
     Form2.Button1.Tag := 2;
     Form2.ShowModal;
    end;
  end;
end;

procedure TForm1.CreateNewFolder1Click(Sender: TObject); //// Create new folder - folder popup
begin
 if (ListView1.Selected <> nil) and (ListView1.Selected.SubItems[0] = ('Folder')) then
  begin
   if
    CurrentClient <> nil
   then
    begin
     Form2 := TForm2.Create(Self);
     Form2.Caption := Form1.Caption + (' - create new folder ');
     Form2.Label1.Caption := ('New folder ');
     Form2.Button1.Tag := 1;
     Form2.ShowModal;
    end;
  end;
end;

procedure TForm1.CreateNewFolder2Click(Sender: TObject); //// Create new folder - empty selected popup
begin
 if
  (ListView1.Selected = nil) and (CurrentDir <> EmptyStr) and (Length(CurrentDir) >= 3)
 then
  begin
   if
    CurrentClient <> nil
   then
    begin
     Form2 := TForm2.Create(Self);
     Form2.Caption := Form1.Caption + (' - create new folder ');
     Form2.Label1.Caption := ('New folder ');
     Form2.Button1.Tag := 1;
     Form2.ShowModal;
    end;
  end;
end;

procedure TForm1.DeleteFolderClick(Sender: TObject); //// Delete folder
var
  Select : Integer;
begin
  if (ListView1.Selected <> nil) and (ListView1.Selected.SubItems[0] = ('Folder')) then
    begin
      if
       CurrentClient <> nil
      then
       begin
        if
         FMTransferMode <> tmNone
        then
         begin
          Winapi.Windows.MessageBox(Handle, PChar('It is not possible to delete folder at this time because the transfer is still in progress!'), PChar(Form1.Caption + ' - file transfer now'),MB_OK+MB_ICONWARNING);
          Exit;
         end;
        Select := Winapi.Windows.MessageBox(Handle, PChar('Do you really want to send a command to delete this folder?'), PChar(Form1.Caption + ' - delete folder'), MB_ICONWARNING + MB_YESNO);
        if Select = mrYes then
         begin
          ServerSocket.ExecCommand(Form1.CurrentClient, 0, BytesOf('DELETE_FOLDER|' + CurrentDir + ListView1.Selected.Caption), False);
         end
       end;
    end;
end;

procedure TForm1.ChangeFileAttributesClick(Sender: TObject);  //// Change file attributes
begin
    if (ListView1.Selected <> nil) and (ListView1.Selected.SubItems[0] = ('File')) then
    begin
      if
       CurrentClient <> nil
      then
       begin
        Form3 := TForm3.Create(Self);
        Form3.Caption := Form1.Caption + (' - file attributes ');
        Form3.FFileName := CurrentDir + ListView1.Selected.Caption;
        Form3.FAttrib := ListView1.Selected.SubItems[2];
        Form3.ShowModal;
       end;
    end;
end;

procedure TForm1.ExecuteFileClick(Sender: TObject);  //// Open file normal
begin
    if (ListView1.Selected <> nil) and (ListView1.Selected.SubItems[0] = ('File')) then
    begin
      if
       CurrentClient <> nil
      then
       begin
        ServerSocket.ExecCommand(Form1.CurrentClient, 0, BytesOf('OPEN_FILE_SHOW|' + CurrentDir + ListView1.Selected.Caption), False);
       end;
    end;
end;

procedure TForm1.ExecuteFileHiddenClick(Sender: TObject);  //// Open file hidden
begin
    if (ListView1.Selected <> nil) and (ListView1.Selected.SubItems[0] = ('File')) then
    begin
      if
       CurrentClient <> nil
      then
       begin
        ServerSocket.ExecCommand(Form1.CurrentClient, 0, BytesOf('OPEN_FILE_HIDE|' + CurrentDir + ListView1.Selected.Caption), False);
       end;
    end;
end;

procedure TForm1.DeleteFileClick(Sender: TObject); //// Delete file
 var
  Select : Integer;
begin
  if (ListView1.Selected <> nil) and (ListView1.Selected.SubItems[0] = ('File')) then
    begin
      if
       CurrentClient <> nil
      then
       begin
        if
         FMTransferMode <> tmNone
        then
         begin
          Winapi.Windows.MessageBox(Handle, PChar('It is not possible to delete file at this time because the transfer is still in progress!'), PChar(Form1.Caption + ' - file transfer now'),MB_OK+MB_ICONWARNING);
          Exit;
         end;
        Select := Winapi.Windows.MessageBox(Handle, PChar('Do you really want to send a command to delete this file?'), PChar(Form1.Caption + ' - delete file'), MB_ICONWARNING + MB_YESNO);
        if Select = mrYes then
         begin
          ServerSocket.ExecCommand(Form1.CurrentClient, 0, BytesOf('DELETE_FILE|' + CurrentDir + ListView1.Selected.Caption), False);
         end
       end;
    end;
end;

procedure TForm1.RefreshList1Click(Sender: TObject); //// Refresh list - file popup
begin
 if
  CurrentClient <> nil
 then
  begin
   Edit1.Text := CurrentDir;
   ListView1.Items.Clear;
   ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('LISTDIR|' + CurrentDir), False);
  end;
end;

procedure TForm1.RefreshList2Click(Sender: TObject);  //// Refresh list - folder popup
begin
 if
  CurrentClient <> nil
 then
  begin
   Edit1.Text := CurrentDir;
   ListView1.Items.Clear;
   ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('LISTDIR|' + CurrentDir), False);
  end;
end;



procedure TForm1.RefreshList3Click(Sender: TObject);  //// Refresh list - empty selected popup
begin
 if
  CurrentClient <> nil
 then
  begin
   Edit1.Text := CurrentDir;
   ListView1.Items.Clear;
   ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('LISTDIR|' + CurrentDir), False);
  end;
end;

procedure TForm1.ListView1Change(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
   if  (CurrentClient = nil) then Exit;
  if
   ListView1.Selected = nil
  then
   begin
    if
     (CurrentDir <> EmptyStr) and (Length(CurrentDir) >= 3)
    then
     ListView1.PopupMenu := PopupMenu3;
   end
  else
  if
   (ListView1.Selected.SubItems[0] = ('File'))
  then
   ListView1.PopupMenu := PopupMenu1
  else
   if
    (ListView1.Selected.SubItems[0] = ('Folder'))
   then
    ListView1.PopupMenu := PopupMenu2
   else
    ListView1.PopupMenu := nil;
end;

procedure TForm1.ListView1DblClick(Sender: TObject);
begin
  if (ListView1.Selected = nil) or (CurrentClient = nil) then Exit;

  if
   (ListView1.Selected.SubItems[0] = ('File'))
  then
   begin
    PopupMenu1.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
    Exit;
   end
  else
  if
   (ListView1.Selected.SubItems[0] = ('Folder')) or (ListView1.Selected.SubItems[0] = ('Disc'))
  then
   begin
    CurrentDir := CurrentDir + ListView1.Selected.Caption;
     if
      CurrentDir[Length(CurrentDir)] <> ('\')
     then
      begin
       CurrentDir := (CurrentDir + '\');
      end;
   end
  else
  if
   (ListView1.Selected.Caption = ('|*BACK*|'))
  then
   begin
    if
     (CurrentDir <> EmptyStr) and (Length(CurrentDir) > 3)
    then
     begin
      if
       CurrentDir[Length(CurrentDir)] = ('\')
      then
       begin
        Delete(CurrentDir, Length(CurrentDir), 1);
       end;
      Delete(CurrentDir, LastDelimiter('\', CurrentDir) + 1, Length(CurrentDir) - LastDelimiter('\', CurrentDir));
     end
    else
     if
      (CurrentDir <> EmptyStr) and (Length(CurrentDir) = 3)
     then
      begin
       CurrentDir := EmptyStr;
       Edit1.Clear;
       ListView1.Items.Clear;
       if
        CurrentClient <> nil
       then
        ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('LISTDISCS|'), False);
       Exit;
      end;
   end;

    if
     CurrentClient <> nil
    then
     begin
      Edit1.Text := CurrentDir;
      ListView1.Items.Clear;
      ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('LISTDIR|' + CurrentDir), False);
     end;
   Exit;
end;



procedure TForm1.ServerSocketConnected(Sender: TObject; aLine: TncLine);
begin
 if
  CurrentClient <> nil
 then
  Exit;
 ServerSocket.ExecCommand(aLine, 0, BytesOf('ID_CONN|'), False);
end;

procedure TForm1.ServerSocketDisconnected(Sender: TObject; aLine: TncLine);
begin
 CleanupTransfer;
 CurrentClient := nil;
 CurrentDir := EmptyStr;
 Edit1.Clear;
 ListView1.Items.Clear;
 while
  PngImageList1.Count > 6
 do
  PngImageList1.Delete(PngImageList1.Count - 1);
 Label2.Caption := ('Client disconnected');
 Form1.Caption := FCaption;
  if
   Assigned(Form2)
  then
   Form2.Close;
  if
   Assigned(Form3)
  then
   Form3.Close;
end;

function TForm1.ServerSocketHandleCommand(Sender: TObject; aLine: TncLine; aCmd: Integer;
  const aData: TBytes; aRequiresResult: Boolean; const aSenderComponent,
  aReceiverComponent: string): TBytes;
 var
  Command: string;           // String representation of received command
  Params: TArray<string>;    // Array of parsed command parameters
  ChunkData: TBytes;
  HeaderLength : Integer;
begin
 // Convert raw bytes to string for command parsing
  Command := stringof(aData);
 // Parse pipe-delimited command string into parameter array
  with Tstringlist.Create do
    try
      Delimiter := '|';
      strictdelimiter := true;
      Delimitedtext := Command;

      // Transfer string list items to static array for later use
      setlength(Params, Count);
      for var I := 0 to Count - 1 do
        Params[I] := strings[I];
    finally
      Free;  // Ensure string list is freed even if exception occurs
    end;

  // Exit if no command parameters were found
  if Length(Params) = 0 then
    Exit;

  // Create thread-safe copy of parameters and connection reference
  var
  ParamsCopy := Copy(Params, 0, Length(Params));
  var
  LineRef := aLine;

  if
   Params[0] = 'ID_CONN_OK_200'
  then
   begin
     // Create thread-safe copy of parameters
    // var CopyParams := Copy(Params, 0, Length(Params));

    TThread.Queue(nil,
      procedure
       begin
        CurrentClient := LineRef;
        Label2.Caption := ('Client connected!');
        Form1.Caption := FCaption + (' - client connected! SocketID : ' + IntToStr(Integer(CurrentClient)));
        CurrentDir := EmptyStr;
        Edit1.Clear;
        ListView1.Items.Clear;
        ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('LISTDISCS|'), False);
       end
      );
    Exit;
   end;

  if
   Params[0] = 'LISTDISCS'
  then
   begin
     // Create thread-safe copy of parameters
     var CopyParams := Copy(Params, 0, Length(Params));
    TThread.Queue(nil,
      procedure
       var
        I : Integer;
        LI : TListItem;
       begin
        if
         Length(CopyParams) > 1
        then
         begin
          while
           PngImageList1.Count > 6
          do
           PngImageList1.Delete(PngImageList1.Count - 1);

          ListView1.SmallImages := PngImageList1;
          for
           I := 1 to Length(CopyParams)-1
          do
           begin
            LI := ListView1.Items.Add;
            LI.Caption := (Copy(CopyParams[i], 1, 1) + ':\');
            LI.SubItems.Add('Disc');
            case StrToInt(Copy(CopyParams[i], 2, 1)) of
              1:
                LI.ImageIndex := 0; //// fixed disc icon
              2:
                LI.ImageIndex := 1; //// removable disc icon
              3:
                LI.ImageIndex := 2;  //// cd rom disc icon
              5:
                LI.ImageIndex := 3; //// remote disc icon
            else
               //// bad disc
               //// LI.ImageIndex := ?;
            end;
           end;
         end;
       end
      );
    Exit;
   end;

  if
   Params[0] = ('FFLIST')
  then
   begin

    TThread.CreateAnonymousThread(        /////!!!!! TThread.Queue
      procedure
       var
        I : Integer;
        BS : TBytesStream;
        CombinedList, FolderList, FileList : TStringList;
        LI : TListItem;
        FileParams : TArray<string>;
        FileSize: Int64;
        SizeStr: string;
        IconData: TBytes;
        IconStream: TMemoryStream;
        IconIndex: Integer;
        TempBitmap: TBitmap;

       begin
         while
          PngImageList1.Count > 6
         do
          PngImageList1.Delete(PngImageList1.Count - 1);

        try
         BS := TBytesStream.Create(Copy(aData, 7, length(aData)));
         CombinedList := TStringList.Create;
         FolderList := TStringList.Create;
         FileList := TStringList.Create;
         FolderList.Sorted := True;
         FileList.Sorted := True;
         if
          BS.Size > 0
         then
          begin
           CombinedList.LoadFromStream(BS);
           if
            CombinedList.Count > 0
           then
            begin

             for
              I := 0 to CombinedList.Count-1
             do
              begin
               if
                Copy(CombinedList.Strings[I],1,3) = ('[D]')
               then
                begin
                 FolderList.Add(Copy(CombinedList.Strings[I],4,Length(CombinedList.Strings[I])-3));
                end
               else
                if
                 Copy(CombinedList.Strings[I],1,3) = ('[F]')
                then
                 begin
                  FileList.Add(Copy(CombinedList.Strings[I],4,Length(CombinedList.Strings[I])-3));
                 end;
              end;


             if
              FolderList.Count > 0
             then
              begin
               ListView1.Items.BeginUpdate;
               for
                I := 0 to FolderList.Count-1
               do
                begin
                 LI := ListView1.Items.Add;
                 LI.ImageIndex := 5;
                 LI.Caption := FolderList.Strings[I];
                 LI.SubItems.Add('Folder');
                end;
               ListView1.Items.EndUpdate;
              end;

             if
              FileList.Count > 0
             then
              begin

               ListView1.Items.BeginUpdate;

               for
                I := 0 to FileList.Count-1
               do
                begin
                 with Tstringlist.Create do
                 try
                  Delimiter := '|';
                  StrictDelimiter := True;
                  DelimitedText := FileList.Strings[I];
                  SetLength(FileParams, Count);
                  for var j := 0 to Count - 1 do
                  FileParams[j] := strings[j];
                 finally
                  Free;
                 end;



                 // Format file size inline
                 FileSize := StrToInt64Def(FileParams[1], 0);

                 if FileSize < 1024 then
                  SizeStr := Format('%d bytes', [FileSize])
                 else if FileSize < 1024 * 1024 then
                  SizeStr := Format('%.2f KB', [FileSize / 1024])
                 else if FileSize < 1024 * 1024 * 1024 then
                  SizeStr := Format('%.2f MB', [FileSize / (1024 * 1024)])
                 else
                  SizeStr := Format('%.2f GB', [FileSize / (1024 * 1024 * 1024)]);



                  IconData := TNetEncoding.Base64String.DecodeStringToBytes(FileParams[4]);

                 // Add icon to ImageList if we have icon data
                    IconIndex := 6; // Default icon index

                    if Length(IconData) > 0 then
                    begin
                      IconStream := TMemoryStream.Create;
                      try
                        IconStream.Write(IconData[0], Length(IconData));
                        IconStream.Position := 0;

                        // Create bitmap and load from stream
                        TempBitmap := TBitmap.Create;
                        try
                          TempBitmap.Transparent := True;
                          TempBitmap.LoadFromStream(IconStream);
                          // Add bitmap to ImageList
                          IconIndex := PngImageList1.AddMasked(TempBitmap, clWhite);

                          //PngImageList1.ColorDepth := cd32bit;
                          PngImageList1.DrawingStyle := {(dsTransparent)}  (dsNormal);

                        finally
                          TempBitmap.Free;
                        end;
                      finally
                        IconStream.Free;
                        SetLength(IconData,0);
                      end;
                    end;



                 LI := ListView1.Items.Add;
                 LI.ImageIndex := IconIndex;
                 LI.Caption := FileParams[0];
                 LI.SubItems.Add('File');
                 LI.SubItems.Add(SizeStr);
                 LI.SubItems.Add(FileParams[2]);
                 LI.SubItems.Add(FileParams[3]);
                end;
               ListView1.Items.EndUpdate;
              end;
            end;
          end;

         if
          (CurrentDir <> EmptyStr) and (Length(CurrentDir) >= 3)
         then
          begin
            ListView1.Items.Insert(0);
            ListView1.Items.Item[0].Caption := ('|*BACK*|');
            ListView1.Items.Item[0].SubItems.Insert(0, '');
            ListView1.Items.Item[0].SubItems.Insert(1, '');
            ListView1.Items.Item[0].SubItems.Insert(2, '');
            ListView1.Items.Item[0].SubItems.Insert(3, '');
            ListView1.Items.Item[0].ImageIndex := 4;
          end;
        finally

         BS.Free;
         CombinedList.Free;
         FolderList.Free;
         FileList.Free;
        end;

       end).Start;
    Exit;
   end;



  if
   Params[0] = 'FILE_SIZE'
  then
   begin
     // Create thread-safe copy of parameters
     var CopyParams := Copy(Params, 0, Length(Params));

    TThread.Queue(nil,
      procedure
       var
        MessSelect : Integer;
       begin
        if
         Length(CopyParams) = 2
        then
         begin

          if
           not (DirectoryExists(ExtractFilePath(ParamStr(0)) + '\Download files'))
          then
           ForceDirectories(ExtractFilePath(ParamStr(0)) + '\Download files');

          if
           FileExists(ExtractFilePath(ParamStr(0)) + '\Download files\' + FM_UP_DOWN_FileName)
          then
           begin
            MessSelect := Winapi.Windows.MessageBox(Handle, PChar('File '''+ (FM_UP_DOWN_FileName) +''' already exists. Overwrite?'), PChar(Form1.Caption + ' - duplicate file!'), MB_ICONWARNING + MB_YESNO);
            if
             MessSelect = mrNo
            then
             begin
                /// File transfer cancelled
              ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('FILE_DW_CANCEL|'), False);
              Winapi.Windows.MessageBox(Handle, PChar('File transfer cancelled!'), PChar(Form1.Caption + ' - File manager'), MB_ICONINFORMATION + MB_OK);
              Exit;
             end;
           end;

          FMFileSize := StrToInt64(CopyParams[1]);
          FMTransferredBytes := 0;
          FMFS := TFileStream.Create(ExtractFilePath(ParamStr(0)) + '\Download files\' + (FM_UP_DOWN_FileName), fmCreate);
          FMTransferMode := tmReceiving;
          Button2.Enabled := True;
          ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('FILE_READY_TO_DW|'), False);
         end;
       end
      );
    Exit;
   end;

  if
   Params[0] = 'DW_CHUNK_DATA'
  then
   begin
     // Create thread-safe copy of parameters
     var CopyParams := Copy(Params, 0, Length(Params));
    if
     (FMTransferMode <> tmReceiving) or (not(Assigned(FMFS)))
    then
     Exit;

    if
     Length(CopyParams) > 2
    then
     begin
      var DataSize := StrToIntDef(CopyParams[1], 0);

      // Calculate position of binary data
      //var HeaderLength := Length('CHUNK_DATA|' + Params[1] + '|');
          HeaderLength := Length('DW_CHUNK_DATA|' + CopyParams[1] + '|');
       // Process chunk data
      if
       (DataSize > 0) and (HeaderLength < Length(aData))
      then
       begin
        // Extract the binary data
       // var ChunkData: TBytes;
        SetLength(ChunkData, DataSize);
        Move(aData[HeaderLength], ChunkData[0], DataSize);

         // Process the download chunk
        TThread.Queue(nil,
         procedure
          begin
            if
             FMStop
            then
             begin
              FM_UpdateProgress;
              ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('FILE_TF_CANCEL|'), False);
              Exit;
             end;


            if
             Assigned(FMFS)
            then
             begin
              FMFS.WriteBuffer(ChunkData[0], DataSize);
              Inc(FMTransferredBytes, DataSize);
              FM_UpdateProgress;
              // Acknowledge receipt of chunk
              ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('DW_CHUNK_RECEIVED|'), False);
             end;
          end);
       end;
     end;
    Exit;
   end;


   if
    Params[0] = ('FILE_READY_TO_UP')
   then
    begin
     TThread.Queue(nil,
      procedure
       begin
        FMTransferMode := tmSending;
        Button2.Enabled := True;
        SendFileChunk;
       end);
     Exit;
    end;

   if
    Params[0] = ('UP_CHUNK_RECEIVED')
   then
    begin
     TThread.Queue(nil,
      procedure
       begin
        if
         Assigned(FMFS) and (FMTransferredBytes < FMFileSize)
        then
         SendFileChunk;
       end);
     Exit;
    end;

   if
    (Params[0] = ('SUCCESS_RENAME_FILE')) or (Params[0] = ('SUCCESS_CHMOD_FILE')) or (Params[0] = ('SUCCESS_DELETE_FILE'))
     or (Params[0] = ('SUCCESS_RENAME_FOLDER')) or (Params[0] = ('SUCCESS_CREATE_FOLDER')) or (Params[0] = ('SUCCESS_DELETE_FOLDER'))
   then
    begin
     TThread.Queue(nil,
      procedure
       begin
        if
          CurrentClient <> nil
        then
         begin
          Edit1.Text := CurrentDir;
          ListView1.Items.Clear;
          ServerSocket.ExecCommand(CurrentClient, 0, BytesOf('LISTDIR|' + CurrentDir), False);
         end;
       end);
     Exit;
    end;


   if
    Params[0] = ('FAILED_RENAME_FILE')
   then
    begin
     TThread.Queue(nil,
      procedure
       begin
        Winapi.Windows.MessageBox(Handle, PChar('Failed to rename file! File is open in another program or locked!'), PChar(Form1.Caption + ' - error rename file '), MB_ICONWARNING + MB_OK);
       end);
     Exit;
    end;

   if
    Params[0] = ('FAILED_RENAME_FOLDER')
   then
    begin
     TThread.Queue(nil,
      procedure
       begin
        Winapi.Windows.MessageBox(Handle, PChar('Failed to rename folder! Folder is in use by other applications or locked!'), PChar(Form1.Caption + ' - error rename folder '), MB_ICONWARNING + MB_OK);
       end);
     Exit;
    end;

   if
    Params[0] = ('FAILED_CHMOD_FILE')
   then
    begin
     TThread.Queue(nil,
      procedure
       begin
        Winapi.Windows.MessageBox(Handle, PChar('Failed to change attributes file! File is open in another program or locked!'), PChar(Form1.Caption + ' - error set attributes file '), MB_ICONWARNING + MB_OK);
       end);
     Exit;
    end;

   if
    Params[0] = ('FAILED_DELETE_FILE')
   then
    begin
     TThread.Queue(nil,
      procedure
       begin
        Winapi.Windows.MessageBox(Handle, PChar('Failed to delete file! File is open in another program or locked!'), PChar(Form1.Caption + ' - error delete file '), MB_ICONWARNING + MB_OK);
       end);
     Exit;
    end;

   if
    Params[0] = ('ERROR_FOLDER_EXISTS')
   then
    begin
     TThread.Queue(nil,
      procedure
       begin
        Winapi.Windows.MessageBox(Handle, PChar('Cannot create a folder with that name! A folder with that name already exists!'), PChar(Form1.Caption + ' - error create new folder '), MB_ICONWARNING + MB_OK);
       end);
     Exit;
    end;

   if
    Params[0] = ('FAILED_CREATE_FOLDER')
   then
    begin
     TThread.Queue(nil,
      procedure
       begin
        Winapi.Windows.MessageBox(Handle, PChar('Unable to create a new folder! You may not have sufficient permissions for this action!'), PChar(Form1.Caption + ' - error create new folder '), MB_ICONWARNING + MB_OK);
       end);
     Exit;
    end;

   if
    Params[0] = ('FAILED_DELETE_FOLDER')
   then
    begin
     TThread.Queue(nil,
      procedure
       begin
        Winapi.Windows.MessageBox(Handle, PChar('Cannot delete folder! You may not have sufficient permissions or some files in this folder are currently being used by other applications!'), PChar(Form1.Caption + ' - error delete folder '), MB_ICONWARNING + MB_OK);
       end);
     Exit;
    end;

 ///////// Based on the code from "BitMasterXor - https://github.com/BitmasterXor/TClientSocket-TServerSocket-File-Transfer"

end;


end.  ////////////////////////////////////////////////////////////////////////////////////////////




