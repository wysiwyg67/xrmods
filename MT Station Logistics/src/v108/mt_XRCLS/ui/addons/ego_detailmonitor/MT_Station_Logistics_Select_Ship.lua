--[[	Manages the select ship screen for the MT Station Logistics mod
		Version:		1.0.0
		Last Update:	2014-12-13
 --]]
 
local Buttons, Availability, Utility = {},{},{}
 
-- Set up the default menu table
local menu = { 	name = "gMT_Station_Logistics_Select_Ship",
				statusWidth = 150,
				statusHeight = 24,
				transparent = {
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

-- Standard Menu cleanup utility - place all variables no longer needed in here and assign the value nil to them
menu.cleanup = function ()
--	menu.selectedRow = nil
--	menu.infotable = nil
--	menu.selecttable = nil
--	menu.buttontable = nil
--	menu.expandStates = nil
--	menu.logindex = nil
--	menu.toprow = nil
--	menu.selrow = nil
	menu.buttons = nil
	menu.rows = nil
	menu.expand = nil
	menu.ship = nil
	return
end

-- hook function to handle displaying the menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.ship = {}
	menu.toprow = menu.param[4][1] or 0
	menu.selrow = menu.param[4][2] or 0 
	menu.expand = menu.param[4][3] or {0, 0}
	
	menu.ship.title = ReadText(150402,21)							-- menu.ship.title = "MT Station Logistics - Administration"
	menu.ship.subtitle = ReadText(150402,101)						-- menu.ship.subtitle = "Select a ship to add as a station trader"

	menu.ship.assigned_ships = menu.param[5] or {}

	menu.selectedRow = { idx = menu.selrow, data = {} }

	menu.display()

	return
end

-- Main redraw function
menu.display = function()	
	Helper.removeAllButtonScripts(menu)
	Helper.currentTableRow = {}
	Helper.currentTableRowData = nil
	menu.rowDataMap = {}
	
	-- Setup the header block
	local infodesc, headerHeight = LibMT.create_standard_header( menu, menu.ship.title, { menu.ship.subtitle, "" })

	local range = { ReadText(20001,201), ReadText(20001,101), ReadText(20001,901)  }	-- local range = { "Sector", "System", "Galaxy" }
	-- get a list of player owned ships
	menu.ship.ships = GetContainedShipsByOwner("player")
	-- sanity check ship list to remove invalid entries i.e. player ship, drones, small, medium,assigned to commander ,battle, CV
	menu.ship.ships = LibMT.filter_ships( menu.ship.ships, {"commander", "playership", "ship_s", "ship_m", "ship_xs", "drone", "battleship", "cv"} )
	-- remove ships with less than 20 cargo lifter drones
	menu.ship.ships = LibMT.filter_ships_bydrones( menu.ship.ships, "cargo", 5 )
	-- Remove ships with insufficient/missing crew - filters out ships with no captain as set up
	menu.ship.ships = LibMT.remove_ships_with_no_crew( menu.ship.ships )

	-- get local copy of assigned ships tables for comparison with unused ships
	local assigned, unassigned, active, inactive = {}, {}, {}, {}
	for _,details in ipairs(menu.ship.assigned_ships) do
		table.insert(assigned, details[1])
	end
	-- Remove active ships
	if #menu.ship.assigned_ships > 0 then
		menu.ship.ships = LibMT.Set.Difference(  menu.ship.ships, assigned )
	end
	
	-- Sort assigned ships into active and inactive ships
	for i, ship in ipairs(menu.ship.assigned_ships) do
		if ship[8] > 0 then
			table.insert(active, ship)
		else
			table.insert(inactive,ship)
		end
	end

	menu.ship.assigned_ships = LibMT.Set.Union( active, inactive )
	
	-- setup the list view here	
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = {
		Helper.standardTextHeight,			-- NB Width set using height parameter to get square button
		370,								-- Ship Section
		250,								-- Homebase section
		70,									-- Crew Level
		70,									-- Crew Score
		0									-- No. of Waypoints (Fill remainder of row)
	}

	-- List already configured and active ships
	local isExpanded = LibMT:IsExpanded(menu, #row_collection + 1) or (menu.expand and menu.expand[1] and (menu.expand[1] > 0) ) 
	local nrOfChildRows = #menu.ship.assigned_ships
	local cells = {}
	local ExpandButtonLabel = (isExpanded and "-") or "+"
	local ExpandScript = 	function (rowIdx, colIdx) LibMT:ToggleRow(menu, rowIdx, false, true) end
	local Label = ReadText(150402,102) .. " (" .. (#menu.ship.assigned_ships or 0) .. ")"		--"Configured Logistics Ships"

	table.insert(cells, LibMT:ButtonCell(ExpandButtonLabel, ExpandScript, 1, #menu.ship.assigned_ships > 0))
	table.insert(cells, LibMT:Cell(Label, nil, 1))
	table.insert(cells, LibMT:Cell(ReadText(150402,103), nil, 1))	-- "Homebase"
	table.insert(cells, LibMT:Cell(ReadText(1001,1302), nil, 1))	-- "Range"
	table.insert(cells, LibMT:Cell(ReadText(150402,111), nil, 1))	-- "Activity" eg None{150402,112}, trading{1002,1005}, mining{150402,113} 
	table.insert(cells, LibMT:Cell(ReadText(150402,106), nil, 1))	-- "#WP"
	table.insert(row_collection, LibMT:Row(cells, { "header", "none" }, Helper.defaultHeaderBackgroundColor, false, nrOfChildRows))

	-- Set initial expand states
	menu.rows = row_collection
	if isExpanded and menu.expand then
		LibMT:ExpandRow(menu, #row_collection, true, false)
	elseif menu.expand then
		LibMT:CollapseRow(menu, #row_collection, true, false)
	end

	-- Expandable row - Assigned ships
	local cells = {}
	if isExpanded then
		for i,ship in ipairs(menu.ship.assigned_ships or {}) do
			cells = {}
			local homebase = ""
			if type(ship[2]) == "string" then homebase = ship[2]
			else homebase = GetComponentData( ship[2], "name") end
			table.insert(cells, LibMT:Cell("", nil, 1))
			table.insert(cells, LibMT:Cell( "   " .. GetComponentData(ship[1], "name"), nil, 1))
			table.insert(cells, LibMT:Cell( homebase, nil, 1))
--			local captainscore, defencescore, engineerscore, level, crewscore = LibMT.get_crew_level( ship[1] )
			local activity = ReadText(150402,112)						-- "None"
			if ship[8] == 1 then activity = ReadText(1002,1005) end		-- "Trading"
			if ship[8] == 2 then activity = ReadText(150402,113) end	-- "Mining"
			table.insert(cells, LibMT:Cell(tostring(range[ship[5]]), nil, 1))
			table.insert(cells, LibMT:Cell(activity, nil, 1))
			table.insert(cells, LibMT:Cell(ship[11], nil, 1))
			table.insert(row_collection, LibMT:Row(cells, { "active", ship }, Helper.defaultHeaderBackgroundColor, false, 0))
		end
	end

	-- Header Row - unassigned ships
	local isExpanded = LibMT:IsExpanded(menu, #row_collection + 1) or (menu.expand and menu.expand[2] and (menu.expand[2] > 0) )
	local nrOfChildRows = #menu.ship.ships
	local cells = {}
	local ExpandButtonLabel = (isExpanded and "-") or "+"
	local ExpandScript = 	function (rowIdx, colIdx) LibMT:ToggleRow(menu, rowIdx, false) end
	local Label = ReadText(150402,107) .. " (" .. #menu.ship.ships .. ")"		-- "Un-configured ships available"

	table.insert(cells, LibMT:ButtonCell(ExpandButtonLabel, ExpandScript, 1, #menu.ship.ships > 0))
	table.insert(cells, LibMT:Cell(Label, nil, 1))
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(row_collection, LibMT:Row(cells, { "header", "none" }, Helper.defaultHeaderBackgroundColor, false, nrOfChildRows))

	-- Set initial expand states
	menu.rows = row_collection
	if isExpanded and menu.expand then
		LibMT:ExpandRow(menu, #row_collection, true)
	elseif menu.expand then
		LibMT:CollapseRow(menu, #row_collection, true)
	end


	-- Expandable row - unassigned ships
	local cells = {}
	if isExpanded then
		for i,ship in ipairs(menu.ship.ships) do
			cells = {}
			-- Calculate the crew score and return with trader stuff
			local captainscore, defencescore, engineerscore, level, crewscore = LibMT.get_crew_level( ship )
			table.insert(cells, LibMT:Cell("", nil, 1))
			table.insert(cells, LibMT:Cell( "   " .. GetComponentData(ship, "name"), nil, 1))
			table.insert(cells, LibMT:Cell("", nil, 1))
			table.insert(cells, LibMT:Cell(tostring(range[level]), nil, 1))
			local activity = ReadText(150402,112)						-- "None"
			table.insert(cells, LibMT:Cell(activity, nil, 1))
			table.insert(cells, LibMT:Cell("", nil, 1))
			table.insert(row_collection, LibMT:Row(cells, { "new", {ship} }, Helper.defaultHeaderBackgroundColor, false, 0))
		end
	end

	-- deal with row changes here
	menu.rows = row_collection
	-- and expand states
	menu.expand = nil 
	
	-- create the body descriptor
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, true, false, headerHeight + 5, bodyHeight - 6, menu.toprow, menu.selrow )

	-- setup the button section view
	menu.buttons = {}
	-- Setup the button bar
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,108), Buttons.Remove, Availability.Remove, "" ))									-- "Remove"
	table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,109),Buttons.Stop, Availability.Stop,""))										-- "Stop"
	table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,103),Buttons.Homebase, Availability.Homebase,""))								-- "Homebase"
	table.insert(menu.buttons, LibMT:BarButton(ReadText(1001,2669), Buttons.Back, function () return true end, "INPUT_STATE_DETAILMONITOR_B" ))	-- "Back"
	table.insert(menu.buttons, LibMT:BarButton(ReadText(1001,3106), Buttons.Add, Availability.Add, "INPUT_STATE_DETAILMONITOR_BACK" ))			-- "Add"
	table.insert(menu.buttons, LibMT:BarButton(ReadText(1009,8), Buttons.Start, Availability.Start,"INPUT_STATE_DETAILMONITOR_Y"))				-- "Start"
	table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,110), Buttons.Select, Availability.Select, "INPUT_STATE_DETAILMONITOR_X" ))		-- "Configure"
	
	-- create the button bar
	local buttondesc = LibMT.create_standard_button_bar( menu, menu.buttons, headerHeight, bodyHeight )

	-- build and display the menu view
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false)

	-- finally, we call all the script attaching functions
	for _, func in ipairs(cell_scripts) do
		func()
	end
	
	Helper.releaseDescriptors()
	return 
end

-- standard hook function to handle changing row
menu.onRowChanged = function (row, rowdata, rc_table)
	if rc_table == menu.defaulttable then
		menu.selectedRow.idx = row
		menu.selectedRow.data = rowdata
		-- Show ship location in header
		if rowdata[1] ~= "header" then
			local zone, sector, system = GetComponentData(rowdata[2][1], "zone", "sector", "cluster")
			local label = ReadText(20001,301) .. ": " ..zone .. " - " .. ReadText(20001,201) .. ": " .. sector .. " - " .. ReadText(20001,101) .. ": " .. system
			Helper.updateCellText(menu.infotable, 3, 1, label, LibMT.colours.white)	
			-- check ship has a captain
			local captain = GetComponentData( rowdata[2][1], "pilot" )
			if captain == nil then
				menu.ship.hascaptain = false
				Helper.updateCellText(menu.infotable, 3, 1, "SHIP HAS NO CAPTAIN!!!", LibMT.colours.red)
			else 
				menu.ship.hascaptain = true
			end
		else
			Helper.updateCellText(menu.infotable, 3, 1, "", nil)
		end
		
		LibMT:CheckButtonBarAvailability(menu, row, rowdata)
	end
	return
end

-- standard hook function to called on select event (not used here)
menu.onSelectElement = function ()
	return 
end

-- standard hook function called when clicking the '<' or 'x' buttons in the corner of the menu
menu.onCloseElement = function (dueToClose)
	if dueToClose == "close" then
		Helper.closeMenuForSection(menu, false, "gMT_Admin_close")
		menu.cleanup()
	else
		Buttons:Back()
		menu.cleanup()
	end
	return
end

-- Callback function for back button
Buttons.Back = function()
	-- Get our expanded state for passing back
	local toprow, selrow, expand_state_table = Utility:GetExpandState()
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_back", { 1, 1, {}, {toprow, selrow, expand_state_table}  })
	menu.cleanup()
	return
end

-- Callback function for Add ship button
Buttons.Add = function ()
	Utility:Trader()
	local toprow, selrow, exp_tab = Utility:GetExpandState()
	local expand_state = { toprow, selrow, exp_tab, "addship" }
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_addship", { toprow, selrow, {}, expand_state, {}, menu.ship.trader, {} })
	menu.cleanup()
	return
end	

-- Callback function for select button
Buttons.Remove = function()
	Utility:Trader()
	local toprow, selrow, exp_tab = Utility:GetExpandState()
	local expand_state = { toprow, selrow, exp_tab, "removeship" }
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_removeship", { toprow, selrow, {}, expand_state, {}, menu.ship.trader, {} })
	menu.cleanup()
	return
end

-- Callback function for Configure button
Buttons.Select = function()
	Utility:Trader()
	local toprow, selrow, exp_tab = Utility:GetExpandState()
	local expand_state = { toprow, selrow, exp_tab, "configship" }
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_config", { toprow, selrow, {}, expand_state, {}, menu.ship.trader, {}})
	menu.cleanup()
	return
end

-- Callback function for Start button
Buttons.Start = function()
	Utility:Trader() -- note that this is just a dummy return value - values are manipulated in MD code
	local toprow, selrow, exp_tab = Utility:GetExpandState()
	local expand_state = { toprow, selrow, exp_tab, "startship" }
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_startship", { toprow, selrow, {}, expand_state, {}, menu.ship.trader, {} })
	menu.cleanup()
	return
end

-- Callback function for Stop button
Buttons.Stop = function()
	Utility:Trader() -- note that this is just a dummy return value - values are manipulated in MD code
	local toprow, selrow, exp_tab = Utility:GetExpandState()
	local expand_state = { toprow, selrow, exp_tab, "stopship" }
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_stopship", { toprow, selrow, {}, expand_state, {}, menu.ship.trader, {} })

--	menu.ret_arg[5] = "stopship"
--	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_stopship", { toprow, selrow, menu.ret_arg, {}, {}, exp_tab })
	menu.cleanup()
	return
end

-- Callback function for Homebase select button
Buttons.Homebase = function()
	Utility:Trader() -- return our trader for safekeeping whilst getting our homebase
	local toprow, selrow, exp_tab = Utility:GetExpandState()
	local expand_state = { toprow, selrow, exp_tab, "map_call"}
	Helper.closeMenuForSubSection(menu, false, "gMT_ShipMenu_gethomebase", { toprow, selrow, {}, expand_state, {}, menu.ship.trader, {} })
	menu.cleanup()
	return
end

-- Availability provider function for Add button
Availability.Add = function(menu, rowIdx, rowData)
	-- Ship is not already on the active list
	return (rowData[1] == "new")
end

-- Availability provider for remove button
Availability.Remove = function(menu, rowIdx, rowData)
	-- Ship is on the active list and must not be trading/mining
	return rowData[1] == "active" and rowData[2][8] < 1
end

-- Availability provider for Configure button
Availability.Select = function(menu, rowIdx, rowData)
	-- Ship is on the active list and has a homebase assigned
	return rowData[1] == "active" and rowData[2][2] ~= "none"
end

-- Availability provider for the Start button
Availability.Start = function(menu, rowIdx, rowData)
	-- Ship must be inactive, have a captain, have a homebase and have at least 2 waypoints to start
	return rowData[1] == "active" and rowData[2][3] ~= "none" and rowData[2][11] > 1 and rowData[2][8] < 1 and menu.ship.hascaptain
end

-- Availability provider for the Stop button
Availability.Stop = function(menu, rowIdx, rowData)
	return rowData[1] == "active" and rowData[2][8] > 0
end

-- Availability provider for the Homebase button
Availability.Homebase = function(menu, rowIdx, rowData)
	-- Ship is on the active list and is not currently trading
	return rowData[1] == "active" and rowData[2][8] < 1
end


-- Returns an array of expanded states and desired rows
Utility.GetExpandState = function()
	local expand_state_table = {}
	for i, exp_state in ipairs(menu.expandStates) do
		if exp_state.expanded then
			table.insert(expand_state_table, 1)
		else
			table.insert(expand_state_table, 0)
		end	
	end
	local toprow = GetTopRow(menu.defaulttable)
	local selrow = Helper.currentDefaultTableRow
	return toprow, selrow, expand_state_table
end

-- Sets up returns values for a trader record
Utility.Trader = function()
	-- Calculate the crew score and return with trader stuff
	local data = menu.selectedRow.data[2]
	menu.ship.trader = {}													-- Holds entire trader record
	menu.ship.ship = data[1] 												-- ship
	menu.ship.homebase = data[2] or "none"									-- homebase	
	menu.ship.cargolist = data[3] or LibMT.GetCargoSpecs( menu.ship.ship ) 	-- List of cargo the ship can carry
	menu.ship.waypoints = data[4] or {}										-- List of configured waypoints for this ship
	menu.ship.level = data[5] or 1
	menu.ship.crewscore = data[6] or 0
	menu.ship.log = data[7] or {}											-- Ship's log entries
	menu.ship.activity = data[8] or 0										-- Current activity
	menu.ship.stats = data[9] or {0, 0, 0, 0}								-- Ship stats { flying time, total time, volume traded, turnover}
	menu.ship.index = data[10] or 0											-- Ship's index in global table
	menu.ship.numwp = data[11] or 0 										-- Number of waypoints
	menu.ship.tracklog = data[12] or {}										-- Tracking log - keep clear unless in use
	menu.ship.DbgLvl = data[13] or 0										-- Debug level for this ship
	menu.ship.Track = data[14] or 0											-- True if ship is being tracked

	table.insert( menu.ship.trader, menu.ship.ship )
	table.insert( menu.ship.trader, menu.ship.homebase )
	table.insert( menu.ship.trader, menu.ship.cargolist )
	table.insert( menu.ship.trader, menu.ship.waypoints )
	table.insert( menu.ship.trader, menu.ship.level )
	table.insert( menu.ship.trader, menu.ship.crewscore )
	table.insert( menu.ship.trader, menu.ship.log )
	table.insert( menu.ship.trader, menu.ship.activity )
	table.insert( menu.ship.trader, menu.ship.stats )
	table.insert( menu.ship.trader, menu.ship.index )
	table.insert( menu.ship.trader, menu.ship.numwp )
	table.insert( menu.ship.trader, menu.ship.tracklog )
	table.insert( menu.ship.trader, menu.ship.DbgLvl )
	table.insert( menu.ship.trader, menu.ship.Track )

end


init()

return
