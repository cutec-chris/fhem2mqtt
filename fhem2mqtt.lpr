program fhem2mqtt;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp, ufhem, laz_synapse, LAZ_MQTT, mqtt
  { you can add units after this };

type

  { TFHEM2MQTT }

  TFHEM2MQTT = class(TCustomApplication)
    procedure FHEMLogInfo(aInfo: string);
  private
    MQTTClient: TMQTTClient;
    FHEMLog: TFHEMLogThread;
    FName : string;
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TFHEM2MQTT }

procedure TFHEM2MQTT.FHEMLogInfo(aInfo: string);
var
  Dev: String;
  Typ: String;
  reading: String;
  value: String;
begin
  writeln(StringReplace(aInfo,'<br>','',[rfReplaceAll]));
  aInfo := copy(aInfo,pos(' ',aInfo)+1,length(aInfo));//Date
  aInfo := copy(aInfo,pos(' ',aInfo)+1,length(aInfo));//Time
  Typ := copy(aInfo,0,pos(' ',aInfo)-1);
  aInfo := copy(aInfo,pos(' ',aInfo)+1,length(aInfo));
  Dev := copy(aInfo,0,pos(' ',aInfo)-1);
  aInfo := copy(aInfo,pos(' ',aInfo)+1,length(aInfo));
  reading := copy(aInfo,0,pos(' ',aInfo)-1);
  if pos(':',reading)=0 then exit;

  aInfo := copy(aInfo,pos(' ',aInfo)+1,length(aInfo));
  value := copy(aInfo,0,pos('<',aInfo)-1);

  if FName='' then
    begin
      FName := FHEMLog.Log.Sock.GetRemoteSinIP;
      FName := FHEMLog.Log.Sock.ResolveIPToName(FName);
    end;

  if not MQTTClient.isConnected then MQTTClient.Connect;
  MQTTClient.Publish('/'+FName+'/'+Dev+'/'+reading,value);
end;

procedure TFHEM2MQTT.DoRun;
var
  ErrorMsg: String;
begin
  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;


  FHEMLog := TFHEMLogThread.Create(GetOptionValue('f','fhem'),True);
  FhemLog.OnInfo:=@FHEMLogInfo;
  MQTTClient := TMQTTClient.Create(GetOptionValue('m','mqtt'),1883);
  if MQTTClient.Connect then
    FHEMLog.Execute;

  // stop program loop
  MQTTClient.Free;
  FHEMLog.Free;
  Terminate;
end;

constructor TFHEM2MQTT.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TFHEM2MQTT.Destroy;
begin
  inherited Destroy;
end;

procedure TFHEM2MQTT.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -hfm');
  writeln('-f FHEM Instance');
  writeln('-m MQTT Instance');
end;

var
  Application: TFHEM2MQTT;
begin
  Application:=TFHEM2MQTT.Create(nil);
  Application.Title:='fhm2mqtt';
  Application.Run;
  Application.Free;
end.

