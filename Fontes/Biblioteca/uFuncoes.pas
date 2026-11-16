unit uFuncoes;

interface

uses
 Winapi. Windows, System.SysUtils, Vcl.Graphics, Vcl.Forms, System.Classes, Vcl.ComCtrls;

type
  TConsole = class
  private
    //
  public
    class procedure InserirLinha(var RichEdit: TRichEdit; Texto: string; Cor: TColor);
    class procedure FormatarEditor(var RichEdit: TRichEdit);
  end;

  TAplicacaoInfo = class
  public
    class function Versao: string; static;
    class function DataHoraBuild: TDateTime; static;
    class function Titulo: string; static;
  end;

implementation

uses uConst;

{ TAplicacaoInfo }

class function TAplicacaoInfo.Versao: string;
var
  Size: DWORD;
  Handle: DWORD;
  Buffer: TBytes;
  FileInfo: PVSFixedFileInfo;
  Len: UINT;
begin
  Result := EmptyStr;
  Handle := 0;
  Size := GetFileVersionInfoSize(PChar(Application.ExeName), Handle);
  if Size = 0 then
    Exit;

  SetLength(Buffer, Size);
  if not GetFileVersionInfo(PChar(Application.ExeName), Handle, Size,
    @Buffer[0]) then
    Exit;

  if VerQueryValue(@Buffer[0], '\', Pointer(FileInfo), Len) and
     (Len > 0) then
    Result := Format('%d.%d.%d.%d', [
      HiWord(FileInfo.dwFileVersionMS),
      LoWord(FileInfo.dwFileVersionMS),
      HiWord(FileInfo.dwFileVersionLS),
      LoWord(FileInfo.dwFileVersionLS)]);
end;

class function TAplicacaoInfo.DataHoraBuild: TDateTime;
const
  DOS_SIGNATURE = $5A4D;
  PE_SIGNATURE = $00004550;
  UNIX_TO_FILETIME_SECONDS: UInt64 = 11644473600;
  FILETIME_TICKS_PER_SECOND: UInt64 = 10000000;
var
  Stream: TFileStream;
  DosSignature: Word;
  PeSignature: DWORD;
  PeOffset: LongInt;
  TimeDateStamp: DWORD;
  FileTimeValue: UInt64;
  UtcFileTime: TFileTime;
  LocalFileTime: TFileTime;
  SystemTime: TSystemTime;
begin
  Result := 0;
  Stream := TFileStream.Create(Application.ExeName,
    fmOpenRead or fmShareDenyNone);
  try
    Stream.ReadBuffer(DosSignature, SizeOf(DosSignature));
    if DosSignature <> DOS_SIGNATURE then
      Exit;

    Stream.Position := $3C;
    Stream.ReadBuffer(PeOffset, SizeOf(PeOffset));
    if (PeOffset <= 0) or (PeOffset + 12 > Stream.Size) then
      Exit;

    Stream.Position := PeOffset;
    Stream.ReadBuffer(PeSignature, SizeOf(PeSignature));
    if PeSignature <> PE_SIGNATURE then
      Exit;

    Stream.Position := PeOffset + 8;
    Stream.ReadBuffer(TimeDateStamp, SizeOf(TimeDateStamp));
    if TimeDateStamp = 0 then
      Exit;
  finally
    Stream.Free;
  end;

  FileTimeValue := (UInt64(TimeDateStamp) + UNIX_TO_FILETIME_SECONDS) *
    FILETIME_TICKS_PER_SECOND;
  UtcFileTime.dwLowDateTime := DWORD(FileTimeValue and $FFFFFFFF);
  UtcFileTime.dwHighDateTime := DWORD(FileTimeValue shr 32);

  if not FileTimeToLocalFileTime(UtcFileTime, LocalFileTime) then
    Exit;

  if not FileTimeToSystemTime(LocalFileTime, SystemTime) then
    Exit;

  Result := EncodeDate(SystemTime.wYear, SystemTime.wMonth,
    SystemTime.wDay) + EncodeTime(SystemTime.wHour, SystemTime.wMinute,
    SystemTime.wSecond, SystemTime.wMilliseconds);
end;

class function TAplicacaoInfo.Titulo: string;
var
  AppVersion: string;
  BuildDateTime: TDateTime;
begin
  Result := 'MigraFacil - Migração assistida Firebird 2.5 para Firebird 5';

  AppVersion := Versao;
  if AppVersion <> EmptyStr then
    Result := Result + ' | v' + AppVersion;

  BuildDateTime := DataHoraBuild;
  if BuildDateTime > 0 then
    Result := Result + ' | build ' +
      FormatDateTime('dd/mm/yyyy hh:nn', BuildDateTime);
end;

{ TConsole }

class procedure TConsole.FormatarEditor(var RichEdit: TRichEdit);
begin
  RichEdit.Color := $00444444;//um cinza escuro;
  RichEdit.Font.Color := clWhite;
  RichEdit.Font.Name := 'Consolas';
  RichEdit.Font.Size := 10;
  RichEdit.ReadOnly := True;
end;

class procedure TConsole.InserirLinha(var RichEdit: TRichEdit; Texto: string; Cor: TColor);
begin
  RichEdit.SelStart := RichEdit.GetTextLen;
  RichEdit.SelLength := 0;
  RichEdit.SelAttributes.Color := Cor;
  RichEdit.Lines.Add(Texto);
  RichEdit.SelAttributes.Color := clBlack; //reset
end;

end.
