#include-once

#Region Includes
#include <InetConstants.au3>
#include <JSON.au3> ; by Ward
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Misc.au3>
#EndRegion Includes

; #INDEX# =======================================================================================================================
; Title .........: AutoIt Updater
; UDF Version....: 1.0.0
; AutoIt Version : 3.3.14.2
; Description ...: An updater for your AutoIt applications
; Author(s) .....: Juno_okyo
; ===============================================================================================================================

; #CONSTANTS# ===================================================================================================================
Global Const $UPDATER_VERSION = '1.0.0'
Global Const $UPDATER_USER_AGENT = 'AutoIt Updater v' & $UPDATER_VERSION
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Author ........: Juno_okyo
; ===============================================================================================================================
Func _update($serverURL, $currentVersion, $beta = False, $parentGUI = 0, $message = 'You are using the latest version!')
	Local $channel = ($beta) ? 'beta' : 'stable'
	Local $unknowError = 'Something wrong happened.'
	Local $response = __request($serverURL & 'version.php?channel=' & _urlEncode($channel))

	If @error Then
		__MsgBox(16, 'Error', 'Server URL is invalid.', $parentGUI)
		Return False
	EndIf

	Local $json = Json_Decode($response)
	Local $latestVersion = Json_Get($json, '["data"]["version"]')
	If @error Then
		__MsgBox(16, 'Error', $unknowError, $parentGUI)
		Return False
	EndIf

	Local $compare = _VersionCompare($currentVersion, $latestVersion)
	If @error Then
		__MsgBox(16, 'Error', $unknowError, $parentGUI)
		Return False
	EndIf

	; New version available
	If $compare == -1 Then
		Local $changelog = Json_Get($json, '["data"]["changelog"]')

		; Show Changelog GUI
		Opt('GUIOnEventMode', 0)
		Opt('GUICloseOnESC', 0)

		#Region ### START Koda GUI section ###
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
		GUISetState(@SW_SHOW, $formUpdate)
		#EndRegion ### END Koda GUI section ###

		Local $iMsg = 0
		While 1
			$iMsg = GUIGetMsg()
			Switch $iMsg
				Case $btnUpdate
					GUISetState(@SW_HIDE, $formUpdate)
					Local $fileName = Json_Get($json, '["data"]["name"]')
					Local $url = $serverURL & 'download.php?channel=' & _urlEncode($channel)
					$url &= '&version=' & _urlEncode($latestVersion)
					$url &= '&file=' & _urlEncode($fileName)

					Local $filePath = __downloader($url, $fileName, $fileName)
					If @error Then
						If __MsgBox(32 + 4, 'Error', 'Download failed. Do you want to open download url in the browser?', $parentGUI) == 6 Then
							ShellExecute($url)
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
		__MsgBox(64, 'Updater', $message, $parentGUI)
		Return False
	EndIf
EndFunc   ;==>_update

#Region <INTERNAL_USE_ONLY>
Func __downloader($sSourceURL, $sTargetName, $sVisibleName, $sTargetDir = @TempDir, $bProgressOff = True, $iEndMsgTime = 2000, $sDownloaderTitle = "Downloader")
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
EndFunc   ;==>__downloader

Func __request($url)
	If StringLen($url) == 0 Then Return SetError(1, 0, False)

	Local $oHTTP = ObjCreate('WinHttp.WinHttpRequest.5.1')
	$oHTTP.Option(6) = False
	$oHTTP.Open('get', $url, False)
	$oHTTP.SetRequestHeader('User-Agent', $UPDATER_USER_AGENT)
	$oHTTP.SetRequestHeader('Content-Type', 'application/vnd.api+json')
	$oHTTP.Send()
	$oHTTP.WaitForResponse
	Return $oHTTP.Responsetext
EndFunc   ;==>__request

Func _urlEncode($vData)
	If IsBool($vData) Then Return $vData
	Local $aData = StringToASCIIArray($vData, Default, Default, 2)
	Local $sOut = '', $total = UBound($aData) - 1
	For $i = 0 To $total
		Switch $aData[$i]
			Case 45, 46, 48 To 57, 65 To 90, 95, 97 To 122, 126
				$sOut &= Chr($aData[$i])
			Case 32
				$sOut &= '+'
			Case Else
				$sOut &= '%' & Hex($aData[$i], 2)
		EndSwitch
	Next
	Return $sOut
EndFunc   ;==>_urlEncode

Func __MsgBox($flag, $title, $text, $parentGUI = 0)
	; Top most
	$flag += 262144

	If $parentGUI == 0 Then
		MsgBox($flag, $title, $text)
	Else
		MsgBox($flag, $title, $text, 0, $parentGUI)
	EndIf
EndFunc   ;==>__MsgBox
#EndRegion <INTERNAL_USE_ONLY>
