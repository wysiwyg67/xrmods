-- temp fix for v3.50b1
local emt_menu = {}

local Funcs = {}

local function init()
	Menus = Menus or {}
	if Menus then
		for _, menu in ipairs(Menus) do
			if menu.name == "MoneyTransferMenu" then
				emt_menu = menu
				menu.onShowMenu = Funcs.EMT_onShowMenu
				menu.onUpdate = Funcs.EMT_onUpdate
				menu.onSelectElement = Funcs.EMT_onSelectElement
				menu.onCloseElement = Funcs.EMT_onCloseElement
				menu.cleanup = Funcs.EMT_cleanup
			end
		end
	end
end

Funcs.EMT_cleanup = function()
	emt_menu.title = nil
	emt_menu.entity = nil
	emt_menu.infotable = nil
	emt_menu.selecttable = nil
	
	emt_menu.searchtext = nil
	emt_menu.displaytext = nil
	emt_menu.displaytext2 = nil
	emt_menu.displaytext3 = nil
	emt_menu.displayTransferMoney = nil
	emt_menu.displayPlayerMoney = nil
	buttonOKActive = nil
	moneytoplayer = nil
	managerMoney = nil
	playerMoney = nil
	newManagermoney = nil
	newPlayermoney = nil
	transferamount = nil
	managerWantedMoney = nil
--	return 
end

local function buttonOK()

	if moneytoplayer then
		TransferMoneyToPlayer(transferamount, emt_menu.entity)
	else
		TransferPlayerMoneyTo(transferamount, emt_menu.entity)
	end

	local money = GetAccountData(emt_menu.entity, "money")

	SetMinBudget(emt_menu.entity, money/10)
	SetMaxBudget(emt_menu.entity, money)


	Helper.closeMenuAndReturn(emt_menu)
	Funcs:EMT_cleanup()

	return 
end

local function buttonCancel()
	Helper.closeMenuAndReturn(emt_menu)
	Funcs:EMT_cleanup()
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
	-- get the entered text
	emt_menu.searchtext = text
	-- convert the text input to a number
	local numVal = 0
	if textchanged then
		numVal = textToNumber( text )
	else
		-- The player can hit enter on an empty text box and the transfer amount will be the manager min required budget
		numVal = managerWantedMoney
	end
	-- display appropriate message
	if numVal == nil then
		-- display an error message and don't do any calcs or enable the OK button
--		menu.displaytext = "Invalid entry - the text box must contain digits 0-9 and 'm', 'M', 'k' or 'K' - e.g. 12345 200k or 30M"
		emt_menu.displaytext = ReadText( 150400, 1 )
		emt_menu.displaytext2 = ""				
		emt_menu.displaytext3 = ""				
		emt_menu.displayTransferMoney = ""
		emt_menu.displayPlayerMoney = ""
		emt_menu.searchtext = ""
		buttonOKActive = false
		emt_menu.activateEditBox = true
	else																																		
		-- we have a valid numerical entry so lets check if it makes sense wrt the player and entity accounts
		if numVal < 0 then
--			menu.displaytext = "Non-valid transaction: account must be set to zero or positive amount"
			emt_menu.displaytext = ReadText( 150400, 2 )
			emt_menu.displaytext2 = ""				
			emt_menu.displaytext3 = ""				
			emt_menu.displayTransferMoney = ""
			emt_menu.displayPlayerMoney = ""
			emt_menu.searchtext = ""
			emt_menu.activateEditBox = true
			buttonOKActive = false
		elseif numVal > playerMoney + managerMoney then
--			menu.displaytext = "Non-valid transaction: not enough money in player and manager accounts to set this amount"
			emt_menu.displaytext = ReadText( 150400, 3 )
			emt_menu.displaytext2 = ""
			emt_menu.displaytext3 = ""		
			emt_menu.displayTransferMoney = ""
			emt_menu.displayPlayerMoney = ""
			emt_menu.searchtext = ""
			emt_menu.activateEditBox = true
			buttonOKActive = false
		elseif managerMoney < numVal then
--			menu.displaytext = "Valid transaction: click OK to complete or Cancel to discard"
			emt_menu.displaytext = ReadText( 150400, 4 )
			transferamount = numVal - managerMoney
			newPlayermoney = playerMoney - transferamount
--			menu.displaytext2 = "Transfer from player account: "
			emt_menu.displaytext2 = ReadText( 150400, 5 )
--			menu.displaytext3 = "New player account balance: " 	
			emt_menu.displaytext3 =  ReadText( 150400, 6 )	
			emt_menu.displayTransferMoney = ConvertMoneyString(transferamount, false, true, nil, true) .. " Cr"
			emt_menu.displayPlayerMoney = ConvertMoneyString(newPlayermoney, false, true, nil, true) .. " Cr"
			emt_menu.searchtext = ConvertMoneyString(numVal, false, true, nil, true)
			buttonOKActive = true
			moneytoplayer = false
		else
--			menu.displaytext = "Valid transaction: click OK to complete or Cancel to discard"
			emt_menu.displaytext = ReadText( 150400, 4 )
			transferamount = managerMoney - numVal
			newPlayermoney = playerMoney + transferamount
--			menu.displaytext2 = "Transfer to player account: "
			emt_menu.displaytext2 = ReadText( 150400, 7 )
--			menu.displaytext3 = "New player account balance: "
			emt_menu.displaytext3 =  ReadText( 150400, 6 )	
			emt_menu.displayTransferMoney = ConvertMoneyString(transferamount, false, true, nil, true) .. " Cr"
			emt_menu.displayPlayerMoney = ConvertMoneyString(newPlayermoney, false, true, nil, true) .. " Cr"
			emt_menu.searchtext = ConvertMoneyString(numVal, false, true, nil, true)
			buttonOKActive = true
			moneytoplayer = true
		end
		-- redisplay the menu with new values
		Funcs:displayMenu()
	end

-- return 
end

Funcs.displayMenu = function()
	Helper.removeAllButtonScripts(emt_menu)

	local setup = Helper.createTableSetup(emt_menu)
	local name, typestring, typeicon, typename, ownericon = GetComponentData(emt_menu.entity, "name", "typestring", "typeicon", "typename", "ownericon")

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
		Helper.createEditBox(Helper.createButtonText(emt_menu.searchtext, "right", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), false, 0, 0, 200, 30, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_0", false), true)
	},nil, {2,2})

	-- custom info row showing status message
	setup.addTitleRow(setup, {
		Helper.createFontString(emt_menu.displaytext, false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
	}, nil, {
		4
	})
	-- custom info row showing details of transaction - amount to transfer
	setup.addTitleRow(setup, {
		Helper.createFontString(emt_menu.displaytext2, false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
		Helper.createFontString(emt_menu.displayTransferMoney, false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
	}, nil, {
		2,2
	})
	-- custom info row showing details of transaction - new player account balance
	setup.addTitleRow(setup, {
		Helper.createFontString(emt_menu.displaytext3, false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
		Helper.createFontString(emt_menu.displayPlayerMoney, false, "right", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize),
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
	setup = Helper.createTableSetup(emt_menu)
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
	
	emt_menu.infotable, emt_menu.selecttable = Helper.displayTwoTableView(emt_menu, infodesc, selectdesc, true)

	Helper.setEditBoxScript(emt_menu, nil, emt_menu.infotable, 5, 3, editboxUpdateText)
	if buttonOKActive then
		Helper.setButtonScript(emt_menu, nil, emt_menu.selecttable, 1, 2, buttonOK)
	end
	Helper.setButtonScript(emt_menu, nil, emt_menu.selecttable, 1, 4, buttonCancel)
	
	Helper.releaseDescriptors()

	return 
end

Funcs.EMT_onShowMenu = function()
	emt_menu.title = ReadText(1001, 2000)
	emt_menu.entity = emt_menu.param[3]
	managerMoney = GetAccountData(emt_menu.entity, "money")
	managerWantedMoney = GetComponentData(emt_menu.entity, "wantedmoney")
	playerMoney = GetPlayerMoney()
	newPlayermoney, newManagermoney, transferamount = 0, 0, 0
	buttonOKActive = false
	emt_menu.searchtext = ""
	emt_menu.displaytext = ""
	emt_menu.displaytext2 = ""
	emt_menu.displaytext3 = ""
	emt_menu.displayTransferMoney = ""
	emt_menu.displayPlayerMoney = ""
	emt_menu.activateEditBox = true
	Funcs:displayMenu()
	return
end

emt_menu.updateInterval = 0.5
Funcs.EMT_onUpdate = function()
	if emt_menu.activateEditBox then
		emt_menu.activateEditBox = nil
		Helper.activateEditBox(emt_menu.infotable, 5, 3)
	end
	return 
end

Funcs.EMT_onSelectElement = function()
	if moneytoplayer then
		TransferMoneyToPlayer(transferamount, emt_menu.entity)
	else
		TransferPlayerMoneyTo(transferamount, emt_menu.entity)
	end

	Helper.closeMenuAndReturn(emt_menu)
	Funcs:EMT_cleanup()

	return 
end

Funcs.EMT_onCloseElement= function(dueToClose)
	if dueToClose == "close" then
		Helper.closeMenuAndCancel(emt_menu)
		Funcs:EMT_cleanup()
	else
		Helper.closeMenuAndReturn(emt_menu)
		Funcs:EMT_cleanup()
	end

	return 
end


init()
