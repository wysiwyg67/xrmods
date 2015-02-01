@ECHO OFF
REM Publish X-Rebirth: MT Logistics mod
REM Version 1.0
REM 2015/01/29

REM if no parameter then update else first time publish 
IF "%1" EQU "update" GOTO Update_mod
IF "%1" EQU "publish" GOTO Publish_mod
IF "%1" EQU "minor" GOTO Update_minor
GOTO Error_args

:Publish_mod
ECHO "Publishing Mod......"
REM Set the changenote text
set change_note="%~3"
set version=%2
IF "%~3" EQU "" GOTO Error_args
ECHO %change_note%
WorkshopTool publish -path "..\release\%version%\mt_XRCLS"  -preview "..\pics\mt_XRCLS_prv.jpg"
GOTO End_of_prog

:Update_mod
REM Set the changenote text
set change_note="%~3"
set version=%2
IF "%~3" EQU "" GOTO Error_args
ECHO %change_note%
WorkshopTool update -path "..\release\%version%\mt_XRCLS" -changenote %change_note%
GOTO End_of_prog

:Update_minor
set change_note="%~3"
set version=%2
IF "%~3" EQU "" GOTO Error_args
ECHO %change_note%
WorkshopTool update -minor -path "..\release\%version%\mt_XRCLS" -changenote %change_note%
GOTO End_of_prog


:Error_args
ECHO "Incorrect command line arguments....."
:End_of_prog
ECHO "Done...."
