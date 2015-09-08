--[[	Manages the list waypoint screen for the MT Station Logistics mod
		Version:		1.0.0
		Last Update:	2014-12-13
 --]]
 
local Buttons, Availability = {}, {}

-- Set up the default menu table
local menu = {	name = "gMT_Station_Logistics_ListWaypoints",
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
--	menu.faction = nil
--	menu.title = nil
--	menu.subtitle = nil
--	menu.subtitle2 = nil
--	menu.subtitle3	= nil
--	menu.ret_arg = nil
--	menu.ship = nil
--	menu.homebase = nil
--	menu.cargolist = nil
--	menu.waypoints = nil
--	menu.wp_paste_buffer = nil
--	menu.trader = nil
--	menu.crewscore = nil
--	menu.level = nil
--	menu.maxwaypoints = nil
--	menu.logindex = nil
	menu.buttons = nil
	menu.wplist = nil
	return
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	menu.wplist = {}
	-- Get the passed parameters
	menu.toprow = menu.param[1]
	menu.selrow = menu.param[2]
	
	menu.wplist.action = menu.param[4][4]
	menu.wplist.trader = menu.param[6]
	menu.wplist.waypoint = menu.param[7] or {}    -- collects return from WP edit menu
	
	menu.wplist.ret_arg = { menu.param[4][1],menu.param[4][2],menu.param[4][3], menu.wplist.action } -- Return parameters if required
	
	-- setup various variables used in the menu
	menu.wplist.title = ReadText(150402,21)				-- menu.title = "MT Station Logistics - Administration"
	menu.wplist.subtitle = ReadText(150402,161)			-- menu.title = "Waypoint Management"
	
--	menu.wplist.waypointType = { "No Action", "Load", "Unload", "Buy", "Sell", "Fly to", "Refuel" }
	menu.wplist.waypointType = { ReadText(150402,167), ReadText(150402,168), ReadText(150402,169), 
									ReadText(1001,2916), ReadText(1001,2917), ReadText(150402,170), ReadText(1002,2027) }

	menu.wplist.ship = menu.wplist.trader[1]
	menu.wplist.homebase = menu.wplist.trader[2]
	menu.wplist.cargolist = menu.wplist.trader[3]
	menu.wplist.waypoints = menu.wplist.trader[4]
	menu.wplist.level = menu.wplist.trader[5]
	menu.wplist.crewscore = menu.wplist.trader[6]
	menu.wplist.log = menu.wplist.trader[7]
	menu.wplist.activity = menu.wplist.trader[8]
	menu.wplist.stats = menu.wplist.trader[9]
	menu.wplist.index = menu.wplist.trader[10]
	menu.wplist.numwp = menu.wplist.trader[11]
	menu.wplist.tracklog = {} -- empty unless in reporting tracking menu
	menu.wplist.DbgLvl = menu.wplist.trader[13]									-- Debug level for this ship
	menu.wplist.Track = menu.wplist.trader[14]										-- True if ship is being tracked
	
	
	-- Deal with add or edit WP here
	if menu.wplist.action == "addwaypoint" then
		-- add a new waypoint
		table.insert(menu.wplist.waypoints, menu.wplist.waypoint[1], menu.wplist.waypoint)
		-- resync waypoint indices
		for i, wp in ipairs(menu.wplist.waypoints) do
			wp[1] = i
		end
	elseif menu.wplist.action == "editwaypoint" then
		-- replace old with edited version
		table.remove(menu.wplist.waypoints, menu.wplist.waypoint[1])
		table.insert(menu.wplist.waypoints, menu.wplist.waypoint[1], menu.wplist.waypoint)
	end
	
	-- Clip maximum waypoints allowed 
	menu.wplist.maxwaypoints = 10
	if menu.wplist.level > 1 and menu.wplist.level < 3 then
		menu.wplist.maxwaypoints = 20
	elseif menu.wplist.level > 2 then
		menu.wplist.maxwaypoints = 40
	end
	
	-- Deal with lists that are too long because crew has been changed for a lower skilled crew 
	-- Routine to check here for crew changes causing change in validity of WP list
	local checkcount = 0 -- keep count of number of valid wps found in list
	for i, waypoint in ipairs(menu.wplist.waypoints) do
		if waypoint[9] <= menu.wplist.level then  -- valid waypoint
			menu.wplist.waypoints[i][10] = 0 			-- Set as valid
			checkcount = checkcount + 1
			if checkcount > menu.wplist.maxwaypoints then
				menu.wplist.waypoints[i][10] = 1
			end
		else
			menu.wplist.waypoints[i][10] = 1			-- Flag waypoint as invalid
		end
	end
--	DebugError( "MT Logistics Captain Score:  " .. captainscore .. "  DO Score:  " .. defencescore .. "  Engineer score:  " ..  engineerscore .. "  Crew Score  " .. crewscore .. " Crew Level:  " .. level)


	-- display our menu
	menu.selectedRow = { idx = menu.selrow, data = {} }
	menu.display( true )
	return
end

-- Main screen redraw function
menu.display = function ( first )	
	Helper.removeAllButtonScripts(menu)

	-- Setup the header block
	local homebase = ""
	if menu.wplist.homebase == "none" then
		homebase = ReadText(150402,162) else homebase = GetComponentData(menu.wplist.homebase, "name") -- "None Selected" or homebase name
	end
	local title = {
			Helper.createFontString(
			menu.wplist.title .. " - " .. menu.wplist.subtitle, -- the main title text of our window
			false, 											-- don't scale the text
			"left", 										-- horizontal alignment
			255, 255, 255, 100,								-- The text colour R,G,B,Alpha 
			Helper.headerRow1Font, 							-- The predefined row 1 font
			Helper.headerRow1FontSize, 						-- The predefined row 1 font size (see detailmonitorhelper\helper.lua
			false, 											-- Don't wrap the text
			Helper.headerRow1Offsetx, 						-- Predefined x offset
			Helper.headerRow1Offsety, 						-- Predefined y offset
			Helper.headerRow1Height, 						-- Predefined row 1 height
			Helper.headerRow1Width)							-- Predefined row 1 width
	}
	local colWidths = { Helper.standardTextHeight, 60, 100, 100, 100, 300, 75, 0 }
	local additional_rows = {}
	local cells ={}
--	local subtitle2 = "Selected Ship: " .. GetComponentData(menu.wplist.ship, "name") .. " -- Homebase Station: " .. homebase
	local subtitle2 = ReadText(150402,173) .. ": " .. GetComponentData(menu.wplist.ship, "name") .. " -- " .. ReadText(150402,174) .. ": " .. homebase
	
	-- Info row
	local function text_fmt( text )
		return Helper.createFontString( text, false, "left", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize, 
				false, Helper.headerRow2Offsetx, Helper.headerRow2Offsety, Helper.headerRow2Height, Helper.headerRow1Width )
	end
	table.insert(cells, LibMT:Cell(text_fmt(""), nil, #colWidths))
	table.insert(additional_rows, LibMT:Row( cells, {}, Helper.defaultHeaderBackgroundColor, true, 0))
	local cells = {}
	table.insert(cells, LibMT:Cell(text_fmt(""), nil, #colWidths))
	table.insert(additional_rows, LibMT:Row( cells, {}, Helper.defaultHeaderBackgroundColor, true, 0))

	-- Fixed header column
	local cells = {}
	table.insert(cells, LibMT:Cell(text_fmt(""), nil, 1))
	table.insert(cells, LibMT:Cell(text_fmt(""), nil, 1))
	table.insert(cells, LibMT:Cell(text_fmt(ReadText(150402,163)), nil, 1))				-- "WP Type"
	table.insert(cells, LibMT:Cell(text_fmt(ReadText(150402,164)), nil, 1))				-- "Min"
	table.insert(cells, LibMT:Cell(text_fmt(ReadText(1001,19)), nil, 1))				-- "Max"
	table.insert(cells, LibMT:Cell(text_fmt(ReadText(1001,45)), nil, 1))				-- "Ware"
	table.insert(cells, LibMT:Cell(text_fmt(ReadText(1001,1302)), nil, 1))				-- "Range"
	table.insert(cells, LibMT:Cell(text_fmt(ReadText(150402,165)), nil, 1))				-- "Active?"
	table.insert(additional_rows, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, true, 0))

	local infodesc, headerHeight = LibMT.create_column_header( menu, title, {subtitle2}, additional_rows, colWidths, {#colWidths} )

	-- setup the waypoints list
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local cells = {}
	for i, waypoint in ipairs(menu.wplist.waypoints) do
		local function text_fmt( text, wp_state )
			if wp_state == 0 then
				return Helper.createFontString( text, false, "left", 255, 255, 255, 100, Helper.standardFont, Helper.standardFontSize, 
														false, Helper.headerRow2Offsetx, Helper.headerRow2Offsety, Helper.headerRow2Height, Helper.headerRow1Width )
			else
				return Helper.createFontString( text, false, "left", 255, 0, 0, 100, Helper.standardFont, Helper.standardFontSize, 
														false, Helper.headerRow2Offsetx, Helper.headerRow2Offsety, Helper.headerRow2Height, Helper.headerRow1Width )
			end
		end
		local wp_state = waypoint[10]
		cells = {}
		table.insert(cells, LibMT:Cell( text_fmt("",wp_state), nil, 1))
		table.insert(cells, LibMT:Cell( text_fmt("WP: " .. tostring(i), wp_state), nil, 1))
		local station = ReadText(150402,166)										-- "No Station Selected"
		if (type(waypoint[3]) ~= "string") and IsComponentClass( waypoint[3], "station") then
			station = GetComponentData( waypoint[3], "name")
		end
		local label = menu.wplist.waypointType[waypoint[4]] or ReadText(150402,112) -- "None"
		table.insert(cells, LibMT:Cell( text_fmt(label,wp_state), nil, 1))


		local label = waypoint[6] or ReadText(150402,112) -- "None"
		table.insert(cells, LibMT:Cell( text_fmt(label,wp_state), nil, 1))
		local label = waypoint[7] or ReadText(150402,112) -- "None"
		table.insert(cells, LibMT:Cell( text_fmt(label,wp_state), nil, 1))
		local label = ReadText(150402,162) -- "None Selected"	
		if waypoint[5] ~= "None Selected" then -- TODO Check for no compare with readtext
			label = GetWareData(waypoint[5], "name") or ReadText(150402,162) -- "None Selected"
		end
		table.insert(cells, LibMT:Cell( text_fmt(label,wp_state), nil, 1))
		-- Range
		local range = { ReadText(20001,201), ReadText(20001,101), ReadText(20001,901)  }	-- local range = { "Sector", "System", "Galaxy" }
		table.insert(cells, LibMT:Cell(text_fmt(range[waypoint[9]],wp_state), nil, 1))
		-- Active?
--		local active = { "No", "Yes" }
		local active = { ReadText(1001,2618), ReadText(1001,2617) }
		if waypoint[10] == 0 then
			table.insert(cells, LibMT:Cell(   text_fmt(active[ waypoint[2] + 1 ], wp_state)    , nil, 1))
		else
--			table.insert(cells, LibMT:Cell(  Helper.createFontString(ReadText(150402,171), false, "left", 255, 0, 0, 100) , nil, 1))	-- "Locked"
			table.insert(cells, LibMT:Cell(  text_fmt(ReadText(150402,171),wp_state)  , nil, 1))	-- "Locked"
		end
		table.insert(row_collection, LibMT:Row(cells, { "exists", waypoint}, Helper.defaultHeaderBackgroundColor, false, 0))
	end
	
	local cells = {}
	table.insert(cells, LibMT:Cell( ReadText(150402,172), nil, 8))	-- "Add New Waypoint"
	table.insert(row_collection, LibMT:Row(cells, {"Add New Waypoint", { "", "","", "","", "","", "","", "","", "",}}, Helper.defaultHeaderBackgroundColor, false, 0))

	-- Build the table descriptor
	local colWidths = { Helper.standardTextHeight, 60, 100, 100, 100, 300, 75, 0 }
	if first then
		menu.toprow = menu.param[1]
		menu.selrow = menu.param[2]
	end
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, true, false, headerHeight - 14, bodyHeight, menu.toprow, menu.selrow )
	menu.toprow = nil
	menu.selrow = nil

	-- Setup the button bar
	menu.buttons = {}

	table.insert(menu.buttons, LibMT:BarButton( ReadText(150402,245), Buttons.MoveUp, Availability.MoveUp,""))
	table.insert(menu.buttons, LibMT:BarButton( ReadText(150402,246), Buttons.MoveDown, Availability.MoveDown,""))
	table.insert(menu.buttons, LibMT:BarButton( ReadText(150402,247), Buttons.Cut, Availability.Cut,""))
	table.insert(menu.buttons, LibMT:BarButton( ReadText(150402,248), Buttons.Paste, Availability.Paste,""))
	table.insert(menu.buttons, LibMT:BarButton( ReadText(1001,2669), Buttons.Back, function () return true end,"INPUT_STATE_DETAILMONITOR_B"))
	table.insert(menu.buttons, LibMT:BarButton( ReadText(150402,222), Buttons.AddWaypoint, Availability.AddWaypoint,"INPUT_STATE_DETAILMONITOR_BACK"))
	table.insert(menu.buttons, LibMT:BarButton( ReadText(150402,221), Buttons.EditWaypoint, Availability.EditWaypoint, "INPUT_STATE_DETAILMONITOR_Y"))
	table.insert(menu.buttons, LibMT:BarButton( ReadText(150402,244), Buttons.Done, Availability.Done, "INPUT_STATE_DETAILMONITOR_X" )) -- "Save"

	local buttondesc = LibMT.create_standard_button_bar( menu, menu.buttons, headerHeight, bodyHeight )

	-- build and display the view
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false)

	-- finally, we call all the script attaching functions
	for _, func in ipairs(cell_scripts) do
		func()
	end

	menu.rows = row_collection

	Helper.releaseDescriptors()
	return 
end

-- standard function stub to handle changing row
menu.onRowChanged = function (row, rowdata, rc_table)
	if rc_table == menu.defaulttable then
		menu.wplist.waypoint_index = row
		menu.selectedRow.idx = row
		menu.selectedRow.data = rowdata
		local label, ware = "", ReadText(150402,162)  -- "None Selected"
		if menu.wplist.wp_paste_buffer then
			if menu.wplist.wp_paste_buffer[5] ~= ReadText(150402,162) then  -- "None Selected"
				ware = GetWareData(menu.wplist.wp_paste_buffer[5], "name")
			end
			label = ( ReadText(150402,249) .. ": " 	.. menu.wplist.wp_paste_buffer[1] .. " - " 							-- "Paste Buffer"
										.. (GetComponentData(menu.wplist.wp_paste_buffer[3], "name") or "") .. " - "   
										.. menu.wplist.waypointType[menu.wplist.wp_paste_buffer[4]] .. " - " 
										.. menu.wplist.wp_paste_buffer[6] .. " - "   
										.. menu.wplist.wp_paste_buffer[7] .. " - "   
										.. ware 
										) or ""
		else
			label = ReadText(150402,250)		-- "Paste Buffer empty"
		end
		Helper.updateCellText(menu.infotable, 3, 1, label, nil)
		local station, zone, sector, cluster = "", "", "", ""
	
		if rowdata[1] == ReadText(150402,172) then    -- "Add New Waypoint"
			station = "" 
		elseif type(rowdata[2][3]) == "string" then
			station = rowdata[2][3]
		else
			station, zone, sector, cluster = GetComponentData( rowdata[2][3], "name", "zone", "sector", "cluster")
		end
		Helper.updateCellText(menu.infotable, 4, 1, ReadText(150402,251) .. ":-  " .. station .. "  -  " .. cluster .. "/" .. sector .. "/" .. zone , nil) -- "Waypoint Station"

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
	end
	return
end

-- Callback for move up button
Buttons.MoveUp = function ()
	local temp_wp = table.remove( menu.wplist.waypoints, menu.wplist.waypoint_index )
	table.insert( menu.wplist.waypoints, menu.wplist.waypoint_index - 1, temp_wp )

	-- resync waypoint indices
	for i, wp in ipairs(menu.wplist.waypoints) do
		wp[1] = i
	end

	menu.toprow = GetTopRow(menu.defaulttable)
	menu.selrow = menu.selectedRow.idx - 1

	if menu.toprow >= menu.selrow then
		menu.toprow = menu.selrow - 1
	end
	
	
	menu.display()
end

-- Callback for move down button
Buttons.MoveDown = function ()
	local temp_wp = table.remove( menu.wplist.waypoints, menu.wplist.waypoint_index )
	table.insert( menu.wplist.waypoints, menu.wplist.waypoint_index + 1, temp_wp )
	-- re-sync waypoint indices
	for i, wp in ipairs(menu.wplist.waypoints) do
		wp[1] = i
	end
	menu.toprow = GetTopRow(menu.defaulttable)
	menu.selrow = menu.selectedRow.idx + 1
	if menu.selrow > 8 then
		menu.toprow = menu.selrow - 8
	end
	menu.display()
end

-- Callback for the cut button
Buttons.Cut = function (menu, rowIdx, rowData)
	-- replace old buffer value with deleted waypoint
	if rowData[2][10] == 0 then
		menu.wplist.wp_paste_buffer = table.remove(menu.wplist.waypoints, menu.wplist.waypoint_index)
	else -- deal with cutting invalid waypoint
		table.remove(menu.wplist.waypoints, menu.wplist.waypoint_index)
		menu.wplist.wp_paste_buffer = nil
	end
	-- re-sync waypoint indices
	for i, wp in ipairs(menu.wplist.waypoints) do
		wp[1] = i
	end
	if menu.wplist.waypoint_index > #menu.wplist.waypoints then
		menu.wplist.waypoint_index = #menu.wplist.waypoints
	end
	menu.toprow = GetTopRow(menu.defaulttable)
	menu.selrow = menu.wplist.waypoint_index
	if menu.toprow >= menu.selrow then
		menu.toprow = menu.selrow - 1
	end
	menu.display()
end

-- Callback for the paste button
Buttons.Paste = function ()
	if menu.wplist.wp_paste_buffer then
		if menu.wplist.waypoint_index < 1 then menu.wplist.waypoint_index = 1 end
		-- need to make a proper copy of the wp buffer to cope with multiple pastes
		temp_wp = LibMT.deepcopy(menu.wplist.wp_paste_buffer)
		table.insert(menu.wplist.waypoints, menu.wplist.waypoint_index, temp_wp)
		
		-- resync waypoint indices
		for i, wp in ipairs(menu.wplist.waypoints) do
			wp[1] = i
		end
		menu.toprow = GetTopRow(menu.defaulttable)
		menu.selrow = menu.wplist.waypoint_index

		if menu.toprow >= menu.selrow then
			menu.toprow = menu.selrow - 1
		end
		menu.display()
	end
end

-- Callback function for back button
Buttons.Back = function ()
	menu.wplist.ret_arg[4] = "nochanges"
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_configreturn", { 0, 0, {}, menu.wplist.ret_arg, {}, menu.wplist.trader, {} })
	menu.cleanup()
	return
end

-- Callback function for select button
Buttons.Done = function()
	menu.wplist.trader = {}
	table.insert( menu.wplist.trader, menu.wplist.ship )
	table.insert( menu.wplist.trader, menu.wplist.homebase )
	table.insert( menu.wplist.trader, menu.wplist.cargolist )		-- Ship cargo analysis table
	table.insert( menu.wplist.trader, menu.wplist.waypoints )		-- Ship waypoint list
	table.insert( menu.wplist.trader, menu.wplist.level )			-- crew level
	table.insert( menu.wplist.trader, menu.wplist.crewscore )		-- crew score
	table.insert( menu.wplist.trader, menu.wplist.log )				-- log list
	table.insert( menu.wplist.trader, menu.wplist.activity )		-- current activity
	table.insert( menu.wplist.trader, menu.wplist.stats )			-- ship stats
	table.insert( menu.wplist.trader, menu.wplist.index )			-- trader index
	table.insert( menu.wplist.trader, #menu.wplist.waypoints )		-- number of waypoints
	table.insert( menu.wplist.trader, {} )							-- empty unless in reporting tracking menu
	table.insert( menu.wplist.trader, menu.wplist.DbgLvl )			-- debug level
	table.insert( menu.wplist.trader, menu.wplist.Track )			-- true (1) if tracking
	menu.wplist.ret_arg[4] = "updateship"
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_configreturn", { 0, 0, {}, menu.wplist.ret_arg, {}, menu.wplist.trader, {}  })
	menu.cleanup()
	return
end

-- Callback function for Add Waypoint button
Buttons.AddWaypoint = function ()
	local toprow = GetTopRow(menu.defaulttable)
	local selrow = Helper.currentDefaultTableRow  -- menu.wplist.waypoint_index
--	local new_waypoint = { menu.wplist.waypoint_index, 1, "None", "No Action", "None Selected", 0, 0, 0, 0, 0 } --  { index, valid, dest, wp_type, ware, min, max amount, price, range, activity override}
	local new_waypoint = { menu.wplist.waypoint_index, 1, ReadText(150402,112), ReadText(150402,167), ReadText(150402,162), 0, 0, 0, 0, 0 } 
											--  { index, valid, dest, wp_type, ware, min, max amount, price, range, activity override}
	menu.wplist.ret_arg[4] = "addwaypoint"
	Helper.closeMenuForSection(menu, false, "gMT_WPListMenu_editwaypoint", { toprow, selrow, {}, menu.wplist.ret_arg, {}, menu.wplist.trader, new_waypoint })
	menu.cleanup()
	return
end

-- Callback function for Edit Waypoint button
Buttons.EditWaypoint = function()
	local toprow = GetTopRow(menu.defaulttable)
	local selrow = Helper.currentDefaultTableRow  -- menu.wplist.waypoint_index
	local selected_waypoint = menu.wplist.waypoints[menu.wplist.waypoint_index]
	menu.wplist.ret_arg[4] = "editwaypoint"
	Helper.closeMenuForSection(menu, false, "gMT_WPListMenu_editwaypoint", { toprow, selrow, {}, menu.wplist.ret_arg, {}, menu.wplist.trader, selected_waypoint })
	menu.cleanup()
	return
end

-- Function to set move up button active or not
Availability.MoveUp = function( menu, row, rowdata)
	return (rowdata[1] ~= "Add New Waypoint") and (row > 1)	
end

-- Function to set move up button active or not
Availability.MoveDown = function( menu, row, rowdata)
	return (rowdata[1] ~= "Add New Waypoint") and (row < #menu.wplist.waypoints)	
end

-- Function to set cut button active or not
Availability.Cut = function( menu, row, rowdata)
	return (rowdata[1] ~= "Add New Waypoint") and ( #menu.wplist.waypoints > 0 )	
end

-- Function to set paste button active or not
Availability.Paste = function ( menu, row, rowdata )
	return menu.wplist.wp_paste_buffer ~= nil and #menu.wplist.waypoints < menu.wplist.maxwaypoints
end

-- Function to set add waypoint button active or not
Availability.AddWaypoint = function (menu, row, rowdata)
--	return rowdata[1] == "Add New Waypoint"
	return #menu.wplist.waypoints < menu.wplist.maxwaypoints
end

-- Function to set edit waypoint button active or not
Availability.EditWaypoint = function (menu, row, rowdata)
	return (rowdata[1] ~= "Add New Waypoint") and (#menu.wplist.waypoints > 0) and rowdata[2][10] == 0
end

-- Function to set select button active or not
Availability.Done = function(menu, row, rowdata)
	return true
end

init()

return
