-- Rename a ship silently
-- Set up the default menu table
local menu = {	
	name = "gMT_ship_Rename",
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
	menu.ship = nil
	menu.newname = nil
	return
end

-- function to handle displaying the menu
menu.onShowMenu = function ()
	menu.ship = menu.param[3]
	menu.newname = menu.param[4]
	SetComponentName(menu.ship, menu.newname)
	Helper.closeMenuAndCancel(menu)
	menu.cleanup()
	return
end

init()

return
