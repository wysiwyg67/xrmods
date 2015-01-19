-- Warp a new ship into the game
-- Set up the default menu table
local menu = {	
	name = "gMT_menu_ship_AddShip",
	statusWidth = 150,
	statusHeight = 24,
	transparent = {
		g = 0,
		a = 0,
		b = 0,
		r = 0
	}
}

-- A table to hold a list of ship type macros
menu.ship_type_macros = {
	size_l = {
		[1] = "units_size_l_kit_container_01_macro",
		[2] = "units_size_l_kit_energy_01_macro",
		[3] = "units_size_l_kit_liquid_01_macro",
		[4] = "units_size_l_kit_bulk_01_macro"
		}
}	

-- Standard menu initialiser - initialise variables global to this menu here if needed
local function init()
	Menus = Menus or {}

	table.insert(Menus, menu)

	if Helper then
		Helper.registerMenu(menu)
	end

	menu.SelectedShipMacro = ""
	menu.SelectedFaction = ""
	menu.SelectedShipName = ""
	return
end

-- Standard Menu cleanup utility - place all variables no longer needed in here and assign the value nil to them
menu.cleanup = function ()
	menu.SelectedShipMacro = nil
	menu.SelectedFaction = nil
	menu.SelectedShipName = nil
	return
end

-- Callback function for back button
local function buttonBack()
	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
	return
end

-- Callback function for select button
local function buttonSelect()
	Helper.closeMenuForSection(menu, false,
			"gMT_ship_AddShip_selected", {
			menu.SelectedShipMacro,
			menu.SelectedShipName,
			menu.SelectedFaction
			})
	menu.cleanup()
	return
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	Helper.removeAllButtonScripts(menu)
	menu.SelectedShipMacro = menu.ship_type_macros.size_l[1]
	menu.SelectedShipName = "SCRIPTED IN!--" .. GetMacroData(menu.SelectedShipMacro, "name")
	menu.SelectedFaction = "player"


	-- assign our basic table info to a local variable
	local setup = Helper.createTableSetup(menu)
	-- set up the menu title row
	setup.addTitleRow(setup, {
		Helper.createFontString(
			"Build this ship", 									-- the main title text of our window
			false, 											-- don't scale the text
			"left", 										-- horizontal alignment
			255, 255, 255, 100,								-- The text colour R,G,B,Alpha 
			Helper.headerRow1Font, 							-- The predefined row 1 font
			Helper.headerRow1FontSize, 						-- The predefined row 1 font size (see detailmonitorhelper\helper.lua
			false, 											-- Don't wrap the text
			Helper.headerRow1Offsetx, 						-- Predefined x offset
			Helper.headerRow1Offsety, 						-- Predefined y offset
			Helper.headerRow1Height, 						-- Predefined row 1 height
			Helper.headerRow1Width)							-- Predefined row 1 width
	})
	-- set up the menu sub-title row
	setup.addTitleRow(setup, {
		Helper.createFontString(
			menu.SelectedShipName, 
			false, 
			"left", 
			255, 255, 255, 100, 
			Helper.headerRow2Font, 
			Helper.headerRow2FontSize, 
			false, 
			Helper.headerRow2Offsetx, 
			Helper.headerRow2Offsety, 
			Helper.headerRow2Height, 
			Helper.headerRow1Width)
	})

	-- set the information table for the window
	local infodesc = setup.createCustomWidthTable(setup, {
		[1] = 0
	}, false)


	setup = Helper.createTableSetup(menu)
	setup:addSimpleRow({
					[1] = " " })

	-- setup our table container for the ships list
	local selectdesc = setup.createCustomWidthTable(setup, {
		[1] = 0
	}, false, false, true, 1, 0, 0, Helper.tableOffsety, 485)
	
	-- add button section description
	setup = Helper.createTableSetup(menu)
	setup.addSimpleRow(setup, {
		[1] = Helper.getEmptyCellDescriptor(),
		[2] = Helper.createButton(Helper.createButtonText(
								"Back", 
								"center", 
								Helper.standardFont, 
								11, 255, 255, 255, 100), 
								nil, 
								false, 
								true, 
								0, 0, 150, 25, 
								nil, 
								Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_B", true)),
		[3] = Helper.getEmptyCellDescriptor(),
		[4] = Helper.createButton(Helper.createButtonText(
								"Select", 
								"center", 
								Helper.standardFont, 
								11, 255, 255, 255, 100), 
								nil, 
								true, 
								true, 
								0, 0, 150, 25, 
								nil, 
								Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_BACK", true)),
		Helper.getEmptyCellDescriptor()
	}, nil, nil, false, menu.transparent)

	local buttondesc = setup.createCustomWidthTable(setup, {
		[1] = 48,
		[2] = 150,
		[3] = 0,
		[4] = 150,
		[5] = 48,
	}, false, false, true, 2, 1, 0, 555, 0, false)

	-- build and display the view
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false)

	Helper.setButtonScript(menu, nil, menu.buttontable, 1, 2, buttonBack)
	Helper.setButtonScript(menu, nil, menu.buttontable, 1, 4, buttonSelect)
			
	Helper.releaseDescriptors()
	return
end

-- standard function stub to handle changing row
menu.onRowChanged = function (row, rowdata)
	return
end

-- standard function stub to handle dynamic update of menu
menu.onUpdate = function ()
	return
end

-- standard function stub to handle selection of an element in the menu
-- TODO: update a variable to reflect our target ships
menu.onSelectElement = function ()
	return
end

-- standard function to deal with clicking the '<' or 'x' buttons in the corner of the menu
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
