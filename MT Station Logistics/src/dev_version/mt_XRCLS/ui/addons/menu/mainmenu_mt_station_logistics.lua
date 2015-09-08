--[[	MT Station Logistics
		Version:		1.35
		Last Update:	2015-04-04
		This file adds side bar menu entries for the station logistics mod
--]]

-- This is the parent menu entry for the table above
local menuAddon = 
{
	entry1 =
	{	
		section = "gMT_Logistics_AdminMenu",
		icon = "mm_ic_trading",
		name = ReadText( 150402, 1 ),	-- name = "MT Station Logistics",
		condition = true,
		info = ReadText( 150402, 2 ),	-- info = "Set-up and manage Station Traders",
		sectionparam = { { 0, 0, {} }, { 0, 0, {} }, "sidebar_menu" }  -- { {called section's row settings}, {calling section's row settings}, "caller" }
	}
}

-- this function iterates through the top level menu entries until it finds the trade menu
local function createSetupAddMTStationLogistics(menu)
    for _, subMenu in ipairs(menu.setup.top) do
        if subMenu.icon == "mm_ic_trading" then
			table.insert(subMenu.list, menuAddon.entry1)
        end
    end
end

-- This function creates the setup wrapper that adds the menu to the core game menu
local function createSetupWrapper()
    menuAddon.origCreateSetup()
	createSetupAddMTStationLogistics(menuAddon.menu)
end

-- function to initialise the menu addition
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

-- initialise the menu
init()
