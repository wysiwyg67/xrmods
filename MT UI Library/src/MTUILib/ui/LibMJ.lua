--[[
	This file is part of the X Rebirth LibMJ script library.
	
	Author: MadJoker
  
	Last Change:
	Version: V0.0.1
	Date: 1st May 2014
  
	X Rebirth version: 1.31
--]]

-- catch the case where menus tried to register before LibMJ was initialized
local registerFuncs = {}
if LibMJ then
	registerFuncs = LibMJ.registerFuncs
end

LibMJ = {
	menus = {},
	stack = nil,
	closeAll = false,
	-- data needed for Egosoft's Helper
	name = "LibMJ",
	param = { nil, nil },
	rowDataMap = {}
}

LibMJ.colors = {
	white = { r = 255, g = 255, b = 255, a = 100 },
	red = {	r = 255, g = 0, b = 0, a = 100 },
	green = { r = 0, g = 255, b = 0, a = 100 },
	blue = { r = 0, g = 0, b = 255, a = 100 },
	transparent = { r = 0, g = 0, b = 0, a = 0 }
}

LibMJ.hotkeys = {
	"INPUT_STATE_DETAILMONITOR_B",
	"INPUT_STATE_DETAILMONITOR_BACK",
	"INPUT_STATE_DETAILMONITOR_Y",
	"INPUT_STATE_DETAILMONITOR_X",
	"INPUT_STATE_DETAILMONITOR_LB",
	"INPUT_STATE_DETAILMONITOR_RB",
	"INPUT_STATE_DETAILMONITOR_A",
	"INPUT_STATE_DETAILMONITOR_0"
}

local function init()
	LibMJ.fixBugs()

	for _, func in ipairs(registerFuncs) do
		func()
	end
	registerFuncs = nil

	Menus = Menus or {}
	table.insert(Menus, LibMJ)
	
	if Helper then
		Helper.registerMenu(LibMJ)
	end
end

LibMJ.fixBugs = function ()
	Helper.removeButtonScripts = function (menu, tableobj, row, col)
		menu.buttonScriptMap = menu.buttonScriptMap or {}

		-- switched start and end value
		for i = #menu.buttonScriptMap, 1, -1 do
			local scriptdata = menu.buttonScriptMap[i]

			if scriptdata.tableobj == tableobj and scriptdata.row == row and scriptdata.col == col then
				Helper.removeButtonScript(scriptdata.tableobj, scriptdata.row, scriptdata.col, scriptdata.type, scriptdata.script)
				table.remove(menu.buttonScriptMap, i)
			end
		end
	end
end

-- initialize menu
LibMJ.onShowMenu = function ()
	-- set some global constants which can't be set outside since they depend on other files being loaded first
	LibMJ.mapSizeY = Helper.standardSizeY - Helper.tableOffsety - 20
	LibMJ.mapSizeX = LibMJ.mapSizeY

	local self = LibMJ
	local startMenu = self.param[1]
	local args = self.param
	self.param = nil
	table.remove(args, 1)
	
	self.stack = self.stack or Stack:Create()
	
	-- we put an empty container on the stack to catch return parameters
	self.stack:push({ menu = { name = startMenu, onReturnArgsReceived = LibMJ.exitMenu } })
	self:OpenMenu(startMenu, nil, args)
end

LibMJ.exitMenu = function (state, isClosingAll, returnArgs)
	local self = LibMJ
	-- we need to pop our state
	local state = self.stack:pop()
	
	-- we can then return the return args
	Helper.closeMenuAndReturn(self, false, { state.menu.name, (self.closeAll and "close") or "back", unpack(returnArgs) })
end

-- either return to last menu or close altogether
LibMJ.onCloseElement = function (dueToClose)
	local self = LibMJ
	-- if user closed all menus, we iterate over the stack and close all
	if dueToClose == "close" then
		-- we set the flag to indicate no return menus need to be opened
		self.closeAll = true
		for i = 1, self.stack:getn() - 1 do
			self:CloseMenu()
		end
		self.closeAll = false
	else
		-- we close to top most menu
		self:CloseMenu()
	end
end

LibMJ.updateInterval = 0.5
LibMJ.onUpdate = function ()
	local self = LibMJ
	local state = self.stack:peek()
	
	-- check if menu is still visible
	if self.shown then
		
		-- we call the onUpdate callback of the current menu
		state.menu.onUpdate(state)
	end
	
	self:ActivateMap(state)
	self:SetSelectedRow()
end

LibMJ.onRowChanged = function (rowIdx, rowData)		
	local self = LibMJ
	local state = self.stack:peek()
	
	-- there are some "fake" events being fired on menu opening, so
	-- we make a distinction here
	if not state.opening then	
		rowData = rowData or {}
		
		self:CheckButtonBarAvailability(rowIdx, rowData)		
		
		-- we also call the onRowChanged callback of the current menu
		state.menu.onRowChanged(state, rowIdx, rowData)
		state.selectedRow = {
			idx = rowIdx,
			data = rowData
		}
	end
end

LibMJ.onSelectElement = function ()
end

function LibMJ:RegisterMenu(name, onMenuInit, onMenuClosed, onReturnArgsReceived, titleProvider, rowProvider, menuTypeInfo, onUpdate, onRowChanged)
	assert(name, "Menu must have a name")
	self.menus[name] = {
		name = name,
		onMenuInit = onMenuInit or function () end,
		onMenuClosed = onMenuClosed or function () end,
		onReturnArgsReceived = onReturnArgsReceived or function () end,
		titleProvider = titleProvider or function () return "" end,
		rowProvider = rowProvider or function () return { LibMJ:Cell() }, { 0 } end, -- returns rows and column widths
		menuTypeInfo = menuTypeInfo or {
			type = "default",
			provider = function () return {} end
		},
		onUpdate = onUpdate or function () end,
		onRowChanged = onRowChanged or function () end
	}
end

function LibMJ:Row(cells, rowData, bgColor, isFixed, nrOfChildRows)	
	return {
		cells = cells or { Helper.getEmptyCellDescriptor() },
		data = rowData,
		bgColor = bgColor,
		isFixed = isFixed,
		nrOfChildRows = nrOfChildRows or 0
	}
end

function LibMJ:Cell(element, script, colspan)
	return self:CreateCell(element, nil, script, colspan)
end

function LibMJ:ButtonCell(element, script, colspan, selectable, color, fontSize, isBold)
	local canSelect = true
	if selectable ~= nil then
		canSelect = selectable
	end
	local button = element
	if type(element) == "string" then
		button = LibMJ:CreateDefaultCenterButton(element, canSelect, color, fontSize, isBold)
	end
	return self:CreateCell(button, "button", script, colspan)
end

function LibMJ:EditBoxCell(element, script, colspan)
	return self:CreateCell(element, "editBox", script, colspan)
end

function LibMJ:CreateCell(element, type, script, colspan)
	return {
		element = element or Helper.getEmptyCellDescriptor(),
		type = type or "text",
		script = script,
		colspan = colspan or 1
	}
end

function LibMJ:BarButton(label, script, availabilityProvider, hotkey)
	return {
		label = label,
		script = script or function () end, -- function(rowIdx, rowData)
		availabilityProvider = availabilityProvider or function () return true end, -- function(rowIdx, rowData) : bool (determine whether button is selectable)
		hotkey = hotkey
	}
end

function LibMJ:OpenMenu(name, state, ...)
	assert(self.menus[name], "Menu '" .. name .. "' is not registered!")
	
	-- if we are closing all windows, we need to prevent opening new ones
	if self.closeAll then
		return
	end
	
	local menu = self.menus[name]
	
	-- remove all button scripts for the active menu
	Helper.removeAllButtonScripts(self.stack:peek())
	Helper.removeAllMenuScripts(self)
	
	-- if this is a new menu, we push it on the stack
	if not state then
		state = { menu = menu, param = { nil, nil }, args = { ... } }
		-- Helper related stuff
		state.interactive = true
		state.buttonOver = self.buttonOver
		state.buttonDown = self.buttonDown
		
		-- put the new menu on the stack
		self.stack:push(state)
		menu.onMenuInit(state, unpack(state.args))
	end

	Helper.currentTableRow = 0
	Helper.currentTableRowData = nil
		
	local isMap = menu.menuTypeInfo.type == "map"
	local renderTarget = nil
	
	-- if the screen is a map, we have to initialize it first, before creating header and body
	if isMap then
		renderTarget = self:CreateMap(state, menu)		
	end
	
	local cellScripts = {}
	local header = self:CreateHeader(state, menu, cellScripts)
	local body = self:CreateBody(state, menu, cellScripts)
		
	-- the last "false" makes the annoying transition effect disappear
	if menu.menuTypeInfo.type == "slider" then
		local slider = self:CreateSlider(state, menu)
		state.headerTable, state.bodyTable, state.sliderTable = Helper.displayTwoTableSliderView(self, header, body, slider, true, nil, nil, nil, nil, nil, nil, nil, false)
	elseif isMap then
		state.headerTable, state.bodyTable, state.renderTarget = Helper.displayTwoTableRenderTargetView(self, header, body, renderTarget, false, "", "", 0, 0, 0, 0, "both", false)
	elseif menu.menuTypeInfo.type == "buttons" then
		local buttonBar = self:CreateButtonBar(state, menu, cellScripts)
		state.headerTable, state.bodyTable, state.buttonBarTable = Helper.displayThreeTableView(self, header, body, buttonBar, false, nil, nil, nil, nil, nil, nil, nil, false)
	else
		state.headerTable, state.bodyTable = Helper.displayTwoTableView(self, header, body, false, nil, nil, nil, nil, nil, nil, nil, false)
	end
	
	-- finally, we call all the script attaching functions
	for _, func in ipairs(cellScripts) do
		func()
	end
	
	Helper.releaseDescriptors()
	
	state.opening = true
end

function LibMJ:CloseMenu() 
	local state = self.stack:pop()
	
	Helper.removeAllButtonScripts(state)
	
	if state.holoMap then
		self:CloseMap(state)
	end
	
	local prevState = self.stack:peek()
	local reopenMenu = prevState.menu.onReturnArgsReceived(prevState, self.closeAll, state.menu.onMenuClosed(state), state.menu.name)
	
	-- only re-open menu if requested and we are not closing all menus
	if reopenMenu and not self.closeAll then
		self:OpenMenu(prevState.menu.name, prevState)
	end
end

function LibMJ:RefreshMenu()
	local state = self.stack:peek()
	self:OpenMenu(state.menu.name, state)
end

function LibMJ:CreateHeader(state, menu, cellScripts)
	-- create header
	local headerSetup = Helper.createTableSetup(self)
	
	local titleString, infoMenu, infoMenuArgs = menu.titleProvider(state)
	local title = Helper.createFontString(titleString, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize, false, Helper.headerRow1Offsetx, Helper.headerRow1Offsety, Helper.headerRow1Height, Helper.headerRow1Width)
	
	if infoMenu then
		local infoIconButton = Helper.createButton(nil, Helper.createButtonIcon("menu_info", nil, 255, 255, 255, 100), false)
		headerSetup:addSimpleRow({ infoIconButton, title }, nil, { 1, 3, 1 }, false, Helper.defaultTitleBackgroundColor)
		
		-- button script for info menu
		table.insert(cellScripts, function ()
			Helper.setButtonScript(state, nil, state.headerTable, 1, 1, function ()
				self:OpenMenu(infoMenu, nil, unpack(infoMenuArgs))
			end)
		end)
	else
		headerSetup:addSimpleRow({ title }, nil, { 4, 1 }, false, Helper.defaultTitleBackgroundColor)
	end
	
	-- add empty spanning row
	if menu.menuTypeInfo.type == "map" then		
		local info = state.holoMapInfo or {}
		
		local upButton = self:CreateDefaultCenterButton("Up", false)
		local downButton = self:CreateDefaultCenterButton("Down", false)
		local selectButton = self:CreateDefaultCenterButton("Select", false)
		local cells = { upButton, downButton, selectButton, Helper.getEmptyCellDescriptor() }
		headerSetup:addSimpleRow(cells, nil, { 1, 1, 1, 2 })
	else
		headerSetup:addTitleRow({ Helper.getEmptyCellDescriptor() }, nil, { 5 })
	end

	local size = 40
	local colWidths = { size, size, size, 0, size + 37 }
	local isColumnWidthsInPercent = false
	local doNotScale = true
	local isBorderEnabled = true
	local tabOrder = 3
	local fixedRows = 2
	local offsetX = 0
	local offsetY = 0
	local height = 0 -- stretch to fill
	
	return headerSetup:createCustomWidthTable(colWidths, isColumnWidthsInPercent, doNotScale, isBorderEnabled, tabOrder, fixedRows, offsetX, offsetY, height)
end

function LibMJ:CreateBody(state, menu, cellScripts)	
	local bodySetup = Helper.createTableSetup(self)
	state.rows = {}
	local colWidths, isColumnWidthsInPercent, bodyHeight = menu.rowProvider(state, state.rows)	
	state.bodyHeight = bodyHeight or 450
	
	local fixedRows = 0
	local sawNonFixedRow = false
	for rowIdx, row in ipairs(state.rows) do
		local elements, colspans = {}, {}
		local colIdx = 1
		for _, cell in ipairs(row.cells) do
			table.insert(elements, cell.element)
			table.insert(colspans, cell.colspan)
			if cell.script then
				local curColIdx = colIdx -- for closure
				table.insert(cellScripts, function()
					if cell.type == "button" then
						Helper.setButtonScript(state, nil, state.bodyTable, rowIdx, curColIdx, function () cell.script(rowIdx, colIdx) end) 
					end
					if cell.type == "editBox" then
						Helper.setEditBoxScript(state, nil, state.bodyTable, rowIdx, curColIdx, function (_, text, textchanged) cell.script(_, text, textchanged, rowIdx, colIdx) end) 
					end
				end)
			end
			colIdx = colIdx + cell.colspan
		end
		
		if row.isFixed then
			assert(not sawNonFixedRow, "Cannot add fixed rows after non-fixed rows")
			fixedRows = fixedRows + 1
		else
			sawNonFixedRow = true
			
			-- we save either the topmost or the last selected row
			state.topRow = state.topRow or state.selectedRow or {
				idx = rowIdx,
				data = row.data
			}
		end
		
		assert(colIdx - 1 == #colWidths, "Missmatch in nr of colWidths (" .. #colWidths .. ") and provided colspans (" .. colIdx - 1 .. ") in row " .. rowIdx .. "")
		
		bodySetup:addSimpleRow(elements, row.data, colspans, false, row.bgColor)
	end
	
	local isColumnWidthsInPercent = false
	local doNotScale = false
	local isBorderEnabled = true
	local tabOrder = 1
	local offsetX = (menu.menuTypeInfo.type == "map" and LibMJ.mapSizeX + 5) or 0
	local offsetY = Helper.tableOffsety
	
	return bodySetup:createCustomWidthTable(colWidths, isColumnWidthsInPercent or false, doNotScale, isBorderEnabled, tabOrder, fixedRows, offsetX, offsetY, state.bodyHeight, nil, nil, (state.selectedRow or {}).idx)
end

function LibMJ:CreateButtonBar(state, menu, cellScripts)
	if not menu.menuTypeInfo.type == "default" then
		return nil
	end

	local buttons = menu.menuTypeInfo.provider(state)
	
	if not buttons or #buttons == 0 then
		return nil
	end
	
	state.buttons = buttons

	-- this will be a two-row setup with 4 buttons in each row
	local buttonBarSetup = Helper.createTableSetup(self)
	local uiButtons = {}
	local emptyCell = Helper.getEmptyCellDescriptor()
	
	for i, button in ipairs(buttons) do
		if button and button.label then
			button.hotkey = button.hotkey or LibMJ.hotkeys[i]
			local hotkey = nil
			if button.hotkey ~= "" then
				hotkey = Helper.createButtonHotkey(button.hotkey, true)
			end
			local offsetY = (i > 4 and 10) or 0
			local b = self:CreateDefaultButtonBarButton(button.label, false, hotkey, nil, nil, nil, offsetY)
			table.insert(uiButtons, b)
		else
			table.insert(uiButtons, emptyCell)
		end
	end
	
	-- create first line of buttons
	local row1buttons = { emptyCell }
	for i = 1, 4 do
		if uiButtons[i] and uiButtons[i] ~= emptyCell then
			table.insert(row1buttons, uiButtons[i])
			buttons[i].row = 1
			buttons[i].col = 2 * i
		else
			table.insert(row1buttons, emptyCell)
		end
		table.insert(row1buttons, emptyCell)
	end
	
	-- create second line of buttons
	local row2buttons = { emptyCell }
	for i = 5, 8 do
		if uiButtons[i] and uiButtons[i] ~= emptyCell then
			table.insert(row2buttons, uiButtons[i])
			buttons[i].row = 2
			buttons[i].col = 2 * (i - 4)
		else
			table.insert(row2buttons, emptyCell)
		end
		table.insert(row2buttons, emptyCell)
	end
	
	buttonBarSetup:addSimpleRow(row1buttons, nil, nil, false, LibMJ.colors.transparent)
	buttonBarSetup:addSimpleRow(row2buttons, nil, nil, false, LibMJ.colors.transparent)
	
	local colWidths = { 38, 170, 38, 170, 0, 170, 38, 170, 38 }
	local isColumnWidthsInPercent = false
	local doNotScale = false
	local isBorderEnabled = true
	local tabOrder = 2
	local fixedRows = 2
	local offsetX = 0
	local offsetY = Helper.tableOffsety + state.bodyHeight - 10
	local height = 0 -- stretch to fill
	
	return buttonBarSetup:createCustomWidthTable(colWidths, isColumnWidthsInPercent, doNotScale, isBorderEnabled, tabOrder, fixedRows, offsetX, offsetY, height)
end

function LibMJ:CreateSlider(state, menu)
	if not menu.menuTypeInfo.type == "slider" then
		return nil
	end

	local sliderInfo, sliderScaleInfo1, sliderScaleInfo2, offsetY = menu.menuTypeInfo.provider(state)
	
	if not sliderInfo then
		return nil
	end
	
	local tabOrder = 2
	local offsetX = Helper.sliderOffsetx
	offsetY = offsetY or Helper.tableCharacterOffsety
	
	-- example slider info
	local sliderInfoExample = {
		background = "tradesellbuy_blur",
		captionLeft = "caption left",
		captionCenter = "caption center",
		captionRight = "caption right",
		min = 1,
		max = 50,
		minSelectable = 1,
		maxSelectable = 50,
		zero = 0, -- is subtracted from all values
		start = 10
	}
	local scaleInfoExample = {
		center = true, -- show value in center,
		floored = false, -- round decimal value down?
		inverted = false, -- invert the scale (i.e. left gets added, right subtracted)
		left = 0, -- left value offset (value will be offset - slider value); if nil no value shown
		right = 0, -- left value offset (value will be offset + slider value); if nil no value shown
		factor = 3, -- factor for slider value
		suffix = "km"
	}
	
	return Helper.createSlider(sliderInfo, sliderScaleInfo1, sliderScaleInfo2, tabOrder, offsetX, offsetY)
end

function LibMJ:CreateMap(state, menu)		
	-- we have to temporarily set some "constants" to different values
	Helper.standardFontSize = 11
	Helper.standardTextHeight = 20
	Helper.headerRow2FontSize = 11
	Helper.headerRow2Height = 20
	Helper.standardButtonWidth = 30
	
	local preSelectedComponent, preSelectedComponentType = menu.menuTypeInfo.provider(state)
	
	if allowNavUp == nil then
		allowNavUp = true
	end
	if allowNavDown == nil then
		allowNavDown = true
	end
		
	if not state.holoMapInfo then	
		state.activateMap = true
		state.holoMapInfo = { }

		if preSelectedComponent and preSelectedComponentType then
			state.holoMapInfo.component = preSelectedComponent
			state.holoMapInfo.componentType = preSelectedComponentType
		else
			-- in case no component was pre-selected, we show the current zone
			state.holoMapInfo.component = GetComponentData(GetPlayerPrimaryShipID(), "zoneid")
			state.holoMapInfo.componentType = "zone"
		end
			
		RegisterEvent("updateHolomap", LibMJ.onUpdateHoloMap)
	end
	
	return Helper.createRenderTarget(LibMJ.mapSizeX, LibMJ.mapSizeY, 0, Helper.tableOffsety)
end

function LibMJ:ActivateMap(state)	
	if state.activateMap then
		state.activateMap = nil
		local info = state.holoMapInfo
		
		state.holoMap = AddHoloMap(tostring(GetRenderTargetTexture(state.renderTarget)))
		
		ShowUniverseMap(state.holoMap, info.component)
		ClearHighlightMapComponent(state.holoMap)
		
		self:CheckNavButtonAvailability(state)
	end
end

function LibMJ:CloseMap(state)
	-- we reset the changed "constants"
	Helper.standardFontSize = 14
	Helper.standardTextHeight = 24
	Helper.headerRow2FontSize = 14
	Helper.headerRow2Height = 24
	Helper.standardButtonWidth = 36
	
	UnregisterEvent("updateHolomap", LibMJ.onUpdateHoloMap)
	
	RemoveHoloMap(state.holoMap)
	
	state.holoMap = nil
end

LibMJ.onUpdateHoloMap = function ()
	local self = LibMJ
	local state = self.stack:peek()
	
	local info = state.holoMapInfo
	if state.menu.menuTypeInfo.onUpdateHoloMap then
		if not info.lastUpdateHolomapTime then
			info.lastUpdateHolomapTime = 0
		end

		local curTime = GetCurRealTime()

		-- only react to holomap updates every 5 seconds
		local skipUpdates = info.noUpdate
		local wasRecentlyUpdated = info.lastUpdateHolomapTime > curTime - 5
		local isZone = info.componentType == "zone"
		local isSector = info.componentType == "sector"
		
		if (isZone or isSector) and not wasRecentlyUpdated and not skipUpdates then
			info.lastUpdateHolomapTime = curTime
			state.menu.menuTypeInfo.onUpdateHoloMap(state)
		end
	end
end

function LibMJ:CheckNavButtonAvailability(state)
	local allowNavUp, allowNavDown, allowSelectOnLevel = state.menu.menuTypeInfo.navButtonAvailabilityProvider(state)
		
	Helper.removeButtonScripts(state, state.headerTable, 2, 1)
	Helper.removeButtonScripts(state, state.headerTable, 2, 2)
	Helper.removeButtonScripts(state, state.headerTable, 2, 3)
	
	local upButton = self:CreateDefaultCenterButton("Up", allowNavUp)
	local downButton = self:CreateDefaultCenterButton("Down", allowNavDown)
	local selectButton = self:CreateDefaultCenterButton("Select", allowSelectOnLevel)
		
	SetCellContent(state.headerTable, upButton, 2, 1)
	SetCellContent(state.headerTable, downButton, 2, 2)
	SetCellContent(state.headerTable, selectButton, 2, 3)
	
	-- button script for navigating up the map
	Helper.setButtonScript(state, nil, state.headerTable, 2, 1, function ()
		self:MapNavigateUp(state)
	end)
	
	-- button script for navigating down the map
	Helper.setButtonScript(state, nil, state.headerTable, 2, 2, function ()
		self:MapNavigateDown(state)
	end)
	
	-- button script for selecting an element
	Helper.setButtonScript(state, nil, state.headerTable, 2, 3, function ()
		self:MapSelectAndReturn(state)
	end)
end

function LibMJ:MapNavigateUp(state)
	local info = state.holoMapInfo
	
	info.selectedComponent = info.component
	if info.componentType == "cluster" then
		info.component = GetComponentData(info.component, "galaxyid")
		info.componentType = "galaxy"
	elseif info.componentType == "sector" then
		info.component = GetComponentData(info.component, "clusterid")
		info.componentType = "cluster"
	elseif info.componentType == "zone" then
		info.component = GetComponentData(info.component, "sectorid")
		info.componentType = "sector"
	elseif info.componentType == "container" then
		info.component = GetComponentData(info.component, "zoneid")
		info.componentType = "zone"
	end
	
	ShowUniverseMap(state.holoMap, info.component)
	ClearHighlightMapComponent(state.holoMap)

	LibMJ:RefreshMenu()
	
	self:CheckNavButtonAvailability(state)
end

function LibMJ:MapNavigateDown(state)
	local info = state.holoMapInfo
	
	info.component = info.selectedComponent
	if info.componentType == "galaxy" then
		info.componentType = "cluster"
	elseif info.componentType == "cluster" then
		info.componentType = "sector"
	elseif info.componentType == "sector" then
		info.componentType = "zone"
	elseif info.componentType == "zone" then
		info.componentType = "container"
	end
	
	ShowUniverseMap(state.holoMap, info.component)
	ClearHighlightMapComponent(state.holoMap)
	
	LibMJ:RefreshMenu()
	
	self:CheckNavButtonAvailability(state)
end

function LibMJ.indexOf(t, el, comp)
	comp = comp or (function (x, y) return x == y end)	
	for i, item in ipairs(t) do
		if comp(item, el) then
			return i
		end
	end	
	return -1
end

function LibMJ:CreateDefaultCenterButton(label, selectable, color, fontSize, isBold)
	color = color or self.colors.white
	local text = Helper.createButtonText(label, "center", (isBold and Helper.standardFontBold) or Helper.standardFont, fontSize or Helper.standardFontSize, color.r, color.g, color.b, color.a)
	return Helper.createButton(text, nil, false, selectable, 0, 0, 0, Helper.standardTextHeight)
end

function LibMJ:CreateDefaultButtonBarButton(label, selectable, hotkey, color, fontSize, width, offsetY)
	color = color or self.colors.white
	local text = Helper.createButtonText(label, "center", Helper.standardFont, fontSize or 11, color.r, color.g, color.b, color.a)
	return Helper.createButton(text, nil, false, selectable, 0, offsetY or 0, width or 170, 25, nil, hotkey)
end

function LibMJ:AddRows(parentRowIdx, count, skipRefresh)
	local wasExpanded = LibMJ:IsExpanded(parentRowIdx)
	LibMJ:CollapseRow(parentRowIdx, true)
	
	for i = 1, count do
		self:AddRow(parentRowIdx, true)
	end
	
	if wasExpanded then
		LibMJ:ExpandRow(parentRowIdx, true)
	end
	
	if not skipRefresh then
		self:RefreshMenu()
	end
end

function LibMJ:AddRow(parentRowIdx, skipRefresh)
	local state = self.stack:peek()
	
	local wasExpanded = LibMJ:IsExpanded(parentRowIdx)
	LibMJ:CollapseRow(parentRowIdx, true)
	
	-- we have to add a row expand state for the new row
	self:AddRowExpandState(parentRowIdx)
	
	if wasExpanded then
		LibMJ:ExpandRow(parentRowIdx, true)
	end
	
	if not skipRefresh then
		self:RefreshMenu()
	end
end

function LibMJ:RemoveRows(rowIdx, count, skipRefresh)
	for i = 1, count do
		self:RemoveRow(rowIdx, true)
	end
	
	if not skipRefresh then
		self:RefreshMenu()
	end
end

function LibMJ:RemoveRow(rowIdx, skipRefresh)
	local state = self.stack:peek()
	
	-- we collapse the removed row first
	self:CollapseRow(rowIdx, true)
	
	-- then, we remove the expand state
	self:DeleteRowExpandState(rowIdx)

	-- we then have to adjust the selected row index if it was below the removed row
	if state.selectedRow and state.selectedRow.idx > rowIdx then
		state.selectedRow.idx = state.selectedRow.idx - 1
	end
	
	if not skipRefresh then
		self:RefreshMenu()
	end
end

function LibMJ:ToggleRow(rowIdx, skipRefresh)
	if self:IsExpanded(rowIdx) then
		self:CollapseRow(rowIdx, skipRefresh)
	else
		self:ExpandRow(rowIdx, skipRefresh)
	end
end

function LibMJ:ExpandRow(rowIdx, skipRefresh)
	local state = self.stack:peek()
	
	state.expandStates = state.expandStates or {}
	
	assert(rowIdx <= #state.rows, "Row index (" .. rowIdx .. ") is larger than number of rows (" .. #state.rows .. ")")
	
	local currentIdx, rowsLeft, nrOfExpandedRows = LibMJ:ExpandRowHelper(state.expandStates, 0, 99999, rowIdx)
	
	assert(currentIdx == rowIdx, "Error during row expansion: mismatch in returned current row index (" .. currentIdx .. ") and target row index (" .. rowIdx .. ")")
	assert(rowsLeft == 0, "Error during row expansion: number of rows left > 0")
	
	-- we have to adjust the selected row index if it was below the expanded row
	if state.selectedRow and state.selectedRow.idx > rowIdx then
		state.selectedRow.idx = state.selectedRow.idx + nrOfExpandedRows
	end
	
	if not skipRefresh then
		self:RefreshMenu()
	end
end

function LibMJ:ExpandRowHelper(rowStates, currentIdx, nrOfChildRows, rowsLeft)
	local state = self.stack:peek()
	for i = 1, nrOfChildRows do
		rowsLeft = rowsLeft - 1
		currentIdx = currentIdx + 1
		local row = state.rows[currentIdx]
		
		if not rowStates[i] then
			rowStates[i] = {
				expanded = false,
				childStates = {},
				nrOfChildRows = row.nrOfChildRows,
				rowsTotal = row.nrOfChildRows
			}
		end
	
		-- if the target index reached 0, we expand the row
		if rowsLeft == 0 then
			-- how many rows are we expanding? 0 if the row was already expanded
			local nrOfExpandedRows = (rowStates[i].expanded and 0) or rowStates[i].rowsTotal
			rowStates[i].expanded = true
			return currentIdx, rowsLeft, nrOfExpandedRows
		end
		
		-- if this row is expanded, we have to go through the child rows as well
		if rowStates[i].expanded then
			local nrOfExpandedRows = 0
			currentIdx, rowsLeft, nrOfExpandedRows = LibMJ:ExpandRowHelper(rowStates[i].childStates, currentIdx, rowStates[i].nrOfChildRows, rowsLeft)
			
			-- we have to accumulate our total child row count
			rowStates[i].rowsTotal = rowStates[i].rowsTotal + nrOfExpandedRows
			
			-- then, if there are no more rows left, we can return
			if rowsLeft == 0 then
				return currentIdx, rowsLeft, nrOfExpandedRows
			end
		end
	end
	
	return currentIdx, rowsLeft, 0
end

function LibMJ:CollapseRow(rowIdx, skipRefresh)
	local state = self.stack:peek()
	state.expandStates = state.expandStates or {}
	
	assert(rowIdx <= #state.rows, "Row index (" .. rowIdx .. ") is larger than number of rows (" .. #state.rows .. ")")
	local rowsLeft, nrOfCollapsedRows = LibMJ:CollapseRowHelper(state.expandStates, 99999, rowIdx)
	
	assert(rowsLeft == 0, "Error during row collapsing: number of rows left > 0")
	
	-- we have to adjust the selected row index if it was below the collapsed row
	if state.selectedRow and state.selectedRow.idx > rowIdx then
		-- if we had a row selected, that is not visible any more now, we set the collapsed row to be selected
		if state.selectedRow.idx <= rowIdx + nrOfCollapsedRows then
			state.selectedRow.idx = rowIdx
		else
			state.selectedRow.idx = state.selectedRow.idx - nrOfCollapsedRows
		end
	end
	
	if not skipRefresh then
		self:RefreshMenu()
	end
end

function LibMJ:CollapseRowHelper(rowStates, nrOfChildRows, rowsLeft)
	for i = 1, nrOfChildRows do
		rowsLeft = rowsLeft - 1
	
		-- if the target index reached 0, we collapse the row
		if rowsLeft == 0 then
			if not rowStates[i] then
				return rowsLeft, 0
			end
		
			-- how many rows are we collapsing? 0 if the row was already collapsed
			local nrOfCollapsedRows = (rowStates[i].expanded and rowStates[i].rowsTotal) or 0
			rowStates[i].expanded = false
			return rowsLeft, nrOfCollapsedRows
		end
		
		-- if this row is expanded, we have to go through the child rows as well
		if rowStates[i] and rowStates[i].expanded then
			local nrOfCollapsedRows = 0
			rowsLeft, nrOfCollapsedRows = LibMJ:CollapseRowHelper(rowStates[i].childStates, rowStates[i].nrOfChildRows, rowsLeft)
			
			-- we have to accumulate our total child row count
			rowStates[i].rowsTotal = rowStates[i].rowsTotal - nrOfCollapsedRows
			
			-- then, if there are no more rows left, we can return
			if rowsLeft == 0 then
				return rowsLeft, nrOfCollapsedRows
			end
		end
	end
	
	return rowsLeft, 0
end

function LibMJ:AddRowExpandState(parentRowIdx)
	local state = self.stack:peek()
	state.expandStates = state.expandStates or {}
	
	-- setting the parentRowIdx to to #rows + 1 lets the helper enumerate all rows in the expand state
	parentRowIdx = parentRowIdx or #state.rows + 1
	parentRowIdx = (parentRowIdx > 0 and parentRowIdx) or #state.rows + 1
	
	assert(parentRowIdx <= #state.rows + 1, "Parent row index (" .. parentRowIdx .. ") is larger than number of rows (" .. #state.rows .. ") + 1")
	
	local _, rowsLeft = LibMJ:AddRowExpandStateHelper(state.expandStates, 0, 99999, parentRowIdx)
	
	-- check if the new row was added at the total end
	if rowsLeft > 0 then
		local newState = {
			expanded = false,
			childStates = {},
			nrOfChildRows = 0, -- will be updated once the row is expanded, until then it doesn't matter
			rowsTotal = 0
		}
		table.insert(state.expandStates, newState)
	end
end

function LibMJ:AddRowExpandStateHelper(rowStates, currentIdx, nrOfChildRows, rowsLeft)
	local state = self.stack:peek()
	
	for i = 1, nrOfChildRows do
		rowsLeft = rowsLeft - 1
		currentIdx = currentIdx + 1
		
		local row = state.rows[currentIdx]
		
		if not rowStates[i] then
			rowStates[i] = {
				expanded = false,
				childStates = {},
				nrOfChildRows = row.nrOfChildRows,
				rowsTotal = row.nrOfChildRows
			}
		end
	
		-- if the target index reached 0, we found the parent row to add a state to
		if rowsLeft == 0 then
			-- we check, if we the state should be added to this state, or the one one level up
			rowStates[i].nrOfChildRows = rowStates[i].nrOfChildRows + 1
			rowStates[i].rowsTotal = rowStates[i].rowsTotal + 1
			
			return currentIdx, rowsLeft
		end
		
		-- if this row is expanded, we have to go through the child rows as well
		if rowStates[i].expanded then
			currentIdx, rowsLeft, parentRowIdx = LibMJ:AddRowExpandStateHelper(rowStates[i].childStates, currentIdx, rowStates[i].nrOfChildRows, rowsLeft)
			
			-- then, if there are no more rows left, we can return
			if rowsLeft == 0 then
				return currentIdx, rowsLeft
			end
		end
	end
	
	return currentIdx, rowsLeft
end

function LibMJ:DeleteRowExpandState(rowIdx)
	local state = self.stack:peek()
	state.expandStates = state.expandStates or {}
	
	assert(rowIdx <= #state.rows, "Row index (" .. rowIdx .. ") is larger than number of rows (" .. #state.rows .. ")")
	
	local rowsLeft = LibMJ:DeleteRowExpandStateHelper(state.expandStates, 99999, rowIdx)
	
	assert(rowsLeft == 0, "Error during deletion of row expand state: number of rows left > 0")
end

function LibMJ:DeleteRowExpandStateHelper(rowStates, nrOfChildRows, rowsLeft)
	for i = 1, nrOfChildRows do
		rowsLeft = rowsLeft - 1
	
		-- if the target index reached 0, we remove the state
		if rowsLeft == 0 then
			table.remove(rowStates, i)
			return rowsLeft
		end
		
		-- if this row is expanded, we have to go through the child rows as well
		if rowStates[i] and rowStates[i].expanded then
			rowsLeft = LibMJ:DeleteRowExpandStateHelper(rowStates[i].childStates, rowStates[i].nrOfChildRows, rowsLeft)
			
			-- then, if there are no more rows left, we can return
			if rowsLeft == 0 then
				-- we also have to decrement our child count
				rowStates[i].nrOfChildRows = rowStates[i].nrOfChildRows - 1
				rowStates[i].rowsTotal = rowStates[i].rowsTotal - 1
				return rowsLeft
			end
		end
	end
	
	return rowsLeft
end

function LibMJ:IsExpanded(rowIdx)
	local state = self.stack:peek()
	state.expandStates = state.expandStates or {}
	
	-- assert(rowIdx <= #state.rows, "Row index (" .. rowIdx .. ") is larger than number of rows (" .. #state.rows .. ")")
	
	local rowsLeft, isExpanded, s = LibMJ:IsExpandedHelper(state.expandStates, 99999, rowIdx, 1)
	
	assert(rowsLeft == 0, "Error during row expansion check: number of rows left > 0")
	
	return isExpanded, s
end

function LibMJ:IsExpandedHelper(rowStates, nrOfChildRows, rowsLeft, indentLevel)
	local s = "\n"
	for i = 1, nrOfChildRows do
		for j = 1, indentLevel do
			s = s .. "..."
		end
		local state = rowStates[i] or {
			expanded = false,
			childStates = {},
			nrOfChildRows = 0,
			rowsTotal = 0
		}
		s = s .. i .. ": " .. tostring(state.expanded) .. ", " .. state.nrOfChildRows .. ", " .. rowsLeft .. "\n"
		
		rowsLeft = rowsLeft - 1
	
		-- if the target index reached 0, we return the current row's state
		if rowsLeft == 0 then
			if not rowStates[i] then
				return rowsLeft, false, s
			end
			return rowsLeft, rowStates[i].expanded, s
		end
		
		-- if this row is expanded, we have to go through the child rows as well
		if rowStates[i] and rowStates[i].expanded then
			local isExpanded = false
			rowsLeft, isExpanded, s2 = LibMJ:IsExpandedHelper(rowStates[i].childStates, rowStates[i].nrOfChildRows, rowsLeft, indentLevel + 1)
			s = s .. s2
			
			-- then, if there are no more rows left, we can return
			if rowsLeft == 0 then
				return rowsLeft, isExpanded, s
			end
		end
	end
	
	return rowsLeft, false, s
end

function LibMJ:ExpandDebug(rowStates, nrOfChildRows, indentLevel)
	local s = "\n"
	for i = 1, nrOfChildRows do
		for j = 1, indentLevel do
			s = s .. "..."
		end
		local state = rowStates[i] or {
			expanded = false,
			childStates = {},
			nrOfChildRows = 0,
			rowsTotal = 0
		}
		s = s .. i .. ": " .. tostring(state.expanded) .. ", " .. state.nrOfChildRows .. "\n"
		
		s = s .. LibMJ:ExpandDebug(state.childStates, state.nrOfChildRows, indentLevel + 1)
	end	
	return s
end

function LibMJ:CheckButtonBarAvailability(rowIdx, rowData)
	local state = self.stack:peek()
	
	if state.buttons then
		for _, button in ipairs(state.buttons) do
			if button and button.label then
				Helper.removeButtonScripts(state, state.buttonBarTable, button.row, button.col)
				local selectable = button.availabilityProvider(state, rowIdx, rowData)
				local offsetY = (button.row == 2 and 10) or 0
				local b = self:CreateDefaultButtonBarButton(button.label, selectable, Helper.createButtonHotkey(button.hotkey, true), nil, nil, nil, offsetY)
				SetCellContent(state.buttonBarTable, b, button.row, button.col)
				Helper.setButtonScript(state, nil, state.buttonBarTable, button.row, button.col, function () button.script(state, rowIdx, rowData) end)	
			end
		end
	end
end

function LibMJ:SetSelectedRow()
	local self = LibMJ
	local state = self.stack:peek()
	
	if state.opening then
		state.opening = nil
		local topRow = state.topRow
		state.topRow = nil
		
		if topRow and topRow.idx then
			-- we have to trigger the onRowChanged event here for the topmost row,
			-- since we will have swallowed it
			self.onRowChanged(topRow.idx, topRow.data)
		else
			self.onRowChanged(-1)
			state.selectedRow = nil
		end
		
		-- TODO: remove; is only for debugging
		local expandStates = state.expandStates or {}
		local s = LibMJ:ExpandDebug(expandStates, #expandStates, 0)
		s = s .. "\n.\n"
		for i = 1, #state.rows do
			local expanded, s2 = LibMJ:IsExpanded(i)
			s = s .. i .. ": " .. tostring(expanded) .. "\n"
			-- s = s .. s2 .. "\n"
		end
		-- assert(false, s)
	end
end

init()
