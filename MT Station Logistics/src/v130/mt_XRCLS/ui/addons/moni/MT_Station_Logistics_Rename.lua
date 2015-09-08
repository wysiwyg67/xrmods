local menu = {
	name = "gMT_Station_Logistics_Rename",
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
--	menu.infotable = nil
--	menu.selecttable = nil
	menu.crewdata = nil
	menu.ret_exp = nil
	return 
end

local function editboxUpdateText(_, text, textchanged)
	if textchanged then
		SetComponentName(menu.object, text)
	end
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_rename_return", {  toprow, selrow, menu.crewdata, menu.ret_exp, {}, {} })

--	Helper.closeMenuAndReturn(menu)
	menu.cleanup()

	return 
end

local function buttonOK()
	Helper.confirmEditBoxInput(menu.selecttable, 1, 1)

	return 
end

local function buttonCancel()
	Helper.cancelEditBoxInput(menu.selecttable, 1, 1)
--	Helper.closeMenuAndReturn(menu)
	Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_rename_return", {  toprow, selrow, menu.crewdata, menu.ret_exp, {}, {} })
	menu.cleanup()

	return 
end

menu.onShowMenu = function ()
	menu.toprow = menu.param[1]						-- return toprow
	menu.selrow = menu.param[2]						-- return row
	menu.crewdata = menu.param[3]				-- data for selected crew member
	menu.ret_exp = menu.param[4]				-- return row and expand states

	menu.object = menu.crewdata[2]
	local container = GetContextByClass(menu.object, "container", false)
	local name, objectowner = GetComponentData(menu.object, "name", "owner")

	if container then
		menu.title = GetComponentData(container, "name") .. " - " .. ((name ~= "" and name) or ReadText(1001, 56))
	else
		menu.title = (name ~= "" and name) or ReadText(1001, 56)
	end

	local setup = Helper.createTableSetup(menu)
	local isplayer, reveal = GetComponentData(menu.object, "isplayerowned", "revealpercent")

	setup.addSimpleRow(setup, {
		Helper.createButton(nil, Helper.createButtonIcon("menu_info", nil, 255, 255, 255, 100), false),
		Helper.createFontString(menu.title .. ((isplayer and "") or " (" .. reveal .. " %)"), false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize, false, Helper.headerRow1Offsetx, Helper.headerRow1Offsety, Helper.headerRow1Height, Helper.headerRow1Width)
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
		Helper.createEditBox(Helper.createButtonText(name, "left", Helper.standardFont, Helper.standardFontSize, 255, 255, 255, 100), false, 0, 0, 880, 24, nil, nil, true)
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
--		Helper.closeMenuAndReturn(menu)
		Helper.closeMenuForSection(menu, false, "gMT_ReportMenu_rename_return", {  toprow, selrow, menu.crewdata, menu.ret_exp, {}, {} })
		menu.cleanup()
	end

	return 
end

init()

return 
