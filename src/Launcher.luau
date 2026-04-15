--// WIP
--// used for loading regui

local repo = "https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/"

local writefile = writefile or function() error("writefile unsupported") end
local makefolder = makefolder or function() end
local isfile = isfile or function() return false end
local isfolder = isfolder or function() return false end

local function ensurePath(path)
	local parts = path:split("/")
	local current = ""

	for i = 1, #parts - 1 do
		current = current .. (i > 1 and "/" or "") .. parts[i]
		if not isfolder("ReDockGui/" .. current) then
			makefolder("ReDockGui/" .. current)
		end
	end
end

local function download(file)
	local ok, res = pcall(function()
		return game:HttpGet(repo .. file)
	end)

	if not ok then
		warn("Failed:", file)
		return
	end

	if not isfolder("ReDockGui") then
		makefolder("ReDockGui")
	end

	ensurePath(file)

	local path = "ReDockGui/" .. file

	if not isfile(path) then
		writefile(path, res)
	end
end

download("Init.lua")
download("Demo Window.lua")
download("classes/Animations.lua")
download("classes/Signaling.lua")
download("classes/Wrappers.lua")
download("configurations/Accent.lua")
download("configurations/Flags.lua")
download("configurations/Icons.lua")
download("configurations/Tagging.lua")
download("configurations/Themes.lua")

return loadfile("ReDockGui/Init.lua")()
