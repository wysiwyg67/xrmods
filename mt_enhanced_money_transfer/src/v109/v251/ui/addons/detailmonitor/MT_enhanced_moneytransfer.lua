local utf8 = require("utf8")
local menu = {
	name = "MoneyTransferMenu"
}

local function init()
	Menus = Menus or {}

	table.insert(Menus, menu)

	if Helper then
		Helper.registerMenu(menu)
	end
	menu.searchtext = ""
	menu.displaytext = ""
	menu.displaytext2 = ""
	menu.displaytext3 = ""
	menu.displayTransferMoney = ""
	menu.displayPlayerMoney = ""
	
	buttonOKActive = false
	managerMoney, playerMoney, newPlayermoney, newManagermoney, transferamount, managerWantedMoney = 0, 0, 0, 0, 0, 0
	moneytoplayer = false

	return 
end

menu.cleanup = function ()
	menu.title = nil
	menu.entity = nil
	menu.infotable = nil
	menu.selecttable = nil
	
	menu.searchtext = nil
	menu.displaytext = nil
	menu.displaytext2 = nil
	menu.displaytext3 = nil
	menu.displayTransferMoney = nil
	menu.displayPlayerMoney = nil
	buttonOKActive = nil
	moneytoplayer = nil
	managerMoney = nil
	playerMoney = nil
	newManagermoney = nil
	newPlayermoney = nil
	transferamount = nil
	managerWantedMoney = nil
	return 
end

local function buttonOK()

	if moneytoplayer then
		TransferMoneyToPlayer(transferamount, menu.entity)
	else
		TransferPlayerMoneyTo(transferamount, menu.entity)
	end

	local money = GetAccountData(menu.entity, "money")

	SetMinBudget(menu.entity, money/10)
	SetMaxBudget(menu.entity, money)


	Helper.closeMenuAndReturn(menu)
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
	local string_length = nil
	local mult = nil
	local numVal = nil
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
		elseif (tonumber(last_char) ~= nil) then
			mult = 1
		else
			mult = nil
			numVal = nil
		end
		-- get the rest of the number and check if valid
		numVal = tonumber( string.sub( numString, 1, string_length - 1) )
		if numVal ~= nil then
			numVal = numVal * mult
			numVal = numVal- numVal%1
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
--			menu.displaytext = "Invalid entry - the text box must contain digits 0-9 and 'm', 'M', 'k' or 'K' - e.g. 12345 200k or 30M"
			menu.displaytext = ReadText( 150400, 1 )
			menu.displaytext2 = ""				
			menu.displaytext3 = ""				
			menu.displayTransferMoney = ""
			menu.displayPlayerMoney = ""
			menu.searchtext = ""
			buttonOKActive = false
			menu.activateEditBox = true
		else																																										
			-- we have a valid numerical entry so lets check if it makes sense wrt the player and entity accounts
--			menu.displaytext = "valid entry   numString= " .. numString .. " - mult =  " .. sM .. " - numVal = " .. sNV  -- debug entry
			if numVal < 0 then
--				menu.displaytext = "Non-valid transaction: account must be set to zero or positive amount"
				menu.displaytext = ReadText( 150400, 2 )
				menu.displaytext2 = ""				
				menu.displaytext3 = ""				
				menu.displayTransferMoney = ""
				menu.displayPlayerMoney = ""
				menu.searchtext = ""
				menu.activateEditBox = true
				buttonOKActive = false
			elseif numVal > playerMoney + managerMoney then
--				menu.displaytext = "Non-valid transaction: not enough money in player and manager accounts to set this amount"
				menu.displaytext = ReadText( 150400, 3 )
				menu.displaytext2 = ""
				menu.displaytext3 = ""		
				menu.displayTransferMoney = ""
				menu.displayPlayerMoney = ""
				menu.searchtext = ""
				menu.activateEditBox = true
				buttonOKActive = false
			elseif managerMoney < numVal then
--				menu.displaytext = "Valid transaction: click OK to complete or Cancel to discard"
				menu.displaytext = ReadText( 150400, 4 )
				transferamount = numVal - managerMoney
				newPlayermoney = playerMoney - transferamount
--				menu.displaytext2 = "Transfer from player account: "
				menu.displaytext2 = ReadText( 150400, 5 )
--				menu.displaytext3 = "New player account balance: " 	
				menu.displaytext3 =  ReadText( 150400, 6 )	
				menu.displayTransferMoney = ConvertMoneyString(transferamount, false, true, nil, true) .. " Cr"
				menu.displayPlayerMoney = ConvertMoneyString(newPlayermoney, false, true, nil, true) .. " Cr"
				menu.searchtext = ConvertMoneyString(numVal, false, true, nil, true)
				buttonOKActive = true
				moneytoplayer = false
			else
--				menu.displaytext = "Valid transaction: click OK to complete or Cancel to discard"
				menu.displaytext = ReadText( 150400, 4 )
				transferamount = managerMoney - numVal
				newPlayermoney = playerMoney + transferamount
--				menu.displaytext2 = "Transfer to player account: "
				menu.displaytext2 = ReadText( 150400, 7 )
--				menu.displaytext3 = "New player account balance: "
				menu.displaytext3 =  ReadText( 150400, 6 )	
				menu.displayTransferMoney = ConvertMoneyString(transferamount, false, true, nil, true) .. " Cr"
				menu.displayPlayerMoney = ConvertMoneyString(newPlayermoney, false, true, nil, true) .. " Cr"
				menu.searchtext = ConvertMoneyString(numVal, false, true, nil, true)
				buttonOKActive = true
				moneytoplayer = true
			end
			
		end
		-- redisplay the menu with new values
		menu.displayMenu()
	end

	return 
end

menu.onShowMenu = function ()
	menu.title = ReadText(1001, 2000)
	menu.entity = menu.param[3]
	managerMoney = GetAccountData(menu.entity, "money")
	managerWantedMoney = GetComponentData(menu.entity, "wantedmoney")
	playerMoney = GetPlayerMoney()
	newPlayermoney, newManagermoney, transferamount = 0, 0, 0
	buttonOKActive = false
	menu.searchtext = ""
	menu.displaytext = ""
	menu.displaytext2 = ""
	menu.displaytext3 = ""
	menu.displayTransferMoney = ""
	menu.displayPlayerMoney = ""
	menu.activateEditBox = true
	menu.displayMenu()
	return
end

menu.displayMenu = function()
	Helper.removeAllButtonScripts(menu)

	local setup = Helper.createTableSetup(menu)
	local name, typestring, typeicon, typename, ownericon = GetComponentData(menu.entity, "name", "typestring", "typeicon", "typename", "ownericon")

	-- custom row with NPC icon, name etc
	setup.addTitleRow(setup, {
		Helper.createIcon(typeicon, false, 255, 255, 255, 100, 0, 0, Helper.headerCharacterIconSize, Helper.headerCharacterIconSize),
		Helper.createFontString(typename .. " " .. name, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize),
		Helper.getEmptyCellDescriptor(),
		Helper.createIcon(ownericon, false, 255, 255, 255, 100, 0, 0, Helper.headerCharacterIconSize, Helper.headerCharacterIconSize)
	})
	
	-- Add row for current player balance
	setup.addTitleRow(setup, {
		Helper.createFontString(ReadText( 150400, 8 ), false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
		Helper.createFontString(ConvertMoneyString(playerMoney, false, true, nil, true) .. " Cr", false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
	}, nil, {
		2,2
	})
	
	-- Add row for current NPC balance
	setup.addTitleRow(setup, {
		Helper.createFontString(ReadText( 150400, 9 ) .. typename .. ReadText( 150400, 10 ), false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
		Helper.createFontString(ConvertMoneyString(managerMoney, false, true, nil, true) .. " Cr", false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
	}, nil, {
		2,2
	})
	
	-- Add row for minimum required budget
	setup.addTitleRow(setup, {
		Helper.createFontString(ReadText(1001, 1919) .. ": ", false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
		Helper.createFontString(ConvertMoneyString(managerWantedMoney, false, true, nil, true) .. " Cr", false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
	}, nil, {
		2,2
	})

	-- Our added row with text box
	setup.addTitleRow(setup, {
		Helper.createFontString(ReadText( 150400, 11 ) .. typename .. ReadText( 150400, 12 ), false, "right", 255, 255, 255, 100, Helper.headerRow1Font, 18, false, Helper.standardTextOffsetx, Helper.standardTextOffsety, 32),
		Helper.createEditBox(Helper.createButtonText(menu.searchtext, "right", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), false, 0, 0, 200, 30, nil, nil, true)
	},nil, {2,2})

	-- custom info row showing status message
	setup.addTitleRow(setup, {
		Helper.createFontString(menu.displaytext, false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
	}, nil, {
		4
	})
	-- custom info row showing details of transaction - amount to transfer
	setup.addTitleRow(setup, {
		Helper.createFontString(menu.displaytext2, false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
		Helper.createFontString(menu.displayTransferMoney, false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
	}, nil, {
		2,2
	})
	-- custom info row showing details of transaction - new player account balance
	setup.addTitleRow(setup, {
		Helper.createFontString(menu.displaytext3, false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
		Helper.createFontString(menu.displayPlayerMoney, false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
	}, nil, {
		2,2
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
		Helper.createButton(Helper.createButtonText(ReadText(1001, 14), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, buttonOKActive, 0, 0, 200, Helper.standardTextHeight+1, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_A", true)),
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 64), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 200, Helper.standardTextHeight+1, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_ESC", true)),
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

	Helper.setEditBoxScript(menu, nil, menu.infotable, 5, 3, editboxUpdateText)
	if buttonOKActive then
		Helper.setButtonScript(menu, nil, menu.selecttable, 1, 2, buttonOK)
	end
	Helper.setButtonScript(menu, nil, menu.selecttable, 1, 4, buttonCancel)
	
--	menu.activateEditBox = true
	
	Helper.releaseDescriptors()

	return 
end
menu.updateInterval = 0.5
menu.onUpdate = function ()
	if menu.activateEditBox then
		menu.activateEditBox = nil
		Helper.activateEditBox(menu.infotable, 5, 3)
	end
	return 
end
menu.onRowChanged = function (row, rowdata)
	return 
end
menu.onSelectElement = function ()
	if moneytoplayer then
		TransferMoneyToPlayer(transferamount, menu.entity)
	else
		TransferPlayerMoneyTo(transferamount, menu.entity)
	end

	Helper.closeMenuAndReturn(menu)
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
