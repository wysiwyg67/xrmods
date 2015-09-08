-- Manages Waypoint Configuration for MT Station Logistics mod
 
-- GLOBALS
-- List of waypoint types

 
-- Set up the default menu table
local menu = {	name = "gMT_Station_Logistics_EditWaypoint",
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

	return
end

-- Standard Menu cleanup utility - place all variables no longer needed in here and assign the value nil to them
menu.cleanup = function ()
--	menu.updateInterval = nil
--	menu.title = nil
--	menu.subtitle = nil
--	menu.subtitle2 = nil
--	menu.subtitle3 = nil
--	menu.ret_arg = nil
--	menu.waypointType = nil
--	menu.revwaypointType = nil
--	menu.selectedWPType = nil
--	menu.selectedModifier = nil
--	menu.modifierType = nil
--	menu.infotable = nil
--	menu.selecttable = nil
--	menu.buttontable = nil
--	menu.waypoint = nil
--	menu.wp_station = nil
--	menu.ware = nil
--	menu.temp = nil
--	menu.trader = nil
--	menu.warelist = nil
--	menu.cargo = nil
--	menu.homebase = nil
--	menu.wprange = nil
	menu.buttons = nil
	menu.bool = nil
	menu.ware = nil
	menu.wpedit = nil
	return
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.bool = 				{} -- empty table for grouping our menu switches
	menu.ware = 				{}
	menu.wpedit = 				{} 
	
	menu.toprow = 				menu.param[1]
	menu.selrow = 				menu.param[2]
	menu.wpedit.toggle =		0
	
	menu.wpedit.ret_arg = 		menu.param[4]

	menu.wpedit.wp_action = 	menu.param[4][4] or ""
	menu.wpedit.trader = 		menu.param[6]
	menu.wpedit.waypoint = 		menu.param[7]
	menu.wpedit.warelist = 		menu.param[8] or {}
	menu.wpedit.newstation = 	menu.param[9]

	menu.wpedit.cargo = 		menu.wpedit.trader[3]
	menu.wpedit.homebase = 		menu.wpedit.trader[2]


	menu.bool.IsWPActive =		menu.wpedit.waypoint[2] or 1
	menu.wpedit.wp_station = 	menu.wpedit.waypoint[3]
	menu.ware.ware = 			menu.wpedit.waypoint[5]


	menu.bool.stationchanged = false
--	menu.wpedit.waypointType = { 	"No Action", "Load", "Unload", "Buy", "Sell", "Fly to", "Refuel" }
	menu.wpedit.waypointType = { ReadText(150402,167), ReadText(150402,168), ReadText(150402,169), 
									ReadText(1001,2916), ReadText(1001,2917), ReadText(150402,170), ReadText(1002,2027) }

--	DebugError( "Menu.param[5][5] = " .. tostring(menu.param[5][5] ) )
	if menu.wpedit.newstation then 
		-- determine if the station has been changed or not
		menu.bool.stationchanged = true
		menu.wpedit.wp_station = 	menu.wpedit.newstation
	end
	
	menu.wpedit.title = 		ReadText(150402,21)			-- menu.title = "MT Station Logistics - Administration"
	
	if menu.wpedit.wp_action == "addwaypoint" then
		menu.wpedit.subtitle = 		ReadText(150402,222)		-- "Add Waypoint"
	else
		menu.wpedit.subtitle = 		ReadText(150402,221)		-- "Edit Waypoint"
	end
	menu.wpedit.subtitle3 = ""

	Utility.RecheckMenu( menu.bool.stationchanged, true, true, true, true, true ) -- Recheck all at start
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
	local title_txt = menu.wpedit.title .. " - " .. menu.wpedit.subtitle
	local subtitle2 = ReadText(150402,173) .. ": " .. GetComponentData(menu.wpedit.trader[1], "name") .. " -- " .. ReadText(150402,174) .. ": " .. GetComponentData(menu.wpedit.trader[2], "name")
	local infodesc, headerHeight = LibMT.create_standard_header( menu, title_txt, {subtitle2}, {  }, 1,  nil, { menu.wpedit.subtitle3 })
	
	-- Setup the main body
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = {
		175,
		250,
		Helper.standardTextHeight,			-- NB Width set using height parameter to get square button
		Helper.standardTextHeight,			-- NB Width set using height parameter to get square button
		80,									-- stretch to fill row
		80, 80, 80, 0 }

		--Header row
	local cells = {}
	local header_text = { ReadText(150402,228) .. ":",  ReadText(150402,229) .. ":", "", ""}		-- "Description:",  "Action:", "", ""
	local rowData = "header"
	for _, text in pairs(header_text) do
		table.insert( cells, LibMT:Cell(text, nil, 1))
	end
	table.insert( cells, LibMT:Cell("", nil, 5))
	table.insert(row_collection, LibMT:Row(cells, rowData, menu.transparent, false, 0))

	-- Row 1 - destination selection
	local cells = {}
	table.insert( cells, LibMT:Cell(ReadText(1001,3), nil, 1))		-- "Station"
	local station = ReadText(150402,112)		-- "None"
	if menu.bool.isStationValid then
		station = GetComponentData( menu.wpedit.wp_station, "name")
	end
	table.insert( cells, LibMT:Cell((station) or ReadText(150402,112), nil, 1))		-- "None"
	table.insert( cells, LibMT:ButtonCell( "", nil, 1, false))    -- TODO: LIST OF PLAYER STATIONS FOR SELECTION??
	table.insert( cells, LibMT:ButtonCell( "", nil, 1, false))
	table.insert( cells, LibMT:ButtonCell( ReadText(150402,230), function() Buttons:SelectHomebase() end, 1, true))							-- "Home"
	table.insert( cells, LibMT:ButtonCell( ReadText(20203,1601), function(rowIdx, colIdx) Buttons:mapSelect("player") end, 1, true))		-- "Player"
	table.insert( cells, LibMT:ButtonCell( ReadText(150402,231), function(rowIdx, colIdx) Buttons:mapSelect("npc") end, 1, true))			-- "NPC"
	table.insert( cells, LibMT:Cell("", nil, 2))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 2 - Waypoint type selection
	local cells = {}
	table.insert( cells, LibMT:Cell( ReadText(150402,232), nil, 1))				-- "Waypoint Type"
	table.insert( cells, LibMT:Cell(menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]], nil, 1))
	table.insert( cells, LibMT:ButtonCell( "-", Buttons.DecWPType, 1, menu.bool.isStationValid))
	table.insert( cells, LibMT:ButtonCell( "+", Buttons.IncWPType, 1, menu.bool.isStationValid))
	table.insert( cells, LibMT:Cell("", nil, 5))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 3 - Ware Type selection
	local cells = {}
	table.insert( cells, LibMT:Cell( ReadText(150402,233), nil, 1))				-- "Ware Type"
	
	if menu.ware.selectedWareType == 1 or not menu.ware.display then
		table.insert( cells, LibMT:Cell(ReadText(150402,162), nil, 1))			-- "None Selected"
	else
		table.insert( cells, LibMT:Cell(GetWareData(menu.ware.display[menu.ware.selectedWareType], "name"), nil, 1))
	end
	
	table.insert( cells, LibMT:ButtonCell( "-", Buttons.DecWareType, 1, menu.bool.isWPTypeValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells"))
	table.insert( cells, LibMT:ButtonCell( "+", Buttons.IncWareType, 1, menu.bool.isWPTypeValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells"))
	table.insert( cells, LibMT:Cell("", nil, 5))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 4 - Minimum Amount selection
	local cells = {}
	if menu.ware.display[menu.ware.selectedWareType] == "fuelcells" then
		table.insert( cells, LibMT:Cell( ReadText(150402,234), nil, 1))			-- "If fuel left less than"
	else
		table.insert( cells, LibMT:Cell( ReadText(150402,235), nil, 1))			-- "Minimum Amount"
	end
	table.insert( cells, LibMT:Cell(menu.ware.MinAmount .. "  (" .. menu.ware.selectedMinAmount .. " % " .. ReadText(150402,236) .. ")", nil, 1)) -- "Cargo Space"
	table.insert( cells, LibMT:ButtonCell( "-", Buttons.DecModifierType, 1, menu.bool.isWareValid and not menu.bool.isFlyTo))
	table.insert( cells, LibMT:ButtonCell( "+", Buttons.IncModifierType, 1, menu.bool.isWareValid and not menu.bool.isFlyTo))
	table.insert( cells, LibMT:ButtonCell( "25%", function(rowIdx, colIdx) Buttons:SetAmount( 25, false ) end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo))    
	table.insert( cells, LibMT:ButtonCell( "50%", function(rowIdx, colIdx) Buttons:SetAmount( 50, false ) end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo))
	table.insert( cells, LibMT:ButtonCell( "75%", function(rowIdx, colIdx) Buttons:SetAmount( 75, false ) end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo))    
	table.insert( cells, LibMT:ButtonCell( ReadText(1001,19), function(rowIdx, colIdx) Buttons:SetAmount( 100, false ) end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo)) -- "Max"
	table.insert( cells, LibMT:Cell("", nil, 1))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 5 - Maximum amount selection
	local cells = {}
	table.insert( cells, LibMT:Cell( ReadText(150402,237), nil, 1)) 		-- "Maximum Amount"
	table.insert( cells, LibMT:Cell(menu.ware.DisplayAmount .. "  (" .. menu.ware.selectedAmount .. " % " .. ReadText(150402,236) .. ")", nil, 1))
	table.insert( cells, LibMT:ButtonCell( "-", Buttons.DecAmount, 1, menu.bool.isWareValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells" ))			-- TODO: Also validate on amount > 0
	table.insert( cells, LibMT:ButtonCell( "+", Buttons.IncAmount, 1, menu.bool.isWareValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells" ))			-- Add 50% and MAX buttons
	table.insert( cells, LibMT:ButtonCell( "25%", function(rowIdx, colIdx) Buttons:SetAmount( 25, true ) end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells"))    
	table.insert( cells, LibMT:ButtonCell( "50%", function(rowIdx, colIdx) Buttons:SetAmount( 50, true ) end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells"))
	table.insert( cells, LibMT:ButtonCell( "75%", function(rowIdx, colIdx) Buttons:SetAmount( 75, true ) end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells"))    
	table.insert( cells, LibMT:ButtonCell( ReadText(1001,19), function(rowIdx, colIdx) Buttons:SetAmount( 100, true ) end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells"))  -- "Max"
	table.insert( cells, LibMT:Cell("", nil, 1))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 6 - max price selection select + AVG MIN MAX BUTTONS - may need reset on ware type change
	local cells = {}
	if menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] == ReadText(1001,2916) then -- "Buy"
		table.insert( cells, LibMT:Cell( ReadText(150402,238), nil, 1))		-- "Maximum buy Price"
	elseif menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] == ReadText(1001,2917) then -- "Sell"
 		table.insert( cells, LibMT:Cell( ReadText(150402,239), nil, 1))		-- "Minimum sell Price"
	else
		table.insert( cells, LibMT:Cell("", nil, 1))
	end
	table.insert( cells, LibMT:Cell(menu.ware.Price, nil, 1))
	table.insert( cells, LibMT:ButtonCell( "-", function(rowIdx, colIdx) Buttons:DecPrice() end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells" and menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] ~= "Load" and menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] ~= "Unload"))		
	table.insert( cells, LibMT:ButtonCell( "+", function(rowIdx, colIdx) Buttons:IncPrice() end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells" and menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] ~= "Load" and menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] ~= "Unload"))
	table.insert( cells, LibMT:ButtonCell( ReadText(150402,164), function(rowIdx, colIdx) Buttons:SetPrice("min") end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells" and menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] ~= "Load" and menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] ~= "Unload"))
	table.insert( cells, LibMT:ButtonCell( ReadText(150402,240), function(rowIdx, colIdx) Buttons:SetPrice("avg") end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells" and menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] ~= "Load" and menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] ~= "Unload"))    
	table.insert( cells, LibMT:ButtonCell( ReadText(1001,19), function(rowIdx, colIdx) Buttons:SetPrice("max") end, 1, menu.bool.isWareValid and not menu.bool.isFlyTo and menu.ware.display[menu.ware.selectedWareType] ~= "fuelcells" and menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] ~= "Load" and menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] ~= "Unload"))
	table.insert( cells, LibMT:Cell( "", nil, 2))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 7 - Activate/deactivate waypoint
	local cells = {}
	table.insert( cells, LibMT:Cell( ReadText(150402,241), nil, 1))  -- "Is Waypoint Active?"
	local label = ""
	if menu.bool.IsWPActive == 0 then label = ReadText(1001,2618) else label = ReadText(1001,2617) end		-- "No" "Yes"
	table.insert( cells, LibMT:Cell(label, nil, 1))
	table.insert( cells, LibMT:ButtonCell( "", nil, 1, false))
	table.insert( cells, LibMT:ButtonCell( "", nil, 1, false))
	table.insert( cells, LibMT:ButtonCell( ReadText(150402,242), function(rowIdx, colIdx) Buttons:SetActive() end, 1, true))	-- "Change"
	table.insert( cells, LibMT:Cell("", nil, 4))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))

	-- Row 8 - Waypoint range
	local cells = {}
	table.insert( cells, LibMT:Cell( ReadText(150402,243), nil, 1))		-- "Waypoint Range"
	local range = { ReadText(20001,201), ReadText(20001,101), ReadText(20001,901)  }	-- local range = { "Sector", "System", "Galaxy" }
	local label = range[menu.wpedit.wprange]
	table.insert( cells, LibMT:Cell(label, nil, 1))
	table.insert( cells, LibMT:Cell( "", nil, 1))
	table.insert( cells, LibMT:Cell( "", nil, 1))
	table.insert( cells, LibMT:Cell("", nil, 1))
	table.insert( cells, LibMT:Cell("", nil, 4))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Build the table descriptor
	local selectdesc = LibMT.create_body( menu, row_collection, cell_scripts, colWidths, false, false, headerHeight + 8, bodyHeight )
	
	-- Setup the button bar
	menu.buttons = {}
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton( ReadText(1001,2669), Buttons.Back, function () return true end,"INPUT_STATE_DETAILMONITOR_B"))
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton())
	table.insert(menu.buttons, LibMT:BarButton( ReadText(150402,244), Buttons.Done, Availability.Done, "INPUT_STATE_DETAILMONITOR_X" )) -- "Save"

	local buttondesc = LibMT.create_standard_button_bar( menu, menu.buttons, headerHeight, bodyHeight )
	
	-- build and display the view
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false)

	-- finally, we call all the script attaching functions
	for _, func in ipairs(cell_scripts) do
		func()
	end

	Helper.releaseDescriptors()

	return 
end

-- Timed update callback 
menu.updateInterval = 0.5
menu.onUpdate = function ()
	if menu.wpedit.toggle > 0 then
		menu.wpedit.toggle = 0
		Helper.updateCellText(menu.infotable, 3, 1, menu.wpedit.subtitle3, LibMT.colours.red)
	else		
		menu.wpedit.toggle = 1
		Helper.updateCellText(menu.infotable, 3, 1, menu.wpedit.subtitle3, LibMT.colours.white)
	end
end 

-- standard function stub to handle changing row
menu.onRowChanged = function (row, rowdata, rc_table)
	if rc_table == menu.defaulttable then
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
		Buttons.Back()
	end
	return
end
-- Callback function for waypoint editor back button

Buttons.Back = function()
	local return_waypoint = menu.wpedit.waypoint
	menu.wpedit.ret_arg[4] = "none"
	Helper.closeMenuForSection(menu, false, "gMT_WPListMenu_return", { 0, 0, {}, menu.wpedit.ret_arg, {}, menu.wpedit.trader, return_waypoint})
	menu.cleanup()
	return
end

-- Callback function for waypoint editor done button
Buttons.Done = function()
-- Calculate parameters of waypoint here
	local new_wp_idx = menu.wpedit.waypoint[1]
	menu.wpedit.waypoint[1] = new_wp_idx
	menu.wpedit.waypoint[2] = menu.bool.IsWPActive
	menu.wpedit.waypoint[3] = menu.wpedit.wp_station or ""
	menu.wpedit.waypoint[4] = menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]
	-- Remove values for fuel and flyto
	if menu.wpedit.waypoint[4] == 6 then
		menu.wpedit.waypoint[5] = ReadText(150402,162)		-- "None Selected" 
		menu.wpedit.waypoint[6] = 0 --menu.ware.MinAmount
		menu.wpedit.waypoint[7] = 0 --menu.ware.DisplayAmount
		menu.wpedit.waypoint[8] = 0 -- Price
		menu.wpedit.waypoint[9] = menu.wpedit.wprange
	else
		menu.wpedit.waypoint[5] = menu.ware.display[menu.ware.selectedWareType]
		menu.wpedit.waypoint[6] = menu.ware.MinAmount
		menu.wpedit.waypoint[7] = menu.ware.DisplayAmount
		menu.wpedit.waypoint[8] = menu.ware.Price
		menu.wpedit.waypoint[9] = menu.wpedit.wprange
	end

	local return_waypoint = menu.wpedit.waypoint
	menu.wpedit.ret_arg[4] = menu.wpedit.wp_action
	Helper.closeMenuForSection(menu, false, "gMT_WPListMenu_return", { 0, 0, {}, menu.wpedit.ret_arg, {}, menu.wpedit.trader, return_waypoint})
	menu.cleanup()
	return
end

-- Callback to handle waypoint decrement
Buttons.DecWPType = function()
	menu.wpedit.selectedWPType = menu.wpedit.selectedWPType - 1
	if menu.wpedit.selectedWPType < 1 then
		menu.wpedit.selectedWPType = #menu.wpedit.revwaypointType
	end
	-- Signal that the WP type has changed and check the menu
	Utility.RecheckMenu( false, false, true, false, false, false )
	menu.display()
	return
end

-- Callback to handle waypoint increment
Buttons.IncWPType = function()
	menu.wpedit.selectedWPType = menu.wpedit.selectedWPType + 1
	if menu.wpedit.selectedWPType > #menu.wpedit.revwaypointType then
		menu.wpedit.selectedWPType = 1
	end
	-- Signal that the WP type has changed and check the menu
	Utility.RecheckMenu( false, false, true, false, false, false )
	menu.display()
	return
end

-- Callback to handle ware type increment
Buttons.IncWareType = function()
	menu.ware.selectedWareType = menu.ware.selectedWareType + 1
	if menu.ware.selectedWareType > #menu.ware.display then
		menu.ware.selectedWareType = 1
	end
	-- Signal that the WP type has changed and check the menu
	Utility.RecheckMenu( false, false, false, false, true, false )
	menu.display()
	return
end

-- Callback to handle ware type decrement
Buttons.DecWareType = function()
	menu.ware.selectedWareType = menu.ware.selectedWareType - 1
	if menu.ware.selectedWareType < 1 then
		menu.ware.selectedWareType = #menu.ware.display
	end
	-- Signal that the WP type has changed and check the menu
	Utility.RecheckMenu( false, false, false, false, true, false)
	menu.display()
	return
end

-- Callback to handle modifier type increment
Buttons.IncModifierType = function()
	menu.ware.selectedMinAmount = menu.ware.selectedMinAmount + 1
	if menu.ware.selectedMinAmount  > 100 then
		menu.ware.selectedMinAmount = 100
	end
	-- Check for exceding min amount
	if menu.ware.selectedMinAmount > menu.ware.selectedAmount then
		menu.ware.selectedAmount = menu.ware.selectedMinAmount 
	end
	-- Signal that the WP type has changed and check the menu
	Utility.RecheckMenu( false, false, false, false, true, false )
	menu.display()
	return
end

-- Callback to handle modifier type decrement
Buttons.DecModifierType = function()
	menu.ware.selectedMinAmount = menu.ware.selectedMinAmount - 1
	if menu.ware.selectedMinAmount < 0 then
		menu.ware.selectedMinAmount = 0
	end
	-- Signal that the WP type has changed and check the menu
	Utility.RecheckMenu( false, false, false, false, true, false)
	menu.display()
	return
end

-- Callback to handle amount type increment
Buttons.IncAmount = function()
	menu.ware.selectedAmount = menu.ware.selectedAmount + 1
	if menu.ware.selectedAmount  > 100 then
		menu.ware.selectedAmount = 100
	end
	-- Signal that the WP type has changed and check the menu
	Utility.RecheckMenu( false, false, false, false, true, false )
	menu.display()
	return
end

-- Callback to handle amount type decrement
Buttons.DecAmount = function()
	menu.ware.selectedAmount = menu.ware.selectedAmount - 1
	if menu.ware.selectedAmount < 0 then
		menu.ware.selectedAmount = 0
	end
	-- Check for exceding min amount
	if  menu.ware.selectedAmount < menu.ware.selectedMinAmount then
		menu.ware.selectedMinAmount = menu.ware.selectedAmount
	end
	-- Signal that the WP type has changed and check the menu
	Utility.RecheckMenu( false, false, false, false, true, false)
	menu.display()
	return
end

-- Callback to increment buy/sell price
function Buttons:IncPrice()
	local pricerange = menu.ware.maxprice - menu.ware.minprice
	if pricerange < 100 then
		menu.ware.Price = menu.ware.Price + 1
	elseif pricerange < 1000 then
		menu.ware.Price = menu.ware.Price + 10
	elseif pricerange < 10000 then
		menu.ware.Price = menu.ware.Price + 100
	elseif pricerange < 100000 then
		menu.ware.Price = menu.ware.Price + 1000
	else
		menu.ware.Price = menu.ware.Price + 10000
	end
	if menu.ware.Price > menu.ware.maxprice then
		menu.ware.Price = menu.ware.maxprice
	end
	if menu.ware.Price < menu.ware.minprice then
		menu.ware.Price = menu.ware.minprice
	end  -- covers adding a new waypoint where price is unknown so set to zero
	menu.display()
end

-- Callback to Decrement buy/sell price
function Buttons:DecPrice()
	local pricerange = menu.ware.maxprice - menu.ware.minprice
	if pricerange < 100 then
		menu.ware.Price = menu.ware.Price - 1
	elseif pricerange < 1000 then
		menu.ware.Price = menu.ware.Price - 10
	elseif pricerange < 10000 then
		menu.ware.Price = menu.ware.Price - 100
	elseif pricerange < 100000 then
		menu.ware.Price = menu.ware.Price - 1000
	else
		menu.ware.Price = menu.ware.Price - 10000
	end
	if menu.ware.Price < menu.ware.minprice then
		menu.ware.Price = menu.ware.minprice
	end
	menu.display()
end



-- Callback to set ware price to mac min avg
function Buttons:SetPrice( value )
	if value == "max" then
		menu.ware.Price = menu.ware.maxprice
	elseif value == "avg" then
		menu.ware.Price = menu.ware.avgprice
	else
		menu.ware.Price = menu.ware.minprice
	end
	menu.display()
	return	
end

-- Callback to set active waypoint
function Buttons:SetActive()
	if menu.bool.IsWPActive == 0 then menu.bool.IsWPActive = 1 else menu.bool.IsWPActive = 0 end
	menu.display()
end

-- Callback to set specific amount
function Buttons:SetAmount( amount, isMax)
	if isMax then
		menu.ware.selectedAmount = amount
		-- Check for exceding min amount
		if  menu.ware.selectedAmount < menu.ware.selectedMinAmount then
			menu.ware.selectedMinAmount = menu.ware.selectedAmount
		end
	else
		menu.ware.selectedMinAmount = amount
		-- Check for exceding min amount
		if menu.ware.selectedMinAmount > menu.ware.selectedAmount then
			menu.ware.selectedAmount = menu.ware.selectedMinAmount 
		end
	end
	-- Signal that the WP type has changed and check the menu
	Utility.RecheckMenu( false, false, false, false, true, false)
	menu.display()
	return
end

-- Callback for button to set homebase as destination
function Buttons:SelectHomebase()
	menu.wpedit.wp_station = menu.wpedit.homebase
	-- Temporary save the working waypoint so we can call up the map
	local new_wp_idx = menu.wpedit.waypoint[1]
	menu.wpedit.waypoint[1] = new_wp_idx
	menu.wpedit.waypoint[2] = menu.bool.IsWPActive
	menu.wpedit.waypoint[3] = menu.wpedit.wp_station
	menu.wpedit.waypoint[4] = menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]
	if menu.wpedit.waypoint[5] == "None Selected" then
		menu.wpedit.waypoint[5] = "None Selected"
		menu.wpedit.waypoint[6] = 0
		menu.wpedit.waypoint[7] = 0
		menu.wpedit.waypoint[8] = 0
	else
		menu.wpedit.waypoint[5] = menu.ware.display[menu.ware.selectedWareType]
		menu.wpedit.waypoint[6] = menu.ware.MinAmount
		menu.wpedit.waypoint[7] = menu.ware.DisplayAmount
		menu.wpedit.waypoint[8] = menu.ware.Price
	end

	local return_waypoint = menu.wpedit.waypoint
	menu.wpedit.ret_arg[4] = menu.wpedit.wp_action
	Helper.closeMenuForSection(menu, false, "gMT_Map_HomebaseSelected", { 0, 0, {}, menu.wpedit.ret_arg, {}, menu.wpedit.trader, return_waypoint})
	menu.cleanup()
	return
end

function Buttons:mapSelect(faction)
	-- Temporary save the working waypoint so we can call up the map
	menu.wpedit.waypoint[1] = menu.wpedit.waypoint[1]
	menu.wpedit.waypoint[2] = menu.bool.IsWPActive
	menu.wpedit.waypoint[3] = menu.wpedit.wp_station
	menu.wpedit.waypoint[4] = menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]
	if menu.wpedit.waypoint[5] == "None Selected" then
		menu.wpedit.waypoint[5] = "None Selected"
		menu.wpedit.waypoint[6] = 0
		menu.wpedit.waypoint[7] = 0
		menu.wpedit.waypoint[8] = 0
	else
		menu.wpedit.waypoint[5] = menu.ware.display[menu.ware.selectedWareType]
		menu.wpedit.waypoint[6] = menu.ware.MinAmount
		menu.wpedit.waypoint[7] = menu.ware.DisplayAmount
		menu.wpedit.waypoint[8] = menu.ware.Price
	end

	local return_waypoint = menu.wpedit.waypoint
	Helper.closeMenuForSubSection(menu, false, "gMT_Map_GetStation", { 0, 0, {}, menu.wpedit.ret_arg, {}, menu.wpedit.trader, return_waypoint, faction})
	menu.cleanup()
	return
end

Availability.Done = function ()
	return menu.bool.isStationValid == true and menu.bool.isWPTypeValid == true and menu.bool.isWareValid == true 
end

-- Utility functions
Utility.RecheckMenu = function( newstation, checkStation, checkWPType, firstwptypecheck, checkWare, firstWareCheck )

	-- check the validity of the station
	if checkStation then
		menu.ware.shipres, menu.ware.shipprod, menu.ware.shiptrade, menu.ware.shipall = {}, {}, {}, {}
		-- initialise some booleans for directing action and button availability
		menu.bool.playerstation = false
		menu.bool.shipCanRefuel = false
		menu.bool.isWayPointValid = menu.wpedit.waypoint[2] or 0
		menu.bool.isStationValid = false
		menu.bool.isWPTypeValid = false
		menu.bool.isWareValid = false
		-- Initialise values we need to display on new or changed station
		
		-- check if the station we picked is valid
		if menu.wpedit.wp_station and (type(menu.wpedit.wp_station) ~= "string")  then
			if not IsComponentClass( menu.wpedit.wp_station, "station") then
				menu.wpedit.subtitle3 = ReadText(150402,223)				-- "!!OBJECT SELECTED MUST BE A STATION!!"
				DebugError("NOT A STATION WAS FIRED")
			elseif not GetComponentData(menu.wpedit.wp_station, "tradesubscription") then
				menu.wpedit.subtitle3 = ReadText(150402,224)		-- "!!STATION MUST HAVE A TRADE AGENT ONBOARD!!"
			-- check if hostile
			elseif GetComponentData(menu.wpedit.wp_station, "isenemy") then
				menu.wpedit.subtitle3 = ReadText(150402,225)		-- "!!STATION SELECTED IS HOSTILE - PLEASE CHOOSE ANOTHER!!"
			elseif LibMT.GetStationRange(menu.wpedit.homebase, menu.wpedit.wp_station) > menu.wpedit.trader[5] then
				menu.wpedit.subtitle3 = ReadText(150402,226)		-- "!!STATION SELECTED IS OUT OF RANGE FOR THE CURRENT CREW!!"
			else
				menu.wpedit.subtitle3 = ""			
				menu.bool.isStationValid = true
			end
		end

		-- Get station warelist and check if it has any wares the ship can carry
		if menu.bool.isStationValid then
--			DebugError( "Is station Valid:  " .. tostring(menu.bool.isStationValid) .. "  STATION:  " .. GetComponentData( menu.wpedit.wp_station, "name"))
			local resources = menu.wpedit.warelist[1] or {}
			local products = menu.wpedit.warelist[2] or {}
			local tradewares = menu.wpedit.warelist[3] or {}
			local cargolist = menu.wpedit.trader[3]
			resources = LibMT.RemoveWares( resources, "ship" )
			products = LibMT.RemoveWares( products, "ship" )
			tradewares = LibMT.RemoveWares( tradewares, "ship" )

			-- Get station range
			menu.wpedit.wprange = LibMT.GetStationRange( menu.wpedit.homebase, menu.wpedit.wp_station )

			menu.ware.shipres, menu.ware.shipprod, menu.ware.shiptrade, menu.ware.shipall, menu.bool.shipCanRefuel = LibMT.CompareStationWarelist( resources, products, tradewares, cargolist ) 
			if menu.wpedit.wp_station ~= ReadText(150402,112) then  -- "None"
 				if GetComponentData(menu.wpedit.wp_station, "owner") == "player" then menu.bool.playerstation = true else menu.bool.playerstation = false end
			end
			
			-- now compare these lists with the ship's cargo capability
			-- Check at least some wares can be traded here
			if #menu.ware.shipres < 1 and #menu.ware.shipprod < 1 and #menu.ware.shiptrade < 1 then
				menu.wpedit.subtitle3 = ReadText(150402,227)		-- "!!! WARNING!  THE STATION SELECTED DOES NOT DEAL IN ANY WARES THAT THE SHIP CAN CARRY !!!"
			end
		end	
	
	
		-- now determine the waypoint types supported
		menu.wpedit.revwaypointType = {1,2,3,4,5,6,7}
		if not menu.bool.shipCanRefuel then table.remove(menu.wpedit.revwaypointType, 7) end


		if (#menu.ware.shipres < 1 and #menu.ware.shiptrade < 1) or menu.bool.playerstation then table.remove(menu.wpedit.revwaypointType, 5) end
		if #menu.ware.shipprod < 1 or menu.bool.playerstation then table.remove(menu.wpedit.revwaypointType, 4) end
		if #menu.ware.shipres < 1 and #menu.ware.shiptrade < 1 and menu.bool.playerstation then table.remove(menu.wpedit.revwaypointType, 3) end
		if #menu.ware.shipprod < 1 and menu.bool.playerstation then table.remove(menu.wpedit.revwaypointType, 2) end


		if not menu.bool.playerstation then 
			table.remove(menu.wpedit.revwaypointType, 3) 
			table.remove(menu.wpedit.revwaypointType, 2) 
		end
	
		-- now resolve the selector index vs the types available
		menu.wpedit.selectedWPType = 1
		for i,v in ipairs(menu.wpedit.revwaypointType) do
			if v == menu.wpedit.waypoint[4] then
				menu.wpedit.selectedWPType = i 
			end
		end
		-- reset the waypoint to "No Action" if a new station is detected
		if newstation then
			menu.wpedit.selectedWPType = 1
		end
	end
	
	-- Check if waypoint type is changed
	if checkWPType then
		menu.ware.display = {}
		-- reset ware type display
		menu.ware.selectedWareType = 1
		local wp_type = menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] -- gets the text of the WP type
		menu.bool.isWPTypeValid = false
		menu.bool.isWareValid = false
		menu.bool.isFlyTo = false
		if wp_type ~= ReadText(150402,167) then   -- "No Action"
			if wp_type == ReadText(1001,2916) or wp_type == ReadText(150402,168) then		-- "Buy" "Load"
				menu.ware.display = LibMT.deepcopy(menu.ware.shipprod)
				menu.bool.isWPTypeValid = true
			elseif wp_type == ReadText(1001,2917) or wp_type == ReadText(150402,169) then				-- "Sell"  "Unload"
				menu.ware.display =  LibMT.deepcopy(LibMT.Set.Symmetric(menu.ware.shipres, menu.ware.shiptrade))
				menu.bool.isWPTypeValid = true
			elseif wp_type == ReadText(1002,2027) then  -- "Refuel"
				menu.ware.display = {"fuelcells"}
				menu.bool.isWPTypeValid = true
				menu.ware.selectedWareType = 2
				menu.bool.isWareValid = true
			elseif wp_type == ReadText(150402,170) then  -- "Fly to"
				menu.ware.display = {ReadText(150402,112)}		-- "None"
				menu.bool.isWPTypeValid = true
				menu.bool.isWareValid = true
				menu.bool.isFlyTo = true
				menu.ware.selectedWareType = 1
				menu.ware.selectedAmount = 0
				menu.ware.selectedMinAmount = 0
				menu.ware.DisplayAmount = 0
			end
			table.insert(menu.ware.display, 1, ReadText(150402,162))		-- "None Selected"

		end

		if firstwptypecheck then
			-- need to get our displayed ware type
			menu.ware.selectedWareType = 1
			for i,ware in ipairs(menu.ware.display) do
				local label = "None"
				if ware ~= ReadText(150402,162) or ware ~= ReadText(150402,112) then  -- "None Selected" "None"
					label = GetWareData(ware, "name")
				end
				if 	menu.ware.ware == ware then
					menu.ware.selectedWareType = i
				end
			end
			if menu.ware.display[2] == "fuelcells" then
				menu.ware.selectedWareType = 2
			end
			if menu.ware.display[2] == ReadText(150402,112) then    -- "None"
				menu.ware.selectedWareType = 2
			end
		end
	end
	
	-- check if ware type is changed
	if checkWare then
		-- Manage reset of volumes etc if ware changes
		if menu.ware.display[menu.ware.selectedWareType] == ReadText(150402,162) or #menu.ware.display < 2 then  -- "None Selected"
			menu.bool.stationchanged = false
			menu.bool.isWareValid = false
			menu.ware.selectedAmount = 0
			menu.ware.DisplayAmount = 0
			menu.ware.selectedMinAmount = 0
			menu.ware.MinAmount = 0
			menu.ware.Price = 0
		elseif menu.ware.display[menu.ware.selectedWareType] == ReadText(150402,112) then  -- Fly to "None"
			menu.ware.selectedAmount = 0
			menu.ware.DisplayAmount = 0
			menu.ware.selectedMinAmount = 0
			menu.ware.selectedWareType = 1
			menu.ware.MinAmount = 0
			menu.ware.Price = 0
		else
--			menu.bool.isWareValid = true
			local ware_lib = GetLibraryEntry("wares", menu.ware.display[menu.ware.selectedWareType])
			menu.ware.volume = ware_lib.volume
			menu.ware.minprice, menu.ware.avgprice, menu.ware.maxprice = GetWareData( menu.ware.display[menu.ware.selectedWareType], "minprice", "avgprice", "maxprice")
--			menu.ware.Price = menu.waypoint[8]
			if menu.wpedit.waypoint[8] == 0 then
				menu.ware.Price = menu.ware.avgprice
			else
				menu.ware.Price = menu.wpedit.waypoint[8]
			end
			-- Determine ware volume and manage further buttons
			local waretransport = GetWareData(menu.ware.display[menu.ware.selectedWareType], "transport")
			local wp_type = menu.wpedit.waypointType[menu.wpedit.revwaypointType[menu.wpedit.selectedWPType]] 
			if firstWareCheck then
				-- Resolve ware max amount
				if menu.wpedit.cargo[6] > 0 then
					if wp_type == ReadText(1002,2027) then -- "Refuel"
 						menu.ware.selectedAmount = Helper.round(   (100 * ((menu.wpedit.cargo[1]/4) - menu.wpedit.waypoint[7]))/(menu.wpedit.cargo[1]/4)    , 0)
						menu.ware.selectedMinAmount = Helper.round(   (100 * ((menu.wpedit.cargo[1]/4) - menu.wpedit.waypoint[6]))/(menu.wpedit.cargo[1]/4)    , 0)
					else	
						menu.ware.selectedAmount = Helper.round(menu.wpedit.waypoint[7]*menu.ware.volume*100/menu.wpedit.cargo[6], 0 ) 
						menu.ware.selectedMinAmount = Helper.round(menu.wpedit.waypoint[6]*menu.ware.volume*100/menu.wpedit.cargo[6], 0 ) 
					end
				elseif CheckSuitableTransportType(menu.wpedit.trader[1], "nividium") and waretransport == "bulk" then
					menu.ware.selectedAmount = Helper.round(menu.wpedit.waypoint[7]*menu.ware.volume*100/menu.wpedit.cargo[2], 0)
					menu.ware.selectedMinAmount = Helper.round(menu.wpedit.waypoint[6]*menu.ware.volume*100/menu.wpedit.cargo[2], 0)
				elseif CheckSuitableTransportType(menu.wpedit.trader[1], "chemicalcompounds") and waretransport == "container" then
					menu.ware.selectedAmount = Helper.round(menu.wpedit.waypoint[7]*menu.ware.volume*100/menu.wpedit.cargo[3], 0)
					menu.ware.selectedMinAmount = Helper.round(menu.wpedit.waypoint[6]*menu.ware.volume*100/menu.wpedit.cargo[3], 0)
				elseif CheckSuitableTransportType(menu.wpedit.trader[1], "ioncells") and waretransport == "energy" then
					menu.ware.selectedAmount = Helper.round(menu.wpedit.waypoint[7]*menu.ware.volume*100/menu.wpedit.cargo[4], 0)
					menu.ware.selectedMinAmount = Helper.round(menu.wpedit.waypoint[6]*menu.ware.volume*100/menu.wpedit.cargo[4], 0)
				elseif CheckSuitableTransportType(menu.wpedit.trader[1], "ions") and waretransport == "liquid" then
					menu.ware.selectedAmount = Helper.round(menu.wpedit.waypoint[7]*menu.ware.volume*100/menu.wpedit.cargo[5], 0)
					menu.ware.selectedMinAmount = Helper.round(menu.wpedit.waypoint[6]*menu.ware.volume*100/menu.wpedit.cargo[5], 0)
				elseif wp_type == ReadText(1002,2027) then
					menu.ware.selectedAmount = 100
					menu.ware.selectedMinAmount = Helper.round(   (100 * ((menu.wpedit.cargo[1]/4) - menu.wpedit.waypoint[6]))/(menu.wpedit.cargo[1]/4)    , 0)
				else
					menu.ware.selectedAmount = 0
					menu.ware.selectedMinAmount = 0
				end
			end
		
			-- calculate the ware number from the amount selected already
			if menu.ware.display[menu.ware.selectedWareType] ~= ReadText(150402,162) then -- "None Selected"
				menu.bool.isWareValid = true
				if menu.wpedit.cargo[6] > 0 and not menu.bool.shipCanRefuel then  -- universal
					menu.ware.DisplayAmount = math.floor(menu.wpedit.cargo[6]*menu.ware.selectedAmount/(menu.ware.volume*100), 0)
					menu.ware.MinAmount = math.floor(menu.wpedit.cargo[6]*menu.ware.selectedMinAmount/(menu.ware.volume*100), 0)
				elseif CheckSuitableTransportType(menu.wpedit.trader[1], "nividium") and waretransport == "bulk" then
					menu.ware.DisplayAmount = math.floor(menu.wpedit.cargo[2]*menu.ware.selectedAmount/(menu.ware.volume*100), 0)
					menu.ware.MinAmount = math.floor(menu.wpedit.cargo[2]*menu.ware.selectedMinAmount/(menu.ware.volume*100), 0)
				elseif CheckSuitableTransportType(menu.wpedit.trader[1], "chemicalcompounds") and waretransport == "container" then
					menu.ware.DisplayAmount = math.floor(menu.wpedit.cargo[3]*menu.ware.selectedAmount/(menu.ware.volume*100), 0)
					menu.ware.MinAmount = math.floor(menu.wpedit.cargo[3]*menu.ware.selectedMinAmount/(menu.ware.volume*100), 0)
				elseif CheckSuitableTransportType(menu.wpedit.trader[1], "ioncells") and waretransport == "energy" then
					menu.ware.DisplayAmount = math.floor(menu.wpedit.cargo[4]*menu.ware.selectedAmount/(menu.ware.volume*100), 0)
					menu.ware.MinAmount = math.floor(menu.wpedit.cargo[4]*menu.ware.selectedMinAmount/(menu.ware.volume*100), 0)
				elseif CheckSuitableTransportType(menu.wpedit.trader[1], "ions") and waretransport == "liquid" then
					menu.ware.DisplayAmount = math.floor(menu.wpedit.cargo[5]*menu.ware.selectedAmount/(menu.ware.volume*100), 0)
					menu.ware.MinAmount = math.floor(menu.wpedit.cargo[5]*menu.ware.selectedMinAmount/(menu.ware.volume*100), 0)
				elseif menu.bool.shipCanRefuel and wp_type == ReadText(1002,2027) then
					menu.ware.DisplayAmount = math.floor(menu.wpedit.cargo[1]/4, 0) 
					menu.ware.selectedAmount = 100
					menu.ware.MinAmount = math.floor((menu.wpedit.cargo[1]/4)*menu.ware.selectedMinAmount/100, 0)
					menu.bool.isWareValid = true
					menu.ware.selectedWareType = 2
				end
			else
				menu.ware.DisplayAmount = 0
				menu.ware.MinAmount = 0
				menu.bool.isWareValid = false
			end
		end
	end	
return	

end

init()

return
