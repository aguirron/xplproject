(***********************************************************)
(* xPLRFX                                                  *)
(* part of Digital Home Server project                     *)
(* http://www.digitalhomeserver.net                        *)
(* info@digitalhomeserver.net                              *)
(***********************************************************)
unit uxPLRFX_0x5A;

interface

Uses uxPLRFXConst, u_xPL_Message, u_xpl_common, uxPLRFXMessages;

procedure RFX2xPL(Buffer : BytesArray; xPLMessages : TxPLRFXMessages);

implementation

Uses SysUtils;

(*

Type $5A - Energy usage sensors

Buffer[0] = packetlength = $11;
Buffer[1] = packettype
Buffer[2] = subtype
Buffer[3] = seqnbr
Buffer[4] = id1
Buffer[5] = id2
Buffer[6] = count
Buffer[7] = instant1
Buffer[8] = instant2
Buffer[9] = instant3
Buffer[10] = instant4
Buffer[11] = total1
Buffer[12] = total2
Buffer[13] = total3
Buffer[14] = total4
Buffer[15] = total5
Buffer[16] = total6
Buffer[17] = battery_level:4/rssi:4

Test strings :

115A01071A7300000003F600000000350B89

xPL Schema

sensor.basic
{
  device=elec2|elec3 0x<hex sensor id>
  type=power
  current=<kilowatt>
  units=kw
}

sensor.basic
{
  device=elec2|elec3 0x<hex sensor id>
  type=total
  current=<kilowatt>
  units=kw
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
  ENERGY  = $5A;

  // Subtype
  ELEC2  = $01;
  ELEC3  = $02;

var
  SubTypeArray : array[1..2] of TRFXSubTypeRec =
    ((SubType : ELEC2; SubTypeString : 'elec2'),
     (SubType : ELEC3; SubTypeString : 'elec3'));

procedure RFX2xPL(Buffer : BytesArray; xPLMessages : TxPLRFXMessages);
var
  DeviceID : String;
  SubType : Byte;
  Instant : Integer;
  TempTotal : Int64;
  Total : Extended;
  BatteryLevel : Integer;
  xPLMessage : TxPLMessage;
begin
  SubType := Buffer[2];
  DeviceID := GetSubTypeString(SubType,SubTypeArray)+IntToHex(Buffer[4],2)+IntToHex(Buffer[5],2);
  Instant := (Buffer[7] shl 24) or (Buffer[8] shl 16) or (Buffer[9] shl 8) or Buffer[10];
  TempTotal := Buffer[16];
  TempTotal := TempTotal+(Buffer[15] shl 8);
  TempTotal := TempTotal+(Buffer[14] shl 16);
  TempTotal := TempTotal+(Buffer[13] shl 24);
  TempTotal := TempTotal+(Int64(Buffer[12]) shl 32);
  TempTotal := TempTotal+(Int64(Buffer[11]) shl 40);
  Total := TempTotal / 223.666;

  if (Buffer[17] and $0F) = 0 then  // zero out rssi
    BatteryLevel := 0
  else
    BatteryLevel := 100;

  // Create sensor.basic messages
  xPLMessage := TxPLMessage.Create(nil);
  xPLMessage.schema.RawxPL := 'sensor.basic';
  xPLMessage.MessageType := trig;
  xPLMessage.source.RawxPL := XPLSOURCE;
  xPLMessage.target.IsGeneric := True;
  xPLMessage.Body.AddKeyValue('device='+DeviceID);
  xPLMessage.Body.AddKeyValue('current='+IntToStr(Instant));
  xPLMessage.Body.AddKeyValue('type=power');
  xPLMessage.Body.AddKeyValue('units=kw');
  xPLMessages.Add(xPLMessage.RawXPL);
  xPLMessage.Free;

  xPLMessage := TxPLMessage.Create(nil);
  xPLMessage.schema.RawxPL := 'sensor.basic';
  xPLMessage.MessageType := trig;
  xPLMessage.source.RawxPL := XPLSOURCE;
  xPLMessage.target.IsGeneric := True;
  xPLMessage.Body.AddKeyValue('device='+DeviceID);
  xPLMessage.Body.AddKeyValue('current='+FloatToStrF(Total,ffGeneral,2,20));

  // TO CHECK : how to get the rounding correct in the formatting of Total

  xPLMessage.Body.AddKeyValue('type=total');
  xPLMessage.Body.AddKeyValue('units=kw');
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
