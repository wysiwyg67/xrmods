-- This file adds side bar menu entries for the mod tools suite
-- and sub-menu entries for each function

-- This is a table of sub-menus - add a section between {} for each sub menu
local submenulist = 
{
	{
		section = "gMT_ReloadUI",
		icon = "engineer_active",
		name = "Reload User Interface",
		condition = true,
		sectionparam = { 0, 0 },
		info = "Experimental - use with caution!!!!!"
	},
	{
		section = "gMT_WarpPlayerShip",
		icon = "engineer_active",
		name = "Warp Player to new location",
		condition = true,
		sectionparam = { 0, 0 },
		info = "Experimental - use with caution!!!!!"
	}
}

-- This is the parent menu entry for the table above
local menuAddon = 
{
	entry1 =
	{	
		icon = "mm_ic_options",
		name = "Modding Tools",
		condition = true,
		info = "Use with caution!!!!",
		list = submenulist
	}
}

-- this function iterates through the top level menu entries until it finds the trade menu
local function createSetupAddMTModTools(menu)
			table.insert(menu.setup.top, menuAddon.entry1)
end

-- This function creates the setup wrapper that adds the menu to the core game menu
local function createSetupWrapper()
    menuAddon.origCreateSetup()
	createSetupAddMTModTools(menuAddon.menu)
end

-- initialise the menu addition
local function init()
	if Menus then
	for _, menu in ipairs(Menus) do
            if menu.name == "MainMenu" then
                menuAddon.menu = menu
                menuAddon.origCreateSetup = menu.createSetup
				menu.createSetup = createSetupWrapper
                break
			end
		end
	end
end

-- call the init() function
init()
