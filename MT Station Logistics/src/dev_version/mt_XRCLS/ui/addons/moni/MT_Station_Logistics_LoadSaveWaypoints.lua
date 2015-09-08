--[[
 Manages load and save waypoints screen for MT Station Logistics mod
 v1.3.5
 2015-04-03
 
--]] 

-- ffi setup
local ffi = require("ffi")
local C = ffi.C
ffi.cdef[[
	typedef uint64_t UniverseID;
	const char* GetMapShortName(UniverseID componentid);
	UniverseID GetContextByClass(UniverseID componentid, const char* classname, bool includeself);
]]

local utf8 = require("utf8")

-- Set up the default menu table
local menu = 	{	name = "gMT_Station_Logistics_LoadSaveWaypoints",
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
	menu.infotable = nil
	menu.selecttable = nil
	menu.buttontable = nil
	menu.defaulttable = nil
	menu.lswp = nil
	menu.buttons = nil
	return
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.lswp = {}
	menu.lswp.toprow = menu.param[1]
	menu.lswp.selrow = menu.param[2]

	menu.lswp.trader		= menu.param[3]
	menu.lswp.ship			= menu.lswp.trader[1]
	menu.lswp.action 		= menu.param[4]
	menu.lswp.wpsave_list	= menu.param[5]
	
	menu.lswp.title 		= "MT Station Logistics - Administration"
	if menu.lswp.action == "loadwaypoints" then
		menu.lswp.subtitle 		= "Select a slot to load into:  " .. GetComponentData(menu.lswp.ship, "name") 
	else
		menu.lswp.subtitle 		= "Select a slot to save waypoints for:  " .. GetComponentData(menu.lswp.ship, "name") 
	end

	-- Hack
	menu.lswp.currentname = ""
	
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
	local infodesc, headerHeight = LibMT.create_standard_header( menu, menu.lswp.title, {menu.lswp.subtitle, "" } )

	-- setup the list view here	
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = { 0 }

	
	-- Setup table
	for _,slot in ipairs(menu.lswp.wpsave_list) do
		local cells = {}
		table.insert( cells, LibMT:Cell(slot[1], nil, 1))
		table.insert(row_collection, LibMT:Row(cells, slot, menu.transparent, false, 0))
	end

	-- create the body descriptor
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, true, false, headerHeight + 6, bodyHeight - 25, menu.lswp.toprow, menu.lswp.selrow )

	-- setup the button section view
	menu.buttons = {}
	-- Setup the button bar
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton( ReadText(1001,2669), Buttons.Back, function () return true end,"INPUT_STATE_DETAILMONITOR_B"))
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	if menu.lswp.action == "loadwaypoints" then
		table.insert(menu.buttons, LibMT:BarButton("Load", Buttons.Select, Availability.Select, "INPUT_STATE_DETAILMONITOR_X" ))
	else
		table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,244), Buttons.Select, Availability.Select, "INPUT_STATE_DETAILMONITOR_X" ))
	end
	-- create the button bar
	local buttondesc = LibMT.create_standard_button_bar( menu, menu.buttons, headerHeight, bodyHeight )

	-- build and display the view
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false, "", "", 0, 0, 0, 0, "both", false, false)

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
		menu.lswp.currentname = rowdata[1]
		menu.lswp.currentlist = rowdata[2]
		menu.lswp.slotnum = row
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
		Buttons:Back()
		menu.cleanup()
	end
end

-- Callback function for back button - return to ship setup screen
Buttons.Back = function()
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_LoadSaveReturn", { menu.lswp.toprow, menu.lswp.selrow, menu.lswp.trader, "loadsaveabort"})
	menu.cleanup()
end

-- Callback function for select button - if load then go back to ship setup, else goto waypoint rename screen and then back to ship setup
Buttons.Select = function()
	if menu.lswp.action == "loadwaypoints" then 	-- goto ship setup screen
		-- convert save list into ship compatible list
		local wp_ship = LibMT.deepcopy(menu.lswp.trader)
		local wp_list = LibMT.deepcopy(menu.lswp.currentlist)
		-- convert to amount based on %
		local listtobeloaded = LibMT.ConvertWayPointsToShip( wp_ship, wp_list )
		local params = { menu.lswp.slotnum, menu.lswp.currentname, listtobeloaded }
		-- return with confirm update
		Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_LoadSaveReturn", { menu.lswp.toprow, menu.lswp.selrow, menu.lswp.trader, "updatewaypoints", params })
	else											-- goto rename waypoint slot screen
		-- get waypoints from current ship
		local wp_ship = LibMT.deepcopy(menu.lswp.trader)
		local wp_list = wp_ship[4]
		-- convert to % based amounts
		local listtobesaved = LibMT.ConvertWayPointsToSave( wp_ship, wp_list )
		-- save as packet to be passed to rename function
		local params = { menu.lswp.slotnum, menu.lswp.currentname, listtobesaved }
		Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_LoadSaveReturn", { menu.lswp.toprow, menu.lswp.selrow, menu.lswp.trader, "renamesave", params })
	end
	menu.cleanup()
end

Availability.Select = function(menu, rowIdx, rowData)
	-- Check for list suitability against ship type here
	local retval = false
	local message_neg = "Ship cannot carry some or all of the wares on that list"
	local message_empty = "Slot is empty"
	local message_pos = ""
	if menu.lswp.action == "loadwaypoints" then
		if #rowData[2] < 1 then
			retval = false
			Helper.updateCellText(menu.infotable, 3, 1, message_empty, LibMT.colours.red)
		elseif LibMT.LoadWaypointsOK( menu.lswp.trader[1], rowData[2] ) then
			Helper.updateCellText(menu.infotable, 3, 1, message_pos, LibMT.colours.red)
			retval = true
		else 
			Helper.updateCellText(menu.infotable, 3, 1, message_neg, LibMT.colours.red)
			retval = false
		end
	else
		Helper.updateCellText(menu.infotable, 3, 1, message_pos, LibMT.colours.red)
		retval = true  -- Always available for save slots
	end
	return retval
end

init()

return
