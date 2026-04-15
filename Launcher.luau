--// launcher for the regui
local repo = "https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/"

local writefile = writefile or function() error("writefile unsupported") end
local makefolder = makefolder or function() end
local readfile = readfile or function() end
local isfile = isfile or function() return false end
local isfolder = isfolder or function() return false end

local hint = _G.Hint == true and {}

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
	if hint then
		local h = Instance.new("Hint")
		h.Text = "Downloading: " .. file
		h.Parent = game:GetService("CoreGui")
		hint[#hint + 1] = h
	end

	local ok, res = pcall(game.HttpGet, game, repo .. file)
	if not ok then return end

	if not isfolder("ReDockGui") then
		makefolder("ReDockGui")
	end

	ensurePath(file)

	local path = "ReDockGui/" .. file
	if not isfile(path) then
		writefile(path, res)
	end
end

--// files
local files = {
	"Init.lua",
	"Demo Window.lua",
	"classes/Animations.lua",
	"classes/Signaling.lua",
	"classes/Wrappers.lua",
	"configurations/Accent.lua",
	"configurations/Flags.lua",
	"configurations/Icons.lua",
	"configurations/Tagging.lua",
	"configurations/Themes.lua"
}

for i = 1, #files do
	download(files[i])
end

--// cleanup hints
if hint then
	task.wait()
	for i = 1, #hint do
		pcall(function()
			hint[i]:Destroy()
		end)
	end
end

--// execute init
return (loadfile and loadfile("ReDockGui/Init.lua"))
	or (loadstring and loadstring(readfile("ReDockGui/Init.lua")))
	and (loadstring(readfile("ReDockGui/Init.lua")))()
