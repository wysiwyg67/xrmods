REM Build batch file for X-Rebirth - MT Mod Tools
REM Version 1.0
REM Date 2014-12-04
@ECHO OFF
set version=%1
rmdir ..\release\%version%\mt_XRCLS\
mkdir ..\release\%version%\mt_XRCLS\

REM update the .xpl files
FOR /R ..\src\%version%\mt_XRCLS\ %%F IN (*.xpl) DO (rename %%~F %%~nF.old)
REM make the new xpl file
FOR /R ..\src\%version%\mt_XRCLS\ %%F IN (*.lua) DO (luajit.exe -b %%F %%~pnF.xpl)
REM delete old files
FOR /R ..\src\%version%\mt_XRCLS\ %%F IN (*.old) DO (del %%~F)

REM Add current release to ext_01.cat
XRCatTool -in ..\src\%version%\mt_XRCLS -out ..\release\%version%\mt_XRCLS\ext_01.cat -exclude "^ego_forum_text" "lua$" "old$" -dump

REM Copy content.xml to release folder
copy ..\src\%version%\mt_XRCLS\content.xml ..\release\%version%\mt_XRCLS\content.xml

REM Copy readme.txt to release folder
copy ..\src\%version%\mt_XRCLS\readme.txt ..\release\%version%\mt_XRCLS\readme.txt
echo "Done...."
