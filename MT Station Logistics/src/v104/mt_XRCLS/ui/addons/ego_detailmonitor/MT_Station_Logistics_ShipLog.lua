--[[	Manages the trader ship log screen for the MT Station Logistics mod
		Version:		1.0.1
		Last Update:	2015-01-23
 --]]
 
-- Set up the default menu table
local menu = 	{	name = "gMT_Station_Logistics_ShipLog",
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
	menu.updateInterval = nil
	menu.infotable = nil
	menu.selecttable = nil
	menu.buttontable = nil
	menu.defaulttable = nil
	menu.buttons = nil
	menu.ship = nil
	return
end

-- standard callback function that fires on first time display of menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.ship = {}
	menu.toprow = 3 -- menu.param[1]				-- return toprow
	menu.selrow = 3 -- menu.param[2]				-- return row
	menu.ship.ret_exp = menu.param[4]				-- return row and expand states
	menu.ship.trader = menu.param[7]
	menu.ship.numwaypoints = menu.ship.trader[11]
	
	menu.ship.title = ReadText(150402,401)			-- menu.title = "MT Station Logistics - Ship Log"
	menu.ship.subtitle = ReadText(150402,402) 		-- "Get data from your Logistics Trader ships"
	
	menu.ship.log = menu.ship.trader[7] or {}
	menu.ship.adminlog = menu.param[8] or {}
--	menu.ship.TrackLog = menu.ship.trader[12]
	menu.ship.debug_level = menu.ship.trader[13]
	menu.ship.tracking = menu.ship.trader[14]
	menu.ship.dbgType = { "Normal", "Verbose" }
	menu.ship.tracktype = { "Not Tracking", "Tracking" }
	
	-- Get a handle for the captain's log which is used for tracking entries
	menu.ship.captain = GetComponentData( menu.ship.trader[1], "pilot" )
	menu.ship.TrackLog = {}
	menu.ship.command = ""
	if menu.ship.captain then
		local aicommandstack, aicommand, aicommandparam, aicommandaction, aicommandactionparam = GetComponentData(menu.ship.captain, "aicommandstack", "aicommand", "aicommandparam", "aicommandaction", "aicommandactionparam")
		local numaicommands = #aicommandstack
		local updatetext = ""
		if 0 < numaicommands then
			aicommand = aicommandstack[1].command
			aicommandparam = aicommandstack[1].param
		end

		updatetext = updatetext .. "" .. ReadText(1001, 78) .. ReadText(1001, 120) .. " " .. string.format(aicommand, (IsComponentClass(aicommandparam, "component") and GetComponentData(aicommandparam, "name")) or nil)

		if 1 < numaicommands then
			aicommandaction = aicommandstack[numaicommands].command
			aicommandactionparam = aicommandstack[numaicommands].param
		end

		if aicommandaction ~= "" then
			updatetext = updatetext .. " - " .. string.format(aicommandaction, (IsComponentClass(aicommandactionparam, "component") and GetComponentData(aicommandactionparam, "name")) or nil)
		end
		menu.ship.command = updatetext
		menu.ship.captainlog = GetNPCBlackboard(menu.ship.captain, "$XRCLS")
		if menu.ship.captainlog then
			menu.ship.TrackLog = menu.ship.captainlog[6]
		else	
			menu.ship.TrackLog = {}
			menu.ship.command = ""
		end
	end
	
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
	local name, ownericon = GetComponentData(menu.ship.trader[1], "name", "ownericon") -- , "typestring", "typeicon", "typename", "ownericon", "skills")
	local textstring = menu.ship.title .. "\n" .. name
	title = {Helper.createIcon(ownericon, false, 255, 255, 255, 100, 0, 0, Helper.headerCharacterIconSize, Helper.headerCharacterIconSize),
	Helper.createFontString(textstring, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize, true),
	Helper.createFontString("", false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize),
	}
	local colwidth = {
						Helper.scaleX(Helper.headerCharacterIconSize),
						0,
						250,
						Helper.scaleX(Helper.headerCharacterIconSize) + 37
					}
	local colspan = {1,2,1}
	local additional = {}
	local cells = {}
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(cells, LibMT:Cell(ReadText(150402,303) .. ":", nil, 1))  -- "Flying Time"
	table.insert(cells, LibMT:Cell(ConvertTimeString(  menu.ship.trader[9][1] ), nil, 1))   
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(additional, LibMT:Row(cells, {"none"}, Helper.defaultHeaderBackgroundColor, false, 0))
	local cells = {}
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(cells, LibMT:Cell(ReadText(150402,403) .. ":", nil, 1))  -- "Total Time"
	table.insert(cells, LibMT:Cell(ConvertTimeString(  menu.ship.trader[9][2] ), nil, 1))   
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(additional, LibMT:Row(cells, {"none"}, Helper.defaultHeaderBackgroundColor, false, 0))
	local cells = {}
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(cells, LibMT:Cell(ReadText(150402,406) .. ":", nil, 1))  -- "% Time Active"
	local pc_time = 0
	if Helper.round(menu.ship.trader[9][2], 0) > 0 then
		pc_time = Helper.round(menu.ship.trader[9][1]*100/menu.ship.trader[9][2], 0)
	end
	table.insert(cells, LibMT:Cell(pc_time .. " %", nil, 1))   
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(additional, LibMT:Row(cells, {"none"}, Helper.defaultHeaderBackgroundColor, false, 0))
	local cells = {}
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(cells, LibMT:Cell(ReadText(150402,404) .. ":", nil, 1))  -- "Turnover"
	local money = ConvertMoneyString( menu.ship.trader[9][4]/100, false, true, nil, true) .. " Cr" 
	table.insert(cells, LibMT:Cell(money, nil, 1))
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(additional, LibMT:Row(cells, {"none"}, Helper.defaultHeaderBackgroundColor, false, 0))
	local cells = {}
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(cells, LibMT:Cell(ReadText(150402,405) .. ":", nil, 1))  -- "Volume Traded"
	local vol = ConvertIntegerString(menu.ship.trader[9][3], true, 4, true)
	table.insert(cells, LibMT:Cell(vol .. ReadText(1001,110), nil, 1))
	table.insert(cells, LibMT:Cell("", nil, 1))
	table.insert(additional, LibMT:Row(cells, {"none"}, Helper.defaultHeaderBackgroundColor, false, 0))
	local cells = {}
	table.insert(cells, LibMT:Cell(menu.ship.command, nil, 4))
	table.insert(additional, LibMT:Row(cells, {"none"}, Helper.defaultHeaderBackgroundColor, false, 0))
	
	-- Create the menu header and get its height
	local infodesc, headerHeight = LibMT.create_column_header( menu, title, { typename }, additional, colwidth, colspan, true )

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
	-- Normal log view
	-- Header Rows
	if menu.ship.tracking == 0 then 
		local cells = {}
		table.insert(cells, LibMT:Cell( ReadText(150402,410), nil, 2) ) -- "Activity Log"
		if LibMT.DEBUG then
			if 0 < menu.ship.debug_level then
				table.insert(cells, LibMT:Cell( ReadText(150402,411) .. " - " .. menu.ship.dbgType[2], nil, 2) ) -- "Debug Level for this ship"
			else
				table.insert(cells, LibMT:Cell( ReadText(150402,411) .. " - " .. menu.ship.dbgType[1], nil, 2) ) -- "Debug Level for this ship"
			end
		else
			table.insert(cells, LibMT:Cell( "", nil, 2) ) 
		end
		table.insert(cells, LibMT:Cell( menu.ship.tracktype[menu.ship.tracking + 1], nil, 1) ) -- "Tracking for this ship"
		table.insert(row_collection, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, true, 0))
		if 0 < #menu.ship.log then
			local cells = {}
			table.insert(cells, LibMT:Cell( ReadText(1001,24), nil, 1) ) -- "Time"
			table.insert(cells, LibMT:Cell( ReadText(150402,163), nil, 1) ) -- "WP Type"
			table.insert(cells, LibMT:Cell( ReadText(1001,45), nil, 1) ) -- "Ware"
			table.insert(cells, LibMT:Cell( ReadText(1001,1202), nil, 1) ) -- "Amount"
			table.insert(cells, LibMT:Cell( ReadText(1001,3), nil, 1) ) -- "Station"
			table.insert(row_collection, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, true, 0))
		
			for i,msg in ipairs(menu.ship.log) do
				local cells = {}
				table.insert(cells, LibMT:Cell( ConvertTimeString(GetCurTime() - msg[1]), nil, 1) )
				table.insert(cells, LibMT:Cell( LibMT.WPType[msg[6]], nil, 1) )
				table.insert(cells, LibMT:Cell( GetWareData( msg[8],"name"), nil, 1) )
				table.insert(cells, LibMT:Cell(msg[9], nil, 1) )
				table.insert(cells, LibMT:Cell( GetComponentData( msg[7], "name"), nil, 1) )
				table.insert(row_collection, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, false, 0))
			end
		else
			local cells = {}
			table.insert(cells, LibMT:Cell("", nil, 5) ) -- ""
			table.insert(row_collection, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, true, 0))
			local cells = {}
			table.insert(cells, LibMT:Cell( ReadText(150402,412), nil, 5) ) -- "No Log Entries to show"
			table.insert(row_collection, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, false, 0))
		end
	elseif menu.ship.tracking == 1 then
		local cells = {}
		table.insert(cells, LibMT:Cell( ReadText(150402,413), nil, 2) ) -- "Tracking Log"
		if LibMT.DEBUG then
			if 0 < menu.ship.debug_level then
				table.insert(cells, LibMT:Cell( ReadText(150402,411) .. " - " .. menu.ship.dbgType[2], nil, 2) ) -- "Debug Level for this ship"
			else
				table.insert(cells, LibMT:Cell( ReadText(150402,411) .. " - " .. menu.ship.dbgType[1], nil, 2) ) -- "Debug Level for this ship"
			end
		else
			table.insert(cells, LibMT:Cell( "", nil, 2) ) 
		end
		table.insert(cells, LibMT:Cell( menu.ship.tracktype[menu.ship.tracking + 1], nil, 1) ) -- "Tracking for this ship"
		table.insert(row_collection, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, true, 0))
		local cells = {}
		table.insert(cells, LibMT:Cell( ReadText(1001,24), nil, 1) ) -- "Time"
		table.insert(cells, LibMT:Cell( ReadText(150402,463), nil, 4) ) -- "Message"
		table.insert(row_collection, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, true, 0))
		
		for i = 3, 33, 1 do
			local msg = menu.ship.TrackLog[i - 2]
			if msg then
				if msg[3] == "TRADE_SUCCESS" then
					local cells = {}
					local message = ReadText(150402,414) .. ": " .. tostring(msg[17]) .. " - " .. LibMT.WPType[msg[6]] .. " - " .. GetWareData( msg[8],"name") .. " - " .. msg[9] .. " - " .. GetComponentData( msg[7], "name")
					table.insert(cells, LibMT:Cell( ConvertTimeString(GetCurTime() - msg[1]), nil, 1) )
					table.insert(cells, LibMT:Cell( message, nil, 4) )
					table.insert(row_collection, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, false, 0))
				else
					local cells = {}
					local message = ReadText(150402,414) .. ": " .. tostring(msg[17]) .. ": " .. tostring(LibMT.Messages[ msg[3] ])
					table.insert(cells, LibMT:Cell( ConvertTimeString(GetCurTime() - msg[1]), nil, 1) )
					table.insert(cells, LibMT:Cell( message, nil, 4) )
					table.insert(row_collection, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, false, 0))
				end
			else
				local cells = {}
				local message = ""
				table.insert(cells, LibMT:Cell( "", nil, 1) )
				table.insert(cells, LibMT:Cell( message, nil, 4) )
				table.insert(row_collection, LibMT:Row(cells, {}, Helper.defaultHeaderBackgroundColor, false, 0))
			end
		end
	end
	-- create the body descriptor
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
	if LibMT.DEBUG then
		table.insert(menu.buttons, LibMT:BarButton("(DBG) Verbose", Buttons.Verbose, function () return true end,"INPUT_STATE_DETAILMONITOR_Y"))
	else
		table.insert(menu.buttons, LibMT:BarButton())
	end
	table.insert(menu.buttons, LibMT:BarButton(ReadText(150402,407), Buttons.Track, function () return true end,"INPUT_STATE_DETAILMONITOR_X"))
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

-- Timed update callback 
menu.updateInterval = 1
menu.onUpdate = function ()
	if menu.ship.captain then
		local zone, sector, system = GetComponentData(menu.ship.trader[1], "zone", "sector", "cluster")
		local aicommandstack, aicommand, aicommandparam, aicommandaction, aicommandactionparam = GetComponentData(menu.ship.captain, "aicommandstack", "aicommand", "aicommandparam", "aicommandaction", "aicommandactionparam")
		local numaicommands = #aicommandstack
		local updatetext = "Location: " .. tostring(system) .. " / " .. tostring(sector) .. " / " .. tostring(zone) .. "  "
		if 0 < numaicommands then
			aicommand = aicommandstack[1].command
			aicommandparam = aicommandstack[1].param
		end

		updatetext = tostring(updatetext .. "" .. ReadText(1001, 78) .. 
								ReadText(1001, 120) .. " " ..  
								string.format(aicommand, (IsComponentClass(aicommandparam, "component") and GetComponentData(aicommandparam, "name")) or nil))

		if 1 < numaicommands then
			aicommandaction = aicommandstack[numaicommands].command
			aicommandactionparam = aicommandstack[numaicommands].param
		end

		if aicommandaction ~= "" then
			updatetext = tostring(updatetext .. " - " .. string.format(aicommandaction, (IsComponentClass(aicommandactionparam, "component") and GetComponentData(aicommandactionparam, "name")) or nil))
		end
		menu.ship.command = updatetext
		menu.ship.captainlog = GetNPCBlackboard(menu.ship.captain, "$XRCLS")
		if menu.ship.captainlog and menu.ship.tracking == 1 then
			if 0 < #menu.ship.TrackLog then
				menu.ship.TrackLog = menu.ship.captainlog[6]
				local wpnum = menu.ship.captainlog[6][1][17]
				if wpnum == menu.ship.numwaypoints then
					wpnum = 0
				end
				Helper.updateCellText(menu.infotable, 7, 1, updatetext, LibMT.colours.white)
				Helper.updateCellText(menu.selecttable, 1, 1, ReadText(150402,413) .. " - WP " .. wpnum + 1, LibMT.colours.white)
				for i=3, 33 ,1 do
					local msg = menu.ship.TrackLog[i - 2]
					if msg then
						if msg[3] == "TRADE_SUCCESS" then
							local message = ReadText(150402,414) .. ": " .. tostring(msg[17]) .. " - " .. LibMT.WPType[msg[6]] .. " - " .. GetWareData( msg[8],"name") .. " - " .. msg[9] .. " - " .. GetComponentData( msg[7], "name")
							Helper.updateCellText(menu.selecttable, i, 1, ConvertTimeString(GetCurTime() - msg[1]), LibMT.colours.white)
							Helper.updateCellText(menu.selecttable, i, 2, message, LibMT.colours.white)
						else
							local message = ReadText(150402,414) .. ": " .. tostring(msg[17]) .. " - " .. tostring(LibMT.Messages[ msg[3] ])
							Helper.updateCellText(menu.selecttable, i, 1, ConvertTimeString(GetCurTime() - msg[1]), LibMT.colours.white)
							Helper.updateCellText(menu.selecttable, i, 2, message, LibMT.colours.white)
						end
					end
				end
			end
		end
	end
end 

-- Callback function for back button
Buttons.Back = function()
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_return", { menu.ship.ret_exp[1], menu.ship.ret_exp[2], {}, menu.ship.ret_exp, {}, {}, menu.ship.trader } )
	menu.cleanup()
	return
end

-- Callback function for ship track button
Buttons.Track = function()
	-- toggle the value
	if menu.ship.tracking == 0 then
		menu.ship.tracking = 1
	else
		menu.ship.tracking = 0
	end
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_toggleTracking", { 3, 3, menu.ship.tracking, menu.ship.ret_exp, {}, {}, menu.ship.trader} )
	menu.cleanup()
	return
end

-- Callback function for toggle verbose debug button
Buttons.Verbose = function()
	if menu.ship.debug_level == 0 then
		menu.ship.debug_level = 4
	else
		menu.ship.debug_level = 0
	end
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_toggleDbg", { menu.ship.ret_exp[1], menu.ship.ret_exp[2], menu.ship.debug_level, menu.ship.ret_exp, {}, {}, menu.ship.trader} )
	menu.cleanup()
	return
end

-- Availability provider for the train button
Availability.Select = function(menu, rowIdx, rowData )
end

init()

return
