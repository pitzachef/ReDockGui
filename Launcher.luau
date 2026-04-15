--// WIP
--// can be not used anyway but i recommend you should
--// used for loading regui

local repo = "https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/"

local writefile = writefile or function() error("writefile unsupported") end
local makefolder = makefolder or function() end
local isfile = isfile or function() return false end
local isfolder = isfolder or function() return false end

local http_request =
	syn and syn.request
	or http_request
	or request

local function req(url, method)
	if http_request then
		local ok, res = pcall(function()
			return http_request({
				Url = url,
				Method = method or "GET",
			})
		end)
		if ok then
			return res
		end
	end

	return { Body = game:HttpGet(url) }
end

local function getSize(file)
	local res = req(repo .. file, "HEAD")
	if not res or not res.Headers then return nil end

	local len = res.Headers["Content-Length"] or res.Headers["content-length"]
	return len and tonumber(len) or nil
end

local function IsPath(path)
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
	local size = getSize(file)
	print(("Downloading %s (%s bytes)"):format(file, size and tostring(size) or "unknown"))

	local res = req(repo .. file, "GET")
	if not res then
		warn("Failed:", file)
		return
	end

	local body = res.Body or ""
	print(("Downloaded %s (%d bytes)"):format(file, #body))

	if not isfolder("ReDockGui") then
		makefolder("ReDockGui")
	end

	IsPath(file)

	local path = "ReDockGui/" .. file

	if not isfile(path) then
		writefile(path, body)
	end
end

download("Init.lua")
download("Demo%20Window.lua") -- idk why they put spaces but ok
download("classes/Animations.lua")
download("classes/Signaling.lua")
download("classes/Wrappers.lua")
download("configurations/Accent.lua")
download("configurations/Flags.lua")
download("configurations/Icons.lua")
download("configurations/Tagging.lua")
download("configurations/Themes.lua")

return loadfile("ReDockGui/Init.lua")() -- yeah its like that
