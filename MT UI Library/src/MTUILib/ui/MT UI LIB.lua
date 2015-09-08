--[[ MT UI Library - Main file containing core UI functions
	
	Author: 		Wysiwyg
	Last Change:	2015-04-09
	Mod Version: 	V1.0.0
	File Version:	1
	Date: 			2015-04-09
  
	X Rebirth version: 3.53
--]]

-- Catch cases where mods register before library
local registerFunctions = {}
if MTUILib then
	registerFunctions = MTUILib.registerFunctions
end

-- Define the basic table structure for the library
MTUILib = {
	menus = {},
	stack = nil,
	closeAll = false,
	-- EgoSoft Helper compatibility
	name = "MTUILib",
	param = { nil, nil },
	rowDataMap = {}
}

MTUILib.colours = {
	white = { r = 255, g = 255, b = 255, a = 100 },
	red = {	r = 255, g = 0, b = 0, a = 100 },
	green = { r = 0, g = 255, b = 0, a = 100 },
	blue = { r = 0, g = 0, b = 255, a = 100 },
	transparent = { r = 0, g = 0, b = 0, a = 0 }
}

MTUILib.hotkeys = {
	"INPUT_STATE_DETAILMONITOR_B",
	"INPUT_STATE_DETAILMONITOR_BACK",
	"INPUT_STATE_DETAILMONITOR_Y",
	"INPUT_STATE_DETAILMONITOR_X",
	"INPUT_STATE_DETAILMONITOR_LB",
	"INPUT_STATE_DETAILMONITOR_RB",
	"INPUT_STATE_DETAILMONITOR_A",
	"INPUT_STATE_DETAILMONITOR_0"
}

-- The library's initialisation function executed on mod load
local function init()

	-- Register functions already defined by mods that loaded before the library
	for _, func in ipairs(registerFunctions) do
		func()
	end

	-- Remove temporary function table
	registerFuncions = nil

	-- Register the library in the game
	Menus = Menus or {}
	table.insert(Menus, MTUILib)
	
	-- Register with the EgoSoft Helper Functions
	if Helper then
		Helper.registerMenu(MTUILib)
	end
end

-- initialize the library menu when called
MTUILib.onShowMenu = function ()
	-- Get a local reference to the library
	local self = MTUILib
	-- Set our first menu to be shown to the first parameter passed
	local firstMenu = self.param[1]
	-- Copy the arguments to a local variable
	local args = self.param
	-- remove arguments from library table as we don't need them anymore here
	self.param = nil
	-- remove the first called menu name
	table.remove(args, 1)
	
	-- create or retrieve our stack
	self.stack = self.stack or MTUILibStack:Create()
	
	-- place an empty container on the stack to catch return parameters
	self.stack:push({ menu = { name = firstMenu, onReturnArgsReceived = MTUILib.exitMenu } })
	-- open the first menu
	self:OpenMenu(firstMenu, nil, args)
end

-- Close the current menu(s) when returning to MD
MTUILib.exitMenu = function (state, isClosingAll, returnArgs)
	--[[ Params:
			state 			- the menu that called the close
			isClosingAll	- true if all menus are being closed
			returnArgs		- arguments to pass back to MD
	--]]
	local self = MTUILib
	-- pop the state of the library so we can return to MD land
	local state = self.stack:pop()
	
	-- we can then return the return args
	Helper.closeMenuAndReturn(self, false, { state.menu.name, (self.closeAll and "close") or "back", unpack(returnArgs) })
end

-- either return to last menu or close altogether
MTUILib.onCloseElement = function (dueToClose)
	local self = MTUILib
	-- "close" means the 'x' was pressed or del pressed so we need to iterate over and close all menus
	if dueToClose == "close" then
		-- set the flag to indicate no return menus need to be opened
		self.closeAll = true
		for i = 1, self.stack:getn() - 1, 1 do
			self:CloseMenu()
		end
		self.closeAll = false
	else
		-- escape or back arrow pressed so go back to the previous menu 
		self:CloseMenu()
	end
end

MTUILib.updateInterval = 0.5
MTUILib.onUpdate = function ()
	local self = MTUILib
	-- get current state of shown menu
	local state = self.stack:peek()
	
	if self.shown then  -- if current menu is visible then
		-- call the onUpdate callback of the current menu
		state.menu.onUpdate(state)
	end
	-- Set the correct row state for the current menu
	self:SetSelectedRow()
end

MTUILib.onRowChanged = function (rowIdx, rowData, rc_table)		
	local self = MTUILib
	local state = self.stack:peek()

	if rc_table == state.defaulttable then
		rowData = rowData or {}

		self:CheckButtonBarAvailability(rowIdx, rowData)		
		
		-- TODO: needs checking - not sure about the state."menu".onRowChanged entry?? call the onRowChanged callback of the current menu -- 
		state.menu.onRowChanged(state, rowIdx, rowData)
		state.selectedRow = {
			idx = rowIdx,
			data = rowData
		}
	end
end

MTUILib.onSelectElement = function ()
end

function MTUILib:RegisterMenu(name, onMenuInit, onMenuClosed, onReturnArgsReceived, titleProvider, rowProvider, menuTypeInfo, onUpdate, onRowChanged)
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


-- call the initialisation function
init()
