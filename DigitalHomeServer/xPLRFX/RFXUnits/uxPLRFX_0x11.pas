(***********************************************************)
(* xPLRFX                                                  *)
(* part of Digital Home Server project                     *)
(* http://www.digitalhomeserver.net                        *)
(* info@digitalhomeserver.net                              *)
(***********************************************************)
unit uxPLRFX_0x11;

interface

Uses uxPLRFXConst, u_xPL_Message, u_xpl_common, uxPLRFXMessages;

procedure RFX2xPL(Buffer : BytesArray; xPLMessages : TxPLRFXMessages);
procedure xPL2RFX(aMessage : TxPLMessage; var Buffer : BytesArray);

implementation

Uses SysUtils;

(*

Type $11 - Lighting2 - AC, HomeEasy EU, Anslut

Buffer[0] = packetlength = $0B;
Buffer[1] = packettype
Buffer[2] = subtype
Buffer[3] = seqnbr
Buffer[4] = id1:2/filler1:6
Buffer[5] = id2
Buffer[6] = id3
Buffer[7] = id4
Buffer[8] = unitcode
Buffer[9] = cmnd
Buffer[10] = level
Buffer[11] = filler:4/rssi:4

Test Strings :

0B11000600109B520B000080

xPL schema

ac.basic
{
  address=(0x1-0x3fffffff)
  unit=(0-15)|group
  command=on|off|preset
  [level=(0-15)]
  [protocol=homeasyeu|anslut]
}

*)

const
  // Packet length
  PACKETLENGTH  = $0B;

  // Type
  LIGHTING2     = $11;

  // Subtype
  AC         = $00;
  HOMEASYEU  = $01;
  ANSLUT     = $02;

  // Commands
  COMMAND_OFF      = $00;
  COMMAND_ON       = $01;
  COMMAND_DIM      = $02;
  COMMAND_GROUPOFF = $03;
  COMMAND_GROUPON  = $04;
  COMMAND_GROUPDIM = $05;


procedure RFX2xPL(Buffer : BytesArray; xPLMessages : TxPLRFXMessages);
var
  Address : String;
  UnitCode : String;
  Command : String;
  Level : Integer;
  xPLMessage : TxPLMessage;
begin
  Buffer[4] := Buffer[4] and $03;  // Make sure filler is zeroed
  Address := '0x'+IntToHex(Buffer[4],2)+IntToHex(Buffer[5],2)+IntToHex(Buffer[6],2)+IntToHex(Buffer[7],2);
  if (Buffer[9] = COMMAND_GROUPOFF) or (Buffer[9] = COMMAND_GROUPON) or (Buffer[9] = COMMAND_GROUPDIM) then
    UnitCode := 'group'
  else
    UnitCode := IntToStr(Buffer[8]);
  if (Buffer[9] = COMMAND_OFF) or (Buffer[9] = COMMAND_GROUPOFF) then
    Command := 'off' else
  if (Buffer[9] = COMMAND_ON) or (Buffer[9] = COMMAND_GROUPON) then
    Command := 'on'
  else
    Command := 'preset';
  Level := Buffer[10];

  // Create ac.basic message
  xPLMessage := TxPLMessage.Create(nil);
  xPLMessage.schema.RawxPL := 'ac.basic';
  xPLMessage.MessageType := trig;
  xPLMessage.source.RawxPL := XPLSOURCE;
  xPLMessage.target.IsGeneric := True;
  xPLMessage.Body.AddKeyValue('address='+Address);
  xPLMessage.Body.AddKeyValue('unit='+UnitCode);
  xPLMessage.Body.AddKeyValue('command='+Command);
  if Command = 'preset' then
    xPLMessage.Body.AddKeyValue('level='+IntToStr(Level));
  if Buffer[2] = HOMEASYEU then
    xPLMessage.Body.AddKeyValue('protocol=homeasyeu');
  if Buffer[2] = ANSLUT then
    xPLMessage.Body.AddKeyValue('protocol=anslut');
  xPLMessages.Add(xPLMessage.RawXPL);
end;

procedure xPL2RFX(aMessage : TxPLMessage; var Buffer : BytesArray);
begin
  ResetBuffer(Buffer);
  Buffer[0] := PACKETLENGTH;
  Buffer[1] := LIGHTING2;  // Type
  // Subtype
  if aMessage.Body.Strings.IndexOf('protocol=homeasyEU') > -1 then
    Buffer[2] := HOMEASYEU else
  if aMessage.Body.Strings.IndexOf('protocol=anslut') > -1 then
    Buffer[2] := ANSLUT
  else
    Buffer[2] := AC;
  // Copy the address
  Buffer[4] := StrToInt('$'+Copy(aMessage.Body.Strings.Values['address'],3,2));
  Buffer[5] := StrToInt('$'+Copy(aMessage.Body.Strings.Values['address'],5,2));
  Buffer[6] := StrToInt('$'+Copy(aMessage.Body.Strings.Values['address'],7,2));
  Buffer[7] := StrToInt('$'+Copy(aMessage.Body.Strings.Values['address'],9,2));
  // Unit
  if CompareText(aMessage.Body.Strings.Values['command'],'off') = 0 then
    begin
      if CompareText(aMessage.Body.Strings.Values['unit'],'group') = 0 then
        Buffer[9] := COMMAND_GROUPOFF
      else
        begin
          Buffer[8] := StrToInt(aMessage.Body.Strings.Values['unit']);
          Buffer[9] := COMMAND_OFF;
        end;
    end else
  if CompareText(aMessage.Body.Strings.Values['command'],'on') = 0 then
    begin
      if CompareText(aMessage.Body.Strings.Values['unit'],'group') = 0 then
        Buffer[9] := COMMAND_GROUPON
      else
        begin
          Buffer[8] := StrToInt(aMessage.Body.Strings.Values['unit']);
          Buffer[9] := COMMAND_ON;
        end;
    end
  else
    begin
      if CompareText(aMessage.Body.Strings.Values['unit'],'group') = 0 then
        Buffer[9] := COMMAND_GROUPDIM
      else
        begin
          Buffer[8] := StrToInt(aMessage.Body.Strings.Values['unit']);
          Buffer[9] := COMMAND_DIM;
        end;
    end;
  if aMessage.Body.Strings.IndexOfName('level') > -1 then
    Buffer[10] := StrToInt(aMessage.Body.Strings.Values['level']);
  Buffer[11] := $0;
end;

end.
