#include-once

#Region Includes
#include <InetConstants.au3>
#include <JSON.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Misc.au3>
#EndRegion Includes

#Region Options
Opt('MustDeclareVars', 1)
Opt('WinTitleMatchMode', 2)
Opt('GUICloseOnESC', 0)
#EndRegion Options

; Script Start - Add your code below here
Func _webDownloader($sSourceURL, $sTargetName, $sVisibleName, $sTargetDir = @TempDir, $bProgressOff = True, $iEndMsgTime = 2000, $sDownloaderTitle = "Downloader")
	; Declare some general vars
	Local $iMBbytes = 1048576

	; If the target directory doesn't exist -> create the dir
	If Not FileExists($sTargetDir) Then DirCreate($sTargetDir)

	; Get download and target info
	Local $sTargetPath = $sTargetDir & "\" & $sTargetName
	Local $iFileSize = InetGetSize($sSourceURL)
	Local $hFileDownload = InetGet($sSourceURL, $sTargetPath, $INET_LOCALCACHE, $INET_DOWNLOADBACKGROUND)

	; Show progress UI
	ProgressOn($sDownloaderTitle, "Downloading " & $sVisibleName)

	; Keep checking until download completed
	Do
		Sleep(250)

		; Set vars
		Local $iDLPercentage = Round(InetGetInfo($hFileDownload, $INET_DOWNLOADREAD) * 100 / $iFileSize, 0)
		Local $iDLBytes = Round(InetGetInfo($hFileDownload, $INET_DOWNLOADREAD) / $iMBbytes, 2)
		Local $iDLTotalBytes = Round($iFileSize / $iMBbytes, 2)

		; Update progress UI
		If IsNumber($iDLBytes) And $iDLBytes >= 0 Then
			ProgressSet($iDLPercentage, $iDLPercentage & "% - Downloaded " & $iDLBytes & " MB of " & $iDLTotalBytes & " MB")
		Else
			ProgressSet(0, "Downloading '" & $sVisibleName & "'")
		EndIf
	Until InetGetInfo($hFileDownload, $INET_DOWNLOADCOMPLETE)

	; If the download was successfull, return the target location
	If InetGetInfo($hFileDownload, $INET_DOWNLOADSUCCESS) Then
		ProgressSet(100, "Downloading '" & $sVisibleName & "' completed")
		If $bProgressOff Then
			Sleep($iEndMsgTime)
			ProgressOff()
		EndIf
		Return $sTargetPath
		; If the download failed, set @error and return False
	Else
		Local $errorCode = InetGetInfo($hFileDownload, $INET_DOWNLOADERROR)
		ProgressSet(0, "Downloading '" & $sVisibleName & "' failed." & @CRLF & "Error code: " & $errorCode)
		If $bProgressOff Then
			Sleep($iEndMsgTime)
			ProgressOff()
		EndIf
		SetError(1, $errorCode, False)
	EndIf
EndFunc   ;==>_webDownloader

Func _request($url)
	If StringLen($url) == 0 Then Return False

	Local $oHTTP = ObjCreate('WinHttp.WinHttpRequest.5.1')
	$oHTTP.Option(6) = False
	$oHTTP.Open('get', $url, False)
	$oHTTP.SetRequestHeader('User-Agent', 'AutoIt Updater')
	$oHTTP.SetRequestHeader('Content-Type', 'application/vnd.api+json')
	$oHTTP.Send()
	$oHTTP.WaitForResponse
	Return $oHTTP.Responsetext
EndFunc   ;==>_request

Func _MsgBox($flag, $title, $message, $parentGUI = 0)
	If $parentGUI == 0 Then
		MsgBox($flag, $title, $message)
	Else
		MsgBox($flag, $title, $message, 0, $parentGUI)
	EndIf
EndFunc

Func _update($serverURL, $currentVersion, $beta = False, $parentGUI = 0, $message = 'You are using the latest version!')
	Local $response = _request($serverURL)
	Local $channel = ($beta) ? 'beta' : 'stable'
	Local $unknowError = 'Something wrong happened.'

	Local $json = Json_Decode($response)
	Local $latestVersion = Json_Get($json, '["data"]["' & $channel & '"]["version"]')
	If @error Then
		_MsgBox(16 + 262144, 'Error', $unknowError, $parentGUI)
		Return False
	EndIf

	Local $compare = _VersionCompare($currentVersion, $latestVersion)
	If @error Then
		_MsgBox(16 + 262144, 'Error', $unknowError, $parentGUI)
		Return False
	EndIf

	; New version available
	If $compare == -1 Then
		Local $changelog = Json_Get($json, '["data"]["' & $channel & '"]["changelog"]')

		; Show Changelog GUI
		Opt('GUIOnEventMode', 0)

		#Region ### START Koda GUI section ### Form=E:\Program Files\AutoIt3\SciTE\Koda\Templates\Form1.kxf
		Local $formUpdate = GUICreate('New version is available', 457, 270, -1, -1, -1, -1, $parentGUI)
		GUISetFont(12, 400, 0, 'Arial')
		Local $Edit = GUICtrlCreateEdit('', 8, 8, 441, 217, BitOR($ES_AUTOVSCROLL, $ES_READONLY, $ES_WANTRETURN, $WS_HSCROLL, $WS_VSCROLL))
		GUICtrlSetData(-1, $changelog)
		GUIStartGroup()
		Local $btnUpdate = GUICtrlCreateButton('Update now', 102, 235, 107, 25)
		GUICtrlSetFont(-1, 12, 400, 0, 'Arial')
		Local $btnCancel = GUICtrlCreateButton('Cancel', 246, 235, 107, 25)
		GUICtrlSetFont(-1, 12, 400, 0, 'Arial')
		GUIStartGroup()
		GUISetState(@SW_SHOW)
		#EndRegion ### END Koda GUI section ###

		Local $iMsg = 0
		While 1
			$iMsg = GUIGetMsg()
			Switch $iMsg
				Case $btnUpdate
					GUISetState(@SW_HIDE, $formUpdate)
					Local $base_url = Json_Get($json, '["data"]["base_url"]')
					Local $fileName = Json_Get($json, '["data"]["' & $channel & '"]["name"]')
					Local $filePath = _webDownloader($base_url & $fileName, $fileName, $fileName)
					If @error Then
						If _MsgBox(32 + 4 + 262144, 'Error', 'Download failed. Do you want to open download url in the browser?', $parentGUI) == 6 Then
							ShellExecute($base_url & $fileName)
						EndIf
					Else
						; Run setup file
						ShellExecute($filePath)
					EndIf
					ExitLoop

				Case $btnCancel
					ExitLoop

				Case $GUI_EVENT_CLOSE
					ExitLoop
			EndSwitch
		WEnd

		GUIDelete($formUpdate)
	Else
		_MsgBox(64 + 262144, 'Updater', $message, $parentGUI)
		Return False
	EndIf
EndFunc   ;==>_update

;~ _update('http://localhost/', '1.0.0')
