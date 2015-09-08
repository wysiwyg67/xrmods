--[[	Manages the reports screen for the MT Station Logistics mod
		Version:		1.0.0
		Last Update:	2014-12-13
		
		Ranks:
			Rank							XP
		Captain
			Admiral							500,000
			Rear Admiral					200,000
			Commander						100,000
			Colonel							75,000
			Lieutenant Colonel				50,000
			Major							20,000
			Captain					
			
		Defence Officer
			Sergeant major					500,000
			Gunnery Sergeant				200,000
			Sergeant 1st Class				100,000
			Crew Sergeant					75,000
			Corporal						50,000
			Private 1st Class				20,000
			Private
			
		Engineer
			Master Chief Petty Officer		500,000
			Chief Petty Officer				200,000
			Petty Officer 1st Class			100,000
			Petty Officer 2nd Class			75,000
			Specialist						50,000
			Crewman							20,000
			Crewman Apprentice
			
 --]]
 
local Buttons, Availability, Utility = {},{},{}
 
-- Set up the default menu table
local menu = { 	name = "gMT_Station_Logistics_Reports",
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
--	menu.ships = nil
--	menu.ship = nil
	menu.buttons = nil
--	menu.rows = nil
--	menu.selectedRow = nil
--	menu.infotable = nil
--	menu.selecttable = nil
--	menu.buttontable = nil
--	menu.expandStates = nil
	menu.expand = nil
	menu.report = nil
	menu.exp_ret = nil
	return
end

-- hook function to handle displaying the menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.report 			= {}
	
	menu.toprow 				= menu.param[4][1] or 0
	menu.selrow 				= menu.param[4][2] or 0 
	menu.expand					= menu.param[4][3]
	
	menu.report.title 			= ReadText(150402,41)						-- menu.title = "MT Station Logistics - Reports Menu"
	menu.report.subtitle 		= ReadText(150402,42)						--	menu.title = "Get data about ships and crew"

	menu.report.assigned_ships 	= menu.param[5] or {}
	menu.report.cls_crew 		= menu.param[6] or {}
	menu.report.ship			= menu.param[7] or {}
	
	menu.selectedRow = { idx = menu.selrow, data = {} }

	menu.exp_ret = {}
	-- display our menu
	menu.display( true )
	return
end

-- Main redraw function
menu.display = function (first)	
	Helper.removeAllButtonScripts(menu)
	Helper.currentTableRow = {}
	Helper.currentTableRowData = nil
	menu.rowDataMap = {}
	
	-- Setup the header block
	local infodesc, headerHeight = LibMT.create_standard_header( menu, menu.report.title, { menu.report.subtitle, "" })
	local range = { ReadText(20001,201), ReadText(20001,101), ReadText(20001,901)  }	-- local range = { "Sector", "System", "Galaxy" }
	-- Sort crew and get a list of anyone not currently on a cls ship but is configured as a cls crewmember
	-- Get list of cls crew already on cls ships
	local assigned_crew = {}
	local ship_count = 0				-- counts number of entries in our ship list as # doesn't work with keyed tables
	for key, ship in pairs(menu.report.assigned_ships) do
--		DebugError( "Key  " .. tostring(key) .. "  Ship -  " .. GetComponentData(ship[1], "name") )
		local captain, defence, engineer = GetComponentData( ship[1], "pilot", "defencenpc", "engineer" )
		if captain and GetNPCBlackboard(captain, "$XRCLS") then
			table.insert(assigned_crew, captain)
		end	
		if defence and GetNPCBlackboard(defence, "$XRCLS") then
			table.insert(assigned_crew, defence)
		end	
		if engineer and GetNPCBlackboard(engineer, "$XRCLS") then
			table.insert(assigned_crew, engineer)
		end	
		ship_count = ship_count + 1     -- Add a ship
	end
	
	-- Now remove these from our list of all-time cls crew
	local unassigned_crew = LibMT.Set.Difference(menu.report.cls_crew, assigned_crew )

	-- Sort ships into a list ordered by homebase
	local sorted_ships  = {}
	local homebases = {}
--	DebugError("No. of ships = " .. tostring(#menu.report.assigned_ships))
	if 0 < ship_count then
		for key, ship in pairs(menu.report.assigned_ships) do
			local homebase = ""
			
			if type(ship[2]) == "string" then homebase = ship[2]
			else homebase = GetComponentData( ship[2], "name") end

			if sorted_ships[homebase] == nil then	
				sorted_ships[homebase] = {}
				local ship = ship[2]
				homebases[homebase] = {}
				table.insert(homebases[homebase], ship) -- for station data
			end
			local captain, defence, engineer = GetComponentData( ship[1], "pilot", "defencenpc", "engineer" )
			local crew = {captain, defence, engineer}
			table.insert(sorted_ships[homebase], {ship, crew} )
		end
	end

	if 0 < #homebases then 
		for i, station in pairs(homebases) do
--			DebugError(  GetComponentData( station, "name" ))
		end
	end

	-- setup the list view here	
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = {
		Helper.standardButtonWidth,			-- 
		320,								-- Ship Section
		150,								-- Homebase section
		200,								-- Crew Level
		0,									-- Crew Score
		30									-- No. of Waypoints (Fill remainder of row)
	}


	local row_index = 0			-- index var for row states
	local stationctr = 0

	if 0 < ship_count then
		for homebase_key, homebase_name in pairs(sorted_ships) do
			row_index = row_index + 1
			stationctr = stationctr + 1
			-- Homebase header row
			local nrOfChildRows = 0
			for k,v in pairs(sorted_ships[homebase_key]) do
				nrOfChildRows = nrOfChildRows + 1
			end
			local isExpanded = LibMT:IsExpanded(menu, #row_collection + 1) or (menu.expand and menu.expand[row_index] and (menu.expand[row_index] > 0) ) 
			table.insert(menu.exp_ret, row_index, (isExpanded and 1) or 0)
			table.remove(menu.exp_ret, row_index+1)
			local cells = {}
			local ExpandButtonLabel = (isExpanded and "-") or "+"
			local ExpandScript = 	function (rowIdx, colIdx) LibMT:ToggleRow(menu, rowIdx, false, true) end
			local Label = tostring(homebase_key)
			local label2, zone, sector, system = "", "", "", ""
			if Label ~= "none" then
				zone, sector, system = GetComponentData(homebases[homebase_key][1], "zone", "sector", "cluster" )
			end
			label2 = system .. " - " .. sector .. " - " .. zone
			table.insert(cells, LibMT:ButtonCell(ExpandButtonLabel, ExpandScript, 1, nrOfChildRows > 0))
			table.insert(cells, LibMT:Cell(Label, nil, 1))
			table.insert(cells, LibMT:Cell(label2, nil, 4))
			table.insert(row_collection, LibMT:Row(cells, { "station", "none" }, Helper.defaultHeaderBackgroundColor, false, nrOfChildRows))
			-- Set initial expand states
			menu.rows = row_collection
			if isExpanded and menu.expand and menu.expand[row_index] > 0 then
				LibMT:ExpandRow(menu, #row_collection, true, true)
			elseif menu.expand then
				LibMT:CollapseRow(menu, #row_collection, true, true)
			end

			-- Child entries (ships)
			if isExpanded then
				for i,ship in ipairs(sorted_ships[homebase_key]) do
					row_index = row_index + 1
					local cells = {}
					local isExpanded = LibMT:IsExpanded(menu, #row_collection + 1) or (menu.expand and menu.expand[row_index] and menu.expand[row_index] > 0)
					table.insert(menu.exp_ret, row_index, (isExpanded and 1) or 0)
					table.remove(menu.exp_ret, row_index+1)
					local crew = ship[2]
					local nrOfChildRows = #crew
					local ExpandButtonLabel = (isExpanded and "-") or "+"
					local ExpandScript = 	function (rowIdx, colIdx) LibMT:ToggleRow(menu, rowIdx, false, true) end
					table.insert(cells, LibMT:ButtonCell(ExpandButtonLabel, ExpandScript, 1, nrOfChildRows > 0))
					table.insert(cells, LibMT:Cell( "    " .. GetComponentData(ship[1][1], "name"), nil, 2))
					local activity = ReadText(150402,112)						-- "None"
					if ship[1][8] == 1 then activity = ReadText(1002,1005) end	-- "Trading"
					if ship[1][8] == 2 then activity = ReadText(150402,113) end	-- "Mining"
					table.insert(cells, LibMT:Cell(tostring(range[ship[1][5]]), nil, 1))
					table.insert(cells, LibMT:Cell(activity, nil, 1))
					table.insert(cells, LibMT:Cell(ship[1][11], nil, 1))
					table.insert(row_collection, LibMT:Row(cells, { "ship", ship }, Helper.defaultHeaderBackgroundColor, false, nrOfChildRows))
					-- Set initial expand states
					menu.rows = row_collection
					if isExpanded and menu.expand and menu.expand[row_index] > 0 then
						LibMT:ExpandRow(menu, #row_collection, true, true)
						table.insert(menu.exp_ret, row_index, 1)
					elseif menu.expand then
						LibMT:CollapseRow(menu, #row_collection, true, true)
					end
					-- Get crew and display in dropdown
					if isExpanded then
						for i, crewmember in ipairs(crew) do
							local cells = {}
							table.insert(cells, LibMT:Cell("", nil, 1))
							local crew_name = GetComponentData(crewmember, "name")
							table.insert(cells, LibMT:Cell( "        " .. crew_name, nil, 1))
							local crew_type = GetComponentData(crewmember, "typename")
							local entity_type = GetComponentData(crewmember, "typestring")
							table.insert(cells, LibMT:Cell( crew_type, nil, 1))
							local crewlog = GetNPCBlackboard(crewmember, "$XRCLS")
							-- Calculate rank from xp level
							local rank = ReadText(150402,44)  -- "No rank"
							if crewlog then
								if entity_type == "commander" then
									rank = LibMT.Ranks[1][LibMT.get_entity_rank(crewlog[4])]
								elseif entity_type == "defencecontrol" then
									rank = LibMT.Ranks[2][LibMT.get_entity_rank(crewlog[4])]
								elseif entity_type == "engineer" then
									rank = LibMT.Ranks[3][LibMT.get_entity_rank(crewlog[4])]
								else
									rank = ReadText(150402,44)   -- "No Rank"
								end
							end
							table.insert(cells, LibMT:Cell( rank, nil, 1))
							local skill = Helper.round(GetComponentData(crewmember, "combinedskill")/20, 0)
							table.insert(cells, LibMT:Cell( Utility.createStarsText(skill), nil, 2))
							table.insert(row_collection, LibMT:Row(cells, { "crew", crewmember, crewlog }, Helper.defaultHeaderBackgroundColor, false, 0))
						end
					end
				end
			end
		end
	else
		local cells = {}
		table.insert(cells, LibMT:Cell( "No Ships", nil, 6))
		table.insert(row_collection, LibMT:Row(cells, { "none" }, Helper.defaultHeaderBackgroundColor, false, 0))
	end

	menu.rows = row_collection
	-- Add our unassigned crew at the very end
	if 0 < #unassigned_crew then
		row_index = row_index + 1
		stationctr = stationctr + 1
		-- Header row
		local nrOfChildRows = 0
		for _,v in ipairs(unassigned_crew) do
			nrOfChildRows = nrOfChildRows + 1
		end
		local isExpanded = LibMT:IsExpanded(menu, #row_collection + 1) or (menu.expand and menu.expand[row_index] and (menu.expand[row_index] > 0) ) 
		table.insert(menu.exp_ret, row_index, (isExpanded and 1) or 0)
		table.remove(menu.exp_ret, row_index+1)
		local cells = {}
		local ExpandButtonLabel = (isExpanded and "-") or "+"
		local ExpandScript = 	function (rowIdx, colIdx) LibMT:ToggleRow(menu, rowIdx, false, true) end
		local Label = ReadText(150402,29) -- "Unassigned Crew Members"
		table.insert(cells, LibMT:ButtonCell(ExpandButtonLabel, ExpandScript, 1, nrOfChildRows > 0))
		table.insert(cells, LibMT:Cell(Label, nil, 5))
		table.insert(row_collection, LibMT:Row(cells, { "unusedcrew", "none" }, Helper.defaultHeaderBackgroundColor, false, nrOfChildRows))
		-- Set initial expand states
		menu.rows = row_collection
		if isExpanded and menu.expand and menu.expand[row_index] > 0 then
			LibMT:ExpandRow(menu, #row_collection, true, true)
		elseif menu.expand then
			LibMT:CollapseRow(menu, #row_collection, true, true)
		end
		-- Get crew and display in dropdown
		if isExpanded then
			for i, crewmember in ipairs(unassigned_crew) do
				local cells = {}
				table.insert(cells, LibMT:Cell("", nil, 1))
				local crew_name = GetComponentData(crewmember, "name")
				table.insert(cells, LibMT:Cell( "      " .. crew_name, nil, 1))
				local crew_type = GetComponentData(crewmember, "typename")
				local entity_type = GetComponentData(crewmember, "typestring")
				table.insert(cells, LibMT:Cell( crew_type, nil, 1))
				local crewlog = GetNPCBlackboard(crewmember, "$XRCLS")
				-- Calculate rank from xp level
				local rank = ReadText(150402,44)  -- "No rank"
				if crewlog then
					if entity_type == "commander" then
						rank = LibMT.Ranks[1][LibMT.get_entity_rank(crewlog[4])]
					elseif entity_type == "defencecontrol" then
						rank = LibMT.Ranks[2][LibMT.get_entity_rank(crewlog[4])]
					elseif entity_type == "engineer" then
						rank = LibMT.Ranks[3][LibMT.get_entity_rank(crewlog[4])]
					else
						rank = ReadText(150402,44)   -- "No Rank"
					end
				end
				table.insert(cells, LibMT:Cell( rank, nil, 1))
				local skill = Helper.round(GetComponentData(crewmember, "combinedskill")/20, 0)
				table.insert(cells, LibMT:Cell( Utility.createStarsText(skill), nil, 2))
				table.insert(row_collection, LibMT:Row(cells, { "notcrew", crewmember, crewlog }, Helper.defaultHeaderBackgroundColor, false, 0))
			end
		end
	end
	
	
	-- deal with row changes here
	menu.rows = row_collection
	menu.expand = nil

--[[
	if menu.expandStates then
		for i, state in ipairs(menu.expandStates) do
			DebugError( " Expand state = " .. tostring( state.expanded ) .. 
						"\nChild states = " .. tostring( state.childStates ) .. 
						"\nNum Child rows = " .. tostring( state.nrOfChildRows ) .. 
						"\nTotal Rows - " .. tostring( state.rowsTotal ) )
			for j, child in ipairs(state.childStates) do
				DebugError( "    Child Expand = " .. tostring( child.expanded ) .. 
					"\n    Child states = " .. tostring( child.childStates ) .. 
					"\n    Num Child rows = " .. tostring( child.nrOfChildRows ) .. 
					"\n    Total Rows - " .. tostring( child.rowsTotal ) )

			end
		end
	end
--]]
		-- create the body descriptor
	if first then
		menu.toprow = menu.param[1]
		menu.selrow = menu.param[2]
	end
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, true, false, headerHeight + 9, bodyHeight - 3, menu.toprow, menu.selrow )
	menu.toprow = nil
	menu.selrow = nil

	-- setup the button section view
	menu.buttons = {}
	-- Setup the button bar
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton(ReadText(1001,2669), Buttons.Back, function () return true end, "INPUT_STATE_DETAILMONITOR_B" ))
	table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,409), Buttons.AdminLog, function () return true end, "INPUT_STATE_DETAILMONITOR_BACK" ))
	table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,45), Buttons.Train, Availability.Train, "INPUT_STATE_DETAILMONITOR_Y" ))
	table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,46), Buttons.Select, Availability.Select, "INPUT_STATE_DETAILMONITOR_X" ))
	
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
		LibMT:CheckButtonBarAvailability(menu, row, rowdata)
		local label = ""	
		if rowdata[1] == "crew" then
			if rowdata[3] ~= nil then
				local xp = rowdata[3][4]
				local xptospend = rowdata[3][5]
 				label = ReadText(150402,47) .. ": " .. ConvertIntegerString(xptospend, true, 4, true) -- "Crew member has a service record - eXPerience Points available to spend
			else
				label = ReadText(150402,48)  -- "Crew member does not have a service record"
			end
		end
		if rowdata[1] == "notcrew" then
			local entity = rowdata[2]
			local container = GetContextByClass(entity, "container", false)
			label = ReadText(150402,30) .. ":  " .. GetComponentData(container, "name")    --  "CLS crew currently serving on non-cls vessel"
		end
		Helper.updateCellText(menu.infotable, 3, 1, label, nil)			
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
	end
	return
end

-- Callback function for back button
Buttons.Back = function()
	-- Get our expanded state for passing back
	local toprow, selrow, exp_tab = Utility:GetExpandState()
	local expand_state = {toprow, selrow, menu.exp_ret}
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_back", { 1, 2, {}, expand_state })
	menu.cleanup()
	return
end

-- Callback function for Train button
Buttons.Train = function()
	local toprow, selrow, exp_tab = Utility:GetExpandState()
	local expand_state = {toprow, selrow, menu.exp_ret}
	local crew = menu.selectedRow.data
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_crewskills", { 0, 0, crew, expand_state, {}, {} })
	menu.cleanup()
	return
end

-- Callback function for Admin Log button
Buttons.AdminLog = function()
	local toprow, selrow, exp_tab = Utility:GetExpandState()
	local expand_state = {toprow, selrow, menu.exp_ret}
	local ship = menu.selectedRow.data
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_adminlog", { 0, 0, {}, expand_state, {}, {}, {} })
	menu.cleanup()
	return
end

-- Callback function for Ship Log Report button
Buttons.Select = function()
	local toprow, selrow, exp_tab = Utility:GetExpandState()
	local expand_state = {toprow, selrow, menu.exp_ret}
	local ship = menu.selectedRow.data[2][1]
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_shiplog", { 0, 0, {}, expand_state, {}, {}, ship })
	menu.cleanup()
	return
end

-- Availability provider for Report button
Availability.Select = function(menu, rowIdx, rowData)
	return rowData[1] == "ship"
end

-- Availability provider for Train button
Availability.Train = function(menu, rowIdx, rowData )
	return (rowData[1] == "crew" or rowData[1] == "notcrew") and rowData[3] ~= nil
end

-- Returns an array of expanded states and desired rows
Utility.GetExpandState = function()
	local expand_state_table = {}
	if menu.expandStates then
		for i, exp_state in ipairs(menu.expandStates) do
			if exp_state.expanded then
				table.insert(expand_state_table, 1)
			else
				table.insert(expand_state_table, 0)
			end	
		end
	end
	local toprow = GetTopRow(menu.defaulttable)
	local selrow = Helper.currentDefaultTableRow
	return toprow, selrow, expand_state_table
end

Utility.createStarsText = function(skillvalue)
	local stars = string.rep("*", skillvalue) .. string.rep("", 5 - skillvalue)
	return Helper.createFontString(stars, false, "left", 255, 255, 0, 100, Helper.starFont, 16)
end

init()

return
