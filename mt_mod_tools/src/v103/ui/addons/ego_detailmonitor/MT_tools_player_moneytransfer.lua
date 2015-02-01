local utf8 = require("utf8")
local menu = {
	name = "PlayerMoneyTransferMenu"
}

local function init()
	Menus = Menus or {}

	table.insert(Menus, menu)

	if Helper then
		Helper.registerMenu(menu)
	end
	menu.searchtext = ""
	menu.displaytext = ""
	playerMoney = 0
	transferamount = 0
	buttonOKActive = false
	return 
end

menu.cleanup = function ()
	menu.infotable = nil
	menu.selecttable = nil
	
	menu.searchtext = nil
	menu.displaytext = nil
	buttonOKActive = nil
	playerMoney = nil
	transferamount = nil
	return 
end

local function buttonOK()
	Helper.closeMenuForSection(menu, false, "gMT_tools_AddPlayerMoney_amount", transferamount)
	menu.cleanup()
	return 
end

local function buttonCancel()
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
	return 
end

local function textToNumber( inputtext )
	-- returns a numeric value based on the inputtext string or nil if the string is not a valid number
	local string_length = 0
	local mult = 1
	local numVal = 0
	local numString = inputtext
		
	-- convert string to lower case to reduce suffix tests
	numString = string.lower( numString )
	-- get the length of the entered string
	string_length = string.len( numString )
	-- let's first check if the input was a valid number
	if (tonumber(numString) ~= nil) then
		-- yes so let's convert it to an integer
		numVal = tonumber( numString )
		numVal = numVal - numVal%1
	elseif string_length == 1 then
		-- number invalid and only 1 char so exit
		numVal = nil
	elseif string_length > 1 then
		-- entered string not valid but longer than 1 so let's check if the last digit is a modifier m,M,k, or K
		-- check the last character of the entered string to get modifier
		local last_char = string.sub( numString, -1)
		if last_char == "m" then 
			mult = 1000000					-- modifier is one million
		elseif last_char == "k" then
			mult = 1000						-- modifier is one thousand
		elseif (tonumber(last_char) == nil) then
			mult = nil
			numVal = nil
--		else
--			mult = nil
--			numVal = nil
		end
		-- get the rest of the number and check if valid
		numVal = tonumber( string.sub( numString, 1, string_length - 1) )
		if numVal ~= nil then
			if mult ~= nil then
				numVal = numVal * mult
				numVal = numVal- numVal%1
			end
		else
			numVal = nil
		end
	else								-- unhandled - shouldn't get here
		mult = nil						-- modifier is invalid - entry invalid
		numVal = nil
	end	

	return numVal
end

local function editboxUpdateText(_, text, textchanged)
	if textchanged then
		-- get the entered text
		menu.searchtext = text
		-- convert the text input to a number
		local numVal = textToNumber( text )
		-- display appropriate message
		if numVal == nil then
			-- display an error message and don't do any calcs or enable the OK button
			menu.displaytext = "Invalid entry - the text box must contain digits 0-9 and 'm', 'M', 'k' or 'K' - e.g. 12345 200k or 30M"
			menu.searchtext = ""
			buttonOKActive = false
		else																																										
			menu.displaytext = "Valid transaction: click OK to complete or Cancel to discard"
			transferamount = numVal
			menu.searchtext = tostring(numVal)
			buttonOKActive = true
		end
		-- redisplay the menu with new values
		menu.displayMenu()
	end

	return 
end

menu.onShowMenu = function ()
	playerMoney = GetPlayerMoney()
	buttonOKActive = false
	menu.searchtext = ""
	menu.displaytext = ""
	menu.displayMenu()
	return

end

menu.displayMenu = function()
	Helper.removeAllButtonScripts(menu)

	local setup = Helper.createTableSetup(menu)
	
	-- Title of dialog
	setup.addTitleRow(setup, {
		Helper.createFontString("Transfer money to/from player", false, "left", 255, 255, 255, 100, Helper.headerRow1Font, 18, false, Helper.standardTextOffsetx, Helper.standardTextOffsety, 32)
	}, nil, { 4 })
	
	-- Add row for current player balance
	setup.addTitleRow(setup, {
		Helper.createFontString("Current Player Balance", false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
		Helper.createFontString(ConvertMoneyString(playerMoney, false, true, nil, true) .. " Cr", false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
	}, nil, {
		2,2
	})

	-- Our added row with text box
	setup.addTitleRow(setup, {
		Helper.createFontString("Amount to transfer", false, "right", 255, 255, 255, 100, Helper.headerRow1Font, 18, false, Helper.standardTextOffsetx, Helper.standardTextOffsety, 32),
		Helper.createEditBox(Helper.createButtonText(menu.searchtext, "right", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), false, 0, 0, 200, 30, nil, nil, true)
	},nil, {2,2})

	-- custom info row showing status message
	setup.addTitleRow(setup, {
		Helper.createFontString(menu.displaytext, false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
	}, nil, {
		4
	})
	
	-- finally create our table descriptor for the info section
	local infodesc = setup.createCustomWidthTable(setup, {
		Helper.scaleX(Helper.headerCharacterIconSize),
		540,
		0,
		Helper.scaleX(Helper.headerCharacterIconSize) + 60
	}, false, true )

	-- now do some buttons
	setup = Helper.createTableSetup(menu)
	setup.addSimpleRow(setup, {
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 14), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, buttonOKActive, 0, 0, 200, Helper.standardTextHeight),
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 64), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 200, Helper.standardTextHeight),
		Helper.getEmptyCellDescriptor()
	})

	-- Create the button table
	local selectdesc = setup.createCustomWidthTable(setup, {
		200,
		200,
		0,
		200,
		200
	}, false, false, false, 2, 1, 0, 290)
	
	menu.infotable, menu.selecttable = Helper.displayTwoTableView(menu, infodesc, selectdesc, true)

	Helper.setEditBoxScript(menu, nil, menu.infotable, 3, 3, editboxUpdateText)
	if buttonOKActive then
		Helper.setButtonScript(menu, nil, menu.selecttable, 1, 2, buttonOK)
	end
	Helper.setButtonScript(menu, nil, menu.selecttable, 1, 4, buttonCancel)
	Helper.releaseDescriptors()

	return 
end
menu.onUpdate = function ()
	return 
end
menu.onRowChanged = function (row, rowdata)
	return 
end
menu.onSelectElement = function ()
	Helper.closeMenuForSection(menu, false, "gMT_tools_AddPlayerMoney_amount", transferamount)
	menu.cleanup()

	return 
end
menu.onCloseElement = function (dueToClose)
	if dueToClose == "close" then
		Helper.closeMenuAndCancel(menu)
		menu.cleanup()
	else
		Helper.closeMenuAndReturn(menu)
		menu.cleanup()
	end

	return 
end

init()

return 
