do
if not MV_OBFUSCATED then
    MV_OMIT = function(fn) return fn end
    MV_CFF = function(fn) return fn end
end

TweenService = game:GetService("TweenService")
CoreGui = game:GetService("CoreGui")

function applyVexonStyle(obj, isMain)
    obj.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    local corner = Instance.new("UICorner", obj)
    corner.CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", obj)
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(170, 0, 255)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local glowGradient = Instance.new("UIGradient", stroke)
    glowGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 255))
    }
    
    if isMain then
        stroke.Transparency = 0.1
    else
        stroke.Transparency = 0.4
    end
end

function checkExecutorSupport()
    local executorName = (_G.VexonHub and _G.VexonHub.SystemInfo and _G.VexonHub.SystemInfo.Executor) or "Unknown"
    local executorScore = (_G.VexonHub and _G.VexonHub.ExecutorScore) or { unc = 0, sunc = 0, total = 0, supported = false }
    totalSupport = executorScore.total
    isSupported = executorScore.supported
    unc_support = executorScore.unc
    sunc_support = executorScore.sunc
    return {
        supported = isSupported,
        unc = unc_support,
        sunc = sunc_support
    }
end

function StartNormalVersion()



repeat task.wait() until game:IsLoaded();


workspace:SetAttribute("VIPServer", true)
-- ════════════════════════════════════════════════════════════════
-- ZRHUB: Obsidian UI, with a small WindUI-style wrapper so the hub's tabs build on it
-- ════════════════════════════════════════════════════════════════
local OBS = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(OBS .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(OBS .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(OBS .. "addons/SaveManager.lua"))()
local Toggles, Options = Library.Toggles, Library.Options
ZR_Library = Library

local ZR_used = {}
local function ZR_id(base)
    base = "V_" .. tostring(base or "zr"):gsub("[^%w_]", "_")
    local id, n = base, 1
    while ZR_used[id] do n += 1 id = base .. "_" .. n end
    ZR_used[id] = true
    return id
end
local function ZR_noopObj()
    return setmetatable({}, { __index = function() return function() return ZR_noopObj() end end })
end
local function ZR_text(info) return tostring(info.Title or info.Text or info.Name or "") end
local function ZR_tip(info) local d = info.Desc or info.Description return (d ~= nil and d ~= "") and tostring(d) or nil end
local function ZR_rounding(step)
    step = tonumber(step) or 1
    if step >= 1 then return 0 end
    local s = tostring(step)
    local dec = s:match("%.(%d+)")
    return dec and #dec or 2
end

-- VexonHub items left out (KittyWare's No Stun / No Slow / No Fatigue replace them)
ZR_VEX_SKIP = {
    ["No Dash Cool Down"] = true, ["No Stun Cframe Walk"] = true,
    ["Select Movement Modifications"] = true, ["Enable Movement Modifications"] = true,
    ["Teleport UI"] = true, -- on-screen buttons: only M1 Reset and True DownSlam keep one
}
ZR_VEX_SKIP_SECTIONS = { ["Bring Settings"] = true }
-- keybinds go on the main feature toggles (empty by default)
local ZR_KEYED = {}

local function ZR_Elements(getBox, opts)
    opts = opts or {}
    local E = {}
    function E:Toggle(info)
        if info.Locked == true or ZR_VEX_SKIP[ZR_text(info)] then return ZR_noopObj() end
        local id = ZR_id(info.Flag or ("t_" .. ZR_text(info)))
        local box = getBox()
        local default = info.Default
        if default == nil then default = info.Value end
        local t = box:AddToggle(id, { Text = ZR_text(info), Default = default == true, Tooltip = ZR_tip(info), Callback = function(v)
            if info.Callback then info.Callback(v) end
        end })
        if not opts.noKeys then
            pcall(function()
                t:AddKeyPicker(id .. "_key", { Default = "None", Mode = "Toggle", SyncToggleState = true, Text = ZR_text(info) })
            end)
        end
        ZR_KEYED[#ZR_KEYED + 1] = id
        local o = {}
        function o:Set(v) Toggles[id]:SetValue(v) end
        o.SetValue = o.Set
        function o:Lock() pcall(function() Toggles[id]:SetDisabled(true) end) end
        function o:Unlock() pcall(function() Toggles[id]:SetDisabled(false) end) end
        function o:Destroy() pcall(function() Toggles[id]:SetVisible(false) end) end
        function o:SetTitle(s) pcall(function() Toggles[id]:SetText(s) end) end
        function o:SetDesc() end
        return setmetatable(o, { __index = function(_, k) if k == "Value" then return Toggles[id].Value end return function() end end })
    end
    function E:Button(info)
        if info.Locked == true or ZR_VEX_SKIP[ZR_text(info)] then return ZR_noopObj() end
        local box = getBox()
        local b = box:AddButton({ Text = ZR_text(info), Tooltip = ZR_tip(info), Func = function()
            if info.Callback then info.Callback() end
        end })
        local o = {}
        function o:Destroy() pcall(function() b:SetVisible(false) end) end
        function o:SetTitle(s) pcall(function() b:SetText(s) end) end
        function o:Lock() pcall(function() b:SetDisabled(true) end) end
        function o:Unlock() pcall(function() b:SetDisabled(false) end) end
        return setmetatable(o, { __index = function() return function() end end })
    end
    function E:Slider(info)
        if info.Locked == true or ZR_VEX_SKIP[ZR_text(info)] then return ZR_noopObj() end
        local id = ZR_id(info.Flag or ("s_" .. ZR_text(info)))
        local v = type(info.Value) == "table" and info.Value or {}
        local min, max = tonumber(v.Min) or 0, tonumber(v.Max) or 100
        local def = tonumber(v.Default) or min
        getBox():AddSlider(id, { Text = ZR_text(info), Tooltip = ZR_tip(info), Min = min, Max = max, Default = math.clamp(def, min, max),
            Rounding = ZR_rounding(info.Step), Callback = function(x) if info.Callback then info.Callback(x) end end })
        local o = {}
        function o:Set(x) Options[id]:SetValue(x) end
        o.SetValue = o.Set
        return setmetatable(o, { __index = function(_, k) if k == "Value" then return Options[id].Value end return function() end end })
    end
    function E:Dropdown(info)
        if info.Locked == true or ZR_VEX_SKIP[ZR_text(info)] then return ZR_noopObj() end
        local id = ZR_id(info.Flag or ("d_" .. ZR_text(info)))
        local values = type(info.Values) == "table" and table.clone(info.Values) or {}
        local multi = info.Multi == true
        local default
        if multi then
            default = {}
            if type(info.Value) == "table" then for _, x in ipairs(info.Value) do if table.find(values, x) then table.insert(default, x) end end end
        elseif info.Value ~= nil and table.find(values, info.Value) then
            default = info.Value
        end
        local special = info.SpecialType == "Player" and "Player" or nil
        getBox():AddDropdown(id, { Text = ZR_text(info), Tooltip = ZR_tip(info), Values = values, Default = default, Multi = multi,
            SpecialType = special, ExcludeLocalPlayer = special and (info.ExcludeLocalPlayer ~= false) or nil, Searchable = info.SearchBarEnabled == true,
            AllowNull = info.AllowNone ~= false, Callback = function(val)
                if not info.Callback then return end
                if multi then
                    local list = {}
                    for k, on in pairs(val or {}) do if on then table.insert(list, k) end end
                    info.Callback(list)
                else
                    info.Callback(val)
                end
            end })
        local o = {}
        function o:Refresh(newValues) pcall(function() Options[id]:SetValues(newValues or {}) end) end
        function o:Select(x)
            pcall(function()
                if multi and type(x) == "table" then
                    local d = {} for _, k in ipairs(x) do d[k] = true end
                    Options[id]:SetValue(d)
                else
                    Options[id]:SetValue(x)
                end
            end)
        end
        o.Set, o.SetValue = o.Select, o.Select
        return setmetatable(o, { __index = function(_, k) if k == "Value" then return Options[id].Value end return function() end end })
    end
    function E:Input(info)
        if info.Locked == true or ZR_VEX_SKIP[ZR_text(info)] then return ZR_noopObj() end
        local id = ZR_id(info.Flag or ("i_" .. ZR_text(info)))
        getBox():AddInput(id, { Text = ZR_text(info), Tooltip = ZR_tip(info), Default = tostring(info.Value or ""), Placeholder = info.Placeholder or "",
            Numeric = false, Finished = true, ClearTextOnFocus = false, Callback = function(x) if info.Callback then info.Callback(x) end end })
        local o = {}
        function o:Set(x) Options[id]:SetValue(tostring(x)) end
        o.SetValue = o.Set
        return setmetatable(o, { __index = function() return function() end end })
    end
    function E:Keybind(info)
        if info.Locked == true or ZR_VEX_SKIP[ZR_text(info)] then return ZR_noopObj() end
        local id = ZR_id(info.Flag or ("k_" .. ZR_text(info)))
        local box = getBox()
        box:AddLabel(ZR_text(info)):AddKeyPicker(id, { Default = tostring(info.Value or "None"), Text = ZR_text(info), Mode = "Toggle", NoUI = true,
            ChangedCallback = function(new)
                if not info.Callback then return end
                local name = typeof(new) == "EnumItem" and new.Name or tostring(new)
                info.Callback(name)
            end })
        return setmetatable({}, { __index = function() return function() end end })
    end
    function E:Colorpicker(info)
        if info.Locked == true or ZR_VEX_SKIP[ZR_text(info)] then return ZR_noopObj() end
        local id = ZR_id(info.Flag or ("c_" .. ZR_text(info)))
        getBox():AddLabel(ZR_text(info)):AddColorPicker(id, { Default = info.Default or Color3.new(1, 1, 1), Title = ZR_text(info),
            Transparency = info.Transparency, Callback = function(c)
                if info.Callback then info.Callback(c, Options[id] and Options[id].Transparency or 0) end
            end })
        return setmetatable({}, { __index = function() return function() end end })
    end
    function E:Paragraph(info)
        local box = getBox()
        local t, d = ZR_text(info), ZR_tip(info)
        local lbl = box:AddLabel((t ~= "" and ("<b>" .. t .. "</b>") or "") .. (d and ((t ~= "" and "\n" or "") .. d) or ""), true)
        if type(info.Buttons) == "table" then
            for _, b in ipairs(info.Buttons) do box:AddButton({ Text = b.Title or "Button", Func = function() if b.Callback then b.Callback() end end }) end
        end
        local o = {}
        function o:SetTitle(s) t = s pcall(function() lbl:SetText("<b>" .. s .. "</b>" .. (d and ("\n" .. d) or "")) end) end
        function o:SetDesc(s) d = s pcall(function() lbl:SetText((t ~= "" and ("<b>" .. t .. "</b>\n") or "") .. s) end) end
        return setmetatable(o, { __index = function() return function() end end })
    end
    function E:Code(info) return E.Paragraph(self, { Title = info.Title, Desc = info.Code }) end
    function E:Divider() pcall(function() getBox():AddDivider() end) return ZR_noopObj() end
    function E:Space() return ZR_noopObj() end
    return E
end

local function ZR_MakeTab(obsTab, opts)
    local tab = { _count = 0 }
    local defaultBox
    local function nextSide()
        tab._count += 1
        return tab._count % 2 == 1
    end
    local function newBox(title, icon)
        if nextSide() then return obsTab:AddLeftGroupbox(title, icon) end
        return obsTab:AddRightGroupbox(title, icon)
    end
    local function sectionFrom(box)
        local S = ZR_Elements(type(box) == "function" and box or function() return box end, opts)
        function S:Section(info) return S end
        function S:Group() return S end
        return S
    end
    tab._newBox = newBox
    function tab:Section(info)
        info = info or {}
        if info.Locked == true or ZR_VEX_SKIP_SECTIONS[ZR_text(info)] then return ZR_noopObj() end
        -- the box is only made when something is put in it, so a section with only premium items doesn't show up empty
        local box
        return sectionFrom(function()
            if not box then box = newBox(ZR_text(info) ~= "" and ZR_text(info) or "Section", info.Icon) end
            return box
        end)
    end
    function tab:MultiSection(info)
        info = info or {}
        local M = {}
        local tabbox
        function M:Tab(t)
            if not tabbox then
                tabbox = nextSide() and obsTab:AddLeftTabbox(ZR_text(info)) or obsTab:AddRightTabbox(ZR_text(info))
            end
            return sectionFrom(tabbox:AddTab(ZR_text(t)))
        end
        function M:Section(s) return tab:Section(s) end
        return M
    end
    function tab:Group() return tab end
    -- elements placed straight on the tab go into one box
    local direct = ZR_Elements(function()
        if not defaultBox then defaultBox = newBox("Main", "box") end
        return defaultBox
    end, opts)
    return setmetatable(tab, { __index = function(_, k)
        if direct[k] then return function(_, ...) return direct[k](direct, ...) end end
        return function() return ZR_noopObj() end
    end })
end

local WindUI = setmetatable({}, { __index = function() return function() return ZR_noopObj() end end })
function WindUI:Notify(info)
    info = info or {}
    pcall(function()
        Library:Notify({ Title = tostring(info.Title or "ZRHUB"), Description = tostring(info.Content or info.Desc or ""), Time = tonumber(info.Duration) or 3 })
    end)
end

        

WindUI:AddTheme({ Name = "Dark",     Accent = "#18181b", Dialog = "#18181b", Outline = "#FFFFFF", Text = "#FFFFFF", Placeholder = "#999999", Background = "#0e0e10", Button = "#52525b", Icon = "#a1a1aa",})
WindUI:AddTheme({ Name = "Light",    Accent = "#f4f4f5", Dialog = "#f4f4f5", Outline = "#000000", Text = "#000000", Placeholder = "#666666", Background = "#ffffff", Button = "#e4e4e7", Icon = "#52525b",})
WindUI:AddTheme({ Name = "Gray",     Accent = "#374151", Dialog = "#374151", Outline = "#d1d5db", Text = "#f9fafb", Placeholder = "#9ca3af", Background = "#1f2937", Button = "#4b5563", Icon = "#d1d5db",})
WindUI:AddTheme({ Name = "Blue",     Accent = "#1e40af", Dialog = "#1e3a8a", Outline = "#93c5fd", Text = "#f0f9ff", Placeholder = "#60a5fa", Background = "#1e293b", Button = "#3b82f6", Icon = "#93c5fd",})
WindUI:AddTheme({ Name = "Green",    Accent = "#059669", Dialog = "#047857", Outline = "#6ee7b7", Text = "#ecfdf5", Placeholder = "#34d399", Background = "#064e3b", Button = "#10b981", Icon = "#6ee7b7",})
WindUI:AddTheme({ Name = "Purple",   Accent = "#a855f7", Dialog = "#1e1b4b", Outline = "#4c1d95", Text = "#f5f3ff", Placeholder = "#7c3aed", Background = "#0f172a", Button = "#6d28d9", Icon = "#d8b4fe",})
WindUI:AddTheme({ Name = "Premium",  Accent = "#a41be9", Dialog = "#6bff30", Outline = "#ecbf0a", Text = "#ffffff", Placeholder = "#30ff6a", Background = "#0a0a0a", Button = "#a20feb", Icon = "#30ff6a",})
WindUI:AddTheme({ Name = "Sunset",   Accent = "#ff6b35", Dialog = "#f7931e", Outline = "#ffa630", Text = "#ffffff", Placeholder = "#ffb84d", Background = "#1a0f0a", Button = "#ff8c42", Icon = "#ffa630",})
WindUI:AddTheme({ Name = "Cyberpunk",Accent = "#00ff88", Dialog = "#1a1a2e", Outline = "#ff006e", Text = "#00ff88", Placeholder = "#00d4ff", Background = "#0f0f1e", Button = "#ff006e", Icon = "#00d4ff",})
WindUI:AddTheme({ Name = "Retro",    Accent = "#ff1654", Dialog = "#2a2a3e", Outline = "#ffd60a", Text = "#fffacd", Placeholder = "#ffa500", Background = "#1a1a2e", Button = "#ff006e", Icon = "#ffd60a",})
WindUI:AddTheme({ Name = "Ocean",    Accent = "#0369a1", Dialog = "#082f49", Outline = "#7dd3fc", Text = "#e0f2fe", Placeholder = "#38bdf8", Background = "#0c2d42", Button = "#0284c7", Icon = "#38bdf8",})
WindUI:AddTheme({ Name = "Forest",   Accent = "#15803d", Dialog = "#1b4332", Outline = "#84cc16", Text = "#f0fdf4", Placeholder = "#4ade80", Background = "#0b3d1f", Button = "#22c55e", Icon = "#84cc16",})
WindUI:AddTheme({ Name = "Desert",   Accent = "#d97706", Dialog = "#78350f", Outline = "#fcd34d", Text = "#fffbeb", Placeholder = "#fbbf24", Background = "#451a03", Button = "#f59e0b", Icon = "#fcd34d",})
WindUI:AddTheme({ Name = "Candy",    Accent = "#ec4899", Dialog = "#831843", Outline = "#f472b6", Text = "#fce7f3", Placeholder = "#f472b6", Background = "#500724", Button = "#db2777", Icon = "#fbcfe8",})
WindUI:AddTheme({ Name = "Gold",     Accent = "#ca8a04", Dialog = "#422006", Outline = "#fde047", Text = "#fefce8", Placeholder = "#facc15", Background = "#1c1502", Button = "#eab308", Icon = "#fde047",})
WindUI:AddTheme({ Name = "Coffee",   Accent = "#78350f", Dialog = "#2c1810", Outline = "#d97706", Text = "#fef3c7", Placeholder = "#b45309", Background = "#1c1006", Button = "#92400e", Icon = "#d97706",})
WindUI:AddTheme({ Name = "Neon",     Accent = "#d946ef", Dialog = "#1a0a1f", Outline = "#f0abfc", Text = "#fdf4ff", Placeholder = "#e879f9", Background = "#0d0410", Button = "#c026d3", Icon = "#f0abfc",})
WindUI:AddTheme({ Name = "Rose",     Accent = "#e11d48", Dialog = "#881337", Outline = "#fb7185", Text = "#fff1f2", Placeholder = "#fda4af", Background = "#4c0519", Button = "#e11d48", Icon = "#fb7185",})
WindUI:AddTheme({ Name = "Rainbow",  Accent = "#ff0080", Dialog = "#1a0033", Outline = "#00f0ff", Text = "#ffffff", Placeholder = "#ffea00", Background = "#0d001a", Button = "#8000ff", Icon = "#39ff14",})

WindUI:SetNotificationLower(true)


HttpService = game:GetService("HttpService")
Players = game:GetService("Players")
LocalPlayer = Players.LocalPlayer
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")
Workspace = game:GetService("Workspace")
Camera = Workspace.CurrentCamera
StarterGui = game:GetService("StarterGui")
plr = LocalPlayer
character = plr.Character or plr.CharacterAdded:Wait()
humanoid = character:WaitForChild("Humanoid")
humanoidRootPart = character:WaitForChild("HumanoidRootPart")


PremiumStatus = (_G.VexonHub and _G.VexonHub.Whitelist and _G.VexonHub.Whitelist.status) or false
LockedStatus = not PremiumStatus


themes = {"Purple", "Dark", "Light", "Gray", "Blue", "Green", "Premium", "Sunset", "Cyberpunk", "Retro", "Ocean", "Forest", "Desert", "Candy", "Gold", "Coffee", "Neon", "Rose", "Rainbow"}
currentThemeIndex = 1

if not getgenv().TransparencyEnabled then
    getgenv().TransparencyEnabled = false
end
function LoadVexonHub()
    Window = Library:CreateWindow({
        Title = "ZRHUB",
        Footer = "The Strongest Battlegrounds",
        Icon = "rbxthumb://type=Asset&id=129949624640047&w=150&h=150",
        NotifySide = "Right",
        ShowCustomCursor = false,
        Center = true,
        AutoShow = true,
        CornerRadius = 6,
    })

    Tabs = {}
    Tabs.Home = Window:AddTab("Home", "house")
    -- Character takes the place of the old Main tab
    Tabs.Main = ZR_MakeTab(Window:AddTab("Character", "person-standing"))

    -- 3rd: ESP, 4th: Dash, then Tech (from KittyWare)
    Tabs.ESP = ZR_MakeTab(Window:AddTab("ESP", "atom"), { noKeys = true })
    Tabs.Dash = ZR_MakeTab(Window:AddTab("Dash", "wind"))
    -- Side Dash Assist is the first box in Dash
    ZR_KW_Boxes["Side Dash Assist"] = Tabs.Dash._newBox("Side Dash Assist", "move-horizontal")
    Tabs.Tech = ZR_MakeTab(Window:AddTab("Tech", "wrench"))

    local tabList = {
        { key = "Bring",    title = "Bring",         icon = "arrow-down-to-line", func = BringTab     },
        { key = "Lag",      title = "Lag-Ping",      icon = "leaf",               func = LagTab       },
        { key = "Disguise", title = "Disguise",      icon = "venetian-mask",      func = DisguiseTab  },
        { key = "Place",    title = "Teleport",      icon = "map",                func = TeleportTab  },
        { key = "Fling",    title = "Fling",         icon = "user",               func = FlingTab     },
        { key = "AntiBan",  title = "Anti Ban",      icon = "shield",             func = AntiBanTab   },
        { key = "Tools",    title = "Tools",         icon = "pencil",             func = ToolsTab     },
        { key = "Block",    title = "Defence",       icon = "shield-half",        func = BlockTab     },
        { key = "Emote",    title = "Limited Emote", icon = "party-popper",       func = EmoteTab     },
    }
    for _, t in ipairs(tabList) do
        Tabs[t.key] = ZR_MakeTab(Window:AddTab(t.title, t.icon))
    end
    table.insert(tabList, 1, { key = "ESP", title = "ESP", func = EspTab })

    -- VexonHub's own Tech tab is gone: only its dash parts are kept, in the Dash tab
    local DASH_SCRIPTS = { ["Oreo Dash Script"] = true, ["Tornado Dash Script"] = true }
    local function noop() return setmetatable({}, { __index = function() return function() return noop() end end }) end
    Tabs.VexTech = setmetatable({}, { __index = function(_, k)
        if k == "Section" then
            return function(_, info)
                local title = info and info.Title or ""
                if title == "Tech Scripts" then
                    local real
                    local function box() real = real or Tabs.Dash:Section({ Title = "Dash Scripts", Icon = "scroll" }) return real end
                    return setmetatable({}, { __index = function(_, m)
                        if m == "Button" then
                            return function(_, b) if DASH_SCRIPTS[b.Title] then return box():Button(b) end return noop() end
                        end
                        return function() return noop() end
                    end })
                elseif title == "Supa Tech" or (title:find("Hook Dash") and not title:find("On%-Screen")) then
                    return Tabs.Dash:Section(info)
                end
                return noop()
            end
        elseif k == "MultiSection" then
            return function(_, info)
                if info and info.Title == "Hook Dash" then return Tabs.Dash:MultiSection(info) end
                return noop()
            end
        end
        return function() return noop() end
    end })
    table.insert(tabList, { key = "VexTech", title = "Dash (VexonHub parts)", func = TechTab })

    Tabs.Settings = Window:AddTab("Settings", "settings")
    Tabs.Credits = Window:AddTab("Credits", "user")

	-- ===================== ZRHUB Home =====================
	pcall(function()
		local Stats = game:GetService("Stats")
		local lp = game:GetService("Players").LocalPlayer
		local me = Tabs.Home:AddLeftGroupbox("ZRHUB", "user-round")
		local avatar = Instance.new("ImageLabel")
		avatar.BackgroundTransparency = 1
		avatar.Size = UDim2.new(1.4, 0, 1.4, 0)
		avatar.Position = UDim2.new(-0.2, 0, -0.2, 0)
		avatar.ScaleType = Enum.ScaleType.Fit
		avatar.Image = "rbxthumb://type=AvatarThumbnail&id=" .. tostring(lp.UserId) .. "&w=420&h=420"
		local pass
		pcall(function() pass = me:AddUIPassthrough("ZR_HomeAvatar", { Instance = avatar, Height = 225 }) end)
		task.spawn(function()
			task.wait(0.1)
			local parent = avatar.Parent
			if parent and pass then
				local function fit()
					local x = parent.AbsoluteSize.X
					if x > 0 then pcall(function() pass:SetHeight(math.clamp(x, 180, 270)) end) end
				end
				fit()
				parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
			end
		end)
		local statsBox = Tabs.Home:AddRightGroupbox("Statistics", "blinds")
		local lTime = statsBox:AddLabel("Current time: <b>--:--</b>")
		local lFps = statsBox:AddLabel("FPS: <b>--</b>")
		local lPing = statsBox:AddLabel("Ping: <b>-- ms</b>")
		statsBox:AddDivider()
		local lPlayers = statsBox:AddLabel("Players in server: <b>--</b>")
		local lElapsed = statsBox:AddLabel("Elapsed time: <b>0 seconds</b>")
		local started, frames = tick(), 0
		local fc = game:GetService("RunService").RenderStepped:Connect(function() frames += 1 end)
		task.spawn(function()
			while not Library.Unloaded do
				task.wait(1)
				local fps = frames
				frames = 0
				pcall(function() lTime:SetText(string.format("Current time: <b>%s</b>", os.date("%H:%M"))) end)
				pcall(function() lFps:SetText("FPS: <b>" .. fps .. "</b>") end)
				pcall(function() lPing:SetText("Ping: <b>" .. math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) .. " ms</b>") end)
				pcall(function() lPlayers:SetText("Players in server: <b>" .. #game:GetService("Players"):GetPlayers() .. " / " .. game:GetService("Players").MaxPlayers .. "</b>") end)
				pcall(function() lElapsed:SetText("Elapsed time: <b>" .. math.floor(tick() - started) .. " seconds</b>") end)
			end
			fc:Disconnect()
		end)
	end)


    -- build every tab (each one fills itself in)
    task.spawn(MainTab)
    -- KittyWare parts: No Stun & More (Character), the dash boxes (Dash) and Tech
    task.spawn(function()
        local ok, err = pcall(ZR_RunKittyWare)
        if not ok then warn("[ZRHUB] KittyWare parts: " .. tostring(err)) end
    end)
    for _, t in ipairs(tabList) do
        task.spawn(function()
            local ok, err = pcall(t.func)
            if not ok then warn("[ZRHUB] " .. t.title .. " tab: " .. tostring(err)) end
        end)
    end

    -- Settings
    do
        local MenuBox = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")
        MenuBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
        MenuBox:AddButton({ Text = "Unload", Func = function() Library:Unload() end })
        Library.ToggleKeybind = Options.MenuKeybind

        local mb = Tabs.Settings:AddRightGroupbox("On-Screen Buttons", "smartphone")
        mb:AddLabel("Round buttons for M1 Reset and True DownSlam (turn them on in the Tech tab).", true)
        mb:AddSlider("ZR_MBSize", { Text = "Button Size", Default = ZR_MB.Size, Min = 40, Max = 110, Rounding = 0,
            Callback = function(v) ZR_MB.Size = v for _, b in ipairs(ZR_MB.list) do pcall(b.refresh) end end })
        mb:AddToggle("ZR_MBLock", { Text = "Lock Buttons In Place", Default = false, Callback = function(v) ZR_MB.Locked = v end })
        mb:AddToggle("ZR_MBHide", { Text = "Hide All Buttons", Default = false,
            Callback = function(v) ZR_MB.Hidden = v for _, b in ipairs(ZR_MB.list) do pcall(b.refresh) end end })
        pcall(function()
            ThemeManager:SetLibrary(Library)
            SaveManager:SetLibrary(Library)
            SaveManager:IgnoreThemeSettings()
            SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
            ThemeManager:SetFolder("ZRHUB")
            SaveManager:SetFolder("ZRHUB/TSB_Vexon")
            SaveManager:BuildConfigSection(Tabs.Settings)
            ThemeManager:ApplyToTab(Tabs.Settings)
            ThemeManager:ApplyTheme("Jester")
        end)
    end

    -- Credits
    do
        local CreditsBox = Tabs.Credits:AddLeftGroupbox("Credits", "user")
        CreditsBox:AddLabel("Made by tung zo1os", true)
        CreditsBox:AddButton({
            Text = "Copy Discord Link",
            Func = function()
                pcall(setclipboard, "https://discord.gg/TCuMcKy9j4")
                Library:Notify({ Title = "Copied!", Description = "Discord link copied.", Time = 3 })
            end,
        })
    end
    pcall(function() Tabs.Home:Show() end)
end


task.spawn(function()
	function createCirclePart(radius, thickness, position, transparency)
	    local part = Instance.new("Part")
	    part.Shape = Enum.PartType.Cylinder
	    part.Size = Vector3.new(thickness, radius * 2, radius * 2)
	    part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	    part.Anchored = true
	    part.Transparency = transparency
	    part.CanCollide = true
	    part.CastShadow = false
	    part.Color = Color3.new(0, 0, 0)
	    part.Parent = game.Workspace
	    return part
	end
	
	createCirclePart(100000, 0.5, Vector3.new(0, -500, 0), 0.5)
	createCirclePart(150, 0.5, Vector3.new(-68, 0, 20354), 0.5)
	createCirclePart(25, 1, Vector3.new(150, 500, 30), 0.5)
	createCirclePart(40, 0.5, Vector3.new(150, 700, 30), 0.5)
	createCirclePart(25, 1, Vector3.new(0, -2, 0), 0.5)
	createCirclePart(100000, 1, Vector3.new(30000000, 29999995, 30000000), 1)
	createCirclePart(50, 1, Vector3.new(1063, 129, 23006), 0.5)
	createCirclePart(25, 1, Vector3.new(0 ,900000000000 ,0), 0)
	createCirclePart(7, 0.5, Vector3.new(1000, -500, 1000), 0.7)
	createCirclePart(25, 1, Vector3.new(38.473, 87795.758, 32.568), 0.5)
end)






-- ================ INFO0 TAB0 ================ --
function MainTab()
    task.spawn(function()
	    do
	        local Players = game:GetService("Players")
	        local RunService = game:GetService("RunService")
	        local VirtualInputManager = game:GetService("VirtualInputManager")
	        local UserInputService = game:GetService("UserInputService")
	        local ReplicatedStorage = game:GetService("ReplicatedStorage")
	        local PhysicsService = game:GetService("PhysicsService")
	        local Debris = game:GetService("Debris")
	        local TeleportService = game:GetService("TeleportService")
	        local StarterGui = game:GetService("StarterGui")
	        local Workspace = game.Workspace
	        local LocalPlayer = Players.LocalPlayer
	
	        local teleportPosition = Vector3.new(150, -495, 30)
	        local autoVoidEnabled = false
	        local isAnimationPlaying = false
	        local tpBackEnabled = false
	        local autoWhirlwindEnabled = false
	        local autoWallComboEnabled = false
	        local antiInvisibilityEnabled = false
	        local espDeathCounterEnabled = false
	        local espUltBarEnabled = false
	        local espEveryoneEnabled = false
	        local speedEnabled = false
	        local fakeDownslamEnabled = false
	        local speedValue = 9
	        local jumpValue = 200
	        local wallComboConnection = nil
	        local animConnection = nil
	        local antiAfkConnection = nil
	        local originalCFrame = nil
	        local flaggedAntiInvisibility = {}
	        local espObjects = {}
	        local whirlwindDunkAnimationId = "rbxassetid://12296113986"
	
	        local Connections = {}
	        local CharacterConnections = {}
	        local Settings = {}
        end

        local antiInvisibilityAnimIds = {
            ["136370737633649"] = true,
            ["18182425133"] = true,
            ["18236605028"] = true,
        }

        local roastMessages = {
            "Pathetic", "Nice try, loser", "Git gud", "You're a noob", "Did you even try?",
            "Keep dying, it's amusing", "Too easy", "Better luck next time", "That was embarrassing",
            "You're just feeding my kills", "Can't handle the pressure?", "You call that playing?",
            "LOL, what a scrub", "Go cry to your mommy", "Just uninstall.", "I'm not even trying.",
            "Get rekt, scrub", "You're a joke", "Just stop trying.", "Noob alert", "Stay in the kiddie pool",
            "Did someone forget their skills?", "Do you need a tutorial?", "You make this too easy.",
            "You're not even worth my time.", "I've seen toddlers play better.", "You're a respawn machine",
            "You're like a training dummy.", "Did you pay to be this bad?", "Even the NPCs play better than you.",
            "You must be allergic to victory.", "Your gameplay is a tutorial on how not to play.",
            "I bet you're proud of that death streak.", "You're the MVP of feeding kills.",
            "You're like a pinata... full of free kills.", "You're like a legend... in dying.",
            "Do you think dying is a tactic?", "What The Sigma.", "Ez Kill LOL", "hehe cry more",
        }

        local upperVariantEnabled = false
        local autoUppercutEnabled = false
        local flySpeed = 50
        local flying = false
        local flyCharacterAddedConnection = nil

        local teleportDownDistance = 20
        local teleportUpDistance = 20
        local teleportForwardDistance = 20
        local teleportBackDistance = 20
        local teleportLeftDistance = 20
        local teleportRightDistance = 20

        local onAnimationPlayedAutoVoid = function() end

        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        local function updateCharacter(newChar)
            character = newChar
            humanoid = character:WaitForChild("Humanoid")
            animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                animator.AnimationPlayed:Connect(onAnimationPlayedAutoVoid)
            end
        end

        LocalPlayer.CharacterAdded:Connect(updateCharacter)

        workspace.FallenPartsDestroyHeight = -math.huge

        pcall(function()
            PhysicsService:CreateCollisionGroup(CollisionGroupName)
            PhysicsService:CollisionGroupSetCollidable(CollisionGroupName, "Default", false)
        end)



        local OPsection = Tabs.Main:Section({Opened = true, Box = true, BoxBorder = true, Title = "Godmode & Invisible", Icon = "ghost"})


        local heartBeatConnection = nil
        OPsection:Toggle({
            Title = "Semi Godmode",
            Flag = "tsbsemigodmode",
            Desc = "Makes you little bit in underground so others cant hit you with mini moves like M1",
            Value = false,
            Callback = function(state)
                if state then
                    if heartBeatConnection then heartBeatConnection:Disconnect() end
                    heartBeatConnection = RunService.Heartbeat:Connect(MV_CFF(function() 

                        if humanoidRootPart and humanoidRootPart.Parent then
                            local currentCFrame = humanoidRootPart.CFrame
                            humanoidRootPart.CFrame = currentCFrame * CFrame.new(0, -5, 0)
                            RunService.RenderStepped:Wait()
                            humanoidRootPart.CFrame = currentCFrame
                            wait(0.1)
                        end
                    end))
                else
                    if heartBeatConnection then
                        heartBeatConnection:Disconnect()
                        heartBeatConnection = nil
                    end
                end
            end,
        })

        OPsection:Toggle({
            Title = "No Dash Cool Down",
            Flag = "tsbnodashcd",
            Value = false,
            Callback = function(state)
                workspace:SetAttribute("EffectAffects", state and 1 or 0)
                workspace:SetAttribute("NoDashCooldown", state)
            end,
        })

        OPsection:Divider()

        local PlayersService = Players
        local RunServiceGame = RunService
        local LocalPlayerGame = LocalPlayer
        local invisAnimId = "rbxassetid://71181015443030"
        local invisTimePosition = 13.45
        local invisSpeed = 0
        local invisTrack = nil
        local isInvisOn = false
        local currentCharacterInvis = nil
        local currentHumanoidInvis = nil
        local currentAnimatorInvis = nil
        local invisHeartbeatConnection = nil
        local invisRenderSteppedConnection = nil


        local r6BodyParts = {
            ["Head"] = true,
            ["Torso"] = true,
            ["Left Arm"] = true,
            ["Right Arm"] = true,
            ["Left Leg"] = true,
            ["Right Leg"] = true,
        }

        local function setBodyTransparency(transparency)
            if not currentCharacterInvis then return end
            for _, part in ipairs(currentCharacterInvis:GetChildren()) do
                if part:IsA("BasePart") and r6BodyParts[part.Name] then
                    part.Transparency = transparency
                end
            end
        end

        local function stopInvisLoops()
            if invisHeartbeatConnection then invisHeartbeatConnection:Disconnect() invisHeartbeatConnection = nil end
            if invisRenderSteppedConnection then invisRenderSteppedConnection:Disconnect() invisRenderSteppedConnection = nil end
            if invisTrack then invisTrack:Stop() invisTrack = nil end
        end

        local function startInvisibility()
            stopInvisLoops()
            if not currentCharacterInvis or not currentAnimatorInvis then return end
            invisHeartbeatConnection = RunServiceGame.Heartbeat:Connect(MV_CFF(function() 

                if isInvisOn then
                    if not (invisTrack and invisTrack.IsPlaying) then
                        local anim = Instance.new("Animation")
                        anim.AnimationId = invisAnimId
                        local success, track = pcall(function() return currentAnimatorInvis:LoadAnimation(anim) end)
                        if success then
                            invisTrack = track
                            invisTrack:Play()
                            invisTrack.TimePosition = invisTimePosition
                            invisTrack:AdjustSpeed(invisSpeed)
                        end
                    end
                end
            end))
            invisRenderSteppedConnection = RunServiceGame.RenderStepped:Connect(MV_CFF(function() 

                if isInvisOn and invisTrack and invisTrack.IsPlaying then
                    invisTrack:Stop()
                    invisTrack = nil
                end
            end))
            setBodyTransparency(0.5)
        end

        local function onCharacterAddedInvis(newChar)
            currentCharacterInvis = newChar
            currentHumanoidInvis = currentCharacterInvis:WaitForChild("Humanoid")
            currentAnimatorInvis = currentHumanoidInvis:WaitForChild("Animator")
            if isInvisOn then
                task.wait(0.5)
                startInvisibility()
            end
        end

        LocalPlayerGame.CharacterAdded:Connect(onCharacterAddedInvis)

        local mainInvisEnabled = false
        local extraInvisEnabled = false

        local function updateExtraInvisibility()
            if Connections[60] then
                Connections[60]:Disconnect()
                Connections[60] = nil
            end
            if CharacterConnections[60] then
                CharacterConnections[60]:Disconnect()
                CharacterConnections[60] = nil
            end
            local characterNow = LocalPlayer.Character
            local charHumanoid = characterNow and characterNow:FindFirstChild("Humanoid")
            if mainInvisEnabled and extraInvisEnabled then
                Connections[60] = RunService.Heartbeat:Connect(MV_CFF(function() 

                    if not FluInvis then
                        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            local origCFrame = rootPart.CFrame
                            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, 0, math.rad(180))
                            RunService.RenderStepped:Wait()
                            rootPart.CFrame = origCFrame
                        end
                    end
                end))
                CharacterConnections[60] = RunService.PostSimulation:Connect(MV_CFF(function() 

                    if not (FluInvis or FluHideInvis) then
                        local currentHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                        if currentHumanoid then
                            currentHumanoid.CameraOffset = Vector3.new(0, -3.3, 0)
                        end
                    end
                end))
            else
                if charHumanoid then
                    charHumanoid.CameraOffset = Vector3.new(0, 0, 0)
                end
            end
        end

        OPsection:Toggle({
            Title = "Invisibility",
            Desc = "It elevates the character slightly and prevents others from seeing it. If you want to become completely invisible, it is recommended to use the toggle at the bottom.",
            Flag = "tsbmaininvis",
            Value = false,
            Callback = function(state)
                isInvisOn = state
                mainInvisEnabled = state
                if isInvisOn then
                    currentCharacterInvis = LocalPlayerGame.Character
                    if currentCharacterInvis then
                        currentHumanoidInvis = currentCharacterInvis:FindFirstChild("Humanoid")
                        currentAnimatorInvis = currentHumanoidInvis and currentHumanoidInvis:FindFirstChildOfClass("Animator")
                        startInvisibility()
                    end
                else
                    stopInvisLoops()
                    setBodyTransparency(0)
                end
                updateExtraInvisibility()
            end,
        })

        OPsection:Toggle({
            Title = "Invisibility Character Hide",
            Desc = "Hides your character in groud with making your character upside down",
            Flag = "tsbmainextrainvis",
            Value = false,
            Callback = function(state)
                extraInvisEnabled = state
                updateExtraInvisibility()
            end,
        })

	
        local MovementSection = Tabs.Main:Section({Opened = true, Box = true, BoxBorder = true, Title = "Movement", Icon = "settings"})

        local function toggleWalkSpeed(state)
            speedEnabled = state
            getgenv().WalkspeedBypass = speedEnabled
            if state then
                task.spawn(function()
                    while getgenv().WalkspeedBypass and character and character.Parent do
                        local hum = character:FindFirstChildOfClass("Humanoid")
                        if hum and hum.MoveDirection.Magnitude > 0 then
                            character:TranslateBy(hum.MoveDirection * speedValue * RunService.Heartbeat:Wait() * 7)
                        else
                            task.wait()
                        end
                    end
		end)
	end
end

        MovementSection:Toggle({
            Title = "Speed (Keybind On/Off)",
            Flag = "tsbmainspeedtoggle",
            Value = false,
            Callback = toggleWalkSpeed,
        })

        MovementSection:Slider({
            Title = "Speed Boost Value",
            Flag = "tsbmainspeedslider",
            Value = { Min = 1, Max = 100, Default = 9 },
            Callback = function(value) speedValue = value end,
        })

        local speedKeybind = Enum.KeyCode.V
        MovementSection:Keybind({
            Title = "Speed Boost Keybind",
            Desc = "Press to set your Speed Boost key",
            Flag = "tsbmainspeedkeybind",
            Value = "V",
            Callback = function(v)
                local ok, result = pcall(function() return Enum.KeyCode[v] end)
                if ok and result then
                    speedKeybind = result
                end
            end,
        })

        UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
            if input.KeyCode == speedKeybind and not gameProcessedEvent then
                toggleWalkSpeed(not speedEnabled)
            end
        end)

        -- Jump Power (from ZRHUB Visuals): sets your jump power while on, puts the old one back when off
        local ZR_JP = { on = false, value = 100, saved = nil, savedUse = nil }
        game:GetService("RunService").Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if ZR_JP.on then
                if ZR_JP.saved == nil then ZR_JP.saved, ZR_JP.savedUse = hum.JumpPower, hum.UseJumpPower end
                hum.UseJumpPower = true
                hum.JumpPower = ZR_JP.value
            elseif ZR_JP.saved ~= nil then
                hum.JumpPower, hum.UseJumpPower = ZR_JP.saved, ZR_JP.savedUse
                ZR_JP.saved = nil
            end
        end)
        LocalPlayer.CharacterAdded:Connect(function() ZR_JP.saved = nil end)
        MovementSection:Toggle({
            Title = "Jump Power",
            Flag = "zrjumppower",
            Value = false,
            Callback = function(state) ZR_JP.on = state end,
        })
        MovementSection:Slider({
            Title = "Power",
            Flag = "zrjumppowervalue",
            Value = { Min = 50, Max = 1000, Default = 100 },
            Callback = function(v) ZR_JP.value = v end,
        })

        MovementSection:Toggle({
            Title = "No Stun Cframe Walk",
            Flag = "tsbnostuncframewalk",
            Value = false,
            Callback = function(Value)
                getgenv().AutoNoSlow = Value
                task.spawn(function()
                    local connection
                    connection = RunService.RenderStepped:Connect(MV_CFF(function() 

                        if getgenv().AutoNoSlow == true then
                            pcall(function()
                                LocalPlayer.Character.Humanoid.WalkSpeed = 25
                            end)
                        else
                            connection:Disconnect()
                        end
                    end))
                end)
            end,
        })

        local antiMovementSettings = {
            ["Anti-Stun"] = true,
            ["Anti-Ragdoll"] = true,
            ["Always Rotate"] = true,
        }

        MovementSection:Dropdown({
            Title = "Select Movement Modifications",
            Flag = "tsbmovementmoddropdown",
            Desc = "Choose which modification features to enable",
            Values = {"Anti-Stun", "Anti-Ragdoll", "Always Rotate"},
            Value = {"Anti-Stun", "Anti-Ragdoll", "Always Rotate"},
            Multi = true,
            Callback = function(selectedValues)
                antiMovementSettings = {
                    ["Anti-Stun"] = false,
                    ["Anti-Ragdoll"] = false,
                    ["Always Rotate"] = false,
                }
                for _, value in pairs(selectedValues) do
                    antiMovementSettings[value] = true
                end
            end,
        })

        MovementSection:Toggle({
            Title = "Enable Movement Modifications",
            Flag = "tsbmovementmodtoggle",
            Value = false,
            Callback = function(state)
                if Connections[9] then
                    Connections[9]:Disconnect()
                end
                if CharacterConnections[9] then
                    CharacterConnections[9]:Disconnect()
                end
                if state then
                    local function setupAntiStun()
                        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                        if not char:FindFirstChildOfClass("Humanoid") then
                            char:WaitForChild("Humanoid")
                        end
                        for _, child in pairs(char:GetChildren()) do
                            if child:IsA("Accessory") and not (child:FindFirstChild("Handle") or string.match(child.Name, "^#")) then
                                if child.Name ~= "Ragdoll" and child.Name ~= "NoRotate" and antiMovementSettings["Anti-Stun"] then
                                    Debris:AddItem(child, 0)
                                end
                                if child.Name == "Ragdoll" and antiMovementSettings["Anti-Ragdoll"] then
                                    Debris:AddItem(child, 0)
                                end
                                if child.Name == "NoRotate" and antiMovementSettings["Always Rotate"] then
                                    Debris:AddItem(child, 0)
                                end
                            end
                        end
                        Connections[9] = char.ChildAdded:Connect(function(child)
                            if child:IsA("Accessory") and not (child:FindFirstChild("Handle") or string.match(child.Name, "^#")) then
                                if child.Name ~= "Ragdoll" and child.Name ~= "NoRotate" and child.Name ~= "BeingGrabbed" and child.Name ~= "RootAnchor" and antiMovementSettings["Anti-Stun"] then
                                    Debris:AddItem(child, 0)
                                end
                                if child.Name == "Ragdoll" and antiMovementSettings["Anti-Ragdoll"] then
                                    Debris:AddItem(child, 0)
                                end
                                if child.Name == "NoRotate" and antiMovementSettings["Always Rotate"] then
                                    Debris:AddItem(child, 0)
                                end
                            end
                        end)
                    end
                    setupAntiStun()
                    CharacterConnections[9] = LocalPlayer.CharacterAdded:Connect(setupAntiStun)
                end
            end,
        })

        local CharacterSection = Tabs.Main:Section({Opened = true, Box = true, BoxBorder = true, Title = "Character", Icon = "box"})

        CharacterSection:Toggle({
            Title = "Auto upper variants",
            Desc = "Automatically makes the upper variants of the moves like Uppercut or Atomic samurai third move..",
            Value = false,
            Callback = function(state)
                upperVariantEnabled = state
                if state then
                    task.spawn(function()
                        while upperVariantEnabled do
                            LocalPlayer.Character:WaitForChild("Communicate"):FireServer({Goal = "KeyPress", Key = Enum.KeyCode.Space})
                            task.wait()
                        end
                    end)
                end
            end,
        })

        CharacterSection:Toggle({
            Title = "Auto Uppercut",
            Value = false,
            Callback = function(state)
                autoUppercutEnabled = state
                if state then
                    task.spawn(function()
                        while autoUppercutEnabled do
                            local char = LocalPlayer.Character
                            if char and char:FindFirstChild("M1ing") then
                                char:WaitForChild("Communicate"):FireServer({Goal = "KeyPress", Key = Enum.KeyCode.Space})
                            end
                            task.wait(0.02)
                        end
                    end)
                end
            end,
        })

        CharacterSection:Toggle({
            Title = "Fake Downslam",
            Flag = "tsbfakedownslam",
            Value = false,
            Callback = function(state)
                fakeDownslamEnabled = state
            end,
        })

        local function onStateChangedDownslam(oldState, newState)
            if fakeDownslamEnabled and newState == Enum.HumanoidStateType.Jumping then
                local animation = Instance.new("Animation")
                animation.AnimationId = "rbxassetid://10470104242"
                if humanoid then
                    local animationTrack = humanoid:LoadAnimation(animation)
                    task.wait(0.3)
                    animationTrack:Play()
                end
            end
        end

        humanoid.StateChanged:Connect(onStateChangedDownslam)

        CharacterSection:Toggle({
            Title = "Auto Safe Zone",
            Flag = "tsbautosafezone",
            Value = false,
            Callback = function(state)
                getgenv().AutoReturnSafeZone = state
                if state then
                    local teleported = false
                    task.spawn(function()
                        while getgenv().AutoReturnSafeZone do
                            if humanoid and humanoid.Health < 45 and not teleported then
                                humanoidRootPart.CFrame = CFrame.new(150, 705, 30)
                                teleported = true
                            elseif humanoid and humanoid.Health == 50 and teleported then
                                teleported = false
                            end
                            task.wait(0.15)
                        end
                    end)
                end
            end,
        })

        local fluDashAuraEnabled = false
        CharacterSection:Toggle({
            Title = "Spawn Fe Stones",
            Flag = "tsbspawnfestones",
            Value = false,
            Callback = function(enabled)
                fluDashAuraEnabled = enabled
                if enabled then
                    while fluDashAuraEnabled do
                        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                        char.Communicate:FireServer(unpack({{Dash = Enum.KeyCode.S, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}))
                        stopAnimations("10479335397")
                        for _, child in pairs(char:GetChildren()) do
                            if child:IsA("Accessory") and (not child:FindFirstChild("Handle") and child.Name == "Freeze") then
                                Debris:AddItem(child, 0)
                            end
                        end
                        task.wait(0.05)
                    end
                end
            end,
        })

        CharacterSection:Toggle({
            Title = "Upside Down",
            Flag = "tsbupsidedown",
            Desc = "Other players will see you upside down",
            Default = false,
            Callback = function(enabled)
                if Connections[6] then
                    Connections[6]:Disconnect()
                end
                if CharacterConnections[6] then
                    CharacterConnections[6]:Disconnect()
                end
                if enabled then
                    Connections[6] = RunService.Heartbeat:Connect(MV_CFF(function() 

                        if not FluInvis then
                            local rootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                            local origCFrame = rootPart.CFrame
                            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, 0, math.rad(180))
                            RunService.RenderStepped:Wait()
                            rootPart.CFrame = origCFrame
                        end
                    end))
                    CharacterConnections[6] = RunService.PostSimulation:Connect(MV_CFF(function() 

                        if not (FluInvis or FluHideInvis) then
                            humanoid.CameraOffset = Vector3.new(0, -3.3, 0)
                        end
                    end))
                end
            end,
        })
        
        local FlySection = Tabs.Main:Section({Opened = true, Box = true, BoxBorder = true, Title = 'Fly', Icon = 'utensils'})

        local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        local Controls = PlayerModule:GetControls()
        local flyLoadedAnims = {}
        local flyActiveAnimTrack = nil

        local function playFlyAnimation(hum, id, timePos, speed)
            if not hum then return end
            local animator = hum:FindFirstChildOfClass("Animator")
            if not animator then return end
            local animId = 'rbxassetid://' .. id
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Animation.AnimationId ~= animId then
                    track:Stop(0)
                end
            end
            if flyActiveAnimTrack and flyActiveAnimTrack.Animation.AnimationId == animId then
                return
            end
            if not flyLoadedAnims[animId] then
                local Anim = Instance.new('Animation')
                Anim.AnimationId = animId
                flyLoadedAnims[animId] = animator:LoadAnimation(Anim)
            end
            flyActiveAnimTrack = flyLoadedAnims[animId]
            flyActiveAnimTrack:Play(0.1)
            flyActiveAnimTrack.TimePosition = timePos
            flyActiveAnimTrack:AdjustSpeed(speed)
        end

        local function stopFlyAnim(char, hum)
            if flyActiveAnimTrack then
                flyActiveAnimTrack:Stop(0.1)
                flyActiveAnimTrack = nil
            end
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        track:Stop(0.1)
                    end
                end
            end
            if char and char:FindFirstChild("Animate") then
                char.Animate.Disabled = false
            end
        end

        local function startFly(char)
            local torso = char:FindFirstChild('Torso')
            local hum = char:FindFirstChildOfClass('Humanoid')
            if not torso or not hum then return end
            flyLoadedAnims = {}
            flyActiveAnimTrack = nil
            if char:FindFirstChild("Animate") then
                char.Animate.Disabled = true
            end
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:Stop(0)
                end
            end
            for _, v in pairs(torso:GetChildren()) do
                if v.Name == 'GeminiFlyMover' then
                    v:Destroy()
                end
            end
            local bg = Instance.new('BodyGyro', torso)
            bg.Name = 'GeminiFlyMover'
            bg.P = 20000
            bg.maxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.CFrame = torso.CFrame
            local bv = Instance.new('BodyVelocity', torso)
            bv.Name = 'GeminiFlyMover'
            bv.maxForce = Vector3.new(math.huge, math.huge, math.huge)
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if not flying or not char.Parent or hum:GetState() == Enum.HumanoidStateType.Dead then
                    connection:Disconnect()
                    pcall(function()
                        bg:Destroy()
                        bv:Destroy()
                        hum.PlatformStand = false
                        stopFlyAnim(char, hum)
                    end)
                    return
                end
                hum.PlatformStand = true
                local cam = workspace.CurrentCamera
                local moveVector = Controls:GetMoveVector()
                local moveDirection = (cam.CFrame.RightVector * moveVector.X + cam.CFrame.LookVector * -moveVector.Z)
                if moveDirection.Magnitude > 0 then
                    bv.Velocity = moveDirection.Unit * flySpeed
                else
                    bv.Velocity = Vector3.new(0, 0.1, 0)
                end
                local targetPitch = math.rad(-20) * -moveVector.Z
                local targetRoll = math.rad(15) * -moveVector.X
                local targetCFrame = cam.CFrame * CFrame.Angles(targetPitch, 0, targetRoll)
                bg.CFrame = bg.CFrame:Lerp(targetCFrame, 0.1)
                if moveVector.Magnitude > 0.1 then
                    if moveVector.Z < -0.1 then
                        playFlyAnimation(hum, 17124063826, 4.65, 0)
                    elseif moveVector.Z > 0.1 then
                        playFlyAnimation(hum, 17124067635, 4.11, 0)
                    elseif moveVector.X < -0.1 then
                        playFlyAnimation(hum, 17124105294, 3.55, 0)
                    elseif moveVector.X > 0.1 then
                        playFlyAnimation(hum, 17124112547, 4.81, 0)
                    end
                else
                    playFlyAnimation(hum, 17124061663, 4, 0)
                end
            end)
        end

        FlySection:Input({
            Title = 'Fly Speed',
            Placeholder = tostring(flySpeed),
            Flag = "flingflyspeedanim",
            Callback = function(text)
                local newSpeed = tonumber(text)
                if newSpeed and newSpeed > 0 then
                    flySpeed = newSpeed
                    pcall(function()
                        StarterGui:SetCore('SendNotification', {Title = 'ZRHUB Fly', Text = 'Speed set to: ' .. flySpeed, Duration = 2})
                    end)
                end
            end,
        })

        local FlyToggle = FlySection:Toggle({
            Title = 'Fly',
            Value = flying,
            Callback = function(toggleState)
                flying = toggleState
                if flying then
                    if LocalPlayer.Character then task.spawn(startFly, LocalPlayer.Character) end
                    flyCharacterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(char)
                        task.wait(0.5)
                        if flying then task.spawn(startFly, char) end
                    end)
                else
                    if flyCharacterAddedConnection then flyCharacterAddedConnection:Disconnect() end
                    if LocalPlayer.Character then
                        local char = LocalPlayer.Character
                        local torso = char:FindFirstChild("Torso")
                        if torso then
                            for _, v in pairs(torso:GetChildren()) do
                                if v.Name == 'GeminiFlyMover' then v:Destroy() end
                            end
                        end
                        stopFlyAnim(char, char:FindFirstChildOfClass('Humanoid'))
                    end
                end
            end,
        })

        local toggledFly = false
        FlySection:Keybind({
            Title = "Fly Keybind",
            Desc = "Keybind toggle",
            Flag = "flingflykeybind",
            Value = "",
            Callback = function()
                toggledFly = not toggledFly
                FlyToggle:Set(toggledFly)
            end,
        })

        local playerGui = LocalPlayer:WaitForChild("PlayerGui")

        local function createTeleportUI(name, buttonText)
            local mobileGui = Instance.new("ScreenGui")
            mobileGui.Name = "TeleportMobileUI" .. name
            mobileGui.ResetOnSpawn = false
            mobileGui.Enabled = false
            mobileGui.Parent = playerGui
            local btn = Instance.new("TextButton")
            btn.Name = "Teleport" .. name .. "Mobile"
            btn.Size = UDim2.new(0, 140, 0, 45)
            btn.Position = UDim2.new(0, 50, 0, 140)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 16
            btn.Text = buttonText
            btn.Parent = mobileGui
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 12)
            corner.Parent = btn
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(200, 200, 200)
            stroke.Thickness = 1
            stroke.Transparency = 0.5
            stroke.Parent = btn
            local handle = Instance.new("TextButton")
            handle.Name = "DragHandle"
            handle.Size = UDim2.new(0, 30, 1, 0)
            handle.Position = UDim2.new(0, 0, 0, 0)
            handle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            handle.TextColor3 = Color3.fromRGB(200, 200, 200)
            handle.Font = Enum.Font.GothamBold
            handle.TextSize = 16
            handle.Text = "#"
            handle.ZIndex = 2
            handle.Parent = btn
            local handleCorner = Instance.new("UICorner")
            handleCorner.CornerRadius = UDim.new(0, 12)
            handleCorner.Parent = handle
            local dragging = false
            local dragStart = nil
            local startPos = nil
            local function updateInput(input)
                if not dragging then return end
                local delta = input.Position - dragStart
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    startPos = btn.Position
                    local conn
                    conn = input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                            conn:Disconnect()
                        end
                    end)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateInput(input)
                end
            end)
            return mobileGui
        end

        local downGui = createTeleportUI("Down", "TP Down")
        local upGui = createTeleportUI("Up", "TP Up")
        local forwardGui = createTeleportUI("Forward", "TP Forward")
        local backGui = createTeleportUI("Back", "TP Back")
        local leftGui = createTeleportUI("Left", "TP Left")
        local rightGui = createTeleportUI("Right", "TP Right")

        local function teleportPlayer(direction, distance)
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            if direction == "down" then
                root.CFrame = root.CFrame + Vector3.new(0, -distance, 0)
            elseif direction == "up" then
                root.CFrame = root.CFrame + Vector3.new(0, distance, 0)
            elseif direction == "forward" then
                root.CFrame = root.CFrame + root.CFrame.LookVector * distance
            elseif direction == "back" then
                root.CFrame = root.CFrame - root.CFrame.LookVector * distance
            elseif direction == "left" then
                root.CFrame = root.CFrame - root.CFrame.RightVector * distance
            elseif direction == "right" then
                root.CFrame = root.CFrame + root.CFrame.RightVector * distance
            end
        end

        local multiSection = Tabs.Main:MultiSection({
            Title = "Teleports",
            Desc = "Up, Down, Left, Right, Forward, Back with UI + Keybinds",
            Icon = "rows-3",
            Opened = true,
            Box = true,
            BoxBorder = true,
        })

        local function createDirectionTab(direction, icon)
            local directionTab = multiSection:Tab({Title = direction:gsub("^%l", string.upper), Icon = icon})
            local distanceVar = teleportDownDistance
            if direction == "up" then distanceVar = teleportUpDistance
            elseif direction == "forward" then distanceVar = teleportForwardDistance
            elseif direction == "back" then distanceVar = teleportBackDistance
            elseif direction == "left" then distanceVar = teleportLeftDistance
            elseif direction == "right" then distanceVar = teleportRightDistance
            end

            directionTab:Button({
                Title = "Teleport " .. direction:gsub("^%l", string.upper),
                Locked = false,
                Callback = function()
                    teleportPlayer(direction, distanceVar)
                end,
            })

            directionTab:Slider({
                Title = "Teleport " .. direction:gsub("^%l", string.upper) .. " Distance",
                Flag = 'flingmaindistance' .. direction,
                Step = 1,
                Value = { Min = 1, Max = 100, Default = 20 },
                Callback = function(value)
                    if direction == "down" then teleportDownDistance = value
                    elseif direction == "up" then teleportUpDistance = value
                    elseif direction == "forward" then teleportForwardDistance = value
                    elseif direction == "back" then teleportBackDistance = value
                    elseif direction == "left" then teleportLeftDistance = value
                    elseif direction == "right" then teleportRightDistance = value
                    end
                end,
            })

            directionTab:Toggle({
                Title = "Teleport UI",
                Flag = 'flingmainteleportui' .. direction,
                Value = false,
                Callback = function(state)
                    if direction == "down" then downGui.Enabled = state
                    elseif direction == "up" then upGui.Enabled = state
                    elseif direction == "forward" then forwardGui.Enabled = state
                    elseif direction == "back" then backGui.Enabled = state
                    elseif direction == "left" then leftGui.Enabled = state
                    elseif direction == "right" then rightGui.Enabled = state
                    end
                end,
            })

            directionTab:Keybind({
                Title = "Teleport Keybind",
                Flag = 'flingmainkeybind' .. direction,
                Value = "",
                Callback = function(v)
                    teleportPlayer(direction, distanceVar)
                end,
            })
        end

        createDirectionTab("down", "arrow-down")
        createDirectionTab("up", "arrow-up")
        createDirectionTab("forward", "arrow-right")
        createDirectionTab("back", "arrow-left")
        createDirectionTab("left", "arrow-left")
        createDirectionTab("right", "arrow-right")

        downGui:WaitForChild("TeleportDownMobile").Activated:Connect(function() teleportPlayer("down", teleportDownDistance) end)
        upGui:WaitForChild("TeleportUpMobile").Activated:Connect(function() teleportPlayer("up", teleportUpDistance) end)
        forwardGui:WaitForChild("TeleportForwardMobile").Activated:Connect(function() teleportPlayer("forward", teleportForwardDistance) end)
        backGui:WaitForChild("TeleportBackMobile").Activated:Connect(function() teleportPlayer("back", teleportBackDistance) end)
        leftGui:WaitForChild("TeleportLeftMobile").Activated:Connect(function() teleportPlayer("left", teleportLeftDistance) end)
        rightGui:WaitForChild("TeleportRightMobile").Activated:Connect(function() teleportPlayer("right", teleportRightDistance) end)
    end)
end














-- ================ MISC0 TAB0 ================ --
function TechTab()
	task.spawn(function()
		TechScriptsSection = Tabs.VexTech:Section({Opened = true, Box = true, BoxBorder = true,Title = "Tech Scripts", Icon = "box"})
		
		TechScriptsSection:Button({Title = "M1 Reset Script", Locked = false, Callback = function()
		    getgenv().keybinds = {m1reset = Enum.KeyCode.R, emotedash = Enum.KeyCode.T, rotation = Enum.KeyCode.H}
		    loadstring(game:HttpGet("https://raw.githubusercontent.com/Slaphello/M1-Reset-And-Emote-Dash-TSB-OLD-/refs/heads/main/M1R%26ED%20TSB"))()
		end})
		
		TechScriptsSection:Button({Title = "Auto Kyoto Script", Locked = false, Callback = function()
		    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kietba/Kietba/refs/heads/main/Auto%20kyoto%20ma%20hoa"))()
		end})
		
		TechScriptsSection:Button({Title = "Loop Dash Script", Locked = false, Callback = function()
		    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kietba/Kietba/refs/heads/main/Loop%20Dash%20Rework%20Script%20Real"))()
		end})
		
		TechScriptsSection:Button({Title = "Oreo Dash Script", Locked = false, Callback = function()
		    loadstring("loadstring(game:HttpGet(\"https://raw.githubusercontent.com/Kietba/Kietba/refs/heads/main/Oreo%20Tech%20Script\"))()")()
		end})
		
		TechScriptsSection:Button({Title = "Tornado Dash Script", Locked = false, Callback = function()
		    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kietba/Kietba/refs/heads/main/Idk%20lolololol"))()
		end})
		
		TechScriptsSection:Button({Title = "Supa Dash Script", Locked = false, Callback = function()
		    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kietba/Kietba/refs/heads/main/Supa%20tech%20script"))()
		end})
		
		TechScriptsSection:Button({Title = "BackDash Script (MOBILE)", Locked = false, Callback = function()
		    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kietba/Kietba/refs/heads/main/BackDash%20Tech"))()
		end})
		
		TechScriptsSection:Button({Title = "Backdash Script (PC)", Locked = false, Callback = function()
		    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kietba/Kietba/refs/heads/main/BackDash%20For%20Pc"))()
		end})
		
		
		
		
		
		Players = game:GetService("Players")
		VirtualInputManager = game:GetService("VirtualInputManager")
		UIS = game:GetService("UserInputService")
		RunService = game:GetService("RunService")
		player = Players.LocalPlayer
		
		selectedNumber = 1
		isSpaceEnabled = false
		
		toolGroups = {
			{ "Flowing Water", "Lethal Whirlwind Stream", "Hunter's Grasp", "Prey's Peril" },
			{ "Doom Dive", "Crowd Buster", "Hammer Heel", "Binding Cloth" },
			{ "Machine Gun Blows", "Ignition Burst", "Blitz Shot", "Jet Dive" },
			{ "Flash Strike", "Whirlwind Kick", "Scatter", "Explosive Shuriken" },
			{ "Homerun", "Beatdown", "Grand Slam", "Foul Ball" },
			{ "Quick Slice", "Atmos Cleave", "Pinpoint Cut", "Split Second Counter" },
			{ "Crushing Pull", "Windstorm Fury", "Stone Coffin", "Expulsive Push" },
			{ "Bullet Barrage", "Vanishing Kick", "Whirlwind Drop", "Head First" },
			{ "Normal Punch", "Consecutive Punches", "Shove", "Uppercut" }
		}
		
		mobileGui = Instance.new("ScreenGui")
		mobileGui.Name = "BackDashMobileUI"
		mobileGui.ResetOnSpawn = false
		mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		parentGui = (player and player:FindFirstChild("PlayerGui")) or game:GetService("CoreGui")
		pcall(function() mobileGui.Parent = parentGui end)
		
		function triggerRemote(tool)
			args = {
				[1] = {
					["Tool"] = tool,
					["Goal"] = "Console Move"
				}
			}
			remote = player.Character and player.Character:FindFirstChild("Communicate")
			if remote then
				remote:FireServer(unpack(args))
			end
		end
		
		function doBackDash()
			if isSpaceEnabled then
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
				task.wait(0.05)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
			end
		
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.S, false, game)
		
			task.spawn(function()
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
				task.wait(0.05)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
			end)
		
			task.spawn(function()
				backpack = player:FindFirstChild("Backpack")
				if not backpack then return end
		
				for _, group in ipairs(toolGroups) do
					toolName = group[selectedNumber]
					tool = backpack:FindFirstChild(toolName)
					if tool then
						triggerRemote(tool)
						break
					end
				end
			end)
		
			task.delay(0.1, function()
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.S, false, game)
			end)
		end
		
		function createBackDashButton()
			local btn = Instance.new("TextButton")
		    btn.Name = "BackDashMobile"
		    btn.Size = UDim2.new(0, 140, 0, 45)
		    btn.Position = UDim2.new(0, 50, 0, 140)
		    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		    btn.Font = Enum.Font.GothamBold
		    btn.TextSize = 16
		    btn.Text = "  Back Dash"
		    btn.Parent = mobileGui
		
		    corner = Instance.new("UICorner")
		    corner.CornerRadius = UDim.new(0, 12)
		    corner.Parent = btn
		
		    stroke = Instance.new("UIStroke")
		    stroke.Color = Color3.fromRGB(200, 200, 200)
		    stroke.Thickness = 1
		    stroke.Transparency = 0.5
		    stroke.Parent = btn
		
		    handle = Instance.new("TextButton")
		    handle.Name = "DragHandle"
		    handle.Size = UDim2.new(0, 30, 1, 0)
		    handle.Position = UDim2.new(0, 0, 0, 0)
		    handle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		    handle.TextColor3 = Color3.fromRGB(200, 200, 200)
		    handle.Font = Enum.Font.GothamBold
		    handle.TextSize = 16
		    handle.Text = "#"
		    handle.ZIndex = 2
		    handle.Parent = btn
		
		    handleCorner = Instance.new("UICorner")
		    handleCorner.CornerRadius = UDim.new(0, 12)
		    handleCorner.Parent = handle
		
		    btn.MouseButton1Click:Connect(doBackDash)
		
		    handle.MouseButton1Click:Connect(function()
		    end)
		
		    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
		
		    handle.InputBegan:Connect(function(input)
		        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		            dragging = true
		            dragStart = input.Position
		            startPos = Vector2.new(btn.Position.X.Offset, btn.Position.Y.Offset)
		            input.Changed:Connect(function()
		                if input.UserInputState == Enum.UserInputState.End then
		                    dragging = false
		                end
		            end)
		        end
		    end)
		
		    handle.InputChanged:Connect(function(input)
		        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		            dragInput = input
		        end
		    end)
		
		    RunService.RenderStepped:Connect(MV_CFF(function() 

		        if dragging and dragInput and dragStart and startPos then
		            local delta = dragInput.Position - dragStart
		            btn.Position = UDim2.new(0, startPos.X + delta.X, 0, startPos.Y + delta.Y)
		        end
		    end))
		
		    return btn
		end
		
		BackDashSection = Tabs.VexTech:Section({Opened = true, Box = true, BoxBorder = true, 
		    Title = "Back Dash Macro",
		    Icon = "box" 
		    
		})
		
		BackDashSection:Dropdown({
		    Title = "Select Skill Slot",
		    Flag = "tsbbackdashslotdropdown",
		    Desc = "Choose which skill slot to use for Back Dash",
		    Values = {"1", "2", "3", "4"},
		    Value = "1",
		    Callback = function(value)
		        selectedNumber = tonumber(value)
		    end
		})
		
		BackDashSection:Toggle({
		    Title = "Auto Jump",
		    Flag = "tsbbackdashautojump",
		    Desc = "Automatically jump before dashing",
		    Value = false,
		    Callback = function(state)
		        isSpaceEnabled = state
		    end
		})
		
		backDashMobileBtnInstance = nil
		
		BackDashSection:Toggle({
		    Title = "Show Mobile UI",
		    Flag = "tsbbackdashuitoggle",
		    Desc = "Spawns a draggable Back Dash button on your screen",
		    Value = false,
		    Callback = function(state)
		        if state then
		            if not backDashMobileBtnInstance then
		                backDashMobileBtnInstance = createBackDashButton()
		            end
		        else
		            if backDashMobileBtnInstance then
		                backDashMobileBtnInstance:Destroy()
		                backDashMobileBtnInstance = nil
		            end
		        end
		    end
		})
		
		BackDashKey = nil
		
		BackDashSection:Keybind({
		    Title = "Back Dash Keybind",
		    Flag = "tsbbackdashkeybind",
		    Desc = "Press to use Back Dash macro",
		    Value = "0",
		    Callback = function(v)
		        pcall(function()
		            BackDashKey = Enum.KeyCode[v]
		        end)
		    end
		})
		
		UIS.InputBegan:Connect(function(input, gpe)
		    if gpe or UIS:GetFocusedTextBox() then return end
		    if input.UserInputType == Enum.UserInputType.Keyboard and BackDashKey then
		        if input.KeyCode == BackDashKey then
		            pcall(doBackDash)
		        end
		    end
		end)
		
		
		
		
		
		Players = game:GetService("Players")
		Plr = Players.LocalPlayer
		UIS = game:GetService("UserInputService")
		TweenService = game:GetService("TweenService")
		RunService = game:GetService("RunService")
		Workspace = game:GetService("Workspace")
		
		VIM = nil
		pcall(function() VIM = game:GetService("VirtualInputManager") end)
		VIM = VIM or rawget(_G, "VirtualInputManager") or (rawget(_G, "syn") and rawget(_G, "syn").virtual_input) or rawget(_G, "virtualinputmanager")
		
		camera = Workspace.CurrentCamera
		isPerformingAction = false
		animCache = {}
		
		TechStates = {
		    M1Enabled = false,
		    EmoteEnabled = false,
		    M1Key = Enum.KeyCode.G,
		    EmoteKey = Enum.KeyCode.T
		}
		
		mobileGui = Instance.new("ScreenGui")
		mobileGui.Name = "TechMobileUI"
		mobileGui.ResetOnSpawn = false
		mobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		
		parentGui = (Plr and Plr:FindFirstChild("PlayerGui")) or game:GetService("CoreGui")
		pcall(function() mobileGui.Parent = parentGui end)
		
		function createDraggableButton(name, text, position, callback)
		    local btn = Instance.new("TextButton")
		    btn.Name = name
		    btn.Size = UDim2.new(0, 140, 0, 45)
		    btn.Position = position
		    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		    btn.Font = Enum.Font.GothamBold
		    btn.TextSize = 16
		    btn.Text = "  " .. text
		    btn.Parent = mobileGui
		
		    local corner = Instance.new("UICorner")
		    corner.CornerRadius = UDim.new(0, 12)
		    corner.Parent = btn
		
		    local stroke = Instance.new("UIStroke")
		    stroke.Color = Color3.fromRGB(200, 200, 200)
		    stroke.Thickness = 1
		    stroke.Transparency = 0.5
		    stroke.Parent = btn
		
		    local handle = Instance.new("TextButton")
		    handle.Name = "DragHandle"
		    handle.Size = UDim2.new(0, 30, 1, 0)
		    handle.Position = UDim2.new(0, 0, 0, 0)
		    handle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		    handle.TextColor3 = Color3.fromRGB(200, 200, 200)
		    handle.Font = Enum.Font.GothamBold
		    handle.TextSize = 16
		    handle.Text = "#"
		    handle.ZIndex = 2
		    handle.Parent = btn
		
		    local handleCorner = Instance.new("UICorner")
		    handleCorner.CornerRadius = UDim.new(0, 12)
		    handleCorner.Parent = handle
		
		    btn.MouseButton1Click:Connect(callback)
		    handle.MouseButton1Click:Connect(function() end)
		
		    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
		
		    handle.InputBegan:Connect(function(input)
		        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		            dragging = true
		            dragStart = input.Position
		            startPos = Vector2.new(btn.Position.X.Offset, btn.Position.Y.Offset)
		            input.Changed:Connect(function()
		                if input.UserInputState == Enum.UserInputState.End then
		                    dragging = false
		                end
		            end)
		        end
		    end)
		
		    handle.InputChanged:Connect(function(input)
		        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		            dragInput = input
		        end
		    end)
		
		    RunService.RenderStepped:Connect(MV_CFF(function() 

		        if dragging and dragInput and dragStart and startPos then
		            local delta = dragInput.Position - dragStart
		            local newPos = startPos + Vector2.new(delta.X, delta.Y)
		            btn.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
		        end
		    end))
		
		    return btn
		end
		
		function getCharacter()
		    char = Plr and Plr.Character
		    humanoid = char and char:FindFirstChildOfClass("Humanoid")
		    return char, humanoid
		end
		
		function Stopallanimation()
		    local _, humanoid = getCharacter()
		    if humanoid then
		        local animator = humanoid:FindFirstChildOfClass("Animator")
		        if animator then
		            local success, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
		            if success and tracks then
		                for _, track in ipairs(tracks) do
		                    pcall(function() track:Stop() end)
		                end
		            end
		        end
		    end
		end
		
		function playAnimation(animationId)
		    local _, humanoid = getCharacter()
		    if not humanoid then return end
		    local animator = humanoid:FindFirstChildOfClass("Animator")
		    if not animator then
		        animator = Instance.new("Animator")
		        animator.Parent = humanoid
		    end
		    local animation = animCache[animationId]
		    if not animation then
		        animation = Instance.new("Animation")
		        animation.AnimationId = "rbxassetid://" .. tostring(animationId)
		        animCache[animationId] = animation
		    end
		    local ok, animTrack = pcall(function() return animator:LoadAnimation(animation) end)
		    if not ok or not animTrack then return end
		    animTrack.Priority = Enum.AnimationPriority.Action
		    animTrack:Play()
		    pcall(function() animTrack:AdjustSpeed(1.2) end)
		    return animTrack
		end
		
		function rotateCharacter(degrees)
		    if isPerformingAction then return end
		    isPerformingAction = true
		    local character, _ = getCharacter()
		    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		    if rootPart then
		        pcall(function()
		            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(degrees), 0)
		            camPos = camera and camera.CFrame.Position or rootPart.Position + Vector3.new(0, 5, 0)
		            camY = camPos.Y
		            distanceVec = camPos - rootPart.Position
		            flatVec = Vector3.new(distanceVec.X, 0, distanceVec.Z)
		            rotatedVec = CFrame.fromAxisAngle(Vector3.yAxis, math.rad(degrees)) * flatVec
		            newCamPos = rootPart.Position + rotatedVec
		            if camera and camera:IsA("Camera") then
		                camera.CFrame = CFrame.lookAt(Vector3.new(newCamPos.X, camY, newCamPos.Z), rootPart.Position)
		            end
		        end)
		    end
		    isPerformingAction = false
		end
		
		function sideDash(direction, distance, duration)
		    if isPerformingAction then return end
		    isPerformingAction = true
		    local character, _ = getCharacter()
		    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		    if rootPart then
		        local tween = TweenService:Create(
		            rootPart,
		            TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		            {CFrame = rootPart.CFrame * CFrame.new(direction * distance, 0, 0)}
		        )
		        pcall(function() tween:Play() end)
		        if tween then pcall(function() tween.Completed:Wait() end) end
		        pcall(function() tween:Destroy() end)
		    end
		    isPerformingAction = false
		end
		
		function impulseDash(direction, distance, height, power, duration)
		    if isPerformingAction then return end
		    isPerformingAction = true
		    local character, _ = getCharacter()
		    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		    if rootPart then
		        local force = Instance.new("BodyVelocity")
		        local vec = (rootPart.CFrame.RightVector * direction * distance + Vector3.new(0, height, 0))
		        if vec.Magnitude == 0 then vec = Vector3.new(0, 1, 0) end
		        force.Velocity = vec.Unit * power
		        force.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		        force.Parent = rootPart
		        task.delay(duration, function() pcall(function() force:Destroy() end) end)
		    end
		    isPerformingAction = false
		end
		
		function doM1Reset()
		    if not TechStates.M1Enabled then return end
		    Stopallanimation()
		    pcall(function() playAnimation(10480793962) end)
		    pcall(function() sideDash(1, 26, 0.22) end)
		    pcall(function() rotateCharacter(70) end)
		    task.wait(0.003)
		    pcall(function()
		        if VIM and type(VIM.SendKeyEvent) == "function" then
		            VIM:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
		            VIM:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
		        end
		    end)
		end
		
		function doEmoteDash()
		    if not TechStates.EmoteEnabled then return end
		    Stopallanimation()
		    pcall(function() playAnimation(10480793962) end)
		    pcall(function() rotateCharacter(90) end)
		    pcall(function() impulseDash(1, 38, 8, 95, 0.27) end)
		end
		
		
		M1Reset = Tabs.VexTech:Section({Opened = true, Box = true, BoxBorder = true, Title = "M1 Reset Macro", Icon = "box" })
		m1MobileBtnInstance = nil
		
		M1Reset:Toggle({
		    Title = "M1 Reset",
		    Flag = "tsbm1resettoggle",
		    Desc = "Toggle Of All M1 Reset",
		    Value = false,
		    Callback = function(state)
		        TechStates.M1Enabled = state
		    end
		})
		
		M1Reset:Toggle({
		    Title = "M1 Reset Mobile UI",
		    Flag = "tsbm1resetmobileui",
		    Desc = "Opens Mobile UI to Easy to use M1 Reset",
		    Value = false,
		    Callback = function(state)
		        if state then
		            if not m1MobileBtnInstance then
		                m1MobileBtnInstance = createDraggableButton("M1Btn", "M1 Reset", UDim2.new(0, 50, 0, 200), function()
		                    pcall(doM1Reset)
		                end)
		            end
		        else
		            if m1MobileBtnInstance then
		                m1MobileBtnInstance:Destroy()
		                m1MobileBtnInstance = nil
		            end
		        end
		    end
		})
		
		M1Reset:Keybind({
		    Title = "Keybind",
		    Flag = "tsbm1resetkeybind",
		    Desc = "Keybind to Use M1 Reset Tech",
		    Value = "",
		    Callback = function(v)
		        pcall(function()
		            TechStates.M1Key = Enum.KeyCode[v]
		        end)
		    end
		})
		
		
		EmoteDash = Tabs.VexTech:Section({Opened = true, Box = true, BoxBorder = true, Title = "Emote Dash Macro", Icon = "box"  })
		emoteMobileBtnInstance = nil
		
		EmoteDash:Toggle({
		    Title = "Emote Dash",
		    Flag = "tsbemotedashtoggle",
		    Desc = "Toggle Of All Emote Dash",
		    Value = false,
		    Callback = function(state)
		        TechStates.EmoteEnabled = state
		    end
		})
		
		EmoteDash:Toggle({
		    Title = "Emote Dash Mobile UI",
		    Flag = "tsbemotedashuitoggle",
		    Desc = "Opens Mobile UI to Easy to use Emote Dash",
		    Value = false,
		    Callback = function(state)
		        if state then
		            if not emoteMobileBtnInstance then
		                emoteMobileBtnInstance = createDraggableButton("EmoteBtn", "Emote Dash", UDim2.new(0, 50, 0, 260), function()
		                    pcall(doEmoteDash)
		                end)
		            end
		        else
		            if emoteMobileBtnInstance then
		                emoteMobileBtnInstance:Destroy()
		                emoteMobileBtnInstance = nil
		            end
		        end
		    end
		})
		
		EmoteDash:Keybind({
		    Title = "Keybind",
		    Flag = "tsbemotedashkeybind",
		    Desc = "Keybind to Use Emote Dash Tech",
		    Value = "",
		    Callback = function(v)
		        pcall(function()
		            TechStates.EmoteKey = Enum.KeyCode[v]
		        end)
		    end
		})
		
		UIS.InputBegan:Connect(function(input, gpe)
		    if gpe or UIS:GetFocusedTextBox() then return end
		    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		
		    if input.KeyCode == TechStates.M1Key then
		        pcall(doM1Reset)
		    elseif input.KeyCode == TechStates.EmoteKey then
		        pcall(doEmoteDash)
		    end
		end)
		
		
		
		
		
		
		
		
		TwistedAnimIds = {
		    "rbxassetid://15162694192",
		    "rbxassetid://14136436157",
		    "rbxassetid://16552234590",
		    "rbxassetid://13295936866",
		    "rbxassetid://13378708199",
		    "rbxassetid://10469643643",
		    "rbxassetid://17889290569",
		    "rbxassetid://17325537719",
		    "rbxassetid://13294471966"
		}
		
		TwistedEnabled = false
		TwistedMode = "Normal"
		PingOffset = 0
		LethalTime = 1.65
		extraAnimId = "rbxassetid://12273188754"
		extraAnimToggleState = false
		
		twistedConnections = {}
		
		function isInTable(tbl, value)
		    for _, v in ipairs(tbl) do
		        if v == value then return true end
		    end
		    return false
		end
		
		
		task.wait(0.5)
		function addExtraAnim()
		    if not isInTable(TwistedAnimIds, extraAnimId) then
		        table.insert(TwistedAnimIds, extraAnimId)
		    end
		end
		
		function removeExtraAnim()
		    for i, id in ipairs(TwistedAnimIds) do
		        if id == extraAnimId then
		            table.remove(TwistedAnimIds, i)
		            break
		        end
		    end
		end
		
		function DisconnectTwisted()
		    for _, conn in ipairs(twistedConnections) do
		        conn:Disconnect()
		    end
		    twistedConnections = {}
		end
		
		function MoveForward()
		    local rootPart = LocalPlayerGame.Character and LocalPlayerGame.Character:FindFirstChild("HumanoidRootPart")
		    if rootPart then
		        rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, 3)
		    end
		end
		
		function SendDash()
		    local args = {{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}
		    local char = LocalPlayerGame.Character
		    if char and char:FindFirstChild("Communicate") then
		        char.Communicate:FireServer(unpack(args))
		    end
		end
		
		function SetupNormalTwisted()
		    local humanoid = (LocalPlayerGame.Character or LocalPlayerGame.CharacterAdded:Wait()):WaitForChild("Humanoid")
		    local conn = humanoid.AnimationPlayed:Connect(function(track)
		        if track.Animation and isInTable(TwistedAnimIds, track.Animation.AnimationId) and TwistedEnabled then
		
		            local delayTime = 0.23 + PingOffset
		            if track.Animation.AnimationId == extraAnimId then
		                delayTime = LethalTime + PingOffset
		            end
		            task.delay(delayTime, function()
		                MoveForward()
		                SendDash()
		            end)
		        end
		    end)
		    table.insert(twistedConnections, conn)
		end
		
		function PerformInstantTwisted()
		    args = {{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}
		    char = LocalPlayerGame.Character
		    if char and char:FindFirstChild("Communicate") then
		        char.Communicate:FireServer(unpack(args))
		    end
		    
		    Camera = workspace.CurrentCamera
		    currentCFrame = Camera.CFrame
		    rotatedCFrame = currentCFrame * CFrame.Angles(40, math.rad(-90), 180)
		    Camera.CameraType = Enum.CameraType.Scriptable
		    
		    local tween1 = game:GetService("TweenService"):Create(Camera, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {CFrame = rotatedCFrame})
		    tween1:Play()
		    tween1.Completed:Wait()
		    wait(0.00001)
		    
		    local tween2 = game:GetService("TweenService"):Create(Camera, TweenInfo.new(0.001, Enum.EasingStyle.Sine), {CFrame = currentCFrame})
		    tween2:Play()
		    tween2.Completed:Wait()
		    wait(0.1)
		    
		    local tween3 = game:GetService("TweenService"):Create(Camera, TweenInfo.new(0.0001, Enum.EasingStyle.Sine), {CFrame = currentCFrame * CFrame.Angles(math.rad(-6), math.rad(20), 0)})
		    tween3:Play()
		    tween3.Completed:Wait()
		    
		    Camera.CameraType = Enum.CameraType.Custom
		end
		
		function SetupInstantTwisted()
		    local humanoid = (LocalPlayerGame.Character or LocalPlayerGame.CharacterAdded:Wait()):WaitForChild("Humanoid")
		    local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid.ChildAdded:Wait(function(c) return c:IsA("Animator") end)
		    
		    local conn = animator.AnimationPlayed:Connect(function(track)
		        if track.Animation and isInTable(TwistedAnimIds, track.Animation.AnimationId) and TwistedEnabled then
		            local rootPart = LocalPlayerGame.Character and LocalPlayerGame.Character:FindFirstChild("HumanoidRootPart")
		            if rootPart then
		                local backVector = rootPart.CFrame.LookVector * -1
		                rootPart.CFrame = rootPart.CFrame + (backVector * 1)
		            end
		            
		 
		            local delayTime = 0.25 + PingOffset
		            if track.Animation.AnimationId == extraAnimId then
		                delayTime = LethalTime + PingOffset
		            end
		            
		            task.delay(delayTime, function()
		                PerformInstantTwisted()
		            end)
		        end
		    end)
		    table.insert(twistedConnections, conn)
		end
		
		function UpdateTwistedTech()
		    DisconnectTwisted()
		    if not TwistedEnabled then return end
		    
		    if TwistedMode == "Normal" then
		        SetupNormalTwisted()
		    elseif TwistedMode == "Instant" then
		        SetupInstantTwisted()
		    end
		    
		    charConn = LocalPlayerGame.CharacterAdded:Connect(function()
		        task.wait(1)
		        UpdateTwistedTech()
		    end)
		    table.insert(twistedConnections, charConn)
		end
		
		twistedSection = Tabs.VexTech:Section({Opened = true, Box = true, BoxBorder = true,
		    Title = "Twisted Tech",
		    Icon = "box"
		})
		twistedSection:Toggle({
		    Title = "Twisted Tech",
		    Flag = "tsbtwistedtoggle",
		    Value = false,
		    Callback = function(state)
		        TwistedEnabled = state
		        UpdateTwistedTech()
		    end
		})
		
		twistedSection:Dropdown({
		    Title = "Mode",
		    Flag = "tsbtwistedmode",
		    Desc = "Choose between Normal and Instant",
		    Values = {"Normal", "Instant"},
		    Value = "Normal",
		    Multi = false,
		    Callback = function(value)
		        TwistedMode = value
		        if TwistedEnabled then
		            UpdateTwistedTech()
		        end
		    end
		})
		
		twistedSection:Slider({
		    Title = "Ping Compensation",
		    Flag = "tsbtwistedping",
		    Desc = "Additional delay in seconds to account for lag",
		    Value = { Min = 0, Max = 0.5, Default = 0 },
		    Step = 0.1,
		    Callback = function(value)
		        PingOffset = value
		    end
		})
		
		twistedSection:Toggle({
		    Title = "Garou Lethal Whirlwind Twisted",
		    Flag = "tsbtwistedgaroutoggle",
		    Value = false,
		    Callback = function(state)
		        extraAnimToggleState = state
		        if state then
		            addExtraAnim()
		        else
		            removeExtraAnim()
		        end
		    end
		})
		
		twistedSection:Slider({
		    Title = "Lethal Whirlwind Delay",
		    Flag = "tsblethaldelayslider",
		    Desc = "Additional delay in seconds to account for Lethal Whirlwind Twisted",
		    Value = { Min = 1, Max = 2, Default = 1.65 },
		    Step = 0.01,
		    Callback = function(value)
		        LethalTime = value
		    end
		})
		
		
		
		
		
		LocalPlayerGame = game.Players.LocalPlayer
		
		SupaEnabled = false
		SelectedAbilities = {"Stream", "Uppercut"}
		IsExecuting = false
		AnimConnection = nil
		CharConnection = nil
		
		DashDelay = 0.3
		TurnDelay = 0.26
		StreamPreDelay = 2.0
		
		AbilityIds = {
		    Stream   = "rbxassetid://12296113986",
		    Uppercut = "rbxassetid://10503381238"
		}
		
		function DoJump()
		    local humanoid = LocalPlayerGame.Character and LocalPlayerGame.Character:FindFirstChild("Humanoid")
		    if humanoid then humanoid.Jump = true end
		end
		
		function DoStopJump()
		    local humanoid = LocalPlayerGame.Character and LocalPlayerGame.Character:FindFirstChild("Humanoid")
		    if humanoid then humanoid.Jump = false end
		end
		
		function DoTurn()
		    local rootPart = LocalPlayerGame.Character and LocalPlayerGame.Character:FindFirstChild("HumanoidRootPart")
		    if rootPart then
		        local cf = rootPart.CFrame
		        rootPart.CFrame = CFrame.lookAt(cf.Position, cf.Position + (-cf.LookVector))
		        Camera = workspace.CurrentCamera
		        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + (-cf.LookVector))
		    end
		end
		
		function DoDash()
		    local communicate = LocalPlayerGame.Character and LocalPlayerGame.Character:FindFirstChild("Communicate")
		    if communicate then
		        communicate:FireServer({Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"})
		    end
		end
		
		function RunSupa()
		    DoJump()
		    task.delay(DashDelay, function()
		        DoDash()
		        task.delay(TurnDelay, function()
		            DoTurn()
		            DoStopJump()
		            IsExecuting = false
		        end)
		    end)
		end
		
		function ExecuteSupa(triggeredAbility)
		    if IsExecuting then return end
		    IsExecuting = true
		
		    if triggeredAbility == "Stream" then
		        task.delay(StreamPreDelay, function()
		            RunSupa()
		        end)
		    else
		        RunSupa()
		    end
		end
		
		function SetupAnimationListener()
		    if AnimConnection then
		        AnimConnection:Disconnect()
		        AnimConnection = nil
		    end
		    if not SupaEnabled then return end
		    local humanoid = LocalPlayerGame.Character and LocalPlayerGame.Character:FindFirstChild("Humanoid")
		    if not humanoid then return end
		
		    AnimConnection = humanoid.AnimationPlayed:Connect(function(track)
		        if not track.Animation or IsExecuting then return end
		        local animId = track.Animation.AnimationId
		        for _, abilityName in ipairs(SelectedAbilities) do
		            if AbilityIds[abilityName] == animId then
		                ExecuteSupa(abilityName)
		                break
		            end
		        end
		    end)
		end
		
		function OnCharacterAdded()
		    LocalPlayerGame.Character:WaitForChild("Humanoid")
		    SetupAnimationListener()
		end
		
		SupaTech = Tabs.VexTech:Section({Opened = true, Box = true, BoxBorder = true,
		    Title = "Supa Tech",
		    Icon = "box"
		})
		
		SupaTech:Toggle({
		    Title = "Enable Auto Supa",
		    Flag = "tsbautosupatoggle",
		    Value = false,
		    Callback = function(state)
		        SupaEnabled = state
		        if state then
		            SetupAnimationListener()
		            if not CharConnection then
		                CharConnection = LocalPlayerGame.CharacterAdded:Connect(OnCharacterAdded)
		            end
		        else
		            if AnimConnection then AnimConnection:Disconnect(); AnimConnection = nil end
		            if CharConnection then CharConnection:Disconnect(); CharConnection = nil end
		            IsExecuting = false
		        end
		    end
		})
		
		SupaTech:Dropdown({
		    Title = "Select Abilities",
		    Flag = "tsbsupadropdown",
		    Values = {"Stream", "Uppercut"},
		    Value = {"Stream", "Uppercut"},
		    Multi = true,
		    Callback = function(selectedValues)
		        SelectedAbilities = selectedValues
		        if SupaEnabled then SetupAnimationListener() end
		    end
		})
		
		SupaTech:Slider({
		    Title = "Dash Delay",
		    Flag = "tsbsupadashdelay",
		    Value = { Min = 0, Max = 2, Default = 0.3 },
		    Step = 0.05,
		    Callback = function(num) DashDelay = num end
		})
		
		SupaTech:Slider({
		    Title = "Turn Delay",
		    Flag = "tsbsupaturndeley",
		    Value = { Min = 0, Max = 2, Default = 0.26 },
		    Step = 0.05,
		    Callback = function(num) TurnDelay = num end
		})
		
		SupaTech:Slider({
		    Title = "Stream Pre Delay",
		    Flag = "tsbstreamdeley",
		    Value = { Min = 0, Max = 5, Default = 2.0 },
		    Step = 0.1,
		    Callback = function(num) StreamPreDelay = num end
		})
		
		SupaTech:Keybind({
		    Title = "Supa Keybind",
		    Flag = "tsbsupakeybind",
		    Value = "",
		    Callback = function(key, down)
		        if down and SupaEnabled and not IsExecuting then
		            local ability = SelectedAbilities[1] or "Uppercut"
		            ExecuteSupa(ability)
		        end
		    end
		})
		
		
		
		
		DownSlam = Tabs.VexTech:Section({Opened = true, Box = true, BoxBorder = true,Title = "True Downslam Tech", Icon = "box"})
		
		steps = 10
		duration = 0.1
		TrueDownslamConnection = nil
		
		DownSlam:Toggle({
		    Title = "True DownSlam",
		    Flag = "tsbtruedownslamtoggle",
		    Desc = "Dont hold M1 click slowly",
		    Value = false,
		    Callback = function(state)
		        PlayersService = game:GetService("Players")
		        RunServiceLocal = game:GetService("RunService")
		        WorkspaceLocal = game:GetService("Workspace")
		        LocalPlayerLocal = PlayersService.LocalPlayer
		        CameraLocal = WorkspaceLocal.CurrentCamera
		        
		        DownslamAnims = {
		            ["rbxassetid://13532600125"] = true,
		            ["rbxassetid://10469630950"] = true,
		            ["rbxassetid://13296577783"] = true,
		            ["rbxassetid://13370310513"] = true,
		            ["rbxassetid://15240216931"] = true,
		            ["rbxassetid://16515520431"] = true,
		            ["rbxassetid://17889461810"] = true
		        }
		        
		        DownslamHitAnims = {
		            ["rbxassetid://13532604085"] = true,
		            ["rbxassetid://10469639222"] = true,
		            ["rbxassetid://13295919399"] = true,
		            ["rbxassetid://13378751717"] = true,
		            ["rbxassetid://15240176873"] = true,
		            ["rbxassetid://16515448089"] = true,
		            ["rbxassetid://17889471098"] = true
		        }
		        
		        AnimCooldowns = {}
		        CharacterLocal = nil
		        
		        function GetCharacter()
		            char = LocalPlayerLocal.Character or LocalPlayerLocal.CharacterAdded:Wait()
		            hum = char:WaitForChild("Humanoid")
		            char.PrimaryPart = char:WaitForChild("HumanoidRootPart")
		            return char, hum
		        end
		        
		        function PerformTrueDownslam()
		            if CharacterLocal and CharacterLocal.PrimaryPart then
		                camSubject = CameraLocal.CameraSubject
		                CameraLocal.CameraSubject = nil
		                
		                currentPivot = CharacterLocal:GetPivot()
		                targetPivot = currentPivot + Vector3.new(0, 7, 0)
		                
		                for i = 1, steps do
		                    CharacterLocal:PivotTo(currentPivot:Lerp(targetPivot, i / steps))
		                    task.wait(duration / steps)
		                end
		                
		                CameraLocal.CameraSubject = camSubject
		            end
		        end
		        
		        if state then
		            if TrueDownslamConnection then
		                TrueDownslamConnection:Disconnect()
		            end
		            
		            char, hum = GetCharacter()
		            CharacterLocal = char
		            
		            TrueDownslamConnection = RunServiceLocal.RenderStepped:Connect(MV_CFF(function() 

		                if LocalPlayerLocal.Character ~= CharacterLocal then
		                    char, hum = GetCharacter()
		                    CharacterLocal = char
		                end
		                
		                for _, track in pairs(hum:GetPlayingAnimationTracks()) do
		                    animId = tostring(track.Animation.AnimationId)
		                    currentTime = tick()
		                    
		                    if DownslamAnims[animId] and (not AnimCooldowns[animId] or currentTime - AnimCooldowns[animId] > 0.5) then
		                        AnimCooldowns[animId] = currentTime
		                        task.delay(0.15, PerformTrueDownslam)
		                    elseif DownslamHitAnims[animId] and (not AnimCooldowns[animId] or currentTime - AnimCooldowns[animId] > 0.5) then
		                        AnimCooldowns[animId] = currentTime
		                        task.delay(0.15, function()
		                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
		                        end)
		                    end
		                end
		            end))
		        elseif TrueDownslamConnection then
		            TrueDownslamConnection:Disconnect()
		            TrueDownslamConnection = nil
		        end
		    end
		})
		
		DownSlam:Slider({
		    Title = "Speed of Tween",
		    Flag = "tsbdropdownspeedoftween",
		    Value = { Min = 1, Max = 20, Default = 10 },
		    Callback = function(num)
		    steps = num
		end
		})
		
		DownSlam:Slider({
		    Title = "Duration of Tween",
		    Flag = "tsbdropdowndurationoftween",
		    Value = { Min = 0, Max = 1, Default = 0.1 },
		    Step = 0.05,
		    Callback = function(num)
		    duration = num
		end
		})
		
		
		
		
		
		Grasp = Tabs.VexTech:Section({Opened = true, Box = true, BoxBorder = true,Title = "Grasp Techs", Icon = "box"})
		
		
		FlowingTeleportDistance = 24
		FlowingTeleportDelay = 1.8
		FlowingGraspAnimId = "rbxassetid://12273188754"
		FlowingGraspConnection = nil
		FlowingGraspEnabled = false
		
		Grasp:Toggle({
		    Title = "Flowing + Grasp",
		    Flag = "tsbflowinggrasptoggle",
		    Value = false,
		    Callback = function(state)
		        FlowingGraspEnabled = state
		        if FlowingGraspConnection then
		            FlowingGraspConnection:Disconnect()
		            FlowingGraspConnection = nil
		        end
		        
		        if FlowingGraspEnabled then
		            isAnimating = false
		            hasFired = false
		            
		            FlowingGraspConnection = game:GetService("RunService").RenderStepped:Connect(MV_CFF(function() 

		                char = LocalPlayerGame.Character
		                if not char then return end
		                
		                humanoid = char:FindFirstChild("Humanoid")
		                rootPart = char:FindFirstChild("HumanoidRootPart")
		                if not (humanoid and rootPart) then return end
		                
		                foundAnim = false
		                for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
		                    if track.Animation and track.Animation.AnimationId == FlowingGraspAnimId then
		                        foundAnim = true
		                        break
		                    end
		                end
		                
		                if foundAnim and not (isAnimating or hasFired) then
		                    isAnimating = true
		                    hasFired = true
		                    
		                    task.delay(FlowingTeleportDelay, function()
		                        targetCFrame = rootPart.CFrame + rootPart.CFrame.LookVector * 24
		                        tween = TweenService:Create(rootPart, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
		                        tween:Play()
		                        tween.Completed:Wait()
		                        
		                        graspTool = LocalPlayerGame.Backpack:FindFirstChild("Hunter's Grasp")
		                        communicate = char:FindFirstChild("Communicate")
		                        if graspTool and communicate then
		                            communicate:FireServer(unpack({{Tool = graspTool, Goal = "Console Move"}}))
		                        end
		                        
		                        isAnimating = false
		                    end)
		                elseif not foundAnim then
		                    hasFired = false
		                end
		            end))
		        end
		    end
		})
		
		
		Grasp:Slider({
		    Title = "Teleport Delay Of Flowing + Grasp",
		    Flag = "tsbflowinggraspteleportdeley",
		    Value = { Min = 0, Max = 5, Default = 1.8 },
		    Step = 0.1,
		    Callback = function(num)
		    FlowingTeleportDelay = num
		end
		})
		
		Grasp:Slider({
		    Title = "Teleport Distance Of Flowing + Grasp",
		    Flag = "tsbflowinggraspdistance",
		    Value = { Min = 0, Max = 50, Default = 24 },
		    Step = 1,
		    Callback = function(num)
		    FlowingTeleportDistance = num
		end
		})
		
		Grasp:Divider()
		
		
		UpperGraspDelay = 0.18
		UpperGraspUpwards = 8
		UpperGraspAnimId = "rbxassetid://10503381238"
		UpperGraspOffset = Vector3.new(0, UpperGraspUpwards, 0)
		UpperGraspEnabled = false
		UpperGraspConnection = nil
		
		Grasp:Toggle({
		    Title = "Upper + Grasp",
		    Flag = "tsbuppergrasptoggle",
		    Value = false,
		    Callback = function(state)
		        UpperGraspEnabled = state
		        if UpperGraspConnection then
		            UpperGraspConnection:Disconnect()
		            UpperGraspConnection = nil
		        end
		        
		        if UpperGraspEnabled then
		            isAnimating = false
		            hasFired = false
		            onCooldown = false
		            
		            UpperGraspConnection = game:GetService("RunService").RenderStepped:Connect(MV_CFF(function() 

		                char = LocalPlayerGame.Character
		                rootPart = char and char:FindFirstChild("HumanoidRootPart")
		                humanoid = char and char:FindFirstChild("Humanoid")
		                
		                if not (char and rootPart and humanoid) then return end
		                
		                foundAnim = false
		                for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
		                    if track.Animation and track.Animation.AnimationId == UpperGraspAnimId then
		                        foundAnim = true
		                        break
		                    end
		                end
		                
		                if foundAnim and not (isAnimating or hasFired or onCooldown) then
		                    isAnimating = true
		                    hasFired = true
		                    onCooldown = true
		                    
		                    task.delay(UpperGraspDelay, function()
		                        closestTorso = nil
		                        closestDist = 7
		                        liveFolder = workspace:FindFirstChild("Live")
		                        
		                        if liveFolder then
		                            for _, model in ipairs(liveFolder:GetChildren()) do
		                                if model:IsA("Model") and model ~= char then
		                                    torso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
		                                    if torso then
		                                        dist = (rootPart.Position - torso.Position).Magnitude
		                                        if dist <= closestDist then
		                                            closestDist = dist
		                                            closestTorso = torso
		                                        end
		                                    end
		                                end
		                            end
		                        end
		                        
		                        if closestTorso then
		                            targetPos = closestTorso.Position + UpperGraspOffset
		                            tween = TweenService:Create(rootPart, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {CFrame = 
		                            CFrame.new(targetPos)})
		                            tween:Play()
		                            tween.Completed:Wait()
		                        end
		                        
		                        graspTool = LocalPlayerGame.Backpack:FindFirstChild("Hunter's Grasp")
		                        communicate = char:FindFirstChild("Communicate")
		                        if graspTool and communicate then
		                            communicate:FireServer(unpack({{Tool = graspTool, Goal = "Console Move"}}))
		                        end
		                        
		                        isAnimating = false
		                        task.delay(15, function()
		                            onCooldown = false
		                        end)
		                    end)
		                elseif not foundAnim then
		                    hasFired = false
		                end
		            end))
		        end
		    end
		})
		
		
		Grasp:Slider({
		    Title = "Teleport Delay Of Uppercut + Grasp",
		    Flag = "tsbuppercutgraspteleportdeley",
		    Value = { Min = 0, Max = 5, Default = 1.8 },
		    Step = 0.01,
		    Callback = function(num)
		    UpperGraspDelay = num
		end
		})
		
		Grasp:Slider({
		    Title = "Teleport Upwards Distance Of Uppercut + Grasp",
		    Flag = "tsbuppercutgraspteleportdistance",
		    Value = { Min = 0, Max = 15, Default = 8 },
		    Step = 1,
		    Callback = function(num)
		    UpperGraspUpwards = num
		end
		})
		
		
		
		
		
		
		
		
		
		
		gojo = Tabs.VexTech:Section({Opened = true, Box = true, BoxBorder = true,Title = "Zenci Tech", Icon = "box"})
		
		UpperDashPitch = 0
		UpperDashTpStartDelay = 0.18 
		UpperDashDashDelay = 0.5
		UpperDashUpwards = 8
		UpperDashTpDuration = 1.0
		UpperDashAnimId = "rbxassetid://10503381238"
		UpperDashEnabled = false
		UpperDashConnection = nil
		
		gojo:Toggle({
		    Title = "Upper + Dash",
		    Flag = "tsbupperdashtoggle",
		    Value = false,
		    Callback = function(state)
		        UpperDashEnabled = state
		        if UpperDashConnection then
		            UpperDashConnection:Disconnect()
		            UpperDashConnection = nil
		        end
		        
		        if UpperDashEnabled then
		            isAnimating = false
		            hasFired = false
		            onCooldown = false
		            
		            UpperDashConnection = game:GetService("RunService").RenderStepped:Connect(MV_CFF(function() 

		                char = LocalPlayerGame.Character
		                rootPart = char and char:FindFirstChild("HumanoidRootPart")
		                humanoid = char and char:FindFirstChild("Humanoid")
		                
		                if not (char and rootPart and humanoid) then return end
		                
		                foundAnim = false
		                for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
		                    if track.Animation and track.Animation.AnimationId == UpperDashAnimId then
		                        foundAnim = true
		                        break
		                    end
		                end
		                
		                if foundAnim and not (isAnimating or hasFired or onCooldown) then
		                    isAnimating = true
		                    hasFired = true
		                    onCooldown = true
		                    
		                    local originalCFrame = rootPart.CFrame
		
		                    task.delay(UpperDashDashDelay, function()
		                        args = {{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}
		                        local dashChar = LocalPlayerGame.Character
		                        if dashChar and dashChar:FindFirstChild("Communicate") then
		                            dashChar.Communicate:FireServer(unpack(args))
		                        end
		                    end)
		
		                    task.delay(UpperDashTpStartDelay, function()
		                        closestTorso = nil
		                        closestDist = 7
		                        liveFolder = workspace:FindFirstChild("Live")
		                        
		                        if liveFolder then
		                            for _, model in ipairs(liveFolder:GetChildren()) do
		                                if model:IsA("Model") and model ~= char then
		                                    torso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
		                                    if torso then
		                                        dist = (originalCFrame.Position - torso.Position).Magnitude
		                                        if dist <= closestDist then
		                                            closestDist = dist
		                                            closestTorso = torso
		                                        end
		                                    end
		                                end
		                            end
		                        end
		                        
		                        if closestTorso then
		                            local startTime = tick()
		                            
		                            while tick() - startTime <= UpperDashTpDuration do
		                                if not closestTorso or not closestTorso.Parent then break end
		                                
		                                targetPos = closestTorso.Position + Vector3.new(0, UpperDashUpwards, 0)
		                                local targetCFrame = CFrame.new(targetPos) * CFrame.Angles(math.rad(UpperDashPitch), 0, 0)
		                                
		                                if rootPart then
		                                    rootPart.CFrame = targetCFrame
		                                end
		                                task.wait() 
		                            end
		                        end
		
		                        if rootPart then
		                            rootPart.CFrame = originalCFrame
		                        end
		                        
		                        isAnimating = false
		                        task.delay(15, function()
		                            onCooldown = false
		                        end)
		                    end)
		                    
		                elseif not foundAnim then
		                    hasFired = false
		                end
		            end))
		        end
		    end
		})
		
		gojo:Slider({
		    Title = "Teleport Start Delay",
		    Flag = "tsbuppercutdashtpstartdelay",
		    Value = { Min = 0, Max = 5, Default = 0.18 },
		    Step = 0.01,
		    Callback = function(num)
		        UpperDashTpStartDelay = num
		    end
		})
		
		gojo:Slider({
		    Title = "Dash Delay",
		    Flag = "tsbuppercutdashdashdelay",
		    Value = { Min = 0, Max = 5, Default = 0.5 },
		    Step = 0.01,
		    Callback = function(num)
		        UpperDashDashDelay = num
		    end
		})
		
		gojo:Slider({
		    Title = "Teleport Upwards Distance",
		    Flag = "tsbuppercutdashteleportdistance",
		    Value = { Min = -15, Max = 15, Default = 8 },
		    Step = 1,
		    Callback = function(num)
		        UpperDashUpwards = num
		    end
		})
		
		gojo:Slider({
		    Title = "Teleport Duration (Seconds)",
		    Flag = "tsbuppercutdashtpduration",
		    Value = { Min = 0, Max = 3, Default = 1.0 },
		    Step = 0.1,
		    Callback = function(num)
		        UpperDashTpDuration = num
		    end
		})
		
		gojo:Slider({
		    Title = "Look Angle (Up/Down)",
		    Flag = "tsbupperdashpitchanglegojo",
		    Value = { Min = -90, Max = 90, Default = 0 },
		    Step = 1,
		    Callback = function(num)
		        UpperDashPitch = num
		    end
		})
		
		
		
		
		
		
		
		
		do
		    VIM_HD      = game:GetService("VirtualInputManager")
		    TS_HD       = game:GetService("TweenService")
		
		    HD_Enabled    = false
		    HD_Locked     = nil
		    HD_LockKey    = Enum.KeyCode.K
		    HD_DashKey    = Enum.KeyCode.C
		    HD_Side       = "Left"
		    HD_MaxDist    = 50
		    HD_Offset     = 4
		    HD_Hold       = 0.18
		    HD_TweenTime  = 0.18
		    HD_M1Delay    = 0.12
		    HD_AnimSpeed  = 1.0
		    HD_QDelay     = 0.05
		    HD_QHold      = 0.06
		    HD_Busy       = false
		    HD_Highlight  = nil
		    HD_AnimCache  = {}
		
		    local function HD_getRoot(model)
		        if not model then return nil end
		        return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
		    end
		
		    local function HD_isAlive(model)
		        if not model or not model.Parent then return false end
		        local h = model:FindFirstChildOfClass("Humanoid")
		        return h and h.Health > 0
		    end
		
		    local function HD_clearHL()
		        if HD_Highlight then HD_Highlight:Destroy(); HD_Highlight = nil end
		    end
		
		    local function HD_applyHL(model)
		        HD_clearHL()
		        if not model then return end
		        local ok, hl = pcall(Instance.new, "Highlight")
		        if ok and hl then
		            hl.FillColor           = Color3.fromRGB(140, 60, 255)
		            hl.OutlineColor        = Color3.fromRGB(200, 120, 255)
		            hl.FillTransparency    = 0.7
		            hl.OutlineTransparency = 0.2
		            hl.Adornee             = model
		            hl.Parent              = CoreGui
		            HD_Highlight           = hl
		        else
		            local sel               = Instance.new("SelectionBox")
		            sel.Color3              = Color3.fromRGB(160, 60, 255)
		            sel.LineThickness       = 0.04
		            sel.SurfaceTransparency = 0.9
		            sel.SurfaceColor3       = Color3.fromRGB(140, 0, 255)
		            sel.Adornee             = model
		            sel.Parent              = CoreGui
		            HD_Highlight            = sel
		        end
		    end
		
		    local function HD_lock()
		        local char   = LocalPlayer.Character
		        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
		        if not myRoot then return end
		        local live = workspace:FindFirstChild("Live")
		        if not live then return end
		        local best, bestDist = nil, HD_MaxDist
		        for _, model in ipairs(live:GetChildren()) do
		            if model.Name ~= LocalPlayer.Name and model:IsA("Model") then
		                local hum  = model:FindFirstChildOfClass("Humanoid")
		                local root = HD_getRoot(model)
		                if hum and hum.Health > 0 and root then
		                    local d = (myRoot.Position - root.Position).Magnitude
		                    if d < bestDist then bestDist = d; best = model end
		                end
		            end
		        end
		        if best then
		            HD_Locked = best
		            HD_applyHL(best)
		            WindUI:Notify({ Title = "Hook Dash", Content = "Locked: " .. best.Name, Duration = 1.5, Icon = "crosshair" })
		        else
		            HD_Locked = nil
		            HD_clearHL()
		            WindUI:Notify({ Title = "Hook Dash", Content = "No target within " .. HD_MaxDist .. " studs", Duration = 1.5, Icon = "x-circle" })
		        end
		    end
		
		    local function HD_playAnim()
		        local char = LocalPlayer.Character
		        if not char then return end
		        local hum  = char:FindFirstChildOfClass("Humanoid")
		        if not hum then return end
		        local animator = hum:FindFirstChildOfClass("Animator")
		        if not animator then
		            animator = Instance.new("Animator")
		            animator.Parent = hum
		        end
		        local animId = 10480793962
		        local anim = HD_AnimCache[animId]
		        if not anim then
		            anim = Instance.new("Animation")
		            anim.AnimationId = "rbxassetid://" .. animId
		            HD_AnimCache[animId] = anim
		        end
		        local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
		        if not ok or not track then return end
		        track.Priority = Enum.AnimationPriority.Action
		        track:Play()
		        pcall(function() track:AdjustSpeed(HD_AnimSpeed) end)
		    end
		
		    local function HD_fireDash(side)
		        local moveKey = (side == "Left") and Enum.KeyCode.A or Enum.KeyCode.D
		        task.spawn(HD_playAnim)
		        VIM_HD:SendKeyEvent(true, moveKey, false, game)
		        task.delay(HD_QDelay, function()
		            VIM_HD:SendKeyEvent(true,  Enum.KeyCode.Q, false, game)
		            task.wait(HD_QHold)
		            VIM_HD:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
		        end)
		        task.delay(HD_Hold, function()
		            VIM_HD:SendKeyEvent(false, moveKey, false, game)
		        end)
		    end
		
		    local function HD_do()
		        if HD_Busy then return end
		        local char   = LocalPlayer.Character
		        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
		        if not myRoot then return end
		        if not HD_Locked or not HD_isAlive(HD_Locked) then
		            HD_lock()
		            if not HD_Locked then return end
		        end
		        local enemyRoot = HD_getRoot(HD_Locked)
		        if not enemyRoot then return end
		        if (myRoot.Position - enemyRoot.Position).Magnitude > HD_MaxDist then
		            WindUI:Notify({ Title = "Hook Dash", Content = "Too far — get closer", Duration = 1.5, Icon = "alert-circle" })
		            return
		        end
		        HD_Busy = true
		
		        local dir = Vector3.new(
		            enemyRoot.Position.X - myRoot.Position.X, 0,
		            enemyRoot.Position.Z - myRoot.Position.Z)
		        if dir.Magnitude > 0.1 then
		            myRoot.CFrame = CFrame.lookAt(myRoot.Position, myRoot.Position + dir)
		        end
		
		        HD_fireDash(HD_Side)
		        task.wait(HD_Hold + 0.12)
		
		        enemyRoot = HD_getRoot(HD_Locked)
		        if not enemyRoot then HD_Busy = false; return end
		
		        local eCF       = enemyRoot.CFrame
		        local behindPos = eCF.Position + (eCF.LookVector * -HD_Offset)
		        local lookTarget = Vector3.new(eCF.Position.X, behindPos.Y, eCF.Position.Z)
		        local finalCF    = CFrame.lookAt(behindPos, lookTarget)
		        local tween = TS_HD:Create(myRoot,
		            TweenInfo.new(HD_TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		            { CFrame = finalCF })
		        tween:Play()
		        tween.Completed:Wait()
		
		        enemyRoot = HD_getRoot(HD_Locked)
		        if enemyRoot then
		            local myPos    = myRoot.Position
		            local enemyPos = Vector3.new(enemyRoot.Position.X, myPos.Y, enemyRoot.Position.Z)
		            if (myPos - enemyPos).Magnitude > 0.1 then
		                myRoot.CFrame = CFrame.lookAt(myPos, enemyPos)
		            end
		        end
		
		        enemyRoot = HD_getRoot(HD_Locked)
		        if enemyRoot then
		            local camera = workspace.CurrentCamera
		            if camera then
		                local myPos    = myRoot.Position
		                local enemyPos = enemyRoot.Position
		                local backDir  = (myPos - enemyPos).Unit
		                local camPos   = myPos + backDir * 6 + Vector3.new(0, 2, 0)
		                local camTarget = Vector3.new(enemyPos.X, myPos.Y + 1.5, enemyPos.Z)
		                camera.CFrame = CFrame.lookAt(camPos, camTarget)
		            end
		        end
		
		        task.wait(HD_M1Delay)
		        task.spawn(function()
		            local c = LocalPlayer.Character
		            local communicate = c and c:FindFirstChild("Communicate")
		            if not communicate then return end
		            pcall(function() communicate:FireServer(unpack({{Goal = "LeftClick", Mobile = true}})) end)
		            task.wait(0.1)
		            pcall(function() communicate:FireServer(unpack({{Goal = "LeftClickRelease", Mobile = true}})) end)
		        end)
		
		        HD_Busy = false
		    end
		
		    game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
		        if gpe or game:GetService("UserInputService"):GetFocusedTextBox() then return end
		        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		        if not HD_Enabled then return end
		        if input.KeyCode == HD_LockKey then HD_lock()
		        elseif input.KeyCode == HD_DashKey then task.spawn(HD_do) end
		    end)
		
		    game:GetService("RunService").Heartbeat:Connect(MV_CFF(function() 

		        if HD_Locked and not HD_isAlive(HD_Locked) then
		            HD_Locked = nil; HD_clearHL()
		        end
		    end))
		    
		
		    HookDashMultiSection = Tabs.VexTech:MultiSection({
	            Title = "Hook Dash",
	            Icon = "fishing-hook",
	            Opened = true,
	            Box = true,
	            BoxBorder = true,
	        })
		
		    local SecHD_Controls = HookDashMultiSection:Section({Opened = true, Box = true, BoxBorder = true, Title = "Controls", Icon = "zap" })
		
		    SecHD_Controls:Toggle({
		        Title    = "Enable Hook Dash",
		        Desc     = "Enables K / C keybinds only — on-screen buttons work WITHOUT this",
		        Value    = false,
		        Callback = function(v)
		            HD_Enabled = v
		            if not v then HD_Locked = nil; HD_clearHL() end
		        end,
		    })
		
		    SecHD_Controls:Keybind({
		        Title    = "Lock Key",
		        Desc     = "Lock onto nearest enemy in workspace.Live",
		        Value    = "K",
		        Callback = function(v) pcall(function() HD_LockKey = Enum.KeyCode[v] end) end,
		    })
		
		    SecHD_Controls:Keybind({
		        Title    = "Dash Key",
		        Desc     = "Execute the hook dash",
		        Value    = "C",
		        Callback = function(v) pcall(function() HD_DashKey = Enum.KeyCode[v] end) end,
		    })
		
		    SecHD_Controls:Dropdown({
		        Title    = "Dash Direction",
		        Desc     = "Left = A+Q  |  Right = D+Q",
		        Values   = { "Left", "Right" },
		        Value    = "Left",
		        Callback = function(v) HD_Side = v end,
		    })
		
		    SecHD_Controls:Button({
		        Title    = "Lock Now",
		        Icon     = "crosshair",
		        Justify  = "Center",
		        Callback = function() HD_lock() end,
		    })
		
		    SecHD_Controls:Button({
		        Title    = "Dash Now",
		        Icon     = "zap",
		        Justify  = "Center",
		        Callback = function() task.spawn(HD_do) end,
		    })
		
		    local SecHD_Tuning = HookDashMultiSection:Section({Opened = true, Box = true, BoxBorder = true, Title = "Targeting", Icon = "settings" })
		
		    SecHD_Tuning:Slider({
		        Title    = "Lock Range (studs)",
		        Desc     = "Max distance to lock a target",
		        Step     = 1,
		        Value    = { Min = 10, Max = 150, Default = 50 },
		        Callback = function(v) HD_MaxDist = v end,
		    })
		
		    SecHD_Tuning:Slider({
		        Title    = "Behind Offset (studs)",
		        Desc     = "How far behind the enemy you land",
		        Step     = 1,
		        Value    = { Min = 1, Max = 12, Default = 4 },
		        Callback = function(v) HD_Offset = v end,
		    })
		
		    local SecHD_Timing = HookDashMultiSection:Section({Opened = true, Box = true, BoxBorder = true, Title = "Timing (Legit)", Icon = "timer" })
		
		    SecHD_Timing:Slider({
		        Title    = "Hold Duration (ms)",
		        Desc     = "How long A or D is held — lower = faster dash",
		        Step     = 5,
		        Value    = { Min = 60, Max = 300, Default = 180 },
		        Callback = function(v) HD_Hold = v / 1000 end,
		    })
		
		    SecHD_Timing:Slider({
		        Title    = "Q Tap Delay (ms)",
		        Desc     = "Delay before Q is pressed after movement key",
		        Step     = 5,
		        Value    = { Min = 20, Max = 150, Default = 50 },
		        Callback = function(v) HD_QDelay = v / 1000 end,
		    })
		
		    SecHD_Timing:Slider({
		        Title    = "Q Hold Duration (ms)",
		        Desc     = "How long Q is held during the dash input",
		        Step     = 5,
		        Value    = { Min = 20, Max = 150, Default = 60 },
		        Callback = function(v) HD_QHold = v / 1000 end,
		    })
		
		    SecHD_Timing:Slider({
		        Title    = "Tween Speed (ms)",
		        Desc     = "How fast you slide behind the enemy after dash",
		        Step     = 10,
		        Value    = { Min = 50, Max = 500, Default = 180 },
		        Callback = function(v) HD_TweenTime = v / 1000 end,
		    })
		
		    SecHD_Timing:Slider({
		        Title    = "M1 Fire Delay (ms)",
		        Desc     = "Delay before M1 hits after landing behind enemy",
		        Step     = 5,
		        Value    = { Min = 0, Max = 300, Default = 120 },
		        Callback = function(v) HD_M1Delay = v / 1000 end,
		    })
		
		    SecHD_Timing:Slider({
		        Title    = "Dash Anim Speed",
		        Desc     = "Playback speed of the side dash animation",
		        Step     = 0.1,
		        Value    = { Min = 0.5, Max = 2.0, Default = 1.0 },
		        Callback = function(v) HD_AnimSpeed = v end,
		    })
		
		    local HD_lockMobileGui = nil
		    local HD_dashMobileGui = nil
		
		    local function HD_makeMobileButton(guiName, label, accentColor, startX, startY, onPress)
		        local gui              = Instance.new("ScreenGui")
		        gui.Name               = guiName
		        gui.ResetOnSpawn       = false
		        gui.ZIndexBehavior     = Enum.ZIndexBehavior.Global
		        gui.DisplayOrder       = 9999
		        gui.IgnoreGuiInset     = true
		        gui.Parent             = LocalPlayer:WaitForChild("PlayerGui")
		
		        local frame            = Instance.new("Frame")
		        frame.Size             = UDim2.new(0, 120, 0, 54)
		        frame.Position         = UDim2.new(0, startX, 0, startY)
		        frame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
		        frame.BorderSizePixel  = 0
		        frame.Active           = true
		        frame.Parent           = gui
		        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
		
		        local stroke           = Instance.new("UIStroke")
		        stroke.Color           = accentColor
		        stroke.Thickness       = 1.4
		        stroke.Transparency    = 0.3
		        stroke.Parent          = frame
		
		        local bar              = Instance.new("Frame")
		        bar.Size               = UDim2.new(0, 3, 0, 28)
		        bar.Position           = UDim2.new(0, 8, 0.5, -14)
		        bar.BackgroundColor3   = accentColor
		        bar.BorderSizePixel    = 0
		        bar.Parent             = frame
		        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
		
		        local lbl              = Instance.new("TextLabel")
		        lbl.Size               = UDim2.new(1, -26, 1, 0)
		        lbl.Position           = UDim2.new(0, 22, 0, 0)
		        lbl.BackgroundTransparency = 1
		        lbl.Text               = label
		        lbl.TextColor3         = Color3.fromRGB(230, 230, 240)
		        lbl.Font               = Enum.Font.GothamBold
		        lbl.TextSize           = 13
		        lbl.TextXAlignment     = Enum.TextXAlignment.Left
		        lbl.Parent             = frame
		
		        local hitBtn           = Instance.new("TextButton")
		        hitBtn.Size            = UDim2.new(1, 0, 1, 0)
		        hitBtn.BackgroundTransparency = 1
		        hitBtn.Text            = ""
		        hitBtn.ZIndex          = 3
		        hitBtn.AutoButtonColor = false
		        hitBtn.Parent          = frame
		
		        local pressedColor = Color3.new(accentColor.R * 0.25, accentColor.G * 0.25, accentColor.B * 0.25)
		        local normalColor  = Color3.fromRGB(10, 10, 16)
		
		        hitBtn.InputBegan:Connect(function(input)
		            if input.UserInputType == Enum.UserInputType.MouseButton1
		            or input.UserInputType == Enum.UserInputType.Touch then
		                TS_HD:Create(frame,
		                    TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		                    { BackgroundColor3 = pressedColor }
		                ):Play()
		                stroke.Transparency = 0.0
		            end
		        end)
		
		        hitBtn.InputEnded:Connect(function(input)
		            if input.UserInputType == Enum.UserInputType.MouseButton1
		            or input.UserInputType == Enum.UserInputType.Touch then
		                TS_HD:Create(frame,
		                    TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		                    { BackgroundColor3 = normalColor }
		                ):Play()
		                stroke.Transparency = 0.3
		                task.spawn(onPress)
		            end
		        end)
		
		        local dragging, dragStart, startPos2 = false, nil, nil
		        frame.InputBegan:Connect(function(input)
		            if input.UserInputType == Enum.UserInputType.MouseButton1
		            or input.UserInputType == Enum.UserInputType.Touch then
		                dragging  = true
		                dragStart = input.Position
		                startPos2 = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
		                input.Changed:Connect(function()
		                    if input.UserInputState == Enum.UserInputState.End then
		                        dragging = false
		                    end
		                end)
		            end
		        end)
		        frame.InputChanged:Connect(function(input)
		            if not dragging then return end
		            if input.UserInputType == Enum.UserInputType.MouseMovement
		            or input.UserInputType == Enum.UserInputType.Touch then
		                local delta = input.Position - dragStart
		                frame.Position = UDim2.new(0, startPos2.X + delta.X, 0, startPos2.Y + delta.Y)
		            end
		        end)
		
		        return gui
		    end
		
		    local HD_lockPCGui     = nil
		    local HD_dashPCGui     = nil
		
		    local function HD_destroyMobileUI()
		        if HD_lockMobileGui then HD_lockMobileGui:Destroy(); HD_lockMobileGui = nil end
		        if HD_dashMobileGui then HD_dashMobileGui:Destroy(); HD_dashMobileGui = nil end
		    end
		
		    local function HD_destroyPCUI()
		        if HD_lockPCGui then HD_lockPCGui:Destroy(); HD_lockPCGui = nil end
		        if HD_dashPCGui then HD_dashPCGui:Destroy(); HD_dashPCGui = nil end
		    end
		
		    local function HD_createMobileUI()
		        HD_destroyMobileUI()
		        HD_lockMobileGui = HD_makeMobileButton("HD_LockGui_M", "Lock Target", Color3.fromHex("#7c3aed"), 20,  80, function() HD_lock() end)
		        HD_dashMobileGui = HD_makeMobileButton("HD_DashGui_M", "Hook Dash",  Color3.fromHex("#be123c"), 155, 80, function() task.spawn(HD_do) end)
		    end
		
		    local function HD_createPCUI()
		        HD_destroyPCUI()
		        HD_lockPCGui = HD_makeMobileButton("HD_LockGui_PC", "Lock Target", Color3.fromHex("#7c3aed"), 20,  500, function() HD_lock() end)
		        HD_dashPCGui = HD_makeMobileButton("HD_DashGui_PC", "Hook Dash",  Color3.fromHex("#be123c"), 155, 500, function() task.spawn(HD_do) end)
		    end
		
		    local SecHD_Mobile = Tabs.VexTech:Section({Opened = true, Box = true, BoxBorder = true, Title = "Hook Dash — On-Screen Buttons", Icon = "smartphone" })
		
		    SecHD_Mobile:Toggle({
		        Title    = "Show Mobile Buttons",
		        Desc     = "Buttons appear near the TOP of screen — for mobile players",
		        Value    = false,
		        Callback = function(v)
		            if v then HD_createMobileUI() else HD_destroyMobileUI() end
		        end,
		    })
		
		    SecHD_Mobile:Toggle({
		        Title    = "Show PC Buttons",
		        Desc     = "Buttons appear near the BOTTOM of screen — for PC players",
		        Value    = false,
		        Callback = function(v)
		            if v then HD_createPCUI() else HD_destroyPCUI() end
		        end,
		    })
		
		end
	end)
end















-- ================ LAG0 TAB0 ================ --
function LagTab()
    task.spawn(function()
        do
	        local lighting = game:GetService("Lighting")
	        local settingsService = game:GetService("Settings")
	        local starterGui = game:GetService("StarterGui")
	        local runService = game:GetService("RunService")
	        local thrownFolder = workspace:WaitForChild("Thrown")
	        local mapFolder = workspace:FindFirstChild("Map")
	
	        local thrownChildAddedConnection = nil
	        local debrisDescendantAddedConnection = nil
	        local cleanupHeartbeatConnection = nil
	        local hiddenPartsCache = {}
        end

        local function toggleMapPartVisibility(partName, shouldBeVisible)
            if not mapFolder then return end
            local part = mapFolder:FindFirstChild(partName)
            if shouldBeVisible then
                if not part and hiddenPartsCache[partName] then
                    hiddenPartsCache[partName].Parent = mapFolder
                    hiddenPartsCache[partName] = nil
                end
            else
                if part then
                    hiddenPartsCache[partName] = part
                    part.Parent = nil
                end
            end
        end

        local optimizeSection = Tabs.Lag:Section({
            Opened = true, Box = true, BoxBorder = true,
            Title = "Performance Optimizations", Icon = "zap"
        })

        optimizeSection:Button({
            Title = "Optimize Game Performance",
            Callback = function()
                lighting.GlobalShadows = false
                lighting.FogEnd = 9e9
                lighting.Brightness = 0

                settingsService.Rendering.QualityLevel = "Level01"

                local terrain = workspace.Terrain
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 0

                local optimizedCount = 0
                for _, descendant in ipairs(workspace:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        if descendant:IsA("MeshPart") then
                            descendant.Material = "Plastic"
                            descendant.Reflectance = 0
                            optimizedCount = optimizedCount + 1
                        elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                            descendant.Transparency = 1
                            optimizedCount = optimizedCount + 1
                        end
                    elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
                        descendant.Lifetime = NumberRange.new(0)
                        optimizedCount = optimizedCount + 1
                    elseif descendant:IsA("Fire") or descendant:IsA("SpotLight") or descendant:IsA("Smoke") or descendant:IsA("Sparkles") then
                        descendant.Enabled = false
                        optimizedCount = optimizedCount + 1
                    end
                end

                starterGui:SetCore("SendNotification", {
                    Title = "Performance Optimized",
                    Text = string.format("Optimized %d objects", optimizedCount),
                    Duration = 3
                })
            end
        })

        optimizeSection:Toggle({
            Title = "Remove Debris & Thrown",
            Flag = "tsbremovedebris",
            Value = false,
            Callback = function(state)
                if state then
                    thrownChildAddedConnection = thrownFolder.ChildAdded:Connect(function(obj)
                        obj.Parent = nil
                    end)

                    debrisDescendantAddedConnection = workspace.DescendantAdded:Connect(function(obj)
                        if obj:IsA("BasePart") and obj.Name:lower():match("^debris") then
                            obj.Parent = nil
                        end
                    end)

                    cleanupHeartbeatConnection = runService.Heartbeat:Connect(MV_CFF(function() 

                        if #thrownFolder:GetChildren() > 0 then
                            thrownFolder:ClearAllChildren()
                        end
                    end))
                else
                    if thrownChildAddedConnection then
                        thrownChildAddedConnection:Disconnect()
                        thrownChildAddedConnection = nil
                    end
                    if debrisDescendantAddedConnection then
                        debrisDescendantAddedConnection:Disconnect()
                        debrisDescendantAddedConnection = nil
                    end
                    if cleanupHeartbeatConnection then
                        cleanupHeartbeatConnection:Disconnect()
                        cleanupHeartbeatConnection = nil
                    end
                end
            end
        })

        local mapFolder = workspace:FindFirstChild("Map")
		local function toggleMapPartVisibility(name, state)
		    if not mapFolder then return end
		    
		    for _, obj in ipairs(mapFolder:GetDescendants()) do
		        if obj.Name == name and (obj:IsA("BasePart") or obj:IsA("Decal")) then
		            obj.Transparency = state and 0 or 1
		            if obj:IsA("BasePart") then
		                obj.CanCollide = state
		            end
		        end
		    end
		end
		
		local hidePartsSection = Tabs.Lag:Section({
		    Opened = true, 
		    Box = true, 
		    BoxBorder = true,
		    Title = "Hide Parts", 
		    Icon = "package"
		})
		
		if mapFolder then
		    hidePartsSection:Toggle({
		        Title = "Trees",
		        Flag = "tsbtreesremove",
		        Value = true,
		        Callback = function(state)
		            toggleMapPartVisibility("Trees", state)
		        end
		    })
		
		    hidePartsSection:Toggle({
		        Title = "Walls",
		        Flag = "tsbwallsremove",
		        Value = true,
		        Callback = function(state)
		            toggleMapPartVisibility("Walls", state)
		        end
		    })
		
		    hidePartsSection:Toggle({
		        Title = "Grass",
		        Flag = "tsbgrassremove",
		        Value = true,
		        Callback = function(state)
		            toggleMapPartVisibility("Grass", state)
		            toggleMapPartVisibility("GrassBottom", state)
		        end
		    })
		
		    hidePartsSection:Toggle({
		        Title = "Benches",
		        Flag = "tsbbenchesremove",
		        Value = true,
		        Callback = function(state)
		            toggleMapPartVisibility("Benches", state)
		        end
		    })
		
		    task.spawn(function()
		        toggleMapPartVisibility("Trees", false)
		        toggleMapPartVisibility("Walls", false)
		        toggleMapPartVisibility("Grass", false)
		        toggleMapPartVisibility("GrassBottom", false)
		        toggleMapPartVisibility("Benches", false)
		    end)
		end
    end)
end















-- ================ ANIMATION0 TAB0 ================ --
function DisguiseTab()
	task.spawn(function()
		local playersService = game:GetService("Players")
		local localPlayer = playersService.LocalPlayer

		local disguiseConfig = {
			meshList = {},
		}

		local function clearCharacterVisuals(character)
			if not character then return end
			local head = character:FindFirstChild("Head")
			local torso = character:FindFirstChild("Torso")

			for _, mesh in pairs(disguiseConfig.meshList) do
				if mesh and mesh.Parent then
					pcall(function() mesh:Destroy() end)
				end
			end
			disguiseConfig.meshList = {}

			local removableClasses = {"Accessory", "Shirt", "Pants", "CharacterMesh", "BodyColors", "ShirtGraphic"}
			for _, child in pairs(character:GetChildren()) do
				for _, className in pairs(removableClasses) do
					if child:IsA(className) then
						child:Destroy()
						break
					end
				end
			end

			if head then
				for _, child in pairs(head:GetChildren()) do
					if child:IsA("SpecialMesh") or child:IsA("Decal") or child:IsA("MeshPart") then
						child:Destroy()
					end
				end
			end

			if torso then
				for _, child in pairs(torso:GetChildren()) do
					if child:IsA("SpecialMesh") or child:IsA("MeshPart") then
						child:Destroy()
					end
				end
			end
		end

		local function applyAppearanceToCharacter(character, appearance)
			if not character or not appearance then return end
			local head = character:FindFirstChild("Head")
			local torso = character:FindFirstChild("Torso")

			for _, item in pairs(appearance:GetChildren()) do
				if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("BodyColors") or item:IsA("ShirtGraphic") then
					local clone = item:Clone()
					clone.Parent = character

				elseif item:IsA("Accessory") then
					local clone = item:Clone()
					clone.Name = "#ACCESSORY_" .. clone.Name
					clone.Parent = character

				elseif item:IsA("SpecialMesh") then
					local clone = item:Clone()
					if item.MeshType then clone.MeshType = item.MeshType end
					if item.Scale then clone.Scale = item.Scale end
					if item.MeshId then clone.MeshId = item.MeshId end
					if item.TextureId then clone.TextureId = item.TextureId end
					if item.VertexColor then clone.VertexColor = item.VertexColor end
					table.insert(disguiseConfig.meshList, clone)
					local target = (item.Parent and item.Parent.Name == "Torso") and torso or head
					if target then
						clone.Parent = target
					end

				elseif item.Name == "R6" then
					for _, childMesh in pairs(item:GetChildren()) do
						if childMesh:IsA("CharacterMesh") then
							local clone = childMesh:Clone()
							clone.Parent = character
						end
					end

				elseif item.Name == "face" and item:IsA("Decal") then
					local clone = item:Clone()
					clone.Parent = head

				elseif item:IsA("MeshPart") then
					local clone = item:Clone()
					clone.CanCollide = false
					clone.Anchored = false
					local lowerName = item.Name:lower()
					if lowerName:find("head") then
						clone.Parent = head
					elseif lowerName:find("torso") or lowerName:find("upper") or lowerName:find("lower") then
						clone.Parent = torso or character
					else
						clone.Parent = character
					end
					table.insert(disguiseConfig.meshList, clone)
				end
			end

			if head then
				if not head:FindFirstChild("face") then
					local faceDecal = Instance.new("Decal")
					faceDecal.Name = "face"
					faceDecal.Face = Enum.NormalId.Front
					faceDecal.Texture = "rbxasset://textures/face.png"
					faceDecal.Parent = head
				end

				if not head:FindFirstChildOfClass("SpecialMesh") then
					local headMesh = Instance.new("SpecialMesh")
					headMesh.MeshType = Enum.MeshType.Head
					headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
					headMesh.Parent = head
					table.insert(disguiseConfig.meshList, headMesh)
				end
			end
		end

		local function applyDisguise(userId)
			local character = localPlayer.Character
			if not character then return end

			clearCharacterVisuals(character)

			local success, appearance = pcall(function()
				return playersService:GetCharacterAppearanceAsync(userId)
			end)
			if success and appearance then
				applyAppearanceToCharacter(character, appearance)
			end

			local parent = character.Parent
			character.Parent = nil
			character.Parent = parent
		end

		local function clearDisguise()
			local character = localPlayer.Character
			if not character then return end

			clearCharacterVisuals(character)

			local success, selfAppearance = pcall(function()
				return playersService:GetCharacterAppearanceAsync(localPlayer.UserId)
			end)
			if success and selfAppearance then
				applyAppearanceToCharacter(character, selfAppearance)
			end

			local parent = character.Parent
			character.Parent = nil
			character.Parent = parent
		end

		local manualSection = Tabs.Disguise:Section({Opened = true, Box = true, BoxBorder = true, Title = "Manual Input"})

		manualSection:Input({
			Title = "User ID",
			Desc = "Enter Roblox User ID to Disguise",
			Placeholder = "e.g. 1467551683",
			Callback = function(text)
				local userId = tonumber(text)
				if userId then
					applyDisguise(userId)
					WindUI:Notify({
						Title = "Disguise Applied",
						Content = "User ID: " .. userId,
						Duration = 2,
						Icon = "check"
					})
				else
				end
			end
		})

		manualSection:Input({
			Title = "Username",
			Desc = "Enter Roblox Username to Disguise",
			Placeholder = "e.g. builderman",
			Callback = function(username)
				if username == "" then return end
				local success, userId = pcall(function()
					return playersService:GetUserIdFromNameAsync(username)
				end)
				if success and userId then
					applyDisguise(userId)
					WindUI:Notify({
						Title = "Disguise Applied",
						Content = "Target: " .. username .. " (ID: " .. userId .. ")",
						Duration = 2,
						Icon = "check"
					})
				else
					WindUI:Notify({
						Title = "Error",
						Content = "User not found or API error",
						Duration = 2,
						Icon = "alert-triangle"
					})
				end
			end
		})

		manualSection:Button({
			Title = "Random Server Player",
			Desc = "Disguise as a random player in this server",
			Callback = function()
				local playersList = playersService:GetPlayers()
				local availablePlayers = {}
				for _, player in ipairs(playersList) do
					if player ~= localPlayer then
						table.insert(availablePlayers, player)
					end
				end
				if #availablePlayers > 0 then
					local randomPlayer = availablePlayers[math.random(1, #availablePlayers)]
					applyDisguise(randomPlayer.UserId)
					WindUI:Notify({
						Title = "Random Disguise",
						Content = "Now disguised as: " .. randomPlayer.Name,
						Duration = 3,
						Icon = "user"
					})
				else
					WindUI:Notify({
						Title = "Error",
						Content = "No other players found in server",
						Duration = 3,
						Icon = "alert-circle"
					})
				end
			end
		})

		local quickSection = Tabs.Disguise:Section({Opened = true, Box = true, BoxBorder = true, Title = "Quick Selection"})

		local quickDisguiseList = {
			{ name = "Manjiro", userId = 1467551683, description = "Apply Manjiro's Avatar" },
			{ name = "TY01", userId = 4856428538, description = "Apply TY01's Avatar" },
			{ name = "Legendbro Best Frendo", userId = 2733484517, description = "Apply Legendbro's Avatar" },
			{ name = "Burakbabapiro", userId = 2059090606, description = "Apply Burakbabapiro's Avatar" },
			{ name = "Unknown Guy", userId = 9099919347, description = "Apply Unknown Guy's Avatar" },
			{ name = "FINNERIX", userId = 5595931595, description = "Apply FINNERIX's Avatar" },
			{ name = "Unknown Femboy", userId = 2643325532, description = "Apply Unknown Femboy's Avatar" },
			{ name = "Mafia", userId = 2554825563, description = "Apply Mafia's Avatar" },
			{ name = "THE KING", userId = 636351295, description = "Apply THE KING's Avatar" },
			{ name = "My Best Femboy", userId = 3992039715, description = "Apply My Best Femboy's Avatar" },
			{ name = "Vexon", userId = 1154980186, description = "Apply Vexon's Avatar" },
			{ name = "Renji", userId = 2670616781, description = "Apply Renji's Avatar" },
			{ name = "Roblox", userId = 1, description = "Apply Roblox's Avatar" },
			{ name = "Builderman", userId = 156, description = "Apply Builderman's Avatar" },
			{ name = "omar_tacoss", userId = 1624603249, description = "Apply omar_tacoss's Avatar" },
			{ name = "xlvkxlvk", userId = 3927219833, description = "Apply xlvkxlvk's Avatar" },
		}

		for _, entry in ipairs(quickDisguiseList) do
			quickSection:Button({
				Title = entry.name,
				Desc = entry.description,
				Callback = function()
					applyDisguise(entry.userId)
				end
			})
		end

		quickSection:Divider()

		quickSection:Button({
			Title = "Clear Disguise",
			Desc = "Restore your original avatar",
			Callback = function()
				clearDisguise()
				WindUI:Notify({
					Title = "Disguise Cleared",
					Content = "Your avatar restored",
					Duration = 2,
					Icon = "trash-2"
				})
			end
		})
	end)
end















-- ================ BRING0 TAB0 ================ --
function BringTab()
	task.spawn(function()
	
	
	
		local Players = game:GetService("Players")
		local PhysicsService = game:GetService("PhysicsService")
		local RunService = game:GetService("RunService")
		local LocalPlayer = Players.LocalPlayer
		
		local teleportPosition = Vector3.new(150, -495, 30)
		local autoVoidEnabled = false
		local isAnimationPlaying = false
		local tpBackEnabled = false
		local ghostModeEnabled = false
		local savedCFrame = nil
		local originalCameraCFrame = nil
		local originalCameraType = nil
		
		local cameraLockConnection = nil
		local heartbeatConnection = nil
		local animationConnection = nil
		local diedConnection = nil
		
		local CollisionGroupName = "NoCollision"
		local tpMode = "Single TP"
		
		local customAnimations = {
		    {id = "140164642047188", name = "Saitama Serious Uppercut",          teleportDelay = 0,   returnDelay = 9},
		    {id = "12273188754",     name = "Garou Flowing Water",               teleportDelay = 0,   returnDelay = 1.7},
		    {id = "12296113986",     name = "Garou Lethal Whirlwind Stream",     teleportDelay = 0,   returnDelay = 1.7},
		    {id = "13813099821",     name = "Garou ult move 4",                  teleportDelay = 0,   returnDelay = 3},
		    {id = "14057231976",     name = "Garou ult move 3",                  teleportDelay = 0.7, returnDelay = 1},
		    {id = "93546004428904",  name = "Garou ult move 4 Variant",          teleportDelay = 0,   returnDelay = 5},
		    {id = "95034083206292",  name = "Monster Garou Binding Cloth",       teleportDelay = 0,   returnDelay = 2.2},
		    {id = "94638356008696",  name = "Monster Garou Crowd Buster",        teleportDelay = 0,   returnDelay = 3},
		    {id = "115484690572880", name = "Monster Garou Hammer Heel Variant", teleportDelay = 1,   returnDelay = 2},
		    {id = "13633468484",     name = "Sonic ult move 1",                  teleportDelay = 0,   returnDelay = 6},
		    {id = "14705929107",     name = "Metalbat Foul Ball",                teleportDelay = 0,   returnDelay = 2.4},
		    {id = "14004235777",     name = "Metalbat Homerun",                  teleportDelay = 0.5, returnDelay = 1.5},
		    {id = "14046756619",     name = "Metalbat Beatdown",                 teleportDelay = 1,   returnDelay = 3},
		    {id = "14920779925",     name = "Metalbat ult move 3",               teleportDelay = 0,   returnDelay = 4.4},
		    {id = "15145462680",     name = "Atomic Samurai Atmos Cleave",       teleportDelay = 1.4, returnDelay = 1},
		    {id = "15295895753",     name = "Atomic Samurai Pinpoint Cut",       teleportDelay = 0.5, returnDelay = 1.3},
		    {id = "16062712948",     name = "Atomic Samurai ult move 3",         teleportDelay = 0,   returnDelay = 7},
		    {id = "16139108718",     name = "Tatsumaki Crushing Pull",           teleportDelay = 0,   returnDelay = 1},
		    {id = "17278415853",     name = "Tatsumaki ult move 3",              teleportDelay = 2,   returnDelay = 11},
		    {id = "17889080495",     name = "Tatsumaki ult move 4",              teleportDelay = 0,   returnDelay = 2.3},
		    {id = "16734584478",     name = "Tatsumaki ult",                     teleportDelay = 2,   returnDelay = 5.5},
		    {id = "17799224866",     name = "Suiryu Bullet Barrage",             teleportDelay = 2,   returnDelay = 1.2},
		    {id = "18182425133",     name = "Suiryu Head First",                 teleportDelay = 0,   returnDelay = 4},
		    {id = "18896229321",     name = "Suiryu ult move 2",                 teleportDelay = 4,   returnDelay = 3},
		    {id = "98542310119798",  name = "Child emperor Trinity Tear",        teleportDelay = 0,   returnDelay = 2},
		    {id = "16945550029",     name = "KJ Ravage",                         teleportDelay = 0,   returnDelay = 3.3},
		}
		
		local animationNames = {}
		local enabledAnimations = {}
		local animationsDict = {}
		
		for _, anim in ipairs(customAnimations) do
		    table.insert(animationNames, anim.name)
		    enabledAnimations[anim.name] = true
		    animationsDict[anim.id] = anim
		end
		
		local function isCharacterValid()
		    local char = LocalPlayer.Character
		    if not char or not char:IsDescendantOf(workspace) then return false end
		    
		    local hum = char:FindFirstChildOfClass("Humanoid")
		    local hrp = char:FindFirstChild("HumanoidRootPart")
		    
		    if not hum or hum.Health <= 0 or not hrp then return false end
		    return true, char, hum, hrp
		end
		
		local function isTargetAnimation(animationId)
		    local rawId = string.match(animationId, "%d+") 
		    if not rawId then return false, nil end
		    
		    local anim = animationsDict[rawId]
		    if anim and enabledAnimations[anim.name] then
		        return true, anim
		    end
		    return false, nil
		end
		
		local function stopHeartbeat()
		    if heartbeatConnection then
		        heartbeatConnection:Disconnect()
		        heartbeatConnection = nil
		    end
		end
		
		local function unlockCamera()
		    if cameraLockConnection then
		        cameraLockConnection:Disconnect()
		        cameraLockConnection = nil
		    end
		    local camera = workspace.CurrentCamera
		    if camera then
		        if camera.CameraType == Enum.CameraType.Scriptable then
		            camera.CameraType = originalCameraType or Enum.CameraType.Custom
		        end
		    end
		    originalCameraType = nil
		    originalCameraCFrame = nil
		end
		
		local function lockCamera()
		    if not ghostModeEnabled then return end
		    local camera = workspace.CurrentCamera
		    if not camera then return end
		    
		    originalCameraCFrame = camera.CFrame
		    if camera.CameraType ~= Enum.CameraType.Scriptable then
		        originalCameraType = camera.CameraType
		    end
		    camera.CameraType = Enum.CameraType.Scriptable
		
		    if cameraLockConnection then
		        cameraLockConnection:Disconnect()
		    end
		
		    cameraLockConnection = RunService.RenderStepped:Connect(function()
		        if camera and originalCameraCFrame and ghostModeEnabled and isCharacterValid() then
		            camera.CFrame = originalCameraCFrame
		        else
		            unlockCamera()
		        end
		    end)
		end
		
		local function doTeleport(animData)
		    local valid, char, hum, hrp = isCharacterValid()
		    if not valid then return end
		    
		    isAnimationPlaying = true
		    savedCFrame = hrp.CFrame
		
		    task.delay(animData.teleportDelay, function()
		        local stillValid, _, _, currentHrp = isCharacterValid()
		        if not autoVoidEnabled or not stillValid then
		            isAnimationPlaying = false
		            return
		        end
		
		        lockCamera()
		
		        if tpMode == "Loop TP" then
		            stopHeartbeat() 
		            heartbeatConnection = RunService.Heartbeat:Connect(function()
		                local loopValid, _, _, loopHrp = isCharacterValid()
		                if autoVoidEnabled and loopValid then
		                    loopHrp.CFrame = CFrame.new(teleportPosition)
		                else
		                    stopHeartbeat()
		                end
		            end)
		        else
		            currentHrp.CFrame = CFrame.new(teleportPosition)
		        end
		
		        task.delay(animData.returnDelay, function()
		            stopHeartbeat()
		
		            local returnValid, _, _, returnHrp = isCharacterValid()
		            if tpBackEnabled and savedCFrame and returnValid then
		                returnHrp.CFrame = savedCFrame
		            end
		
		            unlockCamera()
		            isAnimationPlaying = false
		            savedCFrame = nil
		        end)
		    end)
		end
		
		local function onAnimationPlayedAutoVoid(track)
		    if not autoVoidEnabled or isAnimationPlaying then return end
		    local isTarget, animData = isTargetAnimation(track.Animation.AnimationId)
		    if not isTarget or not animData then return end
		
		    doTeleport(animData)
		end
		
		local function cleanupCurrentCharacter()
		    stopHeartbeat()
		    unlockCamera()
		    
		    if animationConnection then
		        animationConnection:Disconnect()
		        animationConnection = nil
		    end
		    if diedConnection then
		        diedConnection:Disconnect()
		        diedConnection = nil
		    end
		    
		    isAnimationPlaying = false
		end
		
		local function updateCharacter(newChar)
		    cleanupCurrentCharacter()
		    
		    local humanoid = newChar:WaitForChild("Humanoid", 10)
		    if not humanoid then return end
		    
		    local animator = humanoid:WaitForChild("Animator", 10) or Instance.new("Animator", humanoid)
		    
		    diedConnection = humanoid.Died:Connect(function()
		        cleanupCurrentCharacter()
		    end)
		    
		    if animator then
		        animationConnection = animator.AnimationPlayed:Connect(onAnimationPlayedAutoVoid)
		    end
		
		    savedCFrame = nil
		end
		
		if LocalPlayer.Character then
		    task.spawn(updateCharacter, LocalPlayer.Character)
		end
		LocalPlayer.CharacterAdded:Connect(updateCharacter)
		
		workspace.FallenPartsDestroyHeight = -math.huge
		
		pcall(function()
		    PhysicsService:CreateCollisionGroup(CollisionGroupName)
		    PhysicsService:CollisionGroupSetCollidable(CollisionGroupName, "Default", false)
		end)
		
		local AutoVoidSection = Tabs.Bring:Section({Opened = true, Box = true, BoxBorder = true, Title = "Auto Move Bring", Icon = "star"})
		
		AutoVoidSection:Dropdown({
		    Title = "Select Place to Bring",
		    Values = {"Map", "Pixel", "Void", "Darkness", "Mountain", "Counter", "Atomic Base", "Atomic Base Up", "Atomic Slash", "Prison"},
		    Value = "Void",
		    SearchBarEnabled = true,
		    Multi = false,
		    Callback = function(selectedValue)
		        local placePositions = {
		            Map = Vector3.new(150, 505, 30),
		            Pixel = Vector3.new(30000000, 30000000, 30000000),
		            Void = Vector3.new(150, -495, 30),
		            Darkness = Vector3.new(0, 900000000002, 0),
		            Mountain = Vector3.new(155.577392578125, 628.742431640625, -447.93841552734375),
		            Counter = Vector3.new(-68, 29, 20346),
		            ["Atomic Base"] = Vector3.new(1063, 30, 23006),
		            ["Atomic Base Up"] = Vector3.new(1063, 405, 23006),
		            ["Atomic Slash"] = Vector3.new(1063, 131, 23006),
		            Prison = Vector3.new(438, 439, -376),
		        }
		        teleportPosition = placePositions[selectedValue]
		    end,
		})
		
		AutoVoidSection:Dropdown({
		    Title = "Active Moves",
		    Values = animationNames,
		    Value = animationNames,
		    SearchBarEnabled = true,
		    Multi = true,
		    Callback = function(selected)
		        for name, _ in pairs(enabledAnimations) do
		            enabledAnimations[name] = false
		        end
		        if typeof(selected) == "table" then
		            for _, name in ipairs(selected) do
		                enabledAnimations[name] = true
		            end
		        end
		    end,
		})
		
		AutoVoidSection:Dropdown({
		    Title = "TP Mode",
		    Values = {"Single TP", "Loop TP"},
		    Value = "Single TP",
		    Multi = false,
		    Callback = function(selectedValue)
		        tpMode = selectedValue
		    end,
		})
		
		AutoVoidSection:Toggle({
		    Title = "Auto Bring",
		    Flag = "tsbautovoid",
		    Value = false,
		    Callback = function(state)
		        autoVoidEnabled = state
		        if not state then
		            stopHeartbeat()
		            unlockCamera()
		        end
		    end,
		})
		
		AutoVoidSection:Toggle({
		    Title = "Auto Tp Back",
		    Flag = "tsbautovoidtpback",
		    Value = false,
		    Callback = function(state)
		        tpBackEnabled = state
		    end,
		})
		
		AutoVoidSection:Toggle({
		    Title = "Freeze Camera",
		    Flag = "tsbghostmode",
		    Value = false,
		    Callback = function(state)
		        ghostModeEnabled = state
		        if not state then
		            unlockCamera()
		        end
		    end,
		})
		
		local TeleportGroup = AutoVoidSection:Group({})
		
		TeleportGroup:Button({
		    Title = "Tp To Place",
		    Icon = "map-pin",
		    Callback = function()
		        local valid, _, _, hrp = isCharacterValid()
		        if not valid then return end
		        savedCFrame = hrp.CFrame
		        hrp.CFrame = CFrame.new(teleportPosition)
		    end,
		})
		
		TeleportGroup:Button({
		    Title = "Tp Back",
		    Icon = "undo-2",
		    Callback = function()
		        local valid, _, _, hrp = isCharacterValid()
		        if savedCFrame and valid then
		            hrp.CFrame = savedCFrame
		            savedCFrame = nil
		        end
		    end,
		})
	
	
	
		vexon_cloneref = cloneref or function(obj) return obj end
		vexon_services = setmetatable({}, {
		    __index = function(_, serviceName)
		        return vexon_cloneref(game:GetService(serviceName))
		    end,
		})
		
		vexon_players = vexon_services.Players
		vexon_runService = vexon_services.RunService
		vexon_localPlayer = vexon_players.LocalPlayer
		vexon_renderStepped = vexon_runService.RenderStepped
		vexon_heartbeat = vexon_runService.Heartbeat
		
		local vexon_charStates = {
		    ['Doing Wall Combo Anywhere'] = false,
		    Invisibility = false,
		}
		
		local vexon_teleportCFrames = {
		    ['Atomic Slash'] = CFrame.new(1064, 131, 23007) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    Arena = CFrame.new(-130, 440, -373) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    Baseplate = CFrame.new(1073, 407, 22984) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    ['Below Baseplate'] = CFrame.new(1073, 20, 22984) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    Jail = CFrame.new(440, 440, -395) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    ['Jail But Smaller'] = CFrame.new(20, 439, -460) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    ['Bigger Jail'] = CFrame.new(290, 440, 465) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    ['Even Bigger Jail'] = CFrame.new(378, 439, 457) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    ['Dark Domain'] = CFrame.new(-80, 84, 20395) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    ['Death Counter'] = CFrame.new(-66, 29, 20383) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    Middle = CFrame.new(155, 441, 45) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    ['Mountain 1'] = CFrame.new(306, 671, 411) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    ['Mountain 2'] = CFrame.new(-1, 653, -354) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    ['Mountain Edge'] = CFrame.new(-297, 594, -336) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		    Void = CFrame.new(169, 218, 102) * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(90), 0, 0),
		}
		
		local vexon_sortedNames = {}
		for name in pairs(vexon_teleportCFrames) do
		    table.insert(vexon_sortedNames, name)
		end
		table.sort(vexon_sortedNames)
		
		local function vexon_getChar(player)
		    return player and player.Character
		end
		
		local function vexon_getRoot(character)
		    return character and character:FindFirstChild('HumanoidRootPart') or nil
		end
		
		local function vexon_getHum(character)
		    return character and character:FindFirstChild('Humanoid') or nil
		end
		
		local function vexon_heartbeatTp(targetCframe)
		    local char = vexon_getChar(vexon_localPlayer)
		    local root = vexon_getRoot(char)
		    if char and root then
		        task.spawn(function()
		            vexon_renderStepped:Once(function()
		                root.Velocity = Vector3.new()
		                vexon_heartbeat:Wait()
		                root.Velocity = Vector3.new()
		            end)
		        end)
		        vexon_heartbeat:Once(function()
		            root.CFrame = targetCframe
		        end)
		    end
		end
		
		local function vexon_communicate(data)
		    local char = vexon_getChar(vexon_localPlayer)
		    local comms = char and char:WaitForChild('Communicate', 1)
		    if comms then
		        comms:FireServer(data)
		    end
		end
		
		
		vexon_heartbeat:Connect(MV_CFF(function() 

		    char = vexon_getChar(vexon_localPlayer)
		    root = vexon_getRoot(char)
		    hum = vexon_getHum(char)
		
		    if char and root and hum and hum.Health > 0 then
		        originalCF = root.CFrame
		        originalVel = root.Velocity
		        desyncCF = nil
		
		        if getgenv().vexonWallDesync then
		            desyncCF = getgenv().vexonWallDesync.CFrame
		        end
		
		        if desyncCF then
		            root.CFrame = desyncCF
		            vexon_renderStepped:Wait()
		            root.CFrame = originalCF
		            root.Velocity = originalVel
		        end
		    end
		end))
		
		local WallComboToggles = {
		    Anywhere = {Value = false},
		    Auto = {Value = false},
		    Bring = {Value = false},
		    TPBack = {Value = false}
		}
		
		local WallComboOptions = {
		    Area = {Value = "Death Counter"}
		}
		
		WallComboMods = Tabs.Bring:Section({Opened = true, Box = true, BoxBorder = true, Title = "Wall Combo", Icon = "brick-wall" })
		
		WallComboMods:Toggle({
		    Title = "Wall Combo Everywhere",
		    Value = false,
		    Flag = "vexon_wall_everywhere",
		    Callback = function(state) WallComboToggles.Anywhere.Value = state end
		})
		
		WallComboMods:Toggle({
		    Title = "Auto Wall Combo",
		    Flag = "vexon_wall_auto",
		    Value = false,
		    Callback = function(state) WallComboToggles.Auto.Value = state end
		})
		
		WallComboMods:Toggle({
		    Title = "Bring Wall Combo",
		    Value = false,
		    Callback = function(state) WallComboToggles.Bring.Value = state end
		})
		
		WallComboMods:Toggle({
		    Title = "Tp Back Old Pos",
		    Flag = "vexon_wall_tpback",
		    Value = false,
		    Callback = function(state) WallComboToggles.TPBack.Value = state end
		})
		
		WallComboMods:Dropdown({
		    Title = "Bring Place",
		    Flag = "vexon_wall_place",
		    Values = vexon_sortedNames,
		    Value = "Death Counter",
		    Callback = function(value) WallComboOptions.Area.Value = value end
		})
		
		local function vexon_initHooks(character)
		    character.AttributeChanged:Connect(function(attribute)
		        if attribute == 'Combo' and character:GetAttribute('Combo') == 5 and vexon_getRoot(character) then
		            if WallComboToggles.Anywhere.Value then
		                if WallComboToggles.Bring.Value then
		                    vexon_charStates['Doing Wall Combo Anywhere'] = true
		                    local start = tick()
		                    
		                    repeat
		                        getgenv().vexonWallDesync = {
		                            CFrame = vexon_getRoot(character).CFrame * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		                        }
		                        task.wait()
		                    until tick() >= start + 0.225
		
		                    local oldCF = vexon_getRoot(character).CFrame
		                    getgenv().vexonWallDesync = {
		                        CFrame = vexon_teleportCFrames[WallComboOptions.Area.Value],
		                    }
		                    
		                    task.wait(0.2)
		                    vexon_communicate({Goal = 'Wall Combo'})
		                    getgenv().vexonWallDesync = nil
		                    vexon_charStates['Doing Wall Combo Anywhere'] = false
		                    
		                    task.wait(0.5)
		                    if character:FindFirstChild('ForceField') and WallComboToggles.TPBack.Value then
		                        vexon_heartbeatTp(oldCF)
		                    end
		                else
		                    vexon_charStates['Doing Wall Combo Anywhere'] = true
		                    local start = tick()
		                    repeat
		                        getgenv().vexonWallDesync = {
		                            CFrame = vexon_getRoot(character).CFrame * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
		                        }
		                        task.wait()
		                    until tick() >= start + 0.6
		                    getgenv().vexonWallDesync = nil
		                    vexon_charStates['Doing Wall Combo Anywhere'] = false
		                end
		            end
		        end
		    end)
		
		    character.DescendantAdded:Connect(function(desc)
		        if desc:IsA('ObjectValue') and desc.Name:lower() == 'wallcombo' then
		            local start = tick()
		            while true do
		                if WallComboToggles.Auto.Value then
		                    vexon_communicate({Goal = 'Wall Combo'})
		                end
		                task.wait()
		                if desc.Parent ~= character or tick() >= start + (desc:GetAttribute('DeleteMe') or 0.6) then
		                    break
		                end
		            end
		        end
		    end)
		end
		
		if vexon_localPlayer.Character then vexon_initHooks(vexon_localPlayer.Character) end
		vexon_localPlayer.CharacterAdded:Connect(vexon_initHooks)
		
		
		
		
		
		
		
		
		
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local LocalPlayer = Players.LocalPlayer

SelectedTarget = nil
BodyPosition = nil
NoclipConnection = nil
Blacklist = {}
CollisionGroupName = "PlayerNoclip"
SelectedLocation = "Atomic Slash" 
IsFollowing = false
IsBringing = false
IsInCombo = false
HeightOffset = 7
PredictionTime = 0.15
SmartTargetEnabled = false
ReturnToOldPosition = false
OldPositionCFrame = nil
UseAttachTeleport = false



Locations = {
	["Current Location"] = nil,
    ["Atomic Slash"] = CFrame.new(1064, 131, 23007) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Arena"] = CFrame.new(-130, 440, -373) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Baseplate"] = CFrame.new(1073, 406, 22984) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Below Baseplate"] = CFrame.new(1073, 20, 22984) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Jail"] = CFrame.new(440, 440, -395) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Jail But Smaller"] = CFrame.new(20, 439, -460) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Bigger Jail"] = CFrame.new(290, 440, 465) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Even Bigger Jail"] = CFrame.new(378, 439, 457) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Dark Domain"] = CFrame.new(-80, 84, 20395) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Death Counter"] = CFrame.new(-66, 29, 20383) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Middle"] = CFrame.new(155, 441, 45) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Mountain 1"] = CFrame.new(306, 671, 411) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Mountain 2"] = CFrame.new(-1, 653, -354) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Mountain Edge"] = CFrame.new(-297, 594, -336) * CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(-90), 0, 0),
    ["Void"] = CFrame.new(169, 218, 102) * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
}




LocationNames = {}
for name, _ in pairs(Locations) do
    table.insert(LocationNames, name)
end
table.sort(LocationNames)

pcall(function()
    PhysicsService:CreateCollisionGroup(CollisionGroupName)
    PhysicsService:CollisionGroupSetCollidable(CollisionGroupName, "Default", false)
end)


local function performAttachTeleport(desiredCFrame, targetPlayer)
    if not desiredCFrame then return end
    
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local RootPart = Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso")
    if not RootPart or not RootPart.Parent then return end
    
    if UseAttachTeleport then
        local yOffset = AttachModeEnabled and 1.5 or 3.5
        local adjustedCFrame = desiredCFrame * CFrame.new(0, yOffset, 0)
        
        RootPart.CFrame = adjustedCFrame
        pcall(function() Character:SetPrimaryPartCFrame(adjustedCFrame) end)
        
        local repPart = nil
        if targetPlayer and targetPlayer.Character then
            repPart = targetPlayer.Character:FindFirstChild("Head") or targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        end
        
        if repPart and repPart.Parent then
            pcall(function() 
                sethiddenproperty(RootPart, "PhysicsRepRootPart", repPart) 
            end)
        end
    else
        RootPart.CFrame = desiredCFrame
    end
end


local function BringRandomPlayer()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    
    if not root then return end

    local targets = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
            
            if distance > 15 and p.Name ~= LastBroughtPlayer then
                table.insert(targets, p)
            end
        end
    end

    if #targets == 0 then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
                if distance > 15 then
                    table.insert(targets, p)
                end
            end
        end
    end

    if #targets > 0 then
        local randomTarget = targets[math.random(1, #targets)]
        LastBroughtPlayer = randomTarget.Name
        SelectedTarget = randomTarget.Name
        BringPlayer(SelectedTarget)
    end
end






function SetNoclip(Enabled)
    local Character = LocalPlayer.Character
    if Character and Character.PrimaryPart then
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
        local GroupName = Enabled and CollisionGroupName or "Default"
        for _, Part in ipairs(Character:GetDescendants()) do
            if Part:IsA("BasePart") then
                Part.CollisionGroup = GroupName
            end
        end
        if Enabled then
            NoclipConnection = RunService.Stepped:Connect(MV_CFF(function() 

                if Character then
                    for _, Part in ipairs(Character:GetDescendants()) do
                        if Part:IsA("BasePart") then
                            Part.CanCollide = false
                        end
                    end
                end
            end))
            if BodyPosition then
                BodyPosition:Destroy()
            end
            BodyPosition = Instance.new("BodyPosition")
            BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            BodyPosition.P = 50000
            BodyPosition.D = 1200
            BodyPosition.Parent = Character.PrimaryPart
        elseif BodyPosition then
            BodyPosition:Destroy()
            BodyPosition = nil
        end
    end
end

function BringPlayer(TargetName)
    local TargetPlayer = Players:FindFirstChild(TargetName)
    if TargetPlayer and TargetPlayer ~= LocalPlayer and TargetPlayer.Character then
        task.spawn(function()
            local Character = LocalPlayer.Character
            if Character and Character.PrimaryPart and TargetPlayer.Character then
                local Communicate = Character:FindFirstChild("Communicate")
                
                if Communicate and Communicate:IsA("RemoteEvent") then
                    IsBringing = true
                    
                    if ReturnToOldPosition then
                        OldPositionCFrame = Character.PrimaryPart.CFrame
                    end
                    
                    local CurrentLocationCFrame = nil
                    if SelectedLocation == "Current Location" then
                        CurrentLocationCFrame = Character.PrimaryPart.CFrame
                    end
                    
                    HeightOffset = 15
                    SetNoclip(true)

                    local Args = {
                        Click = {[1] = {["Goal"] = "LeftClick", ["Mobile"] = true}},
                        Jump = {[1] = {["Goal"] = "Record Jump"}},
                        Release = {[1] = {["Goal"] = "LeftClickRelease", ["Mobile"] = true}},
                        WallCombo = {[1] = {["Goal"] = "Wall Combo", ["Mobile"] = true}}
                    }

                    Communicate:FireServer(unpack(Args.Click))
                    task.wait(0.8) 
                    Communicate:FireServer(unpack(Args.Jump))
                    task.wait(0.36)
                    HeightOffset = 6
                    task.wait(0.15)
                    HeightOffset = 1
                    IsInCombo = true
                    task.wait(0.35)
                    Communicate:FireServer(unpack(Args.Release))
                    
                    IsBringing = false
                    IsInCombo = false
                    if not IsFollowing then
                        SetNoclip(false)
                    end
                    
                    local RootPart = Character.PrimaryPart
                    
                    local TargetCFrame
                    if SelectedLocation == "Current Location" and CurrentLocationCFrame then
                        TargetCFrame = CurrentLocationCFrame
                    else
                        TargetCFrame = Locations[SelectedLocation]
                    end
                    
                    if RootPart and TargetCFrame then
                        performAttachTeleport(TargetCFrame, TargetPlayer)
                    end

                    
                    task.wait(0.1)
                    for _ = 1, 6 do
                        Communicate:FireServer(unpack(Args.WallCombo))
                        task.wait(0.03)
                    end
                    
                    if ReturnToOldPosition and OldPositionCFrame then
                        task.wait(0.5)
                        performAttachTeleport(OldPositionCFrame, nil)
                        OldPositionCFrame = nil
                    end

                    
                    task.wait(0.5)
                end
            end
        end)
    end
end







BringSetting = Tabs.Bring:Section({Opened = true, Box = true, BoxBorder = true, Title = "Bring Settings", Icon = "settings" })


BringSetting:Toggle({
    Title = "Attach Teleport Mode",
    Desc = "Zero ping teleport method that attaches your character directly to the target. Highly effective for bringing if the target moving, its makes bring rate almost %100. Requires a high level executor like Delta. Xeno is not supported.",
    Default = false,
    Locked = LockedStatus,
    LockedTitle = "Premium",
    Callback = function(Value)
        UseAttachTeleport = Value
    end
})


task.spawn(function()
    TargetDropdown = BringSetting:Dropdown({
        Title = "Pick a Target",
        Desc = "Select Target to bring To Spot",
        Locked = LockedStatus,
        Value = "Select a player",
        LockedTitle = "Premium",
        SpecialType = "Player",
        ExcludeLocalPlayer = true,
        SearchBarEnabled = true,
        Callback = function(selectedValue)
            SelectedTarget = selectedValue
        end
    })
end)

BringSetting:Dropdown({
    Title = "Bring Spot",
    Flag = "tsbbringspotpremium",
    Locked = LockedStatus,
    LockedTitle = "Premium",
    Desc = "Select location to bring target",
    Values = LocationNames,
    Value = "Atomic Slash",
    Multi = false,
    Callback = function(selectedValue)
        SelectedLocation = selectedValue
    end
})

BringSetting:Divider()

BringSetting:Button({
    Title = "Bring",
    Locked = LockedStatus,
    LockedTitle = "Premium",
    Callback = function()
        BringPlayer(SelectedTarget)
    end
})

BringSetting:Slider({
    Title = "Prediction",
    Locked = LockedStatus,
    LockedTitle = "Premium",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = 0.23 },
    Callback = function(num)
        PredictionTime = num
    end
})

BringSetting:Toggle({
    Title = "Return to Old Position",
    Desc = "Teleport back after bring finishes",
    Default = false,
    Locked = LockedStatus,
    LockedTitle = "Premium",
    Callback = function(Value)
        ReturnToOldPosition = Value
    end
})


BringSetting:Divider()

BringSetting:Toggle({
    Title = "Loop Bring Random Player",
    Default = false,
    Locked = LockedStatus,
    LockedTitle = "Premium",
    Callback = function(Value)
        LoopBringEnabled = Value
        
        if LoopBringEnabled then
            task.spawn(function()
                while LoopBringEnabled do
                    if not IsBringing and not IsInCombo then
                        BringRandomPlayer()
                        task.wait(2.5)
                    else
                        task.wait(0.5)
                    end
                end
            end)
        end
    end
})


BringSetting:Button({
    Title = "Bring Random Player",
    Locked = LockedStatus,
    LockedTitle = "Premium",
    Callback = function()
        if not IsBringing and not IsInCombo then
            BringRandomPlayer()
        end
    end
})


heartbeatConnection = RunService.Heartbeat:Connect(MV_CFF(function() 

    local Character = LocalPlayer.Character
    if Character then
        local RootPart = Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso")
        if RootPart then
            if (IsFollowing or IsBringing) and SelectedTarget then
                local TargetPlayer = Players:FindFirstChild(SelectedTarget)
                if not (TargetPlayer and TargetPlayer.Character) then
                    return
                end
                local TargetRoot = TargetPlayer.Character.PrimaryPart
                if not TargetRoot then
                    return
                end
                local PredictedPos
                if UseAttachTeleport then
                    PredictedPos = TargetRoot.Position
                else
                    PredictedPos = TargetRoot.Position + Vector3.new(TargetRoot.AssemblyLinearVelocity.X, 0, TargetRoot.AssemblyLinearVelocity.Z) * PredictionTime
                end
                local TargetPos
                if IsInCombo then
                    TargetPos = PredictedPos - Vector3.new(0, 1, 0)
                    performAttachTeleport(CFrame.new(TargetPos, TargetPos - Vector3.new(0, 1, 0)), TargetPlayer)
                else
                    TargetPos = PredictedPos - Vector3.new(0, HeightOffset, 0)
                    performAttachTeleport(CFrame.new(TargetPos, PredictedPos), TargetPlayer)
                end
                if BodyPosition then
                    BodyPosition.Position = TargetPos
                end
            end
        end
    end
end))







	end)
end















-- ================ ATTACH0 TAB0 ================ --
function FlingTab()
	task.spawn(function()
		StarterGui = game:GetService("StarterGui")
		PlayersService = game:GetService("Players")
		RunService = game:GetService("RunService")
		PathfindingService = game:GetService("PathfindingService")
		UserInputService = game:GetService("UserInputService")
		TweenService = game:GetService("TweenService")
		
		localPlayer = PlayersService.LocalPlayer
		camera = workspace.CurrentCamera
		originalCameraSubject = camera.CameraSubject
		
		local FlingData = {
		    OldPos = nil,
		    FPDH = workspace.FallenPartsDestroyHeight or -500
		}
		
		USE_ATTACH_TELEPORT = false
		PREDICTION_INTENSITY = 1.25
		orbitSpeed = 8
		orbitDistance = 10
		bangSpeed = 5
		tweenSpeed = 10
		
		local loopFlags = {
		    teleport = false,
		    fling = false,
		    view = false,
		    aimLockCam = false,
		    aimLockChar = false,
		    orbit = false,
		    notifyOnDeath = false,
		    bang = false,
		    faceBang = false,
		    walkTo = false,
		    smartWalk = false,
		    tweenPlayer = false,
		    headSit = false,
		    backpack = false,
		    carpet = false
		}
		
		espEnabled = false
		espBillboard = nil
		connections = {}
		flingConnections = {}
		
		localCache = { Character = nil, Root = nil, Head = nil, Humanoid = nil }
		targetCache = { Character = nil, Root = nil, Head = nil, Humanoid = nil }
		selectedPlayerObject = nil
		
		selectorTool = nil
		toolEquipped = false
		toolToggleEnabled = false
		TOOL_NAME = "Select Player Tool"
		
		walkPath = nil
		walkIndex = 1
		lastTargetPos = Vector3.new()
		pathCalcDebounce = 0
		
		orbitAngle = 0
		bangTime = 0
		flingTimer = 0
		headSitSaved = nil
		backpackSaved = nil
		isFlinging = false
		
		currentTween = nil
		antiGravityVelocity = nil
		
		OrbitPlayerToggle = nil
		LoopFlingToggle = nil
		LoopViewToggle = nil
		AimLockCameraToggle = nil
		AimLockCharactherToggle = nil
		PlayerBangBang = nil
		FaceBangBang = nil
		WalkToPlayerToggle = nil
		TweenPlayerToggle = nil
		HeadSitPlayerToggle = nil
		BackpackPlayerToggle = nil
		CarpetPlayerToggle = nil
		EspPlayerToggle = nil
		
		local function sendNotification(title, text, icon, duration)
		    StarterGui:SetCore("SendNotification", {
		        Title = title or "ZRHUB",
		        Text = text,
		        Icon = icon or "rbxassetid://84519376661277",
		        Duration = duration or 5
		    })
		end
		
		local function clearConnections(connTable)
		    for k, v in pairs(connTable) do
		        if typeof(v) == "RBXScriptConnection" and v.Connected then
		            v:Disconnect()
		        end
		    end
		    table.clear(connTable)
		end
		
		local function updateCache(cache, char)
		    cache.Character = char
		    if char then
		        cache.Root = char:WaitForChild("HumanoidRootPart", 5)
		        cache.Head = char:WaitForChild("Head", 5)
		        cache.Humanoid = char:WaitForChild("Humanoid", 5)
		    else
		        cache.Root = nil
		        cache.Head = nil
		        cache.Humanoid = nil
		    end
		end
		
		local function createSelectedEsp()
		    if espBillboard then
		        espBillboard:Destroy()
		        espBillboard = nil
		    end
		    if not targetCache.Head or not selectedPlayerObject then return end
		    espBillboard = Instance.new("BillboardGui")
		    espBillboard.Name = "ESP_Billboard"
		    espBillboard.Size = UDim2.new(0, 200, 0, 50)
		    espBillboard.Adornee = targetCache.Head
		    espBillboard.AlwaysOnTop = true
		    
		    local frame = Instance.new("Frame")
		    frame.Size = UDim2.new(1, 0, 1, 0)
		    frame.BackgroundColor3 = Color3.new(0.8, 0, 0)
		    frame.BackgroundTransparency = 0.6
		    frame.Parent = espBillboard
		    
		    local corner = Instance.new("UICorner")
		    corner.CornerRadius = UDim.new(0, 8)
		    corner.Parent = frame
		    
		    local textLabel = Instance.new("TextLabel")
		    textLabel.Size = UDim2.new(1, 0, 1, 0)
		    textLabel.BackgroundTransparency = 1
		    textLabel.TextColor3 = Color3.new(1, 1, 1)
		    textLabel.Text = selectedPlayerObject.DisplayName
		    textLabel.Font = Enum.Font.SourceSansBold
		    textLabel.TextSize = 16
		    textLabel.Parent = frame
		    
		    espBillboard.Parent = localPlayer.PlayerGui
		end
		
		local function removeSelectedEsp()
		    if espBillboard then
		        espBillboard:Destroy()
		        espBillboard = nil
		    end
		end
		
		local function manageDeathNotification()
		    if connections.targetDeath then 
		        connections.targetDeath:Disconnect() 
		        connections.targetDeath = nil 
		    end
		    if loopFlags.notifyOnDeath and targetCache.Humanoid and selectedPlayerObject then
		        connections.targetDeath = targetCache.Humanoid.Died:Connect(function()
		            sendNotification("ZRHUB", selectedPlayerObject.DisplayName .. " Died")
		        end)
		    end
		end
		
		local function updateSelectedPlayer(playerName)
		    clearConnections(connections)
		    removeSelectedEsp()
		    selectedPlayerObject = nil
		    updateCache(targetCache, nil)
		    
		    if not playerName or playerName == "" then
		        sendNotification("ZRHUB", "No One Selected")
		        return
		    end
		    
		    local lowerPlayerName = string.lower(playerName)
		    for _, player in ipairs(PlayersService:GetPlayers()) do
		        if string.find(string.lower(player.Name), lowerPlayerName, 1, true) or string.find(string.lower(player.DisplayName), lowerPlayerName, 1, true) then
		            selectedPlayerObject = player
		            break
		        end
		    end
		    
		    if selectedPlayerObject then
		        sendNotification("ZRHUB", "Selected: " .. selectedPlayerObject.DisplayName, "https://www.roblox.com/headshot-thumbnail/image?userId=" .. selectedPlayerObject.UserId .. "&width=420&height=420&format=png", 10)
		        
		        connections.targetAdded = selectedPlayerObject.CharacterAdded:Connect(function(char)
		            task.spawn(function()
		                updateCache(targetCache, char)
		                manageDeathNotification()
		                if espEnabled then createSelectedEsp() end
		            end)
		        end)
		        
		        connections.targetRemoving = selectedPlayerObject.CharacterRemoving:Connect(function()
		            updateCache(targetCache, nil)
		            removeSelectedEsp()
		        end)
		        
		        if selectedPlayerObject.Character then
		            task.spawn(function()
		                updateCache(targetCache, selectedPlayerObject.Character)
		                manageDeathNotification()
		                if espEnabled then createSelectedEsp() end
		            end)
		        end
		    else
		        sendNotification("ZRHUB", "Player Not Found...")
		    end
		end
		
		local function performAttachTeleport(desiredCFrame, targetPart)
		    if not desiredCFrame then return end
		    
		    local localChar = localPlayer.Character
		    if not localChar then return end
		    
		    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
		    if not localRoot or not localRoot.Parent then return end
		    
		    if USE_ATTACH_TELEPORT then
		        local adjustedCFrame = desiredCFrame * CFrame.new(0, 1.5, 0)
		        
		        localRoot.CFrame = adjustedCFrame
		        pcall(function() localChar:SetPrimaryPartCFrame(adjustedCFrame) end)
		        
		        local repPart = targetPart
		        if targetCache.Head and targetCache.Head.Parent then
		            repPart = targetCache.Head
		        end
		        
		        if repPart and repPart.Parent then
		            pcall(function() 
		                sethiddenproperty(localRoot, "PhysicsRepRootPart", repPart) 
		            end)
		        end
		    else
		        localRoot.CFrame = desiredCFrame
		    end
		end
		
		
		local function miniFling()
		    if not localCache.Root or not localCache.Humanoid or not targetCache.Character or isFlinging then return end
		    
		    local tRoot = targetCache.Root
		    local tHead = targetCache.Head
		    local targetPart = tHead or tRoot
		    if not targetPart then return end
		    
		    isFlinging = true
		    
		    if localCache.Root.Velocity.Magnitude < 50 then
		        FlingData.OldPos = localCache.Root.CFrame
		    end
		    
		    local cameraTarget = targetCache.Humanoid or tHead
		    if cameraTarget then
		        camera.CameraSubject = cameraTarget
		    end
		    
		    workspace.FallenPartsDestroyHeight = 0/0
		    
		    local bodyVelocity = Instance.new("BodyVelocity")
		    bodyVelocity.Name = "EpixVel"
		    bodyVelocity.Parent = localCache.Root
		    bodyVelocity.Velocity = Vector3.new(9e8, 9e8, 9e8)
		    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		    
		    localCache.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
		    
		    local startTime = tick()
		    local angle = 0
		    
		    flingConnections.flingLoop = RunService.Heartbeat:Connect(function(dt)
		        if not targetPart or not targetPart.Parent or targetPart.Velocity.Magnitude > 500 or (targetCache.Humanoid and targetCache.Humanoid.Sit) or localCache.Humanoid.Health <= 0 or tick() > startTime + 2 then
		            clearConnections(flingConnections)
		            bodyVelocity:Destroy()
		            localCache.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		            camera.CameraSubject = localCache.Humanoid
		            
		            task.delay(0.1, function()
		                local returnPos = FlingData.OldPos and FlingData.OldPos * CFrame.new(0, 0.5, 0) or localCache.Root.CFrame
		                local retryCount = 0
		                local restoreConn
		                restoreConn = RunService.Heartbeat:Connect(function()
		                    if not localCache.Root then 
		                        restoreConn:Disconnect() 
		                        return 
		                    end
		                    localCache.Root.CFrame = returnPos
		                    localCache.Character:SetPrimaryPartCFrame(returnPos)
		                    localCache.Humanoid:ChangeState("GettingUp")
		                    
		                    for _, part in ipairs(localCache.Character:GetChildren()) do
		                        if part:IsA("BasePart") then
		                            part.Velocity = Vector3.new()
		                            part.RotVelocity = Vector3.new()
		                        end
		                    end
		                    
		                    retryCount = retryCount + 1
		                    if (localCache.Root.Position - returnPos.Position).Magnitude < 25 or retryCount > 50 then
		                        restoreConn:Disconnect()
		                        workspace.FallenPartsDestroyHeight = FlingData.FPDH
		                        isFlinging = false
		                    end
		                end)
		            end)
		            return
		        end
		        
		        angle = angle + (8000 * dt)
		        local offset = USE_ATTACH_TELEPORT and CFrame.new(0, 0.8 * math.sin(tick()*10), 0) or CFrame.new(0, 1.5 * math.sin(tick()*10), 0)
		        local rotation = USE_ATTACH_TELEPORT and CFrame.Angles(math.rad(angle), math.rad(angle * 0.7), 0) or CFrame.Angles(math.rad(angle), 0, 0)
		        
		        if not USE_ATTACH_TELEPORT and targetPart.Velocity.Magnitude < 50 and targetCache.Humanoid then
		            offset = offset + targetCache.Humanoid.MoveDirection * (targetPart.Velocity.Magnitude / PREDICTION_INTENSITY)
		        end
		        
		        local finalCFrame = CFrame.new(targetPart.Position) * offset * rotation
		        localCache.Root.CFrame = finalCFrame
		        localCache.Character:SetPrimaryPartCFrame(finalCFrame)
		        localCache.Root.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
		        localCache.Root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
		        
		        if USE_ATTACH_TELEPORT then
		            pcall(function() sethiddenproperty(localCache.Root, "PhysicsRepRootPart", targetPart) end)
		        end
		    end)
		end
		
		local function removeSelectorTool()
		    toolEquipped = false
		    if selectorTool then
		        selectorTool:Destroy()
		        selectorTool = nil
		    end
		    local bTool = localPlayer.Backpack:FindFirstChild(TOOL_NAME)
		    if bTool then bTool:Destroy() end
		    local cTool = localPlayer.Character and localPlayer.Character:FindFirstChild(TOOL_NAME)
		    if cTool then cTool:Destroy() end
		end
		
		local function giveSelectorTool()
		    if not toolToggleEnabled then return end
		    local existingInBackpack = localPlayer.Backpack:FindFirstChild(TOOL_NAME)
		    local existingInChar = localPlayer.Character and localPlayer.Character:FindFirstChild(TOOL_NAME)
		    if existingInBackpack or existingInChar then return end
		    
		    selectorTool = Instance.new("Tool")
		    selectorTool.Name = TOOL_NAME
		    selectorTool.RequiresHandle = false
		    selectorTool.Parent = localPlayer.Backpack
		    
		    connections.toolEquipped = selectorTool.Equipped:Connect(function()
		        toolEquipped = true
		        sendNotification("ZRHUB", "Tool Equipped. Tap/Click a player to select.", nil, 3)
		    end)
		    
		    connections.toolUnequipped = selectorTool.Unequipped:Connect(function()
		        toolEquipped = false
		    end)
		end
		
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
		    if gameProcessed or not toolToggleEnabled or not toolEquipped then return end
		    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		        local target = nil
		        if input.UserInputType == Enum.UserInputType.MouseButton1 then
		            target = localPlayer:GetMouse().Target
		        else
		            local touchRay = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
		            local raycastResult = workspace:Raycast(touchRay.Origin, touchRay.Direction * 1000)
		            if raycastResult then target = raycastResult.Instance end
		        end
		        
		        if target then
		            local character = target:FindFirstAncestorOfClass("Model")
		            if character then
		                local clickedPlayer = PlayersService:GetPlayerFromCharacter(character)
		                if clickedPlayer and clickedPlayer ~= localPlayer then
		                    if playerDropdown then
		                        playerDropdown:Select(clickedPlayer.Name)
		                    end
		                elseif clickedPlayer == localPlayer then
		                    sendNotification("ZRHUB", "You cannot select yourself!", nil, 3)
		                end
		            end
		        end
		    end
		end)
		
		local function centralizedGameLoop(dt)
		    if not localCache.Root or not localCache.Humanoid then return end
		    
		    if loopFlags.aimLockCam and targetCache.Head then
		        camera.CFrame = CFrame.new(camera.CFrame.Position, targetCache.Head.Position)
		    end
		    
		    local tRoot = targetCache.Root
		    local tHead = targetCache.Head
		    local tPart = tRoot or tHead
		    if not tPart then return end
		    
		    if loopFlags.view and targetCache.Humanoid then
		        if camera.CameraSubject ~= targetCache.Humanoid then
		            camera.CameraSubject = targetCache.Humanoid
		        end
		    end
		    
		    if loopFlags.teleport then
		        performAttachTeleport(tPart.CFrame, tPart)
		    elseif loopFlags.orbit then
		        orbitAngle = (orbitAngle + orbitSpeed * dt * 50) % 360
		        local orbitCFrame = CFrame.new(tPart.Position) * CFrame.Angles(0, math.rad(orbitAngle), 0) * CFrame.new(orbitDistance, 0, 0)
		        local lookCFrame = CFrame.new(orbitCFrame.Position, tPart.Position)
		        performAttachTeleport(lookCFrame, tPart)
		    elseif loopFlags.aimLockChar then
		        local aimCFrame = CFrame.new(localCache.Root.Position, tPart.Position)
		        performAttachTeleport(aimCFrame, tPart)
		    elseif loopFlags.bang then
		        bangTime = bangTime + dt
		        local thrust = math.sin(bangTime * bangSpeed * 10) * 1.8
		        local finalCFrame = tPart.CFrame * CFrame.new(0, 0, 3.5 + thrust)
		        performAttachTeleport(finalCFrame, tPart)
		    elseif loopFlags.faceBang and tHead then
		        bangTime = bangTime + dt
		        local thrust = math.sin(bangTime * bangSpeed * 10) * 1.8
		        local finalCFrame = tHead.CFrame * CFrame.Angles(0, math.rad(180), 0) * CFrame.new(0, 1, 2.5 + thrust)
		        performAttachTeleport(finalCFrame, tHead)
		    elseif loopFlags.tweenPlayer then
		        if currentTween then
		            currentTween:Cancel()
		            currentTween = nil
		        end
		        local distance = (localCache.Root.Position - tPart.Position).Magnitude
		        if distance > 0.5 then
		            local duration = distance / tweenSpeed
		            local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		            currentTween = TweenService:Create(localCache.Root, tweenInfo, {CFrame = tPart.CFrame})
		            currentTween:Play()
		        end
		    elseif loopFlags.headSit and tHead then
		        local sitCFrame = tHead.CFrame * CFrame.new(0, 3, 0)
		        performAttachTeleport(sitCFrame, tHead)
		    elseif loopFlags.backpack then
		        local backpackCFrame = tPart.CFrame * CFrame.new(0, 0, 1) * CFrame.Angles(0, math.rad(180), 0)
		        performAttachTeleport(backpackCFrame, tPart)
		    elseif loopFlags.carpet then
		        local carpetCFrame = tPart.CFrame * CFrame.new(0, -3.6, 0) * CFrame.Angles(math.rad(90), 0, 0)
		        performAttachTeleport(carpetCFrame, tPart)
		    end
		    
		    if loopFlags.walkTo then
		        if loopFlags.smartWalk then
		            pathCalcDebounce = pathCalcDebounce + dt
		            if (tPart.Position - lastTargetPos).Magnitude > 5 and pathCalcDebounce > 0.5 then
		                pathCalcDebounce = 0
		                lastTargetPos = tPart.Position
		                task.spawn(function()
		                    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4})
		                    path:ComputeAsync(localCache.Root.Position, tPart.Position)
		                    if path.Status == Enum.PathStatus.Success then
		                        walkPath = path:GetWaypoints()
		                        walkIndex = 2
		                    end
		                end)
		            end
		            if walkPath and walkPath[walkIndex] then
		                local targetPoint = walkPath[walkIndex].Position
		                local dist = (localCache.Root.Position * Vector3.new(1,0,1) - targetPoint * Vector3.new(1,0,1)).Magnitude
		                if dist < 3 then
		                    walkIndex = walkIndex + 1
		                end
		                localCache.Humanoid:MoveTo(targetPoint)
		            end
		        else
		            localCache.Humanoid:MoveTo(tPart.Position)
		        end
		    end
		    
		    if loopFlags.fling then
		        flingTimer = flingTimer + dt
		        if flingTimer > 0.5 and not isFlinging then
		            flingTimer = 0
		            miniFling()
		        end
		    end
		end
		
		RunService.Heartbeat:Connect(centralizedGameLoop)
		
		local function stopAllLoops()
		    for k, _ in pairs(loopFlags) do loopFlags[k] = false end
		    espEnabled = false
		    camera.CameraSubject = localCache.Humanoid or originalCameraSubject
		    removeSelectedEsp()
		    if currentTween then
		        currentTween:Cancel()
		        currentTween = nil
		    end
		    if antiGravityVelocity then
		        antiGravityVelocity:Destroy()
		        antiGravityVelocity = nil
		    end
		    if localCache.Character then
		        for _, part in ipairs(localCache.Character:GetDescendants()) do
		            if part:IsA("BasePart") then
		                part.CanCollide = true
		            end
		        end
		    end
		    if localCache.Humanoid then
		        localCache.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
		    end
		    if headSitSaved then
		        performAttachTeleport(headSitSaved)
		        if localCache.Humanoid then localCache.Humanoid.Sit = false end
		        headSitSaved = nil
		    end
		    if backpackSaved then
		        performAttachTeleport(backpackSaved)
		        if localCache.Humanoid then localCache.Humanoid.Sit = false end
		        backpackSaved = nil
		    end
		end
		
		local function onLocalCharacterAdded(char)
		    task.spawn(function()
		        updateCache(localCache, char)
		        if localCache.Root then
		            FlingData.OldPos = localCache.Root.CFrame
		        end
		        if localCache.Humanoid then
		            camera.CameraSubject = localCache.Humanoid
		        end
		        if toolToggleEnabled then
		            task.delay(1, giveSelectorTool)
		        end
		    end)
		end
		
		localPlayer.CharacterAdded:Connect(onLocalCharacterAdded)
		localPlayer.CharacterRemoving:Connect(function()
		    loopFlags.teleport = false
		    loopFlags.fling = false
		    loopFlags.orbit = false
		    loopFlags.aimLockChar = false
		    updateCache(localCache, nil)
		end)
		
		if localPlayer.Character then
		    onLocalCharacterAdded(localPlayer.Character)
		end
		
		PlayersService.PlayerRemoving:Connect(function(player)
		    if selectedPlayerObject and player == selectedPlayerObject then
		        sendNotification("ZRHUB", player.DisplayName .. " left the game")
		        stopAllLoops()
		        if LoopViewToggle then LoopViewToggle:Set(false) end
		        if LoopFlingToggle then LoopFlingToggle:Set(false) end
		        if AimLockCameraToggle then AimLockCameraToggle:Set(false) end
		        if FaceBangBang then FaceBangBang:Set(false) end
		        if AimLockCharactherToggle then AimLockCharactherToggle:Set(false) end
		        if EspPlayerToggle then EspPlayerToggle:Set(false) end
		        if CarpetPlayerToggle then CarpetPlayerToggle:Set(false) end
		        if TweenPlayerToggle then TweenPlayerToggle:Set(false) end
		        if HeadSitPlayerToggle then HeadSitPlayerToggle:Set(false) end
		        if BackpackPlayerToggle then BackpackPlayerToggle:Set(false) end
		        if OrbitPlayerToggle then OrbitPlayerToggle:Set(false) end
		        if PlayerBangBang then PlayerBangBang:Set(false) end
		        if WalkToPlayerToggle then WalkToPlayerToggle:Set(false) end
		        updateSelectedPlayer(nil)
		    end
		end)
		
		local FlingSelect = Tabs.Fling:Section({Opened = true, Box = true, BoxBorder = true, Title = "Player Selection", Icon = "eye" })
		
		FlingSelect:Paragraph({
		    Title = "Note:", 
		    Desc = "its a method to make your Teleports 0 ping basically no cooldown rly op 100% flings the guy if the player dont use some type of anti fling. Only works for good executors like delta if you use executors that not support it will probably just crash. Xeno not Supported!!",
		    Image = "rbxassetid://84519376661277",
		    ImageSize = 25,
		    Thumbnail = "",
		    ThumbnailSize = 0,
		    Locked = false,
		})
		
		playerDropdown = FlingSelect:Dropdown({
		    Title = "Select Player",
		    SpecialType = "Player",
		    ExcludeLocalPlayer = true,
		    SearchBarEnabled = true,
		    Callback = function(selected)
		        local name = typeof(selected) == "table" and selected.Title or tostring(selected)
		        updateSelectedPlayer(name)
		    end
		})
		
		FlingSelect:Toggle({
		    Title = "Attach Mode",
		    Desc = "its a method to make your Teleports 0 ping basically no cooldown.",
		    Value = false,
		    Callback = function(state) 
		        USE_ATTACH_TELEPORT = state
		    end
		})
		
		FlingSelect:Toggle({
		    Title = "Player Selector Tool",
		    Desc = "Adds a tool to your inventory to select players by clicking/tapping them.",
		    Value = false,
		    Callback = function(state)
		        toolToggleEnabled = state
		        if state then
		            giveSelectorTool()
		        else
		            removeSelectorTool()
		        end
		    end
		})
		
		FlingSelect:Slider({
		    Title = "Prediction Intensity",
		    Desc = "Prediction for the fling to work better and more change to fling people",
		    Step = 0.1,
		    Value = {
		        Min = 0,
		        Max = 5,
		        Default = 1.2,
		    },
		    Flag = 'flingflingpredictionfling',
		    Callback = function(value)
		        PREDICTION_INTENSITY = value
		    end
		})
		
		local FlingOther = Tabs.Fling:Section({Opened = true, Box = true, BoxBorder = true, Title = "Player Actions" })
		
		FlingOther:Button({
		    Title = "Teleport to Player",
		    Callback = function()
		        if not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            return
		        end
		        local tRoot = targetCache.Root
		        local tHead = targetCache.Head
		        local targetPart = tHead or tRoot    
		        if not targetPart then
		            sendNotification("ZRHUB", "Could not find character to teleport.")
		            return
		        end
		        performAttachTeleport(targetPart.CFrame, targetPart)
		    end
		})
		
		FlingOther:Toggle({
		    Title = "Loop Teleport",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.teleport = toggleState
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.teleport = false
		        end
		    end
		})
		
		FlingOther:Button({
		    Title = "Fix fling teleport bug",
		    Callback = function()
		        if localCache.Root then
		            if FlingData.OldPos then
		                FlingData.OldPos = localCache.Root.CFrame
		                sendNotification("ZRHUB", "Teleport bug fixed!")
		            else
		                sendNotification("ZRHUB", "Didn't find any teleport bug?")
		            end
		        end
		    end
		})
		
		FlingOther:Divider()
		
		FlingOther:Slider({
		    Title = "Orbit Speed",
		    Desc = "Speed of the orbit around the selected player",
		    Step = 1,
		    Value = {
		        Min = 1,
		        Max = 30,
		        Default = 8,
		    },
		    Flag = 'flingorbitspeed',
		    Callback = function(value)
		        orbitSpeed = value
		    end
		})
		
		FlingOther:Slider({
		    Title = "Orbit Distance",
		    Desc = "Distance from the selected player in orbit",
		    Step = 1,
		    Flag = 'flingorbitdistance',
		    Value = {
		        Min = 5,
		        Max = 30,
		        Default = 10,
		    },
		    Callback = function(value)
		        orbitDistance = value
		    end
		})
		
		OrbitPlayerToggle = FlingOther:Toggle({
		    Title = "Orbit Player",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.orbit = toggleState
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.orbit = false
		        end
		    end
		})
		
		FlingOther:Divider()
		
		FlingOther:Button({
		    Title = "Fling Player",
		    Callback = function()
		        if not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            return
		        end
		        miniFling()
		    end
		})
		
		LoopFlingToggle = FlingOther:Toggle({
		    Title = "Loop Fling",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.fling = toggleState
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.fling = false
		        end
		    end
		})
		
		FlingOther:Divider()
		
		FlingOther:Button({
		    Title = "View Player (5 sec)",
		    Callback = function()
		        if not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            return
		        end
		        if targetCache.Humanoid then
		            camera.CameraSubject = targetCache.Humanoid
		            task.delay(5, function()
		                if camera.CameraSubject == targetCache.Humanoid then
		                    camera.CameraSubject = localCache.Humanoid or originalCameraSubject
		                end
		            end)
		        else
		            sendNotification("ZRHUB", "Could not find the player's character to view.")
		        end
		    end
		})
		
		LoopViewToggle = FlingOther:Toggle({
		    Title = "Loop View",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.view = toggleState
		        if not toggleState then
		            camera.CameraSubject = localCache.Humanoid or originalCameraSubject
		            return
		        end
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.view = false
		            camera.CameraSubject = localCache.Humanoid or originalCameraSubject
		        end
		    end
		})
		
		FlingOther:Divider()
		
		AimLockCameraToggle = FlingOther:Toggle({
		    Title = "AimLock (Camera)",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.aimLockCam = toggleState
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.aimLockCam = false
		        end
		    end
		})
		
		AimLockCharactherToggle = FlingOther:Toggle({
		    Title = "AimLock (Character)",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.aimLockChar = toggleState
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.aimLockChar = false
		        end
		    end
		})
		
		FlingOther:Divider()
		
		PlayerBangBang = FlingOther:Toggle({
		    Title = "Bang Player",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.bang = toggleState
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.bang = false
		        end
		    end
		})
		
		FaceBangBang = FlingOther:Toggle({
		    Title = "Face Bang Player",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.faceBang = toggleState
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.faceBang = false
		        end
		    end
		})
		
		FlingOther:Slider({
		    Title = "Bang Speed",
		    Desc = "Speed of the thrusting motion",
		    Flag = 'flingbangspeed',
		    Step = 0.1,
		    Value = {
		        Min = 1,
		        Max = 20,
		        Default = 5,
		    },
		    Callback = function(value)
		        bangSpeed = value
		    end
		})
		
		FlingOther:Divider()
		
		WalkToPlayerToggle = FlingOther:Toggle({
		    Title = "Walk to Player",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.walkTo = toggleState
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.walkTo = false
		        end
		    end
		})
		
		FlingOther:Toggle({
		    Title = "Smart Walk Mode",
		    Flag = 'flingsmartwalkmode',
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.smartWalk = toggleState
		    end
		})
		
		FlingOther:Divider()
		
		TweenPlayerToggle = FlingOther:Toggle({
		    Title = "Tween Player",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.tweenPlayer = toggleState
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.tweenPlayer = false
		            return
		        end
		        if toggleState then
		            if localCache.Character then
		                for _, part in ipairs(localCache.Character:GetDescendants()) do
		                    if part:IsA("BasePart") then
		                        part.CanCollide = false
		                    end
		                end
		            end
		            if localCache.Root and not antiGravityVelocity then
		                antiGravityVelocity = Instance.new("BodyVelocity")
		                antiGravityVelocity.Name = "AntiGravity"
		                antiGravityVelocity.MaxForce = Vector3.new(0, math.huge, 0)
		                antiGravityVelocity.Velocity = Vector3.new(0, 0, 0)
		                antiGravityVelocity.Parent = localCache.Root
		            end
		            if localCache.Humanoid then
		                localCache.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		            end
		        else
		            if currentTween then
		                currentTween:Cancel()
		                currentTween = nil
		            end
		            if antiGravityVelocity then
		                antiGravityVelocity:Destroy()
		                antiGravityVelocity = nil
		            end
		            if localCache.Character then
		                for _, part in ipairs(localCache.Character:GetDescendants()) do
		                    if part:IsA("BasePart") then
		                        part.CanCollide = true
		                    end
		                end
		            end
		            if localCache.Humanoid then
		                localCache.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
		            end
		        end
		    end
		})
		
		FlingOther:Slider({
		    Title = "Tween Speed",
		    Step = 1,
		    Flag = 'flingtweenspeed',
		    Value = {
		        Min = 1,
		        Max = 1000,
		        Default = 50,
		    },
		    Callback = function(value)
		        tweenSpeed = value
		    end
		})
		
		FlingOther:Button({
		    Title = "Stop Tween",
		    Callback = function()
		        if currentTween then
		            currentTween:Cancel()
		            currentTween = nil
		        end
		        sendNotification("ZRHUB", "Tween stopped!")
		    end
		})
		
		FlingOther:Divider()
		
		HeadSitPlayerToggle = FlingOther:Toggle({
		    Title = "Head Sit Player",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.headSit = toggleState
		        if not toggleState and headSitSaved then
		            if localCache.Humanoid then localCache.Humanoid.Sit = false end
		            performAttachTeleport(headSitSaved)
		            headSitSaved = nil
		            return
		        end
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.headSit = false
		            return
		        end
		        if toggleState and localCache.Root then
		            headSitSaved = localCache.Root.CFrame
		            if localCache.Humanoid then localCache.Humanoid.Sit = true end
		        end
		    end
		})
		
		BackpackPlayerToggle = FlingOther:Toggle({
		    Title = "Backpack Player",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.backpack = toggleState
		        if not toggleState and backpackSaved then
		            if localCache.Humanoid then localCache.Humanoid.Sit = false end
		            performAttachTeleport(backpackSaved)
		            backpackSaved = nil
		            return
		        end
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.backpack = false
		            return
		        end
		        if toggleState and localCache.Root then
		            backpackSaved = localCache.Root.CFrame
		            if localCache.Humanoid then localCache.Humanoid.Sit = true end
		        end
		    end
		})
		
		CarpetPlayerToggle = FlingOther:Toggle({
		    Title = "Carpet Player",
		    Value = false,
		    Callback = function(toggleState)
		        loopFlags.carpet = toggleState
		        if toggleState and not selectedPlayerObject then
		            sendNotification("ZRHUB", "No One Selected")
		            loopFlags.carpet = false
		        end
		    end
		})
		
		FlingOther:Divider()
		
		EspPlayerToggle = FlingOther:Toggle({
		    Title = "ESP",
		    Value = espEnabled,
		    Callback = function(toggleState)
		        espEnabled = toggleState
		        if espEnabled then
		            createSelectedEsp()
		        else
		            removeSelectedEsp()
		        end
		    end
		})
		
		FlingOther:Toggle({
		    Title = "Notify On Death",
		    Flag = 'flingnotifyondeath',
		    Value = false,
		    Callback = function(toggle)
		        loopFlags.notifyOnDeath = toggle
		        manageDeathNotification()
		    end
		})
		
		FlingOther:Button({
		    Title = "Stop All Loops",
		    Callback = function()
		        stopAllLoops()
		        if LoopViewToggle then LoopViewToggle:Set(false) end
		        if LoopFlingToggle then LoopFlingToggle:Set(false) end
		        if AimLockCameraToggle then AimLockCameraToggle:Set(false) end
		        if FaceBangBang then FaceBangBang:Set(false) end
		        if AimLockCharactherToggle then AimLockCharactherToggle:Set(false) end
		        if EspPlayerToggle then EspPlayerToggle:Set(false) end
		        if CarpetPlayerToggle then CarpetPlayerToggle:Set(false) end
		        if TweenPlayerToggle then TweenPlayerToggle:Set(false) end
		        if HeadSitPlayerToggle then HeadSitPlayerToggle:Set(false) end
		        if BackpackPlayerToggle then BackpackPlayerToggle:Set(false) end
		        if OrbitPlayerToggle then OrbitPlayerToggle:Set(false) end
		        if PlayerBangBang then PlayerBangBang:Set(false) end
		        if WalkToPlayerToggle then WalkToPlayerToggle:Set(false) end
		    end
		})
		
		
		
		
		FlingBlah = Tabs.Fling:Section({
		    Opened = true,
		    Box = true,
		    BoxBorder = true,
		    Title = "Fling",
		    Icon = "utensils"
		})
		
		local flingAuraEnabled = false
		local clickFlingEnabled = false
		local flingAllEnabled = false
		local touchFlingEnabled = false
		local customTouchFlingEnabled = false
		local antiFlingEnabled = false
		local flingPower = 100
		local auraConnections = {}
		
		local function cleanupAuraConnections()
		    for _, conn in pairs(auraConnections) do
		        if conn and conn.Connected then
		            conn:Disconnect()
		        end
		    end
		    table.clear(auraConnections)
		end
		
		local function flingSpecificPlayer(targetPlayer)
		    if not targetPlayer or targetPlayer == localPlayer or not targetPlayer.Character then
		        return
		    end
		    local char = targetPlayer.Character
		    local backupSelected = selectedPlayerObject
		    local backupCache = {
		        Character = targetCache.Character,
		        Root = targetCache.Root,
		        Head = targetCache.Head,
		        Humanoid = targetCache.Humanoid
		    }
		    selectedPlayerObject = targetPlayer
		    updateCache(targetCache, char)
		    miniFling()
		    task.spawn(function()
		        local startTime = tick()
		        while isFlinging and (tick() - startTime < 5) do
		            task.wait(0.2)
		        end
		        selectedPlayerObject = backupSelected
		        updateCache(targetCache, backupCache.Character)
		    end)
		end
		
		local function startFlingAura()
		    cleanupAuraConnections()
		    table.insert(auraConnections, RunService.Heartbeat:Connect(function()
		        if not flingAuraEnabled or not localCache.Root then
		            return
		        end
		        for _, plr in ipairs(PlayersService:GetPlayers()) do
		            if plr ~= localPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
		                local myPos = localCache.Root.Position
		                local tgtPos = plr.Character.HumanoidRootPart.Position
		                if (myPos - tgtPos).Magnitude <= 10 then
		                    flingSpecificPlayer(plr)
		                    task.wait(1)
		                    break
		                end
		            end
		        end
		    end))
		end
		
		local function startFlingAll()
		    cleanupAuraConnections()
		    table.insert(auraConnections, RunService.Heartbeat:Connect(function()
		        if not flingAllEnabled then
		            return
		        end
		        for _, plr in ipairs(PlayersService:GetPlayers()) do
		            if plr ~= localPlayer and plr.Character then
		                flingSpecificPlayer(plr)
		                task.wait(0.5)
		            end
		        end
		    end))
		end
		
		local hiddenfling = false
		local detection
		if game:GetService("ReplicatedStorage"):FindFirstChild("juisdfj0i32i0eidsuf0iok") then
		    hiddenfling = false
		else
		    hiddenfling = false
		    detection = Instance.new("Decal")
		    detection.Name = "juisdfj0i32i0eidsuf0iok"
		    detection.Parent = game:GetService("ReplicatedStorage")
		end
		
		local function hiddenFlingLoop()
		    local hrp, c, vel, movel = nil, nil, nil, 0.1
		    while hiddenfling do
		        RunService.Heartbeat:Wait()
		        local lp = PlayersService.LocalPlayer
		        while hiddenfling and not (c and c.Parent and hrp and hrp.Parent) do
		            RunService.Heartbeat:Wait()
		            c = lp.Character
		            hrp = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
		        end
		        if hiddenfling then
		            vel = hrp.Velocity
		            hrp.Velocity = vel * 9e7 + Vector3.new(0, 9e7, 0)
		            RunService.RenderStepped:Wait()
		            if c and c.Parent and hrp and hrp.Parent then
		                hrp.Velocity = vel
		            end
		            RunService.Stepped:Wait()
		            if c and c.Parent and hrp and hrp.Parent then
		                hrp.Velocity = vel + Vector3.new(0, movel, 0)
		                movel = movel * -1
		            end
		        end
		    end
		end
		
		local function customHiddenFlingLoop()
		    local hrp, c, vel, movel = nil, nil, nil, 0.1
		    while hiddenfling do
		        RunService.Heartbeat:Wait()
		        local lp = PlayersService.LocalPlayer
		        while hiddenfling and not (c and c.Parent and hrp and hrp.Parent) do
		            RunService.Heartbeat:Wait()
		            c = lp.Character
		            hrp = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
		        end
		        if hiddenfling then
		            vel = hrp.Velocity
		            hrp.Velocity = vel * flingPower + Vector3.new(0, 100, 0)
		            RunService.RenderStepped:Wait()
		            if c and c.Parent and hrp and hrp.Parent then
		                hrp.Velocity = vel
		            end
		            RunService.Stepped:Wait()
		            if c and c.Parent and hrp and hrp.Parent then
		                hrp.Velocity = vel + Vector3.new(0, movel, 0)
		                movel = movel * -1
		            end
		        end
		    end
		end
		
		local antiflingConnections = {}
		
		local function NoCollision(PLR)
		    if antiFlingEnabled and PLR.Character then
		        for _, x in pairs(PLR.Character:GetDescendants()) do
		            if x:IsA("BasePart") and x.CanCollide then
		                x.CanCollide = false
		            end
		        end
		    end
		end
		
		local function RestoreCollision()
		    for _, v in pairs(PlayersService:GetPlayers()) do
		        if v ~= localPlayer and v.Character then
		            for _, x in pairs(v.Character:GetDescendants()) do
		                if x:IsA("BasePart") then
		                    x.CanCollide = true
		                end
		            end
		        end
		    end
		end
		
		local function EnableAntiFling()
		    for _, v in pairs(PlayersService:GetPlayers()) do
		        if v ~= localPlayer then
		            local connection = RunService.Stepped:Connect(function()
		                NoCollision(v)
		            end)
		            table.insert(antiflingConnections, connection)
		        end
		    end
		    PlayersService.PlayerAdded:Connect(function(player)
		        if player ~= localPlayer then
		            local connection = RunService.Stepped:Connect(function()
		                NoCollision(player)
		            end)
		            table.insert(antiflingConnections, connection)
		        end
		    end)
		end
		
		local function DisableAntiFling()
		    for _, connection in pairs(antiflingConnections) do
		        if connection.Connected then
		            connection:Disconnect()
		        end
		    end
		    table.clear(antiflingConnections)
		    RestoreCollision()
		end
		
		local function getPlayerFromTarget(target)
		    if target and target.Parent and target.Parent:IsA("Model") then
		        return PlayersService:GetPlayerFromCharacter(target.Parent)
		    end
		end
		
		local mouse = localPlayer:GetMouse()
		
		FlingBlah:Toggle({
		    Title = "Fling Aura",
		    Value = false,
		    Callback = function(toggleState)
		        flingAuraEnabled = toggleState
		        if toggleState then
		            startFlingAura()
		        else
		            cleanupAuraConnections()
		        end
		    end
		})
		
		FlingBlah:Toggle({
		    Title = "Click Fling",
		    Value = false,
		    Callback = function(toggleState)
		        clickFlingEnabled = toggleState
		    end
		})
		
		mouse.Button1Down:Connect(function()
		    if not clickFlingEnabled then
		        return
		    end
		    local targetPlayer = getPlayerFromTarget(mouse.Target)
		    if targetPlayer and targetPlayer ~= localPlayer then
		        flingSpecificPlayer(targetPlayer)
		    end
		end)
		
		UserInputService.TouchTap:Connect(function(touchPositions, gameProcessed)
		    if not clickFlingEnabled or gameProcessed then
		        return
		    end
		    local touchPosition = touchPositions[1]
		    local rayOrigin = camera.CFrame.Position
		    local rayDirection = (camera:ViewportPointToRay(touchPosition.X, touchPosition.Y)).Direction * 500
		    local raycastParams = RaycastParams.new()
		    raycastParams.FilterDescendantsInstances = {localPlayer.Character}
		    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		    local targetPlayer = getPlayerFromTarget(result and result.Instance)
		    if targetPlayer and targetPlayer ~= localPlayer then
		        flingSpecificPlayer(targetPlayer)
		    end
		end)
		
		FlingBlah:Toggle({
		    Title = "Fling All (Buggy?)",
		    Value = false,
		    Callback = function(toggleState)
		        flingAllEnabled = toggleState
		        if toggleState then
		            startFlingAll()
		        else
		            cleanupAuraConnections()
		        end
		    end
		})
		
		FlingBlah:Toggle({
		    Title = "Touch Fling",
		    Value = false,
		    Callback = function(toggleState)
		        touchFlingEnabled = toggleState
		        hiddenfling = toggleState
		        if toggleState then
		            coroutine.wrap(hiddenFlingLoop)()
		        end
		    end
		})
		FlingBlah:Divider()
		FlingBlah:Toggle({
		    Title = "Costum Touch Fling Power",
		    Value = false,
		    Callback = function(toggleState)
		        customTouchFlingEnabled = toggleState
		        hiddenfling = toggleState
		        if toggleState then
		            coroutine.wrap(customHiddenFlingLoop)()
		        end
		    end
		})
		
		FlingBlah:Input({
		    Title = "Fling Power Value",
		    Value = "100",
		    Type = "Input",
		    Flag = 'flingpowervalue',
		    Placeholder = "Enter fling power...",
		    Callback = function(num)
		        flingPower = tonumber(num) or 100
		    end
		})
		
		FlingBlah:Toggle({
		    Title = "Anti Fling",
		    Flag = 'flingantifling',
		    Value = false,
		    Callback = function(toggleState)
		        antiFlingEnabled = toggleState
		        if toggleState then
		            EnableAntiFling()
		        else
		            DisableAntiFling()
		        end
		    end
		})
	end)
end














-- ================ TELEPORT0 TAB0 ================ --
function TeleportTab()
	task.spawn(function()
		TPThings = Tabs.Place:Section({Opened = true, Box = true, BoxBorder = true, Title = "TP Stuff", Icon = "eye" })
		
		TPThings:Button({
		    Title = "Teleport Panel",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/uiTL0dfO/raw"))()
		end
		})
		
		
		TPThings:Button({
		    Title = "TP Frozen Lock",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/yxXqDjA2/raw"))()
		end
		})
		
		TPThings:Button({
		    Title = "TP Dummy",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/oJwPZY4a/raw"))()
		end
		})
		
		TPPlaces = Tabs.Place:Section({Opened = true, Box = true, BoxBorder = true, Title = "Teleport Places", Icon = "map" })
		
		places = {
		    { "Middle Of Map", 139, 440, 32 },
		    { "Prison", 438, 439, -376 },
		    { "Montain", 155, 628, -447 },
		    { "Door 1", 17, 440, -301 },
		    { "Door 2", 290, 440, 361 },
		    { "Corner 1", 29, 442, 488 },
		    { "Corner 2", -261, 442, -248 },
		    { "Corner 3", 263, 442, -456 },
		    { "Corner 4", 566, 442, 274 },
		    { "Counter", -68, 29, 20346 },
		    { "Counter Up", -78, 84, 20354 },
		    { "Atomic Base", 1063, 30, 23006 },
		    { "Atomic Base Up", 1063, 405, 23006 },
		    { "Atomic Slash", 1063, 131, 23006 },
		    { "Atomic Slash Up", 1063, 190, 23006 },
		    { "Little SafeZone", 150, 505, 30 },
		    { "Big SafeZone", 150, 705, 30 },
		    { "Void", 150, -495, 30 },
		    { "Darkness", 0, 900000000005, 0 },
		    { "Smoke", 0, -1, 0 },
		    { "Pixel", 30000000, 30000000, 30000000 },
			{ "Secret Board", 38.473, 87796.758, 32.568 }
		}
		
		for _, place in ipairs(places) do
		    TPPlaces:Button({
		        Title = place[1],
		        Locked = false,
		        Callback = function()
		            local plr = game.Players.LocalPlayer
		            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
		                plr.Character.HumanoidRootPart.CFrame = CFrame.new(place[2], place[3], place[4])
		            end
		        end
		    })
		end
	end)
end

















-- ================ ESP0 TAB0 ================ --
function EspTab()
	task.spawn(function()
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local StarterGui = game:GetService("StarterGui")
		local Workspace = game:GetService("Workspace")
		local TextService = game:GetService("TextService")
		local LocalPlayer = Players.LocalPlayer
		
		local hasDrawing = Drawing ~= nil
		
		local ESP = {
		    Enabled = false,
		    HumanoidRootPart = true,
		    Highlight = true,
		    Tracker = true,
		    KillStreak = true,
		    Ping = true,
		    UltBar = true,
		    Name = true,
		    Health = true,
		    TotalKills = true,
		    TeamCheck = false,
		    OnlySelectedESP = false,
		    SelectedPlayers = {},
		    ESPColor = Color3.fromRGB(255, 255, 255),
		    HighlightColor = Color3.fromRGB(255, 255, 255),
		    ESPTransparency = 0.3,
		    HighlightTransparency = 0,
		    MaxDistance = 500,
		    InfiniteDistance = false,
		    Device = true,
		    DeathCounter = true,
		    UltColor = Color3.fromRGB(255, 215, 0),
		    CounterColor = Color3.fromRGB(255, 45, 45),
		    Distance = true
		}
		
		local ESP_TABLE = {}
		local activeConnections = {}
		local playerCharConns = {}
		local pendingEsp = {}
		local deathCounterObjects = {}
		local deathCounterActive = false
		local mainRenderConnection = nil
		local localHRP = nil
		local selectedDropdown = nil
		local localPlayerDiedConn = nil
		
		local function safeDestroy(obj)
		    if not obj then return end
		    pcall(function()
		        if typeof(obj) == "Instance" then
		            obj:Destroy()
		        end
		    end)
		end
		
		local function safeRemoveDrawing(drawingObj)
		    if not drawingObj then return end
		    pcall(function()
		        drawingObj.Visible = false
		        if drawingObj.Remove then
		            drawingObj:Remove()
		        end
		    end)
		end
		
		local function isPlayerInList(list, name)
		    if type(list) ~= "table" then return false end
		    for k, v in pairs(list) do
		        if v == name or (type(v) == "boolean" and k == name and v == true) then
		            return true
		        end
		    end
		    return false
		end
		
		local function setupLocalPlayerCharacter(character)
		    if not character then return end
		    local hrp = character:WaitForChild("HumanoidRootPart", 5)
		    local humanoid = character:WaitForChild("Humanoid", 5)
		    if hrp then
		        localHRP = hrp
		    end
		    if humanoid then
		        if localPlayerDiedConn then
		            pcall(function() localPlayerDiedConn:Disconnect() end)
		            for i, conn in ipairs(activeConnections) do
		                if conn == localPlayerDiedConn then
		                    table.remove(activeConnections, i)
		                    break
		                end
		            end
		        end
		        localPlayerDiedConn = humanoid.Died:Connect(function()
		            localHRP = nil
		        end)
		        table.insert(activeConnections, localPlayerDiedConn)
		    end
		end
		
		local function disconnectPlayerCharConn(player)
		    local conn = playerCharConns[player]
		    if conn then
		        pcall(function() conn:Disconnect() end)
		        playerCharConns[player] = nil
		    end
		end
		
		local function cleanupPending(player)
		    if pendingEsp[player] then
		        pcall(function() pendingEsp[player]:Disconnect() end)
		        pendingEsp[player] = nil
		    end
		end
		
		local function removeEsp(player)
		    local data = ESP_TABLE[player]
		    if not data then return end
		    ESP_TABLE[player] = nil
		
		    pcall(function()
		        safeDestroy(data.Highlight)
		        safeDestroy(data.HRPBox)
		        safeDestroy(data.Billboard) safeDestroy(data.TagBillboard)
		        safeRemoveDrawing(data.TracerLine)
		    end)
		    pcall(function() data.DiedConn:Disconnect() end)
		    pcall(function() data.DestroyingConn:Disconnect() end)
		    pcall(function() data.MaxHealthConn:Disconnect() end)
		
		    cleanupPending(player)
		end
		
		local function cleanupAllEsp()
		    for player, data in pairs(ESP_TABLE) do
		        if data then
		            pcall(function()
		                safeDestroy(data.Highlight)
		                safeDestroy(data.HRPBox)
		                safeDestroy(data.Billboard) safeDestroy(data.TagBillboard)
		                safeRemoveDrawing(data.TracerLine)
		            end)
		            pcall(function() data.DiedConn:Disconnect() end)
		            pcall(function() data.DestroyingConn:Disconnect() end)
		            pcall(function() data.MaxHealthConn:Disconnect() end)
		        end
		    end
		    ESP_TABLE = {}
		
		    for player, conn in pairs(playerCharConns) do
		        pcall(function() conn:Disconnect() end)
		    end
		    playerCharConns = {}
		
		    for player, conn in pairs(pendingEsp) do
		        pcall(function() conn:Disconnect() end)
		    end
		    pendingEsp = {}
		end
		
		local function cleanupDeathCounter()
		    for player, obj in pairs(deathCounterObjects) do
		        safeDestroy(obj)
		    end
		    deathCounterObjects = {}
		end
		
		local function createEsp(player)
		    if player == LocalPlayer then return end
		    if not ESP.Enabled then return end
		
		    removeEsp(player)
		
		    local character = player.Character
		    if not character then return end
		
		    local humanoid = character:FindFirstChildOfClass("Humanoid")
		    local hrp = character:FindFirstChild("HumanoidRootPart")
		    if not humanoid or not hrp then return end
		
		    local head = character:FindFirstChild("Head")
		
		    local hrpBox = Instance.new("SelectionBox")
		    hrpBox.Name = "HRP_ESP"
		    hrpBox.Adornee = hrp
		    hrpBox.LineThickness = 0.05
		    hrpBox.Color3 = ESP.ESPColor
		    hrpBox.SurfaceTransparency = 1
		    hrpBox.Parent = hrp
		
		    local highlight = Instance.new("Highlight")
		    highlight.Name = "CharHighlight"
		    highlight.FillTransparency = ESP.ESPTransparency
		    highlight.OutlineTransparency = ESP.HighlightTransparency
		    highlight.OutlineColor = ESP.HighlightColor
		    highlight.FillColor = ESP.HighlightColor
		    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		    highlight.Parent = character
		
		    local billboard = Instance.new("BillboardGui")
		    billboard.Name = "ESP_Billboard"
		    billboard.Adornee = head or hrp
		    billboard.AlwaysOnTop = true
		    billboard.MaxDistance = math.huge
		    billboard.ClipsDescendants = true
		    billboard.Parent = head or hrp
		
		    local scheme = (ZR_Library and ZR_Library.Scheme) or {}
		    local container = Instance.new("Frame")
		    container.Name = "Container"
		    container.Size = UDim2.new(1, -4, 1, -4)
		    container.Position = UDim2.fromOffset(2, 2)
		    container.BackgroundTransparency = 0.12
		    container.BackgroundColor3 = scheme.BackgroundColor or Color3.fromRGB(15, 15, 15)
		    container.BorderSizePixel = 0
		    container.Parent = billboard
		
		    local corner = Instance.new("UICorner")
		    corner.CornerRadius = UDim.new(0, 5)
		    corner.Parent = container
		    local cardStroke = Instance.new("UIStroke")
		    cardStroke.Name = "CardStroke"
		    cardStroke.Thickness = 1.3
		    cardStroke.Color = ESP.ESPColor
		    cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		    cardStroke.Parent = container
		    local cardShade = Instance.new("UIGradient")
		    cardShade.Rotation = 90
		    cardShade.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(175, 175, 185))
		    cardShade.Parent = container
		
		    local nameLabel = Instance.new("TextLabel")
		    nameLabel.Name = "NameLabel"
		    nameLabel.Size = UDim2.new(1, -4, 0, 12)
		    nameLabel.Position = UDim2.new(0, 2, 0, 2)
		    nameLabel.BackgroundTransparency = 1
		    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		    nameLabel.TextStrokeTransparency = 0.2
		    nameLabel.Font = Enum.Font.GothamBold
		    nameLabel.TextSize = 10
		    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
		    nameLabel.Text = ""
		    nameLabel.TextScaled = true
		    nameLabel.TextStrokeTransparency = 0.45
		    pcall(function() nameLabel.FontFace = Font.new(scheme.Font and scheme.Font.Family or "rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold) end)
		    local nameLabelFit = Instance.new("UITextSizeConstraint")
		    nameLabelFit.MaxTextSize = 11
		    nameLabelFit.MinTextSize = 5
		    nameLabelFit.Parent = nameLabel
		    nameLabel.Parent = container
		
		    local infoLabel = Instance.new("TextLabel")
		    infoLabel.Name = "InfoLabel"
		    infoLabel.Size = UDim2.new(1, -4, 0, 10)
		    infoLabel.Position = UDim2.new(0, 2, 0, 15)
		    infoLabel.BackgroundTransparency = 1
		    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		    infoLabel.TextStrokeTransparency = 0.2
		    infoLabel.Font = Enum.Font.GothamBold
		    infoLabel.TextSize = 8
		    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
		    infoLabel.TextYAlignment = Enum.TextYAlignment.Center
		    infoLabel.Text = ""
		    infoLabel.TextScaled = true
		    infoLabel.TextStrokeTransparency = 0.45
		    pcall(function() infoLabel.FontFace = Font.new(scheme.Font and scheme.Font.Family or "rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium) end)
		    local infoLabelFit = Instance.new("UITextSizeConstraint")
		    infoLabelFit.MaxTextSize = 9
		    infoLabelFit.MinTextSize = 5
		    infoLabelFit.Parent = infoLabel
		    infoLabel.Parent = container
		
		    local healthContainer = Instance.new("Frame")
		    healthContainer.Name = "HealthContainer"
		    healthContainer.Size = UDim2.new(0.47, 0, 0, 8)
		    healthContainer.Position = UDim2.new(0.02, 0, 0, 27)
		    healthContainer.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
		    healthContainer.BorderSizePixel = 0
		    healthContainer.Parent = container
		    Instance.new("UICorner", healthContainer).CornerRadius = UDim.new(1, 0)
		
		    local healthBar = Instance.new("Frame")
		    healthBar.Name = "HealthBar"
		    healthBar.Size = UDim2.new(1, 0, 1, 0)
		    healthBar.BackgroundColor3 = Color3.fromRGB(30, 200, 80)
		    healthBar.BorderSizePixel = 0
		    healthBar.Parent = healthContainer
		    Instance.new("UICorner", healthBar).CornerRadius = UDim.new(1, 0)
		
		    local ultContainer = Instance.new("Frame")
		    ultContainer.Name = "UltContainer"
		    ultContainer.Size = UDim2.new(0.47, 0, 0, 8)
		    ultContainer.Position = UDim2.new(0.51, 0, 0, 27)
		    ultContainer.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
		    ultContainer.BorderSizePixel = 0
		    ultContainer.Parent = container
		    Instance.new("UICorner", ultContainer).CornerRadius = UDim.new(1, 0)
		
		    local ultBar = Instance.new("Frame")
		    ultBar.Name = "UltBar"
		    ultBar.Size = UDim2.new(1, 0, 1, 0)
		    ultBar.BackgroundColor3 = Color3.fromRGB(255, 180, 20)
		    ultBar.BorderSizePixel = 0
		    ultBar.Parent = ultContainer
		    Instance.new("UICorner", ultBar).CornerRadius = UDim.new(1, 0)
		
		    local tagBillboard = Instance.new("BillboardGui")
		    tagBillboard.Name = "ESP_Tag"
		    tagBillboard.Adornee = head or hrp
		    tagBillboard.AlwaysOnTop = true
		    tagBillboard.MaxDistance = math.huge
		    tagBillboard.Size = UDim2.fromOffset(170, 90)
		    tagBillboard.Enabled = false
		    tagBillboard.Parent = head or hrp
		    local tagLabel = Instance.new("TextLabel")
		    tagLabel.Name = "Tag"
		    tagLabel.BackgroundTransparency = 1
		    tagLabel.Size = UDim2.new(1, 0, 0, 22)
		    tagLabel.Font = Enum.Font.Arcade
		    tagLabel.TextScaled = true
		    tagLabel.TextStrokeTransparency = 0
		    tagLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		    tagLabel.Text = ""
		    tagLabel.Parent = tagBillboard

		    local tracerLine = nil
		    if hasDrawing then
		        tracerLine = Drawing.new("Line")
		        tracerLine.Visible = false
		        tracerLine.Thickness = 1.5
		        tracerLine.Color = ESP.ESPColor
		        tracerLine.Transparency = 1
		    end
		
		    local cache = {
		        lastNameText = "",
		        lastInfoText = "",
		        lastHealthPercent = -1,
		        lastUltPercent = -1,
		        lastHealthColor = nil,
		        lastScale = 0,
		        lastLayoutHash = -1,
		        lastHRPColor = nil,
		        lastHighlightColor = nil,
		        lastFillTrans = -1,
		        lastOutlineTrans = -1,
		        lastHeadPos = nil,
		        lastBillboardEnabled = nil,
		        lastHighlightEnabled = nil,
		        lastHRPBoxVisible = nil,
		        lastStudsOffset = nil,
		        lastDynamicMinW = -1,
		        maxHealth = humanoid.MaxHealth
		    }
		
		    local diedConn = humanoid.Died:Connect(function()
		        removeEsp(player)
		    end)
		
		    local destroyingConn = character.Destroying:Connect(function()
		        removeEsp(player)
		    end)
		
		    local maxHealthConn = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		        cache.maxHealth = humanoid.MaxHealth
		    end)
		
		    ESP_TABLE[player] = {
		        Player = player,
		        Character = character,
		        Humanoid = humanoid,
		        HRP = hrp,
		        Head = head,
		        Highlight = highlight,
		        HRPBox = hrpBox,
		        Billboard = billboard,
		        Container = container,
		        CardStroke = cardStroke,
		        TagBillboard = tagBillboard,
		        TagLabel = tagLabel,
		        NameLabel = nameLabel,
		        InfoLabel = infoLabel,
		        HealthContainer = healthContainer,
		        HealthBar = healthBar,
		        UltContainer = ultContainer,
		        UltBar = ultBar,
		        TracerLine = tracerLine,
		        Cache = cache,
		        DiedConn = diedConn,
		        DestroyingConn = destroyingConn,
		        MaxHealthConn = maxHealthConn,
		    }
		end
		
		local function setupCharacterEsp(player, character)
		    if player == LocalPlayer then return end
		    if not ESP.Enabled then return end
		
		    cleanupPending(player)
		
		    local neededCount = 2
		    local foundCount = 0
		
		    if character:FindFirstChild("HumanoidRootPart") then foundCount = foundCount + 1 end
		    if character:FindFirstChildOfClass("Humanoid") then foundCount = foundCount + 1 end
		
		    if foundCount >= neededCount and ESP.Enabled and player.Parent then
		        pcall(function() createEsp(player) end)
		        return
		    end
		
		    local conn
		    conn = character.ChildAdded:Connect(function(child)
		        if not ESP.Enabled then
		            conn:Disconnect()
		            pendingEsp[player] = nil
		            return
		        end
		        if child.Name == "HumanoidRootPart" or child:IsA("Humanoid") then
		            foundCount = foundCount + 1
		            if foundCount >= neededCount then
		                conn:Disconnect()
		                pendingEsp[player] = nil
		                if ESP.Enabled and player.Parent then
		                    pcall(function() createEsp(player) end)
		                end
		            end
		        end
		    end)
		    pendingEsp[player] = conn
		
		    task.defer(function()
		        if not ESP.Enabled then return end
		        if not ESP_TABLE[player] and player.Parent and player.Character == character then
		            if character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid") then
		                pcall(function() createEsp(player) end)
		            end
		        end
		    end)
		end
		
		local function updateEsp(player, data)
		    if not ESP.Enabled then return end
		    if not player.Parent then
		        removeEsp(player)
		        return
		    end
		
		    local character = data.Character
		    if not character or not character.Parent then
		        if data.TracerLine then data.TracerLine.Visible = false end
		        removeEsp(player)
		        return
		    end
		
		    local humanoid = data.Humanoid
		    local hrp = data.HRP
		    if not humanoid or not humanoid.Parent or humanoid.Health <= 0 then
		        if data.TracerLine then data.TracerLine.Visible = false end
		        removeEsp(player)
		        return
		    end
		
		    local isSelected = isPlayerInList(ESP.SelectedPlayers, player.Name)
		    if ESP.OnlySelectedESP and not isSelected then
		        if data.TracerLine then data.TracerLine.Visible = false end
		        if data.Billboard then data.Billboard.Enabled = false end
		        if data.Highlight then data.Highlight.Enabled = false end
		        if data.HRPBox then data.HRPBox.Visible = false end
		        return
		    end
		
		    if not localHRP or not localHRP.Parent then
		        if data.TracerLine then data.TracerLine.Visible = false end
		        return
		    end
		
		    local camera = Workspace.CurrentCamera
		    if not camera or not camera.Parent then
		        if data.TracerLine then data.TracerLine.Visible = false end
		        return
		    end
		
		    local distance = (localHRP.Position - hrp.Position).Magnitude
		
		    local isEnemy = true
		    if ESP.TeamCheck then
		        local myTeam = LocalPlayer.Team
		        local theirTeam = player.Team
		        if myTeam and theirTeam then
		            isEnemy = myTeam ~= theirTeam
		        end
		    end
		
		    local shouldShow = isEnemy and (ESP.InfiniteDistance or distance <= ESP.MaxDistance)
		
		    if not shouldShow then
		        if data.Billboard and data.Billboard.Enabled then data.Billboard.Enabled = false end
		        if data.Highlight and data.Highlight.Enabled then data.Highlight.Enabled = false end
		        if data.HRPBox and data.HRPBox.Visible then data.HRPBox.Visible = false end
		        if data.TracerLine then data.TracerLine.Visible = false end
		        return
		    end
		
		    -- ult / death counter: card, box, tracer and highlight change colour, and a tag shows above them
		    local hasCounter = character:FindFirstChild("Counter") ~= nil
		    local ulted = character:GetAttribute("Ulted") == true
		    local stateColor = nil
		    if ESP.DeathCounter then
		        if hasCounter then stateColor = ESP.CounterColor elseif ulted then stateColor = ESP.UltColor end
		    end
		    local boxColor = stateColor or ESP.ESPColor
		    local hlColor = stateColor or ESP.HighlightColor
		    if data.TagBillboard then
		        local txt = stateColor and (hasCounter and "DEATH COUNTER" or "ULT") or nil
		        if (txt ~= nil) ~= data.TagBillboard.Enabled then data.TagBillboard.Enabled = txt ~= nil end
		        if txt then
		            data.TagLabel.Text = txt
		            data.TagLabel.TextColor3 = stateColor
		            data.TagLabel.TextTransparency = (math.sin(os.clock() * 5) + 1) * 0.12
		            data.TagBillboard.Adornee = data.Billboard.Adornee
		            data.TagBillboard.StudsOffset = data.Billboard.StudsOffset
		            local h = data.Billboard.Size.Y.Offset
		            data.TagBillboard.Size = UDim2.fromOffset(170, h + 60)
		        end
		    end

		    if ESP.Highlight and shouldShow then
		        if not data.Highlight or not data.Highlight.Parent then
		            pcall(function()
		                if data.Highlight then
		                    data.Highlight:Destroy()
		                end
		            end)
		            local newHighlight = Instance.new("Highlight")
		            newHighlight.Name = "CharHighlight"
		            newHighlight.FillTransparency = ESP.ESPTransparency
		            newHighlight.OutlineTransparency = ESP.HighlightTransparency
		            newHighlight.OutlineColor = ESP.HighlightColor
		            newHighlight.FillColor = ESP.HighlightColor
		            newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		            newHighlight.Parent = character
		            data.Highlight = newHighlight
		            data.Cache.lastHighlightColor = nil
		            data.Cache.lastFillTrans = -1
		            data.Cache.lastOutlineTrans = -1
		            data.Cache.lastHighlightEnabled = nil
		        end
		    end
		
		    if ESP.Tracker and data.TracerLine then
		        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
		        if onScreen then
		            data.TracerLine.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
		            data.TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
		            data.TracerLine.Color = boxColor
		            data.TracerLine.Visible = true
		        else
		            data.TracerLine.Visible = false
		        end
		    elseif data.TracerLine then
		        data.TracerLine.Visible = false
		    end
		
		    local currentHead = character:FindFirstChild("Head")
		    if currentHead then
		        if data.Cache.lastHeadPos ~= currentHead then
		            data.Billboard.Adornee = currentHead
		            data.Head = currentHead
		            data.Cache.lastHeadPos = currentHead
		        end
		        if data.Cache.lastStudsOffset ~= Vector3.new(0, 2.5, 0) then
		            data.Billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		            data.Cache.lastStudsOffset = Vector3.new(0, 2.5, 0)
		        end
		    else
		        if data.Cache.lastHeadPos ~= nil then
		            data.Billboard.Adornee = hrp
		            data.Head = nil
		            data.Cache.lastHeadPos = nil
		        end
		        if data.Cache.lastStudsOffset ~= Vector3.new(0, 4, 0) then
		            data.Billboard.StudsOffset = Vector3.new(0, 4, 0)
		            data.Cache.lastStudsOffset = Vector3.new(0, 4, 0)
		        end
		    end
		
		    local nameStr = ""
		    if ESP.Name then
		        nameStr = (player.DisplayName or player.Name) .. " (" .. player.Name .. ")"
		    end
		
		    local infoParts = {}
		    if ESP.Distance then
		        table.insert(infoParts, math.floor(distance) .. "m")
		    end
		    if ESP.Ping then
		        local ping = player:GetAttribute("Ping")
		        if ping ~= nil then
		            table.insert(infoParts, math.floor(tonumber(ping) or 0) .. "ms")
		        end
		    end
		    if ESP.KillStreak then
		        local streak = 0
		        pcall(function()
		            local live = Workspace:FindFirstChild("Live")
		            if live then
		                local model = live:FindFirstChild(player.Name)
		                if model then streak = model:GetAttribute("CurrentStreak") or 0 end
		            end
		        end)
		        if streak > 0 then
		            table.insert(infoParts, streak .. " strk")
		        end
		    end
		    if ESP.Device then
		        local device = "PC"
		        pcall(function()
		            if player:GetAttribute("Mobile") then device = "Mobile"
		            elseif player:GetAttribute("Xbox") then device = "Xbox"
		            elseif player:GetAttribute("VR") then device = "VR"
		            elseif player:GetAttribute("Console") then device = "Console" end
		        end)
		        table.insert(infoParts, device)
		    end
		    if ESP.TotalKills then
		        local leaderstats = player:FindFirstChild("leaderstats")
		        if leaderstats then
		            local tk = leaderstats:FindFirstChild("Total Kills")
		            if tk then
		                table.insert(infoParts, tk.Value .. " Kills")
		            end
		        end
		    end
		    local infoStr = table.concat(infoParts, " | ")
		
		    if ESP.Name and data.NameLabel and data.Cache.lastNameText ~= nameStr then
		        data.NameLabel.Text = nameStr
		        data.Cache.lastNameText = nameStr
		    end
		    if data.InfoLabel and data.Cache.lastInfoText ~= infoStr then
		        data.InfoLabel.Text = infoStr
		        data.Cache.lastInfoText = infoStr
		    end
		
		    local nameW = 0
		    local infoW = 0
		    if ESP.Name and nameStr ~= "" then
		        local size = Vector2.new(0, 10)
		        nameW = TextService:GetTextSize(nameStr, 10, Enum.Font.GothamBold, size).X
		    end
		    if infoStr ~= "" then
		        infoW = TextService:GetTextSize(infoStr, 8, Enum.Font.GothamBold, Vector2.new(0, 8)).X
		    end
		    local textWidth = math.max(nameW, infoW)
		    local dynamicMinW = math.max(70, math.ceil(textWidth + 14))
		
		    local hash = 0
		    if ESP.Name then hash = hash + 1 end
		    if ESP.Distance then hash = hash + 2 end
		    if ESP.Ping then hash = hash + 4 end
		    if ESP.KillStreak then hash = hash + 8 end
		    if ESP.Health then hash = hash + 16 end
		    if ESP.UltBar then hash = hash + 32 end
		    if ESP.TotalKills then hash = hash + 64 end
		    if ESP.Device then hash = hash + 128 end
		
		    local bbEnabled = hash > 0
		    if data.Cache.lastBillboardEnabled ~= bbEnabled then
		        data.Billboard.Enabled = bbEnabled
		        data.Cache.lastBillboardEnabled = bbEnabled
		    end
		    if data.Cache.lastHighlightEnabled ~= ESP.Highlight then
		        data.Highlight.Enabled = ESP.Highlight
		        data.Cache.lastHighlightEnabled = ESP.Highlight
		    end
		    if data.Cache.lastHRPBoxVisible ~= ESP.HumanoidRootPart then
		        data.HRPBox.Visible = ESP.HumanoidRootPart
		        data.Cache.lastHRPBoxVisible = ESP.HumanoidRootPart
		    end
		
		    local scale = math.clamp(1 - (distance / 2000), 0.4, 1)
		
		    if hash ~= data.Cache.lastLayoutHash or math.abs(scale - data.Cache.lastScale) >= 0.01 or dynamicMinW ~= data.Cache.lastDynamicMinW then
		        data.Cache.lastLayoutHash = hash
		        data.Cache.lastScale = scale
		        data.Cache.lastDynamicMinW = dynamicMinW
		
		        local pad = 2
		        local rowH = 12
		        local barH = 8
		        local gap = 1
		        local hasInfo = ESP.Distance or ESP.Ping or ESP.KillStreak or ESP.TotalKills or ESP.Device
		        local hasBars = ESP.Health or ESP.UltBar
		        local hasName = ESP.Name
		
		        local totalH = pad
		        if hasName then totalH = totalH + rowH + gap end
		        if hasInfo then totalH = totalH + 10 + gap end
		        if hasBars then totalH = totalH + barH + gap end
		        totalH = totalH + pad
		
		        local minW = dynamicMinW
		        if hasBars then minW = math.max(minW, 80) end
		
		        local baseW = minW
		        local baseH = math.max(totalH, 20)
		
		        data.Billboard.Size = UDim2.new(0, math.floor(baseW * scale), 0, math.floor(baseH * scale))
		
		        local y = pad
		
		        if hasName then
		            data.NameLabel.Visible = true
		            data.NameLabel.Size = UDim2.new(1, -pad*2, 0, math.floor(rowH * scale))
		            data.NameLabel.Position = UDim2.new(0, pad, 0, y)
		            data.NameLabel.TextSize = math.max(7, math.floor(10 * scale))
		            y = y + math.floor(rowH * scale) + gap
		        else
		            data.NameLabel.Visible = false
		        end
		
		        if hasInfo then
		            data.InfoLabel.Visible = true
		            data.InfoLabel.Size = UDim2.new(1, -pad*2, 0, math.floor(10 * scale))
		            data.InfoLabel.Position = UDim2.new(0, pad, 0, y)
		            data.InfoLabel.TextSize = math.max(7, math.floor(8 * scale))
		            y = y + math.floor(10 * scale) + gap
		        else
		            data.InfoLabel.Visible = false
		        end
		
		        if hasBars then
		            local barScaleH = math.max(4, math.floor(barH * scale))
		            local bothBars = ESP.Health and ESP.UltBar
		            if ESP.Health then
		                data.HealthContainer.Visible = true
		                data.HealthContainer.Size = UDim2.new(bothBars and 0.47 or 0.96, 0, 0, barScaleH)
		                data.HealthContainer.Position = UDim2.new(0.02, 0, 0, y)
		            else
		                data.HealthContainer.Visible = false
		            end
		            if ESP.UltBar then
		                data.UltContainer.Visible = true
		                data.UltContainer.Size = UDim2.new(bothBars and 0.47 or 0.96, 0, 0, barScaleH)
		                data.UltContainer.Position = UDim2.new(bothBars and 0.51 or 0.02, 0, 0, y)
		            else
		                data.UltContainer.Visible = false
		            end
		        else
		            data.HealthContainer.Visible = false
		            data.UltContainer.Visible = false
		        end
		    end
		
		    if data.Cache.lastHRPColor ~= boxColor then
		        if data.HRPBox then
		            data.HRPBox.Color3 = boxColor
		        end
		        if data.CardStroke then
		            data.CardStroke.Color = boxColor
		        end
		        data.Cache.lastHRPColor = boxColor
		    end
		
		    if data.Highlight and data.Cache.lastHighlightColor ~= hlColor then
		        data.Highlight.OutlineColor = hlColor
		        data.Highlight.FillColor = hlColor
		        data.Cache.lastHighlightColor = hlColor
		    end
		
		    if data.Highlight and data.Cache.lastFillTrans ~= ESP.ESPTransparency then
		        data.Highlight.FillTransparency = ESP.ESPTransparency
		        data.Cache.lastFillTrans = ESP.ESPTransparency
		    end
		
		    if data.Highlight and data.Cache.lastOutlineTrans ~= ESP.HighlightTransparency then
		        data.Highlight.OutlineTransparency = ESP.HighlightTransparency
		        data.Cache.lastOutlineTrans = ESP.HighlightTransparency
		    end
		
		    if ESP.Health and humanoid.Health > 0 and data.HealthBar then
		        local hp = humanoid.Health
		        local max = data.Cache.maxHealth
		        local pct = math.clamp(hp / max, 0, 1)
		        if math.abs(data.Cache.lastHealthPercent - pct) > 0.001 then
		            data.HealthBar.Size = UDim2.new(pct, 0, 1, 0)
		            data.Cache.lastHealthPercent = pct
		        end
		        local hpColor = Color3.fromHSV(pct * 0.33, 1, 1)
		        if data.Cache.lastHealthColor ~= hpColor then
		            data.HealthBar.BackgroundColor3 = hpColor
		            data.Cache.lastHealthColor = hpColor
		        end
		    end
		
		    if ESP.UltBar and data.UltBar then
		        local ultVal = player:GetAttribute("Ultimate")
		        if ultVal ~= nil then
		            local pct = math.clamp(tonumber(ultVal) / 100, 0, 1)
		            if math.abs(data.Cache.lastUltPercent - pct) > 0.001 then
		                data.UltBar.Size = UDim2.new(pct, 0, 1, 0)
		                data.Cache.lastUltPercent = pct
		            end
		        end
		    end
		end
		
		local function startMainRenderLoop()
		    if mainRenderConnection then return end
		    mainRenderConnection = RunService.RenderStepped:Connect(function()
		        if not ESP.Enabled then return end
		        for player, data in pairs(ESP_TABLE) do
		            if data and player.Parent then
		                pcall(function()
		                    updateEsp(player, data)
		                end)
		            end
		        end
		    end)
		    table.insert(activeConnections, mainRenderConnection)
		end
		
		local function stopMainRenderLoop()
		    if mainRenderConnection then
		        pcall(function() mainRenderConnection:Disconnect() end)
		        mainRenderConnection = nil
		    end
		end
		
		local function checkDeathCounterPlayers()
		    do return end -- replaced: ult / death counter now colour the ESP and show a tag
		    for player, data in pairs(ESP_TABLE) do
		        if data then
		            local character = data.Character
		            if not character or not character.Parent then
		                local obj = deathCounterObjects[player]
		                if obj then
		                    safeDestroy(obj)
		                    deathCounterObjects[player] = nil
		                end
		            else
		                local existing = deathCounterObjects[player]
		                if existing and (not existing.Parent or not existing.Adornee or not existing.Adornee.Parent) then
		                    safeDestroy(existing)
		                    deathCounterObjects[player] = nil
		                    existing = nil
		                end
		
		                if character:FindFirstChild("Counter") then
		                    local head = character:FindFirstChild("Head")
		                    if not existing and head then
		                        local billboard = Instance.new("BillboardGui")
		                        billboard.Name = "DeathCounterESP"
		                        billboard.Size = UDim2.new(6, 0, 6, 0)
		                        billboard.Adornee = head
		                        billboard.AlwaysOnTop = true
		                        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
		                        billboard.Parent = head
		
		                        local skullLabel = Instance.new("TextLabel")
		                        skullLabel.Name = "SkullLabel"
		                        skullLabel.Size = UDim2.new(1, 0, 1, 0)
		                        skullLabel.BackgroundTransparency = 1
		                        skullLabel.Text = "\240\159\146\128"
		                        skullLabel.TextScaled = true
		                        skullLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		                        skullLabel.Font = Enum.Font.FredokaOne
		                        skullLabel.Parent = billboard
		
		                        deathCounterObjects[player] = billboard
		                    elseif existing and head and existing.Adornee ~= head then
		                        existing.Adornee = head
		                        existing.Parent = head
		                    end
		                elseif existing then
		                    safeDestroy(existing)
		                    deathCounterObjects[player] = nil
		                end
		            end
		        end
		    end
		end
		
		local function deathCounterLoop()
		    deathCounterActive = true
		    while deathCounterActive and ESP.Enabled and ESP.DeathCounter do
		        checkDeathCounterPlayers()
		        task.wait(1)
		    end
		    deathCounterActive = false
		end
		
		local function startDeathCounterLoop()
		    if deathCounterActive then return end
		    task.spawn(deathCounterLoop)
		end
		
		local function stopDeathCounterLoop()
		    deathCounterActive = false
		    cleanupDeathCounter()
		end
		
		local function onPlayerCharacterAdded(player)
		    if player == LocalPlayer then return end
		    if not ESP.Enabled then return end
		    disconnectPlayerCharConn(player)
		
		    local charConn = player.CharacterAdded:Connect(function(character)
		        if not ESP.Enabled then return end
		        removeEsp(player)
		        setupCharacterEsp(player, character)
		    end)
		    playerCharConns[player] = charConn
		end
		
		local function onPlayerAdded(player)
		    if player == LocalPlayer then return end
		    if not ESP.Enabled then return end
		    if player.Character then
		        setupCharacterEsp(player, player.Character)
		    end
		    onPlayerCharacterAdded(player)
		end
		
		local function onPlayerRemoving(player)
		    removeEsp(player)
		    if deathCounterObjects[player] then
		        safeDestroy(deathCounterObjects[player])
		        deathCounterObjects[player] = nil
		    end
		    disconnectPlayerCharConn(player)
		
		    if selectedDropdown and selectedDropdown.Set then
		        local newList = {}
		        for _, name in ipairs(ESP.SelectedPlayers) do
		            if name ~= player.Name then
		                table.insert(newList, name)
		            end
		        end
		        for k, v in pairs(ESP.SelectedPlayers) do
		            if type(v) == "boolean" and v == true and k ~= player.Name and not table.find(newList, k) then
		                table.insert(newList, k)
		            end
		        end
		        selectedDropdown:Set(newList)
		    end
		end
		
		local function enableEspSystem()
		    if ESP.Enabled then return end
		    ESP.Enabled = true
		
		    if LocalPlayer.Character then
		        setupLocalPlayerCharacter(LocalPlayer.Character)
		    end
		    local charAddedConn = LocalPlayer.CharacterAdded:Connect(setupLocalPlayerCharacter)
		    table.insert(activeConnections, charAddedConn)
		
		    table.insert(activeConnections, Players.PlayerAdded:Connect(onPlayerAdded))
		    table.insert(activeConnections, Players.PlayerRemoving:Connect(onPlayerRemoving))
		
		    table.insert(activeConnections, LocalPlayer:GetPropertyChangedSignal("Parent"):Connect(function()
		        if not LocalPlayer.Parent then
		            disableEspSystem()
		        end
		    end))
		
		    for _, plr in ipairs(Players:GetPlayers()) do
		        if plr ~= LocalPlayer then
		            if plr.Character then
		                setupCharacterEsp(plr, plr.Character)
		            end
		            onPlayerCharacterAdded(plr)
		        end
		    end
		
		    startMainRenderLoop()
		    if ESP.DeathCounter then
		        startDeathCounterLoop()
		    end
		end
		
		local function disableEspSystem()
		    ESP.Enabled = false
		    stopMainRenderLoop()
		    cleanupAllEsp()
		    cleanupDeathCounter()
		
		    for _, conn in ipairs(activeConnections) do
		        pcall(function() conn:Disconnect() end)
		    end
		    activeConnections = {}
		
		    for player, conn in pairs(playerCharConns) do
		        pcall(function() conn:Disconnect() end)
		    end
		    playerCharConns = {}
		
		    for player, conn in pairs(pendingEsp) do
		        pcall(function() conn:Disconnect() end)
		    end
		    pendingEsp = {}
		
		    stopDeathCounterLoop()
		    localHRP = nil
		
		    if localPlayerDiedConn then
		        pcall(function() localPlayerDiedConn:Disconnect() end)
		        localPlayerDiedConn = nil
		    end
		end
		
		if not hasDrawing then
		    pcall(function()
		        StarterGui:SetCore("SendNotification", {
		            Title = "ZRHUB",
		            Text = "Drawing API not supported on this executor. Tracer lines will be disabled.",
		            Duration = 8
		        })
		    end)
		end
		
		local espSection = Tabs.ESP:Section({ Title = "ESPs", Desc = "Toggle ESP features", Icon = "eye", Opened = true, Box = true, BoxBorder = true })
		
		espSection:Toggle({
		    Title = "Enable ESP",
		    Type = "Toggle",
		    Value = false,
		    Callback = function(state)
		        if state then
		            enableEspSystem()
		        else
		            disableEspSystem()
		        end
		    end
		})
		
		espSection:Divider({})
		
		espSection:Toggle({Title = "HumanoidRootPart", Type = "Checkbox", Value = true, Callback = function(state) ESP.HumanoidRootPart = state end})
		espSection:Toggle({Title = "Highlight", Type = "Checkbox", Value = true, Callback = function(state) ESP.Highlight = state end})
		espSection:Toggle({Title = "Tracker (Tracer Line)", Type = "Checkbox", Value = true, Callback = function(state) ESP.Tracker = state end})
		espSection:Toggle({Title = "Kill Streak", Type = "Checkbox", Value = true, Callback = function(state) ESP.KillStreak = state end})
		espSection:Toggle({Title = "Kills", Type = "Checkbox", Value = true, Callback = function(state) ESP.TotalKills = state end})
		espSection:Toggle({Title = "Ping", Type = "Checkbox", Value = true, Callback = function(state) ESP.Ping = state end})
		espSection:Toggle({Title = "Ult Bar", Type = "Checkbox", Value = true, Callback = function(state) ESP.UltBar = state end})
		espSection:Toggle({Title = "Name", Type = "Checkbox", Value = true, Callback = function(state) ESP.Name = state end})
		espSection:Toggle({Title = "Health", Type = "Checkbox", Value = true, Callback = function(state) ESP.Health = state end})
		espSection:Toggle({Title = "Device", Type = "Checkbox", Value = true, Callback = function(state) ESP.Device = state end})
		espSection:Toggle({Title = "Team Check", Type = "Checkbox", Value = false, Callback = function(state) ESP.TeamCheck = state end})
		espSection:Toggle({Title = "Distance", Type = "Checkbox", Value = true, Callback = function(state) ESP.Distance = state end})
		espSection:Toggle({
		    Title = "Ult / Death Counter Alerts",
		    Desc = "Yellow box + ULT tag when they use ult, red box + DEATH COUNTER tag when they use death counter",
		    Type = "Toggle",
		    Value = true,
		    Callback = function(state)
		        ESP.DeathCounter = state
		        if state and ESP.Enabled then
		            startDeathCounterLoop()
		        elseif not state then
		            stopDeathCounterLoop()
		            cleanupDeathCounter()
		        end
		    end
		})
		
		local SettingsSection = Tabs.ESP:Section({ Title = "Esp settings", Desc = "Manage selected players", Icon = "filter", Opened = true, Box = true, BoxBorder = true })
		
		SettingsSection:Colorpicker({Title = "ESP Color", Default = Color3.fromRGB(255, 255, 255), Transparency = 0, Callback = function(color) ESP.ESPColor = color end})
		SettingsSection:Colorpicker({Title = "Highlight Color", Default = Color3.fromRGB(255, 255, 255), Transparency = 0, Callback = function(color) ESP.HighlightColor = color end})
		SettingsSection:Colorpicker({Title = "Ult Color", Default = Color3.fromRGB(255, 215, 0), Callback = function(color) ESP.UltColor = color end})
		SettingsSection:Colorpicker({Title = "Death Counter Color", Default = Color3.fromRGB(255, 45, 45), Callback = function(color) ESP.CounterColor = color end})
		SettingsSection:Slider({Title = "ESP Transparency", Value = {Min = 0, Max = 100, Default = 30}, Step = 5, IsTooltip = true, Callback = function(value) ESP.ESPTransparency = value / 100 end})
		SettingsSection:Slider({Title = "Highlight Transparency", Value = {Min = 0, Max = 100, Default = 0}, Step = 5, IsTooltip = true, Callback = function(value) ESP.HighlightTransparency = value / 100 end})
		SettingsSection:Slider({Title = "Max Distance", Value = {Min = 50, Max = 1000, Default = 500}, Step = 50, IsTooltip = true, Callback = function(value) ESP.MaxDistance = value end})
		SettingsSection:Toggle({Title = "Infinite Distance", Type = "Toggle", Value = false, Icon = "infinity", Callback = function(state) ESP.InfiniteDistance = state end})
		
		SettingsSection:Divider({})
		
		SettingsSection:Toggle({
		   Title = "Selected Players Only",
		   Value = false,
		   Flag = "only_selected_esp",
		   Callback = function(value)
		       ESP.OnlySelectedESP = value
		   end
		})
		
		selectedDropdown = SettingsSection:Dropdown({
		   Title = "Selected ESP Targets",
		   Flag = "selected_targets",
		   Multi = true,
		   Values = {},
		   Value = {},
		   Callback = function(value)
		       ESP.SelectedPlayers = value
		   end
		})
		
		SettingsSection:Button({
		   Title = "Refresh Player List",
		   Icon = "refresh-cw",
		   Callback = function()
		       local all = {}
		       for _, p in ipairs(Players:GetPlayers()) do
		           if p ~= LocalPlayer then
		               table.insert(all, p.Name)
		           end
		       end
		       if selectedDropdown and selectedDropdown.Refresh then
		           selectedDropdown:Refresh(all)
		       end
		   end
		})
	end)
end
















-- ================ MOVESET0 TAB0 ================ --
function AntiBanTab()
	task.spawn(function()
		Vars = {
		    AnticheatConn = nil
		}
		
		Options = {
		    AvoidBanMethod = { Value = "Kick" },
		    RejoinDelay = { Value = "3" }
		}
		
		function Rejoin(delayTime)
		    task.wait(delayTime or 3)
		    if #Players:GetPlayers() <= 1 then
		        Players.LocalPlayer:Kick("Rejoining...")
		        task.wait()
		        TeleportService:Teleport(game.PlaceId, LocalPlayer)
		    else
		        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		    end
		end
		
		function HandleSafetyAction(reason)
		    Notify("Anticheat Flagged", reason)
		    local method = Options.AvoidBanMethod.Value
		    
		    if method == "Auto Leave" or method == "Kick" then
		        LocalPlayer:Kick("[Anticheat] Safety Kick: " .. reason)
		    elseif method == "Auto Rejoin" then
		        Rejoin(tonumber(Options.RejoinDelay.Value))
		    elseif method == "Warn" then
		        warn("[Anticheat] Flagged: " .. reason)
		    end
		end
		
		AntibanSex = Tabs.AntiBan:Section({Opened = true, Box = true, BoxBorder = true, Title = "Antiban ", Icon = "shield-alert" })
		
		AntibanSex:Dropdown({
		    Title = "Safety Action ",
		    Flag = "tsbsafelyactionantiban",
		    Values = {"None", "Warn", "Auto Leave", "Auto Rejoin", "Kick"},
		    Value = "Kick",
		    Locked = LockedStatus,
		    LockedTitle = "Premium",
		    Callback = function(val)
		        Options.AvoidBanMethod.Value = val
		    end
		})
		
		
		AntibanSex:Input({
		    Title = "Rejoin Delay ",
		    Flag = "tsbrejoindaleyantiban",
		    Locked = LockedStatus,
		    LockedTitle = "Premium",
		    Value = "3",
		    Numeric = true,
		    Finished = true,
		    Callback = function(val)
		        Options.RejoinDelay.Value = val
		    end
		})
		
		
		AntibanSex:Toggle({
		    Title = "Enable Antiban Detector ",
		    Flag = "tsbantibanmaintoggle",
		    Locked = LockedStatus,
		    LockedTitle = "Premium",
		    Value = false,
		    Callback = function(value)
		        if value then
		            if not Vars.AnticheatConn then
		                local rep = ReplicatedStorage:FindFirstChild("Replication")
		                if rep then
		                    Vars.AnticheatConn = rep.OnClientEvent:Connect(function(...)
		                        local args = {...}
		                        local data = args[1]
		                        
		                        if type(data) == "table" then
		                            local effect = rawget(data, "Effect")
		                            if effect and tostring(effect):lower() == "hicheck" then
		                                HandleSafetyAction("A1 (Report/HiCheck)")
		                            end
		                        end
		                    end)
		                else
		                end
		            end
		        else
		            if Vars.AnticheatConn then
		                Vars.AnticheatConn:Disconnect()
		                Vars.AnticheatConn = nil
		            end
		        end
		    end
		})
		
		
		
		Antistaff = Tabs.AntiBan:Section({Opened = true, Box = true, BoxBorder = true, Title = "Anti Staff", Icon = "shield" })
		
		Players = game:GetService("Players")
		ReplicatedStorage = game:GetService("ReplicatedStorage")
		LocalPlayer = Players.LocalPlayer
		
		TargetGroupId = 12013007
		BlacklistedUserIds = {
		    422755031,198131804,681405668,3414432341,339633571,430966809,2039323684,
		    117723419,1015595932,263944298,112905203,2284964418,1266437961,3120648134,
		    1148139861,1633233654,3350014406,971193650,661273560,66105529,77342385,
		    167343092,2055306963,141984224,438917845,1391134999,1796550069,255671730,
		    3162123826,1059541187,1259898795,31070091,1041867508,994994173,1446694201,
		    77525605,1001242712,2533866869,4983064295
		}
		
		activeChecks = {
		    Moderators = true,
		    Contributor = true,
		    Developer = true,
		    Owner = true,
		    Other= true
		}
		
		isEnabled = false
		connection = nil
		
		function KickForStaffPresence(reason)
		    LocalPlayer:Kick("Staff: " .. reason)
		end
		
		function CheckPlayer(targetPlayer)
		    if targetPlayer == LocalPlayer or not isEnabled then return end
		
		    task.spawn(function()
		        if targetPlayer:IsInGroup(TargetGroupId) then
		            role = targetPlayer:GetRoleInGroup(TargetGroupId)
		            if activeChecks["Moderators"] and role:find("Moderator") then KickForStaffPresence("Mod") end
		            if activeChecks["Contributor"] and role:find("Contributor") then KickForStaffPresence("Contrib") end
		            if activeChecks["Developer"] and role:find("Developer") then KickForStaffPresence("Dev") end
		            if activeChecks["Owner"] and role:find("Owner") then KickForStaffPresence("Owner") end
		        end
		
		        if activeChecks["Others..."] then
		            for _, userId in ipairs(BlacklistedUserIds) do
		                if targetPlayer.UserId == userId then KickForStaffPresence("ID " .. userId) end
		                if targetPlayer:IsFriendsWith(userId) then KickForStaffPresence("Friend " .. userId) end
		            end
		        end
		    end)
		end
		
		
		Antistaff:Dropdown({
		    Title = "Target Roles",
		    Flag = "tsbtargetrolesantistaff",
		    Multi = true,
		    Values = {"Moderators", "Contributor", "Developer", "Owner", "Other"},
		    Options = {"Moderators", "Contributor", "Developer", "Owner", "Other"},
		    Callback = function(selected)
		        for k in pairs(activeChecks) do
		            activeChecks[k] = false
		        end
		        for _, option in ipairs(selected) do
		            activeChecks[option] = true
		        end
		    end
		})
		
		Antistaff:Toggle({
		    Title = "Enable Detection",
		    Flag = "tsbantistaffmaintoggle",
		    Value = false,
		    Callback = function(state)
		        isEnabled = state
		        if isEnabled then
		            for _, player in ipairs(Players:GetPlayers()) do
		                CheckPlayer(player)
		            end
		            connection = Players.PlayerAdded:Connect(CheckPlayer)
		        else
		            if connection then
		                connection:Disconnect()
		                connection = nil
		            end
		        end
		    end
		})
		
		if ReplicatedStorage:FindFirstChild("Replication") then
		    ReplicatedStorage.Replication.OnClientEvent:Connect(function(data)
		        if isEnabled and data and data.Effect and data.Effect:lower() == "hicheck" then
		            LocalPlayer:Kick("A1 detected")
		        end
		    end)
		end
	end)
end











-- ================ TOOLS0 TAB0 ================ --
function ToolsTab()
	task.spawn(function()
		ToolsSec = Tabs.Tools:Section({Opened = true, Box = true, BoxBorder = true, Title = "Tools", Icon = "eye" })
		
		local location = nil
		function createTeleportTool(toolName, teleportPosition)
		
		    local originalPosition = nil
		    local tool = Instance.new("Tool")
		    tool.Name = toolName
		    tool.RequiresHandle = false
		    tool.Parent = plr.Backpack
		    tool.Equipped:Connect(function()
		        originalPosition = plr.Character.HumanoidRootPart.Position
		        plr.Character:SetPrimaryPartCFrame(CFrame.new(teleportPosition))
		    end)
		    tool.Unequipped:Connect(function()
		        if originalPosition then
		            plr.Character:SetPrimaryPartCFrame(CFrame.new(originalPosition))
		        end
		    end)
		end
		
		local locations = {
		        Map = {name = "Map Tool", position = Vector3.new(150, 440, 30)},
		        SafeZone1 = {name = "SafeZone1 Tool", position = Vector3.new(150, 505, 30)},
		        SafeZone2 = {name = "SafeZone2 Tool", position = Vector3.new(150, 705, 30)},
		        Pixel = {name = "Pixel Tool", position = Vector3.new(30000000, 30000000, 30000000)},
		        Void = {name = "Void Tool", position = Vector3.new(150, -495, 30)},
		        DarkNess = {name = "DarkNess Tool", position = Vector3.new(0 ,900000000002 ,0)},
		        Montain = {name = "Mountain Tool", position = Vector3.new(155.577, 628.742, -447.938)},
		        Counter = {name = "Counter Tool", position = Vector3.new(-68, 29, 20346)},
		        ["Counter Up"] = {name = "CounterUp Tool", position = Vector3.new(-68, 84, 20354)},
		        ["Atomic Base"] = {name = "AtomicBase Tool", position = Vector3.new(1063, 30, 23006)},
		        ["Atomic Base Up"] = {name = "AtomicBaseUp Tool", position = Vector3.new(1063, 405, 23006)},
		        ["Atomic Slash"] = {name = "AtomicSlash Tool", position = Vector3.new(1063, 131, 23006)},
		        Prison = {name = "Prison Tool", position = Vector3.new(438, 439, -376)},
		    }
		
		ToolsSec:Dropdown({
		    Title = "Place Tools",
		    Desc = "What Place Tool Do You Want?",
		    Values = {"Map", "SafeZone1", "SafeZone2", "Pixel", "Void", "DarkNess", "Montain", "Counter", "Counter Up", "Atomic Base", "Atomic Base Up", "Atomic Slash", "Prison"},
		    Multi = false,
		    AllowNone = false,
		    Callback = function(selectedText)
		    location = locations[selectedText]
		end
		})
		
		ToolsSec:Button({
		    Title = "Get Tool",
		    Locked = false,
		    Callback = function()
			if location then
		        createTeleportTool(location.name, location.position)
		    end
		end
		})
		
		ToolsSec:Divider()
		
		ToolsSec:Button({
		    Title = "TrashCan Tool",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/ffnvee4X/raw"))()
		end
		})
		ToolsSec:Button({
		    Title = "Fake 20-20-20 Dropkick",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/Ja7L18CD/raw"))()
		end
		})
		
		ToolsSec:Button({
		    Title = "Super Dash",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/6oteIFSE/raw"))()
		end
		})
		
		ToolsSec:Button({
		    Title = "Dodge",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/XB1ykQuc/raw"))()
		end
		})
		ToolsSec:Button({
		    Title = "TP Tool (Anim)",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/yEwya3MR/raw"))()
		end
		})
		ToolsSec:Button({
		    Title = "TP Tool (Normal)",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/ZLpXLAeF/raw"))()
		end
		})
		ToolsSec:Button({
		    Title = "Run Tool",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/6DahLoA3/raw"))()
		end
		})
		ToolsSec:Button({
		    Title = "Super Run Tool",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/uN8jb9GF/raw"))()
		end
		})
		ToolsSec:Button({
		    Title = "Jerk Of Tool",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/LcC6ZrhN/raw"))()
		end
		})
		ToolsSec:Button({
		    Title = "Invis Block Tool (Buggy)",
		    Locked = false,
		    Callback = function()
		loadstring(game:HttpGet("https://pastefy.app/sl5RToWq/raw"))()
		end
		})
	end)
end














-- ================ Block0 TAB0 ================ --
function BlockTab()
	task.spawn(function()
		if getgenv().AutoBlockCounterBestLoaded then return end
		getgenv().AutoBlockCounterBestLoaded = true
		
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local UserInputService = game:GetService("UserInputService")
		local VirtualInputManager = game:GetService("VirtualInputManager")
		local Replicated = game:GetService("ReplicatedStorage")
		
		local player = Players.LocalPlayer
		if not player then return end
		
		getgenv().AutoBlocking = getgenv().AutoBlocking or false
		getgenv().AutoCounter = getgenv().AutoCounter or false
		getgenv().AutoBlockDist = getgenv().AutoBlockDist or "19.5"
		getgenv().AutoCounterDist = getgenv().AutoCounterDist or "19.5"
		getgenv().UseDeathMoves = getgenv().UseDeathMoves ~= nil and getgenv().UseDeathMoves or true
		getgenv().SoundParry = getgenv().SoundParry ~= nil and getgenv().SoundParry or true
		getgenv().AimbotWhileBlocking = getgenv().AimbotWhileBlocking ~= nil and getgenv().AimbotWhileBlocking or true
		getgenv().AutoM1AfterBlock = getgenv().AutoM1AfterBlock or false
		getgenv().M1Interval = getgenv().M1Interval or 0.2
		getgenv().M1Count = getgenv().M1Count or 1
		getgenv().BlockReleaseDelay = getgenv().BlockReleaseDelay or 0.6
		getgenv().FollowSpeed = getgenv().FollowSpeed or 700
		getgenv().FollowBehind = getgenv().FollowBehind or 4.4
		getgenv().FollowAnimInterval = getgenv().FollowAnimInterval or 0.2
		getgenv().BatterUltSafeState = getgenv().BatterUltSafeState or {}
		getgenv().ScriptHoldingF = false
		
		_G.CounterData = {
			["130924083726156"] = { Name = "Front Dash", Delay = 0.2, Dist = 10, Angle = 70, PosPredict = 0.14 },
			["121535378064818"] = { Name = "Grave Maker", Dist = 12, NoDir = true, Predict = 0.15, Duration = 0.9 },
			["124962465789551"] = { Name = "Blast Maker", Dist = 40, Angle = 35, Predict = 0.1, Delay = 0.25, IgnoreAfter = 0.8 },
			["100687456175134"] = { Name = "Point Blank", Dist = 15, Angle = 45, Predict = 0.1, Delay = 0.35, IgnoreAfter = 0.7 },
			["118270485922095"] = { Name = "Crossfire", Dist = 18, Angle = 45, Predict = 0.15, Delay = 0.35, IgnoreAfter = 1.1 },
			["16431491215"] = { Name = "Stone Coffin", Special = "StoneCoffin", NoDir = true },
			["16597912086"] = { Name = "Explosive Push", Dist = 15, NoDir = true, IgnoreAfter = 0.55 },
			["17464644182"] = { Name = "Psychic Ricochet", Dist = 20, Angle = 45, Duration = .6 },
			["17860467628"] = { Name = "Sky Snatcher", Delay = .6, Dist = 16, NoDir = true, Predict = 0.15, IgnoreAfter = 2.4 },
			["14004235777"] = { Name = "Homerun Swing", Dist = 8, Duration = 1.2 },
			["14003607057"] = { Name = "Homerun Slam", Delay = 0.5, Predict = 0.15, IgnoreAfter = .9, Dist = 12 },
			["14046756619"] = { Name = "Beatdown", Dist = 11, Duration = 0.7, NoDir = true, Predict = 0.15 },
			["14299135500"] = { Name = "Grand Slam", Dist = 10, PosPredict = 0.25, NoDir = true, Delay = 0.35 },
			["14351441234"] = { Name = "Foul Ball", Delay = 0.2, Duration = 0.8, NoDir = true, Predict = .1 },
			["14719290328"] = { Name = "Savage Tornado", Dist = 40, NoDir = true, Predict = 0.2, Duration = 3.65 },
			["14701242661"] = { Name = "Brutal Beatdown", Delay = 1.5, Dist = 13, Duration = 8.0, NoDir = true, Predict = 0.19 },
			["12272894215"] = { Name = "Flowing Water", Duration = 0.5, Dist = 10 },
			["12273188754"] = { Name = "Flowing Water Punches", Duration = 1.7, Dist = 8, Predict = 0.25 },
			["12296882427"] = { Name = "Lethal Whirlwind Stream", Duration = 0.5 },
			["12307656616"] = { Name = "Hunters Grasp", Dist = 6, Angle = 30, Duration = .25 },
			["13630786846"] = { Name = "Crushed Rock Run", Dist = 16, Predict = 0.2, Duration = 1 },
			["12460977270"] = { Name = "Water Stream Cutting Fist", Duration = 1.6 },
			["14057231976"] = { Name = "Rock Splitting Fist", Duration = 1.45 },
			["72451715583225"] = { Name = "Crushed Rock Grab", Predict = 0.2, Duration = 0.75 },
			["135104210400610"] = { Name = "Crushed Rock Slide", PosPredict = 0.15, Duration = .75, Dist = 11 },
			["102989537449083"] = { Name = "Doom Dive", RaycastType = "ForwardDown", Dist = 10 },
			["82365328621192"] = { Name = "Doom Dive Alt", RaycastType = "ForwardDown", Dist = 10 },
			["131820095363270"] = { Name = "Crowd Buster", Dist = 10, NoDir = true, Predict = 0.15, Duration = 1.6 },
			["109617620932970"] = { Name = "Hammer Heel", Duration = .6, Dist = 8 },
			["135289891173395"] = { Name = "Hammer Heel Variant", Dist = 13, Duration = 0.85, Predict = .5 },
			["125955606488863"] = { Name = "Binding Cloth", Dist = 9, Delay = .2, IgnoreAfter = 0.7 },
			["85025226664507"] = { Name = "Hunters Mark", Dist = 15, Predict = 0.2, Delay = 0.6, IgnoreAfter = 1.3 },
			["10468665991"] = { Name = "Normal Punch", Dist = 70, Angle = 20, Delay = .3, IgnoreAfter = .5 },
			["10466974800"] = { Name = "Consecutive Punches", Dist = 11, IgnoreAfter = 1.4 },
			["10471336737"] = { Name = "Shove", IgnoreAfter = .5 },
			["12510170988"] = { Name = "Uppercut", Delay = .1, IgnoreAfter = 0.45 },
			["17799224866"] = { Name = "Bullet Barrage", IgnoreAfter = 2, Dist = 11, Angle = 50 },
			["17838006839"] = { Name = "Vanishing Kick", Delay = 0.4, IgnoreAfter = .95, Dist = 11, Angle = 45, Predict = 0.15 },
			["17838619895"] = { Name = "Vanishing Kick Slam", Dist = 10, NoDir = true, IgnoreAfter = 1, Predict = .05 },
			["17857788598"] = { Name = "Whirlwind Drop", RaycastType = "DownOnly", Dist = 20 },
			["18464362124"] = { Name = "Whirlwind Finisher", Dist = 20, NoDir = true, IgnoreAfter = 2.7 },
			["18179181663"] = { Name = "Head First", IgnoreAfter = .5, Dist = 10, Angle = 60 },
			["18896229321"] = { Name = "Twin Fangs", Dist = 15, Predict = 0.1, IgnoreAfter = 3.3, Angle = 45 },
			["18897119503"] = { Name = "Earth Splitting", Dist = 70, Angle = 20 },
			["80903587710309"] = { Name = "Trinity Tear Air", RaycastType = "DownOnly", Dist = 15 },
			["77509627104305"] = { Name = "Trinity Tear", Special = "BoxCheck", OffsetZ = 26, Width = 8, NoFace = true, Predict = 0.1 },
			["114095570398448"] = { Name = "Plasma Cannon", Special = "BoxCheck", OffsetZ = 100, Width = 6, NoFace = true },
			["13376869471"] = { Name = "Flash Strike", Delay = 0.2, IgnoreAfter = 0.7, Dist = 57, Angle = 20 },
			["13294790250"] = { Name = "Whirlwind Kick", Special = "SonicKick", IgnoreAfter = 0.8 },
			["13632347366"] = { Name = "Twinblade Rush", Dist = 25, PosPredict = 0.15, Angle = 50 },
			["13881335713"] = { Name = "FourFold Strike", Dist = 50, Angle = 35 },
			["12534735382"] = { Name = "Machine Gun Blows", Dist = 11, IgnoreAfter = 1.8, Angle = 50 },
			["12502664044"] = { Name = "Ignition Burst Opener", Dist = 15, Special = "BehindCheck", IgnoreAfter = .3 },
			["12509505723"] = { Name = "Ignition Burst Blast", Dist = 40, Angle = 35, Predict = 0.1, Delay = 0.3, IgnoreAfter = 0.7 },
			["12684390285"] = { Name = "Jet Dive", RaycastType = "ForwardDown", Delay = 1.268, Dist = 22 },
			["14721837245"] = { Name = "Thunder Kick", Special = "ThunderKick", Predict = 0.17, Delay = .4 },
			["13083332742"] = { Name = "Flamewave Cannon", Special = "GenosFlamewave", Width = 9, CloseDist = 25, NoFace = true, IgnoreAfter = 2 },
			["13146710762"] = { Name = "Incinerate", Special = "GenosIncinerate", CloseDist = 30, IgnoreAfter = 1.5 },
			["15290930205"] = { Name = "Quick Slice", Special = "QuickSlice", Delay = 0.45, NoFace = true },
			["15145462680"] = { Name = "Atmos Cleave", Dist = 12, Angle = 60 },
			["15295895753"] = { Name = "Pinpoint Cut", Delay = 0.4, Dist = 14, Angle = 45, Predict = 0.1, IgnoreAfter = 0.7 },
			["111986840437684"] = { Name = "Flame M1", Dist = 40, Angle = 40, IgnoreAfter = 0.45 },
			["15295336270"] = { Name = "Pinpoint Cut Air", RaycastType = "ForwardDown", Delay = 0.48, Dist = 14 },
			["16062410809"] = { Name = "Sunrise", Dist = 15, Delay = 0.7, Predict = 0.1, Angle = 50 },
			["15676072469"] = { Name = "Solar Cleave", Special = "SolarCleave", NoFace = true },
			["15520132233"] = { Name = "Sunset", Dist = 22, Duration = 3.5, Predict = 0.15 },
			["13380255751"] = { Name = "Sword Dash", Delay = 0.24, Dist = 9, Angle = 70, PosPredict = 0.14 },
			["10479335397"] = { Name = "Normal Dash", Delay = 0.24, Dist = 9, Angle = 70, PosPredict = 0.14 },
		}
		
		_G.BlockData = {
			["130924083726156"] = { Name = "Front Dash", Delay = 0.2, Dist = 11, NoDir = true, Predict = 0.14 },
			["121535378064818"] = { Name = "Grave Maker", Dist = 12, NoDir = true, Predict = 0.15, Duration = 0.9 },
			["124962465789551"] = { Name = "Blast Maker", Dist = 40, Angle = 35, Predict = 0.1, Delay = 0.35, IgnoreAfter = 0.8 },
			["100687456175134"] = { Name = "Point Blank", Dist = 15, Angle = 45, Predict = 0.1, Delay = 0.35, IgnoreAfter = 0.7 },
			["118270485922095"] = { Name = "Crossfire", Dist = 18, Angle = 45, Predict = 0.15, Delay = 0.35, IgnoreAfter = 1.1 },
			["16431491215"] = { Name = "Stone Coffin", Special = "StoneCoffin", NoDir = true },
			["14046756619"] = { Name = "Beatdown", Dist = 11, Duration = 0.7, NoDir = true, Predict = 0.15 },
			["12272894215"] = { Name = "Flowing Water", Duration = 0.5, Dist = 10, NoDir = true },
			["12273188754"] = { Name = "Flowing Water Punches", Duration = 1.7, Dist = 10, Predict = 0.15, Angle = 120 },
			["12296882427"] = { Name = "Lethal Whirlwind Stream", Duration = 0.5, Dist = 9, NoDir = true },
			["131820095363270"] = { Name = "Crowd Buster", Dist = 12, NoDir = true, Angle = 90, Predict = 0.2, Duration = 1.6 },
			["125955606488863"] = { Name = "Binding Cloth", Dist = 9, Delay = .3, IgnoreAfter = 0.7 },
			["10468665991"] = { Name = "Normal Punch", Dist = 70, Angle = 20, Delay = .4, IgnoreAfter = .7 },
			["10466974800"] = { Name = "Consecutive Punches", Dist = 11, IgnoreAfter = 1.4 },
			["17799224866"] = { Name = "Bullet Barrage", IgnoreAfter = 2, Dist = 11, Angle = 50 },
			["17838006839"] = { Name = "Vanishing Kick", Delay = 0.4, IgnoreAfter = .95, Dist = 11, Angle = 45, Predict = 0.15 },
			["17857788598"] = { Name = "Whirlwind Drop", RaycastType = "DownOnly", Dist = 20 },
			["18179181663"] = { Name = "Head First", IgnoreAfter = .5, Dist = 10, Angle = 60 },
			["77509627104305"] = { Name = "Trinity Tear", Special = "BoxCheck", OffsetZ = 22, Width = 8, NoFace = true, Predict = 0.15 },
			["13376869471"] = { Name = "Flash Strike", IgnoreAfter = 0.7, Dist = 57, Angle = 20 },
			["13294790250"] = { Name = "Whirlwind Kick", Special = "SonicKick", IgnoreAfter = 0.4 },
			["12534735382"] = { Name = "Machine Gun Blows", Dist = 11, IgnoreAfter = 1.8, Angle = 50 },
			["12502664044"] = { Name = "Ignition Burst Opener", Dist = 15, Special = "BehindCheck", IgnoreAfter = .3 },
			["12509505723"] = { Name = "Ignition Burst Blast", Dist = 40, Angle = 35, Predict = 0.1, Delay = 0.5, IgnoreAfter = 0.7 },
			["12684390285"] = { Name = "Jet Dive", RaycastType = "ForwardDown", Delay = 1.2, Dist = 22, NoDir = true },
			["15290930205"] = { Name = "Quick Slice", Special = "QuickSlice", Delay = 0.4, NoFace = true },
			["15295895753"] = { Name = "Pinpoint Cut", Delay = 0.4, Dist = 14, Angle = 45, Predict = 0.1, IgnoreAfter = 0.7 },
			["111986840437684"] = { Name = "Flame M1", Dist = 40, Angle = 40, IgnoreAfter = 0.45 },
			["15295336270"] = { Name = "Pinpoint Cut Air", RaycastType = "ForwardDown", Delay = 0.45, Dist = 14 },
			["13380255751"] = { Name = "Sword Dash", Delay = 0.2, Dist = 11, NoDir = true, Predict = 0.14 },
			["10479335397"] = { Name = "Normal Dash", Delay = 0.2, Dist = 11, NoDir = true, Predict = 0.14 },
		}
		
		local ToolWhitelists = {
			["Split Second Counter"] = {
				["Front Dash"]=true,["Grave Maker"]=true,["Blast Maker"]=true,["Point Blank"]=true,["Crossfire"]=true,
				["Sword Dash"]=true,["Normal Dash"]=true,["Plasma Cannon"]=true,["Trinity Tear"]=true,["Trinity Tear Air"]=true,
				["Flowing Water"]=true,["Flowing Water Punches"]=true,["Lethal Whirlwind Stream"]=true,["Hunters Grasp"]=true,
				["Crushed Rock Run"]=true,["Water Stream Cutting Fist"]=true,["Rock Splitting Fist"]=true,["Crushed Rock Grab"]=true,
				["Crushed Rock Slide"]=true,["Doom Dive"]=true,["Doom Dive Alt"]=true,["Crowd Buster"]=true,["Hammer Heel"]=true,
				["Hammer Heel Variant"]=true,["Binding Cloth"]=true,["Hunters Mark"]=true,["Homerun Swing"]=true,["Homerun Slam"]=true,
				["Beatdown"]=true,["Grand Slam"]=true,["Foul Ball"]=true,["Bullet Barrage"]=true,["Vanishing Kick"]=true,
				["Vanishing Kick Slam"]=true,["Whirlwind Drop"]=true,["Whirlwind Finisher"]=true,["Head First"]=true,
				["Twin Fangs"]=true,["Earth Splitting"]=true,["Stone Coffin"]=true,["Explosive Push"]=true,["Machine Gun Blows"]=true,
				["Ignition Burst Opener"]=true,["Ignition Burst Blast"]=true,["Jet Dive"]=true,["Thunder Kick"]=true,
				["Flame M1"]=true,["Quick Slice"]=true,["Atmos Cleave"]=true,["Pinpoint Cut"]=true,["Pinpoint Cut Air"]=true,
				["Sunrise"]=true,["Normal Punch"]=true,["Consecutive Punches"]=true,["Shove"]=true,["Uppercut"]=true,
				["Flash Strike"]=true,["Whirlwind Kick"]=true,
			},
			["Prey's Peril"] = {
				["Front Dash"]=true,["Grave Maker"]=true,["Blast Maker"]=true,["Point Blank"]=true,["Crossfire"]=true,
				["Sword Dash"]=true,["Normal Dash"]=true,["Plasma Cannon"]=true,["Trinity Tear"]=true,["Trinity Tear Air"]=true,
				["Flowing Water"]=true,["Flowing Water Punches"]=true,["Lethal Whirlwind Stream"]=true,["Hunters Grasp"]=true,
				["Crushed Rock Run"]=true,["Water Stream Cutting Fist"]=true,["Rock Splitting Fist"]=true,["Crushed Rock Grab"]=true,
				["Crushed Rock Slide"]=true,["Doom Dive"]=true,["Doom Dive Alt"]=true,["Crowd Buster"]=true,["Hammer Heel"]=true,
				["Hammer Heel Variant"]=true,["Binding Cloth"]=true,["Hunters Mark"]=true,["Homerun Swing"]=true,["Homerun Slam"]=true,
				["Beatdown"]=true,["Grand Slam"]=true,["Foul Ball"]=true,["Foul Ball Projectile"]=true,["Bullet Barrage"]=true,
				["Vanishing Kick"]=true,["Vanishing Kick Slam"]=true,["Whirlwind Drop"]=true,["Whirlwind Finisher"]=true,
				["Head First"]=true,["Twin Fangs"]=true,["Earth Splitting"]=true,["Stone Coffin"]=true,["Explosive Push"]=true,
				["Machine Gun Blows"]=true,["Ignition Burst Opener"]=true,["Ignition Burst Blast"]=true,["Jet Dive"]=true,
				["Thunder Kick"]=true,["Flame M1"]=true,["Quick Slice"]=true,["Atmos Cleave"]=true,["Pinpoint Cut"]=true,
				["Pinpoint Cut Air"]=true,["Sunrise"]=true,["Normal Punch"]=true,["Consecutive Punches"]=true,["Shove"]=true,
				["Uppercut"]=true,["Flash Strike"]=true,["Whirlwind Kick"]=true,
			},
			["Death Counter"] = {
				["Front Dash"]=true,["Grave Maker"]=true,["Blast Maker"]=true,["Point Blank"]=true,["Crossfire"]=true,
				["Sword Dash"]=true,["Normal Dash"]=true,["Stone Coffin"]=true,["Explosive Push"]=true,["Psychic Ricochet"]=true,
				["Sky Snatcher"]=true,["Homerun Swing"]=true,["Homerun Slam"]=true,["Beatdown"]=true,["Grand Slam"]=true,
				["Foul Ball"]=true,["Savage Tornado"]=true,["Brutal Beatdown"]=true,["Flowing Water"]=true,
				["Flowing Water Punches"]=true,["Lethal Whirlwind Stream"]=true,["Hunters Grasp"]=true,["Crushed Rock Run"]=true,
				["Water Stream Cutting Fist"]=true,["Rock Splitting Fist"]=true,["Crushed Rock Grab"]=true,["Crushed Rock Slide"]=true,
				["Doom Dive"]=true,["Doom Dive Alt"]=true,["Crowd Buster"]=true,["Hammer Heel"]=true,["Hammer Heel Variant"]=true,
				["Binding Cloth"]=true,["Hunters Mark"]=true,["Normal Punch"]=true,["Consecutive Punches"]=true,["Shove"]=true,
				["Uppercut"]=true,["Bullet Barrage"]=true,["Vanishing Kick"]=true,["Vanishing Kick Slam"]=true,
				["Whirlwind Drop"]=true,["Whirlwind Finisher"]=true,["Head First"]=true,["Twin Fangs"]=true,["Earth Splitting"]=true,
				["Trinity Tear Air"]=true,["Trinity Tear"]=true,["Plasma Cannon"]=true,["Flash Strike"]=true,["Whirlwind Kick"]=true,
				["Twinblade Rush"]=true,["FourFold Strike"]=true,["Machine Gun Blows"]=true,["Ignition Burst Opener"]=true,
				["Ignition Burst Blast"]=true,["Jet Dive"]=true,["Thunder Kick"]=true,["Flamewave Cannon"]=true,["Incinerate"]=true,
				["Quick Slice"]=true,["Atmos Cleave"]=true,["Pinpoint Cut"]=true,["Flame M1"]=true,["Pinpoint Cut Air"]=true,
				["Sunrise"]=true,["Solar Cleave"]=true,["Sunset"]=true,
			},
			["Death Blow"] = {
				["Front Dash"]=true,["Grave Maker"]=true,["Blast Maker"]=true,["Point Blank"]=true,["Crossfire"]=true,
				["Sword Dash"]=true,["Normal Dash"]=true,["Stone Coffin"]=true,["Explosive Push"]=true,["Psychic Ricochet"]=true,
				["Sky Snatcher"]=true,["Homerun Swing"]=true,["Homerun Slam"]=true,["Beatdown"]=true,["Grand Slam"]=true,
				["Foul Ball"]=true,["Savage Tornado"]=true,["Brutal Beatdown"]=true,["Flowing Water"]=true,
				["Flowing Water Punches"]=true,["Lethal Whirlwind Stream"]=true,["Hunters Grasp"]=true,["Crushed Rock Run"]=true,
				["Water Stream Cutting Fist"]=true,["Rock Splitting Fist"]=true,["Crushed Rock Grab"]=true,["Crushed Rock Slide"]=true,
				["Doom Dive"]=true,["Doom Dive Alt"]=true,["Crowd Buster"]=true,["Hammer Heel"]=true,["Hammer Heel Variant"]=true,
				["Binding Cloth"]=true,["Hunters Mark"]=true,["Normal Punch"]=true,["Consecutive Punches"]=true,["Shove"]=true,
				["Uppercut"]=true,["Bullet Barrage"]=true,["Vanishing Kick"]=true,["Vanishing Kick Slam"]=true,
				["Whirlwind Drop"]=true,["Whirlwind Finisher"]=true,["Head First"]=true,["Twin Fangs"]=true,["Earth Splitting"]=true,
				["Trinity Tear Air"]=true,["Trinity Tear"]=true,["Plasma Cannon"]=true,["Flash Strike"]=true,["Whirlwind Kick"]=true,
				["Twinblade Rush"]=true,["FourFold Strike"]=true,["Machine Gun Blows"]=true,["Ignition Burst Opener"]=true,
				["Ignition Burst Blast"]=true,["Jet Dive"]=true,["Thunder Kick"]=true,["Flamewave Cannon"]=true,["Incinerate"]=true,
				["Quick Slice"]=true,["Atmos Cleave"]=true,["Pinpoint Cut"]=true,["Flame M1"]=true,["Pinpoint Cut Air"]=true,
				["Sunrise"]=true,["Solar Cleave"]=true,["Sunset"]=true,
			},
		}
		
		local COS = {}
		for _, deg in ipairs({10,20,25,30,35,40,45,50,60,70,90,120}) do
			COS[deg] = math.cos(math.rad(deg))
		end
		
		local _pingSamples = {}
		local _smoothPing = 0.08
		task.spawn(function()
			while true do
				local ok, pingVal = pcall(function()
					return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
				end)
				if ok and pingVal and pingVal > 0 then
					_pingSamples[#_pingSamples + 1] = pingVal / 1000
					if #_pingSamples > 8 then table.remove(_pingSamples, 1) end
					local sum = 0
					for _, v in ipairs(_pingSamples) do
						sum = sum + v
					end
					_smoothPing = math.clamp(sum / #_pingSamples, 0.01, 0.35)
				end
				task.wait(0.5)
			end
		end)
		
		local ActiveM1s = {}
		local Live = workspace:FindFirstChild("Live")
		local function MonitorM1(c)
			if not c or c.Name == player.Name then return end
			c.ChildAdded:Connect(function(x) if x.Name == "M1ing" then ActiveM1s[c] = true end end)
			c.ChildRemoved:Connect(function(x) if x.Name == "M1ing" then ActiveM1s[c] = nil end end)
			if c:FindFirstChild("M1ing") then ActiveM1s[c] = true end
			c.AncestryChanged:Connect(function(_, p) if not p then ActiveM1s[c] = nil end end)
		end
		if Live then
			Live.ChildAdded:Connect(MonitorM1)
			for _, c in pairs(Live:GetChildren()) do MonitorM1(c) end
		end
		
		local scatterActive = setmetatable({}, { __mode = "k" })
		local scatterData = setmetatable({}, { __mode = "k" })
		
		local function setupNinjaTracker(char)
			if not char then return end
			if char:GetAttribute("Character") == "Ninja" then
				local function checkKatana()
					if char:FindFirstChild("HasKatana") then
						scatterActive[char] = true
						scatterData[char] = { boxSize = Vector3.new(26, 14, 46), predict = 0.04, startTime = math.huge }
					else
						scatterActive[char] = nil
						scatterData[char] = nil
					end
				end
				char.ChildAdded:Connect(checkKatana)
				char.ChildRemoved:Connect(checkKatana)
				checkKatana()
			end
		end
		
		local function setupBatterTracker(char)
			if not char then return end
			getgenv().BatterUltSafeState[char] = true
			char:GetAttributeChangedSignal("Ulted"):Connect(function()
				if char:GetAttribute("Ulted") and char:GetAttribute("Character") == "Batter" then
					getgenv().BatterUltSafeState[char] = false
				else
					getgenv().BatterUltSafeState[char] = true
				end
			end)
			char.ChildAdded:Connect(function(child)
				if child.Name == "DeathBlowCounter" then getgenv().BatterUltSafeState[char] = false end
			end)
			char.ChildRemoved:Connect(function(child)
				if child.Name == "DeathBlowCounter" then getgenv().BatterUltSafeState[char] = true end
			end)
			if char:GetAttribute("Ulted") and char:GetAttribute("Character") == "Batter" then
				getgenv().BatterUltSafeState[char] = false
			end
		end
		
		if Live then
			for _, child in ipairs(Live:GetChildren()) do
				setupBatterTracker(child)
				setupNinjaTracker(child)
			end
			Live.ChildAdded:Connect(function(child)
				setupBatterTracker(child)
				setupNinjaTracker(child)
			end)
		end
		
		local function animDigits(idStr)
			return tostring(idStr or ""):match("(%d+)")
		end
		
		local function isFacing(originPart, targetPos, cosThreshold)
			local dir = targetPos - originPart.Position
			local m = dir.Magnitude
			if m <= 1e-6 then return true end
			return originPart.CFrame.LookVector:Dot(dir / m) >= cosThreshold
		end
		
		local function boxCheck(enemyRoot, myPos, depth, width, height)
			local rel = enemyRoot.CFrame:PointToObjectSpace(myPos)
			if rel.Z > 0 then return false end
			if rel.Z < -depth then return false end
			if math.abs(rel.X) > width then return false end
			if height and math.abs(rel.Y) > height then return false end
			return true
		end
		
		local function isSelfSoundPlaying(soundId)
			local char = player.Character
			if not char then return false end
			local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
			if not torso then return false end
			for _, s in ipairs(torso:GetChildren()) do
				if s:IsA("Sound") and s.IsPlaying and s.SoundId == soundId then return true end
			end
			return false
		end
		
		local EnemyMotionTrack = setmetatable({}, { __mode = "k" })
		local RaycastTrack = setmetatable({}, { __mode = "k" })
		
		local _mapWhitelistCache = nil
		local _mapWhitelistDirty = true
		local _mapRayParams = RaycastParams.new()
		_mapRayParams.FilterType = Enum.RaycastFilterType.Include
		
		local function _buildMapWhitelist()
			local whitelist = {}
			local map = workspace:FindFirstChild("Map")
			if map then
				for _, name in ipairs({"Walls","Stuff","GrassTop","GrassBottom","Floor/Roads","MainPart"}) do
					local t = map:FindFirstChild(name)
					if t then whitelist[#whitelist+1] = t end
				end
			end
			_mapWhitelistCache = whitelist
			_mapRayParams.FilterDescendantsInstances = whitelist
			_mapWhitelistDirty = false
		end
		
		local function EnsureMapWhitelistFresh()
			if _mapWhitelistDirty or not _mapWhitelistCache then _buildMapWhitelist() end
		end
		
		do
			local function markDirty() _mapWhitelistDirty = true end
			local map = workspace:FindFirstChild("Map")
			if map then
				map.AncestryChanged:Connect(markDirty)
				map.ChildAdded:Connect(markDirty)
				map.ChildRemoved:Connect(markDirty)
			end
			workspace.ChildAdded:Connect(function(c) if c.Name == "Map" then markDirty() end end)
			workspace.ChildRemoved:Connect(function(c) if c.Name == "Map" then markDirty() end end)
		end
		
		local function CastRay(origin, direction)
			if direction.Magnitude < 1e-6 then return nil end
			EnsureMapWhitelistFresh()
			local hit = workspace:Raycast(origin, direction.Unit * 1000, _mapRayParams)
			if not hit then return nil end
			local finalPos = hit.Position
			if math.abs(hit.Normal.Y) < 0.5 then
				local floorOrigin = hit.Position + (hit.Normal * 1.5)
				local floorHit = workspace:Raycast(floorOrigin, Vector3.new(0, -100, 0), _mapRayParams)
				if floorHit then finalPos = floorHit.Position end
			end
			return finalPos
		end
		
		local function GetRaycastImpact(enemyRoot, animId, data)
			if not RaycastTrack[enemyRoot] then
				RaycastTrack[enemyRoot] = { StartCF = enemyRoot.CFrame, LastCF = enemyRoot.CFrame, PredictedPos = nil, AnimId = animId }
			end
			local t = RaycastTrack[enemyRoot]
			if t.AnimId ~= animId then
				RaycastTrack[enemyRoot] = { StartCF = enemyRoot.CFrame, LastCF = enemyRoot.CFrame, PredictedPos = nil, AnimId = animId }
				t = RaycastTrack[enemyRoot]
			end
			local currentPos = enemyRoot.Position
			if t.PredictedPos then
				if (currentPos - t.PredictedPos).Magnitude < 10 then t.PredictedPos = nil return nil end
				return t.PredictedPos
			end
			local triggered = false
			local rayDir = nil
			local relPos = t.StartCF:PointToObjectSpace(currentPos)
			local delta = currentPos - t.StartCF.Position
			if data.Name == "Doom Dive" or data.Name == "Doom Dive Alt" then
				local frameDrop = t.LastCF.Position.Y - currentPos.Y
				local totalDrop = t.StartCF.Position.Y - currentPos.Y
				if (frameDrop > 0.4 or totalDrop > 2.5) and delta.Magnitude > 0.05 then
					rayDir = (currentPos - t.LastCF.Position).Unit
					triggered = true
				end
			elseif data.RaycastType == "DownOnly" then
				if relPos.Y < -2 then rayDir = Vector3.new(0, -1, 0) triggered = true end
			elseif data.RaycastType == "ForwardDown" then
				if relPos.Z < -3 and relPos.Y < -0.5 and delta.Magnitude > 0.05 then
					rayDir = delta.Unit
					triggered = true
				end
			end
			t.LastCF = enemyRoot.CFrame
			if triggered and rayDir then
				local landPos = CastRay(currentPos, rayDir)
				if not landPos and data.Name:find("Doom Dive") then
					landPos = CastRay(currentPos, Vector3.new(0, -1, 0))
				end
				if landPos then t.PredictedPos = landPos return landPos end
			end
			return nil
		end
		
		local function findToolForMove(moveName)
			local backpack = player.Backpack
			local char = player.Character
			local allTools = {}
			if backpack then for _, t in ipairs(backpack:GetChildren()) do if t:IsA("Tool") then allTools[#allTools+1] = t end end end
			if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then allTools[#allTools+1] = t end end end
			for _, tool in ipairs(allTools) do
				local wl = ToolWhitelists[tool.Name]
				if wl and wl[moveName] then return tool.Name end
			end
			return nil
		end
		
		local function getMyHead()
			local char = player.Character
			return char and char:FindFirstChild("Head")
		end
		
		local function enemyM1ingNearby(maxDist)
			local myHead = getMyHead()
			if not myHead then return nil, nil end
			local myPos = myHead.Position
			local maxDist2 = maxDist * maxDist
			local ping = _smoothPing
			local bestChar, bestD2 = nil, math.huge
			for char, _ in pairs(ActiveM1s) do
				if char and char.Parent then
					if not char:FindFirstChild("M1ing") then ActiveM1s[char] = nil  end
					local head = char:FindFirstChild("Head")
					local root = char:FindFirstChild("HumanoidRootPart")
					if head and root then
						local enemyVel = root.AssemblyLinearVelocity or Vector3.zero
						local vm = enemyVel.Magnitude
						if vm > 200 then enemyVel = enemyVel * (200 / vm) end
						local predictedHeadPos = head.Position + (enemyVel * ping)
						local distVec = predictedHeadPos - myPos
						local d2 = distVec.X*distVec.X + distVec.Y*distVec.Y + distVec.Z*distVec.Z
						local qualifies = false
						if d2 <= 49 then
							qualifies = true
						elseif d2 <= maxDist2 then
							if d2 > 0.01 then
								local dot = root.CFrame.LookVector:Dot(-distVec.Unit)
								if dot > 0.422 then qualifies = true end
							else
								qualifies = true
							end
						end
						if qualifies and d2 < bestD2 then
							bestChar = char
							bestD2 = d2
						end
					end
				else ActiveM1s[char] = nil end
			end
			return bestChar, bestD2 ~= math.huge and bestD2 or nil
		end
		
		local function tposWindowOk(track, data)
			local speed = 1
			pcall(function() speed = math.max(track.Speed, 0.01) end)
			local tp = track.TimePosition * speed
			if data.Delay and tp < data.Delay then return false end
			if data.Duration and tp > data.Duration then return false end
			if data.IgnoreAfter and tp > data.IgnoreAfter then return false end
			return true
		end
		
		local function shouldCounter(enemyModel, track, myRoot, dataOverride, animIdOverride, allowNoTool, forcedToolName)
			local enemyRoot = enemyModel and enemyModel:FindFirstChild("HumanoidRootPart")
			if not enemyRoot then return false end
			local animId = animIdOverride or animDigits(track.Animation and track.Animation.AnimationId)
			local data = dataOverride or (animId and _G.CounterData[animId]) or nil
			if not data then return false end
			local toolName = forcedToolName or findToolForMove(data.Name)
			if forcedToolName and not allowNoTool then
				local wl = ToolWhitelists[forcedToolName]
				if wl and not wl[data.Name] then return false end
			end
			if not toolName and not allowNoTool then return false end
			local speed = 1
			pcall(function() speed = math.max(track.Speed, 0.01) end)
			local timePos = track.TimePosition * speed
			if data.Duration and timePos > data.Duration then return false end
			if data.Delay and timePos < data.Delay then return false end
			if data.IgnoreAfter and timePos > data.IgnoreAfter then return false end
			local enemyVel
			if data.PosPredict then
				local currentPos = enemyRoot.Position
				local currentTime = tick()
				local trackData = EnemyMotionTrack[enemyRoot]
				if not trackData then
					EnemyMotionTrack[enemyRoot] = { LastPos = currentPos, LastTime = currentTime }
					enemyVel = enemyRoot.AssemblyLinearVelocity or Vector3.zero
				else
					local dt = currentTime - trackData.LastTime
					if dt > 0 then
						enemyVel = (currentPos - trackData.LastPos) / dt
					else
						enemyVel = enemyRoot.AssemblyLinearVelocity or Vector3.zero
					end
					trackData.LastPos = currentPos
					trackData.LastTime = currentTime
				end
			else
				enemyVel = enemyRoot.AssemblyLinearVelocity or Vector3.zero
			end
			local pTime = data.PosPredict or data.Predict or 0
			local predictedEnemyPos = enemyRoot.Position + enemyVel * pTime
			local dist = (predictedEnemyPos - myRoot.Position).Magnitude
			if data.RaycastType then
				local impactPos = GetRaycastImpact(enemyRoot, animId, data)
				if impactPos then
					if (impactPos - myRoot.Position).Magnitude <= data.Dist then return true end
				end
				if dist <= (data.Dist or 20) then return true end
				return false
			end
			if data.Special == "StoneCoffin" then
				local forward = enemyRoot.CFrame.LookVector
				local origin = enemyRoot.Position + forward * 19.5 + Vector3.new(0, 20, 0)
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = { player.Character, enemyModel }
				local hit = workspace:Raycast(origin, Vector3.new(0, -1000, 0), rayParams)
				if not hit then return false end
				return (hit.Position - myRoot.Position).Magnitude <= 10.5
			end
			if data.Special == "BoxCheck" then
				local predPos = enemyRoot.Position + ((enemyRoot.AssemblyLinearVelocity or Vector3.zero) * (data.Predict or 0))
				local predCFrame = CFrame.new(predPos) * enemyRoot.CFrame.Rotation
				local rel = predCFrame:PointToObjectSpace(myRoot.Position)
				if rel.Z >= 0 then return false end
				if rel.Z < -data.OffsetZ then return false end
				if math.abs(rel.X) > data.Width then return false end
				if math.abs(rel.Y) > (data.Height or 20) then return false end
				return true
			end
			if data.Special == "SonicKick" then
				if timePos < 0.1 then
					if dist > 45 then return false end
					return isFacing(enemyRoot, myRoot.Position, COS[20])
				else
					local req = tonumber(getgenv().AutoCounterDist) or 20
					return dist <= req
				end
			end
			if data.Special == "BehindCheck" then
				local dirToMe = myRoot.Position - enemyRoot.Position
				local m = dirToMe.Magnitude
				if m <= 1e-6 then return true end
				if (dirToMe / m):Dot(enemyRoot.CFrame.LookVector) > math.cos(math.rad(135)) then return false end
				return dist <= (data.Dist or 15)
			end
			if data.Special == "ThunderKick" then
				if timePos >= 0.5 and timePos <= 0.8 then return dist <= 12 end
				if timePos >= 1.5 then
					if toolName == "Death Counter" then return dist <= 60 else return dist <= 30 end
				end
				return false
			end
			if data.Special == "GenosFlamewave" then
				local depth = (toolName == "Death Counter") and 1000 or (data.CloseDist or 25)
				return boxCheck(enemyRoot, myRoot.Position, depth, data.Width or 6, 10)
			end
			if data.Special == "GenosIncinerate" then
				if dist <= (data.CloseDist or 30) then return true end
				if toolName == "Death Blow" then return dist <= 30 and isFacing(enemyRoot, myRoot.Position, COS[40]) end
				if toolName == "Death Counter" then return dist <= 600 and isFacing(enemyRoot, myRoot.Position, COS[35]) end
				return false
			end
			if data.Special == "SolarCleave" then
				return boxCheck(enemyRoot, myRoot.Position, 140, 15, 10)
			end
			if data.Special == "QuickSlice" then
				local center = (enemyRoot.CFrame * CFrame.new(0, 0, -19)).Position
				return (center - myRoot.Position).Magnitude <= 22
			end
			local reqDist = data.Dist or (tonumber(getgenv().AutoCounterDist) or 20)
			if dist > reqDist then return false end
			if not data.NoDir and not data.NoFace then
				local angle = data.Angle or 90
				local cosT = COS[angle] or math.cos(math.rad(angle))
				if not isFacing(enemyRoot, myRoot.Position, cosT) then return false end
			end
			return true
		end
		
		local function shouldBlock(enemyModel, track, myRoot)
			local animId = animDigits(track.Animation and track.Animation.AnimationId)
			local data = animId and _G.BlockData[animId] or nil
			if not data then return false end
			return shouldCounter(enemyModel, track, myRoot, data, animId, true, nil)
		end
		
		local fHeld = false
		
		local function fireF(isDown)
			getgenv().ScriptHoldingF = isDown
			local char = player.Character
			if char then
				local hum = char:FindFirstChild("Humanoid")
				if hum then hum.AutoRotate = not isDown end
				local comm = char:FindFirstChild("Communicate")
				if comm then
					comm:FireServer({ Goal = isDown and "KeyPress" or "KeyRelease", Key = Enum.KeyCode.F })
				end
			end
		end
		
		local function getHotbarFrame()
			local pg = player:FindFirstChild("PlayerGui")
			local hotbar = pg and pg:FindFirstChild("Hotbar")
			local backpack = hotbar and hotbar:FindFirstChild("Backpack")
			return backpack and backpack:FindFirstChild("Hotbar")
		end
		
		local function isHotbarToolReady(toolName)
			local hotbar = getHotbarFrame()
			if not hotbar then return false end
			for i = 1, 4 do
				local slot = hotbar:FindFirstChild(tostring(i))
				local base = slot and slot:FindFirstChild("Base")
				if base then
					local toolLabel = base:FindFirstChild("ToolName")
					if toolLabel and toolLabel.Text == toolName then
						return base:FindFirstChild("Cooldown") == nil
					end
				end
			end
			return false
		end
		
		local function equipBestCounterTool(whitelist)
			local char = player.Character
			local backpack = player.Backpack
			if not (char and backpack) then return end
			local items = { "Death Blow", "Death Counter", "Split Second Counter", "Prey's Peril" }
			for _, itemName in ipairs(items) do
				if (not whitelist) or whitelist[itemName] then
					local tool = backpack:FindFirstChild(itemName)
					if tool and tool:IsA("Tool") then
						tool.Parent = char
						task.defer(function()
							if tool and tool.Parent == char and backpack then
								tool.Parent = backpack
							end
						end)
						Replicated.Replication:FireServer({ Name = tool.Name, Effect = "Cooldown" })
						break
					end
				end
			end
		end
		
		local function performCounter(toolName)
			if not toolName then return false end
			local hotbar = getHotbarFrame()
			if not hotbar then return false end
			local found = false
			for i = 1, 4 do
				local slot = hotbar:FindFirstChild(tostring(i))
				local base = slot and slot:FindFirstChild("Base")
				if base then
					local toolLabel = base:FindFirstChild("ToolName")
					if toolLabel and toolLabel.Text == toolName then
						if base:FindFirstChild("Cooldown") == nil then found = true end
						break
					end
				end
			end
			if not found then return false end
			local backpack = player.Backpack
			local char = player.Character
			local tool = (char and char:FindFirstChild(toolName)) or (backpack and backpack:FindFirstChild(toolName))
			if not tool then return false end
			if fHeld then fHeld = false fireF(false) end
			equipBestCounterTool({ [toolName] = true })
			return true
		end
		
		local function desiredToolFromSelf()
			local c = player.Character
			if not c then return nil end
			local charType = c:GetAttribute("Character")
			local ulted = c:GetAttribute("Ulted") == true
			if charType == "Bald" and ulted then
				if not getgenv().UseDeathMoves then return nil end
				return "Death Counter"
			end
			if charType == "Batter" and ulted then
				if not getgenv().UseDeathMoves then return nil end
				return "Death Blow"
			end
			if charType == "Blade" and not ulted then return "Split Second Counter" end
			if charType == "Hunter" and not ulted then return "Prey's Peril" end
			return nil
		end
		
		local ActiveCounterPacks = setmetatable({}, { __mode = "k" })
		local ActiveBlockPacks = setmetatable({}, { __mode = "k" })
		local AnimWatch = {}
		
		local function trackIsPlayingSafe(track)
			local ok, v = pcall(function() return track.IsPlaying end)
			return ok and v or false
		end
		
		local function updateRaycastEveryFrame(info, track, myRoot)
			local impactPos = GetRaycastImpact(info.EnemyRoot, info.AnimId, info.Data)
			info.LastImpactPos = impactPos
			if not impactPos then return false end
			if not tposWindowOk(track, info.Data) then return false end
			local req = info.Data.Dist or (tonumber(getgenv().AutoCounterDist) or 20)
			return (impactPos - myRoot.Position).Magnitude <= req
		end
		
		local ActiveCounterTracksCount = 0
		local CounterLoopConnection = nil
		local UpdateCounterLoopState
		
		local function disconnectPack(pack)
			if not pack then return end
			local old = pack.activeTracks
			if old then
				for _, info in pairs(old) do
					if info then
						info.isActionActive = false
						if info.EnemyRoot then RaycastTrack[info.EnemyRoot] = nil EnemyMotionTrack[info.EnemyRoot] = nil end
						if info.__counted then info.__counted = nil if UpdateCounterLoopState then UpdateCounterLoopState(-1) end end
					end
				end
				pack.activeTracks = nil
			end
			local oldB = pack.blockTracks
			if oldB then
				for _, info in pairs(oldB) do
					if info then
						info.isActionActive = false
						if info.EnemyRoot then RaycastTrack[info.EnemyRoot] = nil end
					end
				end
				pack.blockTracks = nil
			end
			for k, c in pairs(pack) do if typeof(c) == "RBXScriptConnection" then c:Disconnect() end pack[k] = nil end
		end
		
		local function onEnemyTrackStarted(plr, eChar, eHum, track)
			local animId = animDigits(track.Animation and track.Animation.AnimationId)
			local pack = AnimWatch[plr]
			if not pack then return end
			local cData = _G.CounterData[animId] or nil
			local bData = _G.BlockData[animId] or nil
			if not cData and not bData then return end
			local enemyRoot = eChar and eChar:FindFirstChild("HumanoidRootPart")
			if not enemyRoot then return end
			pack.activeTracks = pack.activeTracks or {}
			pack.blockTracks = pack.blockTracks or {}
			if cData then
				pack.activeTracks[track] = pack.activeTracks[track] or {
					isActionActive = true, Fired = false, Char = eChar, EnemyRoot = enemyRoot,
					AnimId = animId, Data = cData, LastImpactPos = nil
				}
				ActiveCounterPacks[plr] = true
				pack.activeTracks[track].isActionActive = true
				if not pack.activeTracks[track].__counted then
					pack.activeTracks[track].__counted = true
					if UpdateCounterLoopState then UpdateCounterLoopState(1) end
				end
			end
			if bData then
				pack.blockTracks[track] = pack.blockTracks[track] or {
					isActionActive = true, Char = eChar, EnemyRoot = enemyRoot, AnimId = animId, Data = bData
				}
				ActiveBlockPacks[plr] = true
				pack.blockTracks[track].isActionActive = true
			end
			track.Stopped:Connect(function()
				local p2 = AnimWatch[plr]
				if not p2 then return end
				if p2.activeTracks then
					local info = p2.activeTracks[track]
					if info then
						info.isActionActive = false
						if info.EnemyRoot then RaycastTrack[info.EnemyRoot] = nil EnemyMotionTrack[info.EnemyRoot] = nil end
						if info.__counted then info.__counted = nil UpdateCounterLoopState(-1) end
						p2.activeTracks[track] = nil
					end
					if next(p2.activeTracks) == nil then ActiveCounterPacks[plr] = nil end
				end
				if p2.blockTracks then
					local binfo = p2.blockTracks[track]
					if binfo then
						binfo.isActionActive = false
						if binfo.EnemyRoot then RaycastTrack[binfo.EnemyRoot] = nil end
						p2.blockTracks[track] = nil
					end
					if next(p2.blockTracks) == nil then ActiveBlockPacks[plr] = nil end
				end
			end)
		end
		
		local ParrySounds = {
			["12244488517"]=true,["2232392291"]=true,["4306994267"]=true,["4306994923"]=true,
			["4306994664"]=true,["4306995205"]=true,["13391515385"]=true,["13391515477"]=true,
			["13391515421"]=true,["13391515338"]=true,
		}
		local SoundParryBlockOverrideUntil = 0
		local _parrySoundWasPlaying = setmetatable({}, { __mode = "k" })
		local _parrySoundConns = setmetatable({}, { __mode = "k" })
		local _parryHRPChildConn = nil
		
		local function _soundParryShouldCancel(hrp)
			local liveFolder = workspace:FindFirstChild("Live")
			if not liveFolder then return false end
			for _, enemy in ipairs(liveFolder:GetChildren()) do
				if enemy.Name ~= player.Name then
					local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
					if enemyRoot then
						local dist = (enemyRoot.Position - hrp.Position).Magnitude
						if dist <= 12 and enemy:FindFirstChild("Counter") then return true end
						if dist < 10 then
							local isUlted = enemy:GetAttribute("Ulted")
							local charType = enemy:GetAttribute("Character")
							if isUlted and charType == "Batter" then
								if getgenv().BatterUltSafeState[enemy] == false then return true end
							end
							if isUlted and charType == "Bald" then return true end
						end
					end
				end
			end
			return false
		end
		
		local function _tapM1()
			pcall(function()
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
				task.wait()
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
			end)
		end
		
		local function _handleParrySoundStart(sound)
			if not getgenv().SoundParry then return end
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			if _soundParryShouldCancel(hrp) then return end
			local m1Held = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			if not m1Held then
				SoundParryBlockOverrideUntil = tick() + 0.02
				if fHeld then fHeld = false fireF(false) end
				_tapM1()
			end
		end
		
		local function _detachParryListeners()
			if _parryHRPChildConn then _parryHRPChildConn:Disconnect() _parryHRPChildConn = nil end
			for s, c in pairs(_parrySoundConns) do if c then c:Disconnect() end _parrySoundConns[s] = nil _parrySoundWasPlaying[s] = nil end
		end
		
		local function _attachSound(sound)
			if _parrySoundConns[sound] then return end
			_parrySoundWasPlaying[sound] = sound.IsPlaying
			if sound.IsPlaying then _handleParrySoundStart(sound) end
			_parrySoundConns[sound] = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
				local was = _parrySoundWasPlaying[sound]
				local nowPlaying = sound.IsPlaying
				_parrySoundWasPlaying[sound] = nowPlaying
				if nowPlaying and not was then _handleParrySoundStart(sound) end
			end)
		end
		
		local function _bindParryToChar(char)
			_detachParryListeners()
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then
				local tmp
				tmp = char.ChildAdded:Connect(function(ch)
					if ch.Name == "HumanoidRootPart" then tmp:Disconnect() _bindParryToChar(char) end
				end)
				return
			end
			for _, child in ipairs(hrp:GetChildren()) do
				if child:IsA("Sound") then
					local cleanId = child.SoundId and child.SoundId:match("%d+")
					if cleanId and ParrySounds[cleanId] then _attachSound(child) end
				end
			end
			_parryHRPChildConn = hrp.ChildAdded:Connect(function(ch)
				if ch:IsA("Sound") then
					local cleanId = ch.SoundId and ch.SoundId:match("%d+")
					if cleanId and ParrySounds[cleanId] then _attachSound(ch) end
				end
			end)
		end
		
		_bindParryToChar(player.Character)
		player.CharacterAdded:Connect(_bindParryToChar)
		
		local doBlock = false
		local blockTarget = nil
		local scriptedBlockActive = false
		local m1SequenceActive = false
		local m1Cancel = false
		local blockReleasePending = false
		
		local function startM1Sequence(count, interval)
			if m1SequenceActive then return end
			m1SequenceActive = true
			m1Cancel = false
			local conn
			conn = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					m1Cancel = true
					conn:Disconnect()
				end
			end)
			task.spawn(function()
				for i = 1, count do
					if m1Cancel then break end
					_tapM1()
					if i < count then task.wait(interval) end
				end
				m1SequenceActive = false
				if conn then conn:Disconnect() end
			end)
		end
		
		local function CounterLoopAction()
			local myChar = player.Character
			if not myChar then return end
			local myRoot = myChar:FindFirstChild("HumanoidRootPart")
			if not myRoot then return end
			doBlock = false
			blockTarget = nil
			local autoBlock = getgenv().AutoBlocking
			local autoCounter = getgenv().AutoCounter
			if not (autoBlock or autoCounter) then
				if fHeld then fHeld = false fireF(false) end
				scriptedBlockActive = false
				return
			end
			local didCounter = false
			local now = tick()
			local counterDst = tonumber(getgenv().AutoCounterDist) or 7.5
			local blockDst = tonumber(getgenv().AutoBlockDist) or 9
			local scanDst = counterDst > blockDst and counterDst or blockDst
			local m1Enemy, m1d2 = enemyM1ingNearby(scanDst)
			local counterDst2 = counterDst * counterDst
			local blockDst2 = blockDst * blockDst
			local desiredTool = nil
			local canCounterNow = false
			if autoCounter then
				desiredTool = desiredToolFromSelf()
				canCounterNow = desiredTool and isHotbarToolReady(desiredTool) or false
			end
			if autoCounter and canCounterNow then
				if desiredTool == "Death Counter" or desiredTool == "Death Blow" then
					if isSelfSoundPlaying("rbxassetid://16139753098") or isSelfSoundPlaying("rbxassetid://17294130580") then
						if performCounter(desiredTool) then didCounter = true end
					end
				end
				if not didCounter then
					for plr in pairs(ActiveCounterPacks) do
						local pack = AnimWatch[plr]
						local active = pack and pack.activeTracks
						if active then
							for track, info in pairs(active) do
								if info and info.isActionActive and not info.Fired then
									if not trackIsPlayingSafe(track) then
										if info.EnemyRoot then RaycastTrack[info.EnemyRoot] = nil EnemyMotionTrack[info.EnemyRoot] = nil end
										if info.__counted then info.__counted = nil if UpdateCounterLoopState then UpdateCounterLoopState(-1) end end
										active[track] = nil
										if next(active) == nil then ActiveCounterPacks[plr] = nil end
									else
										local moveData = info.Data
										local wl = ToolWhitelists[desiredTool]
										local okToFire = false
										if (not wl) or wl[moveData.Name] then
											if moveData.RaycastType then
												okToFire = updateRaycastEveryFrame(info, track, myRoot)
											else
												okToFire = shouldCounter(info.Char, track, myRoot, info.Data, info.AnimId, false, desiredTool)
											end
										end
										if okToFire and not info.Fired then
											if performCounter(desiredTool) then
												info.Fired = true
												didCounter = true
												break
											end
										end
									end
								end
							end
						end
						if didCounter then break end
					end
				end
				if not didCounter then
					for char, active in pairs(scatterActive) do
						if active and char.Parent and char:FindFirstChild("HumanoidRootPart") then
							local enemyRoot = char.HumanoidRootPart
							local sData = scatterData[char]
							if sData then
								if now - sData.startTime > 3 then
									scatterActive[char] = nil scatterData[char] = nil
								else
									local enemyVel = enemyRoot.AssemblyLinearVelocity or Vector3.zero
									local predPos = enemyRoot.Position + (enemyVel * sData.predict)
									local boxCFrame = CFrame.new(predPos) * enemyRoot.CFrame.Rotation
									local rel = boxCFrame:PointToObjectSpace(myRoot.Position)
									local bs = sData.boxSize
									local depthBehind = bs.Z * 0.2
									local depthFront = -(bs.Z * 0.8)
									local okToFire = (math.abs(rel.X) <= (bs.X * 0.5))
										and (math.abs(rel.Y) <= (bs.Y * 0.5))
										and (rel.Z <= depthBehind and rel.Z >= depthFront)
									if okToFire then
										if performCounter(desiredTool) then
											scatterActive[char] = nil scatterData[char] = nil
											didCounter = true break
										else
											doBlock = true
											getgenv().AutoBlockTarget = Players:GetPlayerFromCharacter(char)
										end
									end
								end
							end
						else
							scatterActive[char] = nil scatterData[char] = nil
						end
					end
				end
				if not didCounter then
					if m1Enemy and m1d2 and m1d2 <= counterDst2 then
						if performCounter(desiredTool) then didCounter = true end
					end
				end
			end
			if autoBlock and not didCounter then
				local m1Held = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
				local manualF = UserInputService:IsKeyDown(Enum.KeyCode.F)
				local preBlock = doBlock
				local preBlockTarget = getgenv().AutoBlockTarget
				local bestBlockPlr = nil
				local bestBlockD2 = math.huge
				local soundParryLock = getgenv().SoundParry and tick() < SoundParryBlockOverrideUntil
				if m1Enemy and m1d2 and m1d2 <= blockDst2 then
					bestBlockPlr = Players:GetPlayerFromCharacter(m1Enemy)
					bestBlockD2 = m1d2
				end
				if not soundParryLock and not preBlock then
					for plr in pairs(ActiveBlockPacks) do
						local pack = AnimWatch[plr]
						local bt = pack and pack.blockTracks
						if not bt then
							ActiveBlockPacks[plr] = nil
						else
							for track, info in pairs(bt) do
								if info and info.isActionActive then
									if not trackIsPlayingSafe(track) then
										if info.EnemyRoot then RaycastTrack[info.EnemyRoot] = nil end
										bt[track] = nil
										if next(bt) == nil then ActiveBlockPacks[plr] = nil end
									else
										if shouldCounter(info.Char, track, myRoot, info.Data, info.AnimId, true, nil) then
											local enemyRoot = info.EnemyRoot
											local delta = enemyRoot and (enemyRoot.Position - myRoot.Position) or nil
											local d2 = delta and (delta.X * delta.X + delta.Y * delta.Y + delta.Z * delta.Z) or math.huge
											if d2 < bestBlockD2 then
												bestBlockD2 = d2
												bestBlockPlr = plr
											end
										end
									end
								end
							end
						end
					end
				end
				if soundParryLock then
					doBlock = false
					blockTarget = nil
				elseif preBlock then
					doBlock = true
					blockTarget = blockTarget or preBlockTarget
				else
					doBlock = bestBlockPlr ~= nil
					blockTarget = bestBlockPlr
				end
				if manualF or m1Held then doBlock = false blockTarget = nil end
				if doBlock then
					if not fHeld then fHeld = true if not manualF then fireF(true) end end
					scriptedBlockActive = not manualF
					getgenv().AutoBlockTarget = blockTarget
					blockReleasePending = false  -- cancel any pending release if we re-entered block
				else
					if fHeld and scriptedBlockActive then
						if not blockReleasePending then
							blockReleasePending = true
							local releaseDelay = tonumber(getgenv().BlockReleaseDelay) or 0.35
							task.delay(releaseDelay, function()
								if not blockReleasePending then return end  -- cancelled
								blockReleasePending = false
								if fHeld and scriptedBlockActive then
									if getgenv().AutoM1AfterBlock and not m1SequenceActive then
										local count = tonumber(getgenv().M1Count) or 1
										local interval = tonumber(getgenv().M1Interval) or 0.2
										startM1Sequence(count, interval)
									end
									fHeld = false
									local mf = UserInputService:IsKeyDown(Enum.KeyCode.F)
									if not mf then fireF(false) else getgenv().ScriptHoldingF = false end
									scriptedBlockActive = false
									getgenv().AutoBlockTarget = nil
								end
							end)
						end
						-- keep holding the block while the delay counts down
					elseif fHeld then
						fHeld = false
						if not manualF then fireF(false) else getgenv().ScriptHoldingF = false end
						scriptedBlockActive = false
						getgenv().AutoBlockTarget = nil
					else
						scriptedBlockActive = false
						getgenv().AutoBlockTarget = nil
					end
				end
				if getgenv().ScriptHoldingF and not doBlock and not manualF then fireF(false) end
			end
			if fHeld and getgenv().AimbotWhileBlocking and blockTarget and blockTarget.Character then
				local targetChar = blockTarget.Character
				local targetPart = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
				if targetPart then
					local targetPos = targetPart.Position + ((targetPart.AssemblyLinearVelocity or Vector3.zero) * _smoothPing)
					local lookAt = CFrame.lookAt(myRoot.Position, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z))
					myRoot.CFrame = lookAt
				end
			end
		end
		
		UpdateCounterLoopState = function(change)
			if change then ActiveCounterTracksCount = math.max(0, ActiveCounterTracksCount + change) end
			local shouldRun = (ActiveCounterTracksCount > 0) or getgenv().AutoBlocking or getgenv().AutoCounter
			if shouldRun then
				if not CounterLoopConnection then
					CounterLoopConnection = RunService.RenderStepped:Connect(CounterLoopAction)
				end
			else
				if CounterLoopConnection then
					CounterLoopConnection:Disconnect()
					CounterLoopConnection = nil
				end
			end
		end
		
		local function bindPlayer(plr)
			if plr == player then return end
			if AnimWatch[plr] then disconnectPack(AnimWatch[plr]) end
			ActiveCounterPacks[plr] = nil
			ActiveBlockPacks[plr] = nil
			AnimWatch[plr] = { activeTracks = {}, blockTracks = {} }
			local function bindCharacter(char)
				local pack = AnimWatch[plr]
				if not pack then return end
				if pack.humConn then pack.humConn:Disconnect() pack.humConn = nil end
				if pack.animConn then pack.animConn:Disconnect() pack.animConn = nil end
				do
					local old = pack.activeTracks
					if old then
						for track, info in pairs(old) do
							if info then
								info.isActionActive = false
								if info.EnemyRoot then RaycastTrack[info.EnemyRoot] = nil EnemyMotionTrack[info.EnemyRoot] = nil end
								if info.__counted then info.__counted = nil if UpdateCounterLoopState then UpdateCounterLoopState(-1) end end
							end
						end
					end
				end
				pack.activeTracks = {}
				pack.blockTracks = {}
				if not char then return end
				local hum = char:FindFirstChildOfClass("Humanoid")
				if not hum then
					pack.humConn = char.ChildAdded:Connect(function(ch)
						if ch:IsA("Humanoid") then
							if pack.humConn then pack.humConn:Disconnect() pack.humConn = nil end
							bindCharacter(char)
						end
					end)
					return
				end
				local animator = hum:FindFirstChildOfClass("Animator")
				if not animator then
					pack.humConn = hum.ChildAdded:Connect(function(ch)
						if ch:IsA("Animator") then
							if pack.humConn then pack.humConn:Disconnect() pack.humConn = nil end
							bindCharacter(char)
						end
					end)
					return
				end
				pack.animConn = animator.AnimationPlayed:Connect(function(track)
					onEnemyTrackStarted(plr, char, hum, track)
				end)
			end
			bindCharacter(plr.Character)
			AnimWatch[plr].charConn = plr.CharacterAdded:Connect(bindCharacter)
		end
		
		for _, plr in ipairs(Players:GetPlayers()) do bindPlayer(plr) end
		Players.PlayerAdded:Connect(bindPlayer)
		Players.PlayerRemoving:Connect(function(plr)
			local pack = AnimWatch[plr]
			if pack then disconnectPack(pack) AnimWatch[plr] = nil ActiveCounterPacks[plr] = nil ActiveBlockPacks[plr] = nil end
		end)
		
		getgenv().SetAutoBlock = function(v)
			getgenv().AutoBlocking = v
			if not v then fireF(false) end
			UpdateCounterLoopState(0)
		end
		
		getgenv().SetAutoCounter = function(v)
			getgenv().AutoCounter = v
			UpdateCounterLoopState(0)
		end
		
		getgenv().SetAutoBlockDist = function(v) getgenv().AutoBlockDist = tostring(v) end
		getgenv().SetAutoCounterDist = function(v) getgenv().AutoCounterDist = tostring(v) end
		getgenv().SetUseDeathMoves = function(v) getgenv().UseDeathMoves = v end
		getgenv().SetAimbotWhileBlocking = function(v) getgenv().AimbotWhileBlocking = v end
		getgenv().SetAutoM1AfterBlock = function(v) getgenv().AutoM1AfterBlock = v end
		getgenv().SetSoundParry = function(v) getgenv().SoundParry = v end
		getgenv().SetM1Interval = function(v) getgenv().M1Interval = v end
		getgenv().SetM1Count = function(v) getgenv().M1Count = v end
		getgenv().SetBlockReleaseDelay = function(v) getgenv().BlockReleaseDelay = v end
		
		if Tabs and Tabs.Block then
			AutoBlockSec = Tabs.Block:Section({Opened = true, Box = true, BoxBorder = true, Title = "Auto Block & Counter", Icon = "shield" })
			AutoBlockSec:Toggle({
				Title = "Auto Block",
				Flag = "abc_best_block",
				Value = getgenv().AutoBlocking,
				Callback = function(v) getgenv().AutoBlocking = v UpdateCounterLoopState(0) end
			})
			AutoBlockSec:Toggle({
				Title = "Auto Counter",
				Flag = "abc_best_counter",
				Value = getgenv().AutoCounter,
				Callback = function(v) getgenv().AutoCounter = v UpdateCounterLoopState(0) end
			})
			AutoBlockSec:Toggle({
				Title = "Face Threat",
				Flag = "abc_best_face",
				Value = getgenv().AimbotWhileBlocking,
				Callback = function(v) getgenv().AimbotWhileBlocking = v end
			})
			AutoBlockSec:Toggle({
				Title = "Sound Parry",
				Flag = "abc_best_sound",
				Value = getgenv().SoundParry,
				Callback = function(v) getgenv().SoundParry = v end
			})
			AutoBlockSec:Toggle({
				Title = "Use Death Moves",
				Flag = "abc_best_death",
				Value = getgenv().UseDeathMoves,
				Callback = function(v) getgenv().UseDeathMoves = v end
			})
			AutoBlockSec:Slider({
				Title = "Block Distance",
				Flag = "abc_best_blockdist",
				Min = 5,
				Max = 50,
				Default = tonumber(getgenv().AutoBlockDist) or 19.5,
				Decimals = 1,
				Callback = function(v) getgenv().AutoBlockDist = tostring(v) UpdateCounterLoopState(0) end
			})
			AutoBlockSec:Slider({
				Title = "Counter Distance",
				Flag = "abc_best_counterdist",
				Min = 5,
				Max = 50,
				Default = tonumber(getgenv().AutoCounterDist) or 19.5,
				Decimals = 1,
				Callback = function(v) getgenv().AutoCounterDist = tostring(v) UpdateCounterLoopState(0) end
			})
			AutoBlockSec:Slider({
				Title = "Block Release Delay",
				Flag = "abc_best_blockrelease",
				Min = 0,
				Max = 1,
				Default = tonumber(getgenv().BlockReleaseDelay) or 0.6,
				Decimals = 2,
				Callback = function(v) getgenv().BlockReleaseDelay = v end
			})
		end
	end)
end













-- ================ EMOTE0 TAB0 ================ --
function EmoteTab()
	task.spawn(function()
		LimitedEmotesSec = Tabs.Emote:Section({Opened = true, Box = true, BoxBorder = true, Title = "Buy Limited Emotes", Icon = "star" })
		
		MarketplaceService = game:GetService("MarketplaceService")
		ReplicatedStorage = game:GetService("ReplicatedStorage")
		Players = game:GetService("Players")
		LocalPlayer = Players.LocalPlayer
		
		
		local success_info, Info = pcall(function()
		    return require(ReplicatedStorage:WaitForChild("Info"))
		end)
		
		if success_info and Info and Info.Limited then
		
		local productNameToIdMap = {}
		for _, itemInfo in pairs(Info.Limited) do
		    productNameToIdMap[itemInfo.Name] = itemInfo.ID
		end
		
		local success_products, developerProducts = pcall(function()
		    return MarketplaceService:GetDeveloperProductsAsync():GetCurrentPage()
		end)
		
		if success_products and developerProducts then
		    for _, product in ipairs(developerProducts) do
		        if productNameToIdMap[product.Name] then
		            
		            local NewButton = LimitedEmotesSec:Button({
		                Title = product.Name .. " (" .. product.PriceInRobux .. " R$)",
		                Callback = function()
		                    local giftData = {
		                        {
		                            Goal = "Gift Gamepass",
		                            GiftData = {
		                                Receiver = LocalPlayer.UserId, 
		                                Gamepass = product.ProductId
		                            }
		                        }
		                    }
		
		                    local character = LocalPlayer.Character
		                    local communicate = character and character:FindFirstChild("Communicate")
		                    
		                    if communicate then
		                        communicate:FireServer(unpack(giftData))
		                    else
		                    end
		                end
		            })
		
		            local targetUI = NewButton.Element or NewButton.Instance
		
		            if targetUI and product.IconImageAssetId then
		                local Icon = Instance.new("ImageLabel")
		                Icon.Name = "RightSideIcon"
		                Icon.Parent = targetUI
		               
		                Icon.Size = UDim2.new(0, 26, 0, 26) 
		                Icon.AnchorPoint = Vector2.new(1, 0.5) 
		                Icon.Position = UDim2.new(1, -10, 0.5, 0)
		                Icon.BackgroundTransparency = 1
		                Icon.Image = "rbxassetid://" .. tostring(product.IconImageAssetId)
		                Icon.ZIndex = targetUI.ZIndex + 1 
		                
		                local UICorner = Instance.new("UICorner")
		                UICorner.CornerRadius = UDim.new(0, 4)
		                UICorner.Parent = Icon
		            end
		        end
		    end
		end
		
		
		
		
		
		
		end -- shop part

		CSLimitedEmotesex = Tabs.Emote:Section({Opened = true, Box = true, BoxBorder = true, Title = "Client Side Limited Emotes", Icon = "star" })
		
		Players = game:GetService("Players")
		TweenService = game:GetService("TweenService")
		ReplicatedStorage = game:GetService("ReplicatedStorage")
		CollectionService = game:GetService("CollectionService")
		Debris = game:GetService("Debris")
		LocalPlayer = Players.LocalPlayer
		local function PlayEmote(cfg)
		    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		    local humanoid = character:WaitForChild("Humanoid")
		    local anim = Instance.new("Animation")
		    anim.AnimationId = cfg.animId:find("rbxassetid://") and cfg.animId
		                       or ("rbxassetid://" .. cfg.animId)
		    humanoid:LoadAnimation(anim):Play()
		    for _, s in ipairs(cfg.sounds or {}) do
		        task.delay(s.Delay or 0, function()
		            local sound = Instance.new("Sound")
		            sound.SoundId = s.SoundId
		            sound.Volume = s.Volume or 1
		            sound.Looped = s.Looped or false
		            sound.Parent = character:FindFirstChild("Torso")
		                          or character:FindFirstChild("HumanoidRootPart")
		                          or workspace
		            sound:Play()
		        end)
		    end
		    task.delay(0.1, function()
		        local bind
		        if cfg.useFolderBind then
		            bind = Instance.new("Folder")
		            bind.Name = cfg.accName or "PrideBind"
		        else
		            bind = Instance.new("Accessory")
		            bind.Name = cfg.accName or ("#EmoteHolder_" .. math.random(1, 100000))
		        end
		        bind:SetAttribute("EmoteProperty", true)
		        bind.Parent = character
		        if cfg.useCollection then
		            CollectionService:AddTag(bind, "emoteendstuff" .. character.Name)
		        end
		        require(ReplicatedStorage.Emotes.VFX):MainFunction({
		            Character = character,
		            vfxName = cfg.vfxName,
		            SpecificModule = ReplicatedStorage.Emotes.VFX,
		            AnimSent = tonumber(cfg.animId:match("%d+")),
		            RealBind = bind,
		            NoInsertion = cfg.noInsertion or nil,
		            Colour = cfg.colour or nil,
		            CanRotate = cfg.canRotate or nil,
		        })
		        if cfg.auraSetup and cfg.postDelay then
		            task.delay(cfg.postDelay, function()
		                if bind and bind.Parent then
		                    cfg.auraSetup(character, bind)
		                end
		            end)
		        end
		    end)
		end
		local EmoteList = {
		    {
		        Title = "Final Stand",
		        animId = "rbxassetid://113876851900426",
		        vfxName = "Final Stand",
		        postDelay = 9,
		        auraSetup = function(character)
		            if not workspace:FindFirstChild("Live") then return end
		            if not workspace.Live:FindFirstChild(character.Name) then return end
		            local sounds = {
		                { SoundId = "rbxassetid://112446641141594", Volume = 1 },
		                { SoundId = "rbxassetid://98080224862986", Volume = 0.3 },
		            }
		            for _, info in ipairs(sounds) do
		                local s = Instance.new("Sound")
		                s.SoundId = info.SoundId
		                s.Volume = info.Volume
		                s.Looped = true
		                s.Parent = character:FindFirstChild("Torso")
		                          or character:FindFirstChild("HumanoidRootPart")
		                s:Play()
		                task.delay(60, function()
		                    TweenService:Create(s, TweenInfo.new(0.5), { Volume = 0 }):Play()
		                    task.delay(0.75, function() if s then s:Destroy() end end)
		                end)
		            end
		            local auraClone = ReplicatedStorage.Emotes.VFX.VfxMods.FS.vfx.Aura:Clone()
		            for _, part in ipairs(auraClone:GetChildren()) do
		                local target = (part.Name == "HumanoidRootPart")
		                    and (character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart"))
		                    or character:FindFirstChild(part.Name)
		                if target then
		                    for _, fx in ipairs(part:GetChildren()) do
		                        if fx:IsA("ParticleEmitter") then fx.LockedToPart = true end
		                        fx:SetAttribute("LimitedAura", true)
		                        fx.Parent = target
		                        task.delay(60, function()
		                            if fx:IsA("ParticleEmitter") then fx.Enabled = false
		                            else
		                                for _, sub in ipairs(fx:GetChildren()) do
		                                    if sub:IsA("ParticleEmitter") then sub.Enabled = false end
		                                end
		                            end
		                        end)
		                        task.delay(65, function() if fx then fx:Destroy() end end)
		                    end
		                end
		            end
		            auraClone:Destroy()
		        end,
		    },
		    {
		        Title = "Inner Rage",
		        animId = "rbxassetid://96993907314948",
		        vfxName = "Energy Explosion",
		        useCollection = true,
		        noInsertion = true,
		        colour = Color3.fromRGB(
		            math.random(0,255), math.random(0,255), math.random(0,255)
		        ),
		        _useDirectCallback = true,
		    },
		    {
		        Title = "Shadow Eruption",
		        animId = "rbxassetid://121032789756540",
		        vfxName = "Shadow Eruption",
		        sounds = {
		            { SoundId = "rbxassetid://117425361961655", Volume = 0, Delay = 0 },
		        },
		        postDelay = 8.1,
		        auraSetup = function(character)
		            if not workspace:FindFirstChild("Live") then return end
		            if not workspace.Live:FindFirstChild(character.Name) then return end
		            auraSource = ReplicatedStorage:WaitForChild("Emotes"):WaitForChild("AuraNew")
		            auraFolder = Instance.new("Folder")
		            auraFolder.Name = "AuraHolder"
		            auraFolder.Parent = character
		            for _, part in ipairs(auraSource:GetChildren()) do
		                local charPart = character:FindFirstChild(part.Name)
		                if charPart then
		                    clone = part:Clone()
		                    clone.Parent = auraFolder
		                    clone:SetAttribute("LimitedAura", true)
		                    task.delay(65, function() if clone then clone:Destroy() end end)
		                    for _, fx in ipairs(clone:GetDescendants()) do
		                        if fx:IsA("Trail") or fx:IsA("Beam") or fx:IsA("ParticleEmitter") then
		                            fx.Enabled = true
		                            task.delay(60, function() if fx then fx.Enabled = false end end)
		                        end
		                    end
		                end
		            end
		            local loopSound = Instance.new("Sound")
		            loopSound.SoundId = "rbxassetid://128082194939921"
		            loopSound.Looped = true
		            loopSound.Volume = 1
		            loopSound.Parent = character:FindFirstChild("Torso")
		                             or character:FindFirstChild("HumanoidRootPart")
		            loopSound:Play()
		            Debris:AddItem(loopSound, 80)
		            task.delay(60, function()
		                TweenService:Create(loopSound, TweenInfo.new(1), { Volume = 0 }):Play()
		                Debris:AddItem(loopSound, 1.2)
		                for _, v in ipairs(character:GetDescendants()) do
		                    if v:GetAttribute("aura") and
		                       (v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail")) then
		                        v.Enabled = false
		                        Debris:AddItem(v, 5)
		                    end
		                end
		            end)
		        end,
		    },
		    {
		        Title = "Divine Form",
		        animId = "rbxassetid://116187503451999",
		        vfxName = "Divine Form",
		        postDelay = 7,
		        auraSetup = function(character)
		            if not workspace:FindFirstChild("Live") then return end
		            if not workspace.Live:FindFirstChild(character.Name) then return end
		            function applyAura(char, duration)
		                auraSource = ReplicatedStorage.Emotes.VFX.VfxMods.Evolved.vfx.Folder
		                folder = Instance.new("Folder")
		                folder.Name = "AuraHolder"
		                folder:SetAttribute("DivineForm", true)
		                folder:SetAttribute("LimAura", true)
		                folder:SetAttribute("EmoteEffect", true)
		                folder.Parent = char
		                for _, obj in ipairs(auraSource:GetChildren()) do
		                    if obj:IsA("BasePart") then
		                        bodyPart = char:FindFirstChild(obj.Name)
		                        if bodyPart then
		                            clone = obj:Clone()
		                            clone.Transparency = 1
		                            clone.Massless = true
		                            clone.Name = tostring(math.random(1, 1000))
		                            clone:SetAttribute("LimAura", true)
		                            clone.Parent = folder
		                            local weld = Instance.new("Weld")
		                            weld.Part0 = bodyPart
		                            weld.Part1 = clone
		                            weld.Parent = clone
		                            for _, fx in ipairs(clone:GetDescendants()) do
		                                if fx:IsA("ParticleEmitter") or fx:IsA("Beam") then
		                                    fx:SetAttribute("LimitedAura", true)
		                                    task.delay(duration, function() if fx then fx:Destroy() end end)
		                                    task.delay(duration - 2, function() if fx then fx.Enabled = false end end)
		                                end
		                            end
		                            task.delay(duration, function() if clone and clone.Parent then clone:Destroy() end end)
		                        end
		                    end
		                end
		            end
		            applyAura(character, 4)
		            task.spawn(function()
		                task.wait(0.14)
		                applyAura(character, 244)
		            end)
		        end,
		    },
		    {
		        Title = "The Strongest",
		        animId = "rbxassetid://86505219150915",
		        vfxName = "Boss Raid",
		        useFolderBind = true,
		        accName = "PrideBind",
		        sounds = {
		            { SoundId = "rbxassetid://117787451950766", Volume = 2, Delay = 0 },
		            { SoundId = "rbxassetid://97998065677521", Volume = 1.85, Delay = 0.01 },
		            { SoundId = "rbxassetid://99535007576182", Volume = 2, Delay = 2.29, Looped = true },
		        },
		    },
		    {
		        Title = "Boundless Rage",
		        animId = "rbxassetid://107649573628906",
		        vfxName = "Boundless Rage",
		        postDelay = 4,
		        auraSetup = function(character)
		            auraTemplate = ReplicatedStorage.Emotes.VFX.VfxMods.Boundless.vfx.AuraChar:Clone()
		            Debris:AddItem(auraTemplate, 5)
		            noRot = character:FindFirstChild("NoRotate")
		            if noRot then noRot:Destroy() end
		            sound = Instance.new("Sound")
		            sound.SoundId = "rbxassetid://81055990581650"
		            sound.Looped = true
		            sound.Volume = 1
		            sound.Name = "CrushEmoteAmbience"
		            sound.Parent = character:FindFirstChild("HumanoidRootPart")
		                          or character:FindFirstChild("Torso")
		                          or character
		            sound:Play()
		            for _, part in ipairs(auraTemplate:GetChildren()) do
		                if part:IsA("BasePart") then
		                    charPart = character:FindFirstChild(part.Name)
		                    if charPart then
		                        for _, obj in ipairs(part:GetChildren()) do
		                            if obj:IsA("Attachment") or obj:IsA("ParticleEmitter") then
		                                clone = obj:Clone()
		                                clone:SetAttribute("LimitedAura", true)
		                                clone.Parent = charPart
		                                task.delay(60, function()
		                                    TweenService:Create(sound, TweenInfo.new(0.5), { Volume = 0 }):Play()
		                                    task.delay(0.75, function()
		                                        if sound and sound.Parent then sound:Destroy() end
		                                    end)
		                                    if clone:IsA("ParticleEmitter") then
		                                        clone.Enabled = false
		                                    else
		                                        for _, fx in ipairs(clone:GetChildren()) do
		                                            if fx:IsA("ParticleEmitter") or fx:IsA("Beam") then
		                                                fx.Enabled = false
		                                            end
		                                        end
		                                    end
		                                end)
		                                task.delay(65, function()
		                                    if clone and clone.Parent then clone:Destroy() end
		                                end)
		                            end
		                        end
		                    end
		                end
		            end
		            auraTemplate:Destroy()
		        end,
		    },
		    {
		        Title = "The Fallen",
		        animId = "rbxassetid://133818134745501",
		        vfxName = "Pride",
		        canRotate = true,
		        accName = "DismantleEffect",
		        sounds = {
		            { SoundId = "rbxassetid://93369149563360", Volume = 2, Delay = 0.1 },
		        },
		    },
		    {
		        Title = "True Aura",
		        animId = "rbxassetid://103668868712897",
		        vfxName = "True Aura",
		        useCollection = true,
		        sounds = {
		            { SoundId = "rbxassetid://83049960731792", Volume = 3, Delay = 0.1 },
		        },
		    },
		}
		function InnerRageCallback()
		    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		    humanoid = character:WaitForChild("Humanoid")
		    baseColor = Color3.fromRGB(
		        math.random(100,255), math.random(50,150), math.random(50,150)
		    )
		    randColor = Color3.fromRGB(
		        math.random(0,255), math.random(0,255), math.random(0,255)
		    )
		    local trackAnim = Instance.new("Animation")
		    trackAnim.AnimationId = "rbxassetid://96993907314948"
		    local track = humanoid:LoadAnimation(trackAnim)
		    track:Play()
		    track.Stopped:Connect(function()
		        local loopAnim = Instance.new("Animation")
		        loopAnim.AnimationId = "rbxassetid://127234845846317"
		        humanoid:LoadAnimation(loopAnim):Play()
		    end)
		    acc = Instance.new("Accessory")
		    acc.Name = "#EmoteHolder_" .. math.random(1, 100000)
		    acc.Parent = character
		    CollectionService:AddTag(acc, "emoteendstuff" .. character.Name)
		    require(ReplicatedStorage.Emotes.VFX):MainFunction({
		        Character = character,
		        vfxName = "Energy Explosion",
		        AnimSent = 96993907314948,
		        RealBind = acc,
		        NoInsertion = true,
		        Colour = randColor,
		    })
		    fxList = {}
		    task.delay(1.3, function()
		        if not acc.Parent then return end
		        hairHandles = {}
		        for _, child in ipairs(character.FakeHead:GetChildren()) do
		            if child:IsA("Accessory") and child:FindFirstChild("Handle")
		               and child.Handle:FindFirstChild("HairAttachment") then
		                handle = child.Handle
		                table.insert(hairHandles, handle)
		                for _, mesh in ipairs(handle:GetChildren()) do
		                    if mesh:IsA("SpecialMesh") then
		                        mesh:SetAttribute("basetext", mesh.TextureId)
		                    end
		                end
		            end
		        end
		        for _, hair in ipairs(hairHandles) do
		            clone = hair:Clone()
		            weld = Instance.new("Weld")
		            weld.Part0 = clone
		            weld.Part1 = hair
		            weld.Parent = clone
		            clone.Parent = workspace.Thrown
		            hair.Transparency = 1
		            TweenService:Create(hair, TweenInfo.new(0.25), { Transparency = 0 }):Play()
		            mesh = hair:FindFirstChildOfClass("SpecialMesh")
		            if mesh then
		                mesh.TextureId = ""
		                glow = ReplicatedStorage.Resources.DeathEffect.Template:Clone()
		                glow.Color3 = Color3.new(baseColor.R*5, baseColor.G*5, baseColor.B*5)
		                glow.Parent = clone
		            end
		        end
		        auraHolder = Instance.new("Folder")
		        auraHolder.Name = "AuraHolder"
		        auraHolder:SetAttribute("LimAura", true)
		        auraHolder:SetAttribute("EmoteEffect", true)
		        auraHolder.Parent = character
		        task.delay(203, function() if auraHolder then auraHolder:Destroy() end end)
		        for _, obj in ipairs(ReplicatedStorage.Emotes.AuraReal:GetChildren()) do
		            clone = obj:Clone()
		            clone:SetAttribute("LimAura", true)
		            if clone:IsA("Attachment") then
		                clone.Parent = character.PrimaryPart
		            else
		                weld = Instance.new("Weld")
		                weld.Part0 = character.PrimaryPart
		                weld.Part1 = clone
		                weld.Parent = clone
		            end
		            for _, fx in ipairs(clone:GetDescendants()) do
		                if fx:IsA("ParticleEmitter") or fx:IsA("PointLight") then
		                    fx.Enabled = false
		                    fx:SetAttribute("LimitedAura", true)
		                    fx:SetAttribute("InnerRageAura", true)
		                    if fx:IsA("ParticleEmitter") then fx.Color = ColorSequence.new(baseColor) end
		                    if fx:IsA("PointLight") then fx.Color = baseColor; fx.Brightness = 1.3 end
		                    table.insert(fxList, fx)
		                end
		            end
		            task.delay(203, function() if clone then clone:Destroy() end end)
		        end
		    end)
		    task.delay(5.3, function()
		        if not acc.Parent then return end
		        for _, fx in ipairs(fxList) do fx.Enabled = true end
		        task.wait(0.05)
		        for _, t in ipairs(humanoid:GetPlayingAnimationTracks()) do
		            if t.Animation.AnimationId == "rbxassetid://127234845846317" then
		                t:Stop()
		                finalAnim = Instance.new("Animation")
		                finalAnim.AnimationId = "rbxassetid://117177504280717"
		                humanoid:LoadAnimation(finalAnim):Play()
		            end
		        end
		    end)
		end
		for _, emote in ipairs(EmoteList) do
		    CSLimitedEmotesex:Button({
		        Title = emote.Title,
		        Icon = "mouse-pointer-click",
		        IconAlign = "Right",
		        Locked = false,
		        LockedTitle = "Locked",
		        Justify = "Between",
		        Callback = emote._useDirectCallback
		            and InnerRageCallback
		            or function() PlayEmote(emote) end,
		    })
		end
		
	end)
end





-- ================ PREMIUM0 TAB0 ================ --

-- ═══════════ KittyWare parts (No Stun, Dash, Tech) on the same Obsidian window ═══════════
local Library = ZR_Library
ZR_Options = Library.Options
ZR_Toggles = Library.Toggles
ZR_Tabs = {}
ZR_UIS = game:GetService("UserInputService")
ZR_TweenService = game:GetService("TweenService")

ZR_ids = {}
function ZR_kid(name)
    local base = "ZR_" .. tostring(name):gsub("[^%w]", "")
    local id, n = base, 1
    while ZR_ids[id] do n += 1 id = base .. n end
    ZR_ids[id] = true
    return id
end

-- a thing that answers anything (for menu parts that were removed)
function ZR_Dummy()
    local mt = {}
    local d = setmetatable({}, mt)
    mt.__index = function(_, k)
        if k == "current" or k == "Value" or k == "sectionholder" or k == "content" then return nil end
        return d
    end
    mt.__call = function() return d end
    return d
end

-- ═══════════ fake key presses from the on-screen buttons ═══════════
-- the hold-type features (auto block hold, freeze, lock on hold) listen for a key being let go;
-- the mobile buttons send the same "pressed / let go" so they work without a keyboard
local function ZR_Signal()
    local s = { list = {} }
    function s:Connect(fn)
        local c = { fn = fn, Connected = true }
        function c:Disconnect() c.Connected = false end
        table.insert(s.list, c)
        return c
    end
    function s:Fire(...)
        for _, c in ipairs(s.list) do
            if c.Connected then task.spawn(c.fn, ...) end
        end
    end
    return s
end
ZR_InputBegan = ZR_Signal()
ZR_InputEnded = ZR_Signal()
ZR_UIS.InputBegan:Connect(function(...) ZR_InputBegan:Fire(...) end)
ZR_UIS.InputEnded:Connect(function(...) ZR_InputEnded:Fire(...) end)
local function fakeInput(current)
    local kind, name = current and current[1], current and current[2]
    return {
        KeyCode = { Name = kind == "KeyCode" and name or "Unknown" },
        UserInputType = { Name = kind == "UserInputType" and name or "Keyboard" },
        Position = Vector3.zero, ZR_Fake = true,
    }
end

-- ═══════════ on-screen buttons (round, drag them anywhere) ═══════════
ZR_MB = { Size = 62, Locked = false, Hidden = false, list = {} }
do
    local gui = Instance.new("ScreenGui")
    gui.Name = "ZRHUB_MobileButtons"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 60
    if not pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end) then
        gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    ZR_MB.gui = gui
end
local function scheme()
    local s = Library.Scheme or {}
    return s.MainColor or Color3.fromRGB(25, 25, 25), s.AccentColor or Color3.fromRGB(125, 85, 255),
        s.OutlineColor or Color3.fromRGB(40, 40, 40), s.FontColor or Color3.new(1, 1, 1)
end
function ZR_MobileButton(label, onDown, onUp)
    local index = #ZR_MB.list
    local size = ZR_MB.Size
    local frame = Instance.new("Frame")
    frame.Name = "ZRBtn_" .. label
    frame.BackgroundTransparency = 1
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.fromOffset(size, size)
    frame.Position = UDim2.new(1, -(size / 2 + 20) - math.floor(index / 5) * (size + 10), 0.25, (index % 5) * (size + 10))
    frame.Visible = false
    frame.Parent = ZR_MB.gui
    local scale = Instance.new("UIScale") scale.Parent = frame
    local ring = Instance.new("Frame")
    ring.BackgroundTransparency = 1
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    ring.Size = UDim2.fromScale(1, 1)
    ring.Parent = frame
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
    local rs = Instance.new("UIStroke") rs.Thickness = 3 rs.Color = Color3.new(1, 1, 1) rs.Parent = ring
    local rg = Instance.new("UIGradient")
    rg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(0.75, 0.85), NumberSequenceKeypoint.new(1, 1),
    })
    rg.Parent = rs
    local disc = Instance.new("TextButton")
    disc.AutoButtonColor = false
    disc.Text = ""
    disc.BorderSizePixel = 0
    disc.AnchorPoint = Vector2.new(0.5, 0.5)
    disc.Position = UDim2.fromScale(0.5, 0.5)
    disc.Size = UDim2.new(1, -10, 1, -10)
    disc.Parent = frame
    Instance.new("UICorner", disc).CornerRadius = UDim.new(1, 0)
    local ds = Instance.new("UIStroke") ds.Thickness = 1 ds.ApplyStrokeMode = Enum.ApplyStrokeMode.Border ds.Parent = disc
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, -8, 1, -8)
    text.Position = UDim2.fromOffset(4, 4)
    text.TextWrapped = true
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Text = label
    text.Parent = disc
    local tc = Instance.new("UITextSizeConstraint") tc.MaxTextSize = 13 tc.Parent = text
    local held = false
    local function paint()
        local main, accent, outline, font = scheme()
        disc.BackgroundColor3 = held and accent:Lerp(main, 0.5) or main
        ds.Color = held and accent or outline
        rg.Color = ColorSequence.new(held and accent or outline)
        text.TextColor3 = font
    end
    paint()
    local pressing, moved, startAt, startPos, input0 = false, false, nil, nil, nil
    disc.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        pressing, moved, startAt, startPos, input0 = true, false, input.Position, frame.Position, input
        held = true
        paint()
        ZR_TweenService:Create(scale, TweenInfo.new(0.07), { Scale = 0.9 }):Play()
        task.spawn(onDown)
    end)
    ZR_UIS.InputChanged:Connect(function(input)
        if not pressing or ZR_MB.Locked then return end
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if input0.UserInputType == Enum.UserInputType.Touch and input ~= input0 then return end
        local d = input.Position - startAt
        if not moved and d.Magnitude < 14 then return end
        moved = true
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end)
    ZR_UIS.InputEnded:Connect(function(input)
        if not pressing then return end
        if input == input0 or input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressing, held = false, false
            paint()
            ZR_TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
            if onUp then task.spawn(onUp) end
        end
    end)
    local b = { frame = frame, wanted = false }
    function b.refresh()
        frame.Visible = b.wanted and not ZR_MB.Hidden
        frame.Size = UDim2.fromOffset(ZR_MB.Size, ZR_MB.Size)
        paint()
    end
    table.insert(ZR_MB.list, b)
    return b
end
task.spawn(function()
    while not Library.Unloaded do
        task.wait(1)
        for _, b in ipairs(ZR_MB.list) do pcall(b.refresh) end
    end
    pcall(function() ZR_MB.gui:Destroy() end)
end)

-- ═══════════ KittyWare menu → Obsidian ═══════════
ZR_TAB_ICONS = { Combat = "swords", Macro = "keyboard", Visuals = "eye", Rage = "flame", Notifications = "bell", Misc = "layout-grid" }
-- sections the new menu handles itself (config / auto load / menu key)
ZR_SKIP_SECTIONS = { Config = true, ["Auto Load Config"] = true }
ZR_SKIP_ELEMENTS = { ["GUI Keybind"] = true, ["Mobile KW Button"] = true }
-- keybinds that don't get an on-screen button
ZR_NO_BUTTON = { ["Auto Block Keybind"] = true, ["Add Friend/Enemy Keybind"] = true }
-- every dash box goes to the Movement tab (in this order on the page, alternating sides)
ZR_MOVE_SECTIONS = { ["Custom Dash"] = true, ["Custom Dash v2"] = true, ["Emote Dash"] = true, ["Backdash Cancel"] = true,
    ["Side Dash Assist"] = true, ["Front Dash"] = true, ["Side Dash"] = true }
ZR_MoveCount = 0
ZR_Keybinds = {}
ZR_SEC_ICONS = {
    ["Auto Block"] = "shield", ["Misc"] = "layout-grid", ["True DownSlam"] = "arrow-down", ["Auto Lethal"] = "skull",
    ["Lethal Settings"] = "sliders-horizontal", ["Auto Tech"] = "zap", ["Auto Tech Settings"] = "sliders-horizontal",
    ["Custom Dash"] = "wind", ["Custom Dash v2"] = "wind", ["True M1 Reset"] = "rotate-ccw", ["Emote Dash"] = "smile",
    ["Backdash Cancel"] = "undo-2", ["Tech Helper"] = "wrench", ["Clean Look"] = "sparkles", ["Custom Ultbar"] = "battery-charging",
    ["Custom Effects"] = "palette", ["ESP"] = "eye", ["Character & Self Chams"] = "user", ["Custom Atmosphere"] = "cloud",
    ["Custom Sky"] = "sun", ["Char (Copy Avatar)"] = "copy", ["Toggles"] = "toggle-right", ["Fling"] = "tornado",
    ["Side Dash Assist"] = "move-horizontal", ["Front Dash"] = "move-up", ["Side Dash"] = "move-right",
    ["Undying Hero / Sniper"] = "crosshair", ["Main"] = "bell", ["Lock On"] = "lock", ["Ping Spoofer"] = "wifi", ["Device Spoofer"] = "smartphone",
}

local function keyName(k)
    if typeof(k) == "EnumItem" then
        if k.EnumType == Enum.UserInputType then
            return ({ MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3" })[k.Name] or "None"
        end
        return k.Name
    end
    if type(k) == "string" and k ~= "" then return k end
    return "None"
end
local function currentOf(id, virtual)
    local v = ZR_Options[id] and ZR_Options[id].Value
    if v == "MB1" then return { "UserInputType", "MouseButton1" } end
    if v == "MB2" then return { "UserInputType", "MouseButton2" } end
    if v == "MB3" then return { "UserInputType", "MouseButton3" } end
    if type(v) == "string" and v ~= "" and v ~= "None" then return { "KeyCode", v } end
    return { "KeyCode", virtual } -- no key: only the on-screen button can press it
end

local function makeSection(box, secName)
    local sec = {}
    function sec:toggle(o)
        if ZR_SKIP_ELEMENTS[o.name] then return ZR_Dummy() end
        local id = ZR_kid(o.pointer or o.name)
        local t = box:AddToggle(id, {
            Text = tostring(o.name), Default = o.def == true, Tooltip = o.tooltip,
            Callback = function(v) if o.callback then task.spawn(o.callback, v) end end,
        })
        local obj = {}
        function obj:set(v) pcall(function() ZR_Toggles[id]:SetValue(v == true) end) end
        function obj:get() return ZR_Toggles[id].Value end
        setmetatable(obj, { __index = function(_, k) if k == "current" or k == "value" then return ZR_Toggles[id].Value end end })
        return obj
    end
    function sec:slider(o)
        local mn, mx = tonumber(o.min) or 0, tonumber(o.max) or 100
        local id = ZR_kid(o.pointer or o.name)
        box:AddSlider(id, {
            Text = tostring(o.name), Default = math.clamp(tonumber(o.def) or mn, mn, mx), Min = mn, Max = mx,
            Rounding = o.rounding == false and 2 or 0, Suffix = o.measurement, Tooltip = o.tooltip, Compact = false,
            Callback = function(v) if o.callback then task.spawn(o.callback, v) end end,
        })
        local obj = {}
        function obj:set(v) pcall(function() ZR_Options[id]:SetValue(math.clamp(tonumber(v) or mn, mn, mx)) end) end
        return obj
    end
    function sec:dropdown(o)
        local values = type(o.options) == "table" and o.options or {}
        local id = ZR_kid(o.pointer or o.name)
        local def = o.def
        if def == nil or not table.find(values, def) then def = values[1] end
        box:AddDropdown(id, {
            Text = tostring(o.name), Values = values, Default = def, Tooltip = o.tooltip, AllowNull = false,
            Callback = function(v) if v ~= nil and o.callback then task.spawn(o.callback, v) end end,
        })
        local obj = {}
        function obj:set(v) pcall(function() ZR_Options[id]:SetValue(v) end) end
        function obj:refresh(list) pcall(function() ZR_Options[id]:SetValues(list) end) end
        obj.optionsholder = ZR_Dummy()
        return obj
    end
    function sec:textbox(o)
        local id = ZR_kid(o.pointer or o.name)
        box:AddInput(id, {
            Text = tostring(o.name), Default = tostring(o.def or ""), Placeholder = tostring(o.placeholder or ""),
            Tooltip = o.tooltip, Finished = true, ClearTextOnFocus = false,
            Callback = function(v) if o.callback then task.spawn(o.callback, v) end end,
        })
        local obj = {}
        function obj:set(v) pcall(function() ZR_Options[id]:SetValue(tostring(v)) end) end
        return obj
    end
    function sec:button(o)
        box:AddButton({ Text = tostring(o.name), Tooltip = o.tooltip, Func = function()
            if o.callback then task.spawn(o.callback) end
        end })
        return {}
    end
    function sec:colorpicker(o)
        local id = ZR_kid(o.pointer or o.name)
        box:AddLabel(tostring(o.name)):AddColorPicker(id, {
            Default = typeof(o.def) == "Color3" and o.def or Color3.new(1, 1, 1), Title = tostring(o.name),
            Callback = function(c) if o.callback then task.spawn(o.callback, c) end end,
        })
        return {}
    end
    -- keybinds: the Obsidian key picker + an on-screen button for phones
    function sec:keybind(o)
        if ZR_SKIP_ELEMENTS[o.name] then return ZR_Dummy() end
        local id = ZR_kid(o.pointer or o.name)
        local virtual = "ZRMobile_" .. id
        local label = box:AddLabel(tostring(o.name))
        label:AddKeyPicker(id, { Default = keyName(o.def), Mode = "Toggle", Text = tostring(o.name), NoUI = false,
            ChangedCallback = function(k) if o.changeCallback then pcall(o.changeCallback, k) end end })
        local obj = setmetatable({}, { __index = function(_, k)
            if k == "current" then return currentOf(id, virtual) end
        end })
        local function press(fake)
            if fake then ZR_InputBegan:Fire(fakeInput(currentOf(id, virtual)), false) end
            if o.callback then task.spawn(o.callback, currentOf(id, virtual)) end
        end
        table.insert(ZR_Keybinds, { id = id, press = press })
        if ZR_NO_BUTTON[o.name] or not ZR_KEEP_BUTTON[o.name] then return obj end
        local short = tostring(o.name):gsub(" [Kk]ey[Bb]ind$", "")
        if short == "Keybind" then short = secName end
        local btn = ZR_MobileButton(short, function() press(true) end, function()
            ZR_InputEnded:Fire(fakeInput(currentOf(id, virtual)), false)
        end)
        local tid = ZR_kid(id .. "Mobile")
        box:AddToggle(tid, { Text = "On-Screen Button", Default = false,
            Tooltip = "Shows a round button for " .. tostring(o.name) .. ". Tap it to use it, drag it to move it.",
            Callback = function(v) btn.wanted = v btn.refresh() end })
        return obj
    end
    return sec
end

-- presses for the PC key pickers
ZR_UIS.InputBegan:Connect(function(input, gp)
    if gp or ZR_UIS:GetFocusedTextBox() then return end
    local name
    if input.UserInputType == Enum.UserInputType.Keyboard then name = input.KeyCode.Name
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then name = "MB1"
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then name = "MB2"
    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then name = "MB3" end
    if not name then return end
    for _, k in ipairs(ZR_Keybinds) do
        local v = ZR_Options[k.id] and ZR_Options[k.id].Value
        if v == name then k.press(false) end
    end
end)

ZR_KW = {}
-- the only keybinds that keep an on-screen button
ZR_KEEP_BUTTON = { ["M1 Reset KeyBind"] = true, ["True Down Slam Jump"] = true }
-- which KittyWare boxes show up, and in which ZRHUB tab
ZR_KW_ROUTE = {
    ["Toggles"] = { "Main", "No Stun & More", "shield-off" },
    ["Custom Dash"] = { "Dash" }, ["Custom Dash v2"] = { "Dash" }, ["Side Dash Assist"] = { "Dash" },
    ["Front Dash"] = { "Dash" }, ["Side Dash"] = { "Dash" }, ["Emote Dash"] = { "Dash" }, ["Backdash Cancel"] = { "Dash" },
    ["Tech Helper"] = { "Tech" }, ["True M1 Reset"] = { "Tech" }, ["Auto Tech"] = { "Tech" },
    ["Auto Tech Settings"] = { "Tech" }, ["True DownSlam"] = { "Tech" },
}
-- single items pulled out of a hidden box
ZR_KW_ELEMENTS = { ["No Dash Endlag"] = "Toggles" }
ZR_KW_Boxes = {}
local function kwBox(sectionName)
    if ZR_KW_Boxes[sectionName] then return ZR_KW_Boxes[sectionName] end
    local r = ZR_KW_ROUTE[sectionName]
    local tab = r and Tabs[r[1]]
    if not tab then return nil end
    local title = r[2] or sectionName
    local box = tab._newBox(title, r[3] or ZR_SEC_ICONS[sectionName] or "box")
    ZR_KW_Boxes[sectionName] = box
    return box
end
function ZR_KW:new(opts)
    local w = {
        isMobile = Library.IsMobile == true,
        theme = setmetatable({}, { __index = function(_, k) if k == "accent" then return Library.Scheme and Library.Scheme.AccentColor end end }),
        uiscale = { Scale = 1 },
        tabsbuttons = { GetChildren = function() return {} end },
        connections = {},
        key = Enum.KeyCode.RightShift,
        screen = { Destroy = function() end },
    }
    function w:page(o)
        local p = {}
        function p:section(so)
            local name = tostring(so.name)
            if ZR_KW_ROUTE[name] then
                return makeSection(kwBox(name), name)
            end
            -- hidden box: only the single items listed in ZR_KW_ELEMENTS get through
            local sec = {}
            for _, kind in ipairs({ "toggle", "slider", "dropdown", "textbox", "button", "colorpicker", "keybind" }) do
                sec[kind] = function(_, el)
                    local target = el and ZR_KW_ELEMENTS[el.name]
                    if target and kwBox(target) then
                        return makeSection(kwBox(target), target)[kind](nil, el)
                    end
                    return ZR_Dummy()
                end
            end
            return setmetatable(sec, { __index = function(_, k)
                if k == "sectionholder" or k == "content" or k == "current" or k == "Value" then return nil end
                return function() return ZR_Dummy() end
            end })
        end
        function p:openpage() end
        return p
    end
    function w:setkey() end
    function w:togglemobilebutton() end
    function w:optimizemobile() end
    function w:loadconfig() return false, "use the config in Settings" end
    function w:destroy() end
    return w
end

-- ═══════════ phones: keep the touch controls while macros press keys ═══════════
-- macros press keyboard keys / the mouse for you. Roblox's control script sees that, thinks you
-- switched to a keyboard and hides the joystick + jump button. On a phone we stop it from switching
-- for fake presses, and switch it back to touch after the macro. PC is left alone.
ZR_RealTouch = ZR_UIS.TouchEnabled
ZR_lastFake = 0
ZR_Controls = nil
local restoring = false
local function isFakeTime() return os.clock() - ZR_lastFake < 0.6 end
ZR_UIS.InputBegan:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.Touch then
        ZR_RealTouch = true
    elseif (t == Enum.UserInputType.Keyboard or t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2)
        and not isFakeTime() then
        ZR_RealTouch = false -- a real keyboard / mouse: you're on PC
    end
end)
local KEYBOARDISH = {
    [Enum.UserInputType.Keyboard] = true, [Enum.UserInputType.MouseButton1] = true, [Enum.UserInputType.MouseButton2] = true,
    [Enum.UserInputType.MouseButton3] = true, [Enum.UserInputType.MouseMovement] = true, [Enum.UserInputType.MouseWheel] = true,
}
-- hook Roblox's ControlModule so a fake key doesn't flip you to keyboard controls
task.spawn(function()
    local lp = game:GetService("Players").LocalPlayer
    local ok, controls = pcall(function()
        local pm = lp:WaitForChild("PlayerScripts", 20):WaitForChild("PlayerModule", 20)
        return require(pm):GetControls()
    end)
    if not ok or type(controls) ~= "table" or type(controls.OnLastInputTypeChanged) ~= "function" then return end
    ZR_Controls = controls
    local original = controls.OnLastInputTypeChanged
    controls.OnLastInputTypeChanged = function(self, newType, ...)
        if ZR_RealTouch and KEYBOARDISH[newType] and isFakeTime() then return end
        return original(self, newType, ...)
    end
    ZR_ControlsOriginal = original
end)
local function restoreTouch()
    -- 1) tell the control script you're on touch again
    if ZR_Controls and ZR_ControlsOriginal then
        pcall(ZR_ControlsOriginal, ZR_Controls, Enum.UserInputType.Touch)
    end
    -- 2) show the touch controls again
    pcall(function()
        local tg = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("TouchGui")
        if tg then
            tg.Enabled = true
            local f = tg:FindFirstChild("TouchControlFrame")
            if f then f.Visible = true end
        end
    end)
    -- 3) a quick invisible tap at the very top so Roblox (and the game's own buttons) see touch again
    if ZR_UIS:GetLastInputType() ~= Enum.UserInputType.Touch then
        local VIM = game:GetService("VirtualInputManager")
        local cam = workspace.CurrentCamera
        local x, y = cam and cam.ViewportSize.X * 0.5 or 400, 1
        pcall(function()
            VIM:SendTouchEvent(987654, Enum.UserInputState.Begin, x, y)
            task.wait()
            VIM:SendTouchEvent(987654, Enum.UserInputState.End, x, y)
        end)
    end
end
function ZR_NoteFake()
    ZR_lastFake = os.clock()
    if not ZR_RealTouch or restoring then return end
    restoring = true
    task.spawn(function()
        repeat task.wait(0.1) until os.clock() - ZR_lastFake >= 0.15
        restoring = false
        if ZR_RealTouch then restoreTouch() end
    end)
end

function ZR_RunKittyWare()
local App = {}
if not game:IsLoaded() then
    game.Loaded:Wait()
end
local Services = setmetatable({}, {
    __index = function(_PIUsH, _uxgSI)
        return game:GetService(_uxgSI)
    end
})
local VirtualInputManager = Services.VirtualInputManager
local UserInputService = Services.UserInputService
local RunService = Services.RunService
local Lighting = Services.Lighting
local Players = Services.Players
local DataPingItem = Services.Stats.Network.ServerStatsItem["Data Ping"]
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Mouse = LocalPlayer:GetMouse()
local Library = ZR_KW
local Notify = (function()
    local _uROeR = 300
    local _PQyah = 10
    local _k1jL7 = 44
    local _Fb5q2, _amv4w = Enum.Font.GothamSemibold, 14
    local _vxKIE, _QIqmW = Enum.Font.Gotham, 14
    local _l59Ng = Instance.new("ScreenGui")
    _l59Ng.Name = "KittyNotif"
    _l59Ng.ResetOnSpawn = false
    _l59Ng.DisplayOrder = 50
    _l59Ng.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local _Gf2vI = pcall(function()
        _l59Ng.Parent = (gethui and gethui()) or Services.CoreGui
    end)
    if not _Gf2vI or not _l59Ng.Parent then
        _l59Ng.Parent = PlayerGui
    end
    local _bqJUE = Instance.new("Frame")
    _bqJUE.Name = "Container"
    _bqJUE.BackgroundTransparency = 1
    _bqJUE.Position = UDim2.new(0, 20, 0.5, -20)
    _bqJUE.Size = UDim2.new(0, _uROeR, 0.5, 0)
    _bqJUE.Parent = _l59Ng
    local _wNQog = Instance.new("UIListLayout")
    _wNQog.Padding = UDim.new(0, 8)
    _wNQog.SortOrder = Enum.SortOrder.LayoutOrder
    _wNQog.Parent = _bqJUE
    local _SJO8N = 0
    local function _lq0Ko(_Ibc39, _bMw4Q, _yvGKy, _Ri_Q_)
        local _o35Fh = tostring(_Ibc39):gsub("<[^>]->", "")
        return Services.TextService:GetTextSize(_o35Fh, _yvGKy, _bMw4Q, Vector2.new(_Ri_Q_, math.huge)).Y
    end
    local function _HEF9z(_eoSk_, _xb4dg, _UWtfL, _nD247Vg, _KjlCfVtx, _dktB4, _ANj2KI, _TTzuk7P, _qctk9juS)
        local _JrB05
        _JrB05 = Instance.new("TextLabel")
        _JrB05.BackgroundTransparency = 1
        _JrB05.RichText = true
        _JrB05.TextWrapped = true
        _JrB05.TextXAlignment = Enum.TextXAlignment.Left
        _JrB05.TextYAlignment = Enum.TextYAlignment.Top
        _JrB05.Font = _UWtfL
        _JrB05.TextSize = _nD247Vg
        _JrB05.TextColor3 = _qctk9juS
        _JrB05.Text = _xb4dg
        _JrB05.Position = UDim2.fromOffset(_dktB4, _KjlCfVtx)
        _JrB05.Size = UDim2.fromOffset(_ANj2KI, _TTzuk7P)
        _JrB05.Parent = _eoSk_
        return _JrB05
    end
    local function _UGUDCx(_B0EiWma, _e6O_aCEl)
        local _LyCZo = TweenInfo.new(_e6O_aCEl, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        for _oQMcI0, _V7TKepU in ipairs(_B0EiWma:GetDescendants()) do
            if _V7TKepU:IsA("TextLabel") then
                Services.TweenService:Create(_V7TKepU, _LyCZo, {TextTransparency = 1}):Play()
            elseif _V7TKepU:IsA("ImageLabel") then
                Services.TweenService:Create(_V7TKepU, _LyCZo, {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
            elseif _V7TKepU:IsA("UIStroke") then
                Services.TweenService:Create(_V7TKepU, _LyCZo, {Transparency = 1}):Play()
            elseif _V7TKepU:IsA("Frame") and _V7TKepU.BackgroundTransparency < 1 then
                Services.TweenService:Create(_V7TKepU, _LyCZo, {BackgroundTransparency = 1}):Play()
            end
        end
    end
    local function _yuZK39Sf(_fFVBX)
        _fFVBX = type(_fFVBX) == "table" and _fFVBX or {}
        local _IViFy = _fFVBX.Title
        local _pjUim = _fFVBX.Description
        local _SH1sp = _fFVBX.Image
        if type(_SH1sp) ~= "string" or _SH1sp == "" then
            _SH1sp = nil
        end
        local _zzicr = tonumber(_fFVBX.Duration) or 5
        local _c6q3D = _PQyah + (_SH1sp and _k1jL7 + _PQyah or 0)
        local _JVDRS = _uROeR - _c6q3D - _PQyah
        local _p5Pf6 = _IViFy and _lq0Ko(_IViFy, _Fb5q2, _amv4w, _JVDRS) or 0
        local _UBkUy = _pjUim and _lq0Ko(_pjUim, _vxKIE, _QIqmW, _JVDRS) or 0
        local _vNrVo = (_IViFy and _pjUim) and 4 or 0
        local _a5nsQ = math.max(_PQyah + _p5Pf6 + _vNrVo + _UBkUy + _PQyah, _SH1sp and _k1jL7 + _PQyah * 2 or 0)
        _SJO8N = _SJO8N + 1
        local _J8wHy = Instance.new("Frame")
        _J8wHy.BackgroundTransparency = 1
        _J8wHy.LayoutOrder = _SJO8N
        _J8wHy.Size = UDim2.fromOffset(_uROeR, _a5nsQ)
        _J8wHy.Parent = _bqJUE
        local _oU8iJ = Instance.new("Frame")
        _oU8iJ.BackgroundColor3 = Color3.fromRGB(26, 26, 28)
        _oU8iJ.BorderSizePixel = 0
        _oU8iJ.Size = UDim2.fromScale(1, 1)
        _oU8iJ.Position = UDim2.fromOffset(- (_uROeR + 30), 0)
        _oU8iJ.Parent = _J8wHy
        local _PKUsH = Instance.new("UICorner")
        _PKUsH.CornerRadius = UDim.new(0, 6)
        _PKUsH.Parent = _oU8iJ
        local _uYrfC = Instance.new("UIStroke")
        _uYrfC.Color = Color3.fromRGB(60, 60, 64)
        _uYrfC.Transparency = 0.3
        _uYrfC.Parent = _oU8iJ
        if _SH1sp then
            local _daU5w, _IPkfJ
            _daU5w = Instance.new("ImageLabel")
            _daU5w.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
            _daU5w.BorderSizePixel = 0
            _daU5w.Image = _SH1sp
            _daU5w.ScaleType = Enum.ScaleType.Crop
            _daU5w.Size = UDim2.fromOffset(_k1jL7, _k1jL7)
            _daU5w.Position = UDim2.fromOffset(_PQyah, math.floor((_a5nsQ - _k1jL7) / 2))
            _daU5w.Parent = _oU8iJ
            _IPkfJ = Instance.new("UICorner")
            _IPkfJ.CornerRadius = UDim.new(0, 5)
            _IPkfJ.Parent = _daU5w
        end
        local _jIzaP = _PQyah
        if _IViFy then
            _HEF9z(_oU8iJ, _IViFy, _Fb5q2, _amv4w, _jIzaP, _c6q3D, _JVDRS, _p5Pf6, Color3.fromRGB(255, 255, 255))
            _jIzaP = _jIzaP + (_p5Pf6 + _vNrVo)
        end
        if _pjUim then
            _HEF9z(_oU8iJ, _pjUim, _vxKIE, _QIqmW, _jIzaP, _c6q3D, _JVDRS, _UBkUy, Color3.fromRGB(200, 200, 205))
        end
        Services.TweenService:Create(_oU8iJ, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)}):Play()
        task.delay(_zzicr, function()
            if not _J8wHy.Parent then
                return
            end
            _UGUDCx(_J8wHy, 0.25)
            task.wait(0.25)
            Services.TweenService:Create(_J8wHy, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(_uROeR, 0)}):Play()
            task.wait(0.2)
            _J8wHy:Destroy()
        end)
    end
    local function _OyIHu()
        _l59Ng:Destroy()
    end
    return {Notify = _yuZK39Sf, Destroy = _OyIHu}
end)()
local Version = "1.1.0"
local DiscordInvite = "failed request"

local World = {
    Map = workspace:FindFirstChild("Map") or workspace:WaitForChild("Map", 0.05) or Instance.new("Folder"),
    Live = workspace:FindFirstChild("Live") or workspace:WaitForChild("Live", 0.05) or Instance.new("Folder"),
    Thrown = workspace:FindFirstChild("Thrown") or workspace:WaitForChild("Thrown", 0.05) or Instance.new("Folder"),
    Terrain = workspace:FindFirstChild("Terrain") or workspace:WaitForChild("Terrain", 0.05) or workspace.Terrain,
    Cutscenes = workspace:FindFirstChild("Cutscenes") or workspace:WaitForChild("Cutscenes", 0.05) or Instance.new("Folder")
}
local Camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        Camera = workspace.CurrentCamera
    end
end)
local DefaultDestroyHeight = workspace.FallenPartsDestroyHeight
local _uMouq
local _LMfeK
do
    local _g0ECr, _F35TD, _aTgR2
    _g0ECr = Lighting:FindFirstChild("ColorCorrection")
    _uMouq = _g0ECr or Instance.new("ColorCorrectionEffect", Lighting)
    _F35TD = _g0ECr == nil
    _aTgR2 = _uMouq.Name
    _uMouq.Name = "ColorCorrection"
    _LMfeK = {
        GlobalShadows = Lighting.GlobalShadows,
        ClockTime = Lighting.ClockTime,
        FieldOfView = Camera.FieldOfView,
        Saturation = _uMouq.Saturation,
        createdCC = _F35TD,
        originalCCName = _aTgR2
    }
end
local _rJ2QD = {}
local PlayerConnections = {}
local CharacterConnections = {}
local ActiveConnections = {}
local _XNd6n = {}
local _sDkXo = setmetatable({}, {__mode = "k"})
local Unloaded = false
local _meXJ9 = false
local _ElMhN
local _XXmEh = {HeadTransparency = 0, FaceTransparency = 0, AutoRotate = true, JumpPower = 50}
local PlayerFrames = {}
local _RWZpc = {
    Garou = {
        WaterTrail = true,
        WaterTrailEnd = true,
        AirTrail = true,
        Trail1 = true,
        Spinparticle = true,
        Spinparticle2 = true,
        ["1"] = true,
        ["2"] = true,
        ["3"] = true,
        ["4"] = true,
        ["5"] = true,
        ["6"] = true,
        ["7"] = true,
        ["8"] = true,
        ["9"] = true,
        ["10"] = true,
        ["1-1"] = true,
        ["1-2"] = true,
        ["1-3"] = true,
        ["2-1"] = true,
        ["2-2"] = true,
        ["2-3"] = true,
        ["3-1"] = true,
        ["3-2"] = true,
        ["3-3"] = true,
        ["4-1"] = true,
        ["4-2"] = true,
        ["4-3"] = true,
        ["4-4"] = true,
        ["5-1"] = true,
        ["5-2"] = true,
        ["6-1"] = true,
        ["7-1"] = true,
        ["8-1"] = true,
        ["9-1"] = true,
        ["9-2"] = true,
        Line = true,
        Real = true,
        Real2 = true,
        ParticleEmitter = true,
        big = true,
        Big = true,
        Was = true,
        Blue = true,
        Hit = true,
        HitEffect = true,
        Splash = true,
        Impact = true,
        Flash = true,
        Sparks = true
    },
    ["Red Garou"] = {
        WaterTrail = true,
        WaterTrailEnd = true,
        AirTrail = true,
        Trail1 = true,
        Spinparticle = true,
        Spinparticle2 = true,
        Line = true,
        Real = true,
        ParticleEmitter = true,
        big = true,
        Big = true,
        Red = true,
        Splash = true,
        Impact = true,
        Flash = true,
        Sparks = true,
        Hit = true
    },
    Saitama = {
        AirTrail = true,
        Trail = true,
        ParticleEmitter = true,
        Shockwave = true,
        Punch = true,
        Hit = true,
        HitEffect = true,
        Impact = true,
        Flash = true,
        Wind = true,
        Sparks = true,
        Line = true,
        Dust = true,
        Crater = true
    },
    Genos = {
        Fire = true,
        Flame = true,
        Sparks = true,
        Spark = true,
        Ignition = true,
        Heat = true,
        Burst = true,
        Explosion = true,
        Smoke = true,
        Glow = true,
        Trail = true,
        ParticleEmitter = true,
        Beam = true,
        Hit = true,
        Impact = true,
        Thruster = true,
        Core = true,
        Jet = true,
        Energy = true,
        Burn = true
    },
    Sonic = {
        Trail = true,
        SonicTrail = true,
        Purple = true,
        Slash = true,
        Slice = true,
        Speed = true,
        Flash = true,
        Wind = true,
        ParticleEmitter = true,
        Hit = true,
        Impact = true,
        Sparks = true,
        Line = true,
        Spin = true,
        AirTrail = true
    },
    ["Metal Bat"] = {
        Trail = true,
        BatTrail = true,
        Swing = true,
        SwingTrail = true,
        Hit = true,
        Impact = true,
        Smash = true,
        Slam = true,
        Sparks = true,
        ParticleEmitter = true,
        RedTrail = true,
        Bash = true,
        Line = true,
        Flash = true
    },
    Samurai = {
        Trail = true,
        Slash = true,
        SlashTrail = true,
        SwordTrail = true,
        Slice = true,
        Cut = true,
        Blade = true,
        Hit = true,
        Impact = true,
        Flash = true,
        Sparks = true,
        ParticleEmitter = true,
        Line = true
    },
    Tatsumaki = {
        Esper = true,
        Psychic = true,
        Aura = true,
        Wave = true,
        Green = true,
        Glow = true,
        Trail = true,
        Beam = true,
        ParticleEmitter = true,
        Hit = true,
        Impact = true,
        Sparks = true,
        Pebble = true,
        Rock = true,
        Crush = true
    },
    Siryu = {
        Dragon = true,
        Fang = true,
        Void = true,
        Tiger = true,
        Purple = true,
        Trail = true,
        ParticleEmitter = true,
        Hit = true,
        Impact = true,
        Flash = true,
        Sparks = true,
        Spin = true,
        Kick = true,
        Wave = true
    }
}
local _keMEq = {
    BodySmoke = true,
    BodySmokez = true,
    SmokeUpTwo = true,
    SmokeUp = true,
    UpSmoke = true,
    SmokeBack = true,
    GroundSmoke = true,
    UpSmoke2 = true,
    SmokeOne = true,
    Push = true,
    SmokeDown = true,
    Dust = true,
    Smoke = true,
    Smoke3 = true,
    SmokeyUp = true,
    Smokey = true
}
local function _DQit6(_eOZ2hq)
    local _xiR3f = {}
    for _Q6CZS8d5, _jASTFFL in ipairs(_eOZ2hq) do
        _xiR3f[_jASTFFL] = true
    end
    return _xiR3f
end
local State = {
    ignoreEnemy = _DQit6({"DoingEmote", "CancelEmote", "CancelEmote2", "BeingLaunched", "Freeze"}),
    ignoreLocal = _DQit6({
        "Counter",
        "HunterCounter",
        "DoingEmote",
        "CancelEmote",
        "CancelEmote2",
        "BeingLaunched",
        "Ragdoll",
        "Freeze",
        "BarrageBind"
    }),
    ignoreM1 = _DQit6({
        "Counter",
        "AbsoluteImmortal",
        "AtomicCounter",
        "HunterCounter",
        "UpFrames",
        "Ragdoll",
        "ForceField",
        "CanBringUp"
    }),
    interruptMoves = _DQit6({
        "Shove",
        "Normal Punch",
        "Uppercut",
        "Flowing Water",
        "Lethal Whirlwind Stream",
        "Hunter's Grasp",
        "Doom Dive",
        "Crowd Buster",
        "Hammer Heel",
        "Binding Cloth",
        "Jet Dive",
        "Blitz Shot",
        "Ignition Burst",
        "Flash Strike",
        "Scatter",
        "Explosive Shuriken",
        "Homerun",
        "Beatdown",
        "Four Ball",
        "Quick Slice",
        "Atmos Cleave",
        "Pinpoint Cut",
        "Crushing Pull",
        "Windstorm Fury",
        "Stone Coffin",
        "Expulsive Push",
        "GoPush",
        "Vanishing Kick",
        "Whirlwind Drop",
        "Head First",
        "Weboom",
        "Plasma Cannon",
        "Trinity Tear",
        "Twin Burst",
        "TornadoBind"
    }),
    barrageMoves = _DQit6({"Consecutive Punches", "Machine Gun Blows", "Bullet Barrage"}),
    watchedEvents = _DQit6({
        "M1ing",
        "Counter",
        "dodgevelocity",
        "InDash",
        "SideDash",
        "Freeze",
        "Slowed",
        "UsedDash",
        "DashCooldown",
        "SideDashCooldown",
        "moveme"
    }),
    dashEvents = _DQit6({"dodgevelocity", "InDash", "SideDash"}),
    eventStamp = {},
    blockState = {active = false, untilT = 0},
    lastPunish = 0,
    barrageActive = false,
    cape = _DQit6({
        "Custom Cape",
        "Guild Cape",
        "Slinky",
        "Ruler Cape",
        "Webbed Cape",
        "Warden Cape",
        "Desert Cape",
        "Divine Wheel",
        "Spiky Cape",
        "Fur Cape",
        "Blood Scarf",
        "Torn Headband",
        "Headband",
        "Bandage Wrap",
        "Waist Sash",
        "Leg Iron",
        "Leg Iron",
        "Worn Cape",
        "Tattered Cape",
        "Torn Cape",
        "White Cape",
        "Conqueror Cape",
        "Jagged Cape",
        "Royal Cape",
        "White Scarf",
        "Short Sash",
        "Red Gloves",
        "SpiralHolder",
        "Long Sash",
        "Bandages",
        "Purple Scarf"
    }),
    aura = _DQit6({
        "Gold Aura",
        "Midnight Aura",
        "Shadow Aura",
        "Burning Aura",
        "Crimson Aura",
        "Graceful Aura",
        "Glitch Aura",
        "Colorful Aura",
        "Error Aura",
        "Stench Aura",
        "Dark Aura",
        "Lighting Aura",
        "Ki Aura"
    }),
    ultbarPending = false,
    boostUntil = 0,
    serverNoDash = workspace:GetAttribute("NoDashCooldown"),
    serverEffect = workspace:GetAttribute("EffectAffects"),
    spoofingDash = false
}
local CharacterNames = {
    Bald = "Saitama",
    Hunter = "Garou",
    Monster = "Red Garou",
    Cyborg = "Genos",
    Ninja = "Sonic",
    Batter = "Metal Bat",
    Blade = "Samurai",
    Esper = "Tatsumaki",
    Purple = "Siryu",
    Tech = "Emperor",
    KJ = "KJ",
    Zombie = "Zombieman"
}
local _wZKifJPa = {
    headless = false,
    stretch = false,
    lockon = false,
    antifling = false,
    getping = false,
    hitbox = false,
    korblox = false,
    camBypass = false,
    zombieSpin = false,
    fovCircle = false
}
local _lH0uIxY = {}
local _KjGi0a = {
    conn = nil,
    startTime = 0,
    duration = 0.5,
    strength = 50,
    smoothness = 0.65,
    targetOverride = nil
}
local _r6zpd
local _YxtF_bco = ""
local _FPbWqU0 = false
local _ecSEyI, _LZYNd, _sC0i4
local Character
local Humanoid
local RootPart
local _MJSFe, _tew4S, onDescendantAdded
local _zE8Ni
local HeadPart
local _N82Le
local _mzv8k
local _TLppj = LocalPlayer:GetAttribute("S_AutoUnequip")
local _vjMDS = {}
local _i3Z2l
local KeySpace = Enum.KeyCode.Space
local KeyQ = Enum.KeyCode.Q
local KeyW = Enum.KeyCode.W
local KeyS = Enum.KeyCode.S
local KeyD = Enum.KeyCode.D
local KeyA = Enum.KeyCode.A
local _j089A = {
    frontDash = "10479335397",
    rsideDash = "10480793962",
    lsideDash = "10480796021",
    uppercut = "10503381238",
    euppercut = "13379003796",
    backDash = "10491993682"
}
local _Ws0Y9 = {
    holdM1 = {Goal = "LeftClick"},
    releaseM1 = {Goal = "LeftClickRelease"},
    backDash = {Dash = Enum.KeyCode.S, Key = Enum.KeyCode.Q, Goal = "KeyPress"},
    frontDash = {Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"},
    leftDash = {Dash = Enum.KeyCode.A, Key = Enum.KeyCode.Q, Goal = "KeyPress"},
    rightDash = {Dash = Enum.KeyCode.D, Key = Enum.KeyCode.Q, Goal = "KeyPress"},
    holdBlock = {Goal = "KeyPress", Key = Enum.KeyCode.F},
    releaseBlock = {Goal = "KeyRelease", Key = Enum.KeyCode.F}
}
local _vrfgk = {FarDash = 28, NearDash = 22, Barrage = 18, MovingM1 = 15, M1 = 9}
local Config = {
    Autoblock = {
        Enabled = false,
        DashPredict = false,
        AutoM1 = false,
        AutoCounter = false,
        RotateChar = true,
        RotateCam = false,
        CharEasing = 0,
        CamEasing = 0,
        FOV = 360
    },
    AutoTech = {
        Enabled = false,
        Tech = "",
        Method = "Perform Always",
        PerformOnce = false,
        MissChance = 0,
        Loopv2 = {Precision = 0.25, SecondFlick = 0.04, Jump = true, FirstFlickAngle = 0, RotateCam = false},
        Customdash = {
            StartFlickAngle = 0,
            SecondFlickAngle = 0,
            SecondFlickDelay = 0,
            ThirdFlickAngle = 0,
            ThirdFlickDelay = 0,
            Jump = true,
            RotateCam = false,
            LockOn = false,
            LockOnAfter = "",
            LockOnPrecision = 1,
            LockOnDelay = 0
        },
        Customdashv2 = {
            StartFlickAngle = 0,
            SecondFlickAngle = 0,
            SecondFlickDelay = 0,
            SecondFlickDuration = 0,
            ThirdFlickAngle = 0,
            ThirdFlickDelay = 0,
            ThirdFlickDuration = 0,
            Jump = true,
            RotateCam = false,
            LockOn = false,
            LockOnAfter = "",
            LockOnPrecision = 1,
            LockOnDelay = 0
        },
        LockonPrecision = 1,
        SupaMethod = "RenderStepped",
        LoopDashLooksUp = false,
        TargetPart = "HumanoidRootPart"
    },
    AutoLethal = {
        Enabled = false,
        MissChance = 0,
        HitAnim = "12296113986",
        Grave = true,
        GraveAnim = "119833661079663",
        GraveTiming = 0,
        FirstFlickAngle = 0,
        SecondFlick = 0.04,
        Precision = 0.35,
        Jump = true,
        RotateCam = false,
        Highlight = true,
        HighlightColor = Color3.fromRGB(255, 60, 60)
    },
    Misc = {
        FriendCheck = false,
        NoDashEndLag = false,
        StretchEnabled = false,
        StretchValue = 1,
        LockOnEnabled = false,
        LockOnPrecision = 1,
        LockOnTargetPart = "Head",
        LockOnMode = "Mouse",
        LockOnDummies = true,
        LockOnSwitch = true,
        LockOnFaceChar = true,
        LockOnCam = true,
        LockOnPredict = 0,
        LockOnMaxDist = 150,
        LockOnFOV = 300,
        LockOnHighlight = true,
        LockOnHold = false,
        TDSEnabled = false,
        Magnet = {
            Enabled = false,
            Keybind = nil,
            TechTrigger = "Disabled",
            TechDelay = 0,
            Duration = 0.5,
            Height = 2,
            Strength = 50,
            Smoothness = 0.65,
            MaxDistance = 100,
            DashCancel = true
        }
    },
    PingSpoof = {Enabled = false, Ping = 30, Jitter = 3, Interval = 1},
    DeviceSpoof = {Enabled = false, Device = "Console", Icon = "", TapClicks = false},
    Visuals = {
        LowGFX = {
            Enabled = false,
            FPSCap = 9999,
            FastFlags = true,
            LowRendering = true,
            LightingOpt = true,
            TerrainOpt = true,
            SoundOpt = true,
            RemoveParticles = true,
            RemoveTextures = true,
            RemoveLights = true,
            MemorySweeper = true,
            SweeperInterval = 10
        },
        NoSmoke = false,
        NoRings = false,
        NoNewLight = false,
        NoCapes = false,
        NoShadows = false,
        NoAuras = false,
        NoGarouC = false,
        Headless = false,
        FOV = 70,
        Korblox = false,
        MotionBlur = {Enabled = false, Intensity = 10},
        SelfChams = {
            Enabled = false,
            Color = Color3.fromRGB(142, 187, 255),
            Material = "ForceField",
            FillTransparency = 0.5,
            OutlineTransparency = 0
        },
        Atmosphere = {
            Enabled = false,
            Color = Color3.fromRGB(142, 187, 255),
            Decay = Color3.fromRGB(92, 60, 13),
            Density = 0.35,
            Haze = 0,
            Glare = 0
        },
        Sky = {Enabled = false, Preset = "Night", Stars = 3000, SkyboxId = ""},
        EffectsColor = {Enabled = false, Color = Color3.fromRGB(142, 187, 255)},
        CustomUltbar = {
            UltbarText = {Enabled = false, Text = "KITTYWARE"},
            UltbarColor = {Enabled = false, Color = Color3.fromRGB(142, 187, 255)}
        },
        ESP = {
            Enabled = false,
            Boxes = false,
            BoxColor = Color3.fromRGB(142, 187, 255),
            BoxUseESPColor = true,
            BoxThickness = 1,
            BoxFilled = false,
            DeathCounterColor = Color3.new(0.455, 0.137, 0.141),
            NeutralColor = Color3.new(0.365, 0.565, 1),
            FriendColor = Color3.new(0.588, 1, 0.275),
            EnemyColor = Color3.new(0.635, 0.4, 0.114),
            UltColor = Color3.new(0.635, 0.576, 0.114),
            SaitamaUltColor = Color3.new(0.98, 1, 0.678),
            NoBillboards = false,
            Highlight = true,
            OutlineTransparency = 0.7,
            DeathCounterESP = false,
            SaitamaUltESP = false
        }
    },
    Macro = {
        m1ResetEnabled = false,
        EmoteDash = {Enabled = false, Delay = 0.05, Type = "Straight"},
        BackDashCancel1 = {Enabled = false},
        BackDashCancel2 = {Enabled = false},
        BackDashCancel3 = {Enabled = false},
        BackDashCancel4 = {Enabled = false},
        TechHelper = {Enabled = false, Tech = ""},
        ExtraTechHelper = {Enabled = false, Tech = "Instant Lethal Shift Lock"}
    },
    Rage = {
        NoStun = false,
        NoSlow = false,
        NoFatigue = false,
        AlwaysJump = false,
        NoSideDashCooldown = false,
        FreezeHold = false,
        SideDashAssist = {
            Enabled = false,
            Mode = "Behind",
            Speed = 1,
            Range = 25,
            Offset = 3.5,
            Strength = 0.8,
            FaceTarget = true,
            RotateCam = true,
            Highlight = true,
            Predict = true
        },
        Fling = {Target = "", LoopFling = false},
        CustomFrontDash = {Enabled = false, OnlyOnKeybind = false, Distance = 1},
        CustomSideDash = {
            Enabled = false,
            OnlyOnKeybind = false,
            Distance = 1,
            Side = "",
            RemoveInertia = false,
            RMIDelay = 0.07,
            Jump = false
        }
    },
    Notifications = {GlobalEnabled = true, UltEnabled = true, DeathCounterEnabled = true, AutoTechEnabled = true, FlingEnabled = true},
    Zombie = {
        SniperSilentAim = false,
        SniperThirdPerson = false,
        ThirdPersonDist = 12,
        SniperSpinbot = false,
        SpinSpeed = 35,
        CameraLockBypass = false,
        LowHpCounter = false,
        TargetPart = "Head",
        SilentAimMode = "Mouse",
        SilentAimFOV = 500,
        FovCircle = true,
        SilentAimMaxDist = 1500,
        SilentAimPredict = 0,
        WallCheck = false
    }
}
local _lNGCT = {Ult = "UltEnabled", ["Death Counter"] = "DeathCounterEnabled", ["Auto Tech"] = "AutoTechEnabled", Fling = "FlingEnabled"}
local function _OS0SJ(_j3AeP)
    local _wjnQ4, _ZAZ9Z, _mRMKU, _H25i7, _k7GNj
    _wjnQ4 = _lNGCT[_j3AeP.Source]
    if not Config.Notifications.GlobalEnabled or (_wjnQ4 and not Config.Notifications[_wjnQ4]) then
        return
    end
    _ZAZ9Z = _j3AeP.Title
    _mRMKU = _j3AeP.Description
    _H25i7 = _j3AeP.Image
    _k7GNj = _j3AeP.Duration or 5
    pcall(function()
        ZR_Library:Notify({ Title = (tostring(_ZAZ9Z or "ZRHUB"):gsub("KittyWare", "ZRHUB")),
            Description = (tostring(_mRMKU or ""):gsub("<[^>]->", "")), Time = tonumber(_k7GNj) or 5 })
    end)
end
local function _xQp2C(_aLjhy)
    if _aLjhy then
        task.cancel(_aLjhy)
        _aLjhy = nil
    end
end
local function _vA5WJ(_Ijh47)
    if _Ijh47 then
        _Ijh47:Disconnect()
        ActiveConnections[_Ijh47] = nil
        _Ijh47 = nil
    end
end
local function connectSignal(_yMT0M, _TBHkm)
    local _wk3L5 = _yMT0M:Connect(function(...)
        if Unloaded then
            return
        end
        return _TBHkm(...)
    end)
    ActiveConnections[_wk3L5] = true
    return _wk3L5
end
local function disconnectAll(_mZM3s)
    if _mZM3s then
        for _HOoHI, _UlJS5 in ipairs(_mZM3s) do
            _vA5WJ(_UlJS5)
        end
        table.clear(_mZM3s)
    end
end
local function bindEvent(_JIm6E, _gouwvTcD, _HoL6e09, _WOk9NU)
    local _xVJJ6 = connectSignal(_gouwvTcD[_HoL6e09], _WOk9NU)
    if _JIm6E then
        table.insert(_JIm6E, _xVJJ6)
    end
    return _xVJJ6
end
local function _UbxYIsuM(_Vl9aYKy, _qOEFkj)
    local _fWiSA
    _fWiSA = _sDkXo[_Vl9aYKy]
    if not _fWiSA then
        _fWiSA = {}
        _sDkXo[_Vl9aYKy] = _fWiSA
    end
    if _fWiSA[_qOEFkj] == nil then
        _fWiSA[_qOEFkj] = {value = _Vl9aYKy[_qOEFkj]}
    end
    return _fWiSA[_qOEFkj].value
end
local function _IeaiYt2E(_hCkNxTU, _SP1Yvr, _r9nTw)
    _UbxYIsuM(_hCkNxTU, _SP1Yvr)
    _hCkNxTU[_SP1Yvr] = _r9nTw
end
local function _Upc_G()
    for _JH0vd, _e4Cri in pairs(_sDkXo) do
        for _TbBLC, _wqz9N in pairs(_e4Cri) do
            pcall(function()
                _JH0vd[_TbBLC] = _wqz9N.value
            end)
        end
    end
    table.clear(_sDkXo)
end
local function randomWait(_G5mQk)
    local _fZ3j5 = math.random(2, 6) / 1000
    task.wait((_G5mQk or 0) + _fZ3j5)
end
local function pressKey(_xq53R)
    ZR_NoteFake() VirtualInputManager:SendKeyEvent(true, _xq53R, false, game) ZR_NoteFake()
end
local function releaseKey(_HYtYZ)
    ZR_NoteFake() VirtualInputManager:SendKeyEvent(false, _HYtYZ, false, game) ZR_NoteFake()
end
local function tapKey(_Jd11Q)
    pressKey(_Jd11Q)
    randomWait()
    releaseKey(_Jd11Q)
end
local function setAutoRotate(_TLC65)
    pressKey(_TLC65)
    randomWait(0.01)
    releaseKey(_TLC65)
    if not _TLppj then
        local _wtxn4, _lcPtH, _JyzKr
        randomWait()
        _wtxn4 = Camera.ViewportSize
        _lcPtH, _JyzKr = math.floor(_wtxn4.X / 2), math.floor(_wtxn4.Y / 2)
        ZR_NoteFake() VirtualInputManager:SendMouseButtonEvent(_lcPtH, _JyzKr, 0, true, game, 0) ZR_NoteFake()
        randomWait()
        VirtualInputManager:SendMouseButtonEvent(_lcPtH, _JyzKr, 0, false, game, 0) ZR_NoteFake()
    end
end
local function _wQo4g()
    local _XdMsy, _uXYDT, _lKoRm, _o1NOl, _NfZkW, _a_wrZ
    _XdMsy = PlayerGui:FindFirstChild("Bar")
    _uXYDT = _XdMsy and _XdMsy:FindFirstChild("MagicHealth")
    _lKoRm = _uXYDT and _uXYDT:FindFirstChild("cdholder")
    _o1NOl = _lKoRm and _lKoRm:FindFirstChild("forward", true)
    _NfZkW = _o1NOl and _o1NOl:FindFirstChild("template")
    _a_wrZ = _NfZkW and _NfZkW:FindFirstChild("Fill")
    return _a_wrZ ~= nil and _a_wrZ.Size.Y.Scale > 0.01
end
State.frontDashAt = 0
local function _zk6rn(_MCg8k)
    if workspace:GetAttribute("NoDashCooldown") == (((_MCg8k) and {true} or {State.serverNoDash})[1]) and workspace:GetAttribute("EffectAffects") == (((_MCg8k) and {1} or {State.serverEffect})[1]) then
        return
    end
    State.spoofingDash = true
    workspace:SetAttribute("NoDashCooldown", ((_MCg8k) and {true} or {State.serverNoDash})[1])
    workspace:SetAttribute("EffectAffects", ((_MCg8k) and {1} or {State.serverEffect})[1])
    State.spoofingDash = false
end
connectSignal(workspace:GetAttributeChangedSignal("NoDashCooldown"), function()
    if not State.spoofingDash then
        State.serverNoDash = workspace:GetAttribute("NoDashCooldown")
    end
end)
connectSignal(workspace:GetAttributeChangedSignal("EffectAffects"), function()
    if not State.spoofingDash then
        State.serverEffect = workspace:GetAttribute("EffectAffects")
    end
end)
local function _lsV0R()
    if Character and Character:FindFirstChild("DashReset3rd") then
        return true
    end
    if not State.serverNoDash then
        return false
    end
    return State.serverEffect == 1 or workspace:GetAttribute("VIPServerOwner") == LocalPlayer.Name
end
local function _Om_zX()
    if _lsV0R() then
        return true
    end
    return not _ecSEyI or (tick() - State.frontDashAt >= 0.5 and not _wQo4g())
end
local function _XjK2G()
    local _AOY0t
    if not _Om_zX() then
        return
    end
    _AOY0t = _tew4S()
    if not _AOY0t then
        return
    end
    _AOY0t:FireServer(_Ws0Y9.frontDash)
    State.frontDashAt = tick()
    if not _lsV0R() then
        _ecSEyI = true
        task.delay(5, function()
            _ecSEyI = false
        end)
    end
    return true
end
local function _ZGKm8(_mYAHa)
    if not _zE8Ni then
        return
    end
    for _Lipbf, _Y1ASW in ipairs(_zE8Ni:GetPlayingAnimationTracks()) do
        if _Y1ASW.Animation and _Y1ASW.Animation.AnimationId == "rbxassetid://" .. tostring(_mYAHa) then
            _Y1ASW:Stop()
        end
    end
end
local function _xFaaK(_aLwZR, _jjZjS)
    local _M_J_a, _lsqPd
    if not _jjZjS then
        _M_J_a = _zE8Ni
    else
        _M_J_a = _jjZjS:FindFirstChildOfClass("Animator") or _jjZjS:FindFirstChild("Animator")
    end
    if not _M_J_a then
        return false
    end
    _lsqPd = tostring(_aLwZR)
    for _yKfvP, _XwGo_ in ipairs(_M_J_a:GetPlayingAnimationTracks()) do
        local _k3VVm = _XwGo_.Animation
        if _k3VVm and _k3VVm.AnimationId and string.find(_k3VVm.AnimationId, _lsqPd, 1, true) then
            return true
        end
    end
    return false
end
local function _JrRW2(_mz4aKkaE, _vrzr7Kh)
    if not _mz4aKkaE or not _mz4aKkaE.Name then
        return false
    end
    if PlayerFrames[_mz4aKkaE.Name] == "Friend" then
        if _vrzr7Kh then
            if Config.Misc.FriendCheck then
                return true
            else
                return false
            end
        else
            return true
        end
    else
        return false
    end
end
local function _YWFA4n(_xaeMm)
    if not PlayerFrames[_xaeMm.Name] then
        PlayerFrames[_xaeMm.Name] = "Neutral"
    end
    local _KVsoZ0kz, _ksUWjn = pcall(function()
        return _xaeMm:IsFriendsWithAsync(LocalPlayer.UserId)
    end)
    if _KVsoZ0kz and _ksUWjn then
        PlayerFrames[_xaeMm.Name] = "Friend"
    end
end
local function _v7Dwg8E(_eVgfUI, _DBWw2, _sYBrbRXB)
    Camera.CFrame = CFrame.new(_eVgfUI) * CFrame.Angles(0, _DBWw2, 0) * CFrame.Angles(_sYBrbRXB, 0, 0)
end
local function _RnQ1A5M(_qInq7MUP)
    local _fwEVN, _Ea8sVU, _SE4N6, _g97xt, _er2eU
    _qInq7MUP = _qInq7MUP or Character or (LocalPlayer and LocalPlayer.Character)
    if not _qInq7MUP then
        return false
    end
    if _qInq7MUP:GetAttribute("InterventionAiming") or _qInq7MUP:GetAttribute("OldInterventionAiming") then
        return true
    end
    if _qInq7MUP:GetAttribute("InterventionChamber") or _qInq7MUP:GetAttribute("OldInterventionChamber") then
        return true
    end
    _fwEVN = PlayerGui or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui"))
    if _fwEVN and _fwEVN:FindFirstChild("InterventionScope") then
        return true
    end
    _Ea8sVU = _qInq7MUP:FindFirstChild("CurrentWeapon")
    if _Ea8sVU then
        local _to77V = tostring(_Ea8sVU.Value):lower()
        if _to77V:find("sniper") then
            return true
        end
        if _to77V ~= "" and _to77V ~= "nil" then
            return false
        end
    end
    _SE4N6 = _qInq7MUP:FindFirstChildOfClass("Tool")
    if _SE4N6 then
        local _r_DxI = _SE4N6.Name:lower()
        if _r_DxI:find("sniper") or _r_DxI:find("intervention") then
            return true
        end
        return false
    end
    _g97xt = workspace.CurrentCamera
    if _g97xt then
        local _FG_MQ = _g97xt:FindFirstChild("SniperViewmodel") or _g97xt:FindFirstChild("Sniper")
        if _FG_MQ then
            return true
        end
    end
    _er2eU = _qInq7MUP:FindFirstChild("Sniper")
    if _er2eU then
        for _T71EJ, _slybh in ipairs(_er2eU:GetDescendants()) do
            if _slybh:IsA("Motor6D") or _slybh:IsA("Weld") or _slybh:IsA("WeldConstraint") then
                local _hBoOZ = _slybh.Part0 and _slybh.Part0.Name
                local _GZBmd = _slybh.Part1 and _slybh.Part1.Name
                if (_hBoOZ and (_hBoOZ:find("Arm") or _hBoOZ:find("Hand"))) or (_GZBmd and (_GZBmd:find("Arm") or _GZBmd:find("Hand"))) then
                    return true
                end
            end
        end
    end
    return false
end
local function _ffQog()
    local _UN0va, _twjOb, _Sb40N
    _UN0va = Character or (LocalPlayer and LocalPlayer.Character)
    _twjOb = Humanoid or (_UN0va and _UN0va:FindFirstChildOfClass("Humanoid"))
    _Sb40N = RootPart or (_UN0va and _UN0va:FindFirstChild("HumanoidRootPart"))
    if not (_UN0va and _twjOb and _Sb40N) then
        return false
    end
    if _twjOb.Health <= 0 then
        return true
    end
    if _UN0va:FindFirstChild("Ragdoll") or _UN0va:GetAttribute("Ragdoll") then
        return true
    end
    if _UN0va:FindFirstChild("BeingLaunched") or _UN0va:FindFirstChild("KnockedDown") then
        return true
    end
    if _UN0va:FindFirstChild("WallCombo") then
        return true
    end
    if _UN0va:FindFirstChild("Freeze") or _UN0va:FindFirstChild("Stun") then
        return true
    end
    if _UN0va:GetAttribute("BreakJointed") then
        return true
    end
    if _twjOb.PlatformStand or _twjOb:GetState() == Enum.HumanoidStateType.Ragdoll or _twjOb:GetState() == Enum.HumanoidStateType.FallingDown then
        return true
    end
    return false
end
State.freeRotate = function()
    if not Humanoid or _mzv8k then
        return
    end
    local _Hg8uG = Character
    Humanoid.AutoRotate = not (_Hg8uG and (_Hg8uG:FindFirstChild("Ragdoll") or _Hg8uG:FindFirstChild("NoRotate")))
end
State.Scope = {
    active = false,
    bind = "KWSniperView",
    conns = {},
    body = {},
    vm = {},
    spin = 0
}
local function _gMeqn()
    local _VvPRR = Character or (LocalPlayer and LocalPlayer.Character)
    return _VvPRR and (_VvPRR:GetAttribute("Character") == "Zombie" or _VvPRR:FindFirstChild("Sniper") ~= nil)
end
local function _ucV8j(_TSxd0)
    local _IzF4d, _hJJZz
    _IzF4d = Character or (LocalPlayer and LocalPlayer.Character)
    if not _IzF4d then
        return
    end
    _hJJZz = _IzF4d:FindFirstChild("zombiebypass")
    if _TSxd0 then
        if not _hJJZz then
            _hJJZz = Instance.new("Folder")
            _hJJZz.Name = "zombiebypass"
            _hJJZz.Parent = _IzF4d
        end
        if workspace.CurrentCamera and workspace.CurrentCamera.CameraType ~= Enum.CameraType.Custom then
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        end
    else
        if _hJJZz then
            pcall(function()
                _hJJZz:Destroy()
            end)
        end
    end
end
local function _GcDR2(_BRX45, _hc1gT, _CzaER, _HJQMv, _sJFe_, _N6sTT)
    if (not _CzaER and not _HJQMv) and not _BRX45 then
        _CzaER = true
    end
    local _SsaC7 = _CzaER or _HJQMv
    local _DYmAt = not _CzaER or _HJQMv
    if _SsaC7 and not (RootPart and Humanoid) then
        return
    end
    if _SsaC7 and _ffQog() then
        _SsaC7 = false
    end
    if not (_SsaC7 or _DYmAt) then
        return
    end
    _N6sTT = _N6sTT or 1
    local _YBTX7 = Camera.CFrame
    local _dfzaP = _YBTX7.Position
    local _y43bf = _dfzaP
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        _y43bf = _y43bf - _YBTX7.RightVector * 1.75
    end
    local _j5e1y = math.asin(math.clamp(_YBTX7.LookVector.Y, -1, 1))
    local _oIwtD = _j5e1y
    local _JmENB
    local _umBhB
    if _hc1gT then
        local _z1hub, _UDjDI, _FEYxn, _atCUT
        _z1hub = _hc1gT - (RootPart and RootPart.Position or _y43bf)
        _UDjDI = _hc1gT - _y43bf
        if _z1hub.Magnitude < 0.01 or _UDjDI.Magnitude < 0.01 then
            return
        end
        _FEYxn = _z1hub.Unit
        _atCUT = _UDjDI.Unit
        if _SsaC7 and not _DYmAt then
            _umBhB = math.atan2(-RootPart.CFrame.LookVector.X, -RootPart.CFrame.LookVector.Z)
            _JmENB = math.atan2(-_FEYxn.X, -_FEYxn.Z)
        elseif _DYmAt and not _SsaC7 then
            local _f7nB1
            _umBhB = math.atan2(-_YBTX7.LookVector.X, -_YBTX7.LookVector.Z)
            _JmENB = math.atan2(-_atCUT.X, -_atCUT.Z)
            _f7nB1 = math.asin(math.clamp(_atCUT.Y, -1, 1))
            _oIwtD = _j5e1y + (_f7nB1 - _j5e1y) * _N6sTT
        else
            local _QW2yY = math.atan2(-RootPart.CFrame.LookVector.X, -RootPart.CFrame.LookVector.Z)
            local _lLgcC = math.atan2(-_FEYxn.X, -_FEYxn.Z)
            local _qoChn = math.atan2(math.sin(_lLgcC - _QW2yY), math.cos(_lLgcC - _QW2yY))
            local _b07wb6f = _QW2yY + _qoChn * _N6sTT
            Humanoid.AutoRotate = false
            local _wgbDhbsh = RootPart.AssemblyLinearVelocity
            RootPart.CFrame = CFrame.new(RootPart.Position) * CFrame.Angles(0, _b07wb6f, 0)
            RootPart.AssemblyLinearVelocity = _wgbDhbsh
            local _BFfk8 = math.atan2(-_YBTX7.LookVector.X, -_YBTX7.LookVector.Z)
            local _WScTox = math.atan2(-_atCUT.X, -_atCUT.Z)
            local _HTriEnK = math.atan2(math.sin(_WScTox - _BFfk8), math.cos(_WScTox - _BFfk8))
            local _MlaAOylK = _BFfk8 + _HTriEnK * _N6sTT
            local _hyiVz = math.asin(math.clamp(_atCUT.Y, -1, 1))
            _oIwtD = _j5e1y + (_hyiVz - _j5e1y) * _N6sTT
            _v7Dwg8E(_dfzaP, _MlaAOylK, _oIwtD)
            return
        end
    else
        local _izwxu0 = _SsaC7 and RootPart.CFrame.LookVector or _YBTX7.LookVector
        _umBhB = math.atan2(-_izwxu0.X, -_izwxu0.Z)
        _JmENB = _umBhB + math.rad(_BRX45)
    end
    local _dYse15H = math.atan2(math.sin(_JmENB - _umBhB), math.cos(_JmENB - _umBhB))
    local _Ie20V3hQ = _umBhB + _dYse15H * _N6sTT
    if _SsaC7 then
        local _WpiGcsmp
        Humanoid.AutoRotate = false
        _WpiGcsmp = RootPart.AssemblyLinearVelocity
        RootPart.CFrame = CFrame.new(RootPart.Position) * CFrame.Angles(0, _Ie20V3hQ, 0)
        RootPart.AssemblyLinearVelocity = _WpiGcsmp
        if not _DYmAt then
            return
        end
    end
    _v7Dwg8E(_dfzaP, _Ie20V3hQ, _oIwtD)
end
State.techRotate = function(_DDdVL, _wKUwjg, _N4Idm, _qysva, _nNcCa, _A1RpD)
    if (not _N4Idm and not _qysva) and not _DDdVL then
        _N4Idm = true
    end
    local _hXRHJ = _N4Idm or _qysva
    local _atsG3 = not _N4Idm or _qysva
    if _hXRHJ and not (RootPart and Humanoid) then
        return
    end
    _A1RpD = _A1RpD or 1
    local _HGlcK = Camera.CFrame
    local _U8Kks = _HGlcK.Position
    local _R2Swf = _U8Kks
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        _R2Swf = _R2Swf - _HGlcK.RightVector * 1.75
    end
    local _uL54o = math.asin(_HGlcK.LookVector.Y)
    local _LnLfb
    local _E7BmZ
    if _wKUwjg then
        local _lVlTc
        if _hXRHJ then
            _lVlTc = (_wKUwjg - RootPart.Position).Unit
            _E7BmZ = math.atan2(-RootPart.CFrame.LookVector.X, -RootPart.CFrame.LookVector.Z)
        else
            _lVlTc = (_wKUwjg - _R2Swf).Unit
            _E7BmZ = math.atan2(-_HGlcK.LookVector.X, -_HGlcK.LookVector.Z)
        end
        _LnLfb = math.atan2(-_lVlTc.X, -_lVlTc.Z)
    else
        local _ys134 = _hXRHJ and RootPart.CFrame.LookVector or _HGlcK.LookVector
        _E7BmZ = math.atan2(-_ys134.X, -_ys134.Z)
        _LnLfb = _E7BmZ + math.rad(_DDdVL)
    end
    local _fgMSe = math.atan2(math.sin(_LnLfb - _E7BmZ), math.cos(_LnLfb - _E7BmZ))
    local _YbPNa = _E7BmZ + _fgMSe * _A1RpD
    if _hXRHJ then
        Humanoid.AutoRotate = false
        RootPart.CFrame = CFrame.new(RootPart.Position) * CFrame.Angles(0, _YbPNa, 0)
        if not _atsG3 then
            return
        end
    end
    _v7Dwg8E(_U8Kks, _YbPNa, _uL54o)
end
local function _pN7KD(_Slwqm, _P4NlG, _cHiKV)
    local _JwPQo, _Cqx7Q, _jZ0QM, _AY5GD, _DDwwd, _avN9S, _JtdGl
    if _cHiKV and not (RootPart and Humanoid) then
        return
    end
    _P4NlG = math.max(tonumber(_P4NlG) or 0, 1 / 240)
    _JwPQo = math.rad(_Slwqm)
    _Cqx7Q = tick()
    _jZ0QM = _cHiKV and RootPart.CFrame or Camera.CFrame
    _AY5GD = _jZ0QM.LookVector
    _DDwwd = math.atan2(-_AY5GD.X, -_AY5GD.Z)
    _avN9S = _DDwwd + _JwPQo
    _JtdGl = "KittyWareSmoothRotateCamera" .. tostring(tick())
    _XNd6n[_JtdGl] = true
    RunService:BindToRenderStep(_JtdGl, Enum.RenderPriority.Camera.Value + 1, function()
        local _QK_ZQ, _jWDW1, _TF4nF, _oibZs, _xoBbm, _inRrP, _zMSWx, _Epdkj
        _QK_ZQ = tick() - _Cqx7Q
        _jWDW1 = math.clamp(_QK_ZQ / _P4NlG, 0, 1)
        _TF4nF = _jWDW1 * _jWDW1 * (3 - 2 * _jWDW1)
        _oibZs = Camera.CFrame
        _xoBbm = _oibZs.Position
        _inRrP = _oibZs.LookVector
        _zMSWx = math.asin(math.clamp(_inRrP.Y, -1, 1))
        _Epdkj = _DDwwd + (_avN9S - _DDwwd) * _TF4nF
        if _cHiKV then
            if not (Humanoid and RootPart) then
                RunService:UnbindFromRenderStep(_JtdGl)
                _XNd6n[_JtdGl] = nil
                return
            end
            Humanoid.AutoRotate = false
            RootPart.CFrame = CFrame.new(RootPart.Position) * CFrame.Angles(0, _Epdkj, 0)
        else
            _v7Dwg8E(_xoBbm, _Epdkj, _zMSWx)
        end
        if _jWDW1 >= 1 then
            RunService:UnbindFromRenderStep(_JtdGl)
            _XNd6n[_JtdGl] = nil
        end
    end)
end
local function _t6uaX(_OgGPD, _PHRBh)
    local _kk1_Z, _ZZ3yn, _elHIb, _vOGb3
    if not Camera or not _OgGPD then
        return
    end
    _PHRBh = _PHRBh or 0
    if _PHRBh <= 0 then
        _PHRBh = 0.08
    end
    _kk1_Z = tick()
    _ZZ3yn = Camera.CFrame.LookVector
    _elHIb = math.atan2(-_ZZ3yn.X, -_ZZ3yn.Z)
    _vOGb3 = "KittyWareSmoothRotateCamToPos" .. tostring(tick()) .. tostring(math.random(1000, 9999))
    _XNd6n[_vOGb3] = true
    RunService:BindToRenderStep(_vOGb3, Enum.RenderPriority.Camera.Value + 1, function()
        local _gDCfh, _p44Zr, _KePja, _reriI, _MzsjXMUj, _VsdNr, _GrWcDJ, _XbKvQWF, _cEubcdhH, _RLuEg, _OyOHrn, _NkzCSxA
        _gDCfh = tick() - _kk1_Z
        _p44Zr = math.clamp(_gDCfh / _PHRBh, 0, 1)
        _KePja = _p44Zr * _p44Zr * (3 - 2 * _p44Zr)
        _reriI = Camera.CFrame
        _MzsjXMUj = _reriI.Position
        _VsdNr = _MzsjXMUj
        if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
            _VsdNr = _VsdNr - _reriI.RightVector * 1.75
        end
        _GrWcDJ = _OgGPD - _VsdNr
        _XbKvQWF = _GrWcDJ.Magnitude > 0.01 and _GrWcDJ.Unit or _reriI.LookVector
        _cEubcdhH = math.atan2(-_XbKvQWF.X, -_XbKvQWF.Z)
        _RLuEg = math.atan2(math.sin(_cEubcdhH - _elHIb), math.cos(_cEubcdhH - _elHIb))
        _OyOHrn = _elHIb + _RLuEg * _KePja
        _NkzCSxA = math.asin(math.clamp(_reriI.LookVector.Y, -1, 1))
        _v7Dwg8E(_MzsjXMUj, _OyOHrn, _NkzCSxA)
        if _p44Zr >= 1 then
            RunService:UnbindFromRenderStep(_vOGb3)
            _XNd6n[_vOGb3] = nil
        end
    end)
end
local function _sxJBdGwo(_DSJg_)
    for _ytNUhc = #_vjMDS, 2, -1 do
        local _h_T7iwz = _vjMDS[_ytNUhc]
        local _wc389xzH = _vjMDS[_ytNUhc - 1]
        if _wc389xzH.time <= _DSJg_ and _h_T7iwz.time >= _DSJg_ then
            local _nNJV4 = (_DSJg_ - _wc389xzH.time) / (_h_T7iwz.time - _wc389xzH.time)
            return _wc389xzH.cf:Lerp(_h_T7iwz.cf, _nNJV4)
        end
    end
    return _vjMDS[1] and _vjMDS[1].cf
end
local function _SCYz7(_kINPp)
    local _Rebsb, _G_mVA = pcall(function()
        return Players:GetUserThumbnailAsync(_kINPp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    return _Rebsb and _G_mVA or ""
end
local function _XEzdh(_EPrtH)
    local _Bkair, _KCt41, _rLEQ4
    _Bkair = math.floor(_EPrtH.R * 255)
    _KCt41 = math.floor(_EPrtH.G * 255)
    _rLEQ4 = math.floor(_EPrtH.B * 255)
    return string.format("#%02X%02X%02X", _Bkair, _KCt41, _rLEQ4)
end
local function _opUYh(_Vd3VT, _eNyEw)
    if not _Vd3VT or not _eNyEw then
        return false
    end
    for _bGDnA, _Iu8_u in ipairs(_Vd3VT:GetChildren()) do
        if _eNyEw[_Iu8_u.Name] or table.find(_eNyEw, _Iu8_u.Name) then
            return false
        end
    end
    return true
end
local function _ZvzU8(_OAVDH, _vyULz, _M0lkk)
    if not (Character and Character.PrimaryPart and RootPart) then
        return
    end
    RootPart.CFrame = CFrame.new(_OAVDH.Position) * _vyULz * _M0lkk
    Character:SetPrimaryPartCFrame(CFrame.new(_OAVDH.Position) * _vyULz * _M0lkk)
    RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
    RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
end
local function _tCAt2(_ivDNC)
    local _zfcIs = _ivDNC and _ivDNC:FindFirstChild("HumanoidRootPart")
    local _gcElC = _ivDNC and _ivDNC:FindFirstChild("Humanoid")
    if not (_zfcIs and _gcElC and RootPart and Character) then
        return
    end
    local _TlRhI = Instance.new("BodyVelocity")
    _TlRhI.Parent = RootPart
    _TlRhI.Velocity = Vector3.new(0, 0, 0)
    _TlRhI.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    local _KFdXC = tick()
    local _d9k6S = 0
    local _grRPL = 0
    local _zEYJx = RootPart.CFrame
    _UbxYIsuM(RootPart, "CFrame")
    for _q7qeh, _tdlrX in pairs(Character:GetChildren()) do
        if _tdlrX:IsA("BasePart") then
            _UbxYIsuM(_tdlrX, "Velocity")
            _UbxYIsuM(_tdlrX, "RotVelocity")
        end
    end
    workspace.FallenPartsDestroyHeight = 0 / 0
    repeat
        _grRPL = _grRPL + 1
        if _grRPL > 1 then
            _grRPL = 0
        end
        if _zfcIs.Velocity.Magnitude < 50 then
            _d9k6S = _d9k6S + 100
            if _grRPL == 1 then
                _ZvzU8(_zfcIs, CFrame.new(0, 1.5, 0) + _gcElC.MoveDirection * _zfcIs.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(_d9k6S), 0, 0))
                _ZvzU8(_zfcIs, CFrame.new(0, 1.5, 0) + _gcElC.MoveDirection, CFrame.Angles(math.rad(_d9k6S), 0, 0))
            else
                _ZvzU8(_zfcIs, CFrame.new(0, -1.5, 0) + _gcElC.MoveDirection * _zfcIs.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(_d9k6S), 0, 0))
                _ZvzU8(_zfcIs, CFrame.new(0, -1.5, 0) + _gcElC.MoveDirection, CFrame.Angles(math.rad(_d9k6S), 0, 0))
            end
        else
            if _grRPL == 1 then
                _ZvzU8(_zfcIs, CFrame.new(0, 1.5, _gcElC.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                _ZvzU8(_zfcIs, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
            else
                _ZvzU8(_zfcIs, CFrame.new(0, -1.5, -_gcElC.WalkSpeed), CFrame.Angles(0, 0, 0))
                _ZvzU8(_zfcIs, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
            end
        end
        task.wait()
    until Unloaded or _KFdXC + 3 < tick()
    _TlRhI:Destroy()
    local _MmEEE = tick() + 3
    repeat
        RootPart.CFrame = _zEYJx * CFrame.new(0, 0.5, 0)
        Character:SetPrimaryPartCFrame(_zEYJx * CFrame.new(0, 0.5, 0))
        for _vo9Ju, _Gff8H in pairs(Character:GetChildren()) do
            if _Gff8H:IsA("BasePart") then
                _UbxYIsuM(_Gff8H, "Velocity")
                _UbxYIsuM(_Gff8H, "RotVelocity")
                _Gff8H.Velocity, _Gff8H.RotVelocity = Vector3.new(), Vector3.new()
            end
        end
        task.wait()
    until (RootPart.Position - _zEYJx.Position).Magnitude < 25 or tick() > _MmEEE or not Character.Parent
    workspace.FallenPartsDestroyHeight = DefaultDestroyHeight
    if not Unloaded then
        for _ZiWeV, _N2pSt in pairs(Character:GetChildren()) do
            local _aMaqO = _sDkXo[_N2pSt]
            if _aMaqO then
                _aMaqO.CFrame, _aMaqO.Velocity, _aMaqO.RotVelocity = nil, nil, nil
            end
        end
    end
end
local function _fwa6a(_Yk1jk, _l7EqW)
    task.wait(_l7EqW)
    if not (RootPart and Humanoid) then
        return
    end
    if _xFaaK(_j089A.backDash, Humanoid) then
        return
    end
    State.boostUntil = tick() + 1
    RootPart.AssemblyLinearVelocity = Vector3.new(RootPart.AssemblyLinearVelocity.X * _Yk1jk, RootPart.AssemblyLinearVelocity.Y, RootPart.AssemblyLinearVelocity.Z * _Yk1jk)
end
local function _yNOi1(_jNIPf)
    local _wlYra, _J486h, _WOna7
    if not (RootPart and _jNIPf) then
        return false
    end
    _wlYra = RootPart.Position
    _J486h = _jNIPf.Position
    _WOna7 = (Vector3.new(_wlYra.X, 0, _wlYra.Z) - Vector3.new(_J486h.X, 0, _J486h.Z)).Magnitude
    if _WOna7 <= 0.2 and _wlYra.Y < _J486h.Y then
        return true
    end
    return false
end
State.ping = 0
task.spawn(function()
    while not Unloaded do
        local _Hx9En, _UW76pP = pcall(DataPingItem.GetValue, DataPingItem)
        if _Hx9En then
            State.ping = _UW76pP
        end
        task.wait(0.25)
    end
end)
local function getPing(_abuUFeVu)
    return State.ping / (_abuUFeVu or 1)
end
local function _fwJeEv6(_sVRdQJeO)
    local _lSzXe = _sVRdQJeO + (getPing() - 50) *-0
    return {_lSzXe, _sVRdQJeO - _lSzXe}
end
local function _yah1udeS(_xzl6M6T, _EwITr2)
    if _EwITr2:FindFirstChild("Counter") then
        return Config.Visuals.ESP.DeathCounterColor
    elseif _EwITr2:GetAttribute("Ulted") then
        if _EwITr2:GetAttribute("Character") == "Bald" then
            return Config.Visuals.ESP.SaitamaUltColor
        end
        return Config.Visuals.ESP.UltColor
    elseif _JrRW2(_xzl6M6T, false) then
        return Config.Visuals.ESP.FriendColor
    elseif _xzl6M6T and PlayerFrames[_xzl6M6T.Name] == "Enemy" then
        return Config.Visuals.ESP.EnemyColor
    end
    return Config.Visuals.ESP.NeutralColor
end
local function _rR9ON(_e_Ig9KYc)
    local _tauTR7j, _gvlHNr
    if not PlayerGui then
        return nil
    end
    _tauTR7j = PlayerGui:FindFirstChild("Hotbar") or (not _e_Ig9KYc and PlayerGui.WaitForChild and PlayerGui:WaitForChild("Hotbar", 0.05))
    if not _tauTR7j then
        return nil
    end
    _gvlHNr = _tauTR7j:FindFirstChild("Backpack") or (not _e_Ig9KYc and _tauTR7j.WaitForChild and _tauTR7j:WaitForChild("Backpack", 0.05))
    if not _gvlHNr then
        return nil
    end
    return _gvlHNr:FindFirstChild("Hotbar") or (not _e_Ig9KYc and _gvlHNr.WaitForChild and _gvlHNr:WaitForChild("Hotbar", 0.05))
end
local function _TQDHO()
    local _G6oE8, _VjNkx, _ISiUp, _vEWQk, _CHzgX, _xkq0a
    _G6oE8 = PlayerGui:FindFirstChild("Bar") or (PlayerGui.WaitForChild and PlayerGui:WaitForChild("Bar", 0.05))
    if not _G6oE8 then
        return
    end
    _VjNkx = _G6oE8:FindFirstChild("MagicHealth") or (_G6oE8.WaitForChild and _G6oE8:WaitForChild("MagicHealth", 0.05))
    if not _VjNkx then
        return
    end
    _ISiUp = _VjNkx:WaitForChild("Health", 0.05):WaitForChild("Bar", 0.05):WaitForChild("Bar", 0.05)
    _vEWQk = _VjNkx:WaitForChild("TextLabel", 0.05)
    _CHzgX = _VjNkx:WaitForChild("cdholder", 0.05)
    _xkq0a = _rR9ON()
    disconnectAll(_rJ2QD)
    connectSignal(_CHzgX.ChildAdded, function(_k5FsR)
        if _k5FsR.Name == "forward" or _k5FsR.Name == "side" or _k5FsR.Name == "evasive" or _k5FsR.Name == "burst" then
            local _q5lju = _k5FsR:WaitForChild("template", 0.05):WaitForChild("Fill", 0.05)
            if Config.Visuals.CustomUltbar.UltbarColor.Enabled then
                _IeaiYt2E(_q5lju, "BackgroundColor3", Config.Visuals.CustomUltbar.UltbarColor.Color)
            else
                _IeaiYt2E(_q5lju, "BackgroundColor3", Color3.fromRGB(255, 78, 78))
            end
        end
    end)
    if _xkq0a then
        for _fZbiN = 1, 4 do
            local _YIcQB = _xkq0a:FindFirstChild(tostring(_fZbiN)) or (_xkq0a.WaitForChild and _xkq0a:WaitForChild(tostring(_fZbiN), 0.1))
            local _he5Vv = _YIcQB and (_YIcQB:FindFirstChild("Base") or (_YIcQB.WaitForChild and _YIcQB:WaitForChild("Base", 0.1)))
            if _he5Vv then
                local _HXyfH = connectSignal(_he5Vv.ChildAdded, function(_S4W_p)
                    if _S4W_p.Name == "Cooldown" then
                        if Config.Visuals.CustomUltbar.UltbarColor.Enabled then
                            _IeaiYt2E(_S4W_p, "BackgroundColor3", Config.Visuals.CustomUltbar.UltbarColor.Color)
                        else
                            _IeaiYt2E(_S4W_p, "BackgroundColor3", Color3.fromRGB(255, 87, 87))
                        end
                    end
                end)
                table.insert(_rJ2QD, _HXyfH)
            end
        end
    end
    if Config.Visuals.CustomUltbar.UltbarText.Enabled then
        _IeaiYt2E(_vEWQk, "Text", Config.Visuals.CustomUltbar.UltbarText.Text)
    else
        _IeaiYt2E(_vEWQk, "Text", Character:GetAttribute("UltimateName") or "Other")
    end
    if Config.Visuals.CustomUltbar.UltbarColor.Enabled then
        _IeaiYt2E(_ISiUp, "ImageColor3", Config.Visuals.CustomUltbar.UltbarColor.Color)
    else
        _IeaiYt2E(_ISiUp, "ImageColor3", Color3.fromRGB(255, 87, 87))
    end
end
local BoxESP = {
    entries = {},
    gui = nil,
    conn = nil
}
BoxESP.getGui = function()
    local _JbQNn, _u3vkF
    if BoxESP.gui and BoxESP.gui.Parent then
        return BoxESP.gui
    end
    _JbQNn = Instance.new("ScreenGui")
    _JbQNn.Name = "KittyBoxes"
    _JbQNn.ResetOnSpawn = false
    _JbQNn.IgnoreGuiInset = true
    _JbQNn.DisplayOrder = 10
    _u3vkF = pcall(function()
        _JbQNn.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if not _u3vkF or not _JbQNn.Parent then
        _JbQNn.Parent = PlayerGui
    end
    BoxESP.gui = _JbQNn
    return _JbQNn
end
BoxESP.bounds = function(_jtZcU, _wiEtA, _lct7a)
    local _W2grW, _fFgSi, _YFjN3, _j3_CA, _eA1qe, _pSAwZ, _w9N93, _nCT0H, _HGJTD, _zuW8R, _M2biu, _VFKzk, _ORjSI
    _W2grW = _lct7a.CFrame
    _fFgSi, _YFjN3, _j3_CA = math.huge, math.huge, math.huge
    _eA1qe, _pSAwZ, _w9N93 =-math.huge, -math.huge, -math.huge
    _nCT0H = math.abs
    for _CNQM7, _NTnVq in ipairs(_jtZcU:GetChildren()) do
        if _NTnVq:IsA("BasePart") and _NTnVq.Name ~= "HumanoidRootPart" then
            local _AlG7u, _LITSi, _aOgvw, _lrX3d, _Yy8tF, _jHiIm, _yPInB, _p3Pho, _wnRk3
            _AlG7u, _LITSi = _W2grW:ToObjectSpace(_NTnVq.CFrame), _NTnVq.Size / 2
            _aOgvw, _lrX3d, _Yy8tF, _jHiIm = _AlG7u.XVector, _AlG7u.YVector, _AlG7u.ZVector, _AlG7u.Position
            _yPInB = _nCT0H(_aOgvw.X) * _LITSi.X + _nCT0H(_lrX3d.X) * _LITSi.Y + _nCT0H(_Yy8tF.X) * _LITSi.Z
            _p3Pho = _nCT0H(_aOgvw.Y) * _LITSi.X + _nCT0H(_lrX3d.Y) * _LITSi.Y + _nCT0H(_Yy8tF.Y) * _LITSi.Z
            _wnRk3 = _nCT0H(_aOgvw.Z) * _LITSi.X + _nCT0H(_lrX3d.Z) * _LITSi.Y + _nCT0H(_Yy8tF.Z) * _LITSi.Z
            if _jHiIm.X - _yPInB < _fFgSi then
                _fFgSi = _jHiIm.X - _yPInB
            end
            if _jHiIm.Y - _p3Pho < _YFjN3 then
                _YFjN3 = _jHiIm.Y - _p3Pho
            end
            if _jHiIm.Z - _wnRk3 < _j3_CA then
                _j3_CA = _jHiIm.Z - _wnRk3
            end
            if _jHiIm.X + _yPInB > _eA1qe then
                _eA1qe = _jHiIm.X + _yPInB
            end
            if _jHiIm.Y + _p3Pho > _pSAwZ then
                _pSAwZ = _jHiIm.Y + _p3Pho
            end
            if _jHiIm.Z + _wnRk3 > _w9N93 then
                _w9N93 = _jHiIm.Z + _wnRk3
            end
        end
    end
    if _fFgSi == math.huge then
        return nil
    end
    _HGJTD, _zuW8R, _M2biu, _VFKzk = math.huge, math.huge, -math.huge, -math.huge
    _ORjSI = false
    for _XQQfg = 0, 7 do
        local _kiNZD = Vector3.new(_XQQfg % 2 == 0 and _fFgSi or _eA1qe, _XQQfg % 4 < 2 and _YFjN3 or _pSAwZ, _XQQfg < 4 and _j3_CA or _w9N93)
        local _Z9TMp = _wiEtA:WorldToViewportPoint(_W2grW:PointToWorldSpace(_kiNZD))
        if _Z9TMp.Z > 0 then
            _ORjSI = true
            if _Z9TMp.X < _HGJTD then
                _HGJTD = _Z9TMp.X
            end
            if _Z9TMp.Y < _zuW8R then
                _zuW8R = _Z9TMp.Y
            end
            if _Z9TMp.X > _M2biu then
                _M2biu = _Z9TMp.X
            end
            if _Z9TMp.Y > _VFKzk then
                _VFKzk = _Z9TMp.Y
            end
        end
    end
    if not _ORjSI then
        return nil
    end
    return math.floor(_HGJTD + 0.5), math.floor(_zuW8R + 0.5), math.floor(_M2biu - _HGJTD + 0.5), math.floor(_VFKzk - _zuW8R + 0.5)
end
BoxESP.ringLines = function(_mQ1knaV8, _vTJB91o)
    local _IfjmMY = {}
    for _x_jvv = 1, 4 do
        local _KRAs_zBe
        _KRAs_zBe = Instance.new("Frame")
        _KRAs_zBe.BorderSizePixel = 0
        _KRAs_zBe.BackgroundColor3 = _vTJB91o
        _KRAs_zBe.Parent = _mQ1knaV8
        _IfjmMY[_x_jvv] = _KRAs_zBe
    end
    return _IfjmMY
end
BoxESP.placeRing = function(_hWeW72s, _oRszEZ, _faFnu, _SSbOv8Ct, _dtbgzyc)
    _hWeW72s[1].Position = UDim2.fromOffset(_oRszEZ, _oRszEZ)
    _hWeW72s[1].Size = UDim2.fromOffset(_SSbOv8Ct - 2 * _oRszEZ, _faFnu)
    _hWeW72s[2].Position = UDim2.fromOffset(_oRszEZ, _dtbgzyc - _oRszEZ - _faFnu)
    _hWeW72s[2].Size = UDim2.fromOffset(_SSbOv8Ct - 2 * _oRszEZ, _faFnu)
    _hWeW72s[3].Position = UDim2.fromOffset(_oRszEZ, _oRszEZ + _faFnu)
    _hWeW72s[3].Size = UDim2.fromOffset(_faFnu, _dtbgzyc - 2 * _oRszEZ - 2 * _faFnu)
    _hWeW72s[4].Position = UDim2.fromOffset(_SSbOv8Ct - _oRszEZ - _faFnu, _oRszEZ + _faFnu)
    _hWeW72s[4].Size = UDim2.fromOffset(_faFnu, _dtbgzyc - 2 * _oRszEZ - 2 * _faFnu)
end
BoxESP.layout = function(_QQTLhs, _HbdhV, _O3IOB, _F16FS, _sy2Ol)
    local _DL55Q, _q2iHF, _h2JWx, _Uzo7T, _fKFUS
    _DL55Q = _HbdhV .. "|" .. _O3IOB .. "|" .. _F16FS .. "|" .. _sy2Ol .. "|" .. _QQTLhs.thick
    if _QQTLhs.key == _DL55Q then
        return
    end
    _QQTLhs.key = _DL55Q
    _q2iHF = _QQTLhs.thick
    _h2JWx = _q2iHF + 2
    _Uzo7T, _fKFUS = _F16FS + 2 * _h2JWx, _sy2Ol + 2 * _h2JWx
    _QQTLhs.root.Position = UDim2.fromOffset(_HbdhV - _h2JWx, _O3IOB - _h2JWx)
    _QQTLhs.root.Size = UDim2.fromOffset(_Uzo7T, _fKFUS)
    BoxESP.placeRing(_QQTLhs.outer, 0, 1, _Uzo7T, _fKFUS)
    BoxESP.placeRing(_QQTLhs.main, 1, _q2iHF, _Uzo7T, _fKFUS)
    BoxESP.placeRing(_QQTLhs.inner, 1 + _q2iHF, 1, _Uzo7T, _fKFUS)
    _QQTLhs.fill.Position = UDim2.fromOffset(_h2JWx, _h2JWx)
    _QQTLhs.fill.Size = UDim2.fromOffset(_F16FS, _sy2Ol)
end
BoxESP.step = function()
    local _S1SQ1, _J3i47, _QYxjO, _HJ7zL, _u0UX9
    _S1SQ1 = workspace.CurrentCamera
    if not _S1SQ1 then
        return
    end
    _J3i47 = _S1SQ1.CFrame.Position
    _QYxjO = _S1SQ1.ViewportSize
    _HJ7zL, _u0UX9 = _QYxjO.X + 80, _QYxjO.Y + 80
    for _EOodm, _tTg1H in pairs(BoxESP.entries) do
        local _iZ2Lm = _EOodm.Parent and _EOodm:FindFirstChild("HumanoidRootPart")
        local _rT9kb = _iZ2Lm and _EOodm:FindFirstChildOfClass("Humanoid")
        if not _iZ2Lm then
            pcall(function()
                _tTg1H.root:Destroy()
            end)
            BoxESP.entries[_EOodm] = nil
        elseif (_rT9kb and _rT9kb.Health <= 0) then
            _tTg1H.root.Visible = false
        else
            local _gBstv, _VUMHu, _eoVGv, _TSIcS
            _gBstv = _iZ2Lm.Position
            _VUMHu = _gBstv.X - _J3i47.X
            _eoVGv = _gBstv.Y - _J3i47.Y
            _TSIcS = _gBstv.Z - _J3i47.Z
            if (_VUMHu * _VUMHu + _eoVGv * _eoVGv + _TSIcS * _TSIcS) > 40000 then
                _tTg1H.root.Visible = false
            else
                local _IYC_m = _S1SQ1:WorldToViewportPoint(_gBstv)
                if _IYC_m.Z <= 0 or _IYC_m.X <-80 or _IYC_m.X > _HJ7zL or _IYC_m.Y <-80 or _IYC_m.Y > _u0UX9 then
                    _tTg1H.root.Visible = false
                else
                    local _xJZN7, _qkxCW, _B3mei, _MQ6GX = BoxESP.bounds(_EOodm, _S1SQ1, _iZ2Lm)
                    if _xJZN7 and _B3mei >= 4 and _MQ6GX >= 4 then
                        BoxESP.layout(_tTg1H, _xJZN7, _qkxCW, _B3mei, _MQ6GX)
                        _tTg1H.root.Visible = true
                    else
                        _tTg1H.root.Visible = false
                    end
                end
            end
        end
    end
end
BoxESP.set = function(_DjboQ, _OW2eK)
    local _ZQuoY = BoxESP.entries[_DjboQ]
    if not _ZQuoY then
        local _Q4lZ2, _b1L5D, _mVK4R
        _Q4lZ2 = Instance.new("Frame")
        _Q4lZ2.BackgroundTransparency = 1
        _Q4lZ2.BorderSizePixel = 0
        _Q4lZ2.Visible = false
        _b1L5D = Instance.new("Frame")
        _b1L5D.BorderSizePixel = 0
        _b1L5D.Parent = _Q4lZ2
        _mVK4R = Color3.new(0, 0, 0)
        _ZQuoY = {
            root = _Q4lZ2,
            fill = _b1L5D,
            outer = BoxESP.ringLines(_Q4lZ2, _mVK4R),
            main = BoxESP.ringLines(_Q4lZ2, _OW2eK),
            inner = BoxESP.ringLines(_Q4lZ2, _mVK4R)
        }
        _Q4lZ2.Parent = BoxESP.getGui()
        BoxESP.entries[_DjboQ] = _ZQuoY
    end
    _ZQuoY.thick = math.clamp(math.floor((Config.Visuals.ESP.BoxThickness or 1) + 0.5), 1, 6)
    _ZQuoY.key = nil
    for _dYDJ6, _ofwlj in ipairs(_ZQuoY.main) do
        _ofwlj.BackgroundColor3 = _OW2eK
    end
    _ZQuoY.fill.BackgroundColor3 = _OW2eK
    _ZQuoY.fill.BackgroundTransparency = Config.Visuals.ESP.BoxFilled and 0.85 or 1
    if not BoxESP.conn then
        BoxESP.conn = connectSignal(RunService.RenderStepped, BoxESP.step)
    end
end
BoxESP.remove = function(_z00fL)
    local _qvVjP = BoxESP.entries[_z00fL]
    if _qvVjP then
        _qvVjP.root:Destroy()
        BoxESP.entries[_z00fL] = nil
    end
    if BoxESP.conn and not next(BoxESP.entries) then
        _vA5WJ(BoxESP.conn)
        BoxESP.conn = nil
    end
end
BoxESP.destroy = function()
    for _BZ4J4 in pairs(BoxESP.entries) do
        BoxESP.remove(_BZ4J4)
    end
    if BoxESP.gui then
        BoxESP.gui:Destroy()
        BoxESP.gui = nil
    end
end
local function _M5_tm(_XZqmo, _OVhkZ, _Z0uRz)
    if (Config.Visuals.ESP.Enabled) or ((Config.Visuals.ESP.DeathCounterESP or Config.Visuals.ESP.SaitamaUltESP) and _Z0uRz) then
        local _kfJlg = _OVhkZ:FindFirstChild("Head")
        local _bAzz2 = _OVhkZ:FindFirstChild("ESP")
        local _mWIs8 = _yah1udeS(_XZqmo, _OVhkZ)
        local _x1tX9 = _OVhkZ:FindFirstChild("Highlight")
        if _x1tX9 then
            task.defer(_x1tX9.Destroy, _x1tX9)
        end
        if Config.Visuals.ESP.Highlight ~= false then
            if not _bAzz2 then
                _bAzz2 = Instance.new("Highlight")
            end
            _bAzz2.Name = "ESP"
            _bAzz2.FillTransparency = Config.Visuals.ESP.OutlineTransparency
            _bAzz2.FillColor = _mWIs8
            _bAzz2.OutlineTransparency = 1
            _bAzz2.Parent = _OVhkZ
        elseif _bAzz2 then
            _bAzz2:Destroy()
        end
        local _NS7mW = _OVhkZ:FindFirstChild("KittyBoxESP")
        if _NS7mW then
            _NS7mW:Destroy()
        end
        if Config.Visuals.ESP.Boxes then
            BoxESP.set(_OVhkZ, Config.Visuals.ESP.BoxUseESPColor and _mWIs8 or Config.Visuals.ESP.BoxColor)
        else
            BoxESP.remove(_OVhkZ)
        end
        if not _kfJlg or Config.Visuals.ESP.NoBillboards then
            return
        end
        local _i5la_lk3 = _kfJlg:FindFirstChild("CheatGui") or Instance.new("BillboardGui", _kfJlg)
        local _Dhs3vad = _i5la_lk3:FindFirstChild("TextLabel") or Instance.new("TextLabel", _i5la_lk3)
        _i5la_lk3.Name = "CheatGui"
        _i5la_lk3.Size = UDim2.fromScale(10, 2)
        _i5la_lk3.StudsOffset = Vector3.new(0, 4, 0)
        _Dhs3vad.Size = UDim2.fromScale(1, 1)
        _Dhs3vad.TextScaled = true
        _Dhs3vad.Font = Enum.Font.RobotoMono
        _Dhs3vad.TextColor3 = _mWIs8
        _Dhs3vad.BackgroundTransparency = 1
        local _E7OmmT = CharacterNames[_OVhkZ:GetAttribute("Character")] or "Other"
        local _ZmEzc = (_XZqmo and _XZqmo:GetAttribute("Ultimate")) or 0
        _Dhs3vad.Text = _E7OmmT .. " " .. math.floor(_ZmEzc) .. "% Ult \n" .. (_XZqmo and _XZqmo.Name or _OVhkZ.Name)
    end
end
local function _uwnGWzzi(_jaBtaeX, _wrwleq, _bEMbS)
    local _GRGnxhd8 = _jaBtaeX:FindFirstChild("ESP")
    local _FHm8agO = _jaBtaeX:FindFirstChild("Head")
    local _kT4OdR7V = _jaBtaeX:FindFirstChild("KittyBoxESP")
    if _GRGnxhd8 and not _bEMbS then
        _GRGnxhd8:Destroy()
    end
    if _kT4OdR7V and not _bEMbS then
        _kT4OdR7V:Destroy()
    end
    if not _bEMbS then
        BoxESP.remove(_jaBtaeX)
    end
    if _FHm8agO then
        local _Pgo9a = _FHm8agO:FindFirstChild("CheatGui")
        if _Pgo9a then
            _Pgo9a:Destroy()
        end
    end
end
local function _aKxqPdSj(_FTdGp, _kf4gi)
    for _jncD6, _ObWIq in pairs(Players:GetChildren()) do
        if _ObWIq ~= LocalPlayer then
            local _t2Cjx = _ObWIq.Character
            if _t2Cjx then
                if _FTdGp then
                    _uwnGWzzi(_t2Cjx, _ObWIq, _kf4gi)
                else
                    _M5_tm(_ObWIq, _t2Cjx)
                end
            end
        end
    end
end
local function _Eg6Ge()
    for _j7ikc, _OVzoC in ipairs(Players:GetPlayers()) do
        local _N9uXV = _OVzoC ~= LocalPlayer and _OVzoC.Character
        if _N9uXV then
            _uwnGWzzi(_N9uXV, _OVzoC, false)
            local _sLGb1 = _N9uXV:FindFirstChild("Counter") ~= nil or (_N9uXV:GetAttribute("Ulted") and _N9uXV:GetAttribute("Character") == "Bald")
            _M5_tm(_OVzoC, _N9uXV, _sLGb1)
        end
    end
end
local _XBTS0 = {}
local function _CperF(_NSADL, _sGRHo)
    State.noTexRun = (State.noTexRun or 0) + 1
    local _Xkmy_ = State.noTexRun
    local function _WPmPE()
        local _BZad1 = os.clock()
        local function _gmYrb()
            if Unloaded then
                return true
            end
            if os.clock() - _BZad1 > 0.003 then
                RunService.Heartbeat:Wait()
                _BZad1 = os.clock()
            end
            return _Xkmy_ == State.noTexRun
        end
        if _NSADL or (_sGRHo and next(_XBTS0) == nil) then
            for _qCIi9, _XYh5p in ipairs({World.Map or workspace:FindFirstChild("Map"), workspace:FindFirstChild("Cutscenes")}) do
                for _Al1_x, _BOX7A in ipairs(_XYh5p:GetDescendants()) do
                    if _BOX7A:IsA("BasePart") and _XBTS0[_BOX7A] == nil then
                        _XBTS0[_BOX7A] = _BOX7A.Material
                    end
                    if not _gmYrb() then
                        return
                    end
                end
            end
        end
        for _S6cOl, _lsTQT in pairs(_XBTS0) do
            if _S6cOl.Parent then
                _S6cOl.Material = _sGRHo and Enum.Material.Plastic or _lsTQT
            end
            if not _gmYrb() then
                return
            end
        end
    end
    if Unloaded then
        _WPmPE()
    else
        task.spawn(_WPmPE)
    end
end
local _cmUMF = {
    highlight = nil,
    headMask = nil,
    mats = {}
}
local function _vNYEl()
    for _S1n8e, _ljKIj in pairs(_cmUMF.mats) do
        if _S1n8e and _S1n8e.Parent then
            pcall(function()
                _S1n8e.Material = _ljKIj[1]
                _S1n8e.Color = _ljKIj[2]
                _S1n8e.CustomPhysicalProperties = _ljKIj[3]
            end)
        end
    end
    table.clear(_cmUMF.mats)
end
local function _oQwzM()
    local _H8a_S = Character or LocalPlayer.Character
    if not (Config.Visuals.SelfChams.Enabled and _H8a_S and _H8a_S.Parent) then
        if _cmUMF.highlight then
            pcall(function()
                _cmUMF.highlight:Destroy()
            end)
            _cmUMF.highlight = nil
        end
        if _cmUMF.headMask then
            pcall(function()
                _cmUMF.headMask:Destroy()
            end)
            _cmUMF.headMask = nil
        end
        _vNYEl()
        return
    end
    local _eupSm = Config.Visuals.SelfChams.Color
    if not (_cmUMF.highlight and _cmUMF.highlight.Parent == _H8a_S) then
        if _cmUMF.highlight then
            pcall(function()
                _cmUMF.highlight:Destroy()
            end)
        end
        local _RZFaO = _H8a_S:FindFirstChild("KittySelfChams")
        if _RZFaO and _RZFaO:IsA("Highlight") then
            _cmUMF.highlight = _RZFaO
        else
            _cmUMF.highlight = Instance.new("Highlight")
            _cmUMF.highlight.Name = "KittySelfChams"
            _cmUMF.highlight.Adornee = _H8a_S
            _cmUMF.highlight.Parent = _H8a_S
        end
    end
    _cmUMF.highlight.FillColor = _eupSm
    _cmUMF.highlight.OutlineColor = _eupSm
    _cmUMF.highlight.FillTransparency = Config.Visuals.SelfChams.FillTransparency
    _cmUMF.highlight.OutlineTransparency = Config.Visuals.SelfChams.OutlineTransparency
    _cmUMF.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    local _oMFBZ = HeadPart or _H8a_S:FindFirstChild("Head")
    if Config.Visuals.Headless and _oMFBZ and _oMFBZ.Parent == _H8a_S then
        if not (_cmUMF.headMask and _cmUMF.headMask.Parent == _oMFBZ) then
            if _cmUMF.headMask then
                pcall(function()
                    _cmUMF.headMask:Destroy()
                end)
            end
            local _Hkgtd = _oMFBZ:FindFirstChild("KittySelfChamsHeadMask")
            if _Hkgtd and _Hkgtd:IsA("Highlight") then
                _cmUMF.headMask = _Hkgtd
            else
                _cmUMF.headMask = Instance.new("Highlight")
                _cmUMF.headMask.Name = "KittySelfChamsHeadMask"
                _cmUMF.headMask.Adornee = _oMFBZ
                _cmUMF.headMask.Parent = _oMFBZ
            end
        end
        _cmUMF.headMask.FillTransparency = 1
        _cmUMF.headMask.OutlineTransparency = 1
        _cmUMF.headMask.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    else
        if _cmUMF.headMask then
            pcall(function()
                _cmUMF.headMask:Destroy()
            end)
            _cmUMF.headMask = nil
        end
    end
    local _KBwd6 = Config.Visuals.SelfChams.Material
    if _KBwd6 and _KBwd6 ~= "None" then
        local _dyqF1 = Enum.Material[_KBwd6] or Enum.Material.ForceField
        for _Ah8iP, _n_Kwe in ipairs(_H8a_S:GetDescendants()) do
            if _n_Kwe:IsA("BasePart") and _n_Kwe.Name ~= "HumanoidRootPart" and not _n_Kwe:FindFirstAncestorWhichIsA("Tool") then
                if not _cmUMF.mats[_n_Kwe] then
                    _cmUMF.mats[_n_Kwe] = {_n_Kwe.Material, _n_Kwe.Color, _n_Kwe.CustomPhysicalProperties}
                    _n_Kwe.CustomPhysicalProperties = _n_Kwe.CurrentPhysicalProperties
                end
                if _n_Kwe.Material ~= _dyqF1 then
                    _n_Kwe.Material = _dyqF1
                end
                _n_Kwe.Color = _eupSm
            end
        end
    else
        _vNYEl()
    end
end
local function _K0t9W(_dLkZs)
    local _ga5DU = Character or LocalPlayer.Character
    if not _ga5DU then
        return
    end
    local _zNIqW = _ga5DU:FindFirstChild("Right Leg")
    local _WwRku = _ga5DU:FindFirstChildOfClass("Humanoid")
    if not _zNIqW then
        return
    end
    if _dLkZs then
        for _pkakj, _gqcJm in ipairs(_ga5DU:GetChildren()) do
            if _gqcJm:IsA("CharacterMesh") and (_gqcJm.Name == "KittyKorbloxCM" or _gqcJm.BodyPart == Enum.BodyPart.RightLeg) then
                pcall(function()
                    _gqcJm:Destroy()
                end)
            end
        end
        if _WwRku then
            pcall(function()
                local _z87uz9J = _WwRku:GetAppliedDescription()
                if _z87uz9J then
                    _z87uz9J.RightLeg = 139607718
                    _WwRku:ApplyDescription(_z87uz9J)
                end
            end)
        end
        local _WP3Sgybg = false
        pcall(function()
            local _VbZTs = game:GetObjects("rbxassetid://139607718")
            if _VbZTs and #_VbZTs > 0 then
                for _sVij5Y, _LMAzx6P in ipairs(_VbZTs) do
                    if _LMAzx6P:IsA("CharacterMesh") and _LMAzx6P.BodyPart == Enum.BodyPart.RightLeg then
                        _LMAzx6P.Name = "KittyKorbloxCM"
                        _LMAzx6P.Parent = _ga5DU
                        _WP3Sgybg = true
                    else
                        for _zuSl39H, _UCcymD3v in ipairs(_LMAzx6P:GetDescendants()) do
                            if _UCcymD3v:IsA("CharacterMesh") and _UCcymD3v.BodyPart == Enum.BodyPart.RightLeg then
                                _UCcymD3v.Name = "KittyKorbloxCM"
                                _UCcymD3v.Parent = _ga5DU
                                _WP3Sgybg = true
                            end
                        end
                    end
                end
            end
        end)
        if _zNIqW then
            if not _WP3Sgybg then
                local _HuFAX = Instance.new("CharacterMesh")
                _HuFAX.Name = "KittyKorbloxCM"
                _HuFAX.MeshId = 101851696
                _HuFAX.OverlayTextureId = 101851254
                _HuFAX.BaseTextureId = 101851254
                _HuFAX.BodyPart = Enum.BodyPart.RightLeg
                _HuFAX.Parent = _ga5DU
            end
            local _GEnMnf = _zNIqW:FindFirstChild("KittyKorbloxSM") or Instance.new("SpecialMesh")
            _GEnMnf.Name = "KittyKorbloxSM"
            _GEnMnf.MeshType = Enum.MeshType.FileMesh
            _GEnMnf.MeshId = "rbxassetid://101851696"
            _GEnMnf.TextureId = "rbxassetid://101851254"
            _GEnMnf.Scale = Vector3.new(1, 1, 1)
            _GEnMnf.Offset = Vector3.new(0, 0, 0)
            _GEnMnf.Parent = _zNIqW
            _IeaiYt2E(_zNIqW, "Transparency", 0)
            local _pZjwKwu = Color3.fromRGB(27, 42, 53)
            _IeaiYt2E(_zNIqW, "Color", _pZjwKwu)
            local _Ufi2yqNl = _ga5DU:FindFirstChildOfClass("BodyColors")
            if _Ufi2yqNl then
                _IeaiYt2E(_Ufi2yqNl, "RightLegColor3", _pZjwKwu)
            end
            _vA5WJ(_wZKifJPa.korblox)
            _wZKifJPa.korblox = connectSignal(_zNIqW:GetPropertyChangedSignal("Color"), function()
                if Config.Visuals.Korblox and _zNIqW.Color ~= _pZjwKwu then
                    _zNIqW.Color = _pZjwKwu
                end
            end)
        end
    else
        _vA5WJ(_wZKifJPa.korblox)
        _wZKifJPa.korblox = nil
        if _zNIqW then
            _zNIqW.Color = _UbxYIsuM(_zNIqW, "Color")
        end
        local _bBxok = _ga5DU:FindFirstChildOfClass("BodyColors")
        if _bBxok then
            _bBxok.RightLegColor3 = _UbxYIsuM(_bBxok, "RightLegColor3")
        end
        for _GnS5ed, _payrV in ipairs(_ga5DU:GetChildren()) do
            if _payrV:IsA("CharacterMesh") and (_payrV.Name == "KittyKorbloxCM" or _payrV.BodyPart == Enum.BodyPart.RightLeg) then
                pcall(function()
                    _payrV:Destroy()
                end)
            end
        end
        if _zNIqW then
            local _UR3GY = _zNIqW:FindFirstChild("KittyKorbloxSM")
            if _UR3GY then
                pcall(function()
                    _UR3GY:Destroy()
                end)
            end
            _zNIqW.Transparency = 0
        end
        if _WwRku then
            pcall(function()
                local _Pg_L4 = _WwRku:GetAppliedDescription()
                if _Pg_L4 then
                    _Pg_L4.RightLeg = 0
                    _WwRku:ApplyDescription(_Pg_L4)
                end
            end)
        end
    end
end
local _ur1pw = {
    exists = false,
    Density = 0.3,
    Offset = 0,
    Color = Color3.fromRGB(199, 170, 107),
    Decay = Color3.fromRGB(92, 60, 13),
    Glare = 0,
    Haze = 0
}
local MotionBlur = {blur = nil, conn = nil, lastCFrame = nil, currentBlur = 0}
MotionBlur.getBlur = function()
    if MotionBlur.blur and MotionBlur.blur.Parent then
        return MotionBlur.blur
    end
    local _oYy6S = Lighting:FindFirstChild("KittyMotionBlur")
    if not _oYy6S or not _oYy6S:IsA("BlurEffect") then
        _oYy6S = Instance.new("BlurEffect")
        _oYy6S.Name = "KittyMotionBlur"
    end
    _oYy6S.Size = 0
    _oYy6S.Parent = Lighting
    MotionBlur.blur = _oYy6S
    return _oYy6S
end
MotionBlur.step = function(_PwdCh)
    local _uIuIE = workspace.CurrentCamera
    if not _uIuIE then
        return
    end
    local _xPd4k = _uIuIE.CFrame
    if not MotionBlur.lastCFrame then
        MotionBlur.lastCFrame = _xPd4k
        return
    end
    local _csYCH = MotionBlur.lastCFrame
    local _D3QP_ = math.clamp(_csYCH.LookVector:Dot(_xPd4k.LookVector), -1, 1)
    local _OB36N = math.acos(_D3QP_)
    local _xz4i7 = _PwdCh > 0 and (_OB36N / _PwdCh) or 0
    local _cny6G = (_xPd4k.Position - _csYCH.Position).Magnitude
    local _XtHra = _PwdCh > 0 and (_cny6G / _PwdCh) or 0
    local _CisN0 = (Config.Visuals.MotionBlur and Config.Visuals.MotionBlur.Intensity) or 10
    local _liq5P = math.clamp(_CisN0, 1, 30)
    local _QFgvu = _xz4i7 * 1.5 * (_CisN0 / 10)
    local _XcSkn = math.max(0, (_XtHra - 20) * 0.04)
    local _C23ux = math.clamp(_QFgvu + _XcSkn, 0, _liq5P)
    local _lXqWY = math.clamp(_PwdCh * 15, 0, 1)
    MotionBlur.currentBlur = MotionBlur.currentBlur + (_C23ux - MotionBlur.currentBlur) * _lXqWY
    if MotionBlur.currentBlur < 0.05 then
        MotionBlur.currentBlur = 0
    end
    local _kypWA = MotionBlur.getBlur()
    _kypWA.Size = MotionBlur.currentBlur
    MotionBlur.lastCFrame = _xPd4k
end
MotionBlur.set = function(_LHoJo)
    _vA5WJ(MotionBlur.conn)
    MotionBlur.conn = nil
    MotionBlur.lastCFrame = nil
    MotionBlur.currentBlur = 0
    if _LHoJo then
        local _GkyaU = MotionBlur.getBlur()
        _GkyaU.Size = 0
        MotionBlur.conn = connectSignal(RunService.RenderStepped, MotionBlur.step)
    else
        if MotionBlur.blur then
            pcall(function()
                MotionBlur.blur:Destroy()
            end)
            MotionBlur.blur = nil
        end
        local _s3IEw = Lighting:FindFirstChild("KittyMotionBlur")
        if _s3IEw then
            pcall(function()
                _s3IEw:Destroy()
            end)
        end
    end
end
local function _L3aVK(_mDk7i)
    local _llFKk = Lighting:FindFirstChildOfClass("Atmosphere")
    if _mDk7i then
        if not _llFKk then
            _llFKk = Instance.new("Atmosphere")
            _llFKk.Name = "KittyAtmosphere"
            _llFKk.Parent = Lighting
        elseif not _ur1pw.exists then
            _ur1pw.exists = true
            _ur1pw.Density = _llFKk.Density
            _ur1pw.Offset = _llFKk.Offset
            _ur1pw.Color = _llFKk.Color
            _ur1pw.Decay = _llFKk.Decay
            _ur1pw.Glare = _llFKk.Glare
            _ur1pw.Haze = _llFKk.Haze
        end
        _llFKk.Density = Config.Visuals.Atmosphere.Density
        _llFKk.Color = Config.Visuals.Atmosphere.Color
        _llFKk.Decay = Config.Visuals.Atmosphere.Decay
        _llFKk.Glare = Config.Visuals.Atmosphere.Glare
        _llFKk.Haze = Config.Visuals.Atmosphere.Haze
    else
        if _llFKk then
            if _ur1pw.exists then
                _llFKk.Density = _ur1pw.Density
                _llFKk.Offset = _ur1pw.Offset
                _llFKk.Color = _ur1pw.Color
                _llFKk.Decay = _ur1pw.Decay
                _llFKk.Glare = _ur1pw.Glare
                _llFKk.Haze = _ur1pw.Haze
            elseif _llFKk.Name == "KittyAtmosphere" then
                pcall(function()
                    _llFKk:Destroy()
                end)
            end
        end
    end
end
local SkyManager = {
    touched = {},
    created = {}
}
SkyManager.presets = {
    ["Clear Day"] = {
        clock = 13,
        bright = 3,
        amb = Color3.fromRGB(110, 110, 110),
        out = Color3.fromRGB(128, 128, 128),
        atmos = {
            0.25,
            Color3.fromRGB(199, 199, 199),
            Color3.fromRGB(106, 112, 125),
            0,
            0
        },
        stars = 3000
    },
    Sunrise = {
        clock = 6.4,
        bright = 2,
        amb = Color3.fromRGB(110, 90, 80),
        out = Color3.fromRGB(150, 120, 100),
        atmos = {
            0.35,
            Color3.fromRGB(255, 190, 150),
            Color3.fromRGB(255, 130, 90),
            0.4,
            1.2
        },
        stars = 1000,
        tint = Color3.fromRGB(255, 245, 235)
    },
    Sunset = {
        clock = 17.8,
        bright = 2,
        amb = Color3.fromRGB(120, 85, 70),
        out = Color3.fromRGB(160, 110, 90),
        atmos = {
            0.35,
            Color3.fromRGB(255, 170, 120),
            Color3.fromRGB(200, 90, 60),
            0.6,
            1.6
        },
        stars = 1000,
        tint = Color3.fromRGB(255, 240, 225)
    },
    Night = {
        clock = 0,
        bright = 1,
        amb = Color3.fromRGB(40, 45, 70),
        out = Color3.fromRGB(60, 65, 100),
        atmos = {
            0.25,
            Color3.fromRGB(70, 80, 130),
            Color3.fromRGB(20, 25, 50),
            0,
            0.5
        },
        stars = 5000
    },
    ["Purple Night"] = {
        clock = 23,
        bright = 1,
        amb = Color3.fromRGB(70, 50, 110),
        out = Color3.fromRGB(100, 70, 150),
        atmos = {
            0.3,
            Color3.fromRGB(150, 110, 255),
            Color3.fromRGB(60, 30, 120),
            0.3,
            0.8
        },
        stars = 4000,
        tint = Color3.fromRGB(240, 225, 255)
    },
    ["Blood Moon"] = {
        clock = 0.5,
        bright = 1,
        amb = Color3.fromRGB(90, 30, 30),
        out = Color3.fromRGB(130, 40, 40),
        atmos = {
            0.35,
            Color3.fromRGB(180, 40, 40),
            Color3.fromRGB(90, 10, 10),
            0.2,
            1
        },
        stars = 1500,
        tint = Color3.fromRGB(255, 200, 200)
    },
    Aurora = {
        clock = 22,
        bright = 1.2,
        amb = Color3.fromRGB(40, 80, 80),
        out = Color3.fromRGB(60, 120, 110),
        atmos = {
            0.3,
            Color3.fromRGB(90, 255, 200),
            Color3.fromRGB(40, 90, 160),
            0.4,
            0.8
        },
        stars = 5000,
        tint = Color3.fromRGB(225, 255, 245)
    },
    Foggy = {
        clock = 9,
        bright = 1.5,
        amb = Color3.fromRGB(120, 120, 125),
        out = Color3.fromRGB(140, 140, 145),
        atmos = {
            0.6,
            Color3.fromRGB(200, 200, 205),
            Color3.fromRGB(160, 160, 170),
            0,
            3
        },
        stars = 0
    }
}
SkyManager.order = {
    "Clear Day",
    "Sunrise",
    "Sunset",
    "Night",
    "Purple Night",
    "Blood Moon",
    "Aurora",
    "Foggy",
    "Custom Skybox"
}
SkyManager.locking = false
SkyManager.set = function(_XqtNO, _Swcu8, _l5Lqk)
    if not _XqtNO then
        return
    end
    local _EsoH2 = SkyManager.touched[_XqtNO]
    if not _EsoH2 then
        _EsoH2 = {}
        SkyManager.touched[_XqtNO] = _EsoH2
    end
    if _EsoH2[_Swcu8] == nil then
        pcall(function()
            _EsoH2[_Swcu8] = _XqtNO[_Swcu8]
        end)
    end
    pcall(function()
        _XqtNO[_Swcu8] = _l5Lqk
    end)
end
SkyManager.restore = function()
    for _XH2_t, _enyA4 in pairs(SkyManager.touched) do
        for _xzlr7, _QAqUU in pairs(_enyA4) do
            pcall(function()
                _XH2_t[_xzlr7] = _QAqUU
            end)
        end
    end
    table.clear(SkyManager.touched)
    for _DAwv3, _e71S9 in ipairs(SkyManager.created) do
        pcall(function()
            _e71S9:Destroy()
        end)
    end
    table.clear(SkyManager.created)
end
SkyManager.child = function(_xiUK7, _wtMka)
    local _P6Wmd = Lighting:FindFirstChild(_wtMka) or Lighting:FindFirstChildOfClass(_xiUK7)
    if not _P6Wmd then
        _P6Wmd = Instance.new(_xiUK7)
        _P6Wmd.Name = _wtMka
        _P6Wmd.Parent = Lighting
        table.insert(SkyManager.created, _P6Wmd)
    end
    return _P6Wmd
end
SkyManager.apply = function(_qBWv4)
    if not _qBWv4 then
        SkyManager.restore()
    end
    local _dpk6v = Config.Visuals.Sky
    if not _dpk6v.Enabled then
        return
    end
    local _wKtC5 = SkyManager.child("Sky", "KittySky")
    SkyManager.set(_wKtC5, "StarCount", _dpk6v.Stars)
    SkyManager.set(_wKtC5, "CelestialBodiesShown", true)
    local _PmMg3 = SkyManager.presets[_dpk6v.Preset]
    if _PmMg3 then
        SkyManager.set(Lighting, "ClockTime", _PmMg3.clock)
        SkyManager.set(Lighting, "Brightness", _PmMg3.bright)
        SkyManager.set(Lighting, "Ambient", _PmMg3.amb)
        SkyManager.set(Lighting, "OutdoorAmbient", _PmMg3.out)
        local _WG0jYGC_ = SkyManager.child("Atmosphere", "KittySkyAtmosphere")
        SkyManager.set(_WG0jYGC_, "Density", _PmMg3.atmos[1])
        SkyManager.set(_WG0jYGC_, "Color", _PmMg3.atmos[2])
        SkyManager.set(_WG0jYGC_, "Decay", _PmMg3.atmos[3])
        SkyManager.set(_WG0jYGC_, "Glare", _PmMg3.atmos[4])
        SkyManager.set(_WG0jYGC_, "Haze", _PmMg3.atmos[5])
        if not _uMouq or not _uMouq.Parent then
            _uMouq = Lighting:FindFirstChild("ColorCorrection") or Instance.new("ColorCorrectionEffect", Lighting)
        end
        SkyManager.set(_uMouq, "TintColor", _PmMg3.tint or Color3.new(1, 1, 1))
    elseif _dpk6v.Preset == "Custom Skybox" then
        local _prUL0 = tostring(_dpk6v.SkyboxId):match("%d+")
        if _prUL0 then
            for _IdOVnO, _btwedRR in ipairs({
                "SkyboxBk",
                "SkyboxDn",
                "SkyboxFt",
                "SkyboxLf",
                "SkyboxRt",
                "SkyboxUp"
            }) do
                SkyManager.set(_wKtC5, _btwedRR, "rbxassetid://" .. _prUL0)
            end
        end
    end
end
local _WpfDds2D = {}
_WpfDds2D.part = function(_pIlr_)
    local _suUadl = Config.AutoTech.TargetPart
    local _tA1yg8R = _pIlr_ and _pIlr_.Parent
    if _tA1yg8R and (_suUadl == "Head" or _suUadl == "Torso") then
        local _SrHidRlg = _tA1yg8R:FindFirstChild(_suUadl) or (_suUadl == "Torso" and _tA1yg8R:FindFirstChild("UpperTorso"))
        if _SrHidRlg then
            return _SrHidRlg
        end
    end
    return _pIlr_
end
_WpfDds2D.pos = function(_zcygD)
    local _H3u0O = _WpfDds2D.part(_zcygD)
    return _H3u0O and _H3u0O.Position or Vector3.zero
end
local function _ulpybJ(_ZCc4leT, _Q3OwZ, _DLDcJ, _aH8Po, _l8MHn)
    local _YFRRM
    _YFRRM = RunService[_ZCc4leT]:Connect(function()
        if not _DLDcJ or _DLDcJ:FindFirstChild("BeingLaunched") or not _DLDcJ:FindFirstChild("Ragdoll") or _aH8Po.Health <= 0 or not Humanoid or Humanoid.Health <= 0 or not _xFaaK(_j089A.frontDash) then
            _mzv8k = false
            _vA5WJ(_YFRRM)
            return
        end
        _l8MHn()
    end)
    task.wait(_Q3OwZ)
    _vA5WJ(_YFRRM)
    _mzv8k = false
end
local function _vAazx(_ijYak)
    _mzv8k = true
    _XjK2G()
    task.wait(getPing(1000) + 0.05 + (_ijYak or 0))
end
local function _hwqr3(_EgR4S, _rZ2nA, _uw8yF, _ZlTUv)
    local _M55OE
    _vAazx()
    State.techRotate(90, nil, true)
    _pN7KD(270, 0.3, true)
    task.wait(0.3)
    _ulpybJ("Heartbeat", 0.4, _EgR4S, _uw8yF, function()
        if _ZlTUv then
            local _D_EDy = (_rZ2nA.CFrame.RightVector * (math.random() > 0.5 and 7 or -7))
            State.techRotate(nil, _WpfDds2D.pos(_rZ2nA) + _D_EDy, true)
        elseif _M55OE or _yNOi1(_WpfDds2D.part(_rZ2nA)) then
            if not _M55OE then
                if Config.AutoTech.LoopDashLooksUp then
                    _M55OE = CFrame.lookAt(RootPart.Position, Vector3.new(RootPart.Position.X + 1.5, RootPart.Position.Y + 1.5, RootPart.Position.Z))
                else
                    _M55OE = RootPart.CFrame
                end
            end
            Character:PivotTo(_M55OE)
        else
            State.techRotate(nil, _WpfDds2D.pos(_rZ2nA), true)
        end
    end)
end
local function _qpoME(_VBJJ9, _YfQ8U, _Lw3JZ, _iBZPy)
    if not (RootPart and Humanoid) then
        return
    end
    local _hkJ5P = {nil, false, Config.AutoTech.Customdash.RotateCam}
    local _UQKak = _WpfDds2D.pos(_YfQ8U)
    if _iBZPy then
        _UQKak = _UQKak + (_YfQ8U.CFrame.RightVector * (math.random() > 0.5 and 8 or -8))
    end
    local _r4idu = {nil, _UQKak, false, _hkJ5P[3], Config.AutoTech.Customdash.LockOnPrecision}
    local function _ezZjK()
        State.techRotate(unpack(_r4idu))
    end
    if Config.AutoTech.Customdash.Jump then
        RootPart.AssemblyLinearVelocity = Vector3.new(RootPart.AssemblyLinearVelocity.X, 50, RootPart.AssemblyLinearVelocity.Z)
    end
    _mzv8k = true
    State.techRotate(Config.AutoTech.Customdash.StartFlickAngle, unpack(_hkJ5P))
    _vAazx(Config.AutoTech.Customdash.SecondFlickDelay)
    State.techRotate(Config.AutoTech.Customdash.SecondFlickAngle, unpack(_hkJ5P))
    if Config.AutoTech.Customdash.LockOn and Config.AutoTech.Customdash.LockOnAfter == "Second Flick" then
        task.wait(Config.AutoTech.Customdash.LockOnDelay)
        _ulpybJ("Heartbeat", 0.4, _VBJJ9, _Lw3JZ, _ezZjK)
    else
        task.wait(Config.AutoTech.Customdash.ThirdFlickDelay)
        State.techRotate(Config.AutoTech.Customdash.ThirdFlickAngle, unpack(_hkJ5P))
        if Config.AutoTech.Customdash.LockOn and Config.AutoTech.Customdash.LockOnAfter == "Third Flick" then
            task.wait(Config.AutoTech.Customdash.LockOnDelay)
            _ulpybJ("Heartbeat", 0.4, _VBJJ9, _Lw3JZ, _ezZjK)
        end
    end
    _mzv8k = false
    State.freeRotate()
end
local function _HXyed(_kd_Sf, _xinWO, _GZ1a7, _b7Suz)
    if not (RootPart and Humanoid) then
        return
    end
    local _oqVmt = _WpfDds2D.pos(_xinWO)
    if _b7Suz then
        _oqVmt = _oqVmt + (_xinWO.CFrame.RightVector * (math.random() > 0.5 and 8 or -8))
    end
    local _mBh_7 = {nil, _oqVmt, false, Config.AutoTech.Customdashv2.RotateCam, Config.AutoTech.Customdashv2.LockOnPrecision}
    local function _xE61o()
        State.techRotate(unpack(_mBh_7))
    end
    if Config.AutoTech.Customdashv2.Jump then
        RootPart.AssemblyLinearVelocity = Vector3.new(RootPart.AssemblyLinearVelocity.X, 50, RootPart.AssemblyLinearVelocity.Z)
    end
    _mzv8k = true
    State.techRotate(Config.AutoTech.Customdashv2.StartFlickAngle, nil, true, Config.AutoTech.Customdashv2.RotateCam)
    _vAazx(Config.AutoTech.Customdashv2.SecondFlickDelay)
    _pN7KD(Config.AutoTech.Customdashv2.SecondFlickAngle, Config.AutoTech.Customdashv2.SecondFlickDuration, not Config.AutoTech.Customdashv2.RotateCam)
    if Config.AutoTech.Customdashv2.LockOn and Config.AutoTech.Customdashv2.LockOnAfter == "Second Flick" then
        task.wait(Config.AutoTech.Customdashv2.LockOnDelay)
        _ulpybJ("Heartbeat", 0.4, _kd_Sf, _GZ1a7, _xE61o)
    else
        task.wait(Config.AutoTech.Customdashv2.ThirdFlickDelay)
        _pN7KD(Config.AutoTech.Customdashv2.ThirdFlickAngle, Config.AutoTech.Customdashv2.ThirdFlickDuration, not Config.AutoTech.Customdashv2.RotateCam)
        if Config.AutoTech.Customdashv2.LockOn and Config.AutoTech.Customdashv2.LockOnAfter == "Third Flick" then
            task.wait(Config.AutoTech.Customdashv2.LockOnDelay)
            _ulpybJ("Heartbeat", 0.4, _kd_Sf, _GZ1a7, _xE61o)
        end
    end
    if not Unloaded then
        _mzv8k = false
        State.freeRotate()
    end
end
local function _U_fen(_bvQMW, _q46lU, _R3eS1, _Ia0J6)
    if Config.AutoTech.Loopv2.Jump then
        RootPart.AssemblyLinearVelocity = Vector3.new(RootPart.AssemblyLinearVelocity.X, 50, RootPart.AssemblyLinearVelocity.Z)
    end
    _mzv8k = true
    State.techRotate(Config.AutoTech.Loopv2.FirstFlickAngle, nil, true, Config.AutoTech.Loopv2.RotateCam)
    _vAazx(Config.AutoTech.Loopv2.SecondFlick)
    _ulpybJ("Heartbeat", 0.4, _bvQMW, _R3eS1, function()
        local _TTP74 = _WpfDds2D.pos(_q46lU)
        if _Ia0J6 then
            _TTP74 = _TTP74 + (_q46lU.CFrame.RightVector * (math.random() > 0.5 and 8 or -8))
        end
        State.techRotate(nil, _TTP74, true, Config.AutoTech.Loopv2.RotateCam, nil, Config.AutoTech.Loopv2.Precision)
    end)
    _mzv8k = false
    State.freeRotate()
end
local function _ywPqv(_JqqbM, _MI4Qi, _nhPx3, _C4L9T)
    _vAazx()
    _ulpybJ("Heartbeat", 0.7, _JqqbM, _nhPx3, function()
        local _xccyh = _WpfDds2D.pos(_MI4Qi)
        if _C4L9T then
            _xccyh = _xccyh + (_MI4Qi.CFrame.RightVector * (math.random() > 0.5 and 8 or -8))
        end
        State.techRotate(nil, _xccyh, true, false, Config.AutoTech.LockonPrecision)
    end)
end
local function _UXktE(_fFkGm, _qXVklc, _BBlLc, _Ysjrtm4e)
    _vAazx()
    _ulpybJ("Heartbeat", 0.4, _fFkGm, _BBlLc, function()
        local _TSqan2N = _WpfDds2D.pos(_qXVklc)
        local _ijM4VXTw
        if _Ysjrtm4e then
            _ijM4VXTw = _TSqan2N + (_qXVklc.CFrame.RightVector * (math.random() > 0.5 and 7 or -7)) - Vector3.new(0, 3, 2)
        else
            _ijM4VXTw = _TSqan2N - Vector3.new(0, 3, 2)
        end
        local _Jqs3Z = CFrame.new(_ijM4VXTw, _TSqan2N)
        Character:PivotTo(_Jqs3Z)
    end)
end
local function _M6A_1r0Z(_dghr31A, _yGKzvt, _nPjQk, _wJtcAH)
    _vAazx()
    local _V6F0ttU = _yGKzvt.CFrame:PointToObjectSpace(RootPart.Position)
    _ulpybJ(Config.AutoTech.SupaMethod, 0.3, _dghr31A, _nPjQk, function()
        local _Gjjw242g = _WpfDds2D.pos(_yGKzvt)
        local _zjlcE = _yGKzvt.CFrame:PointToWorldSpace(_V6F0ttU)
        if _wJtcAH then
            _zjlcE = _zjlcE + (_yGKzvt.CFrame.RightVector * (math.random() > 0.5 and 7 or -7))
        end
        Character:PivotTo(CFrame.lookAt(_zjlcE, Vector3.new(_Gjjw242g.X, _zjlcE.Y + 1.5, _Gjjw242g.Z), Vector3.new(0, 1, 0)))
    end)
end
local LethalState = {busy = false, armedUntil = 0, highlight = nil}
LethalState.getTarget = function(_RL2_W)
    local _VT49w, _Inde5 = nil, _RL2_W
    for _j9H9P, _aQifz in ipairs(World.Live:GetChildren()) do
        if _aQifz ~= Character and _aQifz:IsA("Model") and not _JrRW2(Players:GetPlayerFromCharacter(_aQifz), true) then
            local _RdJuE = _aQifz:FindFirstChild("HumanoidRootPart")
            local _oX8aD = _aQifz:FindFirstChildOfClass("Humanoid")
            if _RdJuE and _oX8aD and _oX8aD.Health > 0 then
                local _vWYUX = (_RdJuE.Position - RootPart.Position).Magnitude
                if _vWYUX < _Inde5 then
                    _VT49w, _Inde5 = _aQifz, _vWYUX
                end
            end
        end
    end
    return _VT49w
end
LethalState.setHighlight = function(_ibJXz)
    if LethalState.highlight then
        LethalState.highlight:Destroy()
        LethalState.highlight = nil
    end
    if not (_ibJXz and Config.AutoLethal.Highlight) then
        return
    end
    local _J7mp6 = Instance.new("Highlight")
    _J7mp6.Name = "KWLethalTarget"
    _J7mp6.FillColor = Config.AutoLethal.HighlightColor
    _J7mp6.OutlineColor = Config.AutoLethal.HighlightColor
    _J7mp6.FillTransparency = 0.5
    _J7mp6.OutlineTransparency = 0
    _J7mp6.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    _J7mp6.Adornee = _ibJXz
    _J7mp6.Parent = _ibJXz
    LethalState.highlight = _J7mp6
end
local function _wNqfv(_rS77O)
    if not _rS77O then
        return
    end
    local _ONC9Q = _rS77O.AssemblyLinearVelocity
    _rS77O.AssemblyLinearVelocity = Vector3.new(_ONC9Q.X, 50, _ONC9Q.Z)
end
LethalState.jump = function()
    local _FUndW = RootPart
    if not _FUndW then
        return
    end
    _wNqfv(_FUndW)
    local _IxbzG = 0
    local _jP5Av
    _jP5Av = RunService.Heartbeat:Connect(function()
        _IxbzG = _IxbzG + 1
        if _IxbzG > 3 or not _FUndW.Parent then
            _jP5Av:Disconnect()
            return
        end
        if _FUndW.AssemblyLinearVelocity.Y < 35 then
            _wNqfv(_FUndW)
        end
    end)
end
LethalState.run = function(_WrWCM, _RHCrj, _EYp3y)
    local _f6ySU = Config.AutoLethal
    local _isEcy = _WrWCM:FindFirstChild("HumanoidRootPart")
    local _Xb4I8 = _WrWCM:FindFirstChildOfClass("Humanoid")
    if not (_isEcy and _Xb4I8) then
        return
    end
    LethalState.setHighlight(_WrWCM)
    local _AvwdD = tick()
    if _EYp3y then
        local _F7i6M = math.min(_f6ySU.GraveTiming, 0)
        repeat
            RunService.Heartbeat:Wait()
        until not _EYp3y.IsPlaying or (_EYp3y.Length > 0 and _EYp3y.TimePosition >= _EYp3y.Length + _F7i6M) or tick() - _AvwdD >= 3
        if _f6ySU.GraveTiming > 0 then
            task.wait(_f6ySU.GraveTiming)
        end
    else
        repeat
            RunService.Heartbeat:Wait()
        until not (Character and Character:FindFirstChildOfClass("ForceField")) or tick() - _AvwdD >= 2.5
        task.wait(0.1)
    end
    if not Humanoid or Humanoid.Health <= 0 or _Xb4I8.Health <= 0 then
        return
    end
    if _f6ySU.Jump then
        LethalState.jump()
    end
    _mzv8k = true
    State.techRotate(_f6ySU.FirstFlickAngle, nil, true, _f6ySU.RotateCam)
    local _S2VSW = _tew4S()
    if _S2VSW then
        _S2VSW:FireServer(_Ws0Y9.frontDash)
    end
    State.frontDashAt = tick()
    _ecSEyI = true
    task.delay(5, function()
        _ecSEyI = false
    end)
    task.wait(getPing(1000) + 0.05 + _f6ySU.SecondFlick)
    local _rtVk4 = tick()
    local _EKbuK
    _EKbuK = RunService.Heartbeat:Connect(function()
        local _x0LUh = tick() - _rtVk4
        if _x0LUh > 0.4 or (_x0LUh > 0.2 and not _xFaaK(_j089A.frontDash)) or not _isEcy.Parent or _Xb4I8.Health <= 0 or Humanoid.Health <= 0 then
            _EKbuK:Disconnect()
            return
        end
        if _RHCrj then
            local _aSpa5 = (_isEcy.CFrame.RightVector * (math.random() > 0.5 and 8 or -8))
            State.techRotate(nil, _WpfDds2D.pos(_isEcy) + _aSpa5, true, _f6ySU.RotateCam, _f6ySU.Precision)
        else
            State.techRotate(nil, _WpfDds2D.pos(_isEcy), true, _f6ySU.RotateCam, _f6ySU.Precision)
        end
    end)
    task.wait(0.4)
    if _EKbuK.Connected then
        _EKbuK:Disconnect()
    end
end
LethalState.trigger = function(_jQ5QH, _sG1wu)
    if LethalState.busy then
        return
    end
    local _RPNkj = Config.AutoLethal
    local _e6AGz = false
    if _RPNkj.MissChance and _RPNkj.MissChance > 0 and math.random(1, 100) <= _RPNkj.MissChance then
        _e6AGz = true
    end
    LethalState.busy = true
    local _YSidA, _jafmP = pcall(LethalState.run, _jQ5QH, _e6AGz, _sG1wu)
    if not _YSidA then
        warn("[ZRHUB] Auto Lethal error: " .. tostring(_jafmP))
    end
    _mzv8k = false
    State.freeRotate()
    LethalState.setHighlight(nil)
    task.wait(0.3)
    LethalState.busy = false
end
LethalState.onAnim = function(_KvpjG)
    if Unloaded then
        return
    end
    local _Ra5fU = Config.AutoLethal
    local _c5asy = _KvpjG.Animation and _KvpjG.Animation.AnimationId:match("%d+")
    local _DBY3i = _c5asy == _Ra5fU.GraveAnim
    if not (_c5asy == _Ra5fU.HitAnim or (_DBY3i and _Ra5fU.Grave)) or LethalState.busy then
        return
    end
    if not (_Ra5fU.Enabled or tick() < LethalState.armedUntil) then
        return
    end
    LethalState.armedUntil = 0
    local _yIO6a = LethalState.getTarget(20)
    if _yIO6a then
        task.spawn(LethalState.trigger, _yIO6a, _DBY3i and _KvpjG or nil)
    end
end
LethalState.elapsed = function()
    if not _zE8Ni then
        return nil
    end
    for _JPFZq, _kfMko in ipairs(_zE8Ni:GetPlayingAnimationTracks()) do
        local _vX0pQ = _kfMko.Animation and _kfMko.Animation.AnimationId:match("%d+")
        if _vX0pQ == Config.AutoLethal.HitAnim then
            return _kfMko.TimePosition
        end
    end
    return nil
end
LethalState.fire = function()
    LethalState.armedUntil = tick() + 3
    local _C7KmU = Character and Character:GetAttribute("Character") == "Zombie"
    setAutoRotate(_C7KmU and Enum.KeyCode.One or Enum.KeyCode.Two)
end
local _dXK4f = {}
_dXK4f.set = function(_oP95qX7E)
    local _jzGzHNO = Character and Character:FindFirstChild("Head")
    if not _jzGzHNO then
        return
    end
    if _jzGzHNO.Transparency ~= _oP95qX7E then
        _IeaiYt2E(_jzGzHNO, "Transparency", _oP95qX7E)
    end
    local _KUomvn = _jzGzHNO:FindFirstChild("face")
    if _KUomvn and _KUomvn.Transparency ~= _oP95qX7E then
        _IeaiYt2E(_KUomvn, "Transparency", _oP95qX7E)
    end
end
_dXK4f.start = function()
    if _wZKifJPa.headless then
        return
    end
    _wZKifJPa.headless = connectSignal(RunService.RenderStepped, function()
        _dXK4f.set(1)
    end)
end
_dXK4f.stop = function()
    if _wZKifJPa.headless then
        _vA5WJ(_wZKifJPa.headless)
        _wZKifJPa.headless = nil
    end
end
local _ViZxv
local function _cNwEk3oQ(_nZNHzTz, _m3g8as, _r7IKc, _gqaLSXNz)
    if not (_nZNHzTz and _nZNHzTz:IsA("Model") and _nZNHzTz ~= Character and _nZNHzTz.Parent) then
        return _r7IKc, _gqaLSXNz
    end
    local _FOk6nm_ = _nZNHzTz:FindFirstChild("HumanoidRootPart")
    local _yQoVr3 = _nZNHzTz:FindFirstChildOfClass("Humanoid")
    if not (_FOk6nm_ and _yQoVr3 and _yQoVr3.Health > 0) then
        return _r7IKc, _gqaLSXNz
    end
    local _nHuXh = Players:GetPlayerFromCharacter(_nZNHzTz)
    if _nHuXh and Config.Misc.FriendCheck and _JrRW2(_nHuXh, false) then
        return _r7IKc, _gqaLSXNz
    end
    local _MZuG3 = (_m3g8as - _FOk6nm_.Position).Magnitude
    if _MZuG3 < _gqaLSXNz then
        return _nZNHzTz, _MZuG3
    end
    return _r7IKc, _gqaLSXNz
end
local function _B58iB(_GaoB5)
    _GaoB5 = _GaoB5 or 16
    if not (Character and RootPart) then
        return nil
    end
    local _fwXR5 = RootPart.Position
    local _UCzKw = Character:GetAttribute("LastM1Hitted")
    local _NSZMp = type(_UCzKw) == "string" and _UCzKw:match("^(.-);;")
    local _mPuo1 = nil
    local _bVOE_ = _GaoB5
    local _bbTCA = {World.Live, workspace, World.Map}
    for _G18fC, _BEt1Q in ipairs(workspace:GetChildren()) do
        if (_BEt1Q:IsA("Folder") or _BEt1Q:IsA("Model")) and _BEt1Q ~= Character and _BEt1Q ~= World.Live and _BEt1Q ~= World.Map then
            local _kikKg = _BEt1Q.Name:lower()
            if _kikKg:find("dummy") or _kikKg:find("npc") or _kikKg:find("bot") or _kikKg:find("live") or _kikKg:find("character") then
                table.insert(_bbTCA, _BEt1Q)
            end
        end
    end
    if _NSZMp then
        for _PFujJ, _K2QaX in ipairs(_bbTCA) do
            if _K2QaX then
                for _Fo_fd, _kL0Fy in ipairs(_K2QaX:GetChildren()) do
                    if _kL0Fy.Name == _NSZMp then
                        _mPuo1, _bVOE_ = _cNwEk3oQ(_kL0Fy, _fwXR5, _mPuo1, _bVOE_)
                    end
                end
            end
        end
        if _mPuo1 then
            return _mPuo1
        end
    end
    for _f8Lwt, _KipWT in ipairs(_bbTCA) do
        if _KipWT then
            for _tUAAE, _ogeTU in ipairs(_KipWT:GetChildren()) do
                _mPuo1, _bVOE_ = _cNwEk3oQ(_ogeTU, _fwXR5, _mPuo1, _bVOE_)
            end
        end
    end
    for _TPf7n, _OnAot in ipairs(Players:GetPlayers()) do
        if _OnAot ~= LocalPlayer and _OnAot.Character then
            _mPuo1, _bVOE_ = _cNwEk3oQ(_OnAot.Character, _fwXR5, _mPuo1, _bVOE_)
        end
    end
    return _mPuo1
end
local function onCharacterRemoving()
    if _LZYNd then
        pcall(_LZYNd)
    end
    State.blockState.active = false
    State.blockState.untilT = 0
    State.blockState.session = nil
    State.barrageActive = false
    if State.Freeze then
        pcall(State.Freeze.release)
    end
    if State.Scope then
        pcall(State.Scope.stop)
    end
    _FPbWqU0 = false
    _mzv8k = false
    _ecSEyI = false
    _KjGi0a.stop()
    table.clear(_vjMDS)
    _ucV8j(false)
    if _cmUMF.highlight then
        pcall(function()
            _cmUMF.highlight:Destroy()
        end)
        _cmUMF.highlight = nil
    end
    if _cmUMF.headMask then
        pcall(function()
            _cmUMF.headMask:Destroy()
        end)
        _cmUMF.headMask = nil
    end
    table.clear(_cmUMF.mats)
    if LethalState and LethalState.setHighlight then
        LethalState.setHighlight(nil)
        LethalState.busy = false
    end
    if Config.Visuals.Sky.Enabled then
        task.spawn(function()
            SkyManager.apply(true)
            task.wait(0.25)
            if Config.Visuals.Sky.Enabled then
                SkyManager.apply(true)
            end
        end)
    end
    if Config.Visuals.Atmosphere.Enabled then
        task.spawn(function()
            _L3aVK(true)
            task.wait(0.25)
            if Config.Visuals.Atmosphere.Enabled then
                _L3aVK(true)
            end
        end)
    end
end
local function onCharacterAdded(_Zk2gb)
    if not _Zk2gb then
        return
    end
    Character = _Zk2gb
    _FPbWqU0 = false
    _mzv8k = false
    _ecSEyI = false
    _KjGi0a.stop()
    table.clear(_vjMDS)
    if Config.Zombie and Config.Zombie.CameraLockBypass then
        _ucV8j(true)
    end
    if _cmUMF.highlight then
        pcall(function()
            _cmUMF.highlight:Destroy()
        end)
        _cmUMF.highlight = nil
    end
    if _cmUMF.headMask then
        pcall(function()
            _cmUMF.headMask:Destroy()
        end)
        _cmUMF.headMask = nil
    end
    table.clear(_cmUMF.mats)
    Humanoid = _Zk2gb:WaitForChild("Humanoid", 3) or _Zk2gb:FindFirstChildOfClass("Humanoid")
    RootPart = _Zk2gb:WaitForChild("HumanoidRootPart", 3) or (Humanoid and Humanoid.RootPart)
    HeadPart = _Zk2gb:WaitForChild("Head", 3) or _Zk2gb:FindFirstChild("Head")
    _MJSFe = _Zk2gb:FindFirstChild("Communicate") or _Zk2gb:WaitForChild("Communicate", 1.5)
    if Humanoid then
        _zE8Ni = Humanoid:FindFirstChildOfClass("Animator") or Humanoid:WaitForChild("Animator", 1.5)
        if not _zE8Ni and Humanoid.Parent then
            pcall(function()
                _zE8Ni = Instance.new("Animator")
                _zE8Ni.Parent = Humanoid
            end)
        end
    end
    _N82Le = HeadPart and (HeadPart:FindFirstChild("face") or HeadPart:WaitForChild("face", 0.5))
    _YxtF_bco = CharacterNames[_Zk2gb:GetAttribute("Character")] or "Other"
    connectSignal(_Zk2gb:GetAttributeChangedSignal("Character"), function()
        _YxtF_bco = CharacterNames[_Zk2gb:GetAttribute("Character")] or "Other"
    end)
    pcall(function()
        _IeaiYt2E(workspace.CurrentCamera, "FieldOfView", Config.Visuals.FOV)
    end)
    _XXmEh = {HeadTransparency = HeadPart and HeadPart.Transparency or 0, FaceTransparency = _N82Le and _N82Le.Transparency or 0, AutoRotate = Humanoid and Humanoid.AutoRotate or true, JumpPower = Humanoid and Humanoid.JumpPower or 50}
    _ElMhN = nil
    pcall(function()
        if Humanoid then
            _ElMhN = Humanoid:GetAppliedDescription()
        end
    end)
    if _zE8Ni then
        connectSignal(_zE8Ni.AnimationPlayed, LethalState.onAnim)
        connectSignal(_zE8Ni.AnimationPlayed, function(_uH_IA)
            local _zSClb = _uH_IA.Animation
            if _zSClb and (_zSClb.AnimationId:find(_j089A.uppercut) or _zSClb.AnimationId:find(_j089A.euppercut)) then
                if not Config.AutoTech.Enabled then
                    return
                end
                if not (Character and RootPart and Humanoid and Humanoid.Health > 0) then
                    return
                end
                local _EeYgo = _B58iB(16)
                if not _EeYgo or _EeYgo == Character then
                    return
                end
                local _ZB_1X = Players:GetPlayerFromCharacter(_EeYgo)
                local _eYSE7 = _EeYgo:FindFirstChild("HumanoidRootPart")
                local _vRhJq = _EeYgo:FindFirstChildOfClass("Humanoid")
                if not _eYSE7 or not _vRhJq or _vRhJq.Health <= 0 then
                    return
                end
                if _ZB_1X and Config.Misc.FriendCheck and _JrRW2(_ZB_1X, false) then
                    return
                end
                local _QtSns = (_ZB_1X == nil) or (_EeYgo.Name:lower():find("dummy") ~= nil) or (_EeYgo.Name:lower():find("npc") ~= nil)
                local _V7wTG = _ZB_1X and _JrRW2(_ZB_1X, false)
                local _qWheU = _vRhJq.Health
                local _vzWfF = _eYSE7.Position.Y
                local _AcA1U = Character:GetAttribute("LastM1Hitted")
                local _VQZAy = (_YxtF_bco == "Metal Bat" or _YxtF_bco == "Batter") and 0.54 or 0.38
                task.wait(math.max(0.05, _VQZAy - getPing(1000)))
                if not (_EeYgo.Parent and _vRhJq.Health > 0 and _eYSE7.Parent and Humanoid and Humanoid.Health > 0 and RootPart) then
                    return
                end
                local _meAhg = false
                local _rSac4 = tick() + 0.22
                while tick() < _rSac4 and _EeYgo.Parent and _vRhJq.Health > 0 and _eYSE7.Parent do
                    local _MvkDk = (_EeYgo:GetAttribute("Blocking") == true) or (_EeYgo:FindFirstChild("Blocking") ~= nil) or (_EeYgo:FindFirstChild("Block") ~= nil) or (_EeYgo:FindFirstChild("BlockShield") ~= nil)
                    if _MvkDk and not _QtSns then
                        return
                    end
                    local _SVwyf = Character:GetAttribute("LastM1Hitted")
                    local _lJc6o = _vRhJq.Health < _qWheU
                    local _sE2np = (_eYSE7.AssemblyLinearVelocity.Y > 6) or (_eYSE7.Position.Y > _vzWfF + 0.6) or (_EeYgo:FindFirstChild("BeingLaunched") ~= nil) or (_EeYgo:GetAttribute("BeingLaunched") ~= nil) or (_EeYgo:FindFirstChild("Ragdoll") ~= nil) or (_EeYgo:GetAttribute("Ragdoll") ~= nil) or (_EeYgo:FindFirstChild("KnockedDown") ~= nil)
                    local _HI5FC = (_SVwyf ~= _AcA1U)
                    local _epkf_ = (_QtSns or (_V7wTG and not Config.Misc.FriendCheck)) and (RootPart.Position - _eYSE7.Position).Magnitude <= 12
                    if _lJc6o or _sE2np or _HI5FC or _epkf_ then
                        _meAhg = true
                        break
                    end
                    RunService.Heartbeat:Wait()
                end
                if not _meAhg and (_QtSns or (_V7wTG and not Config.Misc.FriendCheck)) then
                    local _hZzeE = (RootPart.Position - _eYSE7.Position).Magnitude
                    if _hZzeE <= 13 then
                        _meAhg = true
                    end
                end
                if not _meAhg then
                    return
                end
                local _oj56FM0w = (RootPart.Position - _eYSE7.Position).Magnitude
                if _oj56FM0w > 15 then
                    return
                end
                local _HnNltqc = false
                if Config.AutoTech.MissChance and Config.AutoTech.MissChance > 0 then
                    if math.random(1, 100) <= Config.AutoTech.MissChance then
                        _HnNltqc = true
                    end
                end
                if _Om_zX() and (Config.AutoTech.Method == "Perform Always" or (Config.AutoTech.Method == "Perform Once" and Config.AutoTech.PerformOnce)) then
                    local _OV29Qz = Config.AutoTech.Tech
                    if _OV29Qz ~= "" and Config.AutoTech.Method == "Perform Once" then
                        _xQp2C(_i3Z2l)
                        Config.AutoTech.PerformOnce = false
                    end
                    if _ViZxv and not _HnNltqc then
                        _ViZxv(_OV29Qz, _eYSE7)
                    end
                    local _hIWSw, _ACBZ15Q3 = pcall(function()
                        if _OV29Qz == "Supa" then
                            _M6A_1r0Z(_EeYgo, _eYSE7, _vRhJq, _HnNltqc)
                        elseif _OV29Qz == "Lock On Dash" then
                            _ywPqv(_EeYgo, _eYSE7, _vRhJq, _HnNltqc)
                        elseif _OV29Qz == "Loop Dash" then
                            _hwqr3(_EeYgo, _eYSE7, _vRhJq, _HnNltqc)
                        elseif _OV29Qz == "Kiba" then
                            _UXktE(_EeYgo, _eYSE7, _vRhJq, _HnNltqc)
                        elseif _OV29Qz == "Loop Dash v2" then
                            _U_fen(_EeYgo, _eYSE7, _vRhJq, _HnNltqc)
                        elseif _OV29Qz == "Custom Dash" then
                            _qpoME(_EeYgo, _eYSE7, _vRhJq, _HnNltqc)
                        elseif _OV29Qz == "Custom Dash v2" then
                            _HXyed(_EeYgo, _eYSE7, _vRhJq, _HnNltqc)
                        end
                    end)
                    if not _hIWSw then
                        warn("[ZRHUB] auto tech: " .. tostring(_ACBZ15Q3))
                        _mzv8k = false
                        State.freeRotate()
                    end
                end
            end
        end)
    end
    if Humanoid then
        connectSignal(Humanoid:GetPropertyChangedSignal("JumpPower"), function()
            if (Config.Rage.NoFatigue and not Character:FindFirstChild("NoJump") and _opUYh(Character, State.ignoreLocal)) or Config.Rage.AlwaysJump then
                _IeaiYt2E(Humanoid, "JumpPower", 50)
            end
        end)
        connectSignal(Humanoid:GetPropertyChangedSignal("AutoRotate"), function()
            if _mzv8k then
                Humanoid.AutoRotate = false
            end
        end)
        connectSignal(Humanoid.Died, onCharacterRemoving)
    end
    task.spawn(function()
        local _DCG1hsz, _aZCGze = pcall(_TQDHO)
        if not _DCG1hsz then
            warn("[ZRHUB] setupGui: " .. tostring(_aZCGze))
        end
    end)
    if Config.Visuals.Headless then
        _dXK4f.set(1)
        _dXK4f.start()
    end
    if State.CharCopy and State.CharCopy.userId and State.CharCopy.keep then
        task.spawn(State.CharCopy.reapply, _Zk2gb)
    end
    if Config.Visuals.Korblox then
        task.defer(function()
            _K0t9W(true)
        end)
    end
    if Config.Visuals.SelfChams.Enabled then
        task.spawn(function()
            _oQwzM()
            task.wait(0.2)
            if Config.Visuals.SelfChams.Enabled and Character == _Zk2gb then
                _oQwzM()
            end
            task.wait(0.5)
            if Config.Visuals.SelfChams.Enabled and Character == _Zk2gb then
                _oQwzM()
            end
        end)
    end
    connectSignal(_Zk2gb.DescendantAdded, function(_X1IU7)
        if Config.Visuals.SelfChams.Enabled and _X1IU7:IsA("BasePart") then
            task.defer(_oQwzM)
        end
    end)
    if Config.Rage.NoSideDashCooldown and Character then
        Character:SetAttribute("CustomSideDashCooldown", 0)
        _zk6rn(true)
    end
    if Config.Visuals.Sky.Enabled then
        task.spawn(function()
            SkyManager.apply(true)
            task.wait(0.3)
            if Config.Visuals.Sky.Enabled and Character == _Zk2gb then
                SkyManager.apply(true)
            end
        end)
    end
    if Config.Visuals.Atmosphere.Enabled then
        task.spawn(function()
            _L3aVK(true)
            task.wait(0.3)
            if Config.Visuals.Atmosphere.Enabled and Character == _Zk2gb then
                _L3aVK(true)
            end
        end)
    end
    if onDescendantAdded then
        connectSignal(_Zk2gb.DescendantAdded, onDescendantAdded)
        for _Q8tlbUaP, _xpLOYaB in ipairs(_Zk2gb:GetDescendants()) do
            onDescendantAdded(_xpLOYaB)
        end
    end
    if State.reapplyLook then
        task.spawn(State.reapplyLook, _Zk2gb)
    end
    if State.Scope then
        State.Scope.hook(_Zk2gb)
    end
end
local function _eh2Im8()
    local _LIRPH = LocalPlayer:FindFirstChild("Backpack")
    local _EEXaAvdE = Character or LocalPlayer.Character
    return (_LIRPH and (_LIRPH:FindFirstChild("Prey's Peril") or _LIRPH:FindFirstChild("Split Second Counter"))) or (_EEXaAvdE and (_EEXaAvdE:FindFirstChild("Prey's Peril") or _EEXaAvdE:FindFirstChild("Split Second Counter")))
end
_tew4S = function()
    if _MJSFe and _MJSFe.Parent then
        return _MJSFe
    end
    if Character then
        _MJSFe = Character:FindFirstChild("Communicate") or Character:WaitForChild("Communicate", 2)
    end
    return _MJSFe
end
local function _BzpgT(_e3LLl, _bivEl, _IUvE7)
    _IUvE7 = _IUvE7 or 0
    if not (_e3LLl and _bivEl and RootPart and Humanoid) then
        return
    end
    if _mzv8k or _bivEl.Health <= 0 or Humanoid.Health <= 0 then
        return
    end
    local _p12NO
    _p12NO = RunService.Heartbeat:Connect(function(_imVYf)
        if not (_e3LLl and _e3LLl.Parent and RootPart and RootPart.Parent and _bivEl.Health > 0 and Humanoid.Health > 0) then
            _vA5WJ(_p12NO)
        elseif _opUYh(RootPart.Parent, State.ignoreLocal) then
            Humanoid.AutoRotate = false
            local _PO5cu = RootPart.CFrame
            local _ICmbP = Vector3.new(_e3LLl.Position.X, _PO5cu.Position.Y, _e3LLl.Position.Z)
            local _FxMZj = CFrame.new(_PO5cu.Position, _ICmbP)
            if _IUvE7 <= 0 then
                RootPart.CFrame = _FxMZj
            else
                local _igMqR = math.clamp(_imVYf / _IUvE7, 0, 1)
                RootPart.CFrame = _PO5cu:Lerp(_FxMZj, _igMqR)
            end
        end
    end)
    if #_rJ2QD > 64 then
        for _TrAk2 = #_rJ2QD, 1, -1 do
            local _MdDiN = _rJ2QD[_TrAk2]
            if not (_MdDiN and _MdDiN.Connected) then
                table.remove(_rJ2QD, _TrAk2)
            end
        end
    end
    table.insert(_rJ2QD, _p12NO)
    return _p12NO
end
_sC0i4 = function()
    local _tZaOi = _tew4S()
    if not _FPbWqU0 then
        _FPbWqU0 = true
        if Humanoid then
            Humanoid.AutoRotate = false
        end
        if _tZaOi then
            _tZaOi:FireServer(_Ws0Y9.holdBlock)
        end
    end
end
_LZYNd = function()
    local _pGvOW = _tew4S()
    if _FPbWqU0 then
        _FPbWqU0 = false
        if _pGvOW then
            _pGvOW:FireServer(_Ws0Y9.releaseBlock)
        end
        State.freeRotate()
    end
end
local function _U47hf(_L0Fy6, _uoURw, _dbV4_)
    if Character and Character:FindFirstChild("Counter") then
        return false
    end
    _L0Fy6 = _L0Fy6 or 0.25
    local _YrV1M = State.blockState
    local _Pjka4 = tick()
    if _YrV1M.active and _Pjka4 - (_YrV1M.startedAt or _Pjka4) > (_YrV1M.untilT - (_YrV1M.startedAt or _Pjka4)) + 1 then
        _YrV1M.active = false
    end
    _YrV1M.untilT = math.max(_YrV1M.untilT, _Pjka4 + _L0Fy6)
    if _YrV1M.active then
        return false
    end
    _YrV1M.active = true
    _YrV1M.startedAt = _Pjka4
    local _uWPWO = {}
    _YrV1M.session = _uWPWO
    local _tRHue
    local _YdS4U, _tCvsb = pcall(function()
        _sC0i4()
        if Config.Autoblock.RotateChar and _uoURw and _dbV4_ then
            _tRHue = _BzpgT(_uoURw, _dbV4_, Config.Autoblock.CharEasing)
        end
        if Config.Autoblock.RotateCam and _uoURw then
            _t6uaX(_uoURw.Position, Config.Autoblock.CamEasing)
        end
        while tick() < _YrV1M.untilT and not Unloaded and _YrV1M.session == _uWPWO do
            task.wait()
        end
    end)
    if not _YdS4U then
        warn("[ZRHUB] block error: " .. tostring(_tCvsb))
    end
    _vA5WJ(_tRHue)
    if _YrV1M.session == _uWPWO then
        _YrV1M.active = false
        _YrV1M.session = nil
        _LZYNd()
    end
    return true
end
local function _yu80O()
    local _P_h6H = _tew4S()
    if not _P_h6H then
        return
    end
    local _UxGEJ = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local _dkeGg
    if Config.DeviceSpoof.Enabled then
        _dkeGg = (Config.DeviceSpoof.Device == "Mobile" or Config.DeviceSpoof.Device == "Console")
    else
        _dkeGg = _UxGEJ
    end
    randomWait()
    _P_h6H:FireServer({Goal = "LeftClick", Mobile = _dkeGg or nil})
    randomWait()
    _P_h6H:FireServer({Goal = "LeftClickRelease", Mobile = _dkeGg or nil})
    randomWait()
end
local function _y_W2U()
    pressKey(KeySpace)
    randomWait(0.01)
    _yu80O()
    releaseKey(KeySpace)
end
local function _Lym94(_gaaZQ, _pvDtO, _uPY8L)
    if tick() - (State.lastPunish or 0) < 0.25 then
        return
    end
    State.lastPunish = tick()
    if _gaaZQ.Parent and _opUYh(_gaaZQ.Parent, State.ignoreM1) and not (Character and Character:FindFirstChild("CanBringUp")) then
        local _Lhgzn
        if Config.Autoblock.RotateChar and _gaaZQ and _pvDtO then
            _Lhgzn = _BzpgT(_gaaZQ, _pvDtO, Config.Autoblock.CharEasing)
        end
        if Config.Autoblock.RotateCam and _gaaZQ then
            _t6uaX(_gaaZQ.Position, Config.Autoblock.CamEasing)
        end
        _yu80O()
        task.wait(0.1)
        _vA5WJ(_Lhgzn)
    end
end
local function _QUwWc(_ldveg)
    if not _ldveg or not RootPart then
        return false
    end
    local _GoKsH = _ldveg.AssemblyLinearVelocity
    if _GoKsH.Magnitude < 0.1 then
        return false
    end
    local _HAQsA = RootPart.Position - _ldveg.Position
    if _HAQsA.Magnitude < 0.01 then
        return true
    end
    return _GoKsH.Unit:Dot(_HAQsA.Unit) > 0.7
end
local function _ccj_e(_ltM9g, _qRoy3, _HjpLI)
    if not RootPart or not _ltM9g then
        return
    end
    local _YQB6C = RootPart.Position
    local _he55q = _ltM9g.Position
    local _C3KPw = (_YQB6C - _he55q).Magnitude
    if not _U47hf(_fwJeEv6(0.25)[1], _ltM9g, _qRoy3) then
        return
    end
    if ((not Config.Autoblock.AutoM1) or ((_C3KPw > _vrfgk.M1) and not (_C3KPw <= _vrfgk.MovingM1 and _QUwWc(_ltM9g)))) and not _HjpLI then
        return
    end
    _Lym94(_ltM9g, _qRoy3)
end
local function _EAEfrgSs(_X9iSzZU, _icYta6, _xlsTe, _Qhm_80)
    if not (_X9iSzZU and _icYta6 and RootPart) then
        return
    end
    if State.barrageActive then
        return
    end
    State.barrageActive = true
    local _TjYWBtQ = _BzpgT(_X9iSzZU, _icYta6, Config.Autoblock.CharEasing)
    local _eQGwNW7B
    local _DuajJ = tick()
    _eQGwNW7B = RunService.Heartbeat:Connect(function()
        if not (RootPart and RootPart.Parent and _X9iSzZU.Parent) then
            _vA5WJ(_TjYWBtQ)
            _vA5WJ(_eQGwNW7B)
            State.barrageActive = false
            _LZYNd()
            return
        end
        _sC0i4()
        local _ARUMCb46 = tick() - _DuajJ
        local _h74ciGr = math.clamp(_ARUMCb46 / 0.1, 0, 1)
        if (_xlsTe and _xlsTe:FindFirstChild("NoBlock")) or (RootPart.Position - _X9iSzZU.Position).Magnitude >= (_vrfgk.Barrage + 5) then
            _vA5WJ(_TjYWBtQ)
            _vA5WJ(_eQGwNW7B)
            State.barrageActive = false
            _LZYNd()
            if Config.Autoblock.AutoM1 and (RootPart.Position - _X9iSzZU.Position).Magnitude <= _vrfgk.M1 then
                _Lym94(_X9iSzZU, _icYta6)
            end
            return
        end
        if _h74ciGr >= 1 and not (_xlsTe and _xlsTe:FindFirstChild("Slowed")) then
            _vA5WJ(_TjYWBtQ)
            _vA5WJ(_eQGwNW7B)
            State.barrageActive = false
            _LZYNd()
        end
    end)
end
local function _Kl7n343j(_H66cx, _olfMgh, _lW44C46)
    local _aLAKT = _eh2Im8()
    if not Config.Autoblock.AutoCounter or not _aLAKT or _lW44C46 then
        return true
    end
    local _HPpYB = _rR9ON()
    if _HPpYB then
        local _sALuX = _HPpYB:FindFirstChild("4") or _HPpYB:FindFirstChild(4)
        local _Zn9a4 = _sALuX and _sALuX:FindFirstChild("Base")
        if _Zn9a4 and _Zn9a4:FindFirstChild("Cooldown") then
            return true
        end
    end
    local _OhUdu = _tew4S()
    if _OhUdu and _aLAKT then
        _OhUdu:FireServer({IsAutoActivate = true, Goal = "Console Move", Tool = _aLAKT, ToolName = _aLAKT.Name})
        return false
    end
    return true
end
local function _L8el_(_skHSk, _pIfT9, _Sqgmy)
    if not (_skHSk and _pIfT9 and _Sqgmy) then
        return
    end
    _M5_tm(_skHSk, _pIfT9, true)
    _OS0SJ({
        Title = "ZRHUB",
        Description = string.format("%s used <font color=\"%s\">Death Counter!</font>", _skHSk.DisplayName, _XEzdh(Config.Visuals.ESP.DeathCounterColor)),
        Image = _SCYz7(_skHSk),
        Source = "Death Counter"
    })
    local _zCIA_
    _zCIA_ = connectSignal(_Sqgmy.AncestryChanged, function(_wxUps, _dlhUB)
        if not _dlhUB then
            if (Config.Visuals.ESP.DeathCounterESP or Config.Visuals.ESP.SaitamaUltESP) and not Config.Visuals.ESP.Enabled then
                _uwnGWzzi(_pIfT9, _skHSk, false)
            else
                _M5_tm(_skHSk, _pIfT9, true)
            end
            _vA5WJ(_zCIA_)
        end
    end)
end
State.effectObjects = setmetatable({}, {__mode = "k"})
onDescendantAdded = function(_Sac2K)
    local _PdNSd = Config.Visuals
    if not (_PdNSd.NoNewLight or _PdNSd.NoSmoke or _PdNSd.NoGarouC or _PdNSd.NoAuras or _PdNSd.NoCapes or _PdNSd.NoRings or _PdNSd.EffectsColor.Enabled) then
        return
    end
    local _wZRJQ = _Sac2K.Name
    if (_Sac2K:IsA("PointLight") or _Sac2K:IsA("SpotLight") or _Sac2K:IsA("SurfaceLight")) and Config.Visuals.NoNewLight then
        _IeaiYt2E(_Sac2K, "Enabled", false)
    elseif (_keMEq[_wZRJQ] and Config.Visuals.NoSmoke) or (_wZRJQ == "Clone_Rig" and Config.Visuals.NoGarouC) or ((State.aura[_wZRJQ] or _wZRJQ == "CosmeticAuras") and Config.Visuals.NoAuras) or (State.cape[_wZRJQ] and Config.Visuals.NoCapes) or (_wZRJQ == "Ring" and Config.Visuals.NoRings) then
        task.defer(_Sac2K.Destroy, _Sac2K)
    elseif Config.Visuals.EffectsColor.Enabled and (_Sac2K:IsA("ParticleEmitter") or _Sac2K:IsA("Trail") or _Sac2K:IsA("Beam")) then
        local _hmAns = false
        if (Character and _Sac2K:IsDescendantOf(Character)) or _Sac2K:FindFirstAncestor(LocalPlayer.Name) then
            _hmAns = true
        else
            local _WspM1 = _RWZpc[_YxtF_bco]
            if _WspM1 and _WspM1[_wZRJQ] then
                _hmAns = true
            else
                local _DHy3o = (_Sac2K:IsA("BasePart") and _Sac2K) or _Sac2K:FindFirstAncestorOfClass("BasePart")
                if _DHy3o and RootPart then
                    local _vk4dx = (_DHy3o.Position - RootPart.Position).Magnitude
                    if _vk4dx <= 25 then
                        local _iBgCk = _wZRJQ:lower()
                        if tonumber(_wZRJQ) or _wZRJQ:match("^%d+[%-_]%d+") or _iBgCk:find("trail", 1, true) or _iBgCk:find("spin", 1, true) or _iBgCk:find("particle", 1, true) or _iBgCk:find("water", 1, true) or _iBgCk:find("hit", 1, true) or _iBgCk:find("slash", 1, true) or _iBgCk:find("swing", 1, true) or _iBgCk:find("punch", 1, true) or _iBgCk:find("impact", 1, true) or _iBgCk:find("flash", 1, true) or _iBgCk:find("line", 1, true) or _iBgCk:find("real", 1, true) or _iBgCk:find("air", 1, true) or _iBgCk:find("blue", 1, true) or _iBgCk:find("big", 1, true) or _iBgCk:find("spark", 1, true) or _iBgCk:find("splash", 1, true) then
                            _hmAns = true
                        end
                    end
                end
            end
        end
        if _hmAns then
            _IeaiYt2E(_Sac2K, "Color", ColorSequence.new(Config.Visuals.EffectsColor.Color))
            State.effectObjects[_Sac2K] = true
        end
    end
end
local function _d9naL()
    if not Config.Visuals.EffectsColor.Enabled then
        return
    end
    local _ERCy9 = ColorSequence.new(Config.Visuals.EffectsColor.Color)
    for _FWVpz in pairs(State.effectObjects) do
        if _FWVpz.Parent then
            _IeaiYt2E(_FWVpz, "Color", _ERCy9)
        else
            State.effectObjects[_FWVpz] = nil
        end
    end
end
App.setNoTextures = function(_XXSU_)
    if _XXSU_ then
        if Character then
            for _kQZhn, _xh7ey in pairs(Character:GetDescendants()) do
                onDescendantAdded(_xh7ey)
            end
        end
        for _KzWyR, _beDfr in pairs(Players:GetPlayers()) do
            local _oMugN = _beDfr.Character
            if _oMugN and _oMugN ~= Character then
                for _BvhF6, _Oe5lM in pairs(_oMugN:GetDescendants()) do
                    onDescendantAdded(_Oe5lM)
                end
            end
        end
        if World.Thrown then
            for _TToxd, _gBdST in pairs(World.Thrown:GetDescendants()) do
                onDescendantAdded(_gBdST)
            end
        end
    end
end
State.marks = {}
State.mark = function(_FUqSa, _SDd9E, _XgzmT)
    local _kO4wl = State.marks[_FUqSa]
    if not _SDd9E then
        if _kO4wl then
            _kO4wl:Destroy()
            State.marks[_FUqSa] = nil
        end
        return
    end
    if not (_kO4wl and _kO4wl.Parent) then
        _kO4wl = Instance.new("Highlight")
        _kO4wl.Name = "KWMark"
        _kO4wl.FillTransparency = 0.6
        _kO4wl.OutlineTransparency = 0
        _kO4wl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        State.marks[_FUqSa] = _kO4wl
    end
    _kO4wl.FillColor = _XgzmT
    _kO4wl.OutlineColor = _XgzmT
    if _kO4wl.Adornee ~= _SDd9E then
        _kO4wl.Adornee = _SDd9E
    end
    if _kO4wl.Parent ~= _SDd9E then
        _kO4wl.Parent = _SDd9E
    end
end
State.SDA = {busy = false, color = Color3.fromRGB(255, 45, 45)}
State.SDA.velocity = function(_xxguB)
    if _xxguB:IsA("BodyVelocity") then
        return _xxguB.Velocity
    end
    if _xxguB:IsA("LinearVelocity") then
        return _xxguB.VectorVelocity
    end
    return RootPart and RootPart.AssemblyLinearVelocity or Vector3.zero
end
State.SDA.target = function()
    local _Kgtf4 = RootPart
    if not _Kgtf4 then
        return nil
    end
    local _bGCwy = Config.Rage.SideDashAssist
    local _o9vLG = _Kgtf4.Position
    local _BpijY = _Kgtf4.CFrame.LookVector
    local _OGjuJ = Vector3.new(_BpijY.X, 0, _BpijY.Z)
    _OGjuJ = _OGjuJ.Magnitude > 0 and _OGjuJ.Unit or Vector3.zAxis
    local _T3rQh, _gtUwz7qb, _tLrQq
    local function _SjtwfD(_XIWc9ET)
        if not (_XIWc9ET and _XIWc9ET ~= Character and _XIWc9ET.Parent) then
            return
        end
        local _k5DLz5Gq = _XIWc9ET:FindFirstChild("HumanoidRootPart")
        local _yhMNeNZe = _XIWc9ET:FindFirstChildOfClass("Humanoid")
        if not (_k5DLz5Gq and _yhMNeNZe and _yhMNeNZe.Health > 0) then
            return
        end
        local _JpjHE = Players:GetPlayerFromCharacter(_XIWc9ET)
        if _JpjHE == LocalPlayer then
            return
        end
        if _JpjHE and Config.Misc.FriendCheck and _JrRW2(_JpjHE, false) then
            return
        end
        local _kwkuyl = _k5DLz5Gq.Position - _o9vLG
        local _NSiC3pL = _kwkuyl.Magnitude
        if _NSiC3pL > _bGCwy.Range or _NSiC3pL < 0.5 then
            return
        end
        local _yGDPnDGR = Vector3.new(_kwkuyl.X, 0, _kwkuyl.Z)
        local _nxfO0 = _yGDPnDGR.Magnitude > 0 and _yGDPnDGR.Unit:Dot(_OGjuJ) or 1
        if _nxfO0 <-0.25 then
            return
        end
        local _gVtHCp = _NSiC3pL * (1.6 - _nxfO0 * 0.6)
        if not _tLrQq or _gVtHCp < _tLrQq then
            _T3rQh, _gtUwz7qb, _tLrQq = _k5DLz5Gq, _XIWc9ET, _gVtHCp
        end
    end
    for _ViXGeCA, _GlDEJ in ipairs(Players:GetPlayers()) do
        _SjtwfD(_GlDEJ.Character)
    end
    if World.Live then
        for _vUryq, _chlf5 in ipairs(World.Live:GetChildren()) do
            if _chlf5:IsA("Model") and not Players:GetPlayerFromCharacter(_chlf5) then
                _SjtwfD(_chlf5)
            end
        end
    end
    return _T3rQh, _gtUwz7qb
end
State.SDA.angle = function(_RMww3)
    return math.atan2(_RMww3.Z, _RMww3.X)
end
State.SDA.waypoint = function(_CKtTh, _rvjjb, _kVl5R, _Z9aQt, _yc44w)
    local _n7a77 = Vector3.new(_CKtTh.X - _rvjjb.X, 0, _CKtTh.Z - _rvjjb.Z)
    if _n7a77.Magnitude < 0.1 then
        return _rvjjb, true, 0
    end
    local _gQcxd =-_n7a77.Unit
    local _VK2Dy = Vector3.new(-_gQcxd.Z, 0, _gQcxd.X) * _Z9aQt
    if _yc44w.Mode ~= "Behind" then
        local _GzDh4 = _rvjjb + _VK2Dy * _yc44w.Offset
        local _vtThH = Vector3.new(_GzDh4.X, _CKtTh.Y, _GzDh4.Z)
        return _vtThH, false, (_vtThH - _CKtTh).Magnitude
    end
    local _cD5Pn = Vector3.new(-_kVl5R.X, 0, -_kVl5R.Z)
    if _cD5Pn.Magnitude < 0.1 then
        _cD5Pn = _n7a77
    end
    _cD5Pn = _cD5Pn.Unit
    local _R5uIX = _yc44w.Offset
    local _Cauj5 = Vector3.new(_rvjjb.X, _CKtTh.Y, _rvjjb.Z) + _cD5Pn * _R5uIX
    local _rk2vz = (_n7a77.X * _VK2Dy.Z - _n7a77.Z * _VK2Dy.X) >= 0 and 1 or -1
    local _kOlNH, _ZHam6 = State.SDA.angle(_n7a77), State.SDA.angle(_cD5Pn)
    local _Kxz3A = ((_ZHam6 - _kOlNH) * _rk2vz) % (2 * math.pi)
    if _Kxz3A > math.rad(300) then
        _Kxz3A = 0
    end
    if _Kxz3A < math.rad(12) then
        return _Cauj5, true, (_Cauj5 - _CKtTh).Magnitude
    end
    local _ny8fo = _kOlNH + math.min(_Kxz3A, math.rad(70)) * _rk2vz
    local _gCaag = math.max(_R5uIX, math.min(_n7a77.Magnitude, _R5uIX + 6) - 2)
    local _bUio7 = Vector3.new(_rvjjb.X + math.cos(_ny8fo) * _gCaag, _CKtTh.Y, _rvjjb.Z + math.sin(_ny8fo) * _gCaag)
    return _bUio7, false, math.max(0, _n7a77.Magnitude - _R5uIX) + _R5uIX * _Kxz3A
end
State.SDA.run = function(_nfa72)
    local _Ak3Jf = State.SDA
    local _JJISI = Config.Rage.SideDashAssist
    if _Ak3Jf.busy or not (_JJISI.Enabled and RootPart and Humanoid and Humanoid.Health > 0) then
        return
    end
    RunService.Heartbeat:Wait()
    if _xFaaK(_j089A.backDash) or not (_nfa72 and _nfa72.Parent) then
        return
    end
    local _i7S7H = _xFaaK(_j089A.rsideDash)
    local _rWtHK = _xFaaK(_j089A.lsideDash)
    if _i7S7H == _rWtHK then
        local _EubOe = UserInputService:IsKeyDown(KeyS)
        _i7S7H = UserInputService:IsKeyDown(KeyD) and not _EubOe
        _rWtHK = UserInputService:IsKeyDown(KeyA) and not _EubOe
        if _i7S7H == _rWtHK then
            return
        end
    end
    if _Ak3Jf.busy then
        return
    end
    local _NdA8s, _auNTp = _Ak3Jf.target()
    local _jzdFj = RootPart
    if not (_NdA8s and _jzdFj) then
        return
    end
    _Ak3Jf.busy = true
    if _JJISI.Highlight then
        State.mark("sda", _auNTp, _Ak3Jf.color)
    end
    local _wiqfB = _i7S7H and 1 or -1
    if _nfa72 and _nfa72.Parent then
        _nfa72:Destroy()
    end
    local _RLD7J = Instance.new("BodyVelocity")
    _RLD7J.Name = "KWSideDash"
    _RLD7J.MaxForce = Vector3.new(50000, 0, 50000)
    _RLD7J.P = 4000
    _RLD7J.Velocity = Vector3.zero
    _RLD7J.Parent = _jzdFj
    local _e5GmO = tick()
    local _nY5se
    local _Av3hB
    local _JbC3W
    do
        local _WspHX = _jzdFj.AssemblyLinearVelocity
        local _rV73K = Vector3.new(_WspHX.X, 0, _WspHX.Z)
        if _rV73K.Magnitude > 5 then
            _Av3hB = _rV73K.Unit
        end
    end
    local _Eq_ZF
    local _NCLQ1, _amAq0 = _jzdFj.CFrame:ToOrientation()
    local _jl9eX = "KWSideDashFace"
    local function _wOuhB()
        _vA5WJ(_Eq_ZF)
        pcall(RunService.UnbindFromRenderStep, RunService, _jl9eX)
        if _RLD7J.Parent then
            _RLD7J:Destroy()
        end
        _Ak3Jf.busy = false
        State.freeRotate()
    end
    RunService:BindToRenderStep(_jl9eX, Enum.RenderPriority.Camera.Value + 1, function(_R9wJS)
        local _eI01z9jw = RootPart
        if _eI01z9jw ~= _jzdFj or not (_eI01z9jw and _eI01z9jw.Parent and _NdA8s.Parent) or _ffQog() then
            return
        end
        local _nXUHgYm = _NdA8s.Position - _eI01z9jw.Position
        if Vector3.new(_nXUHgYm.X, 0, _nXUHgYm.Z).Magnitude < 0.5 then
            return
        end
        local _AlgJtUCD = math.min(_R9wJS, 0.1) * 60
        if _JJISI.FaceTarget then
            local _JENLv = math.atan2(-_nXUHgYm.X, -_nXUHgYm.Z)
            local _Wlh1eY = math.atan2(math.sin(_JENLv - _amAq0), math.cos(_JENLv - _amAq0))
            _amAq0 = _amAq0 + (_Wlh1eY * (1 - (1 - (_nY5se and 0.5 or 0.3))^_AlgJtUCD))
            if Humanoid then
                Humanoid.AutoRotate = false
            end
            _eI01z9jw.CFrame = CFrame.new(_eI01z9jw.Position) * CFrame.Angles(0, _amAq0, 0)
        end
        if _JJISI.RotateCam then
            _GcDR2(0, _NdA8s.Position, false, false, nil, 1 - (1 - 0.25)^_AlgJtUCD)
        end
    end)
    _Eq_ZF = RunService.Stepped:Connect(function(_Vrxy7uV, _wXpWoV)
        local _n3MpS = RootPart
        if Unloaded or _n3MpS ~= _jzdFj or not (_n3MpS.Parent and _NdA8s.Parent and Humanoid and Humanoid.Health > 0) or _ffQog() or tick() - _e5GmO > (_JbC3W and _JbC3W + 0.3 or 1) or (not _nY5se and not _RLD7J.Parent) then
            _wOuhB()
            return
        end
        local _aK8RUu = _NdA8s.Position
        if _nY5se then
            if tick() - _nY5se > 0.3 then
                _wOuhB()
            end
            return
        end
        if _JJISI.Predict then
            local _QCajli = _NdA8s.AssemblyLinearVelocity
            local _FxT9_9a = math.min((_aK8RUu - _n3MpS.Position).Magnitude / 60, 0.3)
            _aK8RUu = _aK8RUu + Vector3.new(_QCajli.X, 0, _QCajli.Z) * _FxT9_9a
        end
        local _upr69IKk, _XUPbW, _M3RCm = _Ak3Jf.waypoint(_n3MpS.Position, _aK8RUu, _NdA8s.CFrame.LookVector, _wiqfB, _JJISI)
        local _B4_yB = Vector3.new(_upr69IKk.X - _n3MpS.Position.X, 0, _upr69IKk.Z - _n3MpS.Position.Z)
        local _qR51K = tick() - _e5GmO
        _JbC3W = _JbC3W or math.clamp(_M3RCm / 45, 0.3, 0.55) / math.clamp(_JJISI.Speed, 0.5, 2)
        local _fxxfw = math.max(_JbC3W - _qR51K, 0.06)
        local _UCEG_ = math.clamp(2 * _M3RCm / _fxxfw, 12, 120)
        if (_XUPbW or _JJISI.Mode ~= "Behind") and _B4_yB.Magnitude <= math.max(1.2, _UCEG_ * _wXpWoV * 1.2) then
            _RLD7J:Destroy()
            local _JrWeP = _n3MpS.AssemblyLinearVelocity
            _n3MpS.AssemblyLinearVelocity = Vector3.new(_JrWeP.X * 0.25, _JrWeP.Y, _JrWeP.Z * 0.25)
            _nY5se = tick()
            return
        end
        if _B4_yB.Magnitude < 0.05 then
            return
        end
        local _mPxvd = _B4_yB.Unit
        if _Av3hB then
            local _bWGoo = 1 - (1 - math.clamp(_JJISI.Strength, 0.05, 1))^(math.min(_wXpWoV, 0.1) * 60)
            local _Q1w35 = _Av3hB:Lerp(_mPxvd, _bWGoo)
            _Av3hB = _Q1w35.Magnitude > 0.05 and _Q1w35.Unit or _mPxvd
        else
            _Av3hB = _mPxvd
        end
        _RLD7J.Velocity = _Av3hB * _UCEG_
    end)
end
task.spawn(function()
    while not Unloaded do
        task.wait(0.1)
        local _F2325 = Config.Rage.SideDashAssist
        if not State.SDA.busy then
            local _us_RA
            if _F2325.Enabled and _F2325.Highlight and Humanoid and Humanoid.Health > 0 then
                local _jyYHl, _MWnfr = State.SDA.target()
                _us_RA = _MWnfr
            end
            State.mark("sda", _us_RA, State.SDA.color)
        end
    end
end)
State.DashPred = {
    ids = {[_j089A.frontDash] = true, [_j089A.rsideDash] = true, [_j089A.lsideDash] = true},
    active = {}
}
State.DashPred.start = function(_BMbef, _qVcx6, _fnSEV)
    local _U7L11 = State.DashPred
    local _Jpv8P = _U7L11.active[_BMbef]
    if _Jpv8P and tick() - _Jpv8P.started < 0.4 then
        return
    end
    _U7L11.active[_BMbef] = {hrp = _qVcx6, human = _fnSEV, started = tick()}
end
State.DashPred.threat = function(_m6yW6)
    local _bZJR0 = RootPart.Position - _m6yW6.Position
    _bZJR0 = Vector3.new(_bZJR0.X, 0, _bZJR0.Z)
    local _QjWDA = _m6yW6.AssemblyLinearVelocity
    _QjWDA = Vector3.new(_QjWDA.X, 0, _QjWDA.Z)
    local _FCY9A = _QjWDA:Dot(_QjWDA)
    if _FCY9A < 25 then
        return _bZJR0.Magnitude, 0, 0
    end
    local _CMqsl = _bZJR0.Magnitude > 0 and _bZJR0.Unit:Dot(_QjWDA) or 0
    local _Nx6JP = 0.45 + getPing(1000)
    local _YkNAw = math.clamp(_bZJR0:Dot(_QjWDA) / _FCY9A, 0, _Nx6JP)
    return (_bZJR0 - _QjWDA * _YkNAw).Magnitude, _YkNAw, _CMqsl
end
State.DashPred.step = function()
    local _v_aX_ = State.DashPred
    local _G41b6 = tick()
    for _Rsthx, _Nhsov in pairs(_v_aX_.active) do
        if _G41b6 - _Nhsov.started > 0.65 or not (_Nhsov.hrp.Parent and _Nhsov.human.Health > 0) then
            _v_aX_.active[_Rsthx] = nil
        elseif not _Nhsov.blocked then
            local _i7IOu = Players:GetPlayerFromCharacter(_Rsthx)
            if not (Config.Misc.FriendCheck and _i7IOu and _JrRW2(_i7IOu, false)) and _opUYh(Character, State.ignoreLocal) and _opUYh(_Rsthx, State.ignoreEnemy) then
                local _DWt9E, _M1L16, _hDQ7L = _v_aX_.threat(_Nhsov.hrp)
                local _CtmWK = (_Nhsov.hrp.Position - RootPart.Position).Magnitude
                if _CtmWK <= _vrfgk.M1 or (_hDQ7L > 8 and _DWt9E <= _vrfgk.M1 + 2) then
                    _Nhsov.blocked = true
                    local _Xh6pl = math.clamp(_M1L16 + 0.3 + getPing(1000), 0.3, 0.8)
                    task.spawn(function()
                        if _Kl7n343j(_Nhsov.hrp, _Nhsov.human, false) then
                            _U47hf(_Xh6pl, _Nhsov.hrp, _Nhsov.human)
                        end
                    end)
                end
            end
        end
    end
end
State.DashPred.acc = 0
connectSignal(RunService.Heartbeat, function(_sWYy7)
    local _NKHuy = State.DashPred
    if next(_NKHuy.active) == nil then
        return
    end
    if Unloaded or not (Config.Autoblock.Enabled and Config.Autoblock.DashPredict) then
        table.clear(_NKHuy.active)
        return
    end
    _NKHuy.acc = _NKHuy.acc + (_sWYy7)
    if _NKHuy.acc < 1 / 30 then
        return
    end
    _NKHuy.acc = 0
    if not (RootPart and Humanoid and Humanoid.Health > 0 and World.Live) then
        return
    end
    local _iARSC, _PbMqV = pcall(function()
        _NKHuy.step()
    end)
    if not _iARSC and not _NKHuy.warned then
        _NKHuy.warned = true
        warn("[ZRHUB] dash prediction error: " .. tostring(_PbMqV))
    end
end)
State.AB = {
    m1Ids = _DQit6({
        "10469493270",
        "10469630950",
        "10469639222",
        "10469643643",
        "14004222985",
        "13997092940",
        "14001963401",
        "14136436157",
        "13370310513",
        "13390230973",
        "13378751717",
        "13378708199",
        "15259161390",
        "15240216931",
        "15240176873",
        "15162694192",
        "89044067797964",
        "74334194837918",
        "94353845974131",
        "80601239139774",
        "13532562418",
        "13532600125",
        "13532604085",
        "13294471966",
        "125361499827663",
        "105701432344953",
        "104293439261333",
        "114460992057353",
        "111644455066361",
        "112778933066374",
        "80488470577181",
        "117726521294150",
        "97702234977209",
        "136834606687014",
        "137556620675474",
        "115406134600395",
        "13491635433",
        "13296577783",
        "13295919399",
        "13295936866",
        "16515503507",
        "16515520431",
        "16515448089",
        "16552234590",
        "17325510002",
        "17325513870",
        "17325522388",
        "17325537719",
        "17889458563",
        "17889461810",
        "17889471098",
        "17889290569",
        "123005629431309",
        "100059874351664",
        "104895379416342",
        "134775406437626",
        "122482492364036",
        "125882667406347",
        "134822631853770",
        "76602138940033",
        "13379003796",
        "10503381238",
        "10470104242"
    }),
    lastM1 = setmetatable({}, {__mode = "k"}),
    hooked = setmetatable({}, {__mode = "k"})
}
State.AB.inFOV = function(_kyNpd)
    local _FJn4q = Config.Autoblock.FOV or 360
    if _FJn4q >= 360 then
        return true
    end
    local _aU_Kn = RootPart.CFrame.LookVector
    local _v5qpL = Vector3.new(_aU_Kn.X, 0, _aU_Kn.Z)
    local _QrLPs = _kyNpd.Position - RootPart.Position
    local _Zjbcm = Vector3.new(_QrLPs.X, 0, _QrLPs.Z)
    if _v5qpL.Magnitude < 0.001 or _Zjbcm.Magnitude < 0.001 then
        return true
    end
    local _uAi658 = math.deg(math.acos(math.clamp(_v5qpL.Unit:Dot(_Zjbcm.Unit), -1, 1)))
    return _uAi658 <= _FJn4q / 2
end
State.AB.react = function(_PJlwRBT, _k2f_AHiI)
    if not Config.Autoblock.Enabled or _PJlwRBT == Character then
        return
    end
    if isrbxactive and not isrbxactive() then
        return
    end
    if not (RootPart and Humanoid and Humanoid.Health > 0) then
        return
    end
    local _Fg9HV = _PJlwRBT:FindFirstChild("HumanoidRootPart")
    local _at_zrT = _PJlwRBT:FindFirstChildOfClass("Humanoid")
    if not (_Fg9HV and _at_zrT and _at_zrT.Health > 0) then
        return
    end
    local _HZGJEc5 = Players:GetPlayerFromCharacter(_PJlwRBT)
    if _HZGJEc5 == LocalPlayer then
        return
    end
    if Config.Misc.FriendCheck and _HZGJEc5 and _JrRW2(_HZGJEc5, false) then
        return
    end
    local _YbCrBK = _k2f_AHiI == "M1ing"
    local _DoIR7 = State.interruptMoves[_k2f_AHiI]
    local _iOwuZQ70 = State.barrageMoves[_k2f_AHiI]
    if not (_YbCrBK or _DoIR7 or _iOwuZQ70) then
        return
    end
    local _NB0VKPa = (RootPart.Position - _Fg9HV.Position).Magnitude
    local _skuSTt = _NB0VKPa <= _vrfgk.M1
    local _X8nIm = _NB0VKPa <= _vrfgk.MovingM1 and _QUwWc(_Fg9HV)
    local _OfQ5KpEY = Config.Autoblock.DashPredict and _NB0VKPa <= _vrfgk.FarDash and (_xFaaK(_j089A.lsideDash, _at_zrT) or _xFaaK(_j089A.rsideDash, _at_zrT))
    if not (_skuSTt or _X8nIm or _OfQ5KpEY) then
        return
    end
    if not (_opUYh(Character, State.ignoreLocal) and _opUYh(_PJlwRBT, State.ignoreEnemy)) then
        return
    end
    if not State.AB.inFOV(_Fg9HV) then
        return
    end
    if _YbCrBK then
        local _toqAw = State.AB.lastM1[_PJlwRBT]
        if _toqAw and tick() - _toqAw < 0.15 then
            return
        end
        State.AB.lastM1[_PJlwRBT] = tick()
    end
    if _Kl7n343j(_Fg9HV, _at_zrT, _X8nIm) then
        if _YbCrBK then
            _ccj_e(_Fg9HV, _at_zrT, _OfQ5KpEY)
        elseif _DoIR7 then
            _Lym94(_Fg9HV, _at_zrT)
        elseif _iOwuZQ70 then
            _EAEfrgSs(_Fg9HV, _at_zrT, _PJlwRBT, _OfQ5KpEY)
        end
    end
end
State.AB.hook = function(_YKNHY)
    if not _YKNHY:IsA("Model") or _YKNHY == Character or State.AB.hooked[_YKNHY] then
        return
    end
    State.AB.hooked[_YKNHY] = true
    task.spawn(function()
        local _CPqxT = _YKNHY:WaitForChild("Humanoid", 10)
        local _jndhg = _CPqxT and _CPqxT:WaitForChild("Animator", 10)
        if not _jndhg then
            return
        end
        connectSignal(_jndhg.AnimationPlayed, function(_MlDSK)
            if Unloaded or not Config.Autoblock.Enabled or _YKNHY == Character then
                return
            end
            local _hZhtR = _MlDSK.Animation and _MlDSK.Animation.AnimationId:match("%d+")
            if not _hZhtR then
                return
            end
            if State.AB.m1Ids[_hZhtR] then
                task.spawn(State.AB.react, _YKNHY, "M1ing")
            elseif State.DashPred.ids[_hZhtR] and Config.Autoblock.DashPredict then
                local _KIUwT = _YKNHY:FindFirstChild("HumanoidRootPart")
                if _KIUwT and RootPart and (_KIUwT.Position - RootPart.Position).Magnitude <= 45 then
                    State.DashPred.start(_YKNHY, _KIUwT, _CPqxT)
                end
            end
        end)
    end)
end
if World.Live then
    for _rwLM_, _U42Pi in ipairs(World.Live:GetChildren()) do
        State.AB.hook(_U42Pi)
    end
    connectSignal(World.Live.ChildAdded, State.AB.hook)
end
App.onLiveChildAdded = function(_eBDUW)
    if not _eBDUW then
        return
    end
    local _L010k = _eBDUW.Name
    onDescendantAdded(_eBDUW)
    if not (State.watchedEvents[_L010k] or State.interruptMoves[_L010k] or State.barrageMoves[_L010k]) then
        return
    end
    if isrbxactive and not isrbxactive() then
        return
    end
    local _AUGzw = _eBDUW:FindFirstAncestorWhichIsA("Model")
    if not _AUGzw and _eBDUW.Parent then
        _AUGzw = _eBDUW.Parent:FindFirstAncestorWhichIsA("Model")
    end
    if not _AUGzw then
        return
    end
    local _hv01I = Players:FindFirstChild(_AUGzw.Name)
    local _Kf__L = (_AUGzw == Character) or (_hv01I and _hv01I == LocalPlayer)
    if not _Kf__L and _AUGzw then
        local _rmFhb = _AUGzw:FindFirstChild("HumanoidRootPart")
        local _UBMYH = _AUGzw:FindFirstChildOfClass("Humanoid") or _AUGzw:FindFirstChild("Humanoid")
        if not _UBMYH or not _rmFhb or not RootPart or not Humanoid or Humanoid.Health <= 0 or _UBMYH.Health <= 0 then
            return
        end
        if _L010k == "Counter" and _hv01I then
            _L8el_(_hv01I, _AUGzw, _eBDUW)
        elseif Config.Autoblock.Enabled then
            if State.dashEvents[_L010k] then
                if Config.Autoblock.DashPredict then
                    State.DashPred.start(_AUGzw, _rmFhb, _UBMYH)
                end
            else
                State.AB.react(_AUGzw, _L010k)
            end
        end
    elseif _Kf__L then
        if _L010k == "dodgevelocity" and Config.Rage.SideDashAssist.Enabled then
            task.spawn(State.SDA.run, _eBDUW)
        end
        if (_L010k == "Freeze" and Config.Rage.NoStun) or (_L010k == "Slowed" and Config.Rage.NoSlow) then
            task.defer(_eBDUW.Destroy, _eBDUW)
        elseif Config.Rage.NoSideDashCooldown and (_L010k == "UsedDash" or _L010k == "InDash" or _L010k == "DashCooldown" or _L010k == "SideDashCooldown") then
            task.defer(_eBDUW.Destroy, _eBDUW)
        elseif _L010k == "moveme" and Config.Rage.CustomFrontDash.Enabled and not Config.Rage.CustomFrontDash.OnlyOnKeybind and Config.Rage.CustomFrontDash.Distance > 1 then
            _fwa6a(_fwJeEv6(Config.Rage.CustomFrontDash.Distance)[1], 0.05)
        elseif _L010k == "dodgevelocity" and Config.Rage.CustomSideDash.Distance > 1 and Config.Rage.CustomSideDash.Enabled and not Config.Rage.CustomSideDash.OnlyOnKeybind and not (Config.Rage.SideDashAssist.Enabled and State.SDA.target()) then
            _fwa6a(_fwJeEv6(Config.Rage.CustomSideDash.Distance)[1], 0.05)
        end
    end
end
App.onAttrChanged = function(_S2sFP, _zdk_s, _cizPv)
    if _S2sFP == "Ulted" then
        if _zdk_s:GetAttribute(_S2sFP) then
            local _JGVcB = _zdk_s:GetAttribute("Character")
            _OS0SJ({
                Title = "ZRHUB",
                Description = string.format("%s used <font color=\"%s\">%s Ult!</font>", _cizPv.DisplayName, _XEzdh(_yah1udeS(_cizPv, _zdk_s)), CharacterNames[_JGVcB] or tostring(_JGVcB or "")),
                Image = _SCYz7(_cizPv),
                Source = "Ult"
            })
            if _JGVcB == "Bald" then
                _M5_tm(_cizPv, _zdk_s, true)
            else
                _M5_tm(_cizPv, _zdk_s)
            end
        elseif not Config.Visuals.ESP.Enabled and not _zdk_s:FindFirstChild("Counter") then
            _uwnGWzzi(_zdk_s, _cizPv, false)
        else
            _M5_tm(_cizPv, _zdk_s)
        end
    end
end
App.setupPlayer = function(_dkUvb)
    disconnectAll(PlayerConnections[_dkUvb])
    disconnectAll(CharacterConnections[_dkUvb])
    PlayerConnections[_dkUvb] = {}
    CharacterConnections[_dkUvb] = {}
    local _oQeYG = _dkUvb.Character
    if not _oQeYG then
        _oQeYG = World.Live:FindFirstChild(_dkUvb.Name)
    end
    bindEvent(PlayerConnections[_dkUvb], _dkUvb, "CharacterAdded", function(_HeQlv)
        bindEvent(CharacterConnections[_dkUvb], _HeQlv, "DescendantAdded", App.onLiveChildAdded)
        task.delay(0.5, function()
            if _HeQlv.Parent and onDescendantAdded then
                for _euHg6, _xHeVk in ipairs(_HeQlv:GetDescendants()) do
                    onDescendantAdded(_xHeVk)
                end
            end
        end)
        if _dkUvb == LocalPlayer then
            return
        end
        _M5_tm(_dkUvb, _HeQlv)
        bindEvent(CharacterConnections[_dkUvb], _HeQlv, "AttributeChanged", function(_UXilF)
            App.onAttrChanged(_UXilF, _HeQlv, _dkUvb)
        end)
    end)
    if _dkUvb ~= LocalPlayer then
        bindEvent(PlayerConnections[_dkUvb], _dkUvb, "AttributeChanged", function(_nlIDY)
            local _KBPFi = _dkUvb.Character
            if _nlIDY == "Ultimate" and _KBPFi then
                _M5_tm(_dkUvb, _KBPFi)
            end
        end)
        if not PlayerFrames[_dkUvb.Name] then
            PlayerFrames[_dkUvb.Name] = "Neutral"
        end
        task.spawn(_YWFA4n, _dkUvb)
        if _oQeYG then
            _M5_tm(_dkUvb, _oQeYG)
            bindEvent(CharacterConnections[_dkUvb], _oQeYG, "DescendantAdded", App.onLiveChildAdded)
            bindEvent(CharacterConnections[_dkUvb], _oQeYG, "AttributeChanged", function(_pNM3A)
                App.onAttrChanged(_pNM3A, _oQeYG, _dkUvb)
            end)
        end
    elseif _oQeYG then
        bindEvent(CharacterConnections[_dkUvb], _oQeYG, "DescendantAdded", App.onLiveChildAdded)
    end
    bindEvent(PlayerConnections[_dkUvb], _dkUvb, "CharacterRemoving", function(_MjXPU)
        if CharacterConnections[_dkUvb] then
            disconnectAll(CharacterConnections[_dkUvb])
        end
    end)
end
App.setConfigValue = function(_zKs9F, _UnJM0)
    if not _zKs9F then
        return
    end
    local _ti6sc = Config
    for _C4xvz in string.gmatch(_zKs9F, "[^%.]+") do
        if _ti6sc[_C4xvz] == nil then
            return
        end
        if _C4xvz ~= _zKs9F:match("[^%.]+$") then
            _ti6sc = _ti6sc[_C4xvz]
        else
            _ti6sc[_C4xvz] = _UnJM0
        end
    end
end
App.applyVisualToggle = function(_oJlN4, _NMrLC, _iXKjQ)
    App.setConfigValue(_oJlN4, _iXKjQ)
    if _NMrLC == "ESP" or _NMrLC == "NoBillboards" or _NMrLC == "BoxesESP" or _NMrLC == "HighlightESP" then
        _Eg6Ge()
    elseif _NMrLC == "Custom Ultbar Color" or _NMrLC == "Custom Ultbar Text" then
        task.spawn(pcall, _TQDHO)
    elseif _NMrLC == "NoGShadows" then
        local _zcIKW = _UbxYIsuM(Lighting, "GlobalShadows")
        Lighting.GlobalShadows = not _iXKjQ and _zcIKW
    elseif _NMrLC == "Headless" then
        if _iXKjQ then
            _dXK4f.set(1)
            _dXK4f.start()
        else
            _dXK4f.stop()
            _dXK4f.set(0)
        end
        if Config.Visuals.SelfChams.Enabled then
            _oQwzM()
        end
    elseif _NMrLC == "Korblox" then
        _K0t9W(_iXKjQ)
    elseif _NMrLC == "SelfChams" then
        _oQwzM()
    elseif _NMrLC == "Atmosphere" then
        _L3aVK(_iXKjQ)
    elseif _NMrLC == "MotionBlur" then
        MotionBlur.set(_iXKjQ)
    else
        App.setNoTextures(_iXKjQ)
    end
end
App.execBackDash = function(_FwDT0)
    setAutoRotate(_FwDT0)
    randomWait()
    pressKey(KeyS)
    tapKey(KeyQ)
    randomWait(0.1)
    releaseKey(KeyS)
end
do
    App.window = Library:new({
        name = "KittyWare " .. Version,
        accent = Color3.fromRGB(142, 187, 255),
        textsize = 13,
        discord = DiscordInvite
    })
    App.pages = {
        Combat = App.window:page({name = "Combat", pointer = "Combat Tab"}),
        Macro = App.window:page({name = "Macro", pointer = "Macro Tab"}),
        Visual = App.window:page({name = "Visuals", pointer = "Visual Tab"}),
        Rage = App.window:page({name = "Rage", pointer = "Rage Tab"}),
        Notifications = App.window:page({name = "Notifications", pointer = "Notification Tab"}),
        Misc = App.window:page({name = "Misc", pointer = "Misc Tab"})
    }
    App.sections = {
        AutoBlock = App.pages.Combat:section({name = "Auto Block", side = "left", size = 287, pointer = "Auto Block Section"}),
        MiscCombat = App.pages.Combat:section({name = "Misc", side = "left", size = 335, pointer = "Misc Combat Section"}),
        TrueDownSlam = App.pages.Combat:section({name = "True DownSlam", side = "left", size = 70, pointer = "TDS Section"}),
        LethalMain = App.pages.Combat:section({name = "Auto Lethal", side = "left", size = 165, pointer = "Auto Lethal Section"}),
        LethalTiming = App.pages.Combat:section({name = "Lethal Settings", side = "left", size = 197, pointer = "Auto Lethal Settings Section"}),
        AutoTech = App.pages.Combat:section({name = "Auto Tech", side = "right", size = 225, pointer = "Auto Tech Section"}),
        TechSettings = App.pages.Combat:section({name = "Auto Tech Settings", side = "right", size = 240, pointer = "Loop Dash v2 Section"}),
        CustomDash = App.pages.Combat:section({name = "Custom Dash", side = "right", size = 355, pointer = "Custom Dash Section"}),
        CustomDashv2 = App.pages.Combat:section({name = "Custom Dash v2", side = "right", size = 420, pointer = "Custom Dash v2 Section"}),
        TrueM1Reset = App.pages.Macro:section({name = "True M1 Reset", side = "left", size = 69, pointer = "m1 Reset Section"}),
        EmoteDash = App.pages.Macro:section({name = "Emote Dash", side = "left", size = 149, pointer = "EmoteDash Section"}),
        BackdashCancel = App.pages.Macro:section({name = "Backdash Cancel", side = "left", size = 195, pointer = "Backdash Section"}),
        Tech = App.pages.Macro:section({name = "Tech Helper", side = "right", size = 191, pointer = "Tech Section"}),
        VisualMain = App.pages.Visual:section({name = "Clean Look", side = "left", size = 330, pointer = "Visuals Main Section"}),
        VisualUlt = App.pages.Visual:section({name = "Custom Ultbar", side = "right", size = 127, pointer = "Visuals Ult Section"}),
        VisualColor = App.pages.Visual:section({name = "Custom Effects", side = "left", size = 67, pointer = "Visuals Color Section"}),
        VisualESP = App.pages.Visual:section({name = "ESP", side = "right", size = 413, pointer = "Visuals ESP Section"}),
        VisualChar = App.pages.Visual:section({name = "Character & Self Chams", side = "left", size = 210, pointer = "Visuals Character Section"}),
        VisualAtmosphere = App.pages.Visual:section({name = "Custom Atmosphere", side = "right", size = 183, pointer = "Visuals Atmosphere Section"}),
        VisualSky = App.pages.Visual:section({name = "Custom Sky", side = "left", size = 157, pointer = "Visuals Sky Section"}),
        VisualCharCopy = App.pages.Visual:section({name = "Char (Copy Avatar)", side = "right", size = 142, pointer = "Char Copy Section"}),
        Rage = App.pages.Rage:section({name = "Toggles", side = "right", size = 150, pointer = "Rage Section"}),
        Fling = App.pages.Rage:section({name = "Fling", side = "right", size = 132, pointer = "Fling Section"}),
        SDA = App.pages.Rage:section({name = "Side Dash Assist", side = "right", size = 297, pointer = "Side Dash Assist Section"}),
        Front = App.pages.Rage:section({name = "Front Dash", side = "left", size = 120, pointer = "Front Dash Section"}),
        Side = App.pages.Rage:section({name = "Side Dash", side = "left", size = 265, pointer = "Side Dash Section"}),
        UndyingHero = App.pages.Rage:section({name = "Undying Hero / Sniper", side = "left", size = 460, pointer = "Undying Hero Section"}),
        Notifs = App.pages.Notifications:section({name = "Main", side = "left", size = 127, pointer = "Notifications Section"}),
        Misc = App.pages.Misc:section({name = "Misc", side = "left", size = 210, pointer = "Misc Section"}),
        LockOnSet = App.pages.Misc:section({name = "Lock On", side = "left", size = 440, pointer = "Lock On Section"}),
        Config = App.pages.Misc:section({name = "Config", side = "right", size = 254, pointer = "Config Section"}),
        AutoLoad = App.pages.Misc:section({name = "Auto Load Config", side = "right", size = 115, pointer = "Auto Load Section"}),
        PingSpoof = App.pages.Misc:section({name = "Ping Spoofer", side = "right", size = 143, pointer = "Ping Spoofer Section"}),
        DeviceSpoof = App.pages.Misc:section({name = "Device Spoofer", side = "right", size = 147, pointer = "Device Spoofer Section"})
    }
    App.sections.Config:configloader({folder = "KittyWare"})
    App.autoload = {path = "KittyWare/autoload.json", enabled = false, name = ""}
    App.autoload.read = function()
        if not (isfile and readfile) then
            return
        end
        pcall(function()
            if isfile(App.autoload.path) then
                local _gfTOOU = Services.HttpService:JSONDecode(readfile(App.autoload.path))
                App.autoload.enabled = _gfTOOU.enabled == true
                App.autoload.name = tostring(_gfTOOU.name or "")
            end
        end)
    end
    App.autoload.write = function()
        if not writefile then
            return
        end
        pcall(function()
            if makefolder and isfolder and not isfolder("KittyWare") then
                makefolder("KittyWare")
            end
            writefile(App.autoload.path, Services.HttpService:JSONEncode({enabled = App.autoload.enabled, name = App.autoload.name}))
        end)
    end
    App.autoload.list = function()
        local _vY0MW = {}
        if not (listfiles and isfolder and isfolder("KittyWare")) then
            return _vY0MW
        end
        for _aLsLJtOM, _JSCiJm9 in ipairs(listfiles("KittyWare")) do
            local _o9EbCm = tostring(_JSCiJm9):match("([^/\\]+)%.cfg$")
            if _o9EbCm then
                table.insert(_vY0MW, _o9EbCm)
            end
        end
        table.sort(_vY0MW)
        return _vY0MW
    end
    App.autoload.load = function(_Du5iu)
        local _iI_b3Gru = App.autoload.name
        if _iI_b3Gru == "" then
            if not _Du5iu then
                _OS0SJ({Title = "ZRHUB", Description = "type the config name first", Source = "Config"})
            end
            return
        end
        local _Ruwas = "KittyWare/" .. _iI_b3Gru .. ".cfg"
        if not (isfile and isfile(_Ruwas)) then
            _OS0SJ({Title = "ZRHUB", Description = "auto load: no config named " .. _iI_b3Gru, Source = "Config"})
            return
        end
        local _wekSV, _Xn9WO = App.window:loadconfig(_Ruwas)
        _OS0SJ({Title = "ZRHUB", Description = _wekSV and ("loaded config " .. _iI_b3Gru) or ("couldn't load " .. _iI_b3Gru .. ": " .. tostring(_Xn9WO)), Source = "Config"})
    end
    App.autoload.read()
    App.sections.AutoLoad:toggle({
        name = "Auto Load On Start",
        def = App.autoload.enabled,
        tooltip = "Loads the config below every time KittyWare starts",
        callback = function(_Cvb1p)
            App.autoload.enabled = _Cvb1p
            App.autoload.write()
        end
    })
    App.autoload.options = function()
        local _lB1CK = {"None"}
        for _csfbB, _D3yqi in ipairs(App.autoload.list()) do
            table.insert(_lB1CK, _D3yqi)
        end
        return _lB1CK
    end
    App.autoload.refresh = function(_idNMS)
        local _Q8KaK = _idNMS.titles[1]
        local _xWcIv = _idNMS.optionsholder:FindFirstChildOfClass("ScrollingFrame")
        if not (_Q8KaK and _Q8KaK.Parent and _xWcIv) then
            return
        end
        local _WL9Xh = _Q8KaK.Parent:Clone()
        for _rzhk7, _YqQ7X in ipairs(_idNMS.titles) do
            if _YqQ7X.Parent then
                _YqQ7X.Parent:Destroy()
            end
        end
        table.clear(_idNMS.titles)
        local _Flv7h = App.autoload.options()
        _idNMS.options = _Flv7h
        local _eESHJ = _idNMS.library.theme.accent
        for _Lw8tl, _shNHy in ipairs(_Flv7h) do
            local _ZwdBh = _WL9Xh:Clone()
            local _KZraQ = _ZwdBh:FindFirstChildOfClass("TextLabel")
            _KZraQ.Text = _shNHy
            _KZraQ.TextColor3 = _shNHy == _idNMS.current and _eESHJ or Color3.fromRGB(255, 255, 255)
            _ZwdBh.Parent = _xWcIv
            table.insert(_idNMS.titles, _KZraQ)
            _ZwdBh.Activated:Connect(function()
                _idNMS.optionsholder.Visible = false
                _idNMS.open = false
                _idNMS.optionsholder.ZIndex = 1
                if _idNMS.optionsholder.Parent then
                    _idNMS.optionsholder.Parent.ZIndex = 2
                end
                _idNMS.indicator.Text = "+"
                for _ravIc, _Ya3qM in ipairs(_idNMS.titles) do
                    _Ya3qM.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
                _KZraQ.TextColor3 = _eESHJ
                _idNMS.current = _shNHy
                _idNMS.value.Text = _shNHy
                _idNMS.callback(_shNHy)
            end)
        end
        local _FCGDP = math.clamp(#_Flv7h, 1, 6)
        _xWcIv.Size = UDim2.new(1, 0, 0, _FCGDP * 18 + 2)
        _xWcIv.CanvasSize = UDim2.new(0, 0, 0, #_Flv7h * 18)
    end
    do
        App.configOptions = App.autoload.options()
        App.selectedConfig = table.find(App.configOptions, App.autoload.name) and App.autoload.name or "None"
        if App.selectedConfig == "None" and App.autoload.name ~= "" then
            _OS0SJ({Title = "ZRHUB", Description = "auto load: " .. App.autoload.name .. " was deleted, pick another config", Source = "Config"})
            App.autoload.name = ""
            App.autoload.write()
        end
        App.autoload.dropdown = App.sections.AutoLoad:dropdown({
            name = "Config",
            def = App.selectedConfig,
            max = 6,
            options = App.configOptions,
            callback = function(_QjoYR)
                App.autoload.name = _QjoYR == "None" and "" or tostring(_QjoYR)
                App.autoload.write()
            end
        })
        App.autoload.dropdown.optionsholder:GetPropertyChangedSignal("Visible"):Connect(function()
            if App.autoload.dropdown.optionsholder.Visible then
                pcall(App.autoload.refresh, App.autoload.dropdown)
            end
        end)
    end
    App.sections.AutoLoad:button({
        name = "Load It Now",
        callback = function()
            App.autoload.load(false)
        end
    })
    App.iconState = {icon = nil, folder = "KittyWare/icons", watching = false}
    App.iconState.custom = function()
        return Config.DeviceSpoof.Enabled and Config.DeviceSpoof.Device == "Custom Icon" and App.iconState.icon ~= nil
    end
    App.iconState.real = function()
        return UserInputService.TouchEnabled, UserInputService.GamepadEnabled
    end
    App.iconState.flags = function()
        local _KmjuE = Config.DeviceSpoof.Device
        if _KmjuE == "Custom Icon" then
            return App.iconState.real()
        end
        return _KmjuE == "Mobile", _KmjuE == "Console"
    end
    App.iconState.shown = function()
        if LocalPlayer:GetAttribute("Console") then
            return "Console"
        end
        if LocalPlayer:GetAttribute("Mobile") then
            return "Mobile"
        end
        return "PC"
    end
    App.iconState.send = function(_ddGJT, _wq9Pz)
        local _PytPX = _MJSFe
        if not (_PytPX and _PytPX.Parent) then
            return
        end
        pcall(function()
            _PytPX:FireServer({Goal = "Platform", mobile = _ddGJT})
        end)
        pcall(function()
            _PytPX:FireServer({Goal = "Platform", console = _wq9Pz})
        end)
    end
    App.iconState.apply = function()
        local _e2U07, _xz8E7 = App.iconState.flags()
        App.iconState.send(_e2U07, _xz8E7)
        local _QXHy7 = Config.DeviceSpoof.Device
        if _QXHy7 == "Custom Icon" then
            return
        end
        task.delay(0.7, function()
            if Unloaded or not Config.DeviceSpoof.Enabled or Config.DeviceSpoof.Device ~= _QXHy7 then
                return
            end
            if App.iconState.shown() == _QXHy7 then
                return
            end
            local _jc5oz = _MJSFe
            if _jc5oz and _jc5oz.Parent then
                for _KVjCj, _dGt8d in ipairs({" Platform ", "SetPlatform"}) do
                    pcall(function()
                        _jc5oz:FireServer({Goal = _dGt8d, mobile = _e2U07})
                    end)
                end
            end
            task.wait(0.7)
            if Unloaded or not Config.DeviceSpoof.Enabled or Config.DeviceSpoof.Device ~= _QXHy7 then
                return
            end
            if App.iconState.shown() ~= _QXHy7 then
                _OS0SJ({Title = "ZRHUB", Description = "the server kept your old device (" .. App.iconState.shown() .. "). it probably only lets it change once per join, rejoin and pick the device before turning this on"})
            end
        end)
    end
    App.iconState.restore = function()
        App.iconState.send(App.iconState.real())
    end
    App.iconState.resolveIcon = function(_wSvGO)
        _wSvGO = tostring(_wSvGO or ""):match("^%s*(.-)%s*$")
        if _wSvGO == "" then
            return nil
        end
        if _wSvGO:match("^%d+$") then
            return "rbxassetid://" .. _wSvGO
        end
        if _wSvGO:match("^rbxassetid://") or _wSvGO:match("^rbxasset://") then
            return _wSvGO
        end
        if not (getcustomasset and isfile and writefile and readfile) then
            return nil
        end
        if makefolder and isfolder and not isfolder(App.iconState.folder) then
            pcall(makefolder, "KittyWare")
            pcall(makefolder, App.iconState.folder)
        end
        local _bkCAR
        if _wSvGO:match("^https?://") then
            _bkCAR = App.iconState.folder .. "/" .. _wSvGO:gsub("[^%w]", ""):sub(-40) .. ".png"
            if not isfile(_bkCAR) then
                local _CnA4S = pcall(function()
                    writefile(_bkCAR, game:HttpGet(_wSvGO))
                end)
                if not _CnA4S then
                    return nil
                end
            end
        else
            _bkCAR = App.iconState.folder .. "/" .. _wSvGO
            if not isfile(_bkCAR) then
                return nil
            end
        end
        local _VyfN4, _tdPci = pcall(getcustomasset, _bkCAR)
        return _VyfN4 and _tdPci or nil
    end
    App.iconState.isMine = function(_GvETB)
        local _bFyfE = _GvETB:FindFirstChild("PlayerHeader", true)
        if not _bFyfE then
            return false
        end
        local _sI12H = _bFyfE:FindFirstChild("DisplayName", true)
        if _sI12H and _sI12H:IsA("TextLabel") and _sI12H.Text:sub(1, #LocalPlayer.DisplayName) == LocalPlayer.DisplayName then
            return true
        end
        local _FZOqb = _bFyfE:FindFirstChild("AvatarImage", true)
        return _FZOqb ~= nil and (_FZOqb:IsA("ImageLabel") or _FZOqb:IsA("ImageButton")) and tostring(_FZOqb.Image):find(tostring(LocalPlayer.UserId), 1, true) ~= nil
    end
    App.applyCustomIcon = function(_Di5smvU)
        if App.iconState.custom() and _Di5smvU.Image ~= App.iconState.icon then
            _Di5smvU.Image = App.iconState.icon
        end
    end
    App.iconState.paint = function(_QFDnQ3)
        if not App.iconState.custom() then
            return
        end
        local _tMi6v = _QFDnQ3:FindFirstChild("DeviceIcon", true)
        if not (_tMi6v and _tMi6v:IsA("ImageLabel") and App.iconState.isMine(_QFDnQ3)) then
            return
        end
        App.applyCustomIcon(_tMi6v)
        App.iconState.hooked = App.iconState.hooked or setmetatable({}, {__mode = "k"})
        if App.iconState.hooked[_tMi6v] then
            return
        end
        App.iconState.hooked[_tMi6v] = true
        connectSignal(_tMi6v:GetPropertyChangedSignal("Image"), function()
            App.applyCustomIcon(_tMi6v)
        end)
    end
    App.iconState.repaint = function()
        for _G5yGendB, _nxYm74O in ipairs(PlayerGui:GetDescendants()) do
            if _nxYm74O.Name == "ActiveDropdown" then
                App.iconState.paint(_nxYm74O)
            end
        end
    end
    App.iconState.watch = function(_QHPIuRCp)
        if _QHPIuRCp and not App.iconState.watching then
            App.iconState.watching = connectSignal(PlayerGui.DescendantAdded, function(_X06lR)
                if _X06lR.Name == "ActiveDropdown" then
                    task.defer(App.iconState.paint, _X06lR)
                end
            end)
        elseif not _QHPIuRCp and App.iconState.watching then
            _vA5WJ(App.iconState.watching)
            App.iconState.watching = false
        end
    end
    App.iconState.setIcon = function(_uimkw6)
        task.spawn(function()
            App.iconState.icon = App.iconState.resolveIcon(_uimkw6)
            if _uimkw6 ~= "" and not App.iconState.icon then
                _OS0SJ({Title = "ZRHUB", Description = "couldn't load that icon (asset id, https link to a png, or a file in KittyWare/icons)"})
            end
            if App.iconState.custom() then
                App.iconState.repaint()
            end
        end)
    end
    App.pingSpoof = {hooked = false, thread = false}
    App.pingSpoof.value = function()
        local _MJTnf0Tc = Config.PingSpoof
        return math.clamp(_MJTnf0Tc.Ping + math.random(-_MJTnf0Tc.Jitter, _MJTnf0Tc.Jitter), 0, 5000)
    end
    App.inputState = {
        m1Down = false,
        gamepadDown = false,
        activeTouches = {},
        punchBtnHeld = false
    }
    connectSignal(ZR_InputBegan, function(_iR7W3Lu9)
        local _N4f6naG = _iR7W3Lu9.UserInputType
        if _N4f6naG == Enum.UserInputType.MouseButton1 then
            App.inputState.m1Down = true
        elseif _N4f6naG == Enum.UserInputType.Touch then
            App.inputState.activeTouches[_iR7W3Lu9] = true
        elseif _iR7W3Lu9.KeyCode == Enum.KeyCode.ButtonR2 or _iR7W3Lu9.KeyCode == Enum.KeyCode.ButtonB or _iR7W3Lu9.KeyCode == Enum.KeyCode.ButtonX then
            App.inputState.gamepadDown = true
        end
    end)
    connectSignal(ZR_InputEnded, function(_k9VTr)
        local _XSbmH = _k9VTr.UserInputType
        if _XSbmH == Enum.UserInputType.MouseButton1 then
            App.inputState.m1Down = false
        elseif _XSbmH == Enum.UserInputType.Touch then
            App.inputState.activeTouches[_k9VTr] = nil
        elseif _k9VTr.KeyCode == Enum.KeyCode.ButtonR2 or _k9VTr.KeyCode == Enum.KeyCode.ButtonB or _k9VTr.KeyCode == Enum.KeyCode.ButtonX then
            App.inputState.gamepadDown = false
        end
    end)
    connectSignal(UserInputService.TouchStarted, function(_uNvrJ)
        App.inputState.activeTouches[_uNvrJ] = true
    end)
    connectSignal(UserInputService.TouchEnded, function(_NnQLW)
        App.inputState.activeTouches[_NnQLW] = nil
    end)
    App.triggerM1Click = function()
        if App.inputState.m1Down or App.inputState.gamepadDown or next(App.inputState.activeTouches) ~= nil or App.inputState.punchBtnHeld then
            return true
        end
        local _AVhW7, _XQrY0 = pcall(function()
            return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        end)
        if _AVhW7 and _XQrY0 then
            return true
        end
        local _KzDcO, _pooRm = pcall(function()
            return UserInputService:GetTouches()
        end)
        if _KzDcO and #_pooRm > 0 then
            return true
        end
        for _M8NO5, _zR0Wy in ipairs({Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonX}) do
            local _i1PIR, _NRCjO = pcall(function()
                return UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, _zR0Wy)
            end)
            if _i1PIR and _NRCjO then
                return true
            end
        end
        local _ob08w, _BfTOI = pcall(function()
            for _AzND7, _WKYee in ipairs(PlayerGui:GetChildren()) do
                local _LKaAt = _WKYee:FindFirstChild("PunchButton", true)
                if _LKaAt and _LKaAt:IsA("ImageButton") and tostring(_LKaAt.Image):find("12253807149") then
                    return true
                end
            end
            return false
        end)
        if _ob08w and _BfTOI then
            return true
        end
        return false
    end
    App.getAimRay = function()
        local _LIWP3 = workspace.CurrentCamera
        if not _LIWP3 then
            return nil
        end
        local _oZEdv = Character or (LocalPlayer and LocalPlayer.Character)
        local _d5T0_ = RootPart or (_oZEdv and _oZEdv:FindFirstChild("HumanoidRootPart"))
        local _yrfik = (_d5T0_ and _d5T0_.Position) or _LIWP3.CFrame.Position
        local _JJ3Hz = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        local _UfKPT = _JJ3Hz and (_LIWP3.ViewportSize / 2) or UserInputService:GetMouseLocation()
        local _voVCe = Config.Zombie.SilentAimMaxDist or 1500
        local _KU58i = Config.Zombie.SilentAimFOV or 500
        local _laddB = Config.Zombie.SilentAimMode or "Mouse"
        local _IsVTy = nil
        local _TJ_a5 = nil
        local _KRSeh = nil
        local _Vo2Uc = math.huge
        local function _sWUhy(_TEs5l)
            if not _TEs5l or not _TEs5l.Parent or _TEs5l == _oZEdv then
                return
            end
            local _itimm = _TEs5l:FindFirstChildOfClass("Humanoid")
            local _Jb4_u = _TEs5l:FindFirstChild("HumanoidRootPart")
            if not (_itimm and _Jb4_u and _itimm.Health > 0) then
                return
            end
            local _UGB7v = Players:GetPlayerFromCharacter(_TEs5l)
            if _UGB7v then
                if _UGB7v == LocalPlayer then
                    return
                end
                if Config.Misc and Config.Misc.FriendCheck and _JrRW2(_UGB7v, false) then
                    return
                end
            end
            local _fgUtj = (_Jb4_u.Position - _yrfik).Magnitude
            if _fgUtj > _voVCe then
                return
            end
            local _K15PT = _TEs5l:FindFirstChild("Torso") or _TEs5l:FindFirstChild("UpperTorso")
            local _VSj2G = (Config.Zombie.TargetPart == "Head" and _TEs5l:FindFirstChild("Head")) or _K15PT or _TEs5l:FindFirstChild("Head")
            if not _VSj2G then
                return
            end
            if Config.Zombie.WallCheck then
                local _sE20E = _LIWP3.CFrame.Position
                local _T8XAM = _VSj2G.Position - _sE20E
                local _i0UHe = RaycastParams.new()
                _i0UHe.FilterType = Enum.RaycastFilterType.Exclude
                _i0UHe.FilterDescendantsInstances = {_oZEdv, _TEs5l}
                local _VrnrD = workspace:Raycast(_sE20E, _T8XAM, _i0UHe)
                if _VrnrD and _VrnrD.Instance and _VrnrD.Instance.CanCollide then
                    return
                end
            end
            local _sHORd
            if _laddB == "Distance" then
                _sHORd = _fgUtj
            else
                local _D0lYS, _fQ9_vfz = _LIWP3:WorldToViewportPoint(_VSj2G.Position)
                if not _fQ9_vfz then
                    return
                end
                local _scUBtjZo = Vector2.new(_D0lYS.X, _D0lYS.Y)
                _sHORd = (_scUBtjZo - _UfKPT).Magnitude
                if _KU58i > 0 and _sHORd > _KU58i then
                    return
                end
            end
            if _lH0uIxY.hrp == _Jb4_u then
                _sHORd =-1
            end
            if _sHORd < _Vo2Uc then
                _Vo2Uc = _sHORd
                _IsVTy = _TEs5l
                _TJ_a5 = _VSj2G
                _KRSeh = _Jb4_u
            end
        end
        local _R1kEv = {}
        for _i9VGUD, _rBepenA in ipairs(Players:GetPlayers()) do
            if _rBepenA.Character then
                _R1kEv[_rBepenA.Character] = true
                _sWUhy(_rBepenA.Character)
            end
        end
        local _ULJ9trjf = workspace:FindFirstChild("Live") or (World and World.Live)
        if _ULJ9trjf then
            for _ttxs3, _ud_D3u in ipairs(_ULJ9trjf:GetChildren()) do
                if not _R1kEv[_ud_D3u] and _ud_D3u:IsA("Model") then
                    _sWUhy(_ud_D3u)
                end
            end
        end
        return _IsVTy, _TJ_a5, _KRSeh
    end
    App.pingSpoof.eye = function()
        local _VoR4oa5 = State.Scope
        if _VoR4oa5.active and _VoR4oa5.eye then
            return _VoR4oa5.eye
        end
        local _IGYj20kY = workspace.CurrentCamera
        return _IGYj20kY and _IGYj20kY.CFrame
    end
    App.pingSpoof.shot = function()
        local _X7LAK = App.pingSpoof.eye()
        if not (_X7LAK and Config.Zombie.SniperSilentAim) then
            return nil
        end
        local _ud6LqH, _lKQhWTf, _IBNpU = App.getAimRay()
        if not (_ud6LqH and _lKQhWTf) then
            return nil
        end
        local _jU1a8 = _lKQhWTf.Position
        local _WaOzK = Config.Zombie.SilentAimPredict
        if _WaOzK and _WaOzK > 0 and _IBNpU then
            local _JkBS2 = _IBNpU.AssemblyLinearVelocity
            _jU1a8 = _jU1a8 + Vector3.new(_JkBS2.X, _JkBS2.Y * 0.4, _JkBS2.Z) * ((_WaOzK / 100) * (getPing(1000) * 0.5 + 0.05))
        end
        return {
            Aim = CFrame.lookAt(_X7LAK.Position, _jU1a8),
            Targets = {_ud6LqH},
            Limbs = {_lKQhWTf}
        }
    end
    App.pingSpoof.install = function()
        if App.pingSpoof.hooked then
            return true
        end
        if not (hookmetamethod and newcclosure and getnamecallmethod and checkcaller) then
            return false
        end
        App.pingSpoof.hooked = true
        local _wRynk = setnamecallmethod or (debug and rawget(debug, "setnamecallmethod")) or set_namecall_method
        local _XDqzv
        _XDqzv = hookmetamethod(game, "__namecall", newcclosure(function(_uJD2B, ...)
            if not (Config.PingSpoof.Enabled or Config.DeviceSpoof.Enabled or (Config.Zombie and (Config.Zombie.SniperSilentAim or Config.Zombie.SniperThirdPerson))) or Unloaded then
                return _XDqzv(_uJD2B, ...)
            end
            if checkcaller() then
                return _XDqzv(_uJD2B, ...)
            end
            if getnamecallmethod() ~= "FireServer" then
                return _XDqzv(_uJD2B, ...)
            end
            if typeof(_uJD2B) ~= "Instance" or _uJD2B.ClassName ~= "RemoteEvent" or _uJD2B.Name ~= "Communicate" then
                if _wRynk then
                    _wRynk("FireServer")
                end
                return _XDqzv(_uJD2B, ...)
            end
            local _llaZv = ...
            if type(_llaZv) ~= "table" then
                if _wRynk then
                    _wRynk("FireServer")
                end
                return _XDqzv(_uJD2B, ...)
            end
            local _I4Ony = _llaZv.Goal
            local _XJACk
            if _llaZv.Sniper ~= nil then
                pcall(function()
                    local _KsR2S = App.pingSpoof.shot()
                    if _KsR2S then
                        _XJACk = table.clone(_llaZv)
                        _XJACk.Sniper = _KsR2S
                    elseif State.Scope.active then
                        local _l3Y60 = App.pingSpoof.eye()
                        local _YjLuP = table.clone(_llaZv.Sniper)
                        local _zKdh6 = _YjLuP.Limbs and _YjLuP.Limbs[1]
                        _YjLuP.Aim = _zKdh6 and CFrame.lookAt(_l3Y60.Position, _zKdh6.Position) or (CFrame.new(_l3Y60.Position) * _l3Y60.Rotation)
                        _XJACk = table.clone(_llaZv)
                        _XJACk.Sniper = _YjLuP
                    end
                end)
            elseif _I4Ony == "SniperAim" and _llaZv.Look ~= nil and Config.Zombie.SniperSilentAim then
                pcall(function()
                    local _WGMG0 = App.pingSpoof.shot()
                    if _WGMG0 then
                        _XJACk = table.clone(_llaZv)
                        _XJACk.Look = _WGMG0.Aim.LookVector
                    end
                end)
            end
            if _I4Ony == "ReportPing" and Config.PingSpoof.Enabled then
                _XJACk = table.clone(_llaZv)
                _XJACk.ms = App.pingSpoof.value()
            elseif Config.DeviceSpoof.Enabled and (_I4Ony == "Platform" or _I4Ony == " Platform " or _I4Ony == "SetPlatform") then
                local _N2nf4, _w4QK1 = App.iconState.flags()
                _XJACk = table.clone(_llaZv)
                if _XJACk.mobile ~= nil then
                    _XJACk.mobile = _N2nf4
                end
                if _XJACk.console ~= nil then
                    _XJACk.console = _w4QK1
                end
            elseif Config.DeviceSpoof.Enabled and Config.DeviceSpoof.Device ~= "Custom Icon" and (_I4Ony == "LeftClick" or _I4Ony == "LeftClickRelease") then
                local _XbXO4, _KVKWP = App.iconState.flags()
                local _ku2oA = _XbXO4 or _KVKWP
                local _Z1gAV = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
                if _Z1gAV then
                    if _llaZv.Mobile ~= true then
                        return
                    end
                    _XJACk = table.clone(_llaZv)
                    if not _ku2oA then
                        _XJACk.Mobile = nil
                    else
                        _XJACk.Mobile = true
                    end
                elseif _ku2oA then
                    _XJACk = table.clone(_llaZv)
                    _XJACk.Mobile = true
                    if _I4Ony == "LeftClick" and Config.DeviceSpoof.TapClicks then
                        task.delay(0.06, function()
                            if not Config.DeviceSpoof.TapClicks then
                                return
                            end
                            if App.triggerM1Click() then
                                return
                            end
                            pcall(function()
                                _uJD2B:FireServer({Goal = "LeftClickRelease", Mobile = true})
                            end)
                        end)
                    end
                end
            end
            if _XJACk then
                local _yeg6a, _LqBdY = {...}, select("#", ...)
                _yeg6a[1] = _XJACk
                if _wRynk then
                    _wRynk("FireServer")
                end
                return _XDqzv(_uJD2B, table.unpack(_yeg6a, 1, _LqBdY))
            end
            if _wRynk then
                _wRynk("FireServer")
            end
            return _XDqzv(_uJD2B, ...)
        end))
        local _wHwsW = shared.SniperShot
        shared.SniperShot = function(...)
            local _XxM8d = _wHwsW and _wHwsW(...)
            local _y5TZl, _JDiR8 = pcall(function()
                if not _RnQ1A5M() then
                    return nil
                end
                return App.pingSpoof.shot() or _XxM8d
            end)
            if _y5TZl and _JDiR8 then
                return _JDiR8
            end
            return _XxM8d
        end
        return true
    end
    App.pingSpoof.loop = function()
        if App.pingSpoof.thread then
            return
        end
        App.pingSpoof.thread = task.spawn(function()
            while Config.PingSpoof.Enabled and not Unloaded do
                local _kU_x0 = _MJSFe
                if _kU_x0 and _kU_x0.Parent then
                    pcall(function()
                        _kU_x0:FireServer({Goal = "ReportPing", ms = App.pingSpoof.value()})
                    end)
                end
                task.wait(Config.PingSpoof.Interval)
            end
            App.pingSpoof.thread = false
        end)
    end
    App.sections.LethalMain:toggle({
        name = "Enabled",
        def = false,
        pointer = "Auto Lethal Enabled",
        callback = function(_v9iG6)
            Config.AutoLethal.Enabled = _v9iG6
        end
    })
    App.sections.LethalMain:toggle({
        name = "Grave Maker",
        def = true,
        pointer = "Auto Lethal Grave",
        tooltip = "also does the tech when Grave Maker (Undying Hero) connects",
        callback = function(_KDURS)
            Config.AutoLethal.Grave = _KDURS
        end
    })
    App.sections.LethalMain:slider({
        name = "Miss Chance",
        def = Config.AutoLethal.MissChance,
        max = 100,
        min = 0,
        rounding = true,
        measurement = "%",
        pointer = "Auto Lethal Miss Chance",
        tooltip = "Chance to miss/skip the lethal tech (0% = always performs tech)",
        callback = function(_l4rjf)
            Config.AutoLethal.MissChance = _l4rjf
        end
    })
    App.sections.LethalMain:keybind({
        name = "Instant Lethal KeyBind",
        def = nil,
        pointer = "Auto Lethal KeyBind",
        callback = function(_wlfHx)
            LethalState.fire()
        end
    })
    App.sections.LethalMain:toggle({
        name = "Highlight Target",
        def = true,
        pointer = "Auto Lethal Highlight",
        callback = function(_XI_rk)
            Config.AutoLethal.Highlight = _XI_rk
        end
    })
    App.sections.LethalMain:colorpicker({
        name = "Highlight Color",
        cpname = "",
        def = Config.AutoLethal.HighlightColor,
        pointer = "Auto Lethal Highlight Color",
        callback = function(_yqbcb)
            Config.AutoLethal.HighlightColor = _yqbcb
        end
    })
    App.sections.LethalTiming:slider({
        name = "Lethal Precision",
        def = 35,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Auto Lethal Precision",
        callback = function(_J5kZQ)
            Config.AutoLethal.Precision = _J5kZQ / 100
        end
    })
    App.sections.LethalTiming:slider({
        name = "Lethal First Flick Angle",
        def = 0,
        max = 360,
        min =-360,
        rounding = true,
        pointer = "Auto Lethal First Flick",
        callback = function(_wdPkn)
            Config.AutoLethal.FirstFlickAngle = _wdPkn
        end
    })
    App.sections.LethalTiming:slider({
        name = "Lethal Second Flick Delay",
        def = 4,
        max = 20,
        min = 0,
        rounding = true,
        pointer = "Auto Lethal Second Flick",
        callback = function(_HVms6)
            Config.AutoLethal.SecondFlick = _HVms6 / 100
        end
    })
    App.sections.LethalTiming:slider({
        name = "Grave Maker Timing",
        def = 0,
        max = 30,
        min =-30,
        rounding = true,
        pointer = "Auto Lethal Grave Timing",
        tooltip = "when the tech starts after Grave Maker connects. minus = earlier, plus = later",
        callback = function(_iLkSj)
            Config.AutoLethal.GraveTiming = _iLkSj / 100
        end
    })
    App.sections.LethalTiming:toggle({
        name = "Lethal Jump",
        def = true,
        pointer = "Auto Lethal Jump",
        callback = function(_Jh3WF)
            Config.AutoLethal.Jump = _Jh3WF
        end
    })
    App.sections.LethalTiming:toggle({
        name = "Lethal Rotate Camera",
        def = false,
        pointer = "Auto Lethal Rotate Camera",
        tooltip = "turns the camera with you during the lethal flicks, not just your character",
        callback = function(_Ucfsf)
            Config.AutoLethal.RotateCam = _Ucfsf
        end
    })
    App.sections.PingSpoof:toggle({
        name = "Enabled",
        def = false,
        pointer = "Ping Spoofer Enabled",
        tooltip = "changes the ping other players see on your profile card / leaderboard. updates on the game's next ping report (within 5s)",
        callback = function(_vH7cW)
            if _vH7cW and not App.pingSpoof.install() then
                Config.PingSpoof.Enabled = false
                _OS0SJ({Title = "ZRHUB", Description = "your executor has no hookmetamethod, ping spoofer can't run"})
                return
            end
            Config.PingSpoof.Enabled = _vH7cW
            if _vH7cW then
                App.pingSpoof.loop()
            end
        end
    })
    App.sections.PingSpoof:slider({
        name = "Ping",
        def = Config.PingSpoof.Ping,
        max = 5000,
        min = 0,
        rounding = true,
        pointer = "Ping Spoofer Ping",
        tooltip = "the ping (ms) that gets reported",
        callback = function(_Kcvo4)
            Config.PingSpoof.Ping = _Kcvo4
        end
    })
    App.sections.PingSpoof:slider({
        name = "Jitter",
        def = Config.PingSpoof.Jitter,
        max = 50,
        min = 0,
        rounding = true,
        pointer = "Ping Spoofer Jitter",
        tooltip = "random +/- ms on every report so it doesn't sit on one number",
        callback = function(_Vij_L)
            Config.PingSpoof.Jitter = _Vij_L
        end
    })
    App.sections.PingSpoof:slider({
        name = "Report Rate (x0.1s)",
        def = math.floor(Config.PingSpoof.Interval * 10),
        max = 50,
        min = 2,
        rounding = true,
        pointer = "Ping Spoofer Rate",
        tooltip = "how often the fake ping is sent. 10 = every 1s, 2 = every 0.2s (the game itself only reports every 5s)",
        callback = function(_wLk4K)
            Config.PingSpoof.Interval = _wLk4K / 10
        end
    })
    App.sections.DeviceSpoof:toggle({
        name = "Enabled",
        def = false,
        pointer = "Device Spoofer Enabled",
        tooltip = "changes the device icon other players see on your profile card / leaderboard",
        callback = function(_Htk9x)
            if _Htk9x and not App.pingSpoof.install() then
                Config.DeviceSpoof.Enabled = false
                _OS0SJ({Title = "ZRHUB", Description = "your executor has no hookmetamethod, device spoofer can't run"})
                return
            end
            Config.DeviceSpoof.Enabled = _Htk9x
            App.iconState.watch(_Htk9x and Config.DeviceSpoof.Device == "Custom Icon")
            if _Htk9x then
                App.iconState.apply()
                App.iconState.repaint()
            else
                App.iconState.restore()
            end
        end
    })
    App.sections.DeviceSpoof:toggle({
        name = "Tap Clicks",
        def = Config.DeviceSpoof.TapClicks,
        pointer = "Device Spoofer Tap Clicks",
        tooltip = "for mobile / console: sends the click release right after each click so it doesnt keep auto hitting. turn it off if you want clicks held like normal",
        callback = function(_id5g5)
            Config.DeviceSpoof.TapClicks = _id5g5
        end
    })
    App.sections.DeviceSpoof:dropdown({
        name = "Device",
        def = Config.DeviceSpoof.Device,
        max = 4,
        options = {"PC", "Mobile", "Console", "Custom Icon"},
        pointer = "Device Spoofer Device",
        callback = function(_JQlyq)
            Config.DeviceSpoof.Device = _JQlyq
            if Config.DeviceSpoof.Enabled then
                App.iconState.watch(_JQlyq == "Custom Icon")
                App.iconState.apply()
                App.iconState.repaint()
            end
        end
    })
    App.sections.DeviceSpoof:textbox({
        name = "Custom Icon",
        def = "",
        placeholder = "id, https link or file",
        pointer = "Device Spoofer Icon",
        tooltip = "used when Device is Custom Icon. asset id (123456), a direct https link to a png (downloaded once), or a file you put in workspace/KittyWare/icons. only YOU see it, other players' screens draw the real icon",
        callback = function(_UINvpd)
            Config.DeviceSpoof.Icon = _UINvpd
            App.iconState.setIcon(_UINvpd)
        end
    })
    App.isMobile = (App.window and App.window.isMobile ~= nil and App.window.isMobile) or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) or (Camera.ViewportSize.X < 900 and UserInputService.TouchEnabled)
    App.optimizeMobile = function()
        if App.window and App.window.optimizemobile then
            App.window:optimizemobile(true)
        end
    end
    App.toggleMobileButton = function(_t3_Qv)
        if App.window and App.window.togglemobilebutton then
            App.window:togglemobilebutton(_t3_Qv)
        end
    end
    if App.isMobile then
        task.defer(function()
            App.optimizeMobile()
            App.toggleMobileButton(true)
        end)
    end
    App.sections.AutoBlockToggle = App.sections.AutoBlock:toggle({
        name = "Enabled",
        def = Config.Autoblock.Enabled,
        pointer = "Auto Block Toggle",
        callback = function(_Z445r)
            Config.Autoblock.Enabled = _Z445r
        end
    })
    App.sections.AutoBlockHold = false
    App.sections.AutoBlockKey = App.sections.AutoBlock:keybind({
        name = "Auto Block Keybind",
        def = nil,
        pointer = "Auto Block Keybind",
        callback = function(_GNcYSSx5)
            if Unloaded then
                return
            end
            local _Bs1cEVQ
            if App.sections.AutoBlockHold then
                _Bs1cEVQ = true
            else
                _Bs1cEVQ = not Config.Autoblock.Enabled
            end
            App.sections.AutoBlockToggle:set(_Bs1cEVQ)
            if not App.sections.AutoBlockHold then
                _OS0SJ({Title = "ZRHUB", Description = "Auto Block " .. (_Bs1cEVQ and "on" or "off"), Source = "Auto Block"})
            end
        end
    })
    App.sections.AutoBlock:toggle({
        name = "Keybind: Hold",
        def = false,
        pointer = "Auto Block Keybind Hold",
        tooltip = "off = the keybind turns auto block on / off. on = auto block is only on while you hold the key",
        callback = function(_cRFQmOKp)
            App.sections.AutoBlockHold = _cRFQmOKp
        end
    })
    connectSignal(ZR_InputEnded, function(_H4H9K)
        if not App.sections.AutoBlockHold or not Config.Autoblock.Enabled then
            return
        end
        local _CsHCpB = App.sections.AutoBlockKey.current
        if not _CsHCpB then
            return
        end
        if (_CsHCpB[1] == "KeyCode" and _H4H9K.KeyCode.Name == _CsHCpB[2]) or (_CsHCpB[1] == "UserInputType" and _H4H9K.UserInputType.Name == _CsHCpB[2]) then
            App.sections.AutoBlockToggle:set(false)
        end
    end)
    App.sections.AutoBlock:toggle({
        name = "Auto m1 Punish",
        def = Config.Autoblock.AutoM1,
        pointer = "AutoM1",
        callback = function(_RSNI01_)
            Config.Autoblock.AutoM1 = _RSNI01_
        end
    })
    App.sections.AutoBlock:toggle({
        name = "Auto Counter",
        def = Config.Autoblock.AutoCounter,
        pointer = "Autocounter",
        callback = function(_wFNTdn6K)
            Config.Autoblock.AutoCounter = _wFNTdn6K
        end
    })
    App.sections.AutoBlock:toggle({
        name = "Dash Prediction",
        def = Config.Autoblock.DashPredict,
        pointer = "Dash Prediction Enabled",
        tooltip = "Blocks when someone's front or side dash is going to bring them into hitting range",
        callback = function(_rgCd5)
            Config.Autoblock.DashPredict = _rgCd5
        end
    })
    App.sections.AutoBlock:slider({
        name = "Auto Block FOV",
        def = 360,
        max = 360,
        min = 0,
        rounding = true,
        measurement = "�",
        pointer = "Autoblock FOV",
        tooltip = "Only blocks people inside this angle in front of you. 360 = all around you",
        callback = function(_W6Rz6)
            Config.Autoblock.FOV = _W6Rz6
        end
    })
    App.sections.AutoBlock:toggle({
        name = "Rotate Character",
        def = Config.Autoblock.RotateChar,
        pointer = "Character Easing Toggle",
        callback = function(_ZSpdp)
            Config.Autoblock.RotateChar = _ZSpdp
        end
    })
    App.sections.AutoBlock:toggle({
        name = "Rotate Camera",
        def = Config.Autoblock.RotateCam,
        pointer = "Cam Easing Toggle",
        callback = function(_UkHN6)
            Config.Autoblock.RotateCam = _UkHN6
        end
    })
    App.sections.AutoBlock:slider({
        name = "Camera Easing",
        def = 0,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Cam Easing",
        callback = function(_z9qBF)
            Config.Autoblock.CamEasing = _z9qBF / 1000
        end
    })
    App.sections.AutoBlock:slider({
        name = "Character Easing",
        def = 100,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Char Easing",
        callback = function(_Oa1Gj)
            Config.Autoblock.CharEasing = _Oa1Gj / 1000
        end
    })
    App.sections.MiscCombat:toggle({
        name = "Friend Check",
        def = Config.Misc.FriendCheck,
        pointer = "Friend Check",
        callback = function(_JV2UQ)
            Config.Misc.FriendCheck = _JV2UQ
        end
    })
    App.sections.MiscCombat:toggle({
        name = "No Dash Endlag",
        def = Config.Misc.NoDashEndLag,
        pointer = "No Dash Endlag",
        tooltip = "Disables the eng lag on end of the dash that doesn't let you to dash again",
        callback = function(_orwb5)
            Config.Misc.NoDashEndLag = _orwb5
        end
    })
    _KjGi0a.stop = function()
        if _KjGi0a.conn then
            _vA5WJ(_KjGi0a.conn)
            _KjGi0a.conn = nil
        end
    end
    _KjGi0a.getTarget = function()
        local _PGbTY = nil
        local _uvqeC = Config.Misc.Magnet.MaxDistance or 100
        if not (Character and RootPart) then
            return nil
        end
        local _p9Mfo = RootPart.Position
        if World and World.Live then
            for _E_uY2, _jNkxH in ipairs(World.Live:GetChildren()) do
                if _jNkxH ~= Character and _jNkxH:IsA("Model") then
                    local _eqqXV = Players:GetPlayerFromCharacter(_jNkxH)
                    if not _JrRW2(_eqqXV, true) then
                        local _h9Ymp = _jNkxH:FindFirstChild("HumanoidRootPart")
                        local _Mu6vO = _jNkxH:FindFirstChildOfClass("Humanoid")
                        if _h9Ymp and _Mu6vO and _Mu6vO.Health > 0 then
                            local _HOhSN = (_p9Mfo - _h9Ymp.Position).Magnitude
                            if _HOhSN < _uvqeC and _HOhSN > 0.1 then
                                _uvqeC = _HOhSN
                                _PGbTY = _h9Ymp
                            end
                        end
                    end
                end
            end
        end
        if not _PGbTY then
            for _m2G7O, _B2zB1 in ipairs(Players:GetPlayers()) do
                if _B2zB1 ~= LocalPlayer and _B2zB1.Character and _B2zB1.Character ~= Character then
                    if not _JrRW2(_B2zB1, true) then
                        local _wnfOo = _B2zB1.Character
                        local _bX57H = _wnfOo:FindFirstChild("HumanoidRootPart")
                        local _CTwSL = _wnfOo:FindFirstChildOfClass("Humanoid")
                        if _bX57H and _CTwSL and _CTwSL.Health > 0 then
                            local _x46_W = (_p9Mfo - _bX57H.Position).Magnitude
                            if _x46_W < _uvqeC and _x46_W > 0.1 then
                                _uvqeC = _x46_W
                                _PGbTY = _bX57H
                            end
                        end
                    end
                end
            end
        end
        return _PGbTY
    end
    _KjGi0a.onStep = function()
        if not Config.Misc.Magnet.Enabled or Unloaded then
            _KjGi0a.stop()
            return
        end
        if not (Character and RootPart and Humanoid and Humanoid.Health > 0) then
            _KjGi0a.stop()
            return
        end
        local _UqWKD = tick() - _KjGi0a.startTime
        if _UqWKD >= _KjGi0a.duration then
            _KjGi0a.stop()
            return
        end
        local _G6iEM = (_KjGi0a.targetOverride and _KjGi0a.targetOverride.Parent and _KjGi0a.targetOverride) or _KjGi0a.getTarget()
        if not _G6iEM then
            return
        end
        local _ZFnAF = RootPart.Position
        local _gKrI1 = Vector3.new(_G6iEM.Position.X, _ZFnAF.Y, _G6iEM.Position.Z)
        local _bgVgX = (_gKrI1 - _ZFnAF)
        local _y0DHc = _bgVgX.Magnitude
        if _y0DHc > 1 then
            _bgVgX = _bgVgX.Unit
            local _BZX2Y = _bgVgX * _KjGi0a.strength
            local _olb0C = RootPart.AssemblyLinearVelocity
            local _H_CTY = _olb0C:Lerp(_BZX2Y, _KjGi0a.smoothness)
            RootPart.AssemblyLinearVelocity = Vector3.new(_H_CTY.X * 0.85, _olb0C.Y, _H_CTY.Z * 0.85)
        end
    end
    _KjGi0a.startPull = function(_O5EQD)
        _KjGi0a.stop()
        _KjGi0a.startTime = tick()
        _KjGi0a.duration = Config.Misc.Magnet.Duration or 0.5
        _KjGi0a.strength = Config.Misc.Magnet.Strength or 50
        _KjGi0a.smoothness = Config.Misc.Magnet.Smoothness or 0.65
        _KjGi0a.targetOverride = _O5EQD
        _KjGi0a.onStep()
        _KjGi0a.conn = connectSignal(RunService.Heartbeat, _KjGi0a.onStep)
    end
    _KjGi0a.execute = function(_hSgF1)
        if not Config.Misc.Magnet.Enabled then
            return
        end
        local _IbRpi = Character or LocalPlayer.Character
        if not _IbRpi then
            return
        end
        local _L0hej = Humanoid or _IbRpi:FindFirstChildOfClass("Humanoid")
        local _iJgJ4 = RootPart or _IbRpi:FindFirstChild("HumanoidRootPart")
        if not (_L0hej and _iJgJ4 and _L0hej.Health > 0 and _IbRpi.Parent) then
            return
        end
        if Config.Misc.Magnet.DashCancel then
            for _RkSt4, _Y5y2t in ipairs(Character:GetChildren()) do
                if _Y5y2t:IsA("BodyVelocity") or _Y5y2t:IsA("LinearVelocity") then
                    _Y5y2t:Destroy()
                end
            end
            for _rTfy7, _qF6Tz in ipairs(RootPart:GetChildren()) do
                if _qF6Tz:IsA("BodyVelocity") or _qF6Tz:IsA("LinearVelocity") then
                    _qF6Tz:Destroy()
                end
            end
            local _JWSmR = RootPart.AssemblyLinearVelocity
            RootPart.AssemblyLinearVelocity = Vector3.new(0, _JWSmR.Y, 0)
        end
        local _QoAYy = (_hSgF1 and _hSgF1.Parent and _hSgF1) or _KjGi0a.getTarget()
        if _QoAYy then
            local _zA4Fg = Config.Misc.Magnet.Height or 2
            local _WRbhB = _QoAYy.Position + Vector3.new(0, _zA4Fg, 0)
            RootPart.CFrame = CFrame.new(_WRbhB.X, _WRbhB.Y, _WRbhB.Z)
            _KjGi0a.startPull(_QoAYy)
        end
    end
    _ViZxv = function(_ZRRaY, _APnkET)
        if not Config.Misc.Magnet.Enabled then
            return
        end
        local _TRhCeua = Config.Misc.Magnet.TechTrigger
        if not _TRhCeua or _TRhCeua == "Disabled" or _TRhCeua == "None" then
            return
        end
        local _aqk8FSHV = false
        if _TRhCeua == "All 3" or _TRhCeua == "All" then
            _aqk8FSHV = (_ZRRaY == "Loop Dash v2" or _ZRRaY == "Custom Dash" or _ZRRaY == "Custom Dash v2")
        else
            _aqk8FSHV = (_ZRRaY == _TRhCeua)
        end
        if _aqk8FSHV then
            task.spawn(function()
                local _tceoH = Config.Misc.Magnet.TechDelay or 0
                if _tceoH > 0 then
                    task.wait(_tceoH / 1000)
                end
                _KjGi0a.execute(_APnkET)
            end)
        end
    end
    App.sections.MiscCombat:toggle({
        name = "Auto Magnet",
        def = Config.Misc.Magnet.Enabled,
        pointer = "Magnet Enabled",
        tooltip = "Teleports above closest target and pulls towards them",
        callback = function(_gI6cQM)
            Config.Misc.Magnet.Enabled = _gI6cQM
            if not _gI6cQM then
                _KjGi0a.stop()
            end
        end
    })
    App.sections.MiscCombat:keybind({
        name = "Magnet Keybind",
        def = nil,
        pointer = "Magnet Keybind",
        tooltip = "Press to activate teleport and magnet pull",
        callback = function(_jNkcGR_)
            _KjGi0a.execute()
        end
    })
    App.sections.MiscCombat:dropdown({
        name = "Tech Trigger",
        def = Config.Misc.Magnet.TechTrigger,
        max = 5,
        options = {"Disabled", "Loop Dash v2", "Custom Dash", "Custom Dash v2", "All 3"},
        pointer = "Magnet Tech Trigger",
        tooltip = "Automatically triggers magnet after selected uppercut tech",
        callback = function(_u69jFDoN)
            Config.Misc.Magnet.TechTrigger = _u69jFDoN
        end
    })
    App.sections.MiscCombat:slider({
        name = "Tech Delay",
        def = Config.Misc.Magnet.TechDelay,
        max = 500,
        min = 0,
        rounding = true,
        measurement = "ms",
        pointer = "Magnet Tech Delay",
        tooltip = "Delay before magnet activates after uppercut hit (0ms = instant on hit)",
        callback = function(_z5YOd)
            Config.Misc.Magnet.TechDelay = _z5YOd
        end
    })
    App.sections.MiscCombat:slider({
        name = "Pull Duration",
        def = math.floor(Config.Misc.Magnet.Duration * 1000),
        max = 2000,
        min = 100,
        rounding = true,
        measurement = "ms",
        pointer = "Magnet Duration",
        tooltip = "Duration of the magnet pull (100ms - 2000ms)",
        callback = function(_snFqFw3I)
            Config.Misc.Magnet.Duration = _snFqFw3I / 1000
        end
    })
    App.sections.MiscCombat:slider({
        name = "TP Height",
        def = Config.Misc.Magnet.Height,
        max = 15,
        min = 0,
        rounding = true,
        measurement = " studs",
        pointer = "Magnet Height",
        tooltip = "Height in studs above target to teleport",
        callback = function(_ZGoLc0I)
            Config.Misc.Magnet.Height = _ZGoLc0I
        end
    })
    App.sections.MiscCombat:slider({
        name = "Pull Strength",
        def = Config.Misc.Magnet.Strength,
        max = 150,
        min = 10,
        rounding = true,
        pointer = "Magnet Strength",
        tooltip = "Strength and velocity of the magnet pull",
        callback = function(_pkyvqIW)
            Config.Misc.Magnet.Strength = _pkyvqIW
        end
    })
    App.sections.MiscCombat:slider({
        name = "Max Distance",
        def = Config.Misc.Magnet.MaxDistance,
        max = 300,
        min = 10,
        rounding = true,
        measurement = " studs",
        pointer = "Magnet Distance",
        tooltip = "Maximum distance to detect targets",
        callback = function(_U8KFA7)
            Config.Misc.Magnet.MaxDistance = _U8KFA7
        end
    })
    App.sections.MiscCombat:toggle({
        name = "Dash Cancel",
        def = Config.Misc.Magnet.DashCancel,
        pointer = "Magnet Dash Cancel",
        tooltip = "Cancels active dash velocity when activating magnet",
        callback = function(_LB2iA)
            Config.Misc.Magnet.DashCancel = _LB2iA
        end
    })
    App.sections.TrueDownSlam:toggle({
        name = "Enabled",
        def = Config.Misc.TDSEnabled,
        pointer = "TDS Enabled",
        callback = function(_mkMLQ)
            Config.Misc.TDSEnabled = _mkMLQ
        end
    })
    App.sections.TrueDownSlam:keybind({
        name = "True Down Slam Jump",
        def = nil,
        pointer = "TDS KeyBind",
        callback = function(_VSVPy)
            if not Config.Misc.TDSEnabled then
                return
            end
            local _QgVbn = Character or LocalPlayer.Character
            if not _QgVbn then
                return
            end
            local _b0iLH = Humanoid or _QgVbn:FindFirstChildOfClass("Humanoid")
            local _GdUbO = RootPart or _QgVbn:FindFirstChild("HumanoidRootPart")
            if not (_b0iLH and _GdUbO and _b0iLH.Health > 0 and _QgVbn.Parent) then
                return
            end
            local _FJKW_ = _QgVbn:FindFirstChild("NoJump")
            if _FJKW_ then
                task.defer(_FJKW_.Destroy, _FJKW_)
            end
            _b0iLH:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.01)
            if _GdUbO and _GdUbO.Parent then
                _GdUbO.Velocity = Vector3.new(_GdUbO.Velocity.X, 35, _GdUbO.Velocity.Z)
            end
            _yu80O()
        end
    })
    App.sections.AutoTech:toggle({
        name = "Enabled",
        def = Config.AutoTech.Enabled,
        pointer = "Auto Tech Toggle",
        callback = function(_knNy6)
            Config.AutoTech.Enabled = _knNy6
        end
    })
    App.sections.AutoTech:dropdown({
        name = "Auto Tech Variant",
        def = Config.AutoTech.Tech,
        max = 7,
        options = {
            "Kiba",
            "Supa",
            "Lock On Dash",
            "Loop Dash",
            "Loop Dash v2",
            "Custom Dash",
            "Custom Dash v2"
        },
        pointer = "Auto Tech Variant",
        callback = function(_jdOQV)
            Config.AutoTech.Tech = _jdOQV
        end
    })
    App.sections.AutoTech:dropdown({
        name = "Auto Tech Method",
        def = Config.AutoTech.Method,
        max = 2,
        options = {"Perform Always", "Perform Once"},
        pointer = "Auto Tech Method",
        callback = function(_eRXTU)
            Config.AutoTech.Method = _eRXTU
        end
    })
    App.sections.AutoTech:slider({
        name = "Miss Chance",
        def = Config.AutoTech.MissChance,
        max = 100,
        min = 0,
        rounding = true,
        measurement = "%",
        pointer = "Auto Tech Miss Chance",
        tooltip = "Chance to miss/skip the uppercut tech (0% = always performs tech)",
        callback = function(_NKZ39)
            Config.AutoTech.MissChance = _NKZ39
        end
    })
    App.sections.AutoTech:dropdown({
        name = "Target Part",
        def = Config.AutoTech.TargetPart,
        max = 3,
        options = {"HumanoidRootPart", "Torso", "Head"},
        pointer = "Auto Tech Target Part",
        tooltip = "What auto tech, custom dash, auto lethal and lock on aim at",
        callback = function(_cJ2_o)
            Config.AutoTech.TargetPart = _cJ2_o
        end
    })
    App.sections.AutoTech:keybind({
        name = "Single Perform Keybind",
        def = Config.AutoTech.PerformOnce,
        pointer = "Single Perform Keybind",
        callback = function(_T9PjQ)
            _xQp2C(_i3Z2l)
            Config.AutoTech.PerformOnce = true
            _OS0SJ({Title = "ZRHUB", Description = "Auto Tech will perform once on the next opportunity.", Image = _SCYz7(LocalPlayer), Source = "Auto Tech"})
            _i3Z2l = task.delay(5, function()
                Config.AutoTech.PerformOnce = false
                _OS0SJ({Title = "ZRHUB", Description = "Auto Tech turned off.", Image = _SCYz7(LocalPlayer), Source = "Auto Tech"})
            end)
        end
    })
    App.sections.TechSettings:slider({
        name = "Loop v2 Precision",
        def = 35,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Precision",
        callback = function(_yYAUw)
            Config.AutoTech.Loopv2.Precision = _yYAUw / 100
        end
    })
    App.sections.TechSettings:slider({
        name = "Loop v2 First Flick Angle",
        def = 0,
        max = 360,
        min =-360,
        rounding = true,
        pointer = "1 Flick Delay",
        callback = function(_dc_DC)
            Config.AutoTech.Loopv2.FirstFlickAngle = _dc_DC
        end
    })
    App.sections.TechSettings:slider({
        name = "Loop v2 Second Flick Delay",
        def = 5,
        max = 50,
        min = 0,
        rounding = true,
        pointer = "Flick Delay",
        callback = function(_Iy311)
            Config.AutoTech.Loopv2.SecondFlick = _Iy311 / 100
        end
    })
    App.sections.TechSettings:toggle({
        name = "Loop v2 Jump",
        def = Config.AutoTech.Loopv2.Jump,
        pointer = "Loop Jump",
        callback = function(_zuYWq)
            Config.AutoTech.Loopv2.Jump = _zuYWq
        end
    })
    App.sections.TechSettings:toggle({
        name = "Loop v2 Rotate Camera",
        def = Config.AutoTech.Loopv2.RotateCam,
        pointer = "Loop Rotate Camera",
        callback = function(_Ow03q)
            Config.AutoTech.Loopv2.RotateCam = _Ow03q
        end
    })
    App.sections.TechSettings:slider({
        name = "Lockon Dash Precision",
        def = 100,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Lockon Precision",
        callback = function(_x2R7K)
            Config.AutoTech.LockonPrecision = _x2R7K / 1000
        end
    })
    App.sections.TechSettings:toggle({
        name = "Supa Uses Heartbeat",
        def = false,
        pointer = "Supa Method",
        tooltip = "Uses more smooth method for Supa",
        callback = function(_srmpj)
            if _srmpj then
                Config.AutoTech.SupaMethod = "Heartbeat"
            else
                Config.AutoTech.SupaMethod = "RenderStepped"
            end
        end
    })
    App.sections.TechSettings:toggle({
        name = "Loop Dash Looks Up",
        def = false,
        pointer = "Loop Dash Looks Up",
        tooltip = "Makes the loop dash look up so it lands 95% of the time, looks unlegit",
        callback = function(_ryeRe)
            Config.AutoTech.LoopDashLooksUp = _ryeRe
        end
    })
    App.sections.CustomDash:toggle({
        name = "Jump",
        def = Config.AutoTech.Customdash.Jump,
        pointer = "Custom Dash Jump",
        callback = function(_WbkZD)
            Config.AutoTech.Customdash.Jump = _WbkZD
        end
    })
    App.sections.CustomDash:toggle({
        name = "Rotate Camera",
        def = Config.AutoTech.Customdash.RotateCam,
        pointer = "Custom Dash Rotate Camera",
        callback = function(_VBroB)
            Config.AutoTech.Customdash.RotateCam = _VBroB
        end
    })
    App.sections.CustomDash:slider({
        name = "First Flick Angle",
        def = 0,
        max = 360,
        min =-360,
        rounding = true,
        pointer = "Custom Dash First Flick Angle",
        tooltip = "Angle in degrees (-360 to 360). Drag or click box to type",
        callback = function(_wYKZ7)
            Config.AutoTech.Customdash.StartFlickAngle = _wYKZ7
            Config.AutoTech.Customdash.FirstFlickAngle = _wYKZ7
        end
    })
    App.sections.CustomDash:slider({
        name = "Second Flick Delay",
        def = 5,
        max = 50,
        min = 0,
        rounding = true,
        pointer = "Custom Dash Second Flick Delay",
        tooltip = "Delay for second flick. Drag or click box to type",
        callback = function(_lSYMz)
            Config.AutoTech.Customdash.SecondFlickDelay = _lSYMz / 100
        end
    })
    App.sections.CustomDash:slider({
        name = "Second Flick Angle",
        def = 0,
        max = 360,
        min =-360,
        rounding = true,
        pointer = "Custom Dash Second Flick Angle",
        tooltip = "Angle in degrees (-360 to 360). Drag or click box to type",
        callback = function(_q31km)
            Config.AutoTech.Customdash.SecondFlickAngle = _q31km
        end
    })
    App.sections.CustomDash:slider({
        name = "Third Flick Delay",
        def = 5,
        max = 50,
        min = 0,
        rounding = true,
        pointer = "Custom Dash Third Flick Delay",
        tooltip = "Delay for third flick. Drag or click box to type",
        callback = function(_H71NM)
            Config.AutoTech.Customdash.ThirdFlickDelay = _H71NM / 100
        end
    })
    App.sections.CustomDash:slider({
        name = "Third Flick Angle",
        def = 0,
        max = 360,
        min =-360,
        rounding = true,
        pointer = "Custom Dash Third Flick Angle",
        tooltip = "Angle in degrees (-360 to 360). Drag or click box to type",
        callback = function(_g2W5o)
            Config.AutoTech.Customdash.ThirdFlickAngle = _g2W5o
        end
    })
    App.sections.CustomDash:toggle({
        name = "Lock On",
        def = Config.AutoTech.Customdash.LockOn,
        pointer = "Custom Dash Lock On",
        callback = function(_pT4Q2)
            Config.AutoTech.Customdash.LockOn = _pT4Q2
        end
    })
    App.sections.CustomDash:dropdown({
        name = "Lock On After",
        def = Config.AutoTech.Customdash.LockOnAfter,
        max = 2,
        options = {"Second Flick", "Third Flick"},
        pointer = "Custom Dash Lock On After",
        callback = function(_KFGqw)
            Config.AutoTech.Customdash.LockOnAfter = _KFGqw
        end
    })
    App.sections.CustomDash:slider({
        name = "Lock On Precision",
        def = 100,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Custom Dash Lock On Precision",
        callback = function(_sWXnE)
            Config.AutoTech.Customdash.LockOnPrecision = _sWXnE / 1000
        end
    })
    App.sections.CustomDash:slider({
        name = "Lock On Delay",
        def = 0,
        max = 10,
        min = 0,
        rounding = true,
        pointer = "Custom Dash Lock On Delay",
        callback = function(_LcYMh)
            Config.AutoTech.Customdash.LockOnDelay = _LcYMh / 100
        end
    })
    App.sections.CustomDashv2:toggle({
        name = "Jump",
        def = Config.AutoTech.Customdashv2.Jump,
        pointer = "Custom Dash v2 Jump",
        callback = function(_W8a5x)
            Config.AutoTech.Customdashv2.Jump = _W8a5x
        end
    })
    App.sections.CustomDashv2:toggle({
        name = "Rotate Camera",
        def = Config.AutoTech.Customdashv2.RotateCam,
        pointer = "Custom Dash v2 Rotate Camera",
        callback = function(_RqhkT)
            Config.AutoTech.Customdashv2.RotateCam = _RqhkT
        end
    })
    App.sections.CustomDashv2:slider({
        name = "First Flick Angle",
        def = Config.AutoTech.Customdashv2.StartFlickAngle,
        max = 360,
        min =-360,
        rounding = true,
        pointer = "Custom Dash v2 First Flick Angle",
        tooltip = "Angle in degrees (-360 to 360). Drag or click box to type",
        callback = function(_kJGB4)
            Config.AutoTech.Customdashv2.StartFlickAngle = _kJGB4
        end
    })
    App.sections.CustomDashv2:slider({
        name = "Second Flick Delay",
        def = Config.AutoTech.Customdashv2.SecondFlickDelay,
        max = 50,
        min = 0,
        rounding = true,
        pointer = "Custom Dash v2 Second Flick Delay",
        tooltip = "Delay for second flick. Drag or click box to type",
        callback = function(_nxW4Y)
            Config.AutoTech.Customdashv2.SecondFlickDelay = _nxW4Y / 100
        end
    })
    App.sections.CustomDashv2:slider({
        name = "Second Flick Duration",
        def = Config.AutoTech.Customdashv2.SecondFlickDuration,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Custom Dash v2 Second Flick Duration",
        tooltip = "Duration to turn camera. Drag or click box to type",
        callback = function(_elm63)
            Config.AutoTech.Customdashv2.SecondFlickDuration = _elm63 / 100
        end
    })
    App.sections.CustomDashv2:slider({
        name = "Second Flick Angle",
        def = Config.AutoTech.Customdashv2.SecondFlickAngle,
        max = 360,
        min =-360,
        rounding = true,
        pointer = "Custom Dash v2 Second Flick Angle",
        tooltip = "Angle in degrees (-360 to 360). Drag or click box to type",
        callback = function(_xOpEe)
            Config.AutoTech.Customdashv2.SecondFlickAngle = _xOpEe
        end
    })
    App.sections.CustomDashv2:slider({
        name = "Third Flick Delay",
        def = Config.AutoTech.Customdashv2.ThirdFlickDelay,
        max = 50,
        min = 0,
        rounding = true,
        pointer = "Custom Dash v2 Third Flick Delay",
        tooltip = "Delay for third flick. Drag or click box to type",
        callback = function(_ACJXw)
            Config.AutoTech.Customdashv2.ThirdFlickDelay = _ACJXw / 100
        end
    })
    App.sections.CustomDashv2:slider({
        name = "Third Flick Duration",
        def = Config.AutoTech.Customdashv2.ThirdFlickDuration,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Custom Dash v2 Third Flick Duration",
        tooltip = "Duration to turn camera. Drag or click box to type",
        callback = function(_TZ4kK)
            Config.AutoTech.Customdashv2.ThirdFlickDuration = _TZ4kK / 100
        end
    })
    App.sections.CustomDashv2:slider({
        name = "Third Flick Angle",
        def = Config.AutoTech.Customdashv2.ThirdFlickAngle,
        max = 360,
        min =-360,
        rounding = true,
        pointer = "Custom Dash v2 Third Flick Angle",
        tooltip = "Angle in degrees (-360 to 360). Drag or click box to type",
        callback = function(_yHKpd)
            Config.AutoTech.Customdashv2.ThirdFlickAngle = _yHKpd
        end
    })
    App.sections.CustomDashv2:toggle({
        name = "Lock On",
        def = Config.AutoTech.Customdashv2.LockOn,
        pointer = "Custom Dash v2 Lock On",
        callback = function(_BIr7S)
            Config.AutoTech.Customdashv2.LockOn = _BIr7S
        end
    })
    App.sections.CustomDashv2:dropdown({
        name = "Lock On After",
        def = Config.AutoTech.Customdashv2.LockOnAfter,
        max = 2,
        options = {"Second Flick", "Third Flick"},
        pointer = "Custom Dash v2 Lock On After",
        callback = function(_UsjQZ)
            Config.AutoTech.Customdashv2.LockOnAfter = _UsjQZ
        end
    })
    App.sections.CustomDashv2:slider({
        name = "Lock On Precision",
        def = 100,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Custom Dash v2 Lock On Precision",
        tooltip = "Lock on precision percentage. Drag or click box to type",
        callback = function(_DxAzj)
            Config.AutoTech.Customdashv2.LockOnPrecision = _DxAzj / 1000
        end
    })
    App.sections.CustomDashv2:slider({
        name = "Lock On Delay",
        def = 0,
        max = 10,
        min = 0,
        rounding = true,
        pointer = "Custom Dash v2 Lock On Delay",
        tooltip = "Lock on delay. Drag or click box to type",
        callback = function(_OCJ8I)
            Config.AutoTech.Customdashv2.LockOnDelay = _OCJ8I / 100
        end
    })
    App.sections.Tech:toggle({
        name = "Enabled",
        def = Config.Macro.TechHelper.Enabled,
        pointer = "Tech Helper Toggle",
        callback = function(_hw6qK)
            Config.Macro.TechHelper.Enabled = _hw6qK
        end
    })
    App.sections.Tech:dropdown({
        name = "Tech Helper Variant",
        def = Config.Macro.TechHelper.Tech,
        max = 5,
        options = {"Humbled Twisted", "Loop Dash", "Instant Lee", "Oreo Tech", "Lix Tech"},
        pointer = "Tech Helper Variant",
        callback = function(_c5YkrswS)
            Config.Macro.TechHelper.Tech = _c5YkrswS
        end
    })
    App.sections.Tech:keybind({
        name = "Tech Helper KeyBind",
        def = nil,
        pointer = "Tech Helper KeyBind",
        tooltip = "Press on third m1",
        callback = function(_vk8n6d8)
            if not Config.Macro.TechHelper.Enabled or Config.Macro.TechHelper.Tech == "" then
                return
            end
            local _GTEoIq = _fwJeEv6(0.36)
            if Config.Macro.TechHelper.Tech == "Humbled Twisted" then
                _yu80O()
                task.wait(_GTEoIq[1] - 0.05)
                _XjK2G()
                task.wait(0.075 - _GTEoIq[2])
                _pN7KD(-90, 0.1)
                task.wait(0.1)
                _pN7KD(180, 0.1)
                task.wait(0.125)
                _pN7KD(-90, 0.1)
            elseif Config.Macro.TechHelper.Tech == "Loop Dash" then
                _y_W2U()
                task.wait(_GTEoIq[1])
                _XjK2G()
                _GcDR2(45)
                _pN7KD(340, 0.4 - _GTEoIq[2])
            elseif Config.Macro.TechHelper.Tech == "Instant Lee" then
                _yu80O()
                task.wait(_GTEoIq[1] - 0.05)
                _XjK2G()
                task.wait(_GTEoIq[2])
                _GcDR2(145)
                task.wait(0.075 + _GTEoIq[2])
                _pN7KD(-175, 0.1)
            elseif Config.Macro.TechHelper.Tech == "Oreo Tech" then
                _y_W2U()
                task.wait(_GTEoIq[1])
                _GcDR2(180)
                _XjK2G()
                task.wait(0.18 + _GTEoIq[2])
                _GcDR2(180)
            elseif Config.Macro.TechHelper.Tech == "Lix Tech" then
                _y_W2U()
                task.wait(_GTEoIq[1])
                _XjK2G()
                task.wait(0.16 + _GTEoIq[2])
                _GcDR2(180)
            end
        end
    })
    App.sections.Tech:toggle({
        name = "Enabled",
        def = Config.Macro.ExtraTechHelper.Enabled,
        pointer = "Extra Tech Toggle",
        callback = function(_pttvw)
            Config.Macro.ExtraTechHelper.Enabled = _pttvw
        end
    })
    App.sections.Tech:keybind({
        name = "Extra Tech Helper",
        def = nil,
        pointer = "Extra Tech Helper",
        tooltip = "For Instant Lethal Press Keybind when you want to press second move, for materia tech switch to saitama and after landing 3m1s come closer to enemy and press keybind with a bit delay",
        callback = function(_IbjxSQ4H)
            if not Config.Macro.ExtraTechHelper.Enabled or Config.Macro.ExtraTechHelper.Tech == "" then
                return
            end
            local _LbWwK8s = nil
            local _qlnKrk = Character and Character:GetAttribute("LastM1Hitted")
            if _qlnKrk then
                local _r8u4_ = _qlnKrk:match("^(.-);;")
                if _r8u4_ then
                    _LbWwK8s = World.Live:FindFirstChild(_r8u4_)
                end
            end
            if not _LbWwK8s then
                _LbWwK8s = LethalState.getTarget(35)
            end
            if Config.Macro.ExtraTechHelper.Tech == "Instant Lethal Shift Lock" then
                local _ojtOE2BN = _fwJeEv6(2.2)
                local _VAJlfGI = LethalState.elapsed()
                if _VAJlfGI then
                    task.wait(math.max(0, _ojtOE2BN[1] - _VAJlfGI))
                else
                    setAutoRotate(Enum.KeyCode.Two)
                    task.wait(_ojtOE2BN[1])
                end
                pressKey(KeySpace)
                _XjK2G()
                task.wait(0.18 + _ojtOE2BN[2])
                _GcDR2(180)
                releaseKey(KeySpace)
            elseif Config.Macro.ExtraTechHelper.Tech == "Instant Lethal Loop Dash" then
                local _eeP_5M = _fwJeEv6(2.2)
                local _bbxLw = LethalState.elapsed()
                if _bbxLw then
                    task.wait(math.max(0, _eeP_5M[1] - _bbxLw))
                else
                    setAutoRotate(Enum.KeyCode.Two)
                    task.wait(_eeP_5M[1])
                end
                pressKey(KeySpace)
                _XjK2G()
                task.wait(0.05 - _eeP_5M[2])
                _GcDR2(45)
                _pN7KD(275, 0.25)
                releaseKey(KeySpace)
            elseif Config.Macro.ExtraTechHelper.Tech == "Materia Tech" then
                if not _LbWwK8s then
                    return
                end
                local _IqBcIucv = _LbWwK8s:FindFirstChild("HumanoidRootPart")
                if not _IqBcIucv then
                    return
                end
                local _NCpOy = RunService.Heartbeat:Connect(function()
                    _GcDR2(nil, _WpfDds2D.pos(_IqBcIucv))
                end)
                setAutoRotate(Enum.KeyCode.Three)
                task.wait(0.64)
                pressKey(KeyD)
                task.wait(0.005)
                _vA5WJ(_NCpOy)
                _GcDR2(90)
                tapKey(KeyQ)
                releaseKey(KeyD)
                _yu80O()
            end
        end
    })
    App.sections.Tech:dropdown({
        name = "Extra Tech Variant",
        def = Config.Macro.ExtraTechHelper.Tech ~= "" and Config.Macro.ExtraTechHelper.Tech or "Instant Lethal Shift Lock",
        max = 3,
        options = {"Instant Lethal Shift Lock", "Instant Lethal Loop Dash", "Materia Tech"},
        pointer = "Extra Tech Helper Variant",
        callback = function(_CwAna)
            Config.Macro.ExtraTechHelper.Tech = _CwAna
        end
    })
    App.sections.TrueM1Reset:toggle({
        name = "Enabled",
        def = false,
        pointer = "True M1 Reset Toggle",
        callback = function(_j5cTg)
            Config.Macro.m1ResetEnabled = _j5cTg
        end
    })
    App.sections.TrueM1Reset:keybind({
        name = "M1 Reset KeyBind",
        def = nil,
        pointer = "M1 Reset Keybind",
        tooltip = "Press a keybind when you have side dash and front dash after second m1.",
        callback = function(_vQCq3)
            if not Config.Macro.m1ResetEnabled then
                return
            end
            local _iys4Z = _fwJeEv6(0.28)[1]
            _yu80O()
            task.wait(_iys4Z)
            _GcDR2(-90)
            pressKey(KeyD)
            tapKey(KeyQ)
            task.wait(_iys4Z)
            releaseKey(KeyD)
            _GcDR2(90)
            _XjK2G()
        end
    })
    App.sections.EmoteDash:toggle({
        name = "Enabled",
        def = false,
        pointer = "Emote Dash Toggle",
        callback = function(_dbxcz)
            Config.Macro.EmoteDash.Enabled = _dbxcz
        end
    })
    App.sections.EmoteDash:keybind({
        name = "Emote Dash KeyBind",
        def = nil,
        pointer = "Emote Dash KeyBind",
        callback = function(_wlyg6)
            if not Config.Macro.EmoteDash.Enabled or not (Humanoid and RootPart and Humanoid.Health > 0) then
                return
            end
            releaseKey(KeyW)
            releaseKey(KeyS)
            if Config.Macro.EmoteDash.Type == "Straight" then
                _GcDR2(90)
            end
            if Config.Macro.EmoteDash.Type == "Straight" or Config.Macro.EmoteDash.Type == "Right" then
                pressKey(KeyD)
            elseif Config.Macro.EmoteDash.Type == "Left" then
                pressKey(KeyA)
            end
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.005)
            tapKey(KeyQ)
            task.wait(Config.Macro.EmoteDash.Delay)
            local _j5LFO = RootPart:FindFirstChild("dodgevelocity")
            if _j5LFO then
                _j5LFO:Destroy()
                _ZGKm8(_j089A.rsideDash)
                _ZGKm8(_j089A.lsideDash)
            end
            releaseKey(KeyD)
            releaseKey(KeyA)
            if Config.Macro.EmoteDash.Type == "Straight" then
                _GcDR2(-90)
            end
        end
    })
    App.sections.EmoteDash:textbox({
        name = "Emote Dash Delay",
        def = Config.Macro.EmoteDash.Delay,
        placeholder = "",
        pointer = "Emote Dash Delay",
        callback = function(_WOYl4)
            Config.Macro.EmoteDash.Delay = math.clamp(tonumber(_WOYl4) or 0.05, 0, 1)
        end
    })
    App.sections.EmoteDash:dropdown({
        name = "Emote Dash Type",
        def = Config.Macro.EmoteDash.Type,
        max = 3,
        options = {"Right", "Left", "Straight"},
        pointer = "Emote Dash Type",
        callback = function(_lPwb_)
            Config.Macro.EmoteDash.Type = _lPwb_
        end
    })
    App.sections.BackdashCancel:keybind({
        name = "Backdash Cancel 1",
        def = nil,
        pointer = "Backdash Cancel 1 Keybind",
        callback = function(_YyjAF)
            if not Config.Macro.BackDashCancel1.Enabled then
                return
            end
            App.execBackDash(Enum.KeyCode.One)
        end
    })
    App.sections.BackdashCancel:toggle({
        name = "Enabled",
        def = false,
        pointer = "Backdash Cancel 1 Enabled",
        callback = function(_L6jE2)
            Config.Macro.BackDashCancel1.Enabled = _L6jE2
        end
    })
    App.sections.BackdashCancel:keybind({
        name = "Backdash Cancel 2",
        def = nil,
        pointer = "Backdash Cancel 2 Keybind",
        callback = function(_yPwfR)
            if not Config.Macro.BackDashCancel2.Enabled then
                return
            end
            App.execBackDash(Enum.KeyCode.Two)
        end
    })
    App.sections.BackdashCancel:toggle({
        name = "Enabled",
        def = false,
        pointer = "Backdash Cancel 2 Enabled",
        callback = function(_BJkeF)
            Config.Macro.BackDashCancel2.Enabled = _BJkeF
        end
    })
    App.sections.BackdashCancel:keybind({
        name = "Backdash Cancel 3",
        def = nil,
        pointer = "Backdash Cancel 3 Keybind",
        callback = function(_ocgFW)
            if not Config.Macro.BackDashCancel3.Enabled then
                return
            end
            App.execBackDash(Enum.KeyCode.Three)
        end
    })
    App.sections.BackdashCancel:toggle({
        name = "Enabled",
        def = false,
        pointer = "Backdash Cancel 3 Enabled",
        callback = function(_bsvCB)
            Config.Macro.BackDashCancel3.Enabled = _bsvCB
        end
    })
    App.sections.BackdashCancel:keybind({
        name = "Backdash Cancel 4",
        def = nil,
        pointer = "Backdash Cancel 4 Keybind",
        callback = function(_ie4sF)
            if not Config.Macro.BackDashCancel4.Enabled then
                return
            end
            App.execBackDash(Enum.KeyCode.Four)
        end
    })
    App.sections.BackdashCancel:toggle({
        name = "Enabled",
        def = false,
        pointer = "Backdash Cancel 4 Enabled",
        callback = function(_dILlu)
            Config.Macro.BackDashCancel4.Enabled = _dILlu
        end
    })
    App.sections.VisualMain:toggle({
        name = "No Textures",
        def = false,
        pointer = "No Textures",
        tooltip = "Changes map materials to Plastic for maximum FPS without breaking trees, effects, or ult moves",
        callback = function(_Q0A2y)
            _meXJ9 = _Q0A2y
            _CperF(false, _Q0A2y)
        end
    })
    App.sections.VisualMain:button({
        name = "Update No Textures List",
        callback = function()
            _CperF(true, _meXJ9)
        end
    })
    App.sections.VisualMain:toggle({
        name = "No Shadows",
        def = false,
        pointer = "No Shadows",
        callback = function(_jQAgZ)
            App.applyVisualToggle("Visuals.NoShadows", "NoGShadows", _jQAgZ)
        end
    })
    App.sections.VisualMain:toggle({
        name = "No Smoke",
        def = false,
        pointer = "No Smoke",
        callback = function(_Wuhkd)
            App.applyVisualToggle("Visuals.NoSmoke", "No Smoke", _Wuhkd)
        end
    })
    App.sections.VisualMain:toggle({
        name = "No Rings",
        def = false,
        pointer = "No Rings",
        callback = function(_RFIYW)
            App.applyVisualToggle("Visuals.NoRings", "No Rings", _RFIYW)
        end
    })
    App.sections.VisualMain:toggle({
        name = "No Capes",
        def = false,
        pointer = "No Capes",
        callback = function(_YKcD7)
            App.applyVisualToggle("Visuals.NoCapes", "No Capes", _YKcD7)
        end
    })
    App.sections.VisualMain:toggle({
        name = "No Auras",
        def = false,
        pointer = "No Auras",
        callback = function(_lP1_C)
            App.applyVisualToggle("Visuals.NoAuras", "No Auras", _lP1_C)
        end
    })
    App.sections.VisualMain:toggle({
        name = "No Garou After Images",
        def = false,
        pointer = "No Garou After Images",
        callback = function(_yhCme)
            App.applyVisualToggle("Visuals.NoGarouC", "No Garou Clones", _yhCme)
        end
    })
    App.sections.VisualMain:toggle({
        name = "No New Light",
        def = false,
        pointer = "No New Light",
        callback = function(_vJeet)
            App.applyVisualToggle("Visuals.NoNewLight", "No New Light", _vJeet)
        end
    })
    App.sections.VisualMain:slider({
        name = "Saturation",
        def = 0,
        max = 200,
        min = 0,
        rounding = true,
        pointer = "Saturation",
        callback = function(_IP_mu)
            State.saturation = _IP_mu / 100
            _IeaiYt2E(_uMouq, "Saturation", _IP_mu / 100)
        end
    })
    State.reapplyLook = function(_Vnv_j)
        for _i6Gs4, _T8LBr in ipairs({0.5, 1.5, 3}) do
            task.wait(_T8LBr)
            if Unloaded or Character ~= _Vnv_j then
                return
            end
            pcall(function()
                if not (_uMouq and _uMouq.Parent) then
                    _uMouq = Lighting:FindFirstChild("ColorCorrection") or Instance.new("ColorCorrectionEffect")
                    _uMouq.Name = "ColorCorrection"
                    _uMouq.Parent = Lighting
                end
                if State.saturation and _uMouq.Saturation ~= State.saturation then
                    _uMouq.Saturation = State.saturation
                end
                local _gEvh5 = workspace.CurrentCamera
                if _gEvh5 and Config.Visuals.FOV and _gEvh5.FieldOfView ~= Config.Visuals.FOV then
                    _gEvh5.FieldOfView = Config.Visuals.FOV
                end
                if Config.Visuals.NoShadows and Lighting.GlobalShadows then
                    Lighting.GlobalShadows = false
                end
                for _togkL, _aJnVs in ipairs(_Vnv_j:GetDescendants()) do
                    onDescendantAdded(_aJnVs)
                end
            end)
        end
    end
    App.sections.VisualMain:slider({
        name = "FOV",
        def = 70,
        max = 120,
        min = 1,
        rounding = true,
        pointer = "FOV",
        callback = function(_fmJle)
            Config.Visuals.FOV = _fmJle
            _IeaiYt2E(Camera, "FieldOfView", _fmJle)
        end
    })
    App.sections.VisualMain:toggle({
        name = "Motion Blur",
        def = false,
        pointer = "Motion Blur Toggle",
        tooltip = "Adds smooth dynamic motion blur when rotating camera or moving fast",
        callback = function(_s6woD)
            App.applyVisualToggle("Visuals.MotionBlur.Enabled", "MotionBlur", _s6woD)
        end
    })
    App.sections.VisualMain:slider({
        name = "Motion Blur Intensity",
        def = 10,
        max = 30,
        min = 1,
        rounding = true,
        pointer = "Motion Blur Intensity",
        tooltip = "Intensity of motion blur during camera rotation",
        callback = function(_m3xEQ)
            Config.Visuals.MotionBlur.Intensity = _m3xEQ
        end
    })
    App.sections.VisualESP:toggle({
        name = "Enabled",
        def = false,
        pointer = "ESP Toggle",
        callback = function(_xXYrE)
            App.applyVisualToggle("Visuals.ESP.Enabled", "ESP", _xXYrE)
        end
    })
    App.sections.VisualESP:toggle({
        name = "Highlight",
        def = true,
        pointer = "ESP Highlight Toggle",
        tooltip = "the colored fill over the player. turn it off for boxes / text only",
        callback = function(_EGoaw)
            App.applyVisualToggle("Visuals.ESP.Highlight", "HighlightESP", _EGoaw)
        end
    })
    App.sections.VisualESP:toggle({
        name = "Boxes ESP",
        def = false,
        pointer = "Boxes ESP Toggle",
        callback = function(_HYjFp)
            Config.Visuals.ESP.Boxes = _HYjFp
            App.applyVisualToggle("Visuals.ESP.Boxes", "BoxesESP", _HYjFp)
        end
    })
    App.sections.VisualESP:toggle({
        name = "Box Team/Enemy Color",
        def = true,
        pointer = "Box Team Color Toggle",
        callback = function(_WfJNd)
            Config.Visuals.ESP.BoxUseESPColor = _WfJNd
            _aKxqPdSj(false, false)
        end
    })
    App.sections.VisualESP:colorpicker({
        name = "Box Custom Color",
        cpname = "",
        def = Config.Visuals.ESP.BoxColor,
        pointer = "Box Custom Color",
        callback = function(_hewfP)
            Config.Visuals.ESP.BoxColor = _hewfP
            _aKxqPdSj(false, false)
        end
    })
    App.sections.VisualESP:slider({
        name = "Box Thickness",
        def = 1,
        max = 6,
        min = 1,
        rounding = true,
        pointer = "Box Line Thickness",
        tooltip = "line width of the 2D box in pixels",
        callback = function(_UHPt7)
            Config.Visuals.ESP.BoxThickness = _UHPt7
            _aKxqPdSj(false, false)
        end
    })
    App.sections.VisualESP:toggle({
        name = "Box Filled",
        def = false,
        pointer = "Box Filled Toggle",
        callback = function(_fZKxJ)
            Config.Visuals.ESP.BoxFilled = _fZKxJ
            _aKxqPdSj(false, false)
        end
    })
    App.sections.VisualESP:colorpicker({
        name = "Friend Color",
        cpname = "",
        def = Config.Visuals.ESP.FriendColor,
        pointer = "Friend Color",
        callback = function(_ueeFf)
            Config.Visuals.ESP.FriendColor = _ueeFf
            _aKxqPdSj(false, false)
        end
    })
    App.sections.VisualESP:colorpicker({
        name = "Enemy Color",
        cpname = "",
        def = Config.Visuals.ESP.EnemyColor,
        pointer = "Enemy Color",
        callback = function(_Fjh2l)
            Config.Visuals.ESP.EnemyColor = _Fjh2l
            _aKxqPdSj(false, false)
        end
    })
    App.sections.VisualESP:colorpicker({
        name = "Neutral Color",
        cpname = "",
        def = Config.Visuals.ESP.NeutralColor,
        pointer = "Neutral Color",
        callback = function(_gsu20)
            Config.Visuals.ESP.NeutralColor = _gsu20
            _aKxqPdSj(false, false)
        end
    })
    App.sections.VisualESP:colorpicker({
        name = "Ultimate Color",
        cpname = "",
        def = Config.Visuals.ESP.UltColor,
        pointer = "Ultimate Color",
        callback = function(_raieswU)
            Config.Visuals.ESP.UltColor = _raieswU
            _aKxqPdSj(false, false)
        end
    })
    App.sections.VisualESP:colorpicker({
        name = "Saitama Ultimate Color",
        cpname = "",
        def = Config.Visuals.ESP.SaitamaUltColor,
        pointer = "Saitama Ultimate Color",
        callback = function(_G2Cg7G)
            Config.Visuals.ESP.SaitamaUltColor = _G2Cg7G
            _aKxqPdSj(false, false)
        end
    })
    App.sections.VisualESP:colorpicker({
        name = "Death Counter Color",
        cpname = "",
        def = Config.Visuals.ESP.DeathCounterColor,
        pointer = "Death Counter Color",
        callback = function(_xTYZe)
            Config.Visuals.ESP.DeathCounterColor = _xTYZe
            _aKxqPdSj(false, false)
        end
    })
    App.sections.VisualESP:slider({
        name = "Outline Transparency",
        def = 70,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Outline Transparency",
        callback = function(_Epgj7A6C)
            Config.Visuals.ESP.OutlineTransparency = _Epgj7A6C / 100
            _aKxqPdSj(false, false)
        end
    })
    App.sections.VisualESP:toggle({
        name = "Death Counter ESP",
        def = false,
        pointer = "Death Counter Without ESP",
        callback = function(_P8FjwE9)
            Config.Visuals.ESP.DeathCounterESP = _P8FjwE9
        end
    })
    App.sections.VisualESP:toggle({
        name = "Saitama Ult ESP",
        def = false,
        pointer = "Saitama Ult Without ESP",
        callback = function(_WxmIzoT3)
            Config.Visuals.ESP.SaitamaUltESP = _WxmIzoT3
        end
    })
    App.sections.VisualESP:toggle({
        name = "Name & Ult Text",
        def = true,
        pointer = "ESP Text Toggle",
        tooltip = "the big text above players (character, ult % and name). its own option, works with or without the highlight and boxes",
        callback = function(_TGQJX)
            App.applyVisualToggle("Visuals.ESP.NoBillboards", "NoBillboards", not _TGQJX)
        end
    })
    App.sections.VisualESP:keybind({
        name = "Add Friend/Enemy Keybind",
        def = nil,
        pointer = "Add Friend Keybind",
        callback = function(_MOlpHs)
            local _V07EYuS = Mouse.Target
            if not _V07EYuS then
                return
            end
            local _GyNA41jH = _V07EYuS:FindFirstAncestorOfClass("Model")
            if not _GyNA41jH or not _GyNA41jH:FindFirstChildOfClass("Humanoid") then
                return
            end
            local _vFfz1 = Players:FindFirstChild(_GyNA41jH.Name)
            if not _vFfz1 then
                return
            end
            if not PlayerFrames[_vFfz1.Name] then
                PlayerFrames[_vFfz1.Name] = "Neutral"
            end
            if PlayerFrames[_vFfz1.Name] == "Friend" then
                PlayerFrames[_vFfz1.Name] = "Neutral"
            elseif PlayerFrames[_vFfz1.Name] == "Neutral" then
                PlayerFrames[_vFfz1.Name] = "Enemy"
            elseif PlayerFrames[_vFfz1.Name] == "Enemy" then
                PlayerFrames[_vFfz1.Name] = "Friend"
            end
            _M5_tm(_vFfz1, _GyNA41jH)
        end
    })
    App.sections.VisualUlt:toggle({
        name = "Custom Ultbar Text",
        def = false,
        pointer = "Custom Ultbar Text Toggle",
        callback = function(_UpMNTUFI)
            App.applyVisualToggle("Visuals.CustomUltbar.UltbarText.Enabled", "Custom Ultbar Text", _UpMNTUFI)
        end
    })
    App.sections.VisualUlt:textbox({
        name = "Ultbar Text",
        def = Config.Visuals.CustomUltbar.UltbarText.Text,
        placeholder = "",
        pointer = "Custom Ultbar Text",
        callback = function(_JOfOgI5)
            Config.Visuals.CustomUltbar.UltbarText.Text = _JOfOgI5
            App.applyVisualToggle(nil, "Custom Ultbar Text", Config.Visuals.CustomUltbar.UltbarText.Enabled)
        end
    })
    App.sections.VisualUlt:toggle({
        name = "Custom Ultbar Color",
        def = false,
        pointer = "Custom Ultbar Color Toggle",
        callback = function(_uQkQN)
            App.applyVisualToggle("Visuals.CustomUltbar.UltbarColor.Enabled", "Custom Ultbar Color", _uQkQN)
        end
    })
    State.refreshUltbar = function()
        if State.ultbarPending then
            return
        end
        State.ultbarPending = true
        task.delay(0.1, function()
            State.ultbarPending = false
            if not Unloaded then
                pcall(_TQDHO)
            end
        end)
    end
    App.sections.VisualUlt:colorpicker({
        name = "Ultbar Color",
        cpname = "",
        def = Config.Visuals.CustomUltbar.UltbarColor.Color,
        pointer = "Ultbar Color",
        callback = function(_jpcI6)
            Config.Visuals.CustomUltbar.UltbarColor.Color = _jpcI6
            State.refreshUltbar()
        end
    })
    App.sections.VisualColor:toggle({
        name = "Enabled",
        def = false,
        pointer = "Custom Effects Toggle",
        callback = function(_wouUP)
            App.applyVisualToggle("Visuals.EffectsColor.Enabled", "Custom Effects Color", _wouUP)
        end
    })
    App.sections.VisualColor:colorpicker({
        name = "Effects Color",
        cpname = "",
        def = Config.Visuals.EffectsColor.Color,
        pointer = "Custom Effects Color",
        callback = function(_lFii4)
            Config.Visuals.EffectsColor.Color = _lFii4
            _d9naL()
        end
    })
    App.sections.VisualChar:toggle({
        name = "Headless",
        def = false,
        pointer = "Headless Toggle",
        callback = function(_WRTKe)
            App.applyVisualToggle("Visuals.Headless", "Headless", _WRTKe)
        end
    })
    App.sections.VisualChar:toggle({
        name = "Korblox",
        def = false,
        pointer = "Korblox Toggle",
        callback = function(_TfPeH)
            App.applyVisualToggle("Visuals.Korblox", "Korblox", _TfPeH)
        end
    })
    App.sections.VisualChar:toggle({
        name = "Self Chams",
        def = false,
        pointer = "Self Chams Toggle",
        callback = function(_M_FUx)
            App.applyVisualToggle("Visuals.SelfChams.Enabled", "SelfChams", _M_FUx)
        end
    })
    App.sections.VisualChar:colorpicker({
        name = "Chams Color",
        cpname = "",
        def = Config.Visuals.SelfChams.Color,
        pointer = "Chams Color",
        callback = function(_BTYLo)
            Config.Visuals.SelfChams.Color = _BTYLo
            _oQwzM()
        end
    })
    App.sections.VisualChar:dropdown({
        name = "Chams Material",
        def = "ForceField",
        max = 3,
        options = {
            "None",
            "ForceField",
            "Neon",
            "Glass",
            "SmoothPlastic",
            "Plastic",
            "Foil",
            "DiamondPlate"
        },
        pointer = "Chams Material",
        callback = function(_J4Ime)
            Config.Visuals.SelfChams.Material = _J4Ime
            _oQwzM()
        end
    })
    App.sections.VisualChar:slider({
        name = "Fill Transparency",
        def = 50,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Chams Fill Transp",
        callback = function(_wkVnC)
            Config.Visuals.SelfChams.FillTransparency = _wkVnC / 100
            _oQwzM()
        end
    })
    App.sections.VisualChar:slider({
        name = "Outline Transparency",
        def = 0,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Chams Outline Transp",
        callback = function(_nyX8T)
            Config.Visuals.SelfChams.OutlineTransparency = _nyX8T / 100
            _oQwzM()
        end
    })
    App.sections.VisualSky:toggle({
        name = "Enabled",
        def = false,
        pointer = "Custom Sky Toggle",
        callback = function(_GT4HE)
            Config.Visuals.Sky.Enabled = _GT4HE
            SkyManager.apply()
        end
    })
    App.sections.VisualSky:dropdown({
        name = "Sky Preset",
        def = Config.Visuals.Sky.Preset,
        max = 4,
        options = SkyManager.order,
        pointer = "Custom Sky Preset",
        callback = function(_xOEua)
            Config.Visuals.Sky.Preset = _xOEua
            if Config.Visuals.Sky.Enabled then
                SkyManager.apply()
            end
        end
    })
    App.sections.VisualSky:slider({
        name = "Stars",
        def = Config.Visuals.Sky.Stars,
        max = 5000,
        min = 0,
        rounding = true,
        pointer = "Custom Sky Stars",
        callback = function(_kgZjO)
            Config.Visuals.Sky.Stars = _kgZjO
            if Config.Visuals.Sky.Enabled then
                SkyManager.apply()
            end
        end
    })
    App.sections.VisualSky:textbox({
        name = "Skybox Image ID",
        def = "",
        placeholder = "image id",
        pointer = "Custom Sky Image",
        tooltip = "Used by the Custom Skybox preset. Put an image asset id (not a decal id), it goes on all six sides",
        callback = function(_vbKfg)
            Config.Visuals.Sky.SkyboxId = _vbKfg
            if Config.Visuals.Sky.Enabled and Config.Visuals.Sky.Preset == "Custom Skybox" then
                SkyManager.apply()
            end
        end
    })
    App.sections.VisualAtmosphere:toggle({
        name = "Custom Atmosphere",
        def = false,
        pointer = "Atmosphere Toggle",
        callback = function(_iUVzq)
            App.applyVisualToggle("Visuals.Atmosphere.Enabled", "Atmosphere", _iUVzq)
        end
    })
    App.sections.VisualAtmosphere:colorpicker({
        name = "Atmosphere Color",
        cpname = "",
        def = Config.Visuals.Atmosphere.Color,
        pointer = "Atmosphere Color",
        callback = function(_ZNlgi)
            Config.Visuals.Atmosphere.Color = _ZNlgi
            if Config.Visuals.Atmosphere.Enabled then
                _L3aVK(true)
            end
        end
    })
    App.sections.VisualAtmosphere:colorpicker({
        name = "Decay Color",
        cpname = "",
        def = Config.Visuals.Atmosphere.Decay,
        pointer = "Atmosphere Decay Color",
        callback = function(_M4ypM)
            Config.Visuals.Atmosphere.Decay = _M4ypM
            if Config.Visuals.Atmosphere.Enabled then
                _L3aVK(true)
            end
        end
    })
    App.sections.VisualAtmosphere:slider({
        name = "Density",
        def = 35,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Atmosphere Density",
        callback = function(_LXzHF)
            Config.Visuals.Atmosphere.Density = _LXzHF / 100
            if Config.Visuals.Atmosphere.Enabled then
                _L3aVK(true)
            end
        end
    })
    App.sections.VisualAtmosphere:slider({
        name = "Haze",
        def = 0,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Atmosphere Haze",
        callback = function(_yGmjg)
            Config.Visuals.Atmosphere.Haze = _yGmjg / 10
            if Config.Visuals.Atmosphere.Enabled then
                _L3aVK(true)
            end
        end
    })
    App.sections.VisualAtmosphere:slider({
        name = "Glare",
        def = 0,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Atmosphere Glare",
        callback = function(_pbxyq)
            Config.Visuals.Atmosphere.Glare = _pbxyq / 100
            if Config.Visuals.Atmosphere.Enabled then
                _L3aVK(true)
            end
        end
    })
    App.sections.Rage:toggle({
        name = "No Stun",
        def = false,
        pointer = "No Stun",
        callback = function(_w81pK)
            Config.Rage.NoStun = _w81pK
        end
    })
    App.sections.Rage:toggle({
        name = "No Slow",
        def = false,
        pointer = "No Slow",
        callback = function(_nzqB3)
            Config.Rage.NoSlow = _nzqB3
        end
    })
    App.sections.Rage:toggle({
        name = "No Fatigue",
        def = false,
        pointer = "No Fatigue",
        callback = function(_WENbq)
            Config.Rage.NoFatigue = _WENbq
        end
    })
    State.Freeze = {held = false}
    State.Freeze.hold = function()
        local _zKUCR = State.Freeze
        if _zKUCR.held or not (RootPart and RootPart.Parent) then
            return
        end
        _zKUCR.held = true
        _zKUCR.root = RootPart
        _zKUCR.velocity = RootPart.AssemblyLinearVelocity
        RootPart.Anchored = true
    end
    State.Freeze.release = function()
        local _MEZKX = State.Freeze
        if not _MEZKX.held then
            return
        end
        _MEZKX.held = false
        local _VdWJv = _MEZKX.root
        _MEZKX.root = nil
        if _VdWJv and _VdWJv.Parent then
            _VdWJv.Anchored = false
            if _MEZKX.velocity then
                _VdWJv.AssemblyLinearVelocity = _MEZKX.velocity
            end
        end
    end
    State.Freeze.matches = function(_OTh7h)
        local _X4j0y = App.sections.FreezeKey and App.sections.FreezeKey.current
        if not (_X4j0y and _X4j0y[1]) then
            return false
        end
        return (_X4j0y[1] == "KeyCode" and _OTh7h.KeyCode.Name == _X4j0y[2]) or (_X4j0y[1] == "UserInputType" and _OTh7h.UserInputType.Name == _X4j0y[2])
    end
    App.sections.Rage:toggle({
        name = "Freeze On Hold",
        def = false,
        pointer = "Freeze Hold",
        tooltip = "Hold the freeze key to freeze your character in place, let go and you keep moving",
        callback = function(_kAQs0)
            Config.Rage.FreezeHold = _kAQs0
            if not _kAQs0 then
                State.Freeze.release()
            end
        end
    })
    App.sections.FreezeKey = App.sections.Rage:keybind({name = "Freeze Key", def = Enum.KeyCode.Tab, pointer = "Freeze Keybind"})
    connectSignal(ZR_InputBegan, function(_lYyj8)
        if not Config.Rage.FreezeHold or UserInputService:GetFocusedTextBox() then
            return
        end
        if State.Freeze.matches(_lYyj8) then
            State.Freeze.hold()
        end
    end)
    connectSignal(ZR_InputEnded, function(_yelLD)
        if State.Freeze.held and State.Freeze.matches(_yelLD) then
            State.Freeze.release()
        end
    end)
    App.sections.SDA:toggle({
        name = "Enabled",
        def = false,
        pointer = "Side Dash Assist Enabled",
        tooltip = "Side dash near someone and it curves into them, you end up at their side facing them",
        callback = function(_HPVAz)
            Config.Rage.SideDashAssist.Enabled = _HPVAz
        end
    })
    App.sections.SDA:toggle({
        name = "Face Target",
        def = Config.Rage.SideDashAssist.FaceTarget,
        pointer = "Side Dash Assist Face",
        callback = function(_UyIhW)
            Config.Rage.SideDashAssist.FaceTarget = _UyIhW
        end
    })
    App.sections.SDA:toggle({
        name = "Rotate Camera",
        def = Config.Rage.SideDashAssist.RotateCam,
        pointer = "Side Dash Assist Camera",
        tooltip = "Turns your camera to them during the dash too",
        callback = function(_JXq6b)
            Config.Rage.SideDashAssist.RotateCam = _JXq6b
        end
    })
    App.sections.SDA:toggle({
        name = "Highlight Target",
        def = Config.Rage.SideDashAssist.Highlight,
        pointer = "Side Dash Assist Highlight",
        tooltip = "Highlights who your next side dash will curve into",
        callback = function(_WdDHH)
            Config.Rage.SideDashAssist.Highlight = _WdDHH
            if not _WdDHH then
                State.mark("sda", nil)
            end
        end
    })
    App.sections.SDA:colorpicker({
        name = "Highlight Color",
        def = State.SDA.color,
        callback = function(c)
            State.SDA.color = c
            local m = State.marks and State.marks.sda
            if m then m.FillColor = c m.OutlineColor = c end
        end
    })
    App.sections.SDA:toggle({
        name = "Predict Movement",
        def = Config.Rage.SideDashAssist.Predict,
        pointer = "Side Dash Assist Predict",
        tooltip = "Curves to where they're running to, not where they are",
        callback = function(_fQ3u8)
            Config.Rage.SideDashAssist.Predict = _fQ3u8
        end
    })
    App.sections.SDA:slider({
        name = "Range",
        def = 25,
        max = 50,
        min = 8,
        rounding = true,
        pointer = "Side Dash Assist Range",
        tooltip = "How close someone has to be (studs) for the dash to curve into them",
        callback = function(_M8YT5)
            Config.Rage.SideDashAssist.Range = _M8YT5
        end
    })
    App.sections.SDA:dropdown({
        name = "Land",
        def = Config.Rage.SideDashAssist.Mode,
        max = 2,
        options = {"Behind", "Side"},
        pointer = "Side Dash Assist Mode",
        tooltip = "Behind = curves around them and lands at their back, Side = lands next to them",
        callback = function(_VGTtB)
            Config.Rage.SideDashAssist.Mode = _VGTtB
        end
    })
    App.sections.SDA:slider({
        name = "Speed",
        def = 100,
        max = 150,
        min = 60,
        rounding = true,
        measurement = "%",
        pointer = "Side Dash Assist Speed",
        tooltip = "100% = about as long as a normal side dash",
        callback = function(_iYINi)
            Config.Rage.SideDashAssist.Speed = _iYINi / 100
        end
    })
    App.sections.SDA:slider({
        name = "Distance",
        def = 35,
        max = 80,
        min = 20,
        rounding = true,
        pointer = "Side Dash Assist Offset",
        tooltip = "How far from them you curve around and land (x0.1 studs)",
        callback = function(_YLJw8)
            Config.Rage.SideDashAssist.Offset = _YLJw8 / 10
        end
    })
    App.sections.SDA:slider({
        name = "Curve Strength",
        def = 80,
        max = 100,
        min = 10,
        rounding = true,
        pointer = "Side Dash Assist Strength",
        tooltip = "Higher = snaps to their side faster",
        callback = function(_jVo_G)
            Config.Rage.SideDashAssist.Strength = _jVo_G / 100
        end
    })
    App.sections.Rage:toggle({
        name = "No No Jump",
        def = false,
        pointer = "No No Jump",
        callback = function(_u2ffX)
            Config.Rage.AlwaysJump = _u2ffX
        end
    })
    App.sections.Fling:textbox({
        name = "Fling Target",
        def = "",
        placeholder = "",
        pointer = "Fling Target",
        callback = function(_x6vUp)
            Config.Rage.Fling.Target = _x6vUp
        end
    })
    App.sections.Fling:toggle({
        name = "Loop Fling",
        def = false,
        pointer = "Loop Fling",
        callback = function(_IpJgl)
            Config.Rage.Fling.LoopFling = _IpJgl
        end
    })
    App.sections.Fling:button({
        name = "Fling",
        callback = function()
            repeat
                local _TDeuAvo
                for _KcW1sUhL, _V5t2d in pairs(Players:GetPlayers()) do
                    if _V5t2d.Name == Config.Rage.Fling.Target or _V5t2d.DisplayName == Config.Rage.Fling.Target then
                        _TDeuAvo = _V5t2d
                    end
                end
                if _TDeuAvo then
                    local _gso3RE = _TDeuAvo.Character
                    if _gso3RE then
                        _tCAt2(_gso3RE)
                    end
                else
                    _OS0SJ({Title = "ZRHUB", Description = "Fling target isn't on the server", Source = "Fling"})
                    break
                end
                task.wait(3)
            until not Config.Rage.Fling.LoopFling
        end
    })
    App.sections.Fling:toggle({
        name = "Anti Fling",
        def = false,
        pointer = "Anti Fling",
        callback = function(_rAS27rA)
            _vA5WJ(_wZKifJPa.antifling)
            _wZKifJPa.antifling = nil
            if _rAS27rA then
                local _WXqXmqAR = nil
                _wZKifJPa.antifling = connectSignal(RunService.Heartbeat, function()
                    local _hPSWz = RootPart
                    if not (_hPSWz and _hPSWz.Parent) then
                        return
                    end
                    local _IKcQGPII = tick() < State.boostUntil or _hPSWz:FindFirstChild("moveme") or _hPSWz:FindFirstChild("dodgevelocity")
                    if (not _IKcQGPII and _hPSWz.AssemblyLinearVelocity.Magnitude > 250) or _hPSWz.AssemblyAngularVelocity.Magnitude > 250 then
                        _hPSWz.AssemblyAngularVelocity = Vector3.zero
                        _hPSWz.AssemblyLinearVelocity = Vector3.zero
                        if _WXqXmqAR then
                            _hPSWz.CFrame = _WXqXmqAR
                        end
                    elseif _hPSWz.AssemblyLinearVelocity.Magnitude < 50 and _hPSWz.AssemblyAngularVelocity.Magnitude < 50 then
                        _WXqXmqAR = _hPSWz.CFrame
                    end
                end)
            end
        end
    })
    App.unload = function()
        if Unloaded then
            return
        end
        Unloaded = true
        for _GWz3BX in pairs(State.marks or {}) do
            pcall(State.mark, _GWz3BX, nil)
        end
        pcall(State.Scope.stop)
        if State.Scope.gui then
            pcall(State.Scope.gui.Destroy, State.Scope.gui)
        end
        pcall(function()
            if App.window then
                if App.window.screen then
                    App.window.screen.Enabled = false
                    pcall(function()
                        App.window.screen:Destroy()
                    end)
                end
                if App.window.destroy then
                    pcall(function()
                        App.window:destroy()
                    end)
                elseif App.window.connections then
                    for _vO78g, _sSql59 in ipairs(App.window.connections) do
                        pcall(function()
                            _sSql59:Disconnect()
                        end)
                    end
                end
            end
            if Notify and Notify.Destroy then
                pcall(Notify.Destroy)
            end
        end)
        for _hhe2kJp in pairs(ActiveConnections) do
            _hhe2kJp:Disconnect()
        end
        table.clear(ActiveConnections)
        ActiveConnections = {}
        for _W_H1KfSd in pairs(_XNd6n) do
            RunService:UnbindFromRenderStep(_W_H1KfSd)
        end
        table.clear(_XNd6n)
        _XNd6n = {}
        _xQp2C(_i3Z2l)
        _i3Z2l = nil
        LethalState.armedUntil = 0
        LethalState.busy = false
        _mzv8k = false
        Config.Misc.StretchEnabled = false
        Config.Misc.LockOnEnabled = false
        if Config.Misc.Magnet then
            Config.Misc.Magnet.Enabled = false
        end
        _KjGi0a.stop()
        if Config.Rage.NoSideDashCooldown then
            Config.Rage.NoSideDashCooldown = false
            _zk6rn(false)
            if Character then
                Character:SetAttribute("CustomSideDashCooldown", nil)
            end
        end
        Config.Rage.Fling.LoopFling = false
        Config.AutoTech.Enabled = false
        Config.AutoLethal.Enabled = false
        Config.PingSpoof.Enabled = false
        if Config.DeviceSpoof.Enabled then
            Config.DeviceSpoof.Enabled = false
            pcall(App.iconState.restore)
        end
        Config.Autoblock.Enabled = false
        Config.Visuals.SelfChams.Enabled = false
        Config.Visuals.Atmosphere.Enabled = false
        Config.Visuals.Sky.Enabled = false
        Config.Visuals.MotionBlur.Enabled = false
        _LZYNd()
        disconnectAll(_rJ2QD)
        for _fLtVB, _Uu4DU in pairs(PlayerConnections) do
            disconnectAll(_Uu4DU)
        end
        for _Jc7hX, _etJGw in pairs(CharacterConnections) do
            disconnectAll(_etJGw)
        end
        table.clear(_rJ2QD)
        table.clear(PlayerConnections)
        table.clear(CharacterConnections)
        if _r6zpd then
            pcall(function()
                _r6zpd:Destroy()
            end)
            _r6zpd = nil
        end
        if LethalState.highlight then
            pcall(function()
                LethalState.highlight:Destroy()
            end)
            LethalState.highlight = nil
        end
        pcall(_aKxqPdSj, true)
        pcall(BoxESP.destroy)
        pcall(_oQwzM)
        pcall(_L3aVK, false)
        pcall(SkyManager.restore)
        pcall(MotionBlur.set, false)
        pcall(_CperF, false, false)
        local _T5J2B = Character
        if _T5J2B then
            for _I8ohM, _xPytV in ipairs(_T5J2B:GetChildren()) do
                if _xPytV.Name == "KittyKorbloxCM" then
                    pcall(function()
                        _xPytV:Destroy()
                    end)
                end
            end
            local _GXj0j = _T5J2B:FindFirstChild("Right Leg")
            local _v27wO = _GXj0j and _GXj0j:FindFirstChild("KittyKorbloxSM")
            if _v27wO then
                pcall(function()
                    _v27wO:Destroy()
                end)
            end
        end
        if Config.Visuals.Korblox and Humanoid and _ElMhN then
            local _k1XEk, _hCxpB = Humanoid, _ElMhN
            task.spawn(function()
                pcall(function()
                    _k1XEk:ApplyDescription(_hCxpB)
                end)
            end)
        end
        if Humanoid and _XXmEh then
            pcall(function()
                State.freeRotate()
                Humanoid.JumpPower = _XXmEh.JumpPower
            end)
        end
        if HeadPart and _XXmEh and _XXmEh.HeadTransparency ~= nil then
            pcall(function()
                HeadPart.Transparency = _XXmEh.HeadTransparency
            end)
        end
        if _N82Le and _XXmEh and _XXmEh.FaceTransparency ~= nil then
            pcall(function()
                _N82Le.Transparency = _XXmEh.FaceTransparency
            end)
        end
        _Upc_G()
        pcall(function()
            Lighting.GlobalShadows = _LMfeK.GlobalShadows
        end)
        pcall(function()
            Lighting.ClockTime = _LMfeK.ClockTime
        end)
        if _LMfeK.createdCC then
            pcall(function()
                _uMouq:Destroy()
            end)
        else
            pcall(function()
                _uMouq.Saturation = _LMfeK.Saturation
            end)
            pcall(function()
                _uMouq.Name = _LMfeK.originalCCName
            end)
        end
        pcall(function()
            Camera.FieldOfView = _LMfeK.FieldOfView
        end)
        pcall(function()
            workspace.FallenPartsDestroyHeight = DefaultDestroyHeight
        end)
        for _WIZMd, _Lx_Ox in ipairs({
            KeyW,
            KeyA,
            KeyS,
            KeyD,
            KeyQ,
            KeySpace,
            Enum.KeyCode.One,
            Enum.KeyCode.Two,
            Enum.KeyCode.Three,
            Enum.KeyCode.Four
        }) do
            pcall(releaseKey, _Lx_Ox)
        end
    end
    App.sections.Front:toggle({
        name = "Enabled",
        def = false,
        pointer = "Custom Front Dash Enabled",
        callback = function(_v5k8j)
            Config.Rage.CustomFrontDash.Enabled = _v5k8j
        end
    })
    App.sections.Front:toggle({
        name = "Only On Keybind",
        def = false,
        pointer = "Custom front only on kebab",
        callback = function(_afztR)
            Config.Rage.CustomFrontDash.OnlyOnKeybind = _afztR
        end
    })
    App.sections.Front:slider({
        name = "Front Dash Distance",
        def = 10,
        max = 100,
        min = 1,
        rounding = true,
        pointer = "Front Dash Distance",
        callback = function(_FqBPJ)
            Config.Rage.CustomFrontDash.Distance = _FqBPJ / 10
        end
    })
    App.sections.Front:keybind({
        name = "Keybind",
        def = nil,
        pointer = "front keybind",
        callback = function(_QZg7_)
            if not Config.Rage.CustomFrontDash.Enabled then
                return
            end
            if _XjK2G() then
                _fwa6a(_fwJeEv6(Config.Rage.CustomFrontDash.Distance)[1], 0.05)
            end
        end
    })
    App.sections.Side:toggle({
        name = "No Side Dash Cooldown",
        def = Config.Rage.NoSideDashCooldown,
        pointer = "No Side Dash Cooldown",
        tooltip = "Removes cooldown between side dashes so you can dash continuously",
        callback = function(_vlVwr)
            Config.Rage.NoSideDashCooldown = _vlVwr
            if _vlVwr then
                pcall(function()
                    if Character then
                        Character:SetAttribute("CustomSideDashCooldown", 0)
                    end
                end)
                _zk6rn(true)
            else
                pcall(function()
                    if Character then
                        Character:SetAttribute("CustomSideDashCooldown", nil)
                        Character:SetAttribute("AfterimageDash", nil)
                    end
                end)
                _zk6rn(false)
            end
        end
    })
    App.sections.Side:toggle({
        name = "Enabled",
        def = false,
        pointer = "Custom Side Dash Enabled",
        callback = function(_awFbG)
            Config.Rage.CustomSideDash.Enabled = _awFbG
        end
    })
    App.sections.Side:toggle({
        name = "Only On Keybind",
        def = false,
        pointer = "Side only on keybind",
        callback = function(_l4fP7)
            Config.Rage.CustomSideDash.OnlyOnKeybind = _l4fP7
        end
    })
    App.sections.Side:slider({
        name = "Side Dash Distance",
        def = 10,
        max = 100,
        min = 1,
        rounding = true,
        pointer = "Side Dash Distance",
        callback = function(_QzgtC)
            Config.Rage.CustomSideDash.Distance = _QzgtC / 10
        end
    })
    App.sections.Side:dropdown({
        name = "Dash Side",
        def = Config.Rage.CustomSideDash.Side,
        max = 3,
        options = {"Right", "Left", "Straight"},
        pointer = "CustomSideDashType",
        callback = function(_vBySi)
            Config.Rage.CustomSideDash.Side = _vBySi
        end
    })
    App.sections.Side:keybind({
        name = "Keybind",
        def = nil,
        pointer = "Side keybind",
        callback = function(_WVyac)
            if not Config.Rage.CustomSideDash.Enabled or not (Humanoid and RootPart and Humanoid.Health > 0) then
                return
            end
            releaseKey(KeyW)
            releaseKey(KeyS)
            if Config.Rage.CustomSideDash.Side == "Straight" then
                _GcDR2(90)
            end
            if Config.Rage.CustomSideDash.Side == "Straight" or Config.Rage.CustomSideDash.Side == "Right" then
                pressKey(KeyD)
            elseif Config.Rage.CustomSideDash.Side == "Left" then
                pressKey(KeyA)
            end
            if Config.Rage.CustomSideDash.Jump then
                pressKey(KeySpace)
            end
            task.wait(0.005)
            tapKey(KeyQ)
            if Config.Rage.CustomSideDash.RemoveInertia then
                task.wait(Config.Rage.CustomSideDash.RMIDelay)
                local _jc70N = RootPart:FindFirstChild("dodgevelocity")
                if Config.Rage.CustomSideDash.RemoveInertia and _jc70N then
                    _jc70N:Destroy()
                    _ZGKm8(_j089A.rsideDash)
                    _ZGKm8(_j089A.lsideDash)
                end
            end
            releaseKey(KeySpace)
            releaseKey(KeyD)
            releaseKey(KeyA)
            if Config.Rage.CustomSideDash.Side == "Straight" then
                _GcDR2(-90)
            end
            _fwa6a(Config.Rage.CustomSideDash.Distance, 0.05)
        end
    })
    App.sections.Side:toggle({
        name = "Jump",
        def = false,
        pointer = "SDJ",
        callback = function(_Ee1QJ)
            Config.Rage.CustomSideDash.Jump = _Ee1QJ
        end
    })
    App.sections.Side:toggle({
        name = "Remove Inertia",
        def = false,
        pointer = "Remove Ineria",
        callback = function(_Z3Kw3)
            Config.Rage.CustomSideDash.RemoveInertia = _Z3Kw3
        end
    })
    App.sections.Side:slider({
        name = "RM Inertia Delay",
        def = 70,
        max = 100,
        min = 1,
        rounding = true,
        pointer = "RMID",
        callback = function(_Ou8gP)
            Config.Rage.CustomSideDash.RMIDelay = _Ou8gP / 1000
        end
    })
    App.sections.UndyingHero:toggle({
        name = "Sniper Silent Aim",
        def = false,
        pointer = "Zombie Silent Aim",
        tooltip = "Automatically redirects sniper shots directly to the target body part",
        callback = function(_jj3GQ)
            if _jj3GQ and not App.pingSpoof.install() then
                Config.Zombie.SniperSilentAim = false
                _OS0SJ({Title = "ZRHUB", Description = "Executor does not support hookmetamethod, silent aim unavailable"})
                return
            end
            Config.Zombie.SniperSilentAim = _jj3GQ
            State.Scope.updateCircle()
        end
    })
    App.sections.UndyingHero:dropdown({
        name = "Silent Aim Part",
        def = Config.Zombie.TargetPart,
        max = 3,
        options = {"Head", "Torso", "HumanoidRootPart"},
        pointer = "Zombie Target Part",
        callback = function(_EXw_Y)
            Config.Zombie.TargetPart = _EXw_Y
        end
    })
    App.sections.UndyingHero:dropdown({
        name = "Target Mode",
        def = Config.Zombie.SilentAimMode,
        max = 2,
        options = {"Mouse", "Distance"},
        pointer = "Zombie Target Mode",
        tooltip = "Mouse: closest to cursor | Distance: closest player in world",
        callback = function(_tomFn)
            Config.Zombie.SilentAimMode = _tomFn
            State.Scope.updateCircle()
        end
    })
    App.sections.UndyingHero:slider({
        name = "Silent Aim FOV",
        def = Config.Zombie.SilentAimFOV,
        max = 2000,
        min = 50,
        rounding = true,
        pointer = "Zombie Silent Aim FOV",
        tooltip = "Pixel radius around cursor to detect targets (2000 for full screen)",
        callback = function(_Odd1N)
            Config.Zombie.SilentAimFOV = _Odd1N
        end
    })
    App.sections.UndyingHero:toggle({
        name = "Show FOV Circle",
        def = Config.Zombie.FovCircle,
        pointer = "Zombie FOV Circle",
        tooltip = "Shows the silent aim fov around your cursor while you're undying hero",
        callback = function(_j3snL)
            Config.Zombie.FovCircle = _j3snL
            State.Scope.updateCircle()
        end
    })
    App.sections.UndyingHero:slider({
        name = "Max Range",
        def = Config.Zombie.SilentAimMaxDist,
        max = 1500,
        min = 100,
        rounding = true,
        pointer = "Zombie Silent Aim Range",
        tooltip = "Max stud range to hit targets (sniper range is up to 1500 studs)",
        callback = function(_YCOUP)
            Config.Zombie.SilentAimMaxDist = _YCOUP
        end
    })
    App.sections.UndyingHero:slider({
        name = "Aim Prediction",
        def = Config.Zombie.SilentAimPredict,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "Zombie Silent Aim Predict",
        tooltip = "Velocity prediction lead for moving targets (0 = disabled)",
        callback = function(_t9iG6)
            Config.Zombie.SilentAimPredict = _t9iG6
        end
    })
    App.sections.UndyingHero:toggle({
        name = "Wall Check",
        def = false,
        pointer = "Zombie Wall Check",
        tooltip = "Only shoot targets that have direct line of sight",
        callback = function(_O1dBt)
            Config.Zombie.WallCheck = _O1dBt
        end
    })
    App.sections.UndyingHero:toggle({
        name = "Sniper Third Person",
        def = false,
        pointer = "Zombie Third Person",
        tooltip = "Maintains normal 3rd-person camera and clears scope overlay when holding sniper",
        callback = function(_biori)
            Config.Zombie.SniperThirdPerson = _biori
            if _biori then
                App.pingSpoof.install()
            end
            State.Scope.sync()
        end
    })
    App.sections.UndyingHero:slider({
        name = "Third Person Distance",
        def = Config.Zombie.ThirdPersonDist or 12,
        max = 30,
        min = 5,
        rounding = true,
        pointer = "Zombie Third Person Dist",
        tooltip = "Camera zoom distance in third person",
        callback = function(_wMsIv)
            Config.Zombie.ThirdPersonDist = _wMsIv
        end
    })
    App.sections.UndyingHero:toggle({
        name = "Sniper Spinbot",
        def = false,
        pointer = "Zombie Spinbot",
        tooltip = "Rapidly spins character yaw in 3rd person while holding the sniper rifle",
        callback = function(_RUZBp)
            Config.Zombie.SniperSpinbot = _RUZBp
            State.Scope.setSpin(_RUZBp)
        end
    })
    App.sections.UndyingHero:slider({
        name = "Spinbot Speed",
        def = Config.Zombie.SpinSpeed or 35,
        max = 100,
        min = 1,
        rounding = true,
        pointer = "Zombie Spin Speed",
        tooltip = "Rotation speed for sniper spinbot (1 = slow, 100 = fast)",
        callback = function(_m8m1V)
            Config.Zombie.SpinSpeed = _m8m1V
        end
    })
    App.sections.UndyingHero:toggle({
        name = "Camera Lock Bypass",
        def = false,
        pointer = "Zombie Cam Bypass",
        tooltip = "Bypasses all move and scope camera locks via character zombiebypass",
        callback = function(_bHtQN)
            Config.Zombie.CameraLockBypass = _bHtQN
            _ucV8j(_bHtQN)
            _vA5WJ(_wZKifJPa.camBypass)
            _wZKifJPa.camBypass = nil
            if _bHtQN and workspace.CurrentCamera then
                _wZKifJPa.camBypass = connectSignal(workspace.CurrentCamera:GetPropertyChangedSignal("CameraType"), function()
                    _ucV8j(true)
                end)
            end
        end
    })
    App.sections.UndyingHero:toggle({
        name = "Low HP Alert (<= 40 HP)",
        def = false,
        pointer = "Zombie Low HP",
        tooltip = "Notifies when health drops <= 40 HP (Undying Hero passive threshold)",
        callback = function(_w4jkj)
            Config.Zombie.LowHpCounter = _w4jkj
        end
    })
    State.Scope.aiming = function(_Re5q3)
        return _Re5q3:GetAttribute("InterventionAiming") or _Re5q3:GetAttribute("InterventionChamber") or _Re5q3:GetAttribute("OldInterventionAiming") or _Re5q3:GetAttribute("OldInterventionChamber")
    end
    State.Scope.addBody = function(_GNNuE)
        if (_GNNuE:IsA("BasePart") or _GNNuE:IsA("Decal")) and not _GNNuE:FindFirstAncestorOfClass("Tool") then
            table.insert(State.Scope.body, _GNNuE)
        end
    end
    State.Scope.onCamChild = function(_bY29W)
        if _bY29W:IsA("Model") and _bY29W:FindFirstChildOfClass("Humanoid") then
            for _wkbzg, _mDbWtvq9 in ipairs(_bY29W:GetDescendants()) do
                if _mDbWtvq9:IsA("BasePart") then
                    table.insert(State.Scope.vm, _mDbWtvq9)
                end
            end
        elseif _bY29W:IsA("BlurEffect") or _bY29W:IsA("DepthOfFieldEffect") then
            _bY29W.Enabled = false
        end
    end
    State.Scope.onGui = function(_F06Kr)
        if _F06Kr.Name == "InterventionScope" then
            _F06Kr.Enabled = false
        end
    end
    State.Scope.step = function()
        local _c5blw7 = State.Scope
        local _nDcs2Sk, _K29eW6 = Character, workspace.CurrentCamera
        if not (_nDcs2Sk and _K29eW6) then
            return
        end
        for _d5gfB, _UawDsy in ipairs(_c5blw7.body) do
            if _UawDsy.LocalTransparencyModifier ~= 0 then
                _UawDsy.LocalTransparencyModifier = 0
            end
        end
        for _NTf0a8l, _qL3o1UKg in ipairs(_c5blw7.vm) do
            if _qL3o1UKg.LocalTransparencyModifier ~= 1 then
                _qL3o1UKg.LocalTransparencyModifier = 1
            end
        end
        local _Xm9G4 = Config.Visuals.FOV or 70
        if _K29eW6.FieldOfView ~= _Xm9G4 then
            _K29eW6.FieldOfView = _Xm9G4
        end
        if UserInputService.MouseDeltaSensitivity ~= _c5blw7.sens then
            UserInputService.MouseDeltaSensitivity = _c5blw7.sens
        end
        if _K29eW6:GetAttribute("AimSensitivity") then
            _K29eW6:SetAttribute("AimSensitivity", nil)
        end
        if _K29eW6:GetAttribute("AimAssist") then
            _K29eW6:SetAttribute("AimAssist", nil)
        end
        if not UserInputService.MouseIconEnabled then
            UserInputService.MouseIconEnabled = true
        end
        local _gUCjCB = _K29eW6.CFrame
        _c5blw7.eye = _gUCjCB
        local _Ndx6Uw9 = Config.Zombie.ThirdPersonDist or 12
        local _qusHbAjq = _Ndx6Uw9 - (_gUCjCB.Position - _K29eW6.Focus.Position).Magnitude
        if _qusHbAjq <= 0 then
            return
        end
        local _D1KRF = _gUCjCB:VectorToWorldSpace(Vector3.new(2 * _qusHbAjq / _Ndx6Uw9, 0.5 * _qusHbAjq / _Ndx6Uw9, _qusHbAjq))
        local _gBqRw = workspace:Raycast(_gUCjCB.Position, _D1KRF, _c5blw7.ray)
        if _gBqRw then
            _D1KRF = _D1KRF.Unit * math.max(_gBqRw.Distance - 0.5, 0)
        end
        _K29eW6.CFrame = _gUCjCB + _D1KRF
    end
    State.Scope.start = function(_Nmhcz)
        local _yXigI = State.Scope
        _yXigI.active = true
        _yXigI.sens = UserInputService.MouseDeltaSensitivity
        _yXigI.icon = UserInputService.MouseIconEnabled
        _yXigI.body, _yXigI.vm = {}, {}
        for _fKHiH, _IuUb8 in ipairs(_Nmhcz:GetDescendants()) do
            _yXigI.addBody(_IuUb8)
        end
        local _Vt1Ub = workspace.CurrentCamera
        _yXigI.ray = RaycastParams.new()
        _yXigI.ray.FilterType = Enum.RaycastFilterType.Exclude
        _yXigI.ray.FilterDescendantsInstances = {_Nmhcz, _Vt1Ub, World.Live}
        for _ydcnP, _f1CPJ in ipairs(_Vt1Ub:GetChildren()) do
            _yXigI.onCamChild(_f1CPJ)
        end
        local _oXUCV = PlayerGui and PlayerGui:FindFirstChild("InterventionScope")
        if _oXUCV then
            _yXigI.onGui(_oXUCV)
        end
        _yXigI.conns = {connectSignal(_Vt1Ub.ChildAdded, _yXigI.onCamChild), connectSignal(_Nmhcz.DescendantAdded, _yXigI.addBody)}
        if PlayerGui then
            table.insert(_yXigI.conns, connectSignal(PlayerGui.ChildAdded, _yXigI.onGui))
        end
        _XNd6n[_yXigI.bind] = true
        RunService:BindToRenderStep(_yXigI.bind, Enum.RenderPriority.Camera.Value + 3, _yXigI.step)
    end
    State.Scope.stop = function()
        local _VLwjv = State.Scope
        if not _VLwjv.active then
            return
        end
        _VLwjv.active = false
        _VLwjv.eye = nil
        pcall(RunService.UnbindFromRenderStep, RunService, _VLwjv.bind)
        _XNd6n[_VLwjv.bind] = nil
        for _yu3H0, _f7ZZ6 in ipairs(_VLwjv.conns) do
            _vA5WJ(_f7ZZ6)
        end
        _VLwjv.conns = {}
        _VLwjv.body, _VLwjv.vm = {}, {}
        local _opZGG = PlayerGui and PlayerGui:FindFirstChild("InterventionScope")
        if _opZGG then
            _opZGG.Enabled = true
        end
        UserInputService.MouseDeltaSensitivity = _VLwjv.sens
        if _VLwjv.icon ~= nil then
            UserInputService.MouseIconEnabled = _VLwjv.icon
        end
    end
    State.Scope.sync = function()
        local _V2GbF = State.Scope
        local _yLXZ6 = Character
        local _n0bqV = Config.Zombie.SniperThirdPerson and _yLXZ6 and _V2GbF.aiming(_yLXZ6)
        if _n0bqV and not _V2GbF.active then
            task.defer(function()
                if Config.Zombie.SniperThirdPerson and Character == _yLXZ6 and _V2GbF.aiming(_yLXZ6) and not _V2GbF.active then
                    _V2GbF.start(_yLXZ6)
                end
            end)
        elseif not _n0bqV and _V2GbF.active then
            _V2GbF.stop()
        end
    end
    State.Scope.hook = function(_Qr5As)
        for _xEKJv, _JC2vp in ipairs({"InterventionAiming", "InterventionChamber", "OldInterventionAiming", "OldInterventionChamber"}) do
            connectSignal(_Qr5As:GetAttributeChangedSignal(_JC2vp), State.Scope.sync)
        end
    end
    State.Scope.setSpin = function(_o_VrI)
        local _P9KWp = State.Scope
        _vA5WJ(_wZKifJPa.zombieSpin)
        _wZKifJPa.zombieSpin = nil
        if _P9KWp.spinning then
            _P9KWp.spinning = false
            State.freeRotate()
        end
        if not _o_VrI then
            return
        end
        _wZKifJPa.zombieSpin = connectSignal(RunService.RenderStepped, function(_aIt80)
            local _ngnmM, _IfLS0 = RootPart, Humanoid
            if _P9KWp.holding and _ngnmM and _IfLS0 and _IfLS0.Health > 0 and not _ffQog() then
                _P9KWp.spinning = true
                _IfLS0.AutoRotate = false
                _P9KWp.spin = (_P9KWp.spin + math.rad(Config.Zombie.SpinSpeed or 35) * math.min(_aIt80, 0.1) * 60) % (math.pi * 2)
                _ngnmM.CFrame = CFrame.new(_ngnmM.Position) * CFrame.Angles(0, _P9KWp.spin, 0)
            elseif _P9KWp.spinning then
                _P9KWp.spinning = false
                State.freeRotate()
            end
        end)
    end
    State.Scope.updateCircle = function()
        local _BC1ts = State.Scope
        local _WrMP8 = Config.Zombie
        if not (_WrMP8.FovCircle and _WrMP8.SniperSilentAim and _WrMP8.SilentAimMode ~= "Distance") then
            _vA5WJ(_wZKifJPa.fovCircle)
            _wZKifJPa.fovCircle = nil
            if _BC1ts.circle then
                _BC1ts.circle.Visible = false
            end
            return
        end
        if _wZKifJPa.fovCircle then
            return
        end
        if not _BC1ts.circle then
            local _n_DWD = Instance.new("ScreenGui")
            _n_DWD.Name = tostring(math.random(100000, 999999))
            _n_DWD.IgnoreGuiInset = true
            _n_DWD.ResetOnSpawn = false
            _n_DWD.DisplayOrder = 9998
            _n_DWD.Parent = (gethui and gethui()) or Services.CoreGui
            local _ITylk = Instance.new("Frame")
            _ITylk.AnchorPoint = Vector2.new(0.5, 0.5)
            _ITylk.BackgroundTransparency = 1
            _ITylk.Visible = false
            _ITylk.Parent = _n_DWD
            Instance.new("UICorner", _ITylk).CornerRadius = UDim.new(1, 0)
            local _ZtoL2 = Instance.new("UIStroke")
            _ZtoL2.Thickness = 1.5
            _ZtoL2.Color = App.window.theme.accent
            _ZtoL2.Parent = _ITylk
            _BC1ts.gui, _BC1ts.circle = _n_DWD, _ITylk
        end
        local _uED79 = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        _wZKifJPa.fovCircle = connectSignal(RunService.RenderStepped, function()
            local _LvKPQ = workspace.CurrentCamera
            if not _LvKPQ then
                return
            end
            local _AY524 = _uED79 and (_LvKPQ.ViewportSize / 2) or UserInputService:GetMouseLocation()
            local _ZG3Sj = (_WrMP8.SilentAimFOV or 500) * 2
            _BC1ts.circle.Position = UDim2.fromOffset(_AY524.X, _AY524.Y)
            _BC1ts.circle.Size = UDim2.fromOffset(_ZG3Sj, _ZG3Sj)
            _BC1ts.circle.Visible = _gMeqn() == true
        end)
    end
    task.spawn(function()
        local _uUHgc = false
        while not Unloaded do
            task.wait(0.2)
            local _fR2gB = Config.Zombie
            if _fR2gB.SniperSpinbot then
                State.Scope.holding = _RnQ1A5M(Character)
            end
            if _fR2gB.CameraLockBypass then
                _ucV8j(true)
            end
            if _fR2gB.LowHpCounter and Humanoid and _gMeqn() and Humanoid.Health > 0 and Humanoid.Health <= 40 then
                if not _uUHgc then
                    _uUHgc = true
                    _OS0SJ({Title = "Undying Hero", Description = "Low HP Passive Ready! (<= 40 HP)", Source = "Zombie"})
                end
            elseif Humanoid and Humanoid.Health > 40 then
                _uUHgc = false
            end
        end
    end)
    App.sections.Misc:toggle({
        name = "Display Hitbox",
        def = false,
        pointer = "Display Hitbox",
        callback = function(_AubYE)
            if _r6zpd then
                pcall(function()
                    _r6zpd:Destroy()
                end)
                _r6zpd = nil
            end
            _vA5WJ(_wZKifJPa.getping)
            _vA5WJ(_wZKifJPa.hitbox)
            _wZKifJPa.getping, _wZKifJPa.hitbox = nil, nil
            if _AubYE then
                _r6zpd = Instance.new("Part")
                _r6zpd.Size = Vector3.new(2, 2, 1)
                _r6zpd.Color = Color3.new(1, 0, 0)
                _r6zpd.Transparency = 0.5
                _r6zpd.Anchored = true
                _r6zpd.CanCollide = false
                _r6zpd.CanQuery = false
                _r6zpd.CanTouch = false
                _r6zpd.Name = "PingGhost"
                _r6zpd.Parent = workspace
                _wZKifJPa.getping = connectSignal(RunService.Heartbeat, function(_Z1LjH)
                    local _Oz7ME = tick()
                    if not (RootPart and RootPart.Parent) then
                        return
                    end
                    table.insert(_vjMDS, {time = _Oz7ME, cf = RootPart.CFrame})
                    while _vjMDS[1] and _Oz7ME - _vjMDS[1].time > 2 do
                        table.remove(_vjMDS, 1)
                    end
                end)
                _wZKifJPa.hitbox = connectSignal(RunService.RenderStepped, function()
                    local _fA86S = tick() - getPing(1000)
                    local _Ad4FT = _sxJBdGwo(_fA86S)
                    if _Ad4FT and _r6zpd then
                        _r6zpd.CFrame = _Ad4FT
                    end
                end)
            end
        end
    })
    App.sections.Misc:button({
        name = "Rejoin",
        callback = function()
            if #Players:GetPlayers() <= 1 then
                Services.TeleportService:Teleport(game.PlaceId, LocalPlayer)
            else
                Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end
    })
    App.sections.Misc:button({
        name = "Copy Discord Invite",
        callback = function()
            local _RgXNu = setclipboard or toclipboard or (Clipboard and Clipboard.set)
            if _RgXNu then
                pcall(_RgXNu, DiscordInvite)
                _OS0SJ({Title = "ZRHUB", Description = "copied " .. DiscordInvite})
            else
                _OS0SJ({Title = "ZRHUB", Description = "your executor can't copy, the invite is " .. DiscordInvite})
            end
        end
    })
    App.sections.Misc:button({name = "Panic", tooltip = "Shuts down the script immediately", callback = App.unload})
    App.sections.Misc:keybind({
        name = "GUI Keybind",
        def = Enum.KeyCode.RightShift,
        allowed = 0,
        pointer = "GUI Keybind",
        changeCallback = function(_m6dr6)
            App.window:setkey(_m6dr6)
            App.window.key = _m6dr6
        end
    })
    App.sections.Misc:toggle({
        name = "Screen Strench Enabled",
        def = false,
        pointer = "Stretch Screen Toggle",
        callback = function(_DvcWr)
            Config.Misc.StretchEnabled = _DvcWr
            _vA5WJ(_wZKifJPa.stretch)
            _wZKifJPa.stretch = nil
            if _DvcWr then
                _wZKifJPa.stretch = connectSignal(RunService.RenderStepped, function()
                    Camera.CFrame = (Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, Config.Misc.StretchValue, 0, 0, 0, 1))
                end)
            end
        end
    })
    App.sections.Misc:slider({
        name = "Screen Stretch Value",
        def = 100,
        max = 120,
        min = 0,
        rounding = true,
        pointer = "Stretch Screen Value",
        callback = function(_YSmZ7)
            Config.Misc.StretchValue = _YSmZ7 / 100
        end
    })
    App.sections.Misc:slider({
        name = "Day Time",
        def = math.floor(Lighting.ClockTime),
        max = 24,
        min = 0,
        rounding = true,
        pointer = "CycleTime",
        tooltip = "Time of day (0-24). Drag or click box to type",
        callback = function(_R0ii1)
            _IeaiYt2E(Lighting, "ClockTime", _R0ii1)
        end
    })
    _lH0uIxY.valid = function(_mNpU3dqH)
        if not (_mNpU3dqH and _mNpU3dqH.Parent and _mNpU3dqH ~= Character) then
            return nil
        end
        local _DMtNwHd = _mNpU3dqH:FindFirstChild("HumanoidRootPart")
        local _ssnObe9O = _mNpU3dqH:FindFirstChildOfClass("Humanoid")
        if not (_DMtNwHd and _ssnObe9O and _ssnObe9O.Health > 0) then
            return nil
        end
        local _RJc1a = Players:GetPlayerFromCharacter(_mNpU3dqH)
        if _RJc1a then
            if _RJc1a == LocalPlayer then
                return nil
            end
            if Config.Misc.FriendCheck and _JrRW2(_RJc1a, false) then
                return nil
            end
        elseif not Config.Misc.LockOnDummies then
            return nil
        end
        return _DMtNwHd, _ssnObe9O
    end
    _lH0uIxY.targetPart = function(_mw6cVj)
        if not _mw6cVj then
            return nil
        end
        local _Y7CfRG = Config.Misc.LockOnTargetPart or "Head"
        if _Y7CfRG == "Head" then
            return _mw6cVj:FindFirstChild("Head") or _mw6cVj:FindFirstChild("HumanoidRootPart")
        elseif _Y7CfRG == "Torso" then
            return _mw6cVj:FindFirstChild("Torso") or _mw6cVj:FindFirstChild("UpperTorso") or _mw6cVj:FindFirstChild("HumanoidRootPart")
        else
            return _mw6cVj:FindFirstChild("HumanoidRootPart") or _mw6cVj:FindFirstChild("Torso") or _mw6cVj:FindFirstChild("Head")
        end
    end
    _lH0uIxY.pick = function(_JoU0KZw)
        if not RootPart then
            return nil
        end
        local _iDNXUXJF = workspace.CurrentCamera
        local _X9Uvs = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        local _EZPB9rwS = _X9Uvs and (_iDNXUXJF.ViewportSize / 2) or UserInputService:GetMouseLocation()
        local _lHw2fv3 = RootPart.Position
        local _qLfS3V, _XTnTu, _EhD9l
        local function _lTdFV(_qpBrc)
            if _qpBrc == _JoU0KZw then
                return
            end
            local _XChwa, _Eq0W3 = _lH0uIxY.valid(_qpBrc)
            if not _XChwa then
                return
            end
            local _RyDap = _lH0uIxY.targetPart(_qpBrc) or _XChwa
            local _q9Axj = (_RyDap.Position - _lHw2fv3).Magnitude
            if _q9Axj > Config.Misc.LockOnMaxDist then
                return
            end
            local _Xkfpg = _q9Axj
            if Config.Misc.LockOnMode == "Mouse" then
                local _Mu6mD, _t7HRQ = _iDNXUXJF:WorldToViewportPoint(_RyDap.Position)
                if not _t7HRQ then
                    return
                end
                _Xkfpg = (Vector2.new(_Mu6mD.X, _Mu6mD.Y) - _EZPB9rwS).Magnitude
                if _Xkfpg > Config.Misc.LockOnFOV then
                    return
                end
            end
            if not _EhD9l or _Xkfpg < _EhD9l then
                _qLfS3V, _XTnTu, _EhD9l = _XChwa, _Eq0W3, _Xkfpg
            end
        end
        local _SoJzp = {}
        for _f9Nnp, _MXar1 in ipairs(Players:GetPlayers()) do
            if _MXar1.Character then
                _SoJzp[_MXar1.Character] = true
                _lTdFV(_MXar1.Character)
            end
        end
        if Config.Misc.LockOnDummies and World.Live then
            for _tQO_r, _yOUKc in ipairs(World.Live:GetChildren()) do
                if not _SoJzp[_yOUKc] and _yOUKc:IsA("Model") then
                    _lTdFV(_yOUKc)
                end
            end
        end
        return _qLfS3V, _XTnTu
    end
    _lH0uIxY.stop = function()
        _vA5WJ(_wZKifJPa.lockon)
        _wZKifJPa.lockon = nil
        _lH0uIxY.hrp, _lH0uIxY.human = nil, nil
        State.mark("lockon", nil)
        State.freeRotate()
    end
    _lH0uIxY.start = function()
        local _foJYS, _M24Ym = _lH0uIxY.pick()
        if not _foJYS then
            _OS0SJ({Title = "ZRHUB", Description = "no one to lock on to", Source = "Lock On"})
            return
        end
        _lH0uIxY.hrp, _lH0uIxY.human = _foJYS, _M24Ym
        _wZKifJPa.lockon = connectSignal(RunService.Heartbeat, function(_tAtdY)
            local _yt9jo, _fGOyc = _lH0uIxY.hrp, _lH0uIxY.human
            local _MGlPq = not (_yt9jo and _yt9jo.Parent and _fGOyc and _fGOyc.Health > 0 and RootPart) or (_yt9jo.Position - RootPart.Position).Magnitude > Config.Misc.LockOnMaxDist * 1.5
            if _MGlPq then
                if Config.Misc.LockOnSwitch and RootPart then
                    local _B6cBa, _a0a3N = _lH0uIxY.pick(_yt9jo and _yt9jo.Parent)
                    if _B6cBa then
                        _lH0uIxY.hrp, _lH0uIxY.human = _B6cBa, _a0a3N
                        return
                    end
                end
                _lH0uIxY.stop()
                return
            end
            if Config.Misc.LockOnHighlight then
                State.mark("lockon", _yt9jo.Parent, Color3.fromRGB(255, 60, 60))
            else
                State.mark("lockon", nil)
            end
            local _pNO1J = _yt9jo.Position - RootPart.Position
            if Vector3.new(_pNO1J.X, 0, _pNO1J.Z).Magnitude < 1.5 then
                return
            end
            local _hYHGD = Config.Misc.LockOnPrecision
            if _hYHGD < 1 then
                _hYHGD = 1 - (1 - _hYHGD)^(math.min(_tAtdY, 0.1) * 60)
            end
            local _uTwey = _lH0uIxY.targetPart(_yt9jo.Parent) or _yt9jo
            local _PILS0 = _uTwey.Position
            if Config.Misc.LockOnPredict > 0 then
                local _M5Cbk = _yt9jo.AssemblyLinearVelocity
                local _ZRfqj = Config.Misc.LockOnPredict / 100 + getPing(1000) * 0.5
                _PILS0 = _PILS0 + Vector3.new(_M5Cbk.X, _M5Cbk.Y * 0.4, _M5Cbk.Z) * _ZRfqj
            end
            local _CJjuV, _r_Al2 = Config.Misc.LockOnFaceChar, Config.Misc.LockOnCam
            if _ffQog() then
                if _r_Al2 then
                    _GcDR2(0, _PILS0, false, false, nil, _hYHGD)
                end
                return
            end
            if _CJjuV and _r_Al2 then
                _GcDR2(nil, _PILS0, false, true, nil, _hYHGD)
            elseif _CJjuV then
                _GcDR2(nil, _PILS0, true, false, nil, _hYHGD)
            elseif _r_Al2 then
                _GcDR2(0, _PILS0, false, false, nil, _hYHGD)
            end
        end)
    end
    App.sections.LockOnSet:toggle({
        name = "Lock On Enabled",
        def = false,
        pointer = "Lock On Enabled",
        callback = function(_EUlXk)
            Config.Misc.LockOnEnabled = _EUlXk
            _vA5WJ(_wZKifJPa.lockon)
            _wZKifJPa.lockon = nil
            if not _EUlXk then
                State.mark("lockon", nil)
                State.freeRotate()
            end
        end
    })
    App.sections.LockOnSet:slider({
        name = "Lock On Precision",
        def = 100,
        max = 100,
        min = 0,
        rounding = true,
        pointer = "lockonprec",
        callback = function(_hCZqO)
            Config.Misc.LockOnPrecision = _hCZqO / 100
        end
    })
    App.sections.LockOnKey = App.sections.LockOnSet:keybind({
        name = "Lock On Keybind",
        def = nil,
        pointer = "Lock On Keybind",
        callback = function(_umKSu)
            if not Config.Misc.LockOnEnabled then
                return
            end
            if _wZKifJPa.lockon then
                if not Config.Misc.LockOnHold then
                    _lH0uIxY.stop()
                end
            else
                _lH0uIxY.start()
            end
        end
    })
    connectSignal(ZR_InputEnded, function(_H2aF3)
        if not (Config.Misc.LockOnHold and _wZKifJPa.lockon) then
            return
        end
        local _kizqg = App.sections.LockOnKey and App.sections.LockOnKey.current
        if not (_kizqg and _kizqg[1]) then
            return
        end
        if (_kizqg[1] == "KeyCode" and _H2aF3.KeyCode.Name == _kizqg[2]) or (_kizqg[1] == "UserInputType" and _H2aF3.UserInputType.Name == _kizqg[2]) then
            _lH0uIxY.stop()
        end
    end)
    App.sections.LockOnSet:dropdown({
        name = "Target Part",
        def = Config.Misc.LockOnTargetPart,
        max = 3,
        options = {"Head", "Torso", "HumanoidRootPart"},
        pointer = "Lock On Target Part",
        tooltip = "Which body part the lock-on camera targets",
        callback = function(_xzMAN)
            Config.Misc.LockOnTargetPart = _xzMAN
        end
    })
    App.sections.LockOnSet:dropdown({
        name = "Target Pick",
        def = Config.Misc.LockOnMode,
        max = 2,
        options = {"Mouse", "Closest"},
        pointer = "Lock On Mode",
        tooltip = "Mouse = whoever is closest to your cursor, Closest = whoever is closest to you",
        callback = function(_u2xED)
            Config.Misc.LockOnMode = _u2xED
        end
    })
    App.sections.LockOnSet:toggle({
        name = "Hold To Lock",
        def = Config.Misc.LockOnHold,
        pointer = "Lock On Hold",
        tooltip = "Only locks while you hold the lock on key",
        callback = function(_PcDml)
            Config.Misc.LockOnHold = _PcDml
        end
    })
    App.sections.LockOnSet:toggle({
        name = "Highlight Target",
        def = Config.Misc.LockOnHighlight,
        pointer = "Lock On Highlight",
        callback = function(_cFuWQ)
            Config.Misc.LockOnHighlight = _cFuWQ
            if not _cFuWQ then
                State.mark("lockon", nil)
            end
        end
    })
    App.sections.LockOnSet:toggle({
        name = "Lock Dummies",
        def = Config.Misc.LockOnDummies,
        pointer = "Lock On Dummies",
        callback = function(_Z8X7L)
            Config.Misc.LockOnDummies = _Z8X7L
        end
    })
    App.sections.LockOnSet:toggle({
        name = "Switch On Death",
        def = Config.Misc.LockOnSwitch,
        pointer = "Lock On Switch",
        tooltip = "When your target dies or gets too far it moves to the next one instead of turning off",
        callback = function(_mncnC)
            Config.Misc.LockOnSwitch = _mncnC
        end
    })
    App.sections.LockOnSet:toggle({
        name = "Turn Camera",
        def = Config.Misc.LockOnCam,
        pointer = "Lock On Camera",
        callback = function(_HzV44)
            Config.Misc.LockOnCam = _HzV44
        end
    })
    App.sections.LockOnSet:toggle({
        name = "Turn Character",
        def = Config.Misc.LockOnFaceChar,
        pointer = "Lock On Face Char",
        callback = function(_EcgDk)
            Config.Misc.LockOnFaceChar = _EcgDk
            if not _EcgDk then
                State.freeRotate()
            end
        end
    })
    App.sections.LockOnSet:slider({
        name = "Prediction",
        def = 0,
        max = 30,
        min = 0,
        rounding = true,
        pointer = "Lock On Predict",
        tooltip = "Aims ahead of moving targets, 0 = off",
        callback = function(_Ru7hl)
            Config.Misc.LockOnPredict = _Ru7hl
        end
    })
    App.sections.LockOnSet:slider({
        name = "Max Distance",
        def = 150,
        max = 400,
        min = 20,
        rounding = true,
        pointer = "Lock On Max Distance",
        callback = function(_uBUp2b)
            Config.Misc.LockOnMaxDist = _uBUp2b
        end
    })
    App.sections.LockOnSet:slider({
        name = "Mouse Range",
        def = 300,
        max = 1000,
        min = 50,
        rounding = true,
        pointer = "Lock On FOV",
        tooltip = "How far from your cursor a target can be (pixels), only for Mouse pick",
        callback = function(_HGNvF3X)
            Config.Misc.LockOnFOV = _HGNvF3X
        end
    })
    App.sections.Misc:toggle({
        name = "Mobile KW Button",
        def = App.isMobile,
        pointer = "Mobile KW Button Toggle",
        callback = function(_U2ddvj)
            App.toggleMobileButton(_U2ddvj)
        end
    })
    App.sections.Notifs:toggle({
        name = "Global Enabled",
        def = true,
        pointer = "Notifications Toggle",
        callback = function(_x8LNK)
            Config.Notifications.GlobalEnabled = _x8LNK
        end
    })
    App.sections.Notifs:toggle({
        name = "Ult Notifications",
        def = true,
        pointer = "Ult Notifications Toggle",
        callback = function(_KrbVQ68h)
            Config.Notifications.UltEnabled = _KrbVQ68h
        end
    })
    App.sections.Notifs:toggle({
        name = "Death Counter Notifications",
        def = true,
        pointer = "Death Counter Notifications Toggle",
        callback = function(_z6qCHgl)
            Config.Notifications.DeathCounterEnabled = _z6qCHgl
        end
    })
    App.sections.Notifs:toggle({
        name = "Auto Tech Notifications",
        def = true,
        pointer = "Auto Tech Notifications Toggle",
        callback = function(_ccwzMr)
            Config.Notifications.AutoTechEnabled = _ccwzMr
        end
    })
    App.sections.Notifs:toggle({
        name = "Fling Notifications",
        def = true,
        pointer = "Fling Notifications Toggle",
        callback = function(_LvoVn)
            Config.Notifications.FlingEnabled = _LvoVn
        end
    })
    State.CharCopy = {
        userId = nil,
        keep = true,
        name = "",
        cache = {}
    }
    State.CharCopy.resolve = function(_O0T4UgGR)
        _O0T4UgGR = tostring(_O0T4UgGR or ""):match("^%s*(.-)%s*$")
        if _O0T4UgGR == "" then
            return nil
        end
        if _O0T4UgGR:match("^%d+$") then
            return tonumber(_O0T4UgGR), _O0T4UgGR
        end
        local _tcUNTlP = _O0T4UgGR:lower()
        for _gxpfEF, _iBAkV_ in ipairs(Players:GetPlayers()) do
            if _iBAkV_.Name:lower() == _tcUNTlP or _iBAkV_.DisplayName:lower() == _tcUNTlP then
                return _iBAkV_.UserId, _iBAkV_.Name
            end
        end
        local _XB1KO, _A6Zr32 = pcall(Players.GetUserIdFromNameAsync, Players, _O0T4UgGR)
        if _XB1KO and _A6Zr32 then
            return _A6Zr32, _O0T4UgGR
        end
        return nil
    end
    State.CharCopy.fromAssets = function(_hJer0)
        local _Sxtpv = pcall(function()
            return game.GetObjects
        end)
        if not (_Sxtpv or getobjects) then
            return nil
        end
        local _KJ3Rp = function(_rgMzr)
            local _AnMxR, _p6PWC = pcall(function()
                if _Sxtpv then
                    return game:GetObjects("rbxassetid://" .. _rgMzr)
                end
                return getobjects("rbxassetid://" .. _rgMzr)
            end)
            return _AnMxR and _p6PWC or {}
        end
        local _zDlDo = Instance.new("Model")
        local _Iy3BB, _hgueH = pcall(function()
            return _hJer0:GetAccessories(true)
        end)
        for _S6EsP, _Xa1cd in ipairs(_Iy3BB and _hgueH or {}) do
            for _AVwfz, _pCilu in ipairs(_KJ3Rp(_Xa1cd.AssetId)) do
                if _pCilu:IsA("Accoutrement") then
                    _pCilu.Parent = _zDlDo
                end
            end
        end
        for _SiWoU, _HnJVk in ipairs({"Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}) do
            local _kRUYb = _hJer0[_HnJVk]
            if _kRUYb and _kRUYb ~= 0 then
                for _pKAok, _aVbK8 in ipairs(_KJ3Rp(_kRUYb)) do
                    for _zcarb, _I6hZv in ipairs(_aVbK8:GetDescendants()) do
                        if _I6hZv:IsA("CharacterMesh") then
                            _I6hZv.Parent = _zDlDo
                        end
                    end
                end
            end
        end
        for _xbXbV, _SyG4l in ipairs({"Shirt", "Pants", "GraphicTShirt", "Face"}) do
            local _pQTVC = _hJer0[_SyG4l]
            if _pQTVC and _pQTVC ~= 0 then
                for _gJpnW, _HQs8D in ipairs(_KJ3Rp(_pQTVC)) do
                    if _HQs8D:IsA("Clothing") or _HQs8D:IsA("ShirtGraphic") then
                        _HQs8D.Parent = _zDlDo
                    elseif _HQs8D:IsA("Decal") then
                        local _Wnp5d = _zDlDo:FindFirstChild("Head") or Instance.new("Part")
                        _Wnp5d.Name = "Head"
                        _Wnp5d.Parent = _zDlDo
                        _HQs8D.Name = "face"
                        _HQs8D.Parent = _Wnp5d
                    end
                end
            end
        end
        return _zDlDo
    end
    State.CharCopy.build = function(_pxC1I)
        local _MfZJU = State.CharCopy
        if _MfZJU.cache[_pxC1I] then
            return _MfZJU.cache[_pxC1I]
        end
        local _XZEmi, _TCD7l = pcall(Players.GetHumanoidDescriptionFromUserId, Players, _pxC1I)
        if not _XZEmi or not _TCD7l then
            return nil, "couldn't get their avatar"
        end
        local _glQvv = (Humanoid and Humanoid.RigType) or Enum.HumanoidRigType.R6
        local _FlXjP, _CORtI = pcall(Players.CreateHumanoidModelFromDescription, Players, _TCD7l, _glQvv)
        if not (_FlXjP and _CORtI) then
            _CORtI = _MfZJU.fromAssets(_TCD7l)
            if not _CORtI then
                return nil, "your executor can't load their avatar"
            end
        end
        local _LfqeL = {model = _CORtI, desc = _TCD7l}
        _MfZJU.cache[_pxC1I] = _LfqeL
        return _LfqeL
    end
    State.CharCopy.isOld = function(_oZiOf, _hUDQN)
        local _u_SCt = _hUDQN:IsA("Accoutrement")
        if not (_u_SCt or _hUDQN:IsA("Clothing") or _hUDQN:IsA("ShirtGraphic") or _hUDQN:IsA("BodyColors") or _hUDQN:IsA("CharacterMesh")) then
            return false
        end
        if _hUDQN:GetAttribute("KWChar") then
            return false
        end
        if _u_SCt then
            local _T5mGr = _hUDQN:FindFirstChild("Handle")
            local _gDIO5 = _T5mGr and _T5mGr:FindFirstChildOfClass("Attachment")
            if not (_gDIO5 and State.CharCopy.rigAttachments[_gDIO5.Name]) then
                return false
            end
        end
        local _xG2Lh = _hUDQN
        while _xG2Lh and _xG2Lh ~= _oZiOf do
            if _xG2Lh:GetAttribute("KWChar") or State.cape[_xG2Lh.Name] or State.aura[_xG2Lh.Name] or _xG2Lh.Name == "CosmeticAuras" then
                return false
            end
            _xG2Lh = _xG2Lh.Parent
        end
        return true
    end
    State.CharCopy.rigAttachments = _DQit6({
        "HatAttachment",
        "HairAttachment",
        "FaceFrontAttachment",
        "FaceCenterAttachment",
        "NeckAttachment",
        "BodyFrontAttachment",
        "BodyBackAttachment",
        "LeftCollarAttachment",
        "RightCollarAttachment",
        "WaistFrontAttachment",
        "WaistCenterAttachment",
        "WaistBackAttachment",
        "LeftShoulderAttachment",
        "RightShoulderAttachment",
        "LeftGripAttachment",
        "RightGripAttachment",
        "LeftFootAttachment",
        "RightFootAttachment"
    })
    App.weldAccessory = function(_j6zNd, _gLuFA)
        local _FvucX = _gLuFA:FindFirstChild("Handle")
        if not _FvucX then
            return
        end
        local _SdFTL = _FvucX:FindFirstChildOfClass("Attachment")
        local _LJNXztt
        for _Y6uDhx, _x8BxO in ipairs(_j6zNd:GetChildren()) do
            if _SdFTL and _x8BxO:IsA("BasePart") then
                _LJNXztt = _x8BxO:FindFirstChild(_SdFTL.Name)
                if _LJNXztt then
                    break
                end
            end
        end
        _gLuFA.Parent = _j6zNd
        if _LJNXztt and _LJNXztt:IsA("Attachment") then
            _FvucX.CFrame = _LJNXztt.WorldCFrame * _SdFTL.CFrame:Inverse()
            local _uDdPEWck = Instance.new("Weld")
            _uDdPEWck.Name = "AccessoryWeld"
            _uDdPEWck.Part0 = _FvucX
            _uDdPEWck.Part1 = _LJNXztt.Parent
            _uDdPEWck.C0 = _SdFTL.CFrame
            _uDdPEWck.C1 = _LJNXztt.CFrame
            _uDdPEWck.Parent = _FvucX
        else
            local _D_IhV43 = _j6zNd:FindFirstChild("Head")
            if _D_IhV43 then
                local _gg28LP = Instance.new("Weld")
                _gg28LP.Part0 = _FvucX
                _gg28LP.Part1 = _D_IhV43
                _gg28LP.C1 = CFrame.new(0, 0.6, 0)
                _gg28LP.Parent = _FvucX
            end
        end
    end
    State.CharCopy.apply = function(_xejiH, _qyyXVH)
        if not (_xejiH and _qyyXVH and _qyyXVH.model) then
            return
        end
        local _RE096Rf = _xejiH:FindFirstChildOfClass("Humanoid")
        if not _RE096Rf then
            return
        end
        local _EiKRVx6m = State.CharCopy
        if _EiKRVx6m.watch then
            _EiKRVx6m.watch:Disconnect()
            _EiKRVx6m.watch = nil
        end
        for _LBn6g, _iJov7ypI in ipairs(_xejiH:GetDescendants()) do
            if _iJov7ypI:GetAttribute("KWChar") or _EiKRVx6m.isOld(_xejiH, _iJov7ypI) then
                _iJov7ypI:Destroy()
            end
        end
        for _ZhHfFKF, _cI9bO in ipairs(_qyyXVH.model:GetChildren()) do
            if _cI9bO:IsA("Accoutrement") then
                local _DNBp8 = _cI9bO:Clone()
                _DNBp8:SetAttribute("KWChar", true)
                for _q4oXz, _wUuTS in ipairs(_DNBp8:GetDescendants()) do
                    if _wUuTS:IsA("BasePart") then
                        _wUuTS.CanCollide = false
                        _wUuTS.CanTouch = false
                        _wUuTS.CanQuery = false
                        _wUuTS.Massless = true
                    end
                end
                local _l_j2A = pcall(_RE096Rf.AddAccessory, _RE096Rf, _DNBp8)
                if not _l_j2A or not _DNBp8:FindFirstChild("AccessoryWeld", true) then
                    App.weldAccessory(_xejiH, _DNBp8)
                end
            elseif _cI9bO:IsA("Clothing") or _cI9bO:IsA("ShirtGraphic") or _cI9bO:IsA("BodyColors") or _cI9bO:IsA("CharacterMesh") then
                local _Kx6hL = _cI9bO:Clone()
                _Kx6hL:SetAttribute("KWChar", true)
                _Kx6hL.Parent = _xejiH
            end
        end
        if _EiKRVx6m.userId then
            _EiKRVx6m.watch = _xejiH.DescendantAdded:Connect(function(_rni8t)
                if _EiKRVx6m.userId and Character == _xejiH then
                    if _EiKRVx6m.isOld(_xejiH, _rni8t) then
                        task.defer(_rni8t.Destroy, _rni8t)
                    end
                elseif _EiKRVx6m.watch then
                    _EiKRVx6m.watch:Disconnect()
                    _EiKRVx6m.watch = nil
                end
            end)
        end
        local _g5Tdp = _qyyXVH.desc
        if _g5Tdp then
            local _FBy6r = {
                Head = _g5Tdp.HeadColor,
                Torso = _g5Tdp.TorsoColor,
                UpperTorso = _g5Tdp.TorsoColor,
                LowerTorso = _g5Tdp.TorsoColor,
                ["Left Arm"] = _g5Tdp.LeftArmColor,
                LeftUpperArm = _g5Tdp.LeftArmColor,
                LeftLowerArm = _g5Tdp.LeftArmColor,
                LeftHand = _g5Tdp.LeftArmColor,
                ["Right Arm"] = _g5Tdp.RightArmColor,
                RightUpperArm = _g5Tdp.RightArmColor,
                RightLowerArm = _g5Tdp.RightArmColor,
                RightHand = _g5Tdp.RightArmColor,
                ["Left Leg"] = _g5Tdp.LeftLegColor,
                LeftUpperLeg = _g5Tdp.LeftLegColor,
                LeftLowerLeg = _g5Tdp.LeftLegColor,
                LeftFoot = _g5Tdp.LeftLegColor,
                ["Right Leg"] = _g5Tdp.RightLegColor,
                RightUpperLeg = _g5Tdp.RightLegColor,
                RightLowerLeg = _g5Tdp.RightLegColor,
                RightFoot = _g5Tdp.RightLegColor
            }
            for _KwODE, _zGA5S in pairs(_FBy6r) do
                local _YrZNV = _xejiH:FindFirstChild(_KwODE)
                if _YrZNV and _YrZNV:IsA("BasePart") then
                    _YrZNV.Color = _zGA5S
                end
            end
        end
        local _Ne9i1 = _xejiH:FindFirstChild("Head")
        local _S9QWI = _qyyXVH.model:FindFirstChild("Head")
        local _rVyI_ = _S9QWI and (_S9QWI:FindFirstChild("face") or _S9QWI:FindFirstChildWhichIsA("Decal"))
        local _gDKdr = _Ne9i1 and (_Ne9i1:FindFirstChild("face") or _Ne9i1:FindFirstChildWhichIsA("Decal"))
        if _gDKdr and not _EiKRVx6m.ownFace then
            _EiKRVx6m.ownFace = _gDKdr.Texture
        end
        if _gDKdr and (_rVyI_ or _EiKRVx6m.userId == nil) then
            _gDKdr.Texture = _rVyI_ and _rVyI_.Texture or _EiKRVx6m.ownFace
        elseif _Ne9i1 and _rVyI_ then
            _rVyI_:Clone().Parent = _Ne9i1
        end
        if Config.Visuals.Korblox then
            task.defer(function()
                _K0t9W(true)
            end)
        end
        if Config.Visuals.SelfChams.Enabled then
            task.defer(_oQwzM)
        end
    end
    State.CharCopy.set = function(_lGjNX)
        local _KYiuT = State.CharCopy
        local _zh9EA, _gyWBP = _KYiuT.resolve(_lGjNX)
        if not _zh9EA then
            _OS0SJ({Title = "ZRHUB", Description = "couldn't find a player called " .. tostring(_lGjNX), Source = "Char"})
            return
        end
        _KYiuT.press = (_KYiuT.press or 0) + 1
        local _VHKsO = _KYiuT.press
        local _uBMw_, _zU4o7 = _KYiuT.build(_zh9EA)
        if _VHKsO ~= _KYiuT.press then
            return
        end
        if not _uBMw_ then
            _OS0SJ({Title = "ZRHUB", Description = "char: " .. tostring(_zU4o7), Source = "Char"})
            return
        end
        _KYiuT.userId = _zh9EA
        _KYiuT.apply(Character, _uBMw_)
        _OS0SJ({Title = "ZRHUB", Description = "you look like " .. tostring(_gyWBP or _zh9EA) .. " now (only you can see it)", Source = "Char"})
    end
    State.CharCopy.reapply = function(_Ic6T9)
        local _j0W9K = State.CharCopy
        local _eXYuR = _j0W9K.userId
        if not _eXYuR then
            return
        end
        task.wait(0.5)
        if Character ~= _Ic6T9 or _j0W9K.userId ~= _eXYuR then
            return
        end
        local _pJFB4 = _j0W9K.build(_eXYuR)
        if _pJFB4 then
            _j0W9K.apply(_Ic6T9, _pJFB4)
        end
    end
    State.CharCopy.reset = function()
        local _Q2IkY = State.CharCopy
        if not _Q2IkY.userId then
            return
        end
        _Q2IkY.press = (_Q2IkY.press or 0) + 1
        _Q2IkY.userId = nil
        if _Q2IkY.watch then
            _Q2IkY.watch:Disconnect()
            _Q2IkY.watch = nil
        end
        local _b3tDH = _Q2IkY.build(LocalPlayer.UserId)
        if _b3tDH then
            _Q2IkY.apply(Character, _b3tDH)
        end
        _OS0SJ({Title = "ZRHUB", Description = "back to your own avatar", Source = "Char"})
    end
    App.sections.VisualCharCopy:textbox({
        name = "Username",
        def = "",
        placeholder = "username, display name or id",
        callback = function(_W9ctx)
            State.CharCopy.name = tostring(_W9ctx or "")
        end
    })
    App.sections.VisualCharCopy:toggle({
        name = "Keep After Respawn",
        def = true,
        pointer = "Char Keep",
        callback = function(_xyc__)
            State.CharCopy.keep = _xyc__
        end
    })
    App.sections.VisualCharCopy:button({
        name = "Become Them",
        callback = function()
            task.spawn(State.CharCopy.set, State.CharCopy.name)
        end
    })
    App.sections.VisualCharCopy:button({
        name = "Reset To Me",
        callback = function()
            task.spawn(State.CharCopy.reset)
        end
    })
    pcall(function()
        local _IQXNq = {}
        for _b5KKF, _CCF0t in ipairs(App.window.tabsbuttons:GetChildren()) do
            if _CCF0t:IsA("Frame") then
                table.insert(_IQXNq, _CCF0t)
            end
        end
        for _NIRCj, _Nlf95 in ipairs(_IQXNq) do
            _Nlf95.Size = UDim2.new(1 / #_IQXNq, -2, 1, 0)
        end
    end)
    for _ixniA, _nTFs8 in pairs(App.sections) do
        local _sgggm = type(_nTFs8) == "table" and _nTFs8.sectionholder and _nTFs8.content and _nTFs8.content:FindFirstChildOfClass("UIListLayout")
        if _sgggm then
            local function _NCfzA()
                local _S0Ezu = _sgggm.AbsoluteContentSize.Y / math.max(App.window.uiscale.Scale, 0.01)
                if _S0Ezu > 5 then
                    _nTFs8.sectionholder.Size = UDim2.new(1, 0, 0, math.ceil(_S0Ezu) + 30)
                end
            end
            _sgggm:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(_NCfzA)
            task.defer(_NCfzA)
        end
    end
    App.pages.Combat:openpage()
    if false then
        task.delay(1, function()
            if not Unloaded then
                App.autoload.load(true)
            end
        end)
    end
end
for _Xm0V5, _sJblL in pairs(Players:GetPlayers()) do
    App.setupPlayer(_sJblL)
end
connectSignal(Players.PlayerAdded, App.setupPlayer)
connectSignal(Players.PlayerRemoving, function(_x6QVr)
    disconnectAll(CharacterConnections[_x6QVr])
    disconnectAll(PlayerConnections[_x6QVr])
    CharacterConnections[_x6QVr] = nil
    PlayerConnections[_x6QVr] = nil
    PlayerFrames[_x6QVr.Name] = nil
end)
if LocalPlayer.Character then
    task.spawn(pcall, onCharacterAdded, LocalPlayer.Character)
end
connectSignal(LocalPlayer.CharacterAdded, function(_SgBgJ)
    task.spawn(pcall, onCharacterAdded, _SgBgJ)
end)
connectSignal(LocalPlayer.CharacterRemoving, function(_v7dfv)
    pcall(onCharacterRemoving)
end)
if World.Thrown and World.Thrown.DescendantAdded then
    connectSignal(World.Thrown.DescendantAdded, onDescendantAdded)
end
connectSignal(World.Terrain.DescendantAdded, onDescendantAdded)
connectSignal(Lighting:GetPropertyChangedSignal("GlobalShadows"), function()
    if Config.Visuals.NoShadows and Lighting.GlobalShadows then
        Lighting.GlobalShadows = false
    end
end)
connectSignal(Lighting:GetPropertyChangedSignal("ClockTime"), function()
    if SkyManager.locking or not Config.Visuals.Sky.Enabled then
        return
    end
    local _ADJk9hd6 = SkyManager.presets[Config.Visuals.Sky.Preset]
    if _ADJk9hd6 and math.abs(Lighting.ClockTime - _ADJk9hd6.clock) > 0.05 then
        SkyManager.locking = true
        Lighting.ClockTime = _ADJk9hd6.clock
        SkyManager.locking = false
    end
end)
connectSignal(Lighting.ChildAdded, function(_VQDoB)
    if Config.Visuals.Sky.Enabled and (_VQDoB:IsA("Sky") or _VQDoB:IsA("Atmosphere")) then
        if _VQDoB.Name ~= "KittySky" and _VQDoB.Name ~= "KittySkyAtmosphere" then
            task.defer(function()
                if Config.Visuals.Sky.Enabled then
                    SkyManager.apply(true)
                end
            end)
        end
    end
end)
connectSignal(LocalPlayer:GetAttributeChangedSignal("S_AutoUnequip"), function()
    _TLppj = LocalPlayer:GetAttribute("S_AutoUnequip")
end)
connectSignal(ZR_InputBegan, function(_aeMvC7, _fEGjUoR)
    if _fEGjUoR then
        return
    end
    if _aeMvC7.KeyCode == KeyQ and Character then
        if not UserInputService:IsKeyDown(KeyD) and not UserInputService:IsKeyDown(KeyA) and Config.Misc.NoDashEndLag and not UserInputService:IsKeyDown(KeyS) and Character:FindFirstChild("UsedDash") then
            _XjK2G()
        elseif Config.Rage.NoSideDashCooldown and (UserInputService:IsKeyDown(KeyD) or UserInputService:IsKeyDown(KeyA)) and Character then
            local _AUQrW63M = Character:FindFirstChild("InDash")
            if _AUQrW63M then
                _AUQrW63M:Destroy()
            end
            local _FhBL5 = Character:FindFirstChild("UsedDash")
            if _FhBL5 then
                _FhBL5:Destroy()
            end
        end
    end
end)
connectSignal(RunService.Heartbeat, function()
    if Humanoid and _mzv8k then
        Humanoid.AutoRotate = false
    end
    if Config.Rage.NoSideDashCooldown and Character then
        if Character:GetAttribute("CustomSideDashCooldown") ~= 0 then
            pcall(Character.SetAttribute, Character, "CustomSideDashCooldown", 0)
        end
        local _avNyLj = Character:FindFirstChild("InDash")
        if _avNyLj then
            pcall(_avNyLj.Destroy, _avNyLj)
        end
        local _VVXXG3h = Character:FindFirstChild("UsedDash")
        if _VVXXG3h then
            pcall(_VVXXG3h.Destroy, _VVXXG3h)
        end
        _zk6rn(true)
    end
end)
task.spawn(function()
    while not Unloaded do
        task.wait(20)
        for _Qmmm7E in pairs(ActiveConnections) do
            if not _Qmmm7E.Connected then
                ActiveConnections[_Qmmm7E] = nil
            end
        end
        local _vyYH8 = tick()
        for _qY0OtNw9, _NveaeWt in pairs(State.eventStamp) do
            if _vyYH8 - _NveaeWt > 5 then
                State.eventStamp[_qY0OtNw9] = nil
            end
        end
    end
end)
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    App.optimizeMobile()
end

pcall(function() ZR_Library:OnUnload(function() pcall(App.unload) end) end)

end

LoadVexonHub()

end

end

executorResult = checkExecutorSupport()
StartNormalVersion()
