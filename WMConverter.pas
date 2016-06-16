program WMConverter;

{$mode delphi}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp, IniFiles, math, strutils, FileUtil
  { you can add units after this };

  { TWMConverter }

const
  ATTRMULTIPLIER_HITMULTIPLY       = 100;
  ATTRMULTIPLIER_SPEED             = 10;
  ATTRMULTIPLIER_MOVEMENTACC       = 200;
  ATTRMULTIPLIER_BULLETSPREAD      = 100;
  ATTRMULTIPLIER_PUSH              = 2500;
  ATTRMULTIPLIER_INHERITEDVELOCITY = 100;

type
  TWMConverter = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TWMConverter }

procedure ConvertValue(IniFile: TMemIniFile; SectionName, ValueName: String; Delimiter: Integer);
var
  Value: Extended;
begin
  Value := IniFile.ReadFloat(SectionName, ValueName, NaN);
  if IsNan(Value) then begin
    WriteLn('Invalid value for ', ValueName, ' in section', SectionName, ': ', IniFile.ReadString(SectionName, ValueName, ''));
    Exit;
  end;
  Value := RoundTo(Value / Delimiter, -4);
  //WriteLn('[', SectionName, ']: ', ValueName, ' = ', FormatFloat('', Value));
  IniFile.WriteFloat(SectionName, ValueName, Value);
end;

procedure AddHitboxValues(IniFile: TMemIniFile; SectionName: String; IsRealistic: Boolean);
begin
  if IsRealistic then begin
    IniFile.WriteFloat(SectionName, 'ModifierHead', 1.1);
    IniFile.WriteFloat(SectionName, 'ModifierChest', 1);
    IniFile.WriteFloat(SectionName, 'ModifierLegs', 0.6);
  end else begin
    IniFile.WriteFloat(SectionName, 'ModifierHead', 1.15);
    IniFile.WriteFloat(SectionName, 'ModifierChest', 1);
    IniFile.WriteFloat(SectionName, 'ModifierLegs', 0.9);
  end;
end;

procedure TWMConverter.DoRun;
var
  ErrorMsg: String;
  IniPath, BackupPath: String;
  SectionName: String;
  IniFile: TMemIniFile;
  SectionList: TStringList;
  IsRealistic: Boolean;
  i: Integer;
begin
  // quick check parameters
  ErrorMsg := CheckOptions('h r n w', 'help realistic normal nobackup');
  if ErrorMsg <> '' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  IniPath := Params[ParamCount];
  if HasOption('n', 'normal') then begin
    IsRealistic := False;
    WriteLn('Forcing normal mode');
  end else if HasOption('r', 'realistic') then begin
    IsRealistic := False;
    WriteLn('Forcing realistic mode');
  end else begin
    IsRealistic := AnsiContainsText(LowerCase(IniPath), 'realistic');
    WriteLn('Realistic mode: ', IsRealistic);
  end;

  // parse parameters
  if HasOption('h', 'help') or (IniPath = '') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  if not FileExists(IniPath) then begin
    WriteLn('File not found');
    WriteHelp;
    Terminate;
    Exit;
  end;

  if not HasOption('w', 'nobackup') then begin
    BackupPath := ChangeFileExt(IniPath, '.ini.bak');
    CopyFile(IniPath, BackupPath);

    WriteLn('Backup saved as ', BackupPath);
  end;

  SectionList := TStringList.Create;
  IniFile := TMemIniFile.Create(IniPath);
  IniFile.CacheUpdates := True;
  try
    IniFile.ReadSections(SectionList);
    for i := 0 to SectionList.Count - 1 do begin
      SectionName := SectionList[i];
      if LowerCase(SectionName) = 'info' then
        continue;
      ConvertValue(IniFile, SectionName, 'Damage', ATTRMULTIPLIER_HITMULTIPLY);
      ConvertValue(IniFile, SectionName, 'Speed', ATTRMULTIPLIER_SPEED);
      ConvertValue(IniFile, SectionName, 'MovementAcc', ATTRMULTIPLIER_MOVEMENTACC);
      ConvertValue(IniFile, SectionName, 'BulletSpread', ATTRMULTIPLIER_BULLETSPREAD);
      ConvertValue(IniFile, SectionName, 'Push', ATTRMULTIPLIER_PUSH);
      ConvertValue(IniFile, SectionName, 'InheritedVelocity', ATTRMULTIPLIER_INHERITEDVELOCITY);
      AddHitboxValues(IniFile, SectionName, IsRealistic);
    end;
    IniFile.UpdateFile;
  finally
    IniFile.Free;
    SectionList.Free;
  end;

  WriteLn('File converted successfuly!');
  // stop program loop
  Terminate;
end;

constructor TWMConverter.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;
end;

destructor TWMConverter.Destroy;
begin
  inherited Destroy;
end;

procedure TWMConverter.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExtractFileName(ExeName), '[options] path/to/weapons.ini');
  writeln('Options: ');
  writeln('  -r or --realistic - force realistic mode');
  writeln('  -n or --normal    - force normal mode');
  writeln('  -w or --nobackup  - don''t do backup');
end;

var
  Application: TWMConverter;
begin
  Application := TWMConverter.Create(nil);
  Application.Title := 'WM Converter';
  Application.Run;
  Application.Free;
end.

