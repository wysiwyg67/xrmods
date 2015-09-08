-- MT Logistics Global Options Menu
 
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
end

-- Standard Menu cleanup utility - place all variables no longer needed in here and assign the value nil to them
menu.cleanup = function ()
	menu.updateInterval = nil
	menu.infotable = nil
	menu.selecttable = nil
	menu.buttontable = nil
	menu.buttons = nil
	menu.GlobalOptions = nil
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.GlobalOptions 						= {} 

	menu.GlobalOptions.toprow 				= menu.param[1][1]
	menu.GlobalOptions.selrow 				= menu.param[1][2]

	menu.GlobalOptions.OptionsList 			= menu.param[10] or {0,1}

	if #menu.GlobalOptions.OptionsList < 2 then table.insert(menu.GlobalOptions.OptionsList, 1) end -- fix for v1.25 update
	
	menu.GlobalOptions.title				= "MT Logistics Global Options Menu"
	menu.GlobalOptions.subtitle 			= ""
	menu.GlobalOptions.subtitle3 			= ""

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

	local cells = {}
	table.insert( cells, LibMT:Cell("Add waypoints using list rather than map?", nil, 1))
	if 0 < menu.GlobalOptions.OptionsList[2] then
		table.insert( cells, LibMT:Cell("YES", nil, 1))
	else
		table.insert( cells, LibMT:Cell("NO", nil, 1))	
	end
	table.insert( cells, LibMT:ButtonCell( "Toggle", Buttons.ToggleWPAddList, 1, true))
	table.insert( cells, LibMT:Cell("", nil, 1))
	table.insert(row_collection, LibMT:Row(cells, rowData, menu.transparent, false, 0))


	-- Build the table descriptor
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, false, false, headerHeight + 8, bodyHeight, menu.GlobalOptions.toprow, menu.GlobalOptions.selrow )
	
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
end

-- standard function stub to handle changing row
menu.onRowChanged = function (row, rowdata, rc_table)
	if rc_table == menu.defaulttable then
		LibMT:CheckButtonBarAvailability(menu, row, rowdata)
	end
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
	local toprow = GetTopRow(menu.defaulttable)
	local selrow = Helper.currentDefaultTableRow
	local self_row_state = { toprow, selrow, expand_state_table }				-- Package up expand state
	local return_row_state = {1, 1, {}}											-- The state we want the return table to open in
	Helper.closeMenuForSection(menu, false, "gMT_Logistics_AdminMenu", { return_row_state, self_row_state, menu.name, "", 
																				{}, {}, {}, {}, {}, menu.GlobalOptions.OptionsList })
	menu.cleanup()																-- Clean up variables no longer needed
--	menu.GlobalOptions.trader[15] = menu.GlobalOptions.ShipSettings
--	Helper.closeMenuForSection(menu, false, "gMT_ConfigMenu_GlobalOptionsReturn", { 1, 3, {}, {"","","",""}, {}, menu.GlobalOptions.OptionsList, {} })
--	menu.cleanup()
end

-- Callback function for CV button
Buttons.ToggleOtherMods = function()
	if 0 < menu.GlobalOptions.OptionsList[1] then
		menu.GlobalOptions.OptionsList[1] = 0
	else
		menu.GlobalOptions.OptionsList[1] = 1
	end
	menu.display()
end

-- Callback function for map list option
Buttons.ToggleWPAddList = function()
	if 0 < menu.GlobalOptions.OptionsList[2] then
		menu.GlobalOptions.OptionsList[2] = 0
	else
		menu.GlobalOptions.OptionsList[2] = 1
	end
	menu.display()
end

init()
