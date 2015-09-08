--[[	Manages the trader admin log screen for the MT Station Logistics mod
		Version:		1.2.0
		Last Update:	2015-03-20
 --]]
 
-- Set up the default menu table
local menu = 	{	name = "gMT_Station_Logistics_AdminLog",
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
--	menu.lastupdate = nil
--	menu.infotable = nil
--	menu.selecttable = nil
--	menu.buttontable = nil
--	menu.defaulttable = nil
	menu.buttons = nil
	menu.adminlog = nil
--	menu.updateInterval = nil
	return
end

-- standard callback function that fires on first time display of menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.adminlog = {}
	menu.toprow = menu.param[1]					-- return toprow
	menu.selrow = menu.param[2]					-- return row
	menu.adminlog.ret_exp = menu.param[4]				-- return row and expand states
	menu.adminlog.trader = menu.param[7]				-- trader log for current ship for return ?? sort	
	menu.adminlog.log = menu.param[8]					-- The entire admin log	
	
	menu.adminlog.title = ReadText(150402,460)			-- menu.title = "MT Station Logistics - Admin Log"
	menu.adminlog.subtitle = ReadText(150402,461) 		-- "See all actions on Logistics Ships"
	
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
	-- Create the menu header and get its height
	local infodesc, headerHeight = LibMT.create_standard_header( menu, menu.adminlog.title, { menu.adminlog.subtitle, "" })
--	local infodesc, headerHeight = LibMT.create_column_header( menu, title, { typename }, additional, colwidth, colspan, true )

	-- setup the list view here	
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = {			
		75,
		100,
		200,
		100,
		0
	}
	
	-- Setup main table
	-- create the body descriptor
	if 0 < #menu.adminlog.log then
		for i, msg in ipairs(menu.adminlog.log) do
			local cells = {}
			table.insert(cells, LibMT:Cell( ConvertTimeString(GetCurTime() - msg[1]), nil, 1))  -- "Time"
			table.insert(cells, LibMT:Cell( msg[2], nil, 4))  -- "Message"
			table.insert(row_collection, LibMT:Row(cells, { "none" }, Helper.defaultHeaderBackgroundColor, false, 0))
		end
	else
		local cells = {}
		table.insert(cells, LibMT:Cell( ReadText(150402, 462), nil, 5))  -- "No Admin Log messages"
		table.insert(row_collection, LibMT:Row(cells, { "none" }, Helper.defaultHeaderBackgroundColor, false, 0))
	end
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, true, false, headerHeight + 14, bodyHeight + 20, menu.toprow, menu.selrow)

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
	table.insert(menu.buttons, LibMT:BarButton())
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
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_returnadmin", { menu.adminlog.ret_exp[1], menu.adminlog.ret_exp[2], {}, menu.adminlog.ret_exp, {}, {}, menu.adminlog.trader, menu.adminlog.log } )
	menu.cleanup()
	return
end


init()

return
