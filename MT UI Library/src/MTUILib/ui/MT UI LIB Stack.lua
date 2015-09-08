--[[
	MT UI Library - Stack management
	
	Author: 		Wysiwyg
	Last Change:	First Version
	Mod Version: 	V1.0.0
	File Verison:	1
	Date: 			2015-04-09
  
	X Rebirth version: 3.53
--]]

--[[
	Creates a simple stack management object based on http://lua-users.org/wiki/SimpleStack by CHILLCODE™
	-- create stack
	stack = MTLibStack:Create()
	-- push values on to the stack
	stack:push("a", "b")
	-- pop values
	stack:pop(2)
--]]
-- GLOBAL
MTLibStack = {}

-- Create a Table with stack functions
function MTLibStack:Create()

	-- stack table
	local t = {}
	
	-- entry table
	t._et = {}

	-- push a value on to the stack
	function t:push(...)
		if ... then
			local targs = {...}
			-- add values
			for _,v in ipairs(targs) do
				table.insert(self._et, v)
			end
		end
	end

	-- pop a value from the stack
	function t:pop(num)

		-- get num values from stack
		local num = num or 1

		-- return table
		local entries = {}

		-- get values into entries
		for i = 1, num do
			-- get last entry
			if #self._et ~= 0 then
				table.insert(entries, self._et[#self._et])
				-- remove last value
				table.remove(self._et)
			else
				break
			end
		end
		-- return unpacked entries
		return unpack(entries)
	end
  
	-- peek at top value
	function t:peek()
		return self._et[#self._et]
	end

	-- get entries
	function t:getn()
		return #self._et
	end

	-- Return the stack table
	return t
end
