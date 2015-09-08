REM Build batch file for X-Rebirth - MT Enhanced Money Transfer Mod
REM Version 1.0
REM Date 2014-12-04
set version=%1

rmdir ..\release\%version%\mt_enhanced_money_transfer\
mkdir ..\release\%version%\mt_enhanced_money_transfer\

REM update the .xpl files
REM FOR /R ..\src\%version%\ %%F IN (*.xpl) DO (rename %%~F %%~nF.old)
REM make the new xpl file
REM FOR /R ..\src\%version%\ %%F IN (*.lua) DO (luajit.exe -b %%F %%~pnF.xpl)


REM Add current release to ext_01.cat
XRCatTool -in ..\src\%version% -out ..\release\%version%\mt_enhanced_money_transfer\ext_01.cat -exclude "^content" "^readme" "^ego_forum_text" "xpl$" "old$" "^v251/" "^v320/" -dump

REM Now add the v251 release diff ext_v251.cat file
XRCatTool -in ..\src\%version%\v251 -out ..\release\%version%\mt_enhanced_money_transfer\ext_v251.cat -diff ..\src\%version% -exclude "^v251/"  "^v320/" "^readme" "^ego_forum_text" "^content" "xpl$" "old$" -dump

REM Now add the v320 release diff ext_320.cat file
XRCatTool -in ..\src\%version%\v320 -out ..\release\%version%\mt_enhanced_money_transfer\ext_v320.cat -diff ..\src\%version% -exclude "^v320/" "^v251/"  "^readme" "^ego_forum_text" "^content" "xpl$" "old$" -dump

REM Copy content.xml to release folder
copy ..\src\%version%\content.xml ..\release\%version%\mt_enhanced_money_transfer\content.xml
REM copy ..\src\%version%\ui.xml ..\release\%version%\mt_enhanced_money_transfer\ui.xml
REM copy ..\src\%version%\mt_enhanced_moneytransfer.lua ..\release\%version%\mt_enhanced_money_transfer\mt_enhanced_moneytransfer.lua

REM Copy readme.txt to release folder
copy ..\src\%version%\readme.txt ..\release\%version%\mt_enhanced_money_transfer\readme.txt
echo "Done...."
