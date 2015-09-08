-- Manages Waypoint Configuration for MT Station Logistics mod
 
-- Set up the default menu table
local menu = {	name = "gMT_Station_Logistics_ListWPSelect",
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
	menu.updateInterval = nil
	menu.infotable = nil
	menu.selecttable = nil
	menu.buttontable = nil
	menu.buttons = nil
	menu.bool = nil
	menu.ware = nil
	menu.wplistadd = nil
	return
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	-- setup various variables used in the menu
	menu.bool = 					{} -- empty table for grouping our menu switches
	menu.ware = 					{}
	menu.wplistadd = 				{} 
		
	menu.toprow = 					menu.param[1]
	menu.selrow = 					menu.param[2]

	menu.wplistadd.trader = 		menu.param[6]
	menu.wplistadd.waypoint = 		menu.param[7]
	menu.wplistadd.WPParams =		menu.param[3] or {}
	
	menu.wplistadd.homebase = 		menu.wplistadd.trader[2]
	menu.wplistadd.cargo = 			menu.wplistadd.trader[3]
	menu.wplistadd.trader_range = 	menu.wplistadd.trader[5]
	
	menu.wplistadd.range = 			{ "Zone", "Sector", "System", "Galaxy" }
	menu.wplistadd.selectedRange = 	menu.wplistadd.trader_range + 1

	menu.wplistadd.title = 			ReadText(150402,21)			-- menu.title = "MT Station Logistics - Administration"
	
	menu.wplistadd.subtitle = 		"Add Waypoint(s) by list"
	menu.wplistadd.subtitle3 = 		ReadText(150402,174) .. ": " .. GetComponentData(menu.wplistadd.trader[2], "name")
	
	-- get homebase warelist
	menu.wplistadd.homebasewares =	menu.param[8] or {}
	menu.wplistadd.activewares = 	{}
	menu.wplistadd.selectedWare =	1
	menu.wplistadd.MinWareAmount = 0
	menu.wplistadd.MaxWareAmount = 0
	menu.wplistadd.selectedMaxAmount = 0
	menu.wplistadd.selectedMinAmount = 0
	menu.wplistadd.warePrice = 0
	--	menu.wplistadd.waypointType = { 	"Load", "Unload", "Buy", "Sell" }
	menu.wplistadd.waypointType = { ReadText(150402,168), ReadText(150402,169), 
									ReadText(1001,2916), ReadText(1001,2917) }
	menu.wplistadd.selectedWPType = 1

	-- Boolean switches for drawing menu lists
	menu.bool.IncludeIntermediateResources = false
	
	-- Check here for WP Params already set
	if 0 < #menu.wplistadd.WPParams then
--		DebugError("Returned from Station List")
		menu.wplistadd.selectedWPType		= menu.wplistadd.WPParams[1]
		menu.wplistadd.selectedWare 		= menu.wplistadd.WPParams[7]
		menu.wplistadd.selectedMaxAmount	= menu.wplistadd.WPParams[3]
		menu.wplistadd.selectedMinAmount	= menu.wplistadd.WPParams[4]
		menu.wplistadd.warePrice			= menu.wplistadd.WPParams[5]
		menu.wplistadd.selectedRange		= menu.wplistadd.WPParams[6]
	end
	
	-- Good to go!
	Utility.MenuCheck(true)
	menu.display()
end

-- Main redraw function
menu.display = function ()	
	Helper.removeAllButtonScripts(menu)
	Helper.currentTableRow = {}
	Helper.currentTableRowData = nil
	menu.rowDataMap = {}
	-- Setup the header block
	local title_txt = menu.wplistadd.title .. " - " .. menu.wplistadd.subtitle
	local subtitle2 = ReadText(150402,173) .. ": " .. GetComponentData(menu.wplistadd.trader[1], "name")  --.. " -- " .. ReadText(150402,174) .. ": " .. GetComponentData(menu.wplistadd.trader[2], "name")
	local infodesc, headerHeight = LibMT.create_standard_header( menu, title_txt, {subtitle2}, {  }, 1,  nil, { menu.wplistadd.subtitle3 })
	
	-- Setup the main body
	local standard_button_height = 60
	local bodyHeight = 570 - headerHeight - standard_button_height
	local row_collection = {}
	local cell_scripts = {}
	local colWidths = {
		200,
		200,
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

	-- Row 1 - Waypoint type selection
	local cells = {}
	table.insert( cells, LibMT:Cell( ReadText(150402,232), nil, 1))				-- "Waypoint Type"
	table.insert( cells, LibMT:Cell( menu.wplistadd.waypointType[menu.wplistadd.selectedWPType], nil, 1))
	table.insert( cells, LibMT:ButtonCell( "-", Buttons.DecWPType, 1, true))
	table.insert( cells, LibMT:ButtonCell( "+", Buttons.IncWPType, 1, true))
	table.insert( cells, LibMT:Cell("", nil, 5))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 2 - Toggle intermediate resources
	local cells = {}
	table.insert( cells, LibMT:Cell("Intermediate wares?", nil, 1))				-- "Include homebase intermediate wares?"
	if menu.bool.IncludeIntermediateResources then
		table.insert( cells, LibMT:Cell("YES", nil, 1))
	else table.insert( cells, LibMT:Cell("NO", nil, 1)) end
	table.insert( cells, LibMT:ButtonCell( "-", Buttons.ToggleIntermediateWares, 1, true))
	table.insert( cells, LibMT:ButtonCell( "+", Buttons.ToggleIntermediateWares, 1, true))
	table.insert( cells, LibMT:Cell("", nil, 5))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 3 - valid ware types 
	local cells = {}
	local warename = "None"
	if 0 < #menu.wplistadd.activewares then
		if GetWareData(menu.wplistadd.activewares[menu.wplistadd.selectedWare], "name") then
			warename = GetWareData(menu.wplistadd.activewares[menu.wplistadd.selectedWare], "name")
		end
	end
	table.insert( cells, LibMT:Cell("Ware to trade", nil, 1))				-- "Ware to trade"
	table.insert( cells, LibMT:Cell( warename, nil, 1))
	table.insert( cells, LibMT:ButtonCell( "-", Buttons.DecWareType, 1, true))
	table.insert( cells, LibMT:ButtonCell( "+", Buttons.IncWareType, 1, true))
	table.insert( cells, LibMT:Cell("", nil, 5))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 4 - Minimum Amount selection
	local cells = {}
	table.insert( cells, LibMT:Cell( ReadText(150402,235), nil, 1))			-- "Minimum Amount"
	table.insert( cells, LibMT:Cell(menu.wplistadd.MinWareAmount .. "  (" .. menu.wplistadd.selectedMinAmount .. " % " .. ReadText(150402,236) .. ")", nil, 1)) -- "Cargo Space"
	table.insert( cells, LibMT:ButtonCell( "-", Buttons.DecMinWareAmount, 1, true))
	table.insert( cells, LibMT:ButtonCell( "+", Buttons.IncMinWareAmount, 1, true))
	table.insert( cells, LibMT:ButtonCell( "25%", function(rowIdx, colIdx) Buttons:SetWareAmount( 25, false ) end, 1, true))    
	table.insert( cells, LibMT:ButtonCell( "50%", function(rowIdx, colIdx) Buttons:SetWareAmount( 50, false ) end, 1, true))
	table.insert( cells, LibMT:ButtonCell( "75%", function(rowIdx, colIdx) Buttons:SetWareAmount( 75, false ) end, 1, true))    
	table.insert( cells, LibMT:ButtonCell( ReadText(1001,19), function(rowIdx, colIdx) Buttons:SetWareAmount( 100, false ) end, 1, true)) -- "Max"
	table.insert( cells, LibMT:Cell("", nil, 1))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 5 - Maximum amount selection
	local cells = {}
	table.insert( cells, LibMT:Cell( ReadText(150402,237), nil, 1)) 		-- "Maximum Amount"
	table.insert( cells, LibMT:Cell(menu.wplistadd.MaxWareAmount .. "  (" .. menu.wplistadd.selectedMaxAmount .. " % " .. ReadText(150402,236) .. ")", nil, 1))
	table.insert( cells, LibMT:ButtonCell( "-", Buttons.DecMaxWareAmount, 1, true ))			-- TODO: Also validate on amount > 0
	table.insert( cells, LibMT:ButtonCell( "+", Buttons.IncMaxWareAmount, 1, true ))			-- Add 50% and MAX buttons
	table.insert( cells, LibMT:ButtonCell( "25%", function(rowIdx, colIdx) Buttons:SetWareAmount( 25, true ) end, 1, true ))    
	table.insert( cells, LibMT:ButtonCell( "50%", function(rowIdx, colIdx) Buttons:SetWareAmount( 50, true ) end, 1, true ))
	table.insert( cells, LibMT:ButtonCell( "75%", function(rowIdx, colIdx) Buttons:SetWareAmount( 75, true ) end, 1, true ))    
	table.insert( cells, LibMT:ButtonCell( ReadText(1001,19), function(rowIdx, colIdx) Buttons:SetWareAmount( 100, true ) end, 1, true ))  -- "Max"
	table.insert( cells, LibMT:Cell("", nil, 1))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 6 - max price selection select + AVG MIN MAX BUTTONS - may need reset on ware type change
	local cells = {}
	if menu.wplistadd.selectedWPType == 1 or menu.wplistadd.selectedWPType == 3 then -- "Buy" "Load"
		table.insert( cells, LibMT:Cell( ReadText(150402,238), nil, 1))		-- "Maximum buy Price"
	elseif menu.wplistadd.selectedWPType == 2 or menu.wplistadd.selectedWPType == 4 then -- "Sell" "Unload"
 		table.insert( cells, LibMT:Cell( ReadText(150402,239), nil, 1))		-- "Minimum sell Price"
	end
	table.insert( cells, LibMT:Cell(menu.wplistadd.warePrice, nil, 1))
	table.insert( cells, LibMT:ButtonCell( "-", function(rowIdx, colIdx) Buttons:DecWarePrice() end, 1, true ))		
	table.insert( cells, LibMT:ButtonCell( "+", function(rowIdx, colIdx) Buttons:IncWarePrice() end, 1, true ))
	table.insert( cells, LibMT:ButtonCell( ReadText(150402,164), function(rowIdx, colIdx) Buttons:SetWarePrice("min") end, 1, true ))
	table.insert( cells, LibMT:ButtonCell( ReadText(150402,240), function(rowIdx, colIdx) Buttons:SetWarePrice("avg") end, 1, true ))    
	table.insert( cells, LibMT:ButtonCell( ReadText(1001,19), function(rowIdx, colIdx) Buttons:SetWarePrice("max") end, 1, true ))
	table.insert( cells, LibMT:Cell( "", nil, 2))
	table.insert( row_collection, LibMT:Row( cells, nil, menu.transparent, false, 0))
	
	-- Row 7 - Limit range of search
	local cells = {}
	table.insert( cells, LibMT:Cell( "Limit Search Range to:", nil, 1))				-- "Limit Search Range to:"
	table.insert( cells, LibMT:Cell( menu.wplistadd.range[menu.wplistadd.selectedRange], nil, 1))
	table.insert( cells, LibMT:ButtonCell( "-", Buttons.DecRange, 1, true))
	table.insert( cells, LibMT:ButtonCell( "+", Buttons.IncRange, 1, true))
	table.insert( cells, LibMT:Cell("", nil, 5))
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
	table.insert(menu.buttons, LibMT:BarButton( "Map Select", Buttons.Map, function () return true end, "INPUT_STATE_DETAILMONITOR_Y"))
	table.insert(menu.buttons, LibMT:BarButton( "Get Waypoints", Buttons.Done, Availability.Done, "INPUT_STATE_DETAILMONITOR_X" )) -- "Save"

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
--menu.updateInterval = 1
menu.onUpdate = function ()
end 

-- standard function stub to handle changing row
menu.onRowChanged = function (row, rowdata, rc_table)
	if rc_table == menu.defaulttable then
		LibMT:CheckButtonBarAvailability(menu, row, rowdata)
	end
	return
end

menu.onSelectElement = function ()
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

-- Callback to handle waypoint decrement
Buttons.DecWPType = function()
	menu.wplistadd.selectedWPType = menu.wplistadd.selectedWPType - 1
	if menu.wplistadd.selectedWPType < 1 then
		menu.wplistadd.selectedWPType = #menu.wplistadd.waypointType
	end
	-- check waretypes here to update waretype list
	Utility.MenuCheck(true)
	menu.wplistadd.selectedWare = 1
	menu.display()
	return
end

-- Callback to handle waypoint increment
Buttons.IncWPType = function()
	menu.wplistadd.selectedWPType = menu.wplistadd.selectedWPType + 1
	if menu.wplistadd.selectedWPType > #menu.wplistadd.waypointType then
		menu.wplistadd.selectedWPType = 1
	end
	-- check waretypes here to update waretype list
	menu.wplistadd.selectedWare = 1
	Utility.MenuCheck(true)
	menu.display()
	return
end

-- Toggle include intermediate wares
Buttons.ToggleIntermediateWares = function()
	if menu.bool.IncludeIntermediateResources then
		menu.bool.IncludeIntermediateResources = false
	else
		menu.bool.IncludeIntermediateResources = true
	end
	-- check ware type list if this changes
	menu.wplistadd.selectedWare = 1
	Utility.MenuCheck(true)
	menu.display()
end

-- Callback to handle ware type increment
Buttons.IncWareType = function()
	menu.wplistadd.selectedWare = menu.wplistadd.selectedWare + 1
	if menu.wplistadd.selectedWare > #menu.wplistadd.activewares then
		menu.wplistadd.selectedWare = 1
	end
	-- Signal that the WP type has changed and check the menu
	Utility.MenuCheck(true)
	menu.display()
	return
end

-- Callback to handle ware type decrement
Buttons.DecWareType = function()
	menu.wplistadd.selectedWare = menu.wplistadd.selectedWare - 1
	if menu.wplistadd.selectedWare < 1 then
		if 0 < #menu.wplistadd.activewares then
			menu.wplistadd.selectedWare = #menu.wplistadd.activewares
		else
			menu.wplistadd.selectedWare = 1
		end
	end
	-- Signal that the WP type has changed and check the menu
	Utility.MenuCheck(true)
	menu.display()
	return
end

-- Callback to handle max ware amount increment
Buttons.IncMaxWareAmount = function()
	menu.wplistadd.selectedMaxAmount = menu.wplistadd.selectedMaxAmount + 1
	if menu.wplistadd.selectedMaxAmount  > 100 then
		menu.wplistadd.selectedMaxAmount = 100
	end
	-- Signal has changed and check the menu
	Utility.MenuCheck(false)
	menu.display()
	return
end

-- Callback to handle max ware amount decrement
Buttons.DecMaxWareAmount = function()
	menu.wplistadd.selectedMaxAmount = menu.wplistadd.selectedMaxAmount - 1
	if menu.wplistadd.selectedMaxAmount < 0 then
		menu.wplistadd.selectedMaxAmount = 0
	end
	-- Check for exceding min amount
	if  menu.wplistadd.selectedMaxAmount < menu.wplistadd.selectedMinAmount then
		menu.wplistadd.selectedMinAmount = menu.wplistadd.selectedMaxAmount
	end
	-- Signal has changed and check the menu
	Utility.MenuCheck(false)
	menu.display()
	return
end

-- Callback to handle min ware amount increment
Buttons.IncMinWareAmount = function()
	menu.wplistadd.selectedMinAmount = menu.wplistadd.selectedMinAmount + 1
	if menu.wplistadd.selectedMinAmount  > 100 then
		menu.wplistadd.selectedMinAmount = 100
	end
	-- Check for exceding min amount
	if menu.wplistadd.selectedMinAmount > menu.wplistadd.selectedMaxAmount then
		menu.wplistadd.selectedMaxAmount = menu.wplistadd.selectedMinAmount 
	end
	-- Signal has changed and check the menu
	Utility.MenuCheck(false)
	menu.display()
	return
end

-- Callback to handle min ware amount decrement
Buttons.DecMinWareAmount = function()
	menu.wplistadd.selectedMinAmount = menu.wplistadd.selectedMinAmount - 1
	if menu.wplistadd.selectedMinAmount < 0 then
		menu.wplistadd.selectedMinAmount = 0
	end
	-- Signal has changed and check the menu
	Utility.MenuCheck(false)
	menu.display()
	return
end

-- Callback to set specific amount
function Buttons:SetWareAmount( amount, isMax)
	if isMax then
		menu.wplistadd.selectedMaxAmount = amount
		-- Check for dropping below min amount
		if  menu.wplistadd.selectedMaxAmount < menu.wplistadd.selectedMinAmount then
			menu.wplistadd.selectedMinAmount = menu.wplistadd.selectedMaxAmount
		end
	else
		menu.wplistadd.selectedMinAmount = amount
		-- Check for exceding max amount
		if menu.wplistadd.selectedMinAmount > menu.wplistadd.selectedMaxAmount then
			menu.wplistadd.selectedMaxAmount = menu.wplistadd.selectedMinAmount 
		end
	end
	-- Signal that the ware amount changed and re-check
	Utility.MenuCheck(false)
	menu.display()
	return
end

-- Callback to increment buy/sell price
function Buttons:IncWarePrice()
	local pricerange = menu.wplistadd.waremaxprice - menu.wplistadd.wareminprice
	if pricerange < 100 then
		menu.wplistadd.warePrice = menu.wplistadd.warePrice + 1
	elseif pricerange < 1000 then
		menu.wplistadd.warePrice = menu.wplistadd.warePrice + 10
	elseif pricerange < 10000 then
		menu.wplistadd.warePrice = menu.wplistadd.warePrice + 100
	elseif pricerange < 100000 then
		menu.wplistadd.warePrice = menu.wplistadd.warePrice + 1000
	else
		menu.wplistadd.warePrice = menu.wplistadd.warePrice + 10000
	end
	if menu.wplistadd.warePrice > menu.wplistadd.waremaxprice then
		menu.wplistadd.warePrice = menu.wplistadd.waremaxprice
	end
	if menu.wplistadd.warePrice < menu.wplistadd.wareminprice then
		menu.wplistadd.warePrice = menu.wplistadd.wareminprice
	end  -- covers adding a new waypoint where price is unknown so set to zero
	Utility.MenuCheck(false)
	menu.display()
end

-- Callback to Decrement buy/sell price
function Buttons:DecWarePrice()
	local pricerange = menu.wplistadd.waremaxprice - menu.wplistadd.wareminprice
	if pricerange < 100 then
		menu.wplistadd.warePrice = menu.wplistadd.warePrice - 1
	elseif pricerange < 1000 then
		menu.wplistadd.warePrice = menu.wplistadd.warePrice - 10
	elseif pricerange < 10000 then
		menu.wplistadd.warePrice = menu.wplistadd.warePrice - 100
	elseif pricerange < 100000 then
		menu.wplistadd.warePrice = menu.wplistadd.warePrice - 1000
	else
		menu.wplistadd.warePrice = menu.wplistadd.warePrice - 10000
	end
	if menu.wplistadd.warePrice < menu.wplistadd.wareminprice then
		menu.wplistadd.warePrice = menu.wplistadd.wareminprice
	end
	Utility.MenuCheck(false)
	menu.display()
end

-- Callback to set ware price to mac min avg
function Buttons:SetWarePrice( value )
	if value == "max" then
		menu.wplistadd.warePrice = menu.wplistadd.waremaxprice
	elseif value == "avg" then
		menu.wplistadd.warePrice = menu.wplistadd.wareavgprice
	else
		menu.wplistadd.warePrice = menu.wplistadd.wareminprice
	end
	Utility.MenuCheck(false)
	menu.display()
	return	
end

-- Callback for decreasing range
Buttons.DecRange = function()
	menu.wplistadd.selectedRange = menu.wplistadd.selectedRange - 1
	if menu.wplistadd.selectedRange == 0 then
		menu.wplistadd.selectedRange = menu.wplistadd.trader_range + 1 end
	menu.display()
	return
end

-- Callback for increasing range
Buttons.IncRange = function()
	menu.wplistadd.selectedRange = menu.wplistadd.selectedRange + 1
	if menu.wplistadd.selectedRange > menu.wplistadd.trader_range + 1 then
		menu.wplistadd.selectedRange = 1 end
	menu.display()
	return
end

-- Callback function for waypoint editor back button
Buttons.Back = function()
	local return_waypoint = menu.wplistadd.waypoint
	Helper.closeMenuForSection(menu, false, "gMT_WPListMenu_return_list", { 0, 0, {}, {}, {}, menu.wplistadd.trader, {}})
	menu.cleanup()
	return
end

-- Callback function for waypoint editor done button
Buttons.Done = function()
	local waypoint_params = { menu.wplistadd.selectedWPType, menu.wplistadd.activewares[menu.wplistadd.selectedWare], 
									menu.wplistadd.selectedMaxAmount, menu.wplistadd.selectedMinAmount, menu.wplistadd.warePrice,
										menu.wplistadd.selectedRange, menu.wplistadd.selectedWare,
											menu.wplistadd.MaxWareAmount, menu.wplistadd.MinWareAmount}
	Helper.closeMenuForSection(menu, false, "gMT_WPListMenu_return_getstations", { 0, 0, {}, {}, {}, menu.wplistadd.trader, waypoint_params})
	menu.cleanup()
	return
end

-- Callback for map button - switches to old mapselect method
Buttons.Map = function()
	Helper.closeMenuForSection(menu, false, "gMT_WPListMenu_editwaypoint", { 0, 0, {}, {0,0,0,"mapswitch"}, {}, menu.wplistadd.trader, waypoint_params})
	menu.cleanup()
	return
end

-- Availability for done
Availability.Done = function ()
	return  menu.wplistadd.selectedMaxAmount > 0 and menu.wplistadd.selectedMinAmount > 0 and #menu.wplistadd.activewares > 0
end

-- Checking function
Utility.MenuCheck = function( warehaschanged )
	-- Check when waypoint type changes to update ware list
	-- get lists of wares from passed homebase list
	local wplist = {}
	local resources = menu.wplistadd.homebasewares[1] or {}
	local products = menu.wplistadd.homebasewares[2] or {}
	-- these are wares bought by e.g. shipyards - drones, ammo etc.
	local tradewares = menu.wplistadd.homebasewares[3] or {}
	local cargolist = menu.wplistadd.cargo
	-- remove small and medium ships from lists
	resources = LibMT.RemoveWares( resources, "ship" )
	products = LibMT.RemoveWares( products, "ship" )
	tradewares = LibMT.RemoveWares( tradewares, "ship" )
	-- Filter list against cargo type
	resources, products, tradewares, allwares, menu.bool.shipCanRefuel 
			= LibMT.CompareStationWarelist( resources, products, tradewares, cargolist ) 
	local intermediates = LibMT.Set.Intersection( resources, products)
	
	-- filter list against WP type
	if menu.wplistadd.selectedWPType == 1 then -- load i.e. stuff our HB needs and can sell
		wplist = LibMT.Set.Symmetric(resources, tradewares)
		wplist = LibMT.Set.Symmetric(wplist, products)
	elseif menu.wplistadd.selectedWPType == 3 then -- buy i.e. stuff our HB needs
		wplist = LibMT.Set.Symmetric(resources, tradewares)
	elseif menu.wplistadd.selectedWPType == 2 or menu.wplistadd.selectedWPType == 4 then -- unload or sell i.e. stuff our HB sells
		wplist = products
	end
	if not menu.bool.IncludeIntermediateResources then
		wplist = LibMT.Set.Difference(wplist, intermediates)
	end
	menu.wplistadd.activewares = wplist

	-- Check and calculate ware amounts here
	if 0 < #menu.wplistadd.activewares then
		local ware_lib = GetLibraryEntry("wares", menu.wplistadd.activewares[menu.wplistadd.selectedWare])
		menu.wplistadd.warevolume = ware_lib.volume
		menu.wplistadd.wareminprice, menu.wplistadd.wareavgprice, menu.wplistadd.waremaxprice = GetWareData( menu.wplistadd.activewares[menu.wplistadd.selectedWare], "minprice", "avgprice", "maxprice")

		if (menu.wplistadd.warePrice == 0) or warehaschanged then  -- catch first display
			menu.wplistadd.warePrice = menu.wplistadd.wareavgprice
		end

		local waretransport = GetWareData(menu.wplistadd.activewares[menu.wplistadd.selectedWare], "transport")
		-- calculate the ware number from the amount selected
		if menu.wplistadd.cargo[6] > 0 then  -- universal
			menu.wplistadd.MaxWareAmount = math.floor(menu.wplistadd.cargo[6]*menu.wplistadd.selectedMaxAmount/(menu.wplistadd.warevolume*100), 0)
			menu.wplistadd.MinWareAmount = math.floor(menu.wplistadd.cargo[6]*menu.wplistadd.selectedMinAmount/(menu.wplistadd.warevolume*100), 0)
		elseif CheckSuitableTransportType(menu.wplistadd.trader[1], "nividium") and waretransport == "bulk" then
			menu.wplistadd.MaxWareAmount = math.floor(menu.wplistadd.cargo[2]*menu.wplistadd.selectedMaxAmount/(menu.wplistadd.warevolume*100), 0)
			menu.wplistadd.MinWareAmount = math.floor(menu.wplistadd.cargo[2]*menu.wplistadd.selectedMinAmount/(menu.wplistadd.warevolume*100), 0)
		elseif CheckSuitableTransportType(menu.wplistadd.trader[1], "chemicalcompounds") and waretransport == "container" then
			menu.wplistadd.MaxWareAmount = math.floor(menu.wplistadd.cargo[3]*menu.wplistadd.selectedMaxAmount/(menu.wplistadd.warevolume*100), 0)
			menu.wplistadd.MinWareAmount = math.floor(menu.wplistadd.cargo[3]*menu.wplistadd.selectedMinAmount/(menu.wplistadd.warevolume*100), 0)
		elseif CheckSuitableTransportType(menu.wplistadd.trader[1], "ioncells") and waretransport == "energy" then
			menu.wplistadd.MaxWareAmount = math.floor(menu.wplistadd.cargo[4]*menu.wplistadd.selectedMaxAmount/(menu.wplistadd.warevolume*100), 0)
			menu.wplistadd.MinWareAmount = math.floor(menu.wplistadd.cargo[4]*menu.wplistadd.selectedMinAmount/(menu.wplistadd.warevolume*100), 0)
		elseif CheckSuitableTransportType(menu.wplistadd.trader[1], "ions") and waretransport == "liquid" then
			menu.wplistadd.MaxWareAmount = math.floor(menu.wplistadd.cargo[5]*menu.wplistadd.selectedMaxAmount/(menu.wplistadd.warevolume*100), 0)
			menu.wplistadd.MinWareAmount = math.floor(menu.wplistadd.cargo[5]*menu.wplistadd.selectedMinAmount/(menu.wplistadd.warevolume*100), 0)
		end
	end
end

init()

return
