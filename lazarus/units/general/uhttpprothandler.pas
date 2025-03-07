unit uhttpprothandler;
interface
{$mode delphi}{$H+}

{$ifdef unix}
  { $ define usezlib}
  { $ define useopenssl}
{$endif}
{$ifdef win32}
  { $ define usezlib}
  { $ define useopenssl}
{$endif}

uses
  {$ifdef usezlib}
    IdCompressorZLib,  //for deflate and gzip content encoding
  {$endif}
  IdAuthenticationDigest, //MD5-Digest authentication
  {$ifdef useopenssl}
    IdSSLOpenSSL,  //ssl
    IdAuthenticationNTLM, //NTLM - uses OpenSSL libraries
  {$endif}
  prothandler,
  Classes, SysUtils, 
  IdHTTP,
  IdURI;

type

  { THTTPProtHandler }

  THTTPProtHandler = class(TProtHandler)
  protected
    LFName : string;
    LProxyServer : string;
    LProxyPort   : integer;
    function GetTargetFileName(AHTTP : TIdHTTP; AURI : TIdURI) : String;
  public
    class function CanHandleURL(AURL : TIdURI) : Boolean; override;
    function GetFile(AURL : TIdURI) : string;                                          // glh
    constructor Create(aDestination, aProxyServer, aProxyPort : string);
  end;

implementation


class function THTTPProtHandler.CanHandleURL(AURL : TIdURI) : Boolean;
begin
  Result := UpperCase(AURL.Protocol)='HTTP';
  {$ifdef useopenssl}
  if not Result then
  begin
    Result := UpperCase(AURL.Protocol)='HTTPS';
  end;
  {$endif}
end;

function THTTPProtHandler.GetFile(AURL : TIdURI) : string;    // glh
var
  {$ifdef useopenssl}
  LIO : TIdSSLIOHandlerSocketOpenSSL;
  {$endif}
  LHTTP : TIdHTTP;
  LStr : TMemoryStream;
  i : Integer;
  LHE : EIdHTTPProtocolException;
 // LFName : String;
 {$ifdef usezlib}
    LC : TIdCompressorZLib;
 {$endif}
begin
  result := '';                                           // glh
  {$ifdef useopenssl}
  LIO := TIdSSLIOHandlerSocketOpenSSL.Create;
  {$endif}
  {$ifdef  usezlib}
  LC := TIdCompressorZLib.Create;
  {$endif}
  try
    LHTTP := TIdHTTP.Create;
    if LProxyServer<>'' then begin
       LHTTP.ProxyParams.ProxyServer:=LProxyServer;
       LHTTP.ProxyParams.ProxyPort:=LProxyPort;
    end;
    try
      {$ifdef useopenssl}
      LHTTP.Compressor := LC;
      {$endif}
      //set to false if you want this to simply raise an exception on redirects
      LHTTP.HandleRedirects := True;
{
Note that you probably should set the UserAgent because some servers now screen out requests from
our default string "Mozilla/3.0 (compatible; Indy Library)" to prevent address harvesters
and Denial of Service attacks.  SOme people have used Indy for these.

Note that you do need a Mozilla string for the UserAgent property. The format is like this:

Mozilla/4.0 (compatible; MyProgram)
}
      LHTTP.Request.UserAgent := 'Mozilla/4.0 (compatible; httpget)';
      LStr := TMemoryStream.Create;
      {$ifdef useopenssl}
      LHTTP.IOHandler := LIO;
      {$endif}
      for i := 0 to LHTTP.Request.RawHeaders.Count -1 do
      begin
        FLogData.Add(LHTTP.Request.RawHeaders[i]);
        if FVerbose then
        begin
          WriteLn(stdout,LHTTP.Request.RawHeaders[i]);
        end;
      end;
         LHTTP.Get(AURL.URI,LStr);
      for i := 0 to LHTTP.Response.RawHeaders.Count -1 do
      begin  
        FLogData.Add(LHTTP.Response.RawHeaders[i]);       
        if FVerbose then
        begin
          WriteLn(stdout,LHTTP.Response.RawHeaders[i]);
        end;
      end;
//      LFName := GetTargetFileName(LHTTP,AURL);
      if LFName <> '' then
      begin
        LStr.SaveToFile(LFName);
      end;

    except
      on E : Exception do
      begin
        result := E.Message;                               // glh
        if E is EIdHTTPProtocolException then
        begin
          LHE := E as EIdHTTPProtocolException;
          WriteLn(stderr,'HTTP Protocol Error - '+IntToStr(LHE.ErrorCode));
          WriteLn(stderr,LHE.ErrorMessage);
          if Verbose = False then
          begin
            for i := 0 to FLogData.Count -1 do
            begin
              Writeln(stderr,FLogData[i]);
            end;
          end;
        end
        else
        begin
          Writeln(stderr,E.Message);
        end;
      end;
    end;
    FreeAndNil(LHTTP);
    FreeAndNil(LStr);
  finally
    {$ifdef useopenssl}
    FreeAndNil(LIO);
    {$endif}
    {$ifdef  usezlib}
    FreeAndNil(LC);
    {$endif}
  end;
end;

constructor THTTPProtHandler.Create(aDestination, aProxyServer, aProxyPort : string);
begin
  inherited Create;
  LFName := aDestination;
  LProxyServer := aProxyServer;
  LProxyPort   := StrToIntDef(aProxyPort,0);
end;

function THTTPProtHandler.GetTargetFileName(AHTTP : TIdHTTP; AURI : TIdURI) : String;
begin
{
We do things this way in case the server gave you a specific document type
in response to a request.

eg.

Request:  http://www.indyproject.org/
Response: http://www.indyproject.org/index.html
}
    if AHTTP.Response.Location <> '' then
    begin
      AURI.URI := AHTTP.Response.Location;
    end;
    Result := AURI.Document;
    if Result = '' then
    begin
      Result := 'index.html';
    end;
end;

end.
