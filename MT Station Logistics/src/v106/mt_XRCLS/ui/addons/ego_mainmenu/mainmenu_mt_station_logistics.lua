--[[	MT Station Logistics
		Version:		1.00
		Last Update:	2014-12-06
		This file adds side bar menu entries for the station logistics mod
		and sub-menu entries for each function
--]]

-- This is the parent menu entry for the table above
local menuAddon = 
{
	entry1 =
	{	
		section = "gMT_Logistics",
		icon = "mm_ic_trading",
		name = ReadText( 150402, 1 ),	-- name = "MT Station Logistics",
		condition = true,
		info = ReadText( 150402, 2 ),	-- info = "Set-up and manage Station Traders",
--		list = submenulist
		sectionparam = { 0, 0, {}, {}, {}, {} }
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
