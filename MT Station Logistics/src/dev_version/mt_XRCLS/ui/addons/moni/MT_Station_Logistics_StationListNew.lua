--[[
 Manages station list screen for MT Station Logistics mod
 Finds stations based on passed parameters then displays in simple list sorted by distance from homebase or 
 expandable list by zone sector and cluster
 
 v1.3.5
 2015-04-06
 
 Actions:
	List player stations
	List NPC stations
	List Both types (highlight player in green)
	--Select a single station
	--Select multiple stations
	
	Callers:
	Ship Select - select homebase - single select - return to Ship select menu
	Edit Waypoint - select single station return to WP edit screen
	Add Waypoint - as above
	Add Multi-Waypoints - select multiple stations, convert to list of waypoints, - return to Waypoint List Menu
	
--]] 

-- ffi setup
local ffi = require("ffi")
local C = ffi.C
ffi.cdef[[
	typedef uint64_t UniverseID;
	const char* GetMapShortName(UniverseID componentid);
	UniverseID GetContextByClass(UniverseID componentid, const char* classname, bool includeself);
	const char* GetComponentName(UniverseID componentid);
]]

local utf8 = require("utf8")

-- Set up the default menu table
local menu = 	{	name = "gMT_Station_Logistics_StationListNew",
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
	menu.rows = nil
	menu.toprow = nil
	menu.selrow = nil
	menu.selectedRow = nil
--	menu.expandStates = nil
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.slist = {}

	-- get the passed parameters
	-- starting row states
	menu.toprow		 								= menu.param[1][1]
	menu.selrow 									= menu.param[1][2]
	menu.slist.expand_state							= menu.param[1][3]
	
	-- caller row states
	menu.slist.caller_rowstate 						= menu.param[2] or {}

	-- calling menu name
	menu.slist.caller								= menu.param[3]
	
	-- menu to return to if needed			
	menu.slist.return_menu							= menu.param[4]
	
	-- Additional parameters
	menu.slist.additional_params					= menu.param[5]
		menu.slist.action							= menu.slist.additional_params[1]
		menu.slist.stations 						= menu.slist.additional_params[2]
		menu.slist.WPParams							= menu.slist.additional_params[3]

	-- list of configured traders	
	menu.slist.tradeships							= menu.param[6] or {}
	
	-- Trader being worked on
	menu.slist.trader								= menu.param[7] or {}
		menu.slist.homebase 						= menu.slist.trader[2]
	
	-- Waypoint list for the trader or list passed
	menu.slist.waypoints							= menu.param[8] or {}
	
	-- Waypoint
	menu.slist.waypoint								= menu.param[9] or {}
	
	-- Global Options
	menu.slist.GlobalOptions						= menu.param[10] or {}

	-- Menu title texts
	menu.slist.title 								= "MT Station Logistics - Administration"
	menu.slist.subtitle 							= "Select a Station from the list below"

	-- switches here to sort stations differing methods dependant on call
	-- tag stations as selected or not - setup table
	menu.slist.selection = {}
	menu.slist.SelectedStation = 0

	menu.selectedRow = { idx = menu.selrow, data = {} }

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
		local sector = GetContextByClass(menu.slist.homebase, "sector")
		local asector = GetContextByClass(a, "sector")
		local bsector = GetContextByClass(b, "sector")

		local agates, ajumps = FindJumpRoute(sector, asector)
		local bgates, bjumps = FindJumpRoute(sector, bsector )
		return CompareJumpRoute(agates, ajumps, bgates, bjumps)
	end
	
	if type(menu.slist.homebase) ~= string then 
		if 1 < #menu.slist.stations then
			table.sort( menu.slist.stations, distance )
		end
	end

	-- sort list by zone sector cluster 
	menu.slist.sorted_stations = LibMT.SortStationsByZone( menu.slist.stations ) 
	menu.slist.selected_sorted_stations = {}

	-- Testing
	-- need some switches here or pass in these values
	if menu.slist.caller == "gMT_Station_Logistics_Select_Ship" then
		menu.slist.multiple = false		-- get one station for HB
		if 20 < #menu.slist.stations then
			menu.slist.nested = true  		-- switch between simple list and nested view
		else
			menu.slist.nested = false  		-- switch between simple list and nested view
		end
	elseif menu.slist.caller == "" then
		menu.slist.nested = false  		-- switch between simple list and nested view
		menu.slist.multiple = true		-- get one or multiple stations
	end
	-- display our menu
	menu.display(true)
end

menu.display = function ( first )	
	-- menu setup
	Helper.removeAllButtonScripts(menu)
	Helper.currentTableRow = {}
	Helper.currentTableRowData = nil
	menu.rowDataMap = {}

	menu.slist.selected_sorted_stations = {}

	-- Create the menu header and get its height
	local infodesc, headerHeight
	if menu.slist.multiple then
		infodesc, headerHeight = LibMT.create_standard_header( menu, menu.slist.title, {menu.slist.subtitle .. "  Selected: " .. menu.slist.selected_count} )
	else
		infodesc, headerHeight = LibMT.create_standard_header( menu, menu.slist.title, {menu.slist.subtitle} )
	end 
	
	-- setup the list view here	
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = {	Helper.standardButtonWidth,	400, 200, 0 }
	local row_index = 0			-- index var for row states
	
	-- Setup table
	if not menu.slist.nested then
		if 0 < #menu.slist.stations then
			for row, station in ipairs(menu.slist.stations) do
				local cells = {}
				local Name = GetComponentData( station, "name")
				local Cluster = ffi.string(C.GetMapShortName(   C.GetContextByClass( ConvertIDTo64Bit(station), "cluster", true )  ))
				local Sector = ffi.string(C.GetMapShortName(   C.GetContextByClass( ConvertIDTo64Bit(station), "sector", true )  ))
				local Zone = ffi.string(C.GetMapShortName(   C.GetContextByClass( ConvertIDTo64Bit(station), "zone", true )  ))
				table.insert(cells, LibMT:Cell( Cluster .. "." .. Sector .. "." .. Zone .. " - " .. Name, nil, 2))
				if menu.slist.selection[row] == 1 then
					table.insert(cells, LibMT:Cell("Selected", nil, 1))
					table.insert( 	menu.slist.selected_sorted_stations, station)					
				else
					table.insert(cells, LibMT:Cell("", nil, 1))			
				end
				if menu.slist.multiple then
					table.insert( cells, LibMT:ButtonCell( "Toggle Selection", function (rowIdx, colIdx) Buttons:ToggleSelection( rowIdx ) end, 1, true))
				else
					table.insert( cells, LibMT:ButtonCell( "Select Station", function (rowIdx, colIdx) Buttons:GetCurrentRowStation( rowIdx, {station} ) end, 1, true))
				end
				table.insert(row_collection, LibMT:Row(cells, {station}, Helper.defaultHeaderBackgroundColor, false, 0))
			end
		else
			local cells = {}
			local Label = "No stations found"
			table.insert(cells, LibMT:Cell(Label, nil, 4))
			table.insert(row_collection, LibMT:Row(cells, option, Helper.defaultHeaderBackgroundColor, false, 0))
		end
	else -- draw nested table
		if 0 < #menu.slist.stations then
			for clusterkey, cluster in pairs(menu.slist.sorted_stations) do
				local cells = {}
				local nrOfChildRows = LibMT.GetNumEntries( cluster )
				local isExpanded = LibMT:IsExpanded(menu, #row_collection + 1)
				local ExpandButtonLabel = (isExpanded and "-") or "+"
				local ExpandScript = 	function (rowIdx, colIdx) LibMT:ToggleRow(menu, rowIdx, false, true) end
				table.insert(cells, LibMT:ButtonCell(ExpandButtonLabel, ExpandScript, 1, nrOfChildRows > 0))
				table.insert(cells, LibMT:Cell(clusterkey, nil, 3))
				table.insert(row_collection, LibMT:Row(cells, "", Helper.defaultHeaderBackgroundColor, false, nrOfChildRows))
				menu.rows = row_collection
				if isExpanded and first then
					LibMT:ExpandRow(menu, #row_collection, true, false)
				elseif first then
					LibMT:CollapseRow(menu, #row_collection, true, false)
				end
				-- Child entries (sectors)
				if isExpanded then
					for sectorkey, sector in pairs( cluster ) do
						local cells = {}
						local nrOfChildRows = LibMT.GetNumEntries( sector )
						local isExpanded = LibMT:IsExpanded(menu, #row_collection + 1)
						local ExpandButtonLabel = (isExpanded and "-") or "+"
						local ExpandScript = 	function (rowIdx, colIdx) LibMT:ToggleRow(menu, rowIdx, false, true) end
						table.insert(cells, LibMT:ButtonCell(ExpandButtonLabel, ExpandScript, 1, nrOfChildRows > 0))
						table.insert(cells, LibMT:Cell("   " .. sectorkey, nil, 3))
						table.insert(row_collection, LibMT:Row(cells, "", Helper.defaultHeaderBackgroundColor, false, nrOfChildRows))
						menu.rows = row_collection
						-- Child entries (zones)
						if isExpanded then
							for zonekey, zone in pairs(sector) do
								local cells = {}
								local nrOfChildRows = #zone
								local isExpanded = LibMT:IsExpanded(menu, #row_collection + 1)
								local ExpandButtonLabel = (isExpanded and "-") or "+"
								local ExpandScript = 	function (rowIdx, colIdx) LibMT:ToggleRow(menu, rowIdx, false, true) end
								table.insert(cells, LibMT:ButtonCell(ExpandButtonLabel, ExpandScript, 1, nrOfChildRows > 0))
								table.insert(cells, LibMT:Cell("      " .. zonekey, nil, 3))
								table.insert(row_collection, LibMT:Row(cells, "", Helper.defaultHeaderBackgroundColor, false, nrOfChildRows))
								menu.rows = row_collection
								-- Child entries (stations)
								if isExpanded then
									for _,station in ipairs(zone) do
										local cells = {}
										table.insert(cells, LibMT:Cell("", nil, 1))
										table.insert(cells, LibMT:Cell("         " .. GetComponentData(station[1], "name"), nil, 1))
										if station[2] then 
											table.insert(cells, LibMT:Cell("Selected", nil, 1))
											table.insert( 	menu.slist.selected_sorted_stations, station[1])
										else
											table.insert(cells, LibMT:Cell("", nil, 1))
										end
										if menu.slist.multiple then
											table.insert( cells, LibMT:ButtonCell( "Toggle Selection", function (rowIdx, colIdx) Buttons:ToggleSelection( rowIdx, station ) end, 1, true))
										else
											table.insert( cells, LibMT:ButtonCell( "Select Station", function (rowIdx, colIdx) Buttons:GetCurrentRowStation( rowIdx, station ) end, 1, true))
										end
										table.insert(row_collection, LibMT:Row(cells, {station[1], station[2]}, Helper.defaultHeaderBackgroundColor, false, 0))
									end
								end
							end
						end
					end
				end
			end
		end
	end
	menu.rows = row_collection
	if (menu.toprow == nil) or first then 
		menu.toprow 	= menu.param[1][1] or 0 
		menu.selrow 	= menu.param[1][2] or 0 
	end
	
	-- create the body descriptor
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, true, false, headerHeight + 6, bodyHeight - 25, menu.toprow, menu.selrow )

	-- setup the button section view
	menu.buttons = {}
	-- Setup the button bar
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton(ReadText(1001,2669), Buttons.Back, function () return true end,"INPUT_STATE_DETAILMONITOR_B"))
	if menu.slist.multiple then
		table.insert(menu.buttons, LibMT:BarButton("Select None", Buttons.SelectNone, function () return true end, "INPUT_STATE_DETAILMONITOR_BACK" ))
		table.insert(menu.buttons, LibMT:BarButton("Select All", Buttons.SelectAll, function () return true end, "INPUT_STATE_DETAILMONITOR_Y" ))
		table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,244), Buttons.Select, function () return true end, "INPUT_STATE_DETAILMONITOR_X" ))
	else
		table.insert(menu.buttons, LibMT:BarButton())
		table.insert(menu.buttons, LibMT:BarButton())
		table.insert(menu.buttons, LibMT:BarButton())
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
		menu.selectedRow.idx = row
		menu.selectedRow.data = rowdata
		LibMT:CheckButtonBarAvailability(menu, row, rowdata)
	end
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
	if not menu.slist.nested then
		-- set number of selected stations
		local count = 0
		for i,v in ipairs(menu.slist.selection) do
			menu.slist.selection[i] = 1
			count = count + 1
		end
		menu.slist.selected_count = count
	else
		local count = 0
		for clusterkey, cluster in pairs(menu.slist.sorted_stations) do
			for sectorkey, sector in pairs(cluster) do
				for zonekey, zone in pairs(sector) do
					for _,station in ipairs(zone) do
						station[2] = true
						count = count + 1
					end
				end
			end
		end
		menu.slist.selected_count = count
	end
	
	menu.slist.toprow = GetTopRow(menu.defaulttable)
	menu.slist.selrow = Helper.currentDefaultTableRow
	menu.display()
end

-- Callback function for select none button
function Buttons:SelectNone()
	if not menu.slist.nested then
		-- set number of selected stations
		for i,v in ipairs(menu.slist.selection) do
			menu.slist.selection[i] = 0
		end
	else
		for clusterkey, cluster in pairs(menu.slist.sorted_stations) do
			for sectorkey, sector in pairs(cluster) do
				for zonekey, zone in pairs(sector) do
					for _,station in ipairs(zone) do
						station[2] = false
					end
				end
			end
		end
	end

	menu.slist.selected_count = 0
	menu.slist.toprow = GetTopRow(menu.defaulttable)
	menu.slist.selrow = Helper.currentDefaultTableRow
	menu.display()
end

-- Callback function for toggle selection button
function Buttons:ToggleSelection( Row, station )
	if not menu.slist.nested then
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
	else
		if station[2] then station[2] = false else station[2] = true end
		local count = 0
		for clusterkey, cluster in pairs(menu.slist.sorted_stations) do
			for sectorkey, sector in pairs(cluster) do
				for zonekey, zone in pairs(sector) do
					for _,station in ipairs(zone) do
						if station[2] then	count = count + 1 end
					end
				end
			end
		end
		menu.slist.selected_count = count
	end
	menu.toprow = GetTopRow(menu.defaulttable)
	menu.selrow = Helper.currentDefaultTableRow
	menu.display()
end

-- Callback function if we are in single select mode
function Buttons:GetCurrentRowStation( Row, station )
	menu.slist.SelectedStation = station[1]
	Buttons.Select()
end

-- Callback function for back button
Buttons.Back = function()
	-- Go back to where requested without saving
	if menu.slist.caller == "gMT_Station_Logistics_Select_Ship" then -- return with homebase station
		local additional_params = {"nochange"}
		Helper.closeMenuForSection(menu, false, menu.slist.return_menu, {  {0,0,{}}, menu.slist.caller_rowstate, menu.name, "gMT_Logistics_ShipMenu", 
																			additional_params, {}, menu.slist.trader, {}, {}, {}  })
	end
	menu.cleanup()
end

-- Callback function for select button
Buttons.Select = function()
	-- Get Selected station(s) (create new waypoints if from wp gen screen)
	if menu.slist.caller == "gMT_Station_Logistics_Select_Ship" then -- return with homebase station
		local additional_params = {"homebase", menu.slist.SelectedStation}
		Helper.closeMenuForSection(menu, false, menu.slist.return_menu, {  {0,0,{}}, menu.slist.caller_rowstate, menu.name, "gMT_Logistics_ShipMenu", 
																			additional_params, {}, menu.slist.trader, {}, {}, {}  })
	end
	menu.cleanup()
end

init()
