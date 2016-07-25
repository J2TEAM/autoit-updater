#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:         Juno_okyo

	Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

#NoTrayIcon

#Region Includes
#include <Misc.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include "Updater.au3"
#EndRegion Includes

_Singleton(@ScriptName)

#Region Options
Opt('MustDeclareVars', 1)
Opt('WinTitleMatchMode', 2)
Opt('GUICloseOnESC', 0)
Opt('GUIOnEventMode', 1)
#EndRegion Options

; Script Start - Add your code below here
Global Const $VERSION = '1.0.0'
Global Const $SERVER_UPDATE = 'http://localhost/autoit-updater/'

#Region ### START Koda GUI section ###
Global $FormMain = GUICreate('AutoIt Updater Demo v' & $VERSION, 591, 284, -1, -1)
Global $MenuItem1 = GUICtrlCreateMenu('&File')
Global $MenuItem2 = GUICtrlCreateMenuItem('&Exit', $MenuItem1)
GUICtrlSetOnEvent(-1, 'FormMainClose')
Global $MenuItem3 = GUICtrlCreateMenu('&Help')
Global $MenuItem4 = GUICtrlCreateMenuItem('Check for &Update...', $MenuItem3)
GUICtrlSetOnEvent(-1, 'MenuUpdateClick')
GUICtrlCreateMenuItem('', $MenuItem3)
Global $MenuItem6 = GUICtrlCreateMenuItem('&About', $MenuItem3)
GUICtrlSetOnEvent(-1, 'MenuAboutClick')
GUISetFont(12, 400, 0, 'Arial')
GUISetOnEvent($GUI_EVENT_CLOSE, 'FormMainClose')
Global $Label1 = GUICtrlCreateLabel('Demo by Juno_okyo', 149, 120, 293, 42)
GUICtrlSetFont(-1, 25, 400, 0, 'Arial')
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

While 1
	Sleep(100)
WEnd

Func MenuAboutClick()
	MsgBox(64 + 262144, 'About', 'Version: ' & $VERSION, 0, $FormMain)
EndFunc

Func MenuUpdateClick()
	_update($SERVER_UPDATE, $VERSION, False, $FormMain)
	Opt('GUIOnEventMode', 1) ; _update() will turn-off this option, so we need to reset
EndFunc   ;==>MenuUpdateClick

Func FormMainClose()
	Exit
EndFunc   ;==>FormMainClose
