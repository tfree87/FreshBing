;

;--------------------------------
; Include Modern UI

  !include "MUI2.nsh"
  !include "LogicLib.nsh"

;--------------------------------
; General

  ; Name and file
  !define PUBLISHER "Nikhil Dabas"
  !define PRODUCT_NAME "FreshBing"
  !define PRODUCT_LINK "http://www.nikhildabas.com/"
  !define PRODUCT_FILE "${PRODUCT_NAME}.ps1"
  !define PRODUCT_ICON "Personalization.ico"
  !define PRODUCT_SHORTCUT "${PRODUCT_NAME} - Update Wallpaper.lnk"
  !define PRODUCT_EXEC "powershell.exe"
  !define PRODUCT_ARGS "-NoProfile -WindowStyle Hidden -ExecutionPolicy unrestricted -File $\"$INSTDIR\${PRODUCT_FILE}$\""
  !searchreplace PRODUCT_ARGS_ESC "${PRODUCT_ARGS}" "$\"" "\$\""
  Name "${PRODUCT_NAME}"
  OutFile "${PRODUCT_NAME}Setup.exe"
  
  ; Default installation folder
  InstallDir "$LOCALAPPDATA\${PRODUCT_NAME}"
  
  ; No need for admin privileges
  RequestExecutionLevel user

;--------------------------------
; Interface Settings

  !define MUI_ICON "Icons\Setup_Install.ico"
  !define MUI_UNICON "Icons\Setup_Install.ico"
  
  !define MUI_ABORTWARNING
  
  !define /file MUI_WELCOMEPAGE_TEXT "FreshBingSetup-Welcome.txt"
  
  !define MUI_FINISHPAGE_RUN "${PRODUCT_EXEC}"
  !define MUI_FINISHPAGE_RUN_PARAMETERS "${PRODUCT_ARGS}"

;--------------------------------
; Pages

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH
  
;--------------------------------
; Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections

Section ""

  ReadRegDWORD $R0 HKLM "SOFTWARE\Microsoft\PowerShell\1" "Install"
  ${If} $R0 != 1
    Abort "Please install Windows PowerShell first."
  ${EndIf}
  
  SetOutPath "$INSTDIR"
  
  File "${PRODUCT_FILE}"
  File "Icons\${PRODUCT_ICON}"
  
  CreateShortCut "$SMPROGRAMS\${PRODUCT_SHORTCUT}" "${PRODUCT_EXEC}" "${PRODUCT_ARGS}" "$INSTDIR\${PRODUCT_ICON}" "" SW_SHOWMINIMIZED
  
  ; Scheduled task
  ; Delete it first and then re-add it, because XP does not like the /f switch with /create
  nsExec::ExecToLog 'schtasks /delete /tn "${PRODUCT_NAME}" /f'
  Pop $R0
  nsExec::ExecToLog 'schtasks /create /tn "${PRODUCT_NAME}" /tr "${PRODUCT_EXEC} ${PRODUCT_ARGS_ESC}" /sc DAILY'
  Pop $R0
  
  ; Run on startup
  CreateShortCut "$SMSTARTUP\${PRODUCT_SHORTCUT}" "${PRODUCT_EXEC}" "${PRODUCT_ARGS} -startup" "$INSTDIR\${PRODUCT_ICON}" "" SW_SHOWMINIMIZED
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  WriteRegExpandStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegExpandStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayIcon" "$INSTDIR\${PRODUCT_ICON}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "Publisher" "${PUBLISHER}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "HelpLink" "${PRODUCT_LINK}"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "NoModify" "1"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "NoRepair" "1"

SectionEnd

;--------------------------------
; Uninstaller Section

Section "Uninstall"

  Delete "$INSTDIR\${PRODUCT_FILE}"
  Delete "$INSTDIR\${PRODUCT_ICON}"
  
  Delete "$SMPROGRAMS\${PRODUCT_SHORTCUT}"
  Delete "$SMSTARTUP\${PRODUCT_SHORTCUT}"
  
  nsExec::ExecToLog 'schtasks /delete /tn "${PRODUCT_NAME}" /f'
  Pop $R0

  Delete "$INSTDIR\Uninstall.exe"
  
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"

  RMDir "$INSTDIR"

SectionEnd