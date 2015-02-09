--[[	Manages the administration screen for the MT Station Logistics mod
		Version:		1.0.1
		Last Update:	2015-01-20
 --]]
-- Set up the default menu table
local menu = 	{	name = "gMT_Station_Logistics_Admin",
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

local Buttons = {}

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
	menu.admin = nil
	return
end

-- standard callback function that fires on first time display of menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.admin = {}
	menu.admin.toprow = menu.param[1]						-- return toprow
	menu.admin.selrow = menu.param[2]						-- return row
	menu.admin.title = ReadText(150402,21)					-- menu.title = "MT Station Logistics - Administration"
	menu.admin.subtitle = ReadText(150402,22) 				-- "Select an option from the list below and click select"

	menu.admin.options = {
		{ReadText(150402,26), "gMT_Admin_Ship_menu"},		-- "Administer Trade Ships"
		{ReadText(150402,27), "gMT_Admin_Report_menu"},		-- Get Reports
		{ReadText(150402,28), "gMT_Admin_Config_menu"}		-- Configure
	}

	menu.admin.selection = menu.admin.options[1][2]			-- Default menu selection

	menu.display( )
	
	return
end

-- main draw/redraw function
menu.display = function ()	
	Helper.removeAllButtonScripts(menu)
	Helper.currentTableRow = {}
	Helper.currentTableRowData = nil
	menu.rowDataMap = {}

	-- Create the menu header and get its height
	local infodesc, headerHeight = LibMT.create_standard_header( menu, menu.admin.title, {menu.admin.subtitle} )

	-- setup the list view here	
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = {	0 }

	-- Setup table
	for _, option in ipairs(menu.admin.options) do
		local cells = {}
		local Label = option[1]
		table.insert(cells, LibMT:Cell(Label, nil, 1))
		table.insert(row_collection, LibMT:Row(cells, option, Helper.defaultHeaderBackgroundColor, false, 0))
	end

	-- create the body descriptor
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, true, false, headerHeight + 6, bodyHeight - 45, menu.admin.toprow, menu.admin.selrow)

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

-- standard callback function that fires on a row change
menu.onRowChanged = function (row, rowdata, rc_table)
	if rc_table == menu.defaulttable then
		menu.admin.selection = rowdata[2]
		LibMT:CheckButtonBarAvailability(menu, row, rowdata)
	end
--[[
	DebugError( "Admin: onRowChanged: row = " .. tostring(row) .. 
				"   Rowdata =   " .. tostring(rowdata[2]) .. "\n" .. 
				"Helper.currentTableRow: " .. tostring(Helper.currentTableRow[menu.defaulttable]) .. 
				"\n Helper.currentDefaultTableRow: " .. tostring(Helper.currentDefaultTableRow) .. 
				"\n Menu.selection = " .. tostring(menu.selection)   )
--]]
	return
end

-- standard callback function that fires when an element is selected
menu.onSelectElement = function ()
	return 
end

-- standard callback function to deal with clicking the '<' or 'x' buttons in the corner of the menu
menu.onCloseElement = function (dueToClose)
	if dueToClose == "close" then
		Helper.closeMenuAndCancel(menu)
		menu.cleanup()
	else
		Buttons:Back()
	end
	return
end

-- Callback function for back button
Buttons.Back = function()
	Helper.closeMenuForSection(menu, false, "gMT_Admin_close", {} )
--	Helper.closeMenuAndReturn(menu)
	menu.cleanup()
	return
end

-- Callback function for select button
Buttons.Select = function()
	local toprow = GetTopRow(menu.defaulttable)
	local selrow = Helper.currentDefaultTableRow
	Helper.closeMenuForSection(menu, false, menu.admin.selection, { toprow, selrow, {}, })
	menu.cleanup()
	return
end

init()

return
