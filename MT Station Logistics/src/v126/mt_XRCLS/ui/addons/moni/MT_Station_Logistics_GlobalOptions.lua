-- Ship setup menu
 
-- Set up the default menu table
local menu = {	name = "gMT_Station_Logistics_GlobalOptions",
				statusWidth = 150,
				statusHeight = 24,
				transparent = {
				g = 0,
				a = 0,
				b = 0,
				r = 0			}
	}

local Buttons, Availability, Utility = {}, {}, {}
	
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
--	menu.updateInterval = nil
--	menu.title = nil
--	menu.subtitle = nil
--	menu.subtitle2 = nil
--	menu.subtitle3 = nil
--	menu.ret_arg = nil
--	menu.waypointType = nil
--	menu.revwaypointType = nil
--	menu.selectedWPType = nil
--	menu.selectedModifier = nil
--	menu.modifierType = nil
--	menu.infotable = nil
--	menu.selecttable = nil
--	menu.buttontable = nil
--	menu.waypoint = nil
--	menu.wp_station = nil
--	menu.ware = nil
--	menu.temp = nil
--	menu.trader = nil
--	menu.warelist = nil
--	menu.cargo = nil
--	menu.homebase = nil
--	menu.wprange = nil
	menu.buttons = nil
	menu.GlobalOptions = nil
	return
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.GlobalOptions = 				{} 
	menu.GlobalOptions.OptionsList = menu.param[6] or {0}
	
	menu.GlobalOptions.title = 			"MT Logistics Global Options Menu"
	menu.GlobalOptions.subtitle = 		""
	menu.GlobalOptions.subtitle3 = 		""
	
	menu.toprow = 					menu.param[1]
	menu.selrow = 					menu.param[2]

	-- Good to go!
	menu.display()
end

-- Main redraw function
menu.display = function ()	
	Helper.removeAllButtonScripts(menu)
	Helper.currentTableRow = {}
	Helper.currentTableRowData = nil
	menu.rowDataMap = {}

	-- Setup the header block
	local title_txt = menu.GlobalOptions.title
--	local subtitle2 = ReadText(150402,173) .. ": " .. GetComponentData(menu.GlobalOptions.trader[1], "name") .. " -- " .. ReadText(150402,174) .. ": " .. GetComponentData(menu.GlobalOptions.trader[2], "name")
	local subtitle2 = ""
	local infodesc, headerHeight = LibMT.create_standard_header( menu, title_txt, {subtitle2}, {  }, 1,  nil, { menu.GlobalOptions.subtitle3 })
	
	-- Setup the main body
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = {
		450,
		150,
		150,			-- NB Width set using height parameter to get square button
		0}

	--Header row
	local cells = {}
	local header_text = { "Setting " , "Value", "", ""}		-- 
	local rowData = "header"
	for _, text in pairs(header_text) do
		table.insert( cells, LibMT:Cell(text, nil, 1))
	end
	table.insert(row_collection, LibMT:Row(cells, rowData, menu.transparent, false, 0))
	
	-- Settings Rows
	-- Filter other mod ships from available ship list? (Y/N)
	local cells = {}
	rowData = "setting"
	table.insert( cells, LibMT:Cell("Filter other mod ships from available ship list?", nil, 1))
	if 0 < menu.GlobalOptions.OptionsList[1] then
		table.insert( cells, LibMT:Cell("YES", nil, 1))
	else
		table.insert( cells, LibMT:Cell("NO", nil, 1))	
	end
	table.insert( cells, LibMT:ButtonCell( "Toggle", Buttons.ToggleOtherMods, 1, true))
	table.insert( cells, LibMT:Cell("", nil, 1))
	table.insert(row_collection, LibMT:Row(cells, rowData, menu.transparent, false, 0))


	-- Build the table descriptor
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, false, false, headerHeight + 8, bodyHeight )
	
	-- Setup the button bar
	menu.buttons = {}
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton( ReadText(1001,2669), Buttons.Back, function () return true end,"INPUT_STATE_DETAILMONITOR_B"))
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())

	local buttondesc = LibMT.create_standard_button_bar( menu, menu.buttons, headerHeight, bodyHeight )
	
	-- build and display the view
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false)

	-- finally, we call all the script attaching functions
	for _, func in ipairs(cell_scripts) do
		func()
	end

	Helper.releaseDescriptors()

	return 
end

-- Timed update callback 
menu.onUpdate = function ()
end 

-- standard function stub to handle changing row
menu.onRowChanged = function (row, rowdata, rc_table)
	if rc_table == menu.defaulttable then
		LibMT:CheckButtonBarAvailability(menu, row, rowdata)
	end
	return
end

menu.onSelectElement = function ()
end

-- standard function to deal with clicking the '<' or 'x' buttons in the corner of the menu
menu.onCloseElement = function (dueToClose)
	if dueToClose == "close" then
		Helper.closeMenuAndCancel(menu)
		menu.cleanup()
	else
		Buttons.Back()
	end
	return
end

-- Callback function for back button
Buttons.Back = function()
--	menu.GlobalOptions.trader[15] = menu.GlobalOptions.ShipSettings
	Helper.closeMenuForSection(menu, false, "gMT_ConfigMenu_GlobalOptionsReturn", { 1, 3, {}, {"","","",""}, {}, menu.GlobalOptions.OptionsList, {} })
	menu.cleanup()
	return
end

-- Callback function for CV button
Buttons.ToggleOtherMods = function()
	if 0 < menu.GlobalOptions.OptionsList[1] then
		menu.GlobalOptions.OptionsList[1] = 0
	else
		menu.GlobalOptions.OptionsList[1] = 1
	end
	menu.display()
	return
end

init()

return
