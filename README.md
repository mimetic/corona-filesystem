# corona-filesystem
For Corona SDK, a way to replicate important file system functions in LFS for use on Android.

Android file system does not report media files, so it is hard to check for existing files or scan a directory of files, as one can with iOS.
This "hack" lets you recreate the file system of your app, save it as a file, then use it on Android.

Currently functionality:
* Create file system
* FileExists() : return a table with a found file's name and other information, or false

(funx-min.lua and funx.lua are collections of useful functions)

Example:

-- Entire file system of the app
local filesystem = buildFilesystem( "" )

-- Save filesystem to disk as JSON file
local encoded = json.encode( filesystem )
funx.saveData("filesystem.json", encoded)
filesystem = nil

-- Load the filesystem back in
local filename = system.pathForFile( "filesystem.json", system.ResourceDirectory )
local filesystem, pos, msg = json.decodeFile( filename )


-- A sub-directory of the app
local filesystem = buildFilesystem( "mydir/images" )

-- Does a file exist?
local fileToFind = "funx.lua"
local f = FileExists( fileToFind, filesystem)
if (f) then
  print ("File found" ) 
  funx.dump(f)
else
  print ("File not found", fileToFind)
end
