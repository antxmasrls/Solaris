--[[
	Ophyn Key System library (FPS-Optimized & Leak-Free Build)
]]

local __modules = {}
local __cache = {}

local function import(path)
	local cached = __cache[path]
	if cached ~= nil then
		return cached
	end
	local loader = __modules[path]
	if not loader then
		error("module not found: " .. tostring(path))
	end
	local value = loader()
	__cache[path] = value
	return value
end

__modules["utilities/http"] = function()
	local Http = {}
	local remoteCache = {}

	function Http.request()
		return request
			or http_request
			or (syn and syn.request)
			or (http and http.request)
			or (fluxus and fluxus.request)
	end

	function Http.get(url, retries)
		local lastErr = "request failed"
		for attempt = 0, retries or 0 do
			if attempt > 0 then
				task.wait(0.4 * attempt)
			end

			local req = Http.request()
			if req then
				local ok, res = pcall(req, { Url = url, Method = "GET" })
				if ok and type(res) == "table" then
					if res.StatusCode == 200 and type(res.Body) == "string" and res.Body ~= "" then
						return res.Body
					end
					lastErr = "HTTP " .. tostring(res.StatusCode)
				elseif not ok then
					lastErr = tostring(res)
				end
			end

			local ok, body = pcall(function()
				return game:HttpGet(url)
			end)
			if ok and type(body) == "string" and body ~= "" then
				return body
			end
			if not ok then
				lastErr = tostring(body)
			end
		end
		return nil, lastErr
	end

	function Http.loadRemote(url, retries, fresh)
		if not fresh and remoteCache[url] ~= nil then
			return remoteCache[url]
		end
		if not loadstring then
			return nil, "loadstring is not available"
		end

		local body, err = Http.get(url, retries or 1)
		if not body then
			return nil, err
		end

		local fn, compileErr = loadstring(body)
		if not fn then
			return nil, tostring(compileErr)
		end

		local ok, lib = pcall(fn)
		if not ok then
			return nil, tostring(lib)
		end

		if not fresh then
			remoteCache[url] = lib
		end
		return lib
	end

	function Http.clearCache()
		table.clear(remoteCache)
	end

	return Http
end

__modules["images/images"] = function()
	return {
		FONT = "rbxassetid://12187365364",
		KEY = "rbxassetid://96510194465420",
		SUBMIT = "rbxassetid://113692007244654",
		LINK = "rbxassetid://114238209622913",
		DISCORD = "rbxassetid://127255077587058",
		GLOW = "rbxassetid://8992230677",
		LOGO = "rbxassetid://111673746737789",
		CLOSE_ICON = "rbxassetid://110786993356448",
		MOON_ICON = "rbxassetid://83380517901735",
		SHADOW = "rbxassetid://6014261993",
		GAME_PLACEHOLDER = "rbxassetid://74584987850498",
		KEYLESS = "rbxassetid://130551565616516",
	}
end

__modules["variables"] = function()
	return {
		Title = "Ophyn",
		Description = "Key System",
		Logo = "rbxassetid://111673746737789",
		Theme = "Plant-Dark",
		Folder = "Ophyn-KSY",
		getkey = true,
		Intro = "true",
		startintro_size = 80,
		squareintro_time = 1.2,
		squarecontorn = "true",
		Changelogocolor = true,
		Changeiconscolor = true,
		ChangeTheme = "true",
		discord_link = "",
		website_link = "",
		Discord = "true",
		Website = "false",
		Informations = "true",
		Keyless = {
			enabled = false,
			disabletextbox = true,
			disablegetkey = true,
			showcard = true,
			autoconfirm = false,
		},
		NotifStyle = "1",
		TabsStyle = "1",
		SupportedGames = {},
		Callback = function(key) end,
	}
end

__modules["utilities/jnkie"] = function()
	local Http = import("utilities/http")
	local SDK_URL = "https://jnkie.com/sdk/library.lua"

	local Jnkie = {}
	Jnkie.__index = Jnkie

	function Jnkie.new(config)
		config = config or {}
		local self = setmetatable({}, Jnkie)
		self.__isJnkieInstance = true
		self.service = config.Service or config.service
		self.identifier = config.Identifier or config.identifier
		self.provider = config.Provider or config.provider or "Mixed"
		self.client = nil
		self.loadError = nil
		return self
	end

	function Jnkie:_client()
		if self.client then
			return self.client
		end
		local lib, err = Http.loadRemote(SDK_URL, 1, true)
		if not lib then
			self.loadError = err
			return nil
		end
		lib.service = self.service
		lib.identifier = self.identifier
		lib.provider = self.provider
		self.client = lib
		return lib
	end

	local function isSuccess(result)
		if type(result) ~= "table" then
			return false
		end
		if result.valid == true or result.success == true then
			return true
		end
		if result.message == "KEY_VALID" or result.message == "KEYLESS" then
			return true
		end
		return false
	end

	function Jnkie:CheckKey(key)
		local lib = self:_client()
		if not lib then
			return { valid = false, error = self.loadError or "SDK_LOAD_FAILED" }
		end
		local ok, result = pcall(lib.check_key, key)
		if not ok then
			return { valid = false, error = tostring(result) }
		end
		if type(result) ~= "table" then
			return { valid = false, error = "UNEXPECTED_RESPONSE: " .. tostring(result) }
		end
		result.valid = isSuccess(result)
		return result
	end

	function Jnkie:GetKeyLink()
		local lib = self:_client()
		if not lib then
			return nil, self.loadError or "SDK_LOAD_FAILED"
		end
		local ok, link, err = pcall(lib.get_key_link)
		if not ok then
			return nil, tostring(link)
		end
		return link, err
	end

	function Jnkie:Validator()
		local instance = self
		return setmetatable({
			__isJnkie = true,
			__instance = instance,
		}, {
			__call = function(_, key)
				local result = instance:CheckKey(key)
				local reason = result and (result.error or result.message)
				return result and result.valid == true, reason
			end,
		})
	end

	return Jnkie
end

__modules["utilities/lucide"] = function()
	local Http = import("utilities/http")
	local Lucide = {}
	local PACK_URL = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"
	local CACHE_FOLDER = "Ophyn-KSY"
	local CACHE_FILE = CACHE_FOLDER .. "/lucide_pack.lua"
	local PREFIX = "lucide:"

	local pack = nil
	local failed = false
	local loading = false
	local preloaded = {}

	local function readCache()
		if not (isfile and readfile) then return nil end
		local ok, body = pcall(function()
			if isfile(CACHE_FILE) then return readfile(CACHE_FILE) end
		end)
		if ok and type(body) == "string" and body ~= "" then return body end
		return nil
	end

	local function writeCache(body)
		if not writefile then return end
		pcall(function()
			if isfolder and makefolder and not isfolder(CACHE_FOLDER) then
				makefolder(CACHE_FOLDER)
			end
			writefile(CACHE_FILE, body)
		end)
	end

	local function loadPack()
		if pack or failed then return pack end
		if loading then
			while loading do task.wait() end
			return pack
		end
		loading = true
		local ok, result = pcall(function()
			local cached = readCache()
			if cached then
				local okParse, parsed = pcall(function() return loadstring(cached)() end)
				if okParse and type(parsed) == "table" then return parsed end
			end
			local body, err = Http.get(PACK_URL, 1)
			if not body then error(err) end
			local parsed = loadstring(body)()
			if type(parsed) == "table" then writeCache(body) end
			return parsed
		end)
		loading = false
		if ok and type(result) == "table" then
			pack = result
		else
			failed = true
		end
		return pack
	end

	local function toAsset(value)
		if type(value) == "number" then return "rbxassetid://" .. tostring(math.floor(value)) end
		if type(value) == "string" and value:match("^%d+$") then return "rbxassetid://" .. value end
		return value
	end

	function Lucide.isName(value)
		if type(value) ~= "string" or value == "" then return false end
		if value:match("^%d+$") then return false end
		if value:match("^rbx%a*://") or value:match("^https?://") then return false end
		return true
	end

	local function stripPrefix(name)
		if name:sub(1, #PREFIX):lower() == PREFIX then
			return name:sub(#PREFIX + 1)
		end
		return name
	end

	function Lucide.resolve(value)
		if not Lucide.isName(value) then return nil end
		local name = stripPrefix(value):lower():gsub("_", "-")
		local loaded = loadPack()
		if not loaded then return nil end

		local icons = loaded.Icons or loaded
		local entry = type(icons) == "table" and icons[name] or nil
		if type(entry) ~= "table" then return nil end

		local sheet = entry.Image
		if type(loaded.Spritesheets) == "table" and loaded.Spritesheets[tostring(entry.Image)] ~= nil then
			sheet = loaded.Spritesheets[tostring(entry.Image)]
		end
		sheet = toAsset(sheet)
		if type(sheet) ~= "string" then return nil end

		if not preloaded[sheet] then
			preloaded[sheet] = true
			task.spawn(function()
				pcall(function() game:GetService("ContentProvider"):PreloadAsync({ sheet }) end)
			end)
		end

		return {
			Image = sheet,
			RectSize = entry.ImageRectSize or Vector2.new(0, 0),
			RectOffset = entry.ImageRectPosition or entry.ImageRectOffset or Vector2.new(0, 0),
		}
	end

	function Lucide.apply(label, value)
		local sprite = Lucide.resolve(value)
		if sprite then
			label.Image = sprite.Image
			label.ImageRectSize = sprite.RectSize
			label.ImageRectOffset = sprite.RectOffset
			return true
		end
		label.ImageRectSize = Vector2.new(0, 0)
		label.ImageRectOffset = Vector2.new(0, 0)
		if Lucide.isName(value) then
			label.Image = ""
			return false
		end
		label.Image = value or ""
		return value ~= nil
	end

	return Lucide
end

__modules["components/window/notification"] = function()
	local Notification = {}
	local STYLE_BY_NAME = { stripe = "1", pill = "2", island = "3", ring = "4", solid = "5" }

	function Notification.new(ctx)
		local C = ctx.C
		local make, frame, text, round = ctx.make, ctx.frame, ctx.text, ctx.round
		local tween, prep, fade = ctx.tween, ctx.prep, ctx.fade
		local root, cfg, Images = ctx.root, ctx.cfg, ctx.images
		local FONT = ctx.FONT
		local markBoldFont = ctx.markBoldFont

		local NOTIF_W = cfg.NOTIF_W
		local NOTIF_TRANSPARENCY = cfg.NOTIF_TRANSPARENCY
		local NOTIF_COLOR = cfg.NOTIF_COLOR
		local ISLAND_W = 260
		local RING_DOTS = 28
		local MAX_NOTIFS = 4
		local WHITE = Color3.fromRGB(255, 255, 255)
		local DARK = Color3.fromRGB(11, 11, 11)

		local ICONS = {
			key = { Images.KEY, 18 },
			submit = { Images.SUBMIT, 18 },
			link = { Images.LINK, 18 },
			discord = { Images.DISCORD, 18 },
			close = { Images.CLOSE_ICON, 14 },
			moon = { Images.MOON_ICON, 14 },
		}

		local function kindColor(kind)
			if kind == "success" then return C.success
			elseif kind == "warn" then return C.warn
			elseif kind == "error" then return C.error end
			return C.accent
		end

		local function contrastOn(color)
			local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
			return luminance > 0.55 and DARK or WHITE
		end

		local function cardHover()
			return NOTIF_COLOR == "bg" and C.card or C.btn2
		end

		local cornerHolder = make("Frame", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -8),
			Size = UDim2.new(0, NOTIF_W, 1, -16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 20,
		}, root)
		make("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}, cornerHolder)

		local islandHolder = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 12),
			Size = UDim2.new(0, ISLAND_W, 1, -24),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 20,
		}, root)
		make("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}, islandHolder)

		local notifCount = 0
		local activeNotifs = {}

		-- Blur komplett deaktiviert (Hauptursache für massiven FPS-Drop auf iGPUs)
		local Blur = {
			acquire = function() end,
			release = function() end,
		}

		local function newWrapper(holder, width, height)
			return make("Frame", {
				LayoutOrder = notifCount,
				Size = UDim2.new(0, width, 0, height + 8),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			}, holder)
		end

		local function newToast(wrapper, props, radius, strokeColor)
			props.BorderSizePixel = 0
			props.AutoButtonColor = false
			props.ClipsDescendants = true
			props.Text = ""
			local toast = make("TextButton", props, wrapper)
			round(toast, radius, strokeColor)
			local stroke = toast:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				stroke.Transparency = 0.35
			end
			return toast
		end

		local function label(parent, str, x, y, w, h, size, color, bold)
			local l = text(parent, str, x, y, w, h, size, color)
			if bold then markBoldFont(l) end
			l.TextTruncate = Enum.TextTruncate.AtEnd
			return l
		end

		local function iconImage(parent, spec, color, size)
			return make("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, size, 0, size),
				BackgroundTransparency = 1,
				Image = spec[1],
				ImageColor3 = color,
			}, parent)
		end

		local function buildStripe(title, message, color)
			local W, H = NOTIF_W, 62
			local wrapper = newWrapper(cornerHolder, W, H)
			local toast = newToast(wrapper, {
				Position = UDim2.new(0, 40, 0, 0),
				Size = UDim2.new(0, W, 0, H),
				BackgroundColor3 = C[NOTIF_COLOR],
				BackgroundTransparency = NOTIF_TRANSPARENCY,
			}, 10, C.stroke)

			round(frame(toast, 8, 10, 3, H - 20, color, 0), 2)
			label(toast, title, 22, 11, W - 36, 18, 13, C.text, true)
			label(toast, message, 22, 30, W - 36, 16, 12, C.muted)

			local trackW = W - 44
			round(frame(toast, 22, H - 9, trackW, 2, color, 0.8), 1)
			local fill = frame(toast, 22, H - 9, trackW, 2, color, 0)
			round(fill, 1)

			return {
				wrapper = wrapper,
				toast = toast,
				startPos = UDim2.new(0, 40, 0, 0),
				restPos = UDim2.new(0, 0, 0, 0),
				baseColor = C[NOTIF_COLOR],
				hoverColor = cardHover(),
				progress = function(fraction)
					fill.Size = UDim2.new(0, math.floor(trackW * fraction), 0, 2)
				end,
			}
		end

		local function escapeRich(str)
			return (str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
		end

		local function buildPill(title, message, color, spec)
			local H = 36
			local wrapper = make("Frame", {
				LayoutOrder = notifCount,
				Size = UDim2.new(0, NOTIF_W, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			}, cornerHolder)
			make("UIPadding", { PaddingBottom = UDim.new(0, 8) }, wrapper)

			local toast = newToast(wrapper, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 40, 0, 0),
				Size = UDim2.new(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundColor3 = C[NOTIF_COLOR],
				BackgroundTransparency = NOTIF_TRANSPARENCY,
			}, H / 2, C.stroke)
			make("UISizeConstraint", { MinSize = Vector2.new(0, H) }, toast)
			make("UIPadding", {
				PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 14),
				PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
			}, toast)
			make("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}, toast)

			local badge = make("Frame", {
				LayoutOrder = 1,
				Size = UDim2.new(0, 24, 0, 24),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
			}, toast)
			make("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)
			iconImage(badge, spec, contrastOn(color), math.min(spec[2], 14))

			local rich = "<b>" .. escapeRich(title) .. "</b>"
			if message ~= "" then
				rich = rich .. '  <font color="#' .. C.muted:ToHex() .. '">' .. escapeRich(message) .. "</font>"
			end
			local body = make("TextLabel", {
				LayoutOrder = 2,
				Size = UDim2.new(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				RichText = true,
				TextWrapped = true,
				Text = rich,
				TextSize = 13,
				TextColor3 = C.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				FontFace = FONT,
			}, toast)
			make("UISizeConstraint", { MaxSize = Vector2.new(NOTIF_W - 52, math.huge) }, body)

			return {
				wrapper = wrapper,
				toast = toast,
				startPos = UDim2.new(1, 40, 0, 0),
				restPos = UDim2.new(1, 0, 0, 0),
				baseColor = C[NOTIF_COLOR],
				hoverColor = cardHover(),
			}
		end

		local STYLES = {
			["1"] = buildStripe,
			["2"] = buildPill,
			["3"] = buildStripe,
			["4"] = buildStripe,
			["5"] = buildStripe,
		}

		local function resolveKey()
			local raw = ctx.getStyle and ctx.getStyle() or "1"
			local key = (tostring(raw):lower():gsub("%s+", ""))
			key = STYLE_BY_NAME[key] or key
			return STYLES[key] and key or "1"
		end

		local function notify(title, message, kind, iconKey, duration)
			if not root.Parent then return end
			kind = kind or "info"
			duration = duration or 3.5
			title = tostring(title or "")
			message = tostring(message or "")
			local color = kindColor(kind)
			local spec = ICONS[iconKey] or (kind == "error" and ICONS.close or ICONS.key)

			notifCount += 1
			local n = STYLES[resolveKey()](title, message, color, spec)
			local wrapper, toast = n.wrapper, n.toast
			local items = prep(toast)
			fade(items, 0)

			local handle = {}
			local dismissed = false
			function handle.dismiss()
				if dismissed then return end
				dismissed = true
				local idx = table.find(activeNotifs, handle)
				if idx then table.remove(activeNotifs, idx) end
				if wrapper and wrapper.Parent then
					fade(items, 0, 0.2)
					task.delay(0.22, function()
						if wrapper and wrapper.Parent then
							wrapper:Destroy()
						end
					end)
				end
			end

			toast.MouseButton1Click:Connect(handle.dismiss)
			fade(items, 1, 0.25)
			tween(toast, 0.35, { Position = n.restPos }, Enum.EasingStyle.Quint)

			task.spawn(function()
				local remaining = duration
				local started = os.clock()
				local last = started
				while not dismissed and root.Parent do
					task.wait(0.1)
					local now = os.clock()
					remaining -= now - last
					last = now
					if n.progress and now - started > 0.35 then
						n.progress(math.clamp(remaining / duration, 0, 1))
					end
					if remaining <= 0 then
						handle.dismiss()
						break
					end
				end
			end)

			table.insert(activeNotifs, handle)
			while #activeNotifs > MAX_NOTIFS do
				activeNotifs[1].dismiss()
			end
			return handle
		end

		local function dismissAll()
			for i = #activeNotifs, 1, -1 do
				activeNotifs[i].dismiss()
			end
		end

		return {
			notify = notify,
			dismissAll = dismissAll,
			styleKey = resolveKey,
			blur = Blur,
		}
	end

	return Notification
end

__modules["components/window/pages"] = function()
	local Pages = {}
	function Pages.new(ctx)
		return {
			createTab = function() return {} end,
			open = function() end,
			back = function() end,
			fadeOut = function() end,
			isOpen = function() return false end,
		}
	end
	return Pages
end

__modules["components/window/ui"] = function()
	local TweenService = game:GetService("TweenService")
	local Players = game:GetService("Players")
	local HttpService = game:GetService("HttpService")
	local UserInputService = game:GetService("UserInputService")
	local MarketplaceService = game:GetService("MarketplaceService")
	local player = Players.LocalPlayer

	local Images = import("images/images")
	local Notification = import("components/window/notification")
	local Variables = import("variables")
	local Jnkie = import("utilities/jnkie")
	local Pages = import("components/window/pages")
	local Lucide = import("utilities/lucide")
	local Http = import("utilities/http")

	local FONT = Font.new(Images.FONT, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	local FONT_BOLD = Font.new(Images.FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	local GLOW = Images.GLOW
	local CLOSE_ICON = Images.CLOSE_ICON
	local MOON_ICON = Images.MOON_ICON

	local FINAL_W, FINAL_H = 460, 260
	local NOTIF_W, NOTIF_H = 300, 70
	local NOTIF_TRANSPARENCY = 0.28
	local NOTIF_COLOR = "bg"
	local NOTIF_BLUR = 0

	local CHECK_TIME = 0.8
	local SAVED_CHECK_TIME = 0.15
	local MAX_FAILED_ATTEMPTS = 5
	local LOCKOUT_TIME = 30

	local WHITE = Color3.fromRGB(255, 255, 255)
	local uiSettings = { tintIcons = true, tintLogo = true }

	local function asBool(v, default)
		if v == nil then return default end
		if type(v) == "string" then return v:lower() == "true" end
		return v == true
	end

	local function assetId(v)
		if v == nil or v == "" then return nil end
		local str = tostring(v)
		if str:match("^%d+$") then return "rbxassetid://" .. str end
		return str
	end

	local function iconRole(role) return uiSettings.tintIcons and role or WHITE end
	local function logoRole(role) return uiSettings.tintLogo and role or WHITE end

	local function mountGui(gui)
		if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
		local getters = {
			function() return gethui and gethui() end,
			function() return game:GetService("CoreGui") end,
			function() return player and player:FindFirstChildOfClass("PlayerGui") end,
		}
		for _, get in ipairs(getters) do
			local ok, parent = pcall(get)
			if ok and typeof(parent) == "Instance" then
				local old = parent:FindFirstChild(gui.Name)
				if old and old ~= gui then
					pcall(function() old:Destroy() end)
				end
				if pcall(function() gui.Parent = parent end) and gui.Parent == parent then
					return true
				end
			end
		end
		return false
	end

	local THEMES = {
		["Plant-Dark"] = {
			bg = Color3.fromRGB(10, 10, 10),
			input = Color3.fromRGB(14, 16, 14),
			card = Color3.fromRGB(18, 22, 19),
			stroke = Color3.fromRGB(34, 42, 36),
			btn2 = Color3.fromRGB(28, 34, 29),
			btn2Hover = Color3.fromRGB(40, 48, 42),
			text = Color3.fromRGB(238, 242, 238),
			muted = Color3.fromRGB(122, 132, 124),
			accent = Color3.fromRGB(70, 214, 110),
			warn = Color3.fromRGB(240, 176, 108),
			success = Color3.fromRGB(120, 220, 150),
			error = Color3.fromRGB(240, 120, 120),
			submitBg = Color3.fromRGB(22, 101, 52),
			submitText = Color3.fromRGB(255, 255, 255),
			glowBase = Color3.fromRGB(110, 255, 150),
			glowFrom = Color3.fromRGB(90, 240, 130),
			glowTo = Color3.fromRGB(30, 170, 70),
			confetti = {
				Color3.fromRGB(70, 214, 110),
				Color3.fromRGB(150, 245, 175),
				Color3.fromRGB(255, 255, 255),
			},
		},
		Carmim = {
			bg = Color3.fromRGB(10, 10, 10),
			input = Color3.fromRGB(16, 14, 14),
			card = Color3.fromRGB(20, 17, 17),
			stroke = Color3.fromRGB(38, 32, 32),
			btn2 = Color3.fromRGB(32, 28, 28),
			btn2Hover = Color3.fromRGB(46, 40, 40),
			text = Color3.fromRGB(240, 236, 236),
			muted = Color3.fromRGB(130, 122, 122),
			accent = Color3.fromRGB(230, 45, 55),
			warn = Color3.fromRGB(240, 176, 108),
			success = Color3.fromRGB(120, 210, 140),
			error = Color3.fromRGB(240, 120, 120),
			submitBg = Color3.fromRGB(139, 17, 27),
			submitText = Color3.fromRGB(255, 255, 255),
			glowBase = Color3.fromRGB(255, 120, 120),
			glowFrom = Color3.fromRGB(255, 90, 90),
			glowTo = Color3.fromRGB(200, 20, 35),
			confetti = {
				Color3.fromRGB(230, 45, 55),
				Color3.fromRGB(255, 120, 120),
				Color3.fromRGB(255, 255, 255),
			},
		},
		Dark = {
			bg = Color3.fromRGB(10, 10, 10),
			input = Color3.fromRGB(18, 18, 18),
			card = Color3.fromRGB(23, 23, 23),
			stroke = Color3.fromRGB(46, 46, 46),
			btn2 = Color3.fromRGB(34, 34, 34),
			btn2Hover = Color3.fromRGB(48, 48, 48),
			text = Color3.fromRGB(255, 255, 255),
			muted = Color3.fromRGB(150, 150, 150),
			accent = Color3.fromRGB(255, 255, 255),
			warn = Color3.fromRGB(240, 176, 108),
			success = Color3.fromRGB(120, 210, 140),
			error = Color3.fromRGB(240, 120, 120),
			submitBg = Color3.fromRGB(66, 66, 66),
			submitText = Color3.fromRGB(255, 255, 255),
			glowBase = Color3.fromRGB(255, 255, 255),
			glowFrom = Color3.fromRGB(255, 255, 255),
			glowTo = Color3.fromRGB(210, 210, 210),
			confetti = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(200, 200, 200),
			},
		},
	}

	local THEME_ORDER = { "Carmim", "Plant-Dark", "Dark" }
	local themeIndex = 2
	local C = {}
	local function loadTheme(theme)
		for k, v in pairs(theme) do C[k] = v end
	end

	local COLOR_PROPS = {
		BackgroundColor3 = true, TextColor3 = true, ImageColor3 = true, Color = true, PlaceholderColor3 = true,
	}
	local bindings = {}
	local gradients = {}
	local fontBindings = {}

	local function markTitleFont(inst)
		for _, entry in ipairs(fontBindings) do
			if entry.inst == inst then
				entry.title = true
				inst.FontFace = entry.bold and FONT_BOLD or FONT
				return
			end
		end
	end

	local function markBoldFont(inst)
		for _, entry in ipairs(fontBindings) do
			if entry.inst == inst then
				entry.bold = true
				inst.FontFace = FONT_BOLD
				return
			end
		end
	end

	local function make(class, props, parent)
		local inst = Instance.new(class)
		for k, v in pairs(props) do
			if type(v) == "string" and COLOR_PROPS[k] then
				bindings[#bindings + 1] = { inst, k, v }
				inst[k] = C[v]
			elseif k == "FontFace" and (v == FONT or v == FONT_BOLD) then
				fontBindings[#fontBindings + 1] = { inst = inst, bold = (v == FONT_BOLD), title = false }
				inst[k] = v
			else
				inst[k] = v
			end
		end
		inst.Parent = parent
		return inst
	end

	local function setRole(inst, prop, role)
		for _, b in ipairs(bindings) do
			if b[1] == inst and b[2] == prop then
				b[3] = role
				inst[prop] = C[role]
				return
			end
		end
		bindings[#bindings + 1] = { inst, prop, role }
		inst[prop] = C[role]
	end

	local function frame(parent, x, y, w, h, color, transparency)
		return make("Frame", {
			Position = UDim2.new(0, x, 0, y),
			Size = UDim2.new(0, w, 0, h),
			BackgroundColor3 = color or C.bg,
			BackgroundTransparency = transparency or 1,
			BorderSizePixel = 0,
		}, parent)
	end

	local function text(parent, str, x, y, w, h, size, color, align)
		return make("TextLabel", {
			Position = UDim2.new(0, x, 0, y),
			Size = UDim2.new(0, w, 0, h),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = str,
			TextSize = size,
			TextColor3 = color,
			TextXAlignment = align or Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			FontFace = FONT,
		}, parent)
	end

	local function round(parent, radius, strokeColor)
		make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
		if strokeColor then
			make("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Color = strokeColor }, parent)
		end
	end

	local function icon(parent, x, y, color, image)
		local holder = frame(parent, x, y, 16, 16)
		local img = make("ImageLabel", {
			Name = "iconimage",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ImageColor3 = iconRole(color),
		}, holder)
		Lucide.apply(img, image)
		return holder
	end

	local function centered(parent, w, h)
		return make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, w, 0, h),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, parent)
	end

	local function tween(inst, time, props, style, dir)
		if not inst or not inst.Parent then return nil end
		local t = TweenService:Create(
			inst,
			TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
			props
		)
		t:Play()
		return t
	end

	local function prep(container)
		local items = {}
		local function add(inst)
			if inst:IsA("GuiObject") then
				items[#items + 1] = { inst, "BackgroundTransparency", inst.BackgroundTransparency }
				if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
					items[#items + 1] = { inst, "TextTransparency", inst.TextTransparency }
				elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
					items[#items + 1] = { inst, "ImageTransparency", inst.ImageTransparency }
				end
			elseif inst:IsA("UIStroke") then
				items[#items + 1] = { inst, "Transparency", inst.Transparency }
			end
		end
		add(container)
		for _, d in ipairs(container:GetDescendants()) do add(d) end
		return items
	end

	local function fade(items, alpha, time)
		for _, it in ipairs(items) do
			local inst, prop, orig = it[1], it[2], it[3]
			if inst and inst.Parent then
				local target = 1 - (1 - orig) * alpha
				if time and time > 0 then
					tween(inst, time, { [prop] = target })
				else
					inst[prop] = target
				end
			end
		end
	end

	local UI = {}
	UI.Jnkie = Jnkie

	function UI.new(options)
		local cfg = {}
		for k, v in pairs(Variables) do cfg[k] = v end
		for k, v in pairs(options or {}) do cfg[k] = v end

		local HUB_NAME = tostring(cfg.Title)
		local HUB_SUBTITLE = tostring(cfg.Description)
		local FOLDER = cfg.Folder
		local LOGO = assetId(cfg.Logo) or Images.LOGO

		local INTRO_SIZE = tonumber(cfg.startintro_size) or 80
		local LOADING_TIME = 1.2
		local SQUARE_TIME = tonumber(cfg.squareintro_time) or 0.6

		local themeName = cfg.Theme
		if not THEMES[themeName] then themeName = "Plant-Dark" end
		loadTheme(THEMES[themeName])

		local KEY_CFG = cfg.KeySystem or {}
		local KEY_SAVE = asBool(KEY_CFG.SaveKey, false)
		local apiEntries = type(KEY_CFG.API) == "table" and KEY_CFG.API or {}
		if apiEntries.Type ~= nil or apiEntries.type ~= nil then apiEntries = { apiEntries } end

		local API_SERVICES = {}
		for _, entry in ipairs(apiEntries) do
			local kind = type(entry) == "table" and tostring(entry.Type or entry.type or ""):lower() or ""
			if kind == "jnkie" then
				local instance = Jnkie.new(entry)
				table.insert(API_SERVICES, {
					CheckKey = function(_, key)
						local res = instance:CheckKey(key)
						return res ~= nil and res.valid == true, res and (res.error or res.message)
					end,
					GetKeyLink = function() return instance:GetKeyLink() end,
				})
			end
		end

		local function validateKey(key)
			if type(KEY_CFG.Key) == "table" then
				for _, k in ipairs(KEY_CFG.Key) do
					if tostring(k) == key then return true end
				end
			end
			for _, service in ipairs(API_SERVICES) do
				local ok, valid, why = pcall(service.CheckKey, service, key)
				if ok and valid then return true end
				if ok and why then return false, why end
			end
			return false, "Invalid key"
		end

		local KEY_FILE = (FOLDER and FOLDER ~= "" and (FOLDER .. "/saved_key.txt")) or "saved_key.txt"
		local SAVED_KEY = nil
		if KEY_SAVE and isfile and readfile and pcall(isfile, KEY_FILE) and isfile(KEY_FILE) then
			local ok, content = pcall(readfile, KEY_FILE)
			if ok and content and content:match("%S") then
				SAVED_KEY = content:match("^%s*(.-)%s*$")
			end
		end

		local state = { ready = false, closing = false }
		local root = Instance.new("ScreenGui")
		root.Name = "ophyn-ui-wow"
		root.DisplayOrder = 999
		root.IgnoreGuiInset = true
		root.ResetOnSpawn = false

		-- Komplette Speicherbereinigung beim Zerstören der UI
		local activeConnections = {}
		local function trackConn(conn)
			table.insert(activeConnections, conn)
			return conn
		end

		local function cleanupAll()
			for _, conn in ipairs(activeConnections) do
				if conn.Connected then
					conn:Disconnect()
				end
			end
			table.clear(activeConnections)
			table.clear(bindings)
			table.clear(gradients)
			table.clear(fontBindings)
			Http.clearCache()
			table.clear(__cache)
		end

		root.Destroying:Connect(cleanupAll)

		local main = make("Frame", {
			Name = "Frame",
			Size = UDim2.new(0, FINAL_W, 0, FINAL_H),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, root)

		local canvas = make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = "bg",
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ClipsDescendants = true,
		}, main)
		make("UICorner", { CornerRadius = UDim.new(0, 10) }, canvas)
		make("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = "stroke" }, canvas)

		local ctx = {
			C = C, make = make, frame = frame, text = text, round = round,
			tween = tween, prep = prep, fade = fade, images = Images,
			FONT = FONT, FONT_BOLD = FONT_BOLD, markBoldFont = markBoldFont,
			root = root, canvas = canvas, state = state,
			cfg = { NOTIF_W = NOTIF_W, NOTIF_H = NOTIF_H, NOTIF_TRANSPARENCY = NOTIF_TRANSPARENCY, NOTIF_COLOR = NOTIF_COLOR },
		}

		local notifs = Notification.new(ctx)
		local notify = notifs.notify

		local content = centered(canvas, FINAL_W, FINAL_H)
		local left = frame(content, 0, 0, 272, 260)

		make("ImageLabel", {
			Position = UDim2.new(0, 22, 0, 20),
			Size = UDim2.new(0, 36, 0, 32),
			BackgroundTransparency = 1,
			Image = LOGO,
			ImageColor3 = logoRole("accent"),
			ScaleType = Enum.ScaleType.Fit,
		}, left)

		local hubTitle = text(left, HUB_NAME, 66, 20, 190, 22, 20, "text")
		markTitleFont(hubTitle)
		local hubSubtitle = text(left, HUB_SUBTITLE, 66, 42, 190, 14, 12, "muted")

		text(left, "License key", 22, 78, 228, 14, 11, "muted")
		local inputBox = frame(left, 22, 96, 228, 36, "input", 0)
		round(inputBox, 8, "stroke")
		icon(inputBox, 12, 10, "muted", Images.KEY)

		local keyBox = make("TextBox", {
			Position = UDim2.new(0, 38, 0, 0),
			Size = UDim2.new(1, -48, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			TextSize = 13,
			TextColor3 = "text",
			TextXAlignment = Enum.TextXAlignment.Left,
			PlaceholderText = "Paste your key here",
			PlaceholderColor3 = "muted",
			ClearTextOnFocus = false,
			FontFace = FONT,
		}, inputBox)

		local submit = make("TextButton", {
			Position = UDim2.new(0, 22, 0, 142),
			Size = UDim2.new(0, 110, 0, 34),
			BackgroundColor3 = "submitBg",
			AutoButtonColor = false,
			Text = "Submit",
			TextSize = 13,
			TextColor3 = "submitText",
			FontFace = FONT,
		}, left)
		round(submit, 8)
		make("UIPadding", { PaddingLeft = UDim.new(0, 24) }, submit)
		icon(submit, -12, 9, "submitText", Images.SUBMIT)

		local getKey = make("TextButton", {
			Position = UDim2.new(0, 140, 0, 142),
			Size = UDim2.new(0, 110, 0, 34),
			BackgroundColor3 = "btn2",
			AutoButtonColor = false,
			Text = "Get a key",
			TextSize = 13,
			TextColor3 = "text",
			FontFace = FONT,
		}, left)
		round(getKey, 8, "stroke")
		make("UIPadding", { PaddingLeft = UDim.new(0, 24) }, getKey)
		icon(getKey, -12, 9, "text", Images.KEY)

		local avatar = make("ImageLabel", {
			Position = UDim2.new(0, 22, 0, 214),
			Size = UDim2.new(0, 32, 0, 32),
			BackgroundColor3 = "input",
			Image = player and ("rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150") or "",
		}, left)
		round(avatar, 16, "stroke")

		text(left, "Welcome Back", 62, 215, 188, 14, 11, "muted")
		local welcomeName = text(left, ((player and player.DisplayName) or "User") .. "!", 62, 229, 188, 16, 14, "text")
		markBoldFont(welcomeName)

		frame(content, 272, 20, 1, 220, "stroke", 0)
		local right = frame(content, 273, 0, 187, 260)

		text(right, "Status", 20, 24, 147, 14, 11, "muted")
		local statusValue = text(right, "Key required", 20, 42, 147, 16, 13, "warn")
		markBoldFont(statusValue)

		local closeBtn = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 12),
			Size = UDim2.new(0, 26, 0, 26),
			BackgroundColor3 = "card",
			BackgroundTransparency = 1,
			Text = "",
		}, content)
		make("UICorner", { CornerRadius = UDim.new(0, 7) }, closeBtn)
		make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 12, 0, 12),
			BackgroundTransparency = 1,
			Image = CLOSE_ICON,
			ImageColor3 = iconRole("muted"),
		}, closeBtn)

		local checkingKey = false
		local function runKeyCheck(key, isSavedKey)
			if checkingKey or state.closing then return end
			checkingKey = true
			state.ready = false
			statusValue.Text = "Checking..."
			setRole(statusValue, "TextColor3", "muted")

			task.spawn(function()
				local ok, valid, reason = pcall(validateKey, key)
				if state.closing then return end

				if not (ok and valid) then
					if isSavedKey and delfile and isfile and pcall(isfile, KEY_FILE) and isfile(KEY_FILE) then
						pcall(delfile, KEY_FILE)
					end
					statusValue.Text = "Invalid key"
					setRole(statusValue, "TextColor3", "error")
					notify("Invalid key", tostring(reason or "Key rejected"), "error")
					state.ready = true
					checkingKey = false
					return
				end

				statusValue.Text = "Key valid!"
				setRole(statusValue, "TextColor3", "success")

				if KEY_SAVE and writefile then
					if FOLDER and FOLDER ~= "" and isfolder and makefolder and not isfolder(FOLDER) then
						pcall(makefolder, FOLDER)
					end
					pcall(writefile, KEY_FILE, key)
				end

				notify("Success", "Loading script...", "success")
				task.wait(0.4)

				state.closing = true
				notifs.dismissAll()

				local callback = cfg.Callback
				root:Destroy() -- Zerstört GUI & trennt alle Events VOR dem Laden des Hubs!

				if type(callback) == "function" then
					task.spawn(callback, key)
				end
			end)
		end

		trackConn(getKey.MouseButton1Click:Connect(function()
			if not state.ready or state.closing then return end
			task.spawn(function()
				for _, service in ipairs(API_SERVICES) do
					if service.GetKeyLink then
						local ok, link, err = pcall(service.GetKeyLink)
						if ok and link then
							local fn = setclipboard or toclipboard
							if fn then pcall(fn, link) end
							notify("Copied", "Key link copied to clipboard.", "success", "link")
							return
						else
							notify("Error", tostring(err or "Failed to get link"), "warn")
							return
						end
					end
				end
			end)
		end))

		trackConn(submit.MouseButton1Click:Connect(function()
			if not state.ready or state.closing then return end
			local key = keyBox.Text:match("^%s*(.-)%s*$")
			if key == "" then
				notify("Empty", "Enter a key first.", "warn")
				return
			end
			runKeyCheck(key, false)
		end))

		trackConn(keyBox.FocusLost:Connect(function(enterPressed)
			if enterPressed and state.ready and not state.closing then
				local key = keyBox.Text:match("^%s*(.-)%s*$")
				if key ~= "" then runKeyCheck(key, false) end
			end
		end))

		trackConn(closeBtn.MouseButton1Click:Connect(function()
			if state.closing then return end
			state.closing = true
			notifs.dismissAll()
			root:Destroy()
		end))

		if not mountGui(root) then
			root:Destroy()
			error("Could not mount GUI")
		end

		state.ready = true
		if SAVED_KEY then
			keyBox.Text = SAVED_KEY
			runKeyCheck(SAVED_KEY, true)
		end

		return { Gui = root }
	end

	return UI
end

local KeySystem = {}
function KeySystem.new(options)
	return import("components/window/ui").new(options)
end
KeySystem.Jnkie = import("utilities/jnkie")

return KeySystem