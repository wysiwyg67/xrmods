REM Build batch file for X-Rebirth - MT Enhanced Money Transfer Mod
REM Version 1.0
REM Date 2014-12-04

REM Add current release to ext_01.cat
XRCatTool -in ..\src -out ..\release\mt_enhanced_money_transfer\ext_01.cat -exclude "^ego_forum_text" "xpl$" "lua$" "^v251/" -dump
REM Add current release to subst_01.cat
XRCatTool -in ..\src -out ..\release\mt_enhanced_money_transfer\subst_01.cat -include "xpl$" -exclude "^v251/" -dump

REM Now add the v251 release diff ext_v251.cat file
XRCatTool -in ..\src\v251 -out ..\release\mt_enhanced_money_transfer\ext_v251.cat -diff ..\src -exclude "^v251/" "^ui/addons/ego_detailmonitor/" "^readme" "^ego_forum_text" "^content" "xpl$" "lua$" -dump

REM Now add the v2.51 release diff subst_v251.cat file
XRCatTool -in ..\src\v251 -out ..\release\mt_enhanced_money_transfer\subst_v251.cat -diff ..\src -include "xpl$" -exclude "^v251/" "^readme" "^ui/addons/ego_detailmonitor/" -dump

REM Copy content.xml to release folder
copy ..\src\content.xml ..\release\mt_enhanced_money_transfer\content.xml

REM Copy readme.txt to release folder
copy ..\src\readme.txt ..\release\mt_enhanced_money_transfer\readme.txt
echo "Done...."
