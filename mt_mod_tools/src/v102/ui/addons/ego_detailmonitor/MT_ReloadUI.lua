-- Schedule a reload of the UI
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

-- Simply exit the menu and schedule a reload of the UI
menu.onShowMenu = function ()
	Helper.closeMenuAndCancel(menu)
	menu.cleanup()
	ScheduleReloadUI()
	return
end

init()

return
