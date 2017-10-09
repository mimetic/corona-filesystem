--[[
corona-filesystem

A way to replicate important file system functions LFS for Android

Currently, that means:
* FileExists()
* lfs.dir

--]]


require("mobdebug").start()



local funx = require ("funx-min")

--=======
-- function shortcuts for speed
local substr = string.sub

--=======
local lfs = require "lfs"
local json = require("json")
--=======

local filesystem = {}


-- My Split Function
local function split(str, pat, doTrim)
	pat = pat or ","
	if (not str) then
		return nil
	end
	str = tostring(str)
	local t = {}
	local fpat = "(.-)" .. tostring(pat)
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
		if doTrim then cap = trim(cap) end
		table.insert(t,cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		if doTrim then cap = trim(cap) end
		table.insert(t,cap)
	end
	return t
end




-- Build a table containing files and folders inside of 'p'
-- example: myfiles = buildFileSystem("some/sub/folder")
local function buildFileTable(p)
  local basedir = system.pathForFile('', system.ResourceDirectory)
  local fullpath = funx.joinAsPath( {basedir, p} )
  local files = {}
  
  for f in lfs.dir(fullpath) do
    -- Ignore hidden
    if ( substr(f,1,1) ~= "." ) then
      -- The current path + subdirectory
      local path = funx.joinAsPath( {p,f} )
      local attr = lfs.attributes ( funx.joinAsPath( {basedir, path}))
      if (attr and attr.mode == "directory" ) then
        files[f] = buildFileTable(path) --{name = f, attr = attr}
      else
        files[f] = f --{name = f, attr = attr}
      end
    end
  end
  return files
end
  

-- Build a table containing files and folders inside of 'p'
-- containing important attributes, e.g. size, type, and file system attributes
-- example: myfiles = buildFileSystem("some/folder")
local function buildFilesystem(p)
  local basedir = system.pathForFile('', system.ResourceDirectory)
  local fullpath = funx.joinAsPath( {basedir, p} )
  local files = {}
  
  for f in lfs.dir(fullpath) do
    -- Ignore hidden
    if ( substr(f,1,1) ~= "." ) then
      -- The current path + subdirectory
      local path = funx.joinAsPath( {p,f} )
      local attr = lfs.attributes ( funx.joinAsPath( {basedir, path}))
      if (attr and attr.mode == "directory" ) then
        files[f] = {name=f, attr=attr, mode=attr.mode, contents = buildFilesystem(path), }
      else
        files[f] = {name=f, attr = attr, mode=attr.mode,size=attr.size, }
      end
    end
  end
  return files
end
  



-- FileExists(pathToFile, filesystem)
-- Search the SIMPLE filesystem table to find a file
local function FileExistsSimple(p, filesystem)
  
  pt = split (p, "/", false)
  
  local f = filesystem
  for i,v in pairs (pt) do
    print ("Check for ",v)
    if (f[v]) then
        if (type(f[v]) == "table") then  
          f = f[v]
        else
          return true
        end
    else
      return false
    end
  end
  return true
end

    
    
    -- FileExists(pathToFile, filesystem)
-- Search the complex filesystem table to find a file
local function FileExists(p, filesystem)  
  local result = false
  pt = split (p, "/", false)
  
  local f = filesystem
  for i,v in pairs (pt) do
    result = f[v]
    if ( result ) then
      if (result.mode == "directory") then
        f = result.contents
      else
        return result
      end
    else
      -- stop search and fail
      return result
    end
  end
  return result
end


local function UpdateFileSystem(filename,attr)
end






local dir = ""

-- Version 1:
-- Just names & folders
--filesystem = buildFileTable( dir )

-- Version 2:
-- Full file system with attributes
filesystem = buildFilesystem( dir )

print ("File system for "..dir)
funx.dump( filesystem )

-- Save filesystem to disk as JSON
-- SQL might be a better choice, but more complex to implement
local encoded = json.encode( filesystem )
funx.saveData("filesystem.json", encoded)
filesystem = nil

-- Load the filesystem back in
local filename = system.pathForFile( "filesystem.json", system.ResourceDirectory )
local filesystem, pos, msg = json.decodeFile( filename )

--funx.dump(filesystem)

print ("-------")

-- Testing file system is "_user", let's check inside that
local fileToFind = "funx.lua"
local f = FileExists( fileToFind, filesystem)
if (f) then
  print ("File found" ) 
  funx.dump(f)
else
  print ("File not found", fileToFind)
end
