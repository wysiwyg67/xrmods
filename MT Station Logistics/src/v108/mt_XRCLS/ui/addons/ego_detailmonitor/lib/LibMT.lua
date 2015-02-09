--[[	This file is part of the X Rebirth MT script library mod.
		It is based on MadJoker's LibMT suite
		Author: Wysiwyg
  
		Last Change:
		Version: V0.0.1
		Date: 2014-12-12
  
		X Rebirth version: 3.00
--]]

-- catch early menu registration
local registerFuncs = {}
if LibMT then
	registerFuncs = LibMT.registerFuncs
end

-- Define the base table
LibMT = {
	menus = {},
	name = "LibMT",
	param = {nil, nil},
	rowDataMap = {}
}

-- Debugging switch for entire project - set to nil to turn OFF
LibMT.DEBUG = true
--  LibMT.DEBUG = nil

-- Predefined colours helper
LibMT.colours = {
	white = { r = 255, g = 255, b = 255, a = 100 },
	red = {	 g = 0, a = 100, b = 0,r = 255 },
	green = { r = 0, g = 255, b = 0, a = 100 },
	blue = { r = 0, g = 0, b = 255, a = 100 },
	transparent = { r = 0, g = 0, b = 0, a = 0 }
}

-- Hotkeys Helper
LibMT.hotkeys = {
	"INPUT_STATE_DETAILMONITOR_B",
	"INPUT_STATE_DETAILMONITOR_X",
	"INPUT_STATE_DETAILMONITOR_LB",
	"INPUT_STATE_DETAILMONITOR_RB",
	"INPUT_STATE_DETAILMONITOR_A",
	"INPUT_STATE_DETAILMONITOR_0",
	"INPUT_STATE_DETAILMONITOR_BACK",
	"INPUT_STATE_DETAILMONITOR_Y",
}

-- library initialisation function
local function init()
	for _, func in ipairs(registerFuncs) do
		func()
	end
	registerFuncs = nil
	
	Menus = Menus or {}
	table.insert(Menus, LibMT)
	
	if Helper then
		Helper.registerMenu( LibMT )
	end
end

function LibMT:Row(cells, rowData, bgColour, isFixed, nrOfChildRows)	
	return {
		cells = cells or { Helper.getEmptyCellDescriptor() },
		data = rowData,
		bgColour = bgColour,
		isFixed = isFixed,
		nrOfChildRows = nrOfChildRows or 0
	}
end

function LibMT:Cell(element, script, colspan)
	return self:CreateCell(element, nil, script, colspan)
end

function LibMT:ButtonCell(element, script, colspan, selectable, colour, fontSize, isBold)
	local canSelect = true
	if selectable ~= nil then
		canSelect = selectable
	end
	local button = element
	if type(element) == "string" then
		button = LibMT:CreateDefaultCenterButton(element, canSelect, colour, fontSize, isBold)
	end
	return self:CreateCell(button, "button", script, colspan)
end

function LibMT:EditBoxCell(element, script, colspan)
	return self:CreateCell(element, "editBox", script, colspan)
end

function LibMT:CreateCell(element, type, script, colspan)
	return {
		element = element or Helper.getEmptyCellDescriptor(),
		type = type or "text",
		script = script,
		colspan = colspan or 1
	}
end

function LibMT:BarButton(label, script, availabilityProvider, hotkey)
	return {
		label = label,
		script = script or function () end,
		availabilityProvider = availabilityProvider or function () return true end,
		hotkey = hotkey
	}
end




function LibMT:AddRows( menu, parentRowIdx, count, skipRefresh)
	local wasExpanded = LibMT:IsExpanded(menu,parentRowIdx)
	LibMT:CollapseRow(menu, parentRowIdx, true)
	
	for i = 1, count do
		self:AddRow(menu, parentRowIdx, true)
	end
	
	if wasExpanded then
		LibMT:ExpandRow(menu, parentRowIdx, true)
	end
	
	if not skipRefresh then
		menu.display()
	end
end

function LibMT:AddRow(menu, parentRowIdx, skipRefresh)
--	local state = self.stack:peek()
	
	local wasExpanded = LibMT:IsExpanded(menu, parentRowIdx)
	LibMT:CollapseRow(menu, parentRowIdx, true)
	
	-- we have to add a row expand state for the new row
	self:AddRowExpandState(menu, parentRowIdx)
	
	if wasExpanded then
		LibMT:ExpandRow(menu, parentRowIdx, true)
	end
	
	if not skipRefresh then
		menu.display()
	end
end

function LibMT:RemoveRows(menu, rowIdx, count, skipRefresh)
	for i = 1, count do
		self:RemoveRow(menu, rowIdx, true)
	end
	
	if not skipRefresh then
		menu.display()
	end
end

function LibMT:RemoveRow(menu, rowIdx, skipRefresh)
	-- we collapse the removed row first
	self:CollapseRow(menu, rowIdx, true)
	
	-- then, we remove the expand state
	self:DeleteRowExpandState(menu, rowIdx)

	-- we then have to adjust the selected row index if it was below the removed row
	if menu.selectedRow and menu.selectedRow.idx > rowIdx then
		menu.selectedRow.idx = menu.selectedRow.idx - 1
	end
	
	if not skipRefresh then
		menu.display()
	end
end

function LibMT:ToggleRow(menu, rowIdx, skipRefresh, isToggle)
	if LibMT:IsExpanded(menu, rowIdx) then
		LibMT:CollapseRow(menu, rowIdx, skipRefresh, isToggle)
	else
		LibMT:ExpandRow(menu, rowIdx, skipRefresh, isToggle)
	end
end

function LibMT:ExpandRow(menu, rowIdx, skipRefresh, isToggle)
	menu.expandStates = menu.expandStates or {}
	
	assert(rowIdx <= #menu.rows, "Row index (" .. rowIdx .. ") is larger than number of rows (" .. #menu.rows .. ")")
	
	local currentIdx, rowsLeft, nrOfExpandedRows = LibMT:ExpandRowHelper(menu, menu.expandStates, 0, 99999, rowIdx)
	
	assert(currentIdx == rowIdx, "Error during row expansion: mismatch in returned current row index (" .. currentIdx .. ") and target row index (" .. rowIdx .. ")")
	assert(rowsLeft == 0, "Error during row expansion: number of rows left > 0")
	
	-- we have to adjust the selected row index if it was below the expanded row if we do a toggle row
	if isToggle then
		if menu.selectedRow and menu.selectedRow.idx > rowIdx then
			menu.selectedRow.idx = menu.selectedRow.idx + nrOfExpandedRows
		end
	end
	
	menu.toprow = GetTopRow(menu.defaulttable)
	menu.selrow = menu.selectedRow.idx

	if not skipRefresh then
		menu.display()
	end
end

function LibMT:ExpandRowHelper(menu, rowStates, currentIdx, nrOfChildRows, rowsLeft)
--	local state = self.stack:peek()
	for i = 1, nrOfChildRows do
		rowsLeft = rowsLeft - 1
		currentIdx = currentIdx + 1
		local row = menu.rows[currentIdx]
		
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
			currentIdx, rowsLeft, nrOfExpandedRows = LibMT:ExpandRowHelper(menu, rowStates[i].childStates, currentIdx, rowStates[i].nrOfChildRows, rowsLeft)
			
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

function LibMT:CollapseRow(menu, rowIdx, skipRefresh, isToggle)
	menu.expandStates = menu.expandStates or {}
	
	assert(rowIdx <= #menu.rows, "Row index (" .. rowIdx .. ") is larger than number of rows (" .. #menu.rows .. ")")
	local rowsLeft, nrOfCollapsedRows = LibMT:CollapseRowHelper(menu, menu.expandStates, 99999, rowIdx)
	
	assert(rowsLeft == 0, "Error during row collapsing: number of rows left > 0")
	
	-- we have to adjust the selected row index if it was below the collapsed row if we do a toggle
	if isToggle then
		if menu.selectedRow and menu.selectedRow.idx > rowIdx then
			-- if we had a row selected, that is not visible any more now, we set the collapsed row to be selected
			if menu.selectedRow.idx <= rowIdx + nrOfCollapsedRows then
				menu.selectedRow.idx = rowIdx
			else
				menu.selectedRow.idx = menu.selectedRow.idx - nrOfCollapsedRows
			end
		end
	end
	menu.toprow = GetTopRow(menu.defaulttable)
	menu.selrow = menu.selectedRow.idx
		
	if not skipRefresh then
		menu.display()
	end
end

function LibMT:CollapseRowHelper(menu, rowStates, nrOfChildRows, rowsLeft)
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
			local nrOfCollapsedRows = false
			rowsLeft, nrOfCollapsedRows = LibMT:CollapseRowHelper(menu, rowStates[i].childStates, rowStates[i].nrOfChildRows, rowsLeft)
			
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

function LibMT:AddRowExpandState(menu, parentRowIdx)
--	local state = self.stack:peek()
	menu.expandStates = menu.expandStates or {}
	
	-- setting the parentRowIdx to to #rows + 1 lets the helper enumerate all rows in the expand state
	parentRowIdx = parentRowIdx or #menu.rows + 1
	parentRowIdx = (parentRowIdx > 0 and parentRowIdx) or #menu.rows + 1
	
	assert(parentRowIdx <= #menu.rows + 1, "Parent row index (" .. parentRowIdx .. ") is larger than number of rows (" .. #menu.rows .. ") + 1")
	
	local _, rowsLeft = LibMT:AddRowExpandStateHelper(menu, menu.expandStates, 0, 99999, parentRowIdx)
	
	-- check if the new row was added at the total end
	if rowsLeft > 0 then
		local newState = {
			expanded = false,
			childStates = {},
			nrOfChildRows = 0, -- will be updated once the row is expanded, until then it doesn't matter
			rowsTotal = 0
		}
		table.insert(menu.expandStates, newState)
	end
end

function LibMT:AddRowExpandStateHelper(menu, rowStates, currentIdx, nrOfChildRows, rowsLeft)
--	local state = self.stack:peek()
	
	for i = 1, nrOfChildRows do
		rowsLeft = rowsLeft - 1
		currentIdx = currentIdx + 1
		
		local row = menu.rows[currentIdx]
		
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
			currentIdx, rowsLeft, parentRowIdx = LibMT:AddRowExpandStateHelper(menu, rowStates[i].childStates, currentIdx, rowStates[i].nrOfChildRows, rowsLeft)
			
			-- then, if there are no more rows left, we can return
			if rowsLeft == 0 then
				return currentIdx, rowsLeft
			end
		end
	end
	
	return currentIdx, rowsLeft
end

function LibMT:DeleteRowExpandState(menu, rowIdx)
--	local state = self.stack:peek()
	menu.expandStates = menu.expandStates or {}
	
	assert(rowIdx <= #menu.rows, "Row index (" .. rowIdx .. ") is larger than number of rows (" .. #menu.rows .. ")")
	
	local rowsLeft = LibMT:DeleteRowExpandStateHelper(menu, menu.expandStates, 99999, rowIdx)
	
	assert(rowsLeft == 0, "Error during deletion of row expand state: number of rows left > 0")
end

function LibMT:DeleteRowExpandStateHelper(menu, rowStates, nrOfChildRows, rowsLeft)
	for i = 1, nrOfChildRows do
		rowsLeft = rowsLeft - 1
	
		-- if the target index reached 0, we remove the state
		if rowsLeft == 0 then
			table.remove(rowStates, i)
			return rowsLeft
		end
		
		-- if this row is expanded, we have to go through the child rows as well
		if rowStates[i] and rowStates[i].expanded then
			rowsLeft = LibMT:DeleteRowExpandStateHelper(menu, rowStates[i].childStates, rowStates[i].nrOfChildRows, rowsLeft)
			
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

function LibMT:IsExpanded(menu, rowIdx)
	menu.expandStates = menu.expandStates or {}

	local rowsLeft, isExpanded, s = LibMT:IsExpandedHelper(menu, menu.expandStates, 99999, rowIdx, 1)
	
	assert(rowsLeft == 0, "Error during row expansion check: number of rows left > 0")
	
	return isExpanded, s
end

function LibMT:IsExpandedHelper(menu, rowStates, nrOfChildRows, rowsLeft, indentLevel)
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
--		s = s .. i .. ": " .. tostring(state.expanded) .. ", " .. state.nrOfChildRows .. ", " .. rowsLeft .. "\n"
		
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
			rowsLeft, isExpanded, s2 = LibMT:IsExpandedHelper(menu, rowStates[i].childStates, rowStates[i].nrOfChildRows, rowsLeft, indentLevel + 1)
			s = s .. s2
			
			-- then, if there are no more rows left, we can return
			if rowsLeft == 0 then
				return rowsLeft, isExpanded, s
			end
		end
	end
	
	return rowsLeft, false, s
end




function LibMT:CreateDefaultCenterButton(label, selectable, colour, fontSize, isBold)
	colour = colour or self.colours.white
	local text = Helper.createButtonText(label, "center", (isBold and Helper.standardFontBold) or Helper.standardFont, fontSize or Helper.standardFontSize, colour.r, colour.g, colour.b, colour.a)
	return Helper.createButton(text, nil, false, selectable, 0, 0, 0, Helper.standardTextHeight)
end

function LibMT:CreateDefaultButtonBarButton( label, selectable, hotkey, colour, fontSize, width, offsetY )
	colour = colour or LibMT.colours.white
	local text = Helper.createButtonText( label, "center", Helper.standardFont, fontSize or 11, colour.r, colour.g, colour.b, colour.a )
	return Helper.createButton(text, nil, false, selectable, 0, offsetY or 0, width or 150, 25, nil, hotkey)
end

function LibMT:CheckButtonBarAvailability(menu, rowIdx, rowData)
	local buttons = menu.buttons
	if buttons then
		local buttontable = menu.buttontable
		for _, button in ipairs(buttons) do
			if button and button.label then
				Helper.removeButtonScripts(menu, buttontable, button.row, button.col)
				local selectable = button.availabilityProvider(menu, rowIdx, rowData)
				local offsetY = (button.row == 2 and 10) or 0
				local hotkey = nil
				if button.hotkey ~= "" then
					hotkey = Helper.createButtonHotkey(button.hotkey, true)
				end
				local b = LibMT:CreateDefaultButtonBarButton(button.label, selectable, hotkey, nil, nil, nil, offsetY)
				SetCellContent(buttontable, b, button.row, button.col)
				Helper.setButtonScript(menu, nil, buttontable, button.row, button.col, function () button.script(menu, rowIdx, rowData) end)	
			end
		end
	end
end

function LibMT:SetSelectedRow(menu)
	local topRow = menu.topRow
--	if topRow and topRow.idx then
		-- we have to trigger the onRowChanged event here for the topmost row,
		-- since we will have swallowed it
--		menu.onRowChanged(topRow.idx, topRow.data)
--	else
--		menu.onRowChanged(menu.selectedRow.idx, menu.selectedRow.data)
--		menu.selectedRow = nil
--	end
end




-- Library function that returns a header (title) descriptor and the height of the header
LibMT.create_standard_header = function( menu, title, subtitle, additional_rows, scale, bgColour, custom_rows )
	-- assign our basic table info to a local variable
	local setup = Helper.createTableSetup(menu)
	local spacer = 3
	local headerHeight = Helper.headerRow1Height + spacer
	-- set up the menu title row
	setup.addTitleRow(setup, {
		Helper.createFontString(
			title, 											-- the main title text of our window
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
	}, nil, {1}, scale or false, bgCol or Helper.defaultTitleBackgroundColor)

	-- set up the menu sub-title row if one has been requested
	if subtitle then
		for k,text in ipairs(subtitle) do
			setup.addTitleRow(	setup, 
			{ 
				Helper.createFontString( text, false, "left", 255, 255, 255, 100, Helper.headerRow2Font, Helper.headerRow2FontSize, 
				false, Helper.headerRow2Offsetx, Helper.headerRow2Offsety, Helper.headerRow2Height, Helper.headerRow1Width )
			}, nil, {1}, scale or false, bgCol or Helper.defaultTitleBackgroundColor)
			headerHeight = headerHeight + Helper.headerRow2Height + spacer
		end
	end		
	
	-- Add custom blank rows if requested
	if custom_rows and #custom_rows > 0 then
		for i,row in ipairs(custom_rows) do
			setup.addTitleRow( setup, { row }, 
			nil, {1}, scale or false, bgCol or Helper.defaultTitleBackgroundColor )
			headerHeight = headerHeight + Helper.headerRow2Height + spacer
		end
	end
	-- Add additional blank rows if requested
	if additional_rows and #additional_rows > 0 then
		for i = 1, #additional_rows, 1 do
			setup.addTitleRow( setup, { Helper.createFontString( "", false, "left", 255, 255, 255, 100, Helper.headerRow2Font, Helper.headerRow2FontSize, 
			false, Helper.headerRow2Offsetx, Helper.headerRow2Offsety, Helper.headerRow2Height, Helper.headerRow1Width ) }, 
			nil, {1}, scale or false, bgCol or Helper.defaultTitleBackgroundColor )
			headerHeight = headerHeight + Helper.headerRow2Height + spacer
		end
	end


	-- return the header setup function and the height of the header table
	return setup.createCustomWidthTable(setup, {
		[1] = 0
	}, false), headerHeight
end

-- Library function that returns a header (title) descriptor and the height of the header
LibMT.create_column_header = function( menu, title_elements, subtitle, additional_rows, colWidths, colspans, dontscaletable, scale, bgColour )
	-- assign our basic table info to a local variable
	local setup = Helper.createTableSetup(menu)
	local spacer = 3
	local headerHeight = Helper.headerCharacterIconSize + spacer
	local fixedRows = 0
	local sawNonFixedRow = false
	-- set up the menu title row
	setup.addTitleRow(setup, title_elements, nil, colspans, scale or false, bgCol or Helper.defaultTitleBackgroundColor)

	-- set up the menu sub-title row if one has been requested
	if subtitle then
		for k,text in ipairs(subtitle) do
			setup.addTitleRow(	setup, 
			{ 
				Helper.createFontString( text, false, "left", 255, 255, 255, 100, Helper.headerRow2Font, Helper.headerRow2FontSize, 
				false, Helper.headerRow2Offsetx, Helper.headerRow2Offsety, Helper.headerRow2Height, Helper.headerRow1Width )
			}, nil, {#colWidths}, scale or false, bgCol or Helper.defaultTitleBackgroundColor)
			headerHeight = headerHeight + Helper.headerRow2Height + spacer
		end
	end		
	
	-- Add additional rows if requested
	for rowIdx, row in ipairs(additional_rows) do
		local elements, colspans = {}, {}
		local colIdx = 1
		for _, cell in ipairs(row.cells) do
			table.insert(elements, cell.element)
			table.insert(colspans, cell.colspan)
			if cell.script then
				local curColIdx = colIdx -- for closure
				table.insert(cell_scripts, function()
					if cell.type == "button" then
						Helper.setButtonScript(menu, nil, menu.selecttable, rowIdx, curColIdx, function () cell.script(rowIdx, colIdx) end) 
					end
					if cell.type == "editBox" then
						Helper.setEditBoxScript(menu, nil, menu.selecttable, rowIdx, curColIdx, function (_, text, textchanged) cell.script(_, text, textchanged, rowIdx, colIdx) end) 
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
--			menu.topRow = menu.topRow or menu.selectrow or {
--				idx = rowIdx,
--				data = row.data
--			}
		end
		
		assert(colIdx - 1 == #colWidths, "Missmatch in nr of colWidths (" .. #colWidths .. ") and provided colspans (" .. colIdx - 1 .. ") in row " .. rowIdx .. "")
		
		setup.addTitleRow(setup, elements, row.data, colspans, scale or false, Helper.defaultTitleBackgroundColor)
		headerHeight = headerHeight + Helper.headerRow2Height + spacer
	end

	-- return the header setup function and the height of the header table
	local isColumnWidthsInPercent = false
	local doNotScale = dontscaletable or false
	local isBorderEnabled = true
	local tabOrder = nil
	local fixedRows = 0
	local offsetX = 0
	local offsetY = 0
	local height = 0 -- headerHeight -- stretch to fill
	
	return setup.createCustomWidthTable(setup, colWidths, isColumnWidthsInPercent, doNotScale, isBorderEnabled, tabOrder, fixedRows, offsetX, offsetY, height), headerHeight
end

-- Library function to create standard body section with collapsible rows from a pre-built row collection table
LibMT.create_body = function( menu, row_collection, cell_scripts, colWidths, enable_border, doNotScale, headerHeight, bodyHeight, toprow, selrow )
	local setup = Helper.createTableSetup( menu )
	local fixedRows = 0
	local sawNonFixedRow = false

	for rowIdx, row in ipairs(row_collection) do
		local elements, colspans = {}, {}
		local colIdx = 1
		for _, cell in ipairs(row.cells) do
			table.insert(elements, cell.element)
			table.insert(colspans, cell.colspan)
			if cell.script then
				local curColIdx = colIdx -- for closure
				table.insert(cell_scripts, function()
					if cell.type == "button" then
						Helper.setButtonScript(menu, nil, menu.selecttable, rowIdx, curColIdx, function () cell.script(rowIdx, colIdx) end) 
					end
					if cell.type == "editBox" then
						Helper.setEditBoxScript(menu, nil, menu.selecttable, rowIdx, curColIdx, function (_, text, textchanged) cell.script(_, text, textchanged, rowIdx, colIdx) end) 
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
		end
		
		assert(colIdx - 1 == #colWidths, "Missmatch in nr of colWidths (" .. #colWidths .. ") and provided colspans (" .. colIdx - 1 .. ") in row " .. rowIdx .. "")
		if row.isFixed then
			setup.addHeaderRow(setup, elements, row.data, colspans, false, row.bgColor)
		else
			setup.addSimpleRow(setup, elements, row.data, colspans, false, row.bgColor)
		end
	end
	
	local isColumnWidthsInPercent = false
	local doNotScale = doNotScale or false
	local isBorderEnabled = enable_border and true
	local tabOrder = 1
	local offsetX = 0
	local offsetY = headerHeight
	local toprow = toprow or nil
	local selrow = selrow or nil
	
	local desc = setup.createCustomWidthTable(setup, colWidths, isColumnWidthsInPercent or false, doNotScale, 
											isBorderEnabled, tabOrder, fixedRows, offsetX, offsetY, bodyHeight, false, toprow, selrow)
	return desc
end

-- Library function that returns a standard two-row button bar descriptor
LibMT.create_standard_button_bar = function( menu, buttons, headerHeight, bodyHeight )

	local setup = Helper.createTableSetup(menu)
	local uiButtons = {}
	local emptyCell = Helper.getEmptyCellDescriptor()
	
	for i, button in ipairs(buttons) do
		if button and button.label then
			button.hotkey = button.hotkey or LibMT.hotkeys[i]
			local hotkey = nil
			if button.hotkey ~= "" then
				hotkey = Helper.createButtonHotkey(button.hotkey, true)
			end
			local offsetY = (i > 4 and 10) or 0
			local b = LibMT:CreateDefaultButtonBarButton( button.label, false, hotkey, nil, nil, nil, offsetY )
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
	
	setup.addSimpleRow(setup, row1buttons, nil, nil, false, LibMT.colours.transparent)
	setup.addSimpleRow(setup, row2buttons, nil, nil, false, LibMT.colours.transparent)
	
	
	local colWidths = { 48,150,48,150,0,150,48,150,48 }
	local isColumnWidthsInPercent = false
	local doNotScale = false
	local isBorderEnabled = true
	local tabOrder = 2
	local fixedRows = 2
	local offsetX = 0
	local offsetY = headerHeight + bodyHeight
	local height = 0 -- stretch to fill
	
	return setup.createCustomWidthTable(setup, colWidths, isColumnWidthsInPercent, doNotScale, isBorderEnabled, tabOrder, fixedRows, offsetX, offsetY, height, false)
end

-- Library function to create a simple list body
LibMT.create_section = function( setup, name, header, array, nonetext)
	-- Handle list being empty
	if #array == 0 then
		setup:addSimpleRow({
			[1] = nonetext
		})
	else
		-- add row entry for each item in the table
		for i, component in ipairs(array) do
			setup:addSimpleRow({
				[1] = GetComponentData(component, "name")
			}, component)
		end
	end	
	return
end



-- Functions for querying and manipulating ships
LibMT.filter_ships = function( ships, args )
--[[	Parameters:
			ships - a table of ships
			args - a table of strings that indicate the type of ship to remove from the list
		Returns:
			a table of ships with the requested ship types removed
--]]
	for i = #ships, 1, -1 do
		for _, arg in ipairs(args) do
			if arg == "commander" then
				local commander = GetCommander(ships[i])
				-- if the ship is assigned to another commander (ship or station) then remove from list
				if commander then
					table.remove(ships, i)
					break
				end
			elseif arg == "playership" then
				-- remove the player ship
				if IsSameComponent(ships[i],GetPlayerPrimaryShipID()) then
					table.remove(ships, i)
					break
				end
			elseif arg == "drone" then
				-- remove drones
				if IsComponentClass(ships[i], "drone") then
					table.remove(ships, i)
					break
				end
			elseif arg == "ship_s" then
				-- remove small ships
				if IsComponentClass(ships[i], "ship_s") then
					table.remove(ships, i)
					break
				end
			elseif arg == "ship_m" then
				-- remove medium ships
				if IsComponentClass(ships[i], "ship_m") then
					table.remove(ships, i)
					break
				end
			elseif arg == "ship_xs" then
				-- remove extra small ships
				if IsComponentClass(ships[i], "ship_xs") then
					table.remove(ships, i)
					break
				end
			elseif arg == "ship_xl" then
				-- remove extra large ships
				if IsComponentClass(ships[i], "ship_xl") then
					table.remove(ships, i)
					break
				end
			elseif arg == "ship_l" then
				-- remove large ships
				if IsComponentClass(ships[i], "ship_l") then
					table.remove(ships, i)
					break
				end
			elseif arg == "battleship" then
				-- remove ships with only one cargo bay (i.e. fuel ergo battleships)
				local storage = GetStorageData(ships[i])
				local numberofbays = 0
				local next = next
				if next(storage) ~= nil then
					for i, cargobaytype in ipairs(storage) do
						numberofbays = numberofbays + 1
					end
				end
				if numberofbays < 2 then
					table.remove( ships, i)
					break
				end
			elseif arg == "cv" then
				local macro_string = GetComponentData(ships[i], "macro")
				if string.find(macro_string, "units_size_xl_builder_ship") then
					table.remove( ships, i )
					break
				end
			end
		end
	end
	return( ships )
end

LibMT.filter_ships_bydrones = function( ships, dronetype, min_req )
--[[ 	Parameters:
			ships - a table of ships to filter 
			dronetype - a string describing the drone to look for 
			min_req - an integer that is the amount (at least) that the ship should have
		Returns:
			a table of ships with at least the required number of drones of dronetype
--]]
	for i = #ships, 1, -1 do
		local shipunits = GetUnitStorageData(ships[i])
		local hasdrones = false
		local macroname = ""
		if dronetype == "cargo" then
			macroname = "units_size_xs_transp_empty_macro"
		end
		if IsComponentClass(ships[i], "ship_l") or IsComponentClass(ships[i], "ship_xl") then
			for _, entry in ipairs(shipunits) do
				if entry.macro == macroname and min_req <= entry.amount then
					hasdrones = true
				end
			end
		end
		if hasdrones == false then
			table.remove( ships, i )
		end
	end
	return ships
end

LibMT.remove_ships_with_no_crew = function( ships )
	for i = #ships, 1, -1 do
		local captain, defence, engineer = GetComponentData( ships[i], "pilot", "defencenpc", "engineer" )
--		if captain == nil or defence == nil or engineer == nil then
		if captain == nil then
			table.remove( ships, i ) 
		end
	end
	return ships
end

LibMT.get_crew_level = function( ship )
	local captain, defence, engineer = GetComponentData( ship, "pilot", "defencenpc", "engineer" )
	local captain_score, defence_score, engineer_score = 0, 0, 0
	if captain then
		captain_score = GetComponentData( captain, "combinedskill")
	end
	if defence then 
		defence_score = GetComponentData( defence, "combinedskill")
	end
	if engineer then
		engineer_score = GetComponentData( engineer, "combinedskill")
	end

	-- Now calculate level based on scores
	local crewscore = captain_score + defence_score + engineer_score
	local level = 1
	if crewscore >= 200 and crewscore < 250 then
		level = 2
	elseif crewscore >= 250 then
		level = 3
	end
	return captain_score, defence_score, engineer_score, level, crewscore
end

-- Get a crew member rank index based on XP
LibMT.get_entity_rank = function( xp )
	local rank = 1
	if xp < 250000 then
		rank = 1
	elseif xp < 500000 then
		rank = 2
	elseif xp < 1000000 then
		rank = 3
	elseif xp < 2000000 then
		rank = 4
	elseif xp < 4000000 then
		rank = 5
	elseif xp < 8000000 then
		rank = 6
	else
		rank = 7
	end
	return rank
end

-- A table holding various officer ranks
LibMT.Ranks = {
				{	
					ReadText(150402,50),
					ReadText(150402,51),
					ReadText(150402,52),
					ReadText(150402,53),
					ReadText(150402,54),
					ReadText(150402,55),
					ReadText(150402,56),
				},
				{	
					ReadText(150402,60),
					ReadText(150402,61),
					ReadText(150402,62),
					ReadText(150402,63),
					ReadText(150402,64),
					ReadText(150402,65),
					ReadText(150402,66),
				},
				{
					ReadText(150402,70),
					ReadText(150402,71),
					ReadText(150402,72),
					ReadText(150402,73),
					ReadText(150402,74),
					ReadText(150402,75),
					ReadText(150402,76),
				},
			}

-- Verbose messages for ship log
LibMT.Messages = {
	NO_TRADE 								= ReadText( 150402, 420 ),	-- "Error - report to author" ,
	WP_INACTIVE								= ReadText( 150402, 421 ),	-- "Skipping waypoint due to waypoint set to inactive",
	NO_WAGES								= ReadText( 150402, 422 ),	-- "Skipping waypoint due to wages not being paid!!", 
	WAGES_PAID								= ReadText( 150402, 423 ),	-- "Wages paid - resuming duties", 
	ERR_RANGE								= ReadText( 150402, 424 ),	-- "Skipping waypoint due to waypoint being out of range for the current crew", 
	ERR_HOSTILE								= ReadText( 150402, 425 ),	-- "Skipping waypoint due to destination being hostile", 
	WP_FLYTO_NOMOVE							= ReadText( 150402, 426 ),	-- "Waypoint is fly to. Already close enough so not moving",
	WP_FLYTO								= ReadText( 150402, 427 ),	-- "Successfully flew to destination",
	WP_NULLSWEEP_NOFLY						= ReadText( 150402, 428 ),	-- "Null sweep: already safely at home so not moving",
	WP_NULLSWEEP_FLY						= ReadText( 150402, 429 ),	-- "Null sweep: flew home to safety",
	ERR_SELLOFFER_NOCASH					= ReadText( 150402, 430 ),	-- "Skipping due to not enough cash to pay for wares",
	ERR_SELLOFFER_NOWARES					= ReadText( 150402, 431 ),	-- "Skipping due to not enough wares for purchase at destination",
	ERR_SELLOFFER_COST						= ReadText( 150402, 432 ),	-- "Skipping because the wares are too expensive at the destination",
	ERR_SELLOFFER_NO_OFFER					= ReadText( 150402, 433 ),	-- "Skipping due to no wares for sale at the destination",
	ERR_SELLOFFER_NOTVIABLE_AMOUNT			= ReadText( 150402, 434 ),	-- "Skipping because the amount is too low to be worth the trip",
	ERR_SELLOFFER_DONTNEED					= ReadText( 150402, 435 ),	-- "Skipping because we already have enough of that ware on board",
	ERR_SELLOFFER_NOCARGOSPACE				= ReadText( 150402, 436 ),	-- "Skipping because we don't have enough room in the hold",
	ERR_BUYOFFER_NOTENOUGHWARES				= ReadText( 150402, 437 ),	-- "Skipping because the destination does not want enough wares",
	ERR_BUYOFFER_WONTPAY					= ReadText( 150402, 438 ),	-- "Skipping because the destination won't pay enough for the wares",
	ERR_BUYOFFER_NO_OFFER					= ReadText( 150402, 439 ),	-- "Skipping due to no buy offers at the destination",
	ERR_BUYOFFER_NOTENOUGHCARGO				= ReadText( 150402, 440 ),	-- "Skipping because we don't have enough wares on board to meet the sale",
	ERR_CANTRESERVE							= ReadText( 150402, 441 ),	-- "Skipping due to not being able to reserve enough wares",
	ERR_TARGET_INVALID						= ReadText( 150402, 442 ),	-- "Skipping as it seems that the target has been destroyed or is not functional",
	ERR_CANT_PARK							= ReadText( 150402, 443 ),	-- "Aborted because we couldn't park at the destination",
	ERR_INTRADE_FAIL						= ReadText( 150402, 444 ),	-- "Something went wrong during the trade - Egosoft - I'm looking at you!!!",
	WP_NULLSWEEP_FLYING						= ReadText( 150402, 445 ),	-- "Flying back to homebase",
}
			
--				{ 	"No Action", 		  "Load", 				"Unload", 
--					"Buy", 				 "Sell", 			  "Fly to", 			"Refuel" }
LibMT.WPType = 	{ 	ReadText(150402,167), ReadText(150402,168), ReadText(150402,169), 
					ReadText(1001,2916), ReadText(1001,2917), ReadText(150402,170), ReadText(1002,2027) }			

-- Creates a string of 1 to 5 stars as per Egosoft profile menus					
LibMT.createStarsText = function(skillvalue)
	local stars = string.rep("*", skillvalue) .. string.rep("#", 5 - skillvalue)
	return Helper.createFontString(stars, false, "left", 255, 255, 0, 100, Helper.starFont, 16)
end

			
			
LibMT.GetCargoSpecs = function( ship )
--[[
<page id="20205" title="Ware Transport Types" descr="0" voice="no">
 <t id="100">Container</t>
 <t id="200">Bulk</t>
 <t id="300">Liquid</t>
 <t id="400">Passenger</t>
 <t id="500">Equipment</t>
 <t id="600">Inventory</t>
 <t id="700">Energy</t>
 <t id="800">Fuel</t>
 <t id="900">Ship</t>
</page>
--]]
	local bulk = ReadText(20205, 200)
	local container = ReadText(20205, 100)
	local energy = ReadText(20205, 700)
	local liquid = ReadText(20205, 300)
	local fuel = ReadText(20205, 800)

	local transporttypes = {}
	local canCarryContainer, canCarryLiquid, canCarryEnergy, canCarryBulk, canCarryFuel = false, false, false, false, false
	-- Get possible waretypes for ship
	canCarryFuel = CheckSuitableTransportType(ship, "fuelcells")
	table.insert(transporttypes, (canCarryFuel and 1) or 0)

	canCarryBulk = CheckSuitableTransportType(ship, "nividium")
	table.insert(transporttypes, (canCarryBulk and 1) or 0)

	canCarryContainer = CheckSuitableTransportType(ship, "chemicalcompounds")
	table.insert(transporttypes, (canCarryContainer and 1) or 0)

	canCarryEnergy = CheckSuitableTransportType(ship, "ioncells")
	table.insert(transporttypes, (canCarryEnergy and 1) or 0)

	canCarryLiquid = CheckSuitableTransportType(ship, "ions")
	table.insert(transporttypes, (canCarryLiquid and 1) or 0)


	local num = 0
	for i,v in ipairs(transporttypes) do 
		num = num + v
	end

	if num > 4 then 
		table.insert(transporttypes, 1)
	else
		table.insert(transporttypes, 0)
	end
	
	-- Now get capacity for each transport type
	local storage = GetStorageData(ship)
	for i, cargobay in ipairs(storage) do

		if string.find(cargobay.name, bulk) and string.find(cargobay.name, energy) and string.find(cargobay.name, liquid) and string.find(cargobay.name, container) then
			-- We have universal storage so break
			local mult = transporttypes[6] * cargobay.capacity
			transporttypes[2] = mult
			transporttypes[3] = mult
			transporttypes[4] = mult
			transporttypes[5] = mult
			transporttypes[6] = mult
		end

		if cargobay.name == fuel then
			local mult = transporttypes[1] * cargobay.capacity
			transporttypes[1] = mult
		end

		if cargobay.name == bulk then
			local mult = transporttypes[2] * cargobay.capacity
			transporttypes[2] = mult
		end

		if cargobay.name == container then
			local mult = transporttypes[3] * cargobay.capacity
			transporttypes[3] = mult
		end

		if cargobay.name == energy then
			local mult = transporttypes[4] * cargobay.capacity
			transporttypes[4] = mult
		end

		if cargobay.name == liquid then
			local mult = transporttypes[5] * cargobay.capacity
			transporttypes[5] = mult
		end
	end
	return transporttypes
end

LibMT.RemoveWares = function( warelist, removetype )
	for i = #warelist, 1, -1 do
		if GetWareData(warelist[i], "transport") == removetype then
			table.remove(warelist, i)
		end
	end
	return warelist
end

LibMT.GetStationRange = function( station1, station2)
	local hzone, hsector, hcluster = GetComponentData(station1, "zone", "sector", "cluster")
	local wpzone, wpsector, wpcluster = GetComponentData(station2, "zone", "sector", "cluster")
	local wprange = 1
--	DebugError( "H Zone:  " .. hzone .. "  H Sector:  " .. hsector .. " H Cluster:  " .. hcluster )
--	DebugError( "WP Zone:  " .. wpzone .. "  WP Sector:  " .. wpsector .. " WP Cluster:  " .. wpcluster )
	if hsector == wpsector then
		wprange = 1
	elseif hcluster == wpcluster then
		wprange = 2
	else
		wprange = 3
	end
	return wprange
end

-- Functions for querying and manipulating stations
LibMT.CompareStationWarelist = function( resources, products, tradewares, cargolist ) 
	local ship_res, ship_prod, ship_trade, ship_all = {}, {}, {}, {}
	if cargolist[6] > 0 then -- cargo is universal so all wares are valid
		local temp = LibMT.deepcopy(LibMT.Set.Symmetric( resources, products ))
		ship_all = LibMT.deepcopy(LibMT.Set.Symmetric( ship_all, temp))
		local canRefuel = false
		for i, ware in ipairs(ship_all) do
			if GetWareData(ware, "transport") == "fuel" then
				canRefuel = true
				table.remove(ship_all, i)
				for i, ware in ipairs(products) do
					if GetWareData(ware, "transport") == "fuel" then
						table.remove(products, i)
					end
				end
			end
		end
		return resources, products, tradewares, ship_all, canRefuel
	end
	
	-- cargolist 1 is fuel
	if cargolist[1] > 0 then
		for i, ware in ipairs(resources) do
			if GetWareData(ware, "transport") == "fuel" then
				table.insert(ship_res, ware)
			end
		end
		for i, ware in ipairs(products) do
			if GetWareData(ware, "transport") == "fuel" then
				table.insert(ship_all, ware)
			end
		end
	end
	
	-- Get bulk wares 
	if cargolist[2] > 0 then
		for i, ware in ipairs(resources) do
			if GetWareData(ware, "transport") == "bulk" then
				table.insert(ship_res, ware)
			end
		end
		for i, ware in ipairs(products) do
			if GetWareData(ware, "transport") == "bulk" then
				table.insert(ship_prod, ware)
			end
		end
		for i, ware in ipairs(tradewares) do
			if GetWareData(ware, "transport") == "bulk" then
				table.insert(ship_trade, ware)
			end
		end
	end
	if cargolist[3] > 0 then
		for i, ware in ipairs(resources) do
			if GetWareData(ware, "transport") == "container" then
				table.insert(ship_res, ware)
			end
		end
		for i, ware in ipairs(products) do
			if GetWareData(ware, "transport") == "container" then
				table.insert(ship_prod, ware)
			end
		end
		for i, ware in ipairs(tradewares) do
			if GetWareData(ware, "transport") == "container" then
				table.insert(ship_trade, ware)
			end
		end
	end
	if cargolist[4] > 0 then
		for i, ware in ipairs(resources) do
			if GetWareData(ware, "transport") == "energy" then
				table.insert(ship_res, ware)
			end
		end
		for i, ware in ipairs(products) do
			if GetWareData(ware, "transport") == "energy" then
				table.insert(ship_prod, ware)
			end
		end
		for i, ware in ipairs(tradewares) do
			if GetWareData(ware, "transport") == "energy" then
				table.insert(ship_trade, ware)
			end
		end
	end
	if cargolist[5] > 0 then
		for i, ware in ipairs(resources) do
			if GetWareData(ware, "transport") == "liquid" then
				table.insert(ship_res, ware)
			end
		end
		for i, ware in ipairs(products) do
			if GetWareData(ware, "transport") == "liquid" then
				table.insert(ship_prod, ware)
			end
		end
		for i, ware in ipairs(tradewares) do
			if GetWareData(ware, "transport") == "liquid" then
				table.insert(ship_trade, ware)
			end
		end
	end
	
	
	local temp = LibMT.deepcopy(LibMT.Set.Symmetric( ship_res, ship_prod ))
	ship_all = LibMT.deepcopy(LibMT.Set.Symmetric( ship_all, temp))
	local canRefuel = false
	for i, ware in ipairs(ship_all) do
		if GetWareData(ware, "transport") == "fuel" then
			canRefuel = true
			table.remove(ship_all, i)
		end
	end

	return ship_res, ship_prod, ship_trade, ship_all, canRefuel
	
end

-- Utility functions
-- Table copying
LibMT.deepcopy = function (orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[LibMT.deepcopy(orig_key)] = LibMT.deepcopy(orig_value)
        end
        setmetatable(copy, LibMT.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end





-- set manipulation
LibMT.Set = {}

-- returns true if val is found in set
LibMT.Set.Find = function( val, set )
	for _, val_ in ipairs( set ) do
--	DebugError( "Find Func Val_ = " .. tostring(val_) .. "  Comp Val = " .. tostring( val ) .. "  " .. tostring( tostring(val_) == tostring(val) ))
		if tostring(val_) == tostring(val) then
			return true
		end
	end
	return false
end
-- returns true if val is found in set
LibMT.Set.Find2 = function( val, set )
	for _, val_ in ipairs( set ) do
--	DebugError( "Find Func Val_ = " .. tostring(val_) .. "  Comp Val = " .. tostring( val ) .. "  " .. tostring( tostring(val_) == tostring(val) ))
		if val_ == val then
			return true
		end
	end
	return false
end

-- returns the union of seta and setb
LibMT.Set.Union = function( seta, setb )
	local seta = {unpack(seta)}
	for _, setb_ in ipairs( setb ) do
		if not LibMT.Set.Find( setb_, seta ) then
			table.insert( seta, setb_ )
		end
	end
	return seta
end

-- returns the intersection of seta and setButtonScript
LibMT.Set.Intersection = function( seta, setb )
	local ret_set = {}
	for _, setb_ in ipairs( setb ) do
		if LibMT.Set.Find( setb_, seta ) then
			table.insert( ret_set, setb_ )
		end
	end
	return ret_set
end

-- returns the difference between seta and setb
LibMT.Set.Difference = function( seta, setb )
	local ret_set = {}
	for _, seta_ in ipairs( seta ) do
		if not LibMT.Set.Find( seta_, setb ) then
			table.insert( ret_set, seta_ )
--			DebugError( "Adding:....  " .. tostring( seta_ ))
		end
	end
	return ret_set
end

-- returns symmetric of seta and setb i.e. all the unique values of a and b
LibMT.Set.Symmetric = function( seta, setb )
	return LibMT.Set.Difference( LibMT.Set.Union( seta, setb), LibMT.Set.Intersection( seta, setb ))
end	
	
	
-- init()

