Enhanced Money Transfer 

== Introduction == 

MitchTech Corporation is proud to release its first update for the Pride of Albion user interface software. This small mod will improve productivity for pilots managing many stations and large accounts. The patch replaces the money transfer slider dialog with a dialog that allows the user to type in the exact amount of credits to be set in the manager's or architect's account. 

== Installing == 

Simply subscribe to the mod on the Steam Workshop for x-rebirth and the mod will download and install automagically next time you start the game. 

Steam Workshop Link 

You can find the source files for the mod on my github repository if you're interested in seeing what changes are being made under the hood. 

== Usage == 

The next time you want to transfer some money to or from a station manager or architect you will be presented with an account transaction dialog box that has a single text input box where you can type the amount that you want to set the account to. Note this is the actual amount that the account will contain and NOT the amount to be transferred. Also note that you need to press 'Enter' after typing the number. (I can't seem to get the text box to work like it does on the trade screen!) 

Valid inputs: 
digits 0-9 e.g. 100, 1000000, 500000 
numbers in exponent format e.g. 1e6, 23.67e3 
numbers followed by a suffix e.g. 1m or 1M = 1000000, 1k or 1K = 1000 1.23467k = 1234 (note decimals less than 1 are truncated) 
Thousand separators are NOT allowed 
Multiple prefixes are NOT allowed eg 5kk will not work 

== Uninstalling == 

Simply unsubscribe from the mod on Steam and delete the mod folder 
The mod is savegame compatible 

== Change History == 
v1.12 - Update for X Rebirth v3.50 beta 1

v1.11 - Added french translation (Many thanks to Ronkhar - Ego Forum) Also fixed menu display bug introduced in XR 3.20 RC2

v1.10 - Small update to improve gameplay for controller users. Pressing keyboard <enter> key or controller A button whilst input box is empty sets the manager's account to the minimum required budget.(Thanks to Airstrike Ivanov for suggesting this)

v1.09 - Text input box is now active immediately (no need to click it to activate). Enter key now also mapped to OK button.

v1.08 - Fixed for XR v3.0 b6+ version - now works with both release v2.51 and 3.0 beta 

v1.07 - added russian localisation (thanks to alexalsp @ego-forum) and default lang file where no translation file is available (thanks to Klaus @Egosoft for this info) 

v1.06 - finally nailed the incorrect display bug (fingers crossed!!) - thanks to alexalsp for flagging this issue 

v1.05, v1.04 - Bugged releases - please update! 

v1.03 - minor update to include language files for other languages (no translations yet sorry! - offers welcome Wink ) 

v1.02 - small fix to correct display of final player balance (calculation was correct but display was wrong!) 

v1.01 - small change to allow cells to update properly when invalid amount entered. 

v1.0 - First Release 

== CREDITS == 

Thanks to Mad_Joker for the pioneering work on the Lua interface code 
Thanks to Night Nord for the excellent tool provided for converting Lua bytecode files to Lua source files 
Thanks to all the modders who've already contributed (current and past) for inspiring me to get my finger out and publish something

