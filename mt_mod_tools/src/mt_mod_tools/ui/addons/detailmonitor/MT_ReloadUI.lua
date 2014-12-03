-- Shedule a reload of the UI
-- Set up the default menu table
local menu = {	
	name = "gMT_ReloadUI",
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
	return
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	Helper.releaseDescriptors()
	Helper.closeMenuAndCancel(menu)
	menu.cleanup()
	ScheduleReloadUI()
	return
end

-- standard function stub to handle changing row
menu.onRowChanged = function (row, rowdata)
	return
end

-- standard function stub to handle dynamic update of menu
menu.onUpdate = function ()
	return
end

-- standard function stub to handle selection of an element in the menu
-- TODO: update a variable to reflect our target ships
menu.onSelectElement = function ()
	return
end

-- standard function to deal with clicking the '<' or 'x' buttons in the corner of the menu
menu.onCloseElement = function (dueToClose)
	if dueToClose == "close" then
		Helper.closeMenuAndCancel(menu)
		menu.cleanup()
	else
		Helper.closeMenuAndReturn(menu)
		menu.cleanup()
	end

	return
end

init()

return
