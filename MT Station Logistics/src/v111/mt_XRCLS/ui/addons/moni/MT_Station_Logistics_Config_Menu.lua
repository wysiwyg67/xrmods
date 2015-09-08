-- Manages config screen for MT Station Logistics mod
 
-- Set up the default menu table
local menu = 	{	name = "gMT_Station_Logistics_Configure",
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

-- Standard menu initialiser - initialise variables global to this menu here if needed
local function init()
	Menus = Menus or {}
	table.insert(Menus, menu)
	if Helper then
		Helper.registerMenu(menu)
	end
	return
end

-- local holder for buttons tasks and availability
local Buttons, Availability = {}, {}

-- Standard Menu cleanup utility - place all variables no longer needed in here and assign the value nil to them
menu.cleanup = function ()
--	menu.infotable = nil
--	menu.selecttable = nil
--	menu.buttontable = nil
--	menu.defaulttable = nil
	menu.config = nil
	menu.buttons = nil
	return
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.config = {}
	menu.config.toprow = menu.param[4][1]
	menu.config.selrow = menu.param[4][2]
	menu.config.currentdbg = menu.param[4][3]
	
	menu.config.title 		= ReadText(150402,81)			-- menu.title = "MT Station Logistics - Administration"
	menu.config.subtitle 	= ReadText(150402,82) .. "   " .. ReadText(150402,9001) .. " - " .. ReadText(150402, 9001 + 1 + menu.config.currentdbg)
	if LibMT.DEBUG then
		menu.config.options = {
			{ReadText(150402,83), "gMT_ConfigMenu_debug-error", 0},
			{ReadText(150402,84), "gMT_ConfigMenu_debug-info", 1},
			{ReadText(150402,85), "gMT_ConfigMenu_debug-detail", 2},
			{ReadText(150402,86), "gMT_ConfigMenu_debug-verbose", 3},
			{ReadText(150402,87), "gMT_ConfigMenu_uninstall", 0},
			{ReadText(150402,88), "gMT_ConfigMenu_reset", 0},
			{ReadText(150402,89), "gMT_ConfigMenu_ClearLogs", 0}
		}
	else
		menu.config.options = {
			{ReadText(150402,87), "gMT_ConfigMenu_gMT_ConfigMenu_uninstall", 0},
		}
	end
--	menu.config.selection = menu.config.options[1][2]
--	menu.config.debug_num = menu.config.options[1][3]
	
	-- display our menu
	menu.display( )
	
	return
end

menu.display = function ()	
	-- menu setup
	Helper.removeAllButtonScripts(menu)
	Helper.currentTableRow = {}
	Helper.currentTableRowData = nil
	menu.rowDataMap = {}

	
	-- Create the menu header and get its height
	local infodesc, headerHeight = LibMT.create_standard_header( menu, menu.config.title, {menu.config.subtitle} )

	-- setup the list view here	
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = {	0 }

	-- Setup table
	for _, option in ipairs(menu.config.options) do
		local cells = {}
		local Label = option[1]
		table.insert(cells, LibMT:Cell(Label, nil, 1))
		table.insert(row_collection, LibMT:Row(cells, option, Helper.defaultHeaderBackgroundColor, false, 0))
	end

	-- create the body descriptor
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, true, false, headerHeight+6, bodyHeight - 45)

	-- setup the button section view
	menu.buttons = {}
	-- Setup the button bar
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton(ReadText(1001,2669), Buttons.Back, function () return true end,"INPUT_STATE_DETAILMONITOR_B"))
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton(ReadText(1001,3102), Buttons.Select, function () return true end, "INPUT_STATE_DETAILMONITOR_X" ))
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

-- standard function stub to handle changing row
menu.onRowChanged = function (row, rowdata, rc_table)
	if rc_table == menu.defaulttable then
		menu.config.selection = rowdata[2]
		menu.config.debug_num = rowdata[3]
		LibMT:CheckButtonBarAvailability(menu, row, rowdata)
	end
	return
end

menu.onSelectElement = function ()
	return 
end

-- standard function to deal with clicking the '<' or 'x' buttons in the corner of the menu
menu.onCloseElement = function (dueToClose)
	if dueToClose == "close" then
		Helper.closeMenuAndCancel(menu)
		menu.cleanup()
	else
		Buttons:Back()
		menu.cleanup()
	end

	return
end

-- Callback function for back button
Buttons.Back = function()
	-- return with saved row selections
	Helper.closeMenuForSection(menu, false, "gMT_Admin_Config_return", { menu.config.toprow, menu.config.selrow })
	menu.cleanup()
	return
end

-- Callback function for select button
Buttons.Select = function()
	Helper.closeMenuForSection(menu, false, menu.config.selection, { menu.config.toprow, menu.config.selrow, menu.config.debug_num })
	menu.cleanup()
	return
end


init()

return
