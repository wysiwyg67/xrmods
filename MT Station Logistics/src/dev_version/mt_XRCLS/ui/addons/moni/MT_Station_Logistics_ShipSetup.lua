-- Ship setup menu
local Buttons, Availability, Utility = {}, {}, {}
 
-- Set up the default menu table
local menu = {	name = "gMT_Station_Logistics_ShipSetup",
				statusWidth = 150,
				statusHeight = 24,
				transparent = {
				g = 0,
				a = 0,
				b = 0,
				r = 0			}
	}

	
-- Standard menu initialiser - initialise variables global to this menu here if needed
local function init()
	Menus = Menus or {}

	table.insert(Menus, menu)

	if Helper then
		Helper.registerMenu(menu)
	end
end

-- Standard Menu cleanup utility - place all variables no longer needed in here and assign the value nil to them
menu.cleanup = function ()
	menu.toprow = nil
	menu.selrow = nil
	menu.updateInterval = nil
	menu.infotable = nil
	menu.selecttable = nil
	menu.buttontable = nil
	menu.buttons = nil
	menu.ShipSetup = nil
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.ShipSetup = 				{} 
	
	menu.ShipSetup.title = 			"Ship Setup Menu"
	menu.ShipSetup.subtitle = 		""
	menu.ShipSetup.subtitle3 = 		""

	
	menu.toprow = 					menu.param[1][1]
	menu.selrow = 					menu.param[1][2]

	menu.ShipSetup.trader = 		menu.param[7]
	menu.ShipSetup.ShipSettings = 	menu.ShipSetup.trader[15] or {0,0}
	if not menu.ShipSetup.ShipSettings[2] then table.insert(menu.ShipSetup.ShipSettings, 0) end

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
	local title_txt = menu.ShipSetup.title .. " - " .. menu.ShipSetup.subtitle
	local subtitle2 = ReadText(150402,173) .. ": " .. GetComponentData(menu.ShipSetup.trader[1], "name") .. " -- " .. ReadText(150402,174) .. ": " .. GetComponentData(menu.ShipSetup.trader[2], "name")
	local infodesc, headerHeight = LibMT.create_standard_header( menu, title_txt, {subtitle2}, {  }, 1,  nil, { menu.ShipSetup.subtitle3 })
	
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
	-- Supply the CV setting (Y/N)
	local cells = {}
	rowData = "setting"
	table.insert( cells, LibMT:Cell("Supply Construction Vessels in range?", nil, 1))
	if 0 < menu.ShipSetup.ShipSettings[1] then
		table.insert( cells, LibMT:Cell("YES", nil, 1))
	else
		table.insert( cells, LibMT:Cell("NO", nil, 1))	
	end
	table.insert( cells, LibMT:ButtonCell( "Toggle", Buttons.ToggleCV, 1, true))
	table.insert( cells, LibMT:Cell("", nil, 1))
	table.insert(row_collection, LibMT:Row(cells, rowData, menu.transparent, false, 0))

	-- Build the table descriptor
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, false, false, headerHeight + 8, bodyHeight, menu.toprow, menu.selrow )
	
	-- Setup the button bar
	menu.buttons = {}
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton( ReadText(1001,2669), Buttons.Back, function () return true end,"INPUT_STATE_DETAILMONITOR_B"))
	table.insert(menu.buttons, LibMT:BarButton( "Save Waypoints", Buttons.SaveWaypoints, Availability.SaveWaypoints,"INPUT_STATE_DETAILMONITOR_BACK" ))
	table.insert(menu.buttons, LibMT:BarButton( "Load Waypoints", Buttons.LoadWaypoints, Availability.LoadWaypoints,"INPUT_STATE_DETAILMONITOR_Y" ))
	table.insert(menu.buttons, LibMT:BarButton())

	local buttondesc = LibMT.create_standard_button_bar( menu, menu.buttons, headerHeight, bodyHeight )
	
	-- build and display the view
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false)

	-- finally, we call all the script attaching functions
	for _, func in ipairs(cell_scripts) do
		func()
	end

	Helper.releaseDescriptors()
end

-- standard function stub to handle changing row
menu.onRowChanged = function (row, rowdata, rc_table)
	if rc_table == menu.defaulttable then
		LibMT:CheckButtonBarAvailability(menu, row, rowdata)
	end
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
end

-- Callback function for back button
Buttons.Back = function()
	menu.ShipSetup.trader[15] = menu.ShipSetup.ShipSettings
	Helper.closeMenuForSection(menu, false, "gMT_Logistics_ShipMenu", { {}, {}, menu.name, "", {}, {}, menu.ShipSetup.trader, {}, {}, {} })
	menu.cleanup()
end

-- Callback function for save waypoints button
Buttons.SaveWaypoints = function()
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_LoadSaveWaypoints", { 0, 0, menu.ShipSetup.trader, "savewaypoints"})
	menu.cleanup()
end

-- Callback function for load waypoints button
Buttons.LoadWaypoints = function()
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_LoadSaveWaypoints", { 0, 0, menu.ShipSetup.trader, "loadwaypoints"})
	menu.cleanup()
end

-- Callback function for CV button
Buttons.ToggleCV = function()
	if 0 < menu.ShipSetup.ShipSettings[1] then
		menu.ShipSetup.ShipSettings[1] = 0
	else
		menu.ShipSetup.ShipSettings[1] = 1
	end
	menu.display()
end

-- Check availability of save waypoints button
Availability.SaveWaypoints = function()

end

-- Check availability of load waypoints button
Availability.LoadWaypoints = function()

end

init()
