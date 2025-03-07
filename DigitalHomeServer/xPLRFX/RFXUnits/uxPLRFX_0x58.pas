(***********************************************************)
(* xPLRFX                                                  *)
(* part of Digital Home Server project                     *)
(* http://www.digitalhomeserver.net                        *)
(* info@digitalhomeserver.net                              *)
(***********************************************************)
unit uxPLRFX_0x58;

interface

Uses uxPLRFXConst, u_xPL_Message, u_xpl_common, uxPLRFXMessages;

procedure RFX2xPL(Buffer : BytesArray; xPLMessages : TxPLRFXMessages);

implementation

Uses SysUtils;

(*

Type $58 - Date/Time sensors

Buffer[0] = packetlength = $0D;
Buffer[1] = packettype
Buffer[2] = subtype
Buffer[3] = seqnbr
Buffer[4] = id1
Buffer[5] = id2
Buffer[6] = yy
Buffer[7] = mm
Buffer[8] = dd
Buffer[9] = dow
Buffer[10] = hr
Buffer[11] = min
Buffer[12] = sec
Buffer[13] = battery_level:4/rssi:4

xPL Schema

datetime.basic
{
  datetime=<date and time as yyyymmddhhmmss>
  date=<date as yyyymmdd>
  time=<time as hhmmss>
}

sensor.basic
{
  device=dt1 0x<hex sensor id>
  type=battery
  current=0-100
}

*)

const
  // Type
  DATETIME  = $58;

  // Subtype
  DT1  = $01;

var
  SubTypeArray : array[1..1] of TRFXSubTypeRec =
    ((SubType : DT1; SubTypeString : 'dt1'));


procedure RFX2xPL(Buffer : BytesArray; xPLMessages : TxPLRFXMessages);
var
  DeviceID : String;
  SubType : Byte;
  BatteryLevel : Integer;
  Year, Month, Day : String;
  Hour, Minute, Second : String;
  DateString, TimeString : String;
  xPLMessage : TxPLMessage;
begin
  SubType := Buffer[2];
  DeviceID := GetSubTypeString(SubType,SubTypeArray)+IntToHex(Buffer[4],2)+IntToHex(Buffer[5],2);
  // Convert the date
  Year := '20'+IntToStr(Buffer[6]);
  Month := IntToStr(Buffer[7]);
  if Buffer[7] < 10 then
    Month := '0'+Month;
  Day := IntToStr(Buffer[8]);
  if Buffer[8] < 10 then
    Day := '0'+Day;
  Hour := IntToStr(Buffer[10]);
  if Buffer[10] < 10 then
    Hour := '0'+Hour;
  Minute := IntToStr(Buffer[11]);
  if Buffer[11] < 10 then
    Minute := '0'+Minute;
  Second := IntToSTr(Buffer[12]);
  if Buffer[12] < 0 then
    Second := '0'+Second;
  DateString := Year+Month+Day;
  TimeString := Hour+Minute+Second;

  if (Buffer[13] and $0F) = 0 then  // zero out rssi
    BatteryLevel := 0
  else
    BatteryLevel := 100;

  // Create sensor.basic messages
  xPLMessage := TxPLMessage.Create(nil);
  xPLMessage.schema.RawxPL := 'sensor.basic';
  xPLMessage.MessageType := trig;
  xPLMessage.source.RawxPL := XPLSOURCE;
  xPLMessage.target.IsGeneric := True;
  xPLMessage.Body.AddKeyValue('datetime='+DateString+TimeString);
  xPLMessage.Body.AddKeyValue('date='+DateString);
  xPLMessage.Body.AddKeyValue('time='+TimeString);
  xPLMessages.Add(xPLMessage.RawXPL);
  xPLMessage.Free;

  xPLMessage := TxPLMessage.Create(nil);
  xPLMessage.schema.RawxPL := 'sensor.basic';
  xPLMessage.MessageType := trig;
  xPLMessage.source.RawxPL := XPLSOURCE;
  xPLMessage.target.IsGeneric := True;
  xPLMessage.Body.AddKeyValue('device='+DeviceID);
  xPLMessage.Body.AddKeyValue('current='+IntToStr(BatteryLevel));
  xPLMessage.Body.AddKeyValue('type=battery');
  xPLMessages.Add(xPLMessage.RawXPL);
  xPLMessage.Free;

end;

end.
