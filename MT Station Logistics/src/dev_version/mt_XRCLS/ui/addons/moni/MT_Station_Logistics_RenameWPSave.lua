local menu = {
	name = "gMT_Station_Logistics_RenameSave",
	white = {
		g = 255,
		a = 100,
		b = 255,
		r = 255
	},
	red = {
		g = 0,
		a = 100,
		b = 0,
		r = 255
	}
}

local function init()
	Menus = Menus or {}

	table.insert(Menus, menu)

	if Helper then
		Helper.registerMenu(menu)
	end

	return 
end

menu.cleanup = function ()
	menu.title = nil
	menu.object = nil
	menu.infotable = nil
	menu.selecttable = nil
	menu.wpsave_name = nil
	menu.trader = nil
	return 
end

local function editboxUpdateText(_, text, textchanged)
	menu.wpsave_name = text
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_LoadSaveReturn", {  0, 0, menu.trader, "saveconfirmed", {menu.wp_slot, menu.wpsave_name, menu.waypointstosave} })
	menu.cleanup()
end

local function buttonOK()
	Helper.confirmEditBoxInput(menu.selecttable, 1, 1)
end

local function buttonCancel()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
	Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_LoadSaveReturn", {  0, 0, menu.trader, "loadsaveabort" })
	menu.cleanup()
end

menu.onShowMenu = function ()
	menu.toprow = menu.param[1]						-- return toprow
	menu.selrow = menu.param[2]						-- return row
	menu.trader = menu.param[3]						-- trader details
	menu.wp_slot				= menu.param[4][1]
	menu.wpsave_name			= menu.param[4][2]			-- current name of slot
	menu.waypointstosave		= menu.param[4][3]			-- waypoints to save	

	menu.title = "Type new name for save data slot"

	local setup = Helper.createTableSetup(menu)

	setup.addSimpleRow(setup, {
		Helper.createButton(nil, Helper.createButtonIcon("menu_info", nil, 255, 255, 255, 100), false),
		Helper.createFontString(menu.title, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize, false, Helper.headerRow1Offsetx, Helper.headerRow1Offsety, Helper.headerRow1Height, Helper.headerRow1Width)
	}, nil, {
		1,
		1
	}, false, Helper.defaultTitleBackgroundColor)
	setup.addTitleRow(setup, {
		Helper.getEmptyCellDescriptor()
	}, nil, {
		3
	})

	local infodesc = setup.createCustomWidthTable(setup, {
		Helper.scaleX(Helper.standardButtonWidth),
		0,
		Helper.scaleX(Helper.headerCharacterIconSize) + 37
	}, false, false, true, 3, 1)
	setup = Helper.createTableSetup(menu)

	setup.addSimpleRow(setup, {
		Helper.createEditBox(Helper.createButtonText(menu.wpsave_name, "left", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), false, 0, 0, 880, 24, nil, nil, true)
	})

	local selectdesc = setup.createCustomWidthTable(setup, {
		0
	}, false, false, true, 1, 0, 0, Helper.tableOffsety, nil, nil, nil, 1)
	setup = Helper.createTableSetup(menu)

	setup.addSimpleRow(setup, {
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 14), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 200, 27, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_A", true)),
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 64), "center", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), nil, false, true, 0, 0, 200, 27, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_ESC", true)),
		Helper.getEmptyCellDescriptor()
	}, nil, {
		1,
		1,
		1,
		1,
		1
	}, false, menu.transparent)

	local buttondesc = setup.createCustomWidthTable(setup, {
		200,
		200,
		0,
		200,
		200
	}, false, false, false, 2, 1, 0, 150)
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false)

	Helper.setEditBoxScript(menu, nil, menu.selecttable, 1, 1, editboxUpdateText)
	Helper.setButtonScript(menu, nil, menu.buttontable, 1, 2, buttonOK)
	Helper.setButtonScript(menu, nil, menu.buttontable, 1, 4, buttonCancel)

	menu.activateEditBox = true

	Helper.releaseDescriptors()

	return 
end

menu.updateInterval = 1
menu.onUpdate = function ()
	if menu.activateEditBox then
		menu.activateEditBox = nil

		Helper.activateEditBox(menu.selecttable, 1, 1)
	end

	return 
end
menu.onSelectElement = function ()
	return 
end
menu.onCloseElement = function (dueToClose)
	if dueToClose == "close" then
		Helper.closeMenuAndCancel(menu)
		menu.cleanup()
	else
		Helper.closeMenuForSection(menu, false, "gMT_ShipMenu_LoadSaveReturn", {  toprow, selrow, menu.trader, "loadsaveabort", {}, {} })
		menu.cleanup()
	end

	return 
end

init()

return 
