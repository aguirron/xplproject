VERSION 5.00
Object = "{D9D65F26-40A3-4F6C-8DF0-998D98138058}#1.1#0"; "xPL.ocx"
Begin VB.Form xPL_Template 
   Caption         =   "xPL Template"
   ClientHeight    =   5955
   ClientLeft      =   60
   ClientTop       =   450
   ClientWidth     =   4005
   Icon            =   "xPL_Template.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   5955
   ScaleWidth      =   4005
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Begin VB.Timer VoiceTimer 
      Enabled         =   0   'False
      Interval        =   60000
      Left            =   2040
      Top             =   480
   End
   Begin VB.CheckBox chkActive 
      Height          =   255
      Left            =   3360
      TabIndex        =   4
      Top             =   4560
      Width           =   375
   End
   Begin xPL.xPLCtl xPLSys 
      Left            =   3120
      Top             =   360
      _ExtentX        =   1720
      _ExtentY        =   1508
   End
   Begin VB.TextBox txtMsg 
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   9.75
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   3735
      Index           =   1
      Left            =   120
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   1
      Top             =   720
      Width           =   3735
   End
   Begin VB.TextBox txtMsg 
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   9.75
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   975
      Index           =   0
      Left            =   120
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   0
      Top             =   4920
      Width           =   3735
   End
   Begin VB.Label lblxPL 
      Alignment       =   2  'Center
      Caption         =   "xPL Tx"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   615
      Index           =   1
      Left            =   120
      TabIndex        =   3
      Top             =   120
      Width           =   3735
   End
   Begin VB.Label lblxPL 
      Alignment       =   2  'Center
      Caption         =   "Recognition"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   375
      Index           =   0
      Left            =   120
      TabIndex        =   2
      Top             =   4560
      Width           =   3735
   End
   Begin VB.Menu mPopupSys 
      Caption         =   "&SysTray"
      Visible         =   0   'False
      Begin VB.Menu mPopRestore 
         Caption         =   "&Restore"
      End
      Begin VB.Menu mPopExit 
         Caption         =   "&Exit"
      End
   End
End
Attribute VB_Name = "xPL_Template"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'**************************************
'* xPL Voice
'*
'* Copyright (C) 2003 Tony Tofts
'* http://www.xplhal.com
'*
'* This program is free software; you can redistribute it and/or
'* modify it under the terms of the GNU General Public License
'* as published by the Free Software Foundation; either version 2
'* of the License, or (at your option) any later version.
'*
'* This program is distributed in the hope that it will be useful,
'* but WITHOUT ANY WARRANTY; without even the implied warranty of
'* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'* GNU General Public License for more details.
'*
'* You should have received a copy of the GNU General Public License
'* along with this program; if not, write to the Free Software
'* Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
'**************************************

' lines marked @@@ are application specific and will/may need amending

' this framework has a function for extracting a single name/value pair value
' xPL_GetParam(Msg As xPL.xPLMsg, strName As String, WithStrip As Boolean) As Variant
' Msg is the received message
' strName is the name/value pair name required
' WithStrip is True/False to specify if value should be trimmed
' Returns a variant data type

' simple example of sending a message and having it displayed in tx textbox
'    myMsg = "device=a1,a2" + Chr$(10) + "command=on"
'    Call SendXplMsg("XPL-CMND", "*", "X10.BASIC", myMsg)

' to include status info in heartbeat message
' use xPLSys.StatusSchema = "<class>.<type>" to set schema type
' use xPLSys.StatusMsg = "<xpl message body>" to set status info
' to disable, set either or both to ""

' for further information please refer to the readme.txt file for xPLocx

Option Explicit

Private CP_Speech As New SpVoice
Private WithEvents RecoContext As SpSharedRecoContext
Attribute RecoContext.VB_VarHelpID = -1
Private Grammar As ISpeechRecoGrammar

Private Sub VoiceTimer_Timer()
    
    ' restore context
    VoiceTimer.Enabled = False
    Grammar.CmdLoadFromFile App.Path & "\commands.xml", SLOStatic
    Grammar.DictationSetState SGDSInactive
    Grammar.CmdSetRuleIdState 1, SGDSActive
    CurrentContext = "commands.xml"
    
End Sub

' process message
Private Sub xPLSys_Received(msg As xPLMsg)

    Dim cmd As String
    Dim filename As String
    
    ' check
    If xPL_Ready = False Then Exit Sub
    
    ' process message here @@@
    On Error GoTo failed
    cmd = UCase(xPL_GetParam(msg, "COMMAND", True))
    Select Case cmd
    Case "ACTIVATE"
        Activated = True
        Call xPLSys.SendXplMsg("xpl-stat", "*", "voice.basic", "status=activated")
    Case "SUSPEND"
        Activated = False
        Call xPLSys.SendXplMsg("xpl-stat", "*", "voice.basic", "status=suspended")
    Case "OFF"
        Set Grammar = Nothing
        Set RecoContext = Nothing
        Activated = False
        Call xPLSys.SendXplMsg("xpl-stat", "*", "voice.basic", "status=suspended")
    Case "ON"
        If (RecoContext Is Nothing) Then
            Set RecoContext = New SpSharedRecoContext
            Set Grammar = RecoContext.CreateGrammar(1)
            Grammar.CmdLoadFromFile App.Path & "\commands.xml", SLOStatic
            Grammar.DictationSetState SGDSInactive
            Grammar.CmdSetRuleIdState 1, SGDSActive
            CurrentContext = "commands.xml"
        End If
        If xPLSys.Configs("ACTIVATE") = "" Then Activated = True
        If Activated = True Then
            Call xPLSys.SendXplMsg("xpl-stat", "*", "voice.basic", "status=activated")
        Else
            Call xPLSys.SendXplMsg("xpl-stat", "*", "voice.basic", "status=suspended")
        End If
    Case "CONTEXT"
        filename = UCase(xPL_GetParam(msg, "FILENAME", True))
        If filename = "" Then Exit Sub
        If Dir(App.Path + "\" + filename) = "" Then Exit Sub
        Grammar.CmdLoadFromFile App.Path & "\" & filename, SLOStatic
        Grammar.DictationSetState SGDSInactive
        Grammar.CmdSetRuleIdState 1, SGDSActive
        CurrentContext = filename
        VoiceTimer.Enabled = False
        If LCase(CurrentContext) <> "commands.xml" Then
            If Val(xPLSys.Configs("TIMEOUT")) = 0 Or Val(xPLSys.Configs("TIMEOUT")) > 60 Then
                VoiceTimer.Interval = 60000
            Else
                VoiceTimer.Interval = Val(xPLSys.Configs("TIMEOUT")) * 1000
            End If
            VoiceTimer.Enabled = True
        End If
    End Select
    
    ' etc
    On Error GoTo 0
    Exit Sub

failed:
    txtMsg(0) = Error
    On Error GoTo 0
    
End Sub

' process config item
Private Sub xPLSys_Config(Item As String, Value As String, Occurance As Integer)

    ' process config items @@@
    ' IF you want to use your own variables
    ' OR you want to take some action
    Select Case UCase(Item)
'    Case "LATITUDE"

    End Select
    
End Sub

' configuration process complete
Private Sub xPLSys_Configured(Source As String)
    
    Dim f As Integer
    
    ' update source and title
    xPL_Source = Source
    Me.Caption = xPL_Title + " " + xPL_Source
    If InTray = True And IconInit = True Then
        Shell_NotifyIcon NIM_DELETE, nid
        Me.mPopRestore.Caption = xPL_Source
        Me.mPopupSys.Caption = xPL_Source
        nid.szTip = Me.Caption & vbNullChar
        Shell_NotifyIcon NIM_ADD, nid
    End If
    f = FreeFile
    Open App.Path + "\source.cfg" For Output As #f
    Print #f, xPL_Source
    Close #f
    
    ' application specific processing @@@
    ' e.g. do calculations, set com ports etc etc
    Set CP_Speech = New SpVoice
    If (RecoContext Is Nothing) Then
        Set RecoContext = New SpSharedRecoContext
        Set Grammar = RecoContext.CreateGrammar(1)
        Grammar.CmdLoadFromFile App.Path & "\commands.xml", SLOStatic
        Grammar.DictationSetState SGDSInactive
        Grammar.CmdSetRuleIdState 1, SGDSActive
        CurrentContext = "commands.xml"
    End If
    If xPLSys.Configs("ACTIVATE") = "" Then Activated = True
    If Activated = True Then
        Call xPLSys.SendXplMsg("xpl-stat", "*", "voice.basic", "status=activated")
    Else
        Call xPLSys.SendXplMsg("xpl-stat", "*", "voice.basic", "status=suspended")
    End If

    ' flag as configured
    xPL_Ready = True
    
End Sub

' display message received - remove if display not required @@@
Private Sub xPLSys_xPLRX(msg As String)
    
    ' display message
 '   Call xPL_Display(0, Msg)
    
End Sub

' display message sent - remove if display not required @@@
Private Sub xPLSys_xPLTX(msg As String)
    
    ' display message
    Call xPL_Display(1, msg)
    
End Sub

' initial startup sequence
Private Sub Form_Load()

    Dim x As Integer
    
    ' initialise
    InTray = True
    If InStr(1, Command() & " ", "/hide ", vbTextCompare) > 0 Then InTray = False
    xPL_Source = "TONYT-VOICE" ' set vendor-device here @@@
    If Dir(App.Path + "\source.cfg") <> "" Then
        x = FreeFile
        Open App.Path + "\source.cfg" For Input As #x
        Input #x, xPL_Source
        Close #x
    Else
        xPL_Source = xPL_Source & "." & xPL_BuildInstance(xPLSys.HostName)
        x = FreeFile
        Open App.Path + "\source.cfg" For Output As #x
        Print #x, xPL_Source
        Close #x
    End If
    xPL_WaitForConfig = True ' set to false if config not required (not recommended) @@@
    xPL_Ready = False
    xPL_Title = "Voice" ' application title @@@
    Me.Caption = xPL_Title + " " + xPL_Source
    Me.lblxPL(0) = "xPL RX" ' receive box label @@@
    Me.lblxPL(1) = "xPL TX" ' receive box label @@@
    Me.mPopRestore.Caption = xPL_Source
    
    ' pre initialise
    If xPLSys.Initialise(xPL_Source, xPL_WaitForConfig, 5) = False Then
        ' failed to pre-initialise
        Call MsgBox("Sorry, unable to initialise xPL sub-system.", vbCritical + vbOKOnly, "xPL Init Failed")
        Unload Me
        Exit Sub
    End If
    
    ' add extra configs (set config/reconf/option as needed) @@@
'    Call xPLSys.ConfigsAdd("LATITUDE", "CONFIG",1)
'    etc
    Call xPLSys.ConfigsAdd("ZONE", "OPTION", 1)
    Call xPLSys.ConfigsAdd("CONFIRM", "OPTION", 1)
    Call xPLSys.ConfigsAdd("ACTIVATE", "OPTION", 1)
    Call xPLSys.ConfigsAdd("SUSPEND", "OPTION", 1)
    Call xPLSys.ConfigsAdd("CONFIDENCE", "OPTION", 1)
    Call xPLSys.ConfigsAdd("TIMEOUT", "OPTION", 1)
    
    ' add default extra config values if possible @@@
    ' xPLSys.Configs("LATITUDE") = "1.04532"
'    etc
    xPLSys.Configs("CONFIRM") = "N"
    xPLSys.Configs("CONFIDENCE") = "NORMAL"
    xPLSys.Configs("TIMEOUT") = "60"
    
    ' add default filters @@@
    'Call xPLSys.FiltersAdd("xpl-cmnd.tonyt.voice.*.voice.basic")
    ' etc
    
    ' add default groups (not recommended) @@@
'    Call xPLSys.GroupsAdd("MYGROUP")
    ' etc
    
    ' set up other options @@@
    xPLSys.PassCONFIG = False
    xPLSys.PassHBEAT = False
    xPLSys.PassNOMATCH = False
    xPLSys.StatusSchema = "" ' schema for status in heartbeat
    xPLSys.StatusMsg = "" ' message for status in heartbeat
    
    ' initialise other stuff here prior to start @@@
    
    ' initialise xPL
    If xPLSys.Start = False Then
        ' failed to initialise
        Call MsgBox("Sorry, unable to start xPL sub-system.", vbCritical + vbOKOnly, "xPL Start Failed")
        Unload Me
        Exit Sub
    End If
    
    ' initialise other stuff here after start @@@

    ' for icon tray form must be fully visible before calling Shell_NotifyIcon
    Me.Show
    Me.Refresh
    If InTray = True Then
        With nid
            .cbSize = Len(nid)
            .hwnd = Me.hwnd
            .uId = vbNull
            .uFlags = NIF_ICON Or NIF_TIP Or NIF_MESSAGE
            .uCallBackMessage = WM_MOUSEMOVE
            .hIcon = Me.Icon
            .szTip = Me.Caption & vbNullChar
        End With
        Shell_NotifyIcon NIM_ADD, nid
        IconInit = True
    End If
    Me.WindowState = vbMinimized
    
    ' flag as configured
    If xPL_WaitForConfig = False Then xPL_Ready = True
    
End Sub

' routine to display xPL message in rx/tx status boxes
Private Sub xPL_Display(intDisplay As Integer, strmsg As String)

    Dim x As Integer

    ' display message
    txtMsg(intDisplay) = Format(Now(), "dd/mm/yy hh:mm:ss") + vbCrLf + vbCrLf
    For x = 1 To Len(strmsg)
        Select Case Mid$(strmsg, x, 1)
        Case Chr$(10)
            txtMsg(intDisplay) = txtMsg(intDisplay) + vbCrLf
        Case Chr$(2)
            txtMsg(intDisplay) = txtMsg(intDisplay) + "<STX>"
        Case Chr$(3)
            txtMsg(intDisplay) = txtMsg(intDisplay) + "<ETX>"
        Case Else
            txtMsg(intDisplay) = txtMsg(intDisplay) + Mid$(strmsg, x, 1)
        End Select
    Next x
    
End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, x As Single, y As Single)
        
    'this procedure receives the callbacks from the System Tray icon.
    Dim Result As Long
    Dim msg As Long
         
    'the value of X will vary depending upon the scalemode setting
    If Me.ScaleMode = vbPixels Then
        msg = x
    Else
        msg = x / Screen.TwipsPerPixelX
    End If
    Select Case msg
    Case WM_LBUTTONUP        '514 restore form window
        Me.WindowState = vbNormal
        Result = SetForegroundWindow(Me.hwnd)
        On Error Resume Next
        Me.Show
        On Error GoTo 0
    Case WM_LBUTTONDBLCLK    '515 restore form window
        Me.WindowState = vbNormal
        Result = SetForegroundWindow(Me.hwnd)
        On Error Resume Next
        Me.Show
        On Error GoTo 0
    Case WM_RBUTTONUP        '517 display popup menu
        Result = SetForegroundWindow(Me.hwnd)
        Me.PopupMenu Me.mPopupSys
    End Select
        
End Sub
 
Private Sub Form_Resize()
        
    ' this is necessary to assure that the minimized window is hidden
    If Me.WindowState = vbMinimized Then Me.Hide
    If Me.WindowState <> vbMinimized Then Me.Show
    
End Sub

Private Sub Form_Unload(Cancel As Integer)
    
    ' tidy up stuff here @@@
    
    
    ' this removes the icon from the system tray
    If InTray = True Then Shell_NotifyIcon NIM_DELETE, nid
    
End Sub
 
Private Sub mPopExit_click()
         
    ' called when user clicks the popup menu Exit command
    Unload Me
        
End Sub
 
Private Sub mPopRestore_click()
    
    Dim Result As Long
    
    ' called when the user clicks the popup menu Restore command
    Me.WindowState = vbNormal
    Result = SetForegroundWindow(Me.hwnd)
    Me.Show
    
End Sub

Private Sub RecoContext_Recognition(ByVal StreamNumber As Long, ByVal StreamPosition As Variant, ByVal RecognitionType As SpeechRecognitionType, ByVal Result As ISpeechRecoResult)

    Dim cmd As String
    Dim msg As String
    Dim x As Integer
    Dim c As Integer
    
    On Error GoTo failedreco
    
    ' get text
    cmd = Result.PhraseInfo.GetText
    
    ' check certaintity
    Select Case UCase(xPLSys.Configs("CONFIDENCE"))
    Case "HIGH"
        c = 1
    Case "NORMAL"
        c = 0
    Case "LOW"
        c = -1
    Case Else
        c = 0
    End Select
    If Result.PhraseInfo.Rule.Confidence < c Then
        On Error GoTo 0
        Exit Sub
    End If
    
    ' internal processing
    txtMsg(0) = Format(Now(), "dd/mm/yy hh:mm:ss") + vbCrLf + vbCrLf + cmd
    chkActive.Value = Abs(Activated)
    If Activated = False And LCase(cmd) <> xPLSys.Configs("ACTIVATE") Then
        On Error GoTo 0
        Exit Sub
    End If
    Select Case LCase(cmd)
    Case LCase(xPLSys.Configs("ACTIVATE"))
        Activated = True
        Call xPLSys.SendXplMsg("xpl-stat", "*", "voice.basic", "status=activated")
    Case LCase(xPLSys.Configs("SUSPEND"))
        Activated = False
        Call xPLSys.SendXplMsg("xpl-stat", "*", "voice.basic", "status=suspended")
    Case Else
        msg = "command=" & LCase(cmd) & Chr(10)
        If LCase(CurrentContext) <> "commands.xml" Then msg = msg & "context=" & CurrentContext & Chr(10)
        If xPLSys.Configs("ZONE") <> "" Then msg = msg & "zone=" & xPLSys.Configs("ZONE") & Chr(10)
        Call xPLSys.SendXplMsg("xpl-trig", "*", "voice.basic", msg)
    End Select
    chkActive.Value = Abs(Activated)
    
    ' confirm
    If UCase(xPLSys.Configs("CONFIRM")) = "Y" Then
        Grammar.CmdSetRuleIdState 1, SGDSInactive
        CP_Speech.Speak cmd
        Grammar.CmdSetRuleIdState 1, SGDSActive
    End If
    
    On Error GoTo 0
    Exit Sub
   
failedreco:
    txtMsg(0) = Error
    On Error GoTo 0
End Sub


