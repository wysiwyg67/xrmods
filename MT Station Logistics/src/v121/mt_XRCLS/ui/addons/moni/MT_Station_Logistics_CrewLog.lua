--[[	Manages the crew training and log screen for the MT Station Logistics mod
		Version:		1.2.0
		Last Update:	2015-03-20
 --]]
 
-- Set up the default menu table
local menu = 	{	name = "gMT_Station_Logistics_CrewLog",
					statusWidth = 150,
					statusHeight = 24,
					transparent = 
					{
						g = 0,
						a = 0,
						b = 0,
						r = 0
					}
				}		

local Buttons, Availability = {}, {}

-- Standard menu initialiser - initialise variables global to this menu here if needed
local function init()
	Menus = Menus or {}
	table.insert(Menus, menu)
	if Helper then
		Helper.registerMenu(menu)
	end
	return
end

-- Standard Menu cleanup utility - place all variables no longer needed in here and assign the value nil to them
menu.cleanup = function ()
--	menu.infotable = nil
--	menu.selecttable = nil
--	menu.buttontable = nil
--	menu.defaulttable = nil
	menu.buttons = nil
	menu.crew = nil
	return
end

-- standard callback function that fires on first time display of menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.crew = {}
	menu.toprow = menu.param[1]						-- return toprow
	menu.selrow = menu.param[2]						-- return row
	menu.crew.ret_exp = menu.param[4]				-- return row and expand states
	menu.crew.crewdata = menu.param[3]				-- data for selected crew member
	menu.crew.entity = menu.crew.crewdata[2]		-- entity
	menu.crew.crewlog = GetNPCBlackboard(menu.crew.entity, "$XRCLS")
	
	menu.crew.title = ReadText(150402,301)			-- menu.title = "MT Station Logistics - Crew"
	menu.crew.subtitle = ReadText(150402,302) 		-- "Train your crew member"

	menu.selectedRow = { idx = menu.selrow, data = {} }

	menu.display( )
	
	return
end

-- main draw/redraw function
menu.display = function ()	
	Helper.removeAllButtonScripts(menu)
	Helper.currentTableRow = {}
	Helper.currentTableRowData = nil
	menu.rowDataMap = {}

	-- Setup for display
	local name, entity_type, typeicon, typename, ownericon, skills = GetComponentData(menu.crew.entity, "name", "typestring", "typeicon", "typename", "ownericon", "skills")
	local rank = ReadText(150402,44)   -- "No Rank"
	if entity_type == "commander" then
		rank = LibMT.Ranks[1][LibMT.get_entity_rank(menu.crew.crewlog[4])] -- menu.crew.crewlog[4]
	elseif entity_type == "defencecontrol" then
		rank = LibMT.Ranks[2][LibMT.get_entity_rank(menu.crew.crewlog[4])]
	elseif entity_type == "engineer" then
		rank = LibMT.Ranks[3][LibMT.get_entity_rank(menu.crew.crewlog[4])]
	else
		rank = ReadText(150402,44)   -- "No Rank"
	end

	title = {Helper.createIcon(typeicon, false, 255, 255, 255, 100, 0, 0, Helper.headerCharacterIconSize, Helper.headerCharacterIconSize),
	Helper.createFontString(rank .. " " .. name, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize),
	Helper.createIcon(ownericon, false, 255, 255, 255, 100, 0, 0, Helper.headerCharacterIconSize, Helper.headerCharacterIconSize) 
	}
	local colwidth = {
						Helper.scaleX(Helper.headerCharacterIconSize),
						0,
						Helper.scaleX(Helper.headerCharacterIconSize) + 37
					}
	local colspan = {1,1,1}
	local additional = {}
	local cells = {}
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(cells, LibMT:Cell(ReadText(150402,303) .. ":", nil, 1))  -- "Flying Time"
	table.insert(cells, LibMT:Cell(ConvertTimeString(  menu.crew.crewlog[2] ), nil, 1))   --  menu.crew.crewlog[2]
	table.insert(additional, LibMT:Row(cells, {"none"}, Helper.defaultHeaderBackgroundColor, false, 0))
	local cells = {}
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(cells, LibMT:Cell(ReadText(150402,304) .. ":", nil, 1))  -- "Salary Earned"
	local money = ConvertMoneyString( menu.crew.crewlog[3], false, true, nil, true) .. " Cr" -- menu.crew.crewlog[3]
	table.insert(cells, LibMT:Cell(money, nil, 1))
	table.insert(additional, LibMT:Row(cells, {"none"}, Helper.defaultHeaderBackgroundColor, false, 0))
	local cells = {}
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(cells, LibMT:Cell(ReadText(150402,305) .. ":", nil, 1))  -- "Experience points left to spend"
	table.insert(cells, LibMT:Cell(ConvertIntegerString(menu.crew.crewlog[5],true, 4, true), nil, 1))
	table.insert(additional, LibMT:Row(cells, {"none"}, Helper.defaultHeaderBackgroundColor, false, 0))
	local cells = {}
	table.insert(cells, LibMT:Cell("", nil, 1))
--	table.insert(cells, LibMT:Cell(ReadText(150402,305) .. ":", nil, 1))  -- "XP needed:"
	-- "1st star - 25K xp;   2nd star - 50K xp;   3rd star - 100K xp;   4th star - 200K xp;   5th star - 400K xp;"
	table.insert(cells, LibMT:Cell(ReadText(150402,306), nil, 2))
	table.insert(additional, LibMT:Row(cells, {"none"}, Helper.defaultHeaderBackgroundColor, false, 0))
	
	-- Create the menu header and get its height
	local infodesc, headerHeight = LibMT.create_column_header( menu, title, { typename }, additional, colwidth, colspan, true )

	-- setup the list view here	
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = {			
		Helper.standardButtonWidth,
		0,
		176,
		Helper.standardButtonWidth
	}

	-- Setup main table
	-- Header Row
	local cells = {}
	table.insert(cells, LibMT:Cell( ReadText(1001, 1918), nil, 2) )
	table.insert(cells, LibMT:Cell( "", nil, 2) )
	table.insert(row_collection, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, true, 0))

	-- Sort the skill table by relevance
	table.sort(skills, function (a, b)
		return b.relevance < a.relevance
	end)
	local playermoney = GetPlayerMoney()
	local skillpoints = menu.crew.crewlog[5]
	local skillbuy = { 25000, 50000, 100000, 200000, 400000, 0 }
		
	-- Skill table
	for _,skill in ipairs(skills) do
		local moneyneeded = skillbuy[skill.value + 1] * 100
		local skillpointsneeded = skillbuy[skill.value + 1]
		local cells = {}
		local bolded = false
		if 0 < skill.relevance then
			bolded = true
		end
		local skilltext = Helper.createFontString(ReadText(1013, skill.textid), false, "left", 255, 255, 255, 100, (bolded and Helper.standardFontBold) or Helper.standardFont)
		local skillstars = LibMT.createStarsText(skill.value)
		table.insert(cells, LibMT:Cell( skilltext, nil, 2) )
		table.insert(cells, LibMT:Cell( skillstars, nil, 2) )
		table.insert(row_collection, LibMT:Row(cells, {skill.value, skill.relevance, moneyneeded, skillpointsneeded, skillpoints, playermoney, skill.name}, Helper.defaultHeaderBackgroundColor, false, 0))
	end

	-- create the body descriptor
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, true, false, headerHeight + 14, bodyHeight - 45, menu.toprow, menu.selrow)

	-- setup the button section view
	menu.buttons = {}
	-- Setup the button bar
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton(ReadText(1001,2669), Buttons.Back, function () return true end,"INPUT_STATE_DETAILMONITOR_B"))
	if LibMT.DEBUG then
		table.insert(menu.buttons, LibMT:BarButton("(DBG) Give XP", Buttons.Test, function () return true end, "INPUT_STATE_DETAILMONITOR_BACK" ))
	else
		table.insert(menu.buttons, LibMT:BarButton())
	end
	table.insert(menu.buttons, LibMT:BarButton(ReadText(1001,1114), Buttons.Rename, function () return true end, "INPUT_STATE_DETAILMONITOR_Y"))
	table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,45), Buttons.Select, Availability.Select, "INPUT_STATE_DETAILMONITOR_X" )) -- Train
	-- create the button bar
	local buttondesc = LibMT.create_standard_button_bar( menu, menu.buttons, headerHeight, bodyHeight )

	-- build and display the view
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false, "", "", 0, 0, 0,0, "both", false, false)

	-- finally, we call all the script attaching functions
	for _, func in ipairs(cell_scripts) do
		func()
	end

	Helper.releaseDescriptors()
	
	return 
end

-- standard callback function that fires on a row change
menu.onRowChanged = function (row, rowdata, rc_table)
	if rc_table == menu.defaulttable then
		menu.selectedRow.idx = row
		menu.selectedRow.data = rowdata
		menu.crew.training_data = rowdata
		LibMT:CheckButtonBarAvailability(menu, row, rowdata)
	end
	return
end

-- standard callback function that fires when an element is selected
menu.onSelectElement = function ()
	return 
end

-- standard callback function to deal with clicking the '<' or 'x' buttons in the corner of the menu
menu.onCloseElement = function (dueToClose)
	Buttons:Back()
	return
end

-- Callback function for back button
Buttons.Back = function()
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_returncrew", { menu.crew.ret_exp[1], menu.crew.ret_exp[2], {}, menu.crew.ret_exp, {}, {} } )
	menu.cleanup()
	return
end

-- Callback function for train button
Buttons.Select = function()
	local toprow = GetTopRow(menu.defaulttable)
	local selrow = Helper.currentDefaultTableRow
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_train", {  toprow, selrow, 
																		menu.crew.crewdata, menu.crew.ret_exp, menu.crew.training_data })
	menu.cleanup()
	return
end

-- Callback function for rename button
Buttons.Rename = function()
	local toprow = GetTopRow(menu.defaulttable)
	local selrow = Helper.currentDefaultTableRow
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_rename", {  toprow, selrow, 
																		menu.crew.crewdata, menu.crew.ret_exp, menu.crew.training_data })
	menu.cleanup()
	return
end

-- Callback function - Test to give XP to crew for testing
Buttons.Test = function()
	local toprow = GetTopRow(menu.defaulttable)
	local selrow = Helper.currentDefaultTableRow
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_testxp", {  toprow, selrow, 
																		menu.crew.crewdata, menu.crew.ret_exp, menu.crew.training_data })
	menu.cleanup()
	return
end

-- Availability provider for the train button
Availability.Select = function(menu, rowIdx, rowData )
	return 0 < rowData[2] and rowData[1] < 5  and rowData[4] < rowData[5] and rowData[3] < rowData[6]
end

-- {skill.value, skill.relevance, moneyneeded, skillpointsneeded, skillpoints, playermoney, skill.name }



init()

return
