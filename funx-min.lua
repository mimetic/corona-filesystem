-- funx-min.lua
--
-- Version 1.0
--
-- Copyright (C) 2017 David I. Gross. All Rights Reserved.
--
--[[
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
--]]

--
-- ===================
-- USEFUL FUNCTIONS.
-- ===================

local FUNX = {}

-- Requires json library
local json = require ( "json" )
local lfs = require ( "lfs" )

-- functions
local floor = math.floor
local ceil = math.ceil
local min = math.min
local max = math.max
local random = math.random

local char = string.char
local byte = string.byte
local match = string.match
local gmatch = string.gmatch
local find = string.find
local gsub = string.gsub
local substring = string.sub
local gfind = string.gfind
local lower = string.lower
local upper = string.upper
local strlen = string.len
local format = string.format

-- ALPHA VALUES, can change for RGB or HDR systems
local OPAQUE = 255
local TRANSPARENT = 0


-------------------------------------------------
-- cleanPath: clean up a path
local function cleanPath (p)
	if (p) then
		local substring = substring
		p = p:gsub("/\./","/")
		p = p:gsub("//","/")
		p = p:gsub("/\.$","")
		return p
	end
end


--------------------------------------------------------
-- Trim
-- Remove white space from a string, OR table of strings
-- recursively
-- Only act on strings
-- If flag set, return nil for an empty string
local function trim(s, returnNil)
	if (s) then
		if (type(s) == "table") then
			for i,v in ipairs(s) do
				s[i] = trim(v, returnNil)
			end
		elseif (type(s) == "string") then
			s = s:gsub("^%s*(.-)%s*$", "%1")
		end
	end
	if (returnNil and s == "") then
		return nil
	end
	return s
end



-------------------------------------------------
-- joinAsPath: make a path from different elements of a table.
-- Useful to join pieces together, e.g. server + path + filename
-- If username/password are passed, add them to the URL, e.g. username:password@restofurl
local function joinAsPath( pieces, username, password)
	trim(pieces)
	for i = #pieces, 1, -1 do
		if (pieces[i] == nil or pieces[i] == "") then 
			table.remove(pieces, i)
		end
	end

	local path = cleanPath(table.concat(pieces, "/"))
	local pre = table.concat({username,password},":")
	if (pre ~= "") then
		path = pre .. "@" .. path
	end

	return path
end


-- Dump an XML table
local function dumptable(_class, no_func, depth, maxDepth, filter)
		
		--  = string.match("foo 123 bar", '%d%d%d') -- %d matches a digit
		local function passedFilter(t)
			if not filter then
				return true
			end
			return string.match(t, filter)
		end

	if (not _class) then
		if (_class == nil) then
			print ("dumptable: the table is NIL");
		else
			print ("dumptable: type = " .. type(_class));
			print (tostring(_class))
		end
		return;
	end
	
	if(depth==nil) then depth=0; end
	local str="";
	for n=0,depth,1 do
		str=str.."\t";
	end
	
	maxDepth = maxDepth or 3

	if (depth > maxDepth) then
		print ("Oops, running away! Depth is "..depth)
		return
	end

	print (str.."["..type(_class).."]");
	print (str.."{");

	if (type(_class) == "table") then
		for i,field in pairs(_class) do
			if(type(field)=="table") then
				local fn = tostring(i)
				if (substring(fn,1,2) == "__") then
								print (str.."\t"..tostring(i).." = (not expanding this internal table)");
				else
					print (str.."\t"..tostring(i).." =");
					dumptable(field, no_func, depth+1, maxDepth, filter);
				end
			else
				if (passedFilter(i)) then
					if(type(field)=="number") then
						print (str.." [num]\t"..tostring(i).."="..field);
					elseif(type(field) == "string") then
						print (str.." [str]\t"..tostring(i).."=".."\""..field.."\"");
					elseif(type(field) == "boolean") then
						print (str.." [bool]\t"..tostring(i).."=".."\""..tostring(field).."\"");
					else
						if(not no_func)then
							if(type(field)=="function")then
								print (str.."\t"..tostring(i).."()");
							else
								print (str.."\t"..tostring(i).."<userdata=["..type(field).."]>");
							end
						end
					end
				end
			end
		end
	else
		print ("type = "..type(_class))
	end
	print (str.."}");
end


------------------------------------------------------------------------
-- Save table, load table, default from documents directory
------------------------------------------------------------------------

----------------------
-- Save/load functions

local function saveData(filePath, text)
	--local levelseq = table.concat( levelArray, "-" )
	local file = io.open( filePath, "w" )
	if (file) then
		file:write( text )
		io.close( file )
		return true
	else
		print ("Error: funx.saveData: Could not create file "..tostring(filePath))
		return false
	end
end

local function loadData(filePath)
	local t = nil
	--local levelseq = table.concat( levelArray, "-" )
	local file = io.open( filePath, "r" )
	if (file) then
		t = file:read( "*a" )
		io.close( file )
	else
		print ("scripts.funx.loadData: No file found at "..tostring(filePath))
	end
	return t
end

local function saveTableToFile(filePath, dataTable)

	--local levelseq = table.concat( levelArray, "-" )
	local myfile = io.open( filePath, "w" )

	for k,v in pairs( dataTable ) do
		myfile:write( k .. "=" .. v .. "," )
	end

	io.close( myfile )
end


-- Load a table form a text file.
-- The table is stored as comma-separated name=value pairs.
local function loadTableFromFile(filePath, s)
	local substring = substring

	if (not filePath) then
		print ("WARNING: loadTableFromFile: Missing file name.")
		return false
	end

	local file = io.open( filePath, "r" )

	-- separator, default is comma
	s = s or ","

	if file then

		-- Read file contents into a string
		local dataStr = file:read( "*a" )

		-- Break string into separate variables and construct new table from resulting data
		local datavars = split(dataStr, s)

		local dataTableNew = {}

		for i = 1, #datavars do
			local firstchar = substring(trim(datavars[i]),1,1)
			-- split each name/value pair
			if ( not ((firstchar == "#") or (firstchar == "/") or (firstchar == "-") ) ) then
				local onevalue = trim(split(datavars[i], "="))
				if (onevalue[1]) then
					dataTableNew[onevalue[1]] = onevalue[2]
				end
			end
		end

		io.close( file ) -- important!

		-- Note: all values arrive as strings; cast to numbers where numbers are expected
		dataTableNew["randomValue"] = tonumber(dataTableNew["randomValue"])

		return dataTableNew
	else
		print ("WARNING: loadTableFromFile: File not found ("..filePath..")")
		return false
	end
end

-- 
-- @param doMerge = boolean	If true, then merge table t into the existing data instead of overwriting the data.
local function saveTable(t, filename, path, doMerge)
	if (not t or not filename) then
		return true
	end

	path = path or system.DocumentsDirectory
	--print ("scripts.funx.saveTable: save to "..filename)

	if (doMerge) then
		t = tableMerge( loadTable(filename, path) ,t)
	end

	local json = json.encode (t)
	local filePath = system.pathForFile( filename, path )
	
	--print ("scripts.funx.saveTable: filePath ", filePath)
		
	return saveData(filePath, json)
end

local function loadTable(filename, path)
	path = path or system.DocumentsDirectory
	if (fileExists(filename, path)) then
		local filePath = system.pathForFile( filename, path )
		--print ("scripts.funx.loadTable: load from "..filePath)

		local t = {}
		local f = loadData(filePath)
		if (f and f ~= "") then
			t = json.decode(f)
		end
		--print ("loadTable: end")
		return t
	else
		return false
	end
end



-- ----------------------------------------------------------------

FUNX.joinAsPath = joinAsPath
FUNX.dump = dumptable
FUNX.loadData = loadData
FUNX.saveData = saveData
FUNX.loadTable = loadTable
FUNX.saveTable = saveTable
FUNX.loadTableFromFile = loadTableFromFile
FUNX.saveTableToFile = saveTableToFile

return FUNX
