--[[
 Manages station list screen for MT Station Logistics mod
 v1.3.0
 2015-03-30
 
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
local menu = 	{	name = "gMT_Station_Logistics_StationList",
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
	menu.slist = nil
	menu.buttons = nil
	return
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.slist = {}
	menu.slist.toprow = menu.param[1]
	menu.slist.selrow = menu.param[2]
	
	menu.slist.title 		= "MT Station Logistics - Administration"
	menu.slist.subtitle 	= "Select Stations from list below"
	menu.slist.stations 	= menu.param[3]
	menu.slist.trader		= menu.param[4]
	menu.slist.WPParams		= menu.param[5]

	-- tag stations as selected or not - setup table
	menu.slist.selection = {}
	if 0 < #menu.slist.stations then
		for _, v in ipairs(menu.slist.stations) do
			table.insert(menu.slist.selection, 0)
		end
	end
		-- set number of selected stations
	local count = 0
	for _,v in ipairs(menu.slist.selection) do
		if menu.slist.selection == 1 then
			count = count + 1
		end
	end
	menu.slist.selected_count = count

	-- Sort station list by distance from homebase
	local function distance(a, b)
		local sector = GetContextByClass(menu.slist.trader[2], "sector")
		local asector = GetContextByClass(a, "sector")
		local bsector = GetContextByClass(b, "sector")

		local agates, ajumps = FindJumpRoute(sector, asector)
		local bgates, bjumps = FindJumpRoute(sector, bsector )
		return CompareJumpRoute(agates, ajumps, bgates, bjumps)
	end

	if 1 < #menu.slist.stations then
		table.sort( menu.slist.stations, distance )
	end
	
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
	local infodesc, headerHeight = LibMT.create_standard_header( menu, menu.slist.title, {menu.slist.subtitle .. "  Selected: " .. menu.slist.selected_count} )

	-- setup the list view here	
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = {	500, 200, 0 }

	
	-- Setup table
	if 0 < #menu.slist.stations then
		for row, station in ipairs(menu.slist.stations) do
			local cells = {}
			local Name = GetComponentData( station, "name")
			local Cluster = ffi.string(C.GetMapShortName(   C.GetContextByClass( ConvertIDTo64Bit(station), "cluster", true )  ))
			local Sector = ffi.string(C.GetMapShortName(   C.GetContextByClass( ConvertIDTo64Bit(station), "sector", true )  ))
			local Zone = ffi.string(C.GetMapShortName(   C.GetContextByClass( ConvertIDTo64Bit(station), "zone", true )  ))
			table.insert(cells, LibMT:Cell( Cluster .. "." .. Sector .. "." .. Zone .. " - " .. Name, nil, 1))
			if menu.slist.selection[row] == 1 then
				table.insert(cells, LibMT:Cell("Selected", nil, 1))
			else
				table.insert(cells, LibMT:Cell("", nil, 1))			
			end
			table.insert( cells, LibMT:ButtonCell( "Toggle Selection", function (rowIdx, colIdx) Buttons:ToggleSelection( rowIdx ) end, 1, true))
			table.insert(row_collection, LibMT:Row(cells, "", Helper.defaultHeaderBackgroundColor, false, 0))
		end
	else
		local cells = {}
		local Label = "No stations found"
		table.insert(cells, LibMT:Cell(Label, nil, 3))
		table.insert(row_collection, LibMT:Row(cells, option, Helper.defaultHeaderBackgroundColor, false, 0))
	end
	-- create the body descriptor
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, true, false, headerHeight + 6, bodyHeight - 25, menu.slist.toprow, menu.slist.selrow )

	-- setup the button section view
	menu.buttons = {}
	-- Setup the button bar
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton(ReadText(1001,2669), Buttons.Back, function () return true end,"INPUT_STATE_DETAILMONITOR_B"))
	table.insert(menu.buttons, LibMT:BarButton("Select None", Buttons.SelectNone, function () return true end, "INPUT_STATE_DETAILMONITOR_BACK" ))
	table.insert(menu.buttons, LibMT:BarButton("Select All", Buttons.SelectAll, function () return true end, "INPUT_STATE_DETAILMONITOR_Y" ))
	table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,244), Buttons.Select, function () return true end, "INPUT_STATE_DETAILMONITOR_X" ))
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

-- Callback function for select all button
function Buttons:SelectAll()
	-- set number of selected stations
	local count = 0
	for i,v in ipairs(menu.slist.selection) do
		menu.slist.selection[i] = 1
		count = count + 1
	end
	menu.slist.selected_count = count
	
	menu.slist.toprow = GetTopRow(menu.defaulttable)
	menu.slist.selrow = Helper.currentDefaultTableRow
	menu.display()
	return
end

-- Callback function for select none button
function Buttons:SelectNone()
	-- set number of selected stations
	for i,v in ipairs(menu.slist.selection) do
		menu.slist.selection[i] = 0
	end
	menu.slist.selected_count = 0
	
	menu.slist.toprow = GetTopRow(menu.defaulttable)
	menu.slist.selrow = Helper.currentDefaultTableRow
	menu.display()
	return
end

-- Callback function for toggle selection button
function Buttons:ToggleSelection( Row )
	if menu.slist.selection[Row] == 1 then
		menu.slist.selection[Row] = 0
	else
		menu.slist.selection[Row] = 1
	end
	-- set number of selected stations
	local count = 0
	for i,v in ipairs(menu.slist.selection) do
		if menu.slist.selection[i] == 1 then
			count = count + 1
		end
	end
	menu.slist.selected_count = count
	
	menu.slist.toprow = GetTopRow(menu.defaulttable)
	menu.slist.selrow = Helper.currentDefaultTableRow
	menu.display()
	return
end

-- Callback function for back button
Buttons.Back = function()
	Helper.closeMenuForSection(menu, false, "gMT_WPListMenu_StationListAbort", { menu.slist.toprow, menu.slist.selrow, menu.slist.trader, menu.slist.WPParams })
	menu.cleanup()
end

-- Callback function for select button
Buttons.Select = function()
-- Get Selected stations and create new waypoints
	local new_waypoint_list = {}
	local index = 0
	for i,v in ipairs( menu.slist.selection) do
		if v == 1 then
			index = index + 1
			local waypoint = {}
			table.insert(waypoint, index)						-- Waypoint index
			table.insert(waypoint, 1)							-- Waypoint is active by default
			table.insert(waypoint, menu.slist.stations[i])		-- The target station	
			table.insert(waypoint, menu.slist.WPParams[1] + 1)		-- Waypoint type
			table.insert(waypoint, menu.slist.WPParams[2])		-- Ware
			table.insert(waypoint, menu.slist.WPParams[9])		-- Min Amount
			table.insert(waypoint, menu.slist.WPParams[8])		-- Max Amount
			table.insert(waypoint, menu.slist.WPParams[5])		-- Price
			table.insert(waypoint, LibMT.GetStationRange(menu.slist.trader[2], menu.slist.stations[i]))		-- Range
			table.insert(waypoint, 1)							-- Override
			-- Add to waypoint list
			table.insert(new_waypoint_list, waypoint)
		end
	end
	
	
	Helper.closeMenuForSection(menu, false, "gMT_WPListMenu_StationListSave", { menu.slist.trader, new_waypoint_list})
	menu.cleanup()
	return
end


init()

return
