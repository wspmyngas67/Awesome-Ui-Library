--[[
    omfg im getting tired fixing ts
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local SaveManager = {}
SaveManager.__index = SaveManager

SaveManager.Library = nil
SaveManager.Folder = "SimpleUI_Configs"
SaveManager.FileExtension = ".json"
SaveManager.AutoSaveInterval = 30
SaveManager.IgnoreFlags = {}
SaveManager.AutoloadConfig = nil
SaveManager.SaveOnClose = false
SaveManager.TabName = "Settings"
SaveManager._autosaveEnabled = false
SaveManager._autosaveRunning = false

-- ============ UTILS ============
local function hasIO()
    return isfolder and makefolder and writefile and readfile and isfile and listfiles and delfile
end

local function mkdirR(path)
    if not hasIO() then return false end
    local cur = ""
    for part in path:gmatch("[^/\\]+") do
        cur = (cur == "") and part or (cur .. "/" .. part)
        if not isfolder(cur) then
            if not pcall(makefolder, cur) then return false end
        end
    end
    return true
end

local function cfgPath(self, name)
    return self.Folder .. "/" .. name .. self.FileExtension
end

local function humanSize(b)
    if not b or b <= 0 then return "0 B" end
    if b < 1024 then return b .. " B" end
    if b < 1048576 then return string.format("%.1f KB", b / 1024) end
    return string.format("%.1f MB", b / 1048576)
end

local function humanTime(e)
    if not e then return "unknown" end
    local d = os.time() - e
    if d < 0 then d = 0 end
    if d < 60 then return d .. "s ago" end
    if d < 3600 then return math.floor(d / 60) .. "m ago" end
    if d < 86400 then return math.floor(d / 3600) .. "h ago" end
    return math.floor(d / 86400) .. "d ago"
end

-- ============ SETTERS ============
function SaveManager:SetLibrary(lib) self.Library = lib; return self end
function SaveManager:SetFolder(p) self.Folder = p or "SimpleUI_Configs"; if hasIO() then mkdirR(self.Folder) end; return self end
function SaveManager:SetFileExtension(e) e = e or ".json"; if e:sub(1,1) ~= "." then e = "." .. e end; self.FileExtension = e; return self end
function SaveManager:SetIgnoreFlags(t) self.IgnoreFlags = t or {}; return self end
function SaveManager:SetAutoSaveInterval(s) self.AutoSaveInterval = math.max(5, tonumber(s) or 30); return self end
function SaveManager:SetAutoloadConfig(n) self.AutoloadConfig = n; return self end
function SaveManager:SetTabName(n) self.TabName = n or "Settings"; return self end
function SaveManager:IgnoreThemeSettings() table.insert(self.IgnoreFlags, "ui_theme"); return self end

-- ============ CORE ============
function SaveManager:Save(name)
    local lib = self.Library
    if not lib then warn("[SaveManager] SetLibrary first"); return false end
    name = name or "default"
    if not hasIO() then
        if lib.Notify then lib:Notify({Title = "Save Failed", Text = "No file I/O", Duration = 4}) end
        return false
    end
    mkdirR(self.Folder)

    local ignore = {}
    for _, v in ipairs(self.IgnoreFlags) do ignore[v] = true end

    local data = {_v = "4.1", _saved = os.time(), flags = {}}
    for k, v in pairs(lib.Flags) do
        if not ignore[k] then
            if typeof(v) == "Color3" then
                data.flags[k] = {__t = "Color3", r = v.R, g = v.G, b = v.B}
            elseif typeof(v) == "EnumItem" then
                data.flags[k] = {__t = "Enum", name = v.Name, type = tostring(v.EnumType)}
            elseif typeof(v) == "Vector3" then
                data.flags[k] = {__t = "Vector3", x = v.X, y = v.Y, z = v.Z}
            else
                data.flags[k] = v
            end
        end
    end

    local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end
    local wok = pcall(writefile, cfgPath(self, name), enc)
    if wok then
        if lib.Notify then lib:Notify({Title = "Saved", Text = name, Duration = 3}) end
        return true
    end
    return false
end

function SaveManager:Load(name)
    local lib = self.Library
    if not lib then warn("[SaveManager] SetLibrary first"); return false end
    name = name or "default"
    if not hasIO() then return false end
    local path = cfgPath(self, name)
    if not isfile(path) then
        if lib.Notify then lib:Notify({Title = "Not Found", Text = name, Duration = 3}) end
        return false
    end

    local ok, raw = pcall(readfile, path)
    if not ok then return false end
    local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not dok or not data or not data.flags then return false end

    for k, v in pairs(data.flags) do
        if type(v) == "table" and v.__t == "Color3" then
            lib.Flags[k] = Color3.new(v.r, v.g, v.b)
        elseif type(v) == "table" and v.__t == "Enum" then
            local ok2, e = pcall(function() return Enum[v.type][v.name] end)
            lib.Flags[k] = ok2 and e or Enum.KeyCode[v.name]
        elseif type(v) == "table" and v.__t == "Vector3" then
            lib.Flags[k] = Vector3.new(v.x, v.y, v.z)
        else
            lib.Flags[k] = v
        end
        local el = lib.ElementsByFlag and lib.ElementsByFlag[k]
        if el and el._applyLoaded then pcall(el._applyLoaded, lib.Flags[k]) end
    end

    if lib.Notify then lib:Notify({Title = "Loaded", Text = name, Duration = 3}) end
    return true
end

function SaveManager:Delete(name)
    if not hasIO() then return false end
    local p = cfgPath(self, name)
    if isfile(p) then pcall(delfile, p); return true end
    return false
end

function SaveManager:List()
    if not hasIO() or not isfolder(self.Folder) then return {} end
    local out = {}
    for _, f in ipairs(listfiles(self.Folder)) do
        local n = f:match("([^/\\]+)$")
        if n then
            local s = n:gsub(self.FileExtension:gsub("%.", "%%.") .. "$", "")
            if s ~= n then table.insert(out, s) end
        end
    end
    return out
end

function SaveManager:GetInfo(name)
    local p = cfgPath(self, name)
    if not hasIO() or not isfile(p) then return nil end
    local i = {name = name, size = 0}
    local ok, raw = pcall(readfile, p)
    if ok and raw then
        i.size = #raw
        local dok, d = pcall(function() return HttpService:JSONDecode(raw) end)
        if dok and d then
            i.saved = d._saved
            i.flagCount = 0
            if d.flags then for _ in pairs(d.flags) do i.flagCount += 1 end end
        end
    end
    return i
end

function SaveManager:LoadAutoloadConfig()
    if self.AutoloadConfig then
        task.spawn(function() task.wait(0.5); self:Load(self.AutoloadConfig) end)
    end
end

-- ============ UI ============
local function mkUI(lib)
    local function C(class, props)
        local i = Instance.new(class)
        for k, v in pairs(props or {}) do i[k] = v end
        return i
    end
    return {
        C = C,
        Corner = function(r) return C("UICorner", {CornerRadius = UDim.new(0, r or 8)}) end,
        Stroke = function(c, t, tr) return C("UIStroke", {Color = c or lib.Theme.Border, Thickness = t or 1, Transparency = tr or 0}) end,
        Gradient = function(c1, c2, rot) return C("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rot or 45}) end,
        Tween = function(o, t, p, s, d)
            local tw = TweenService:Create(o, TweenInfo.new(t or 0.2, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p)
            tw:Play(); return tw
        end,
    }
end

function SaveManager:BuildInto(page)
    local lib = self.Library
    if not lib then warn("[SaveManager] SetLibrary first"); return nil end
    if not page then warn("[SaveManager] Need a page (ScrollingFrame)"); return nil end

    local UI = mkUI(lib)
    local C = UI.C
    local currentName = self.AutoloadConfig or "_default"

    -- === NAME INPUT ===
    local nh = C("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = lib.Theme.Secondary, BorderSizePixel = 0, Parent = page,
    })
    UI.Corner(8).Parent = nh
    UI.Stroke(lib.Theme.Border, 1, 0.3).Parent = nh
    UI.Gradient(lib.Theme.Secondary, lib.Theme.Tertiary, 45).Parent = nh

    C("TextLabel", {
        Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1, Text = "Config Name",
        TextColor3 = lib.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = nh,
    })

    local box = C("TextBox", {
        Size = UDim2.new(0.55, -14, 0, 26), Position = UDim2.new(0.45, 0, 0.5, -13),
        BackgroundColor3 = lib.Theme.Tertiary, Text = currentName,
        PlaceholderText = "myLoadout", PlaceholderColor3 = lib.Theme.SubText,
        TextColor3 = lib.Theme.Text, Font = Enum.Font.Gotham, TextSize = 12,
        BorderSizePixel = 0, ClearTextOnFocus = false, Parent = nh,
    })
    UI.Corner(6).Parent = box
    box.FocusLost:Connect(function()
        currentName = (box.Text ~= "" and box.Text) or "_default"
    end)

    -- === ACTION BUTTONS ===
    local ar = C("Frame", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = page,
    })
    C("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ar,
    })

    local function mkBtn(txt, col, cb)
        local b = C("TextButton", {
            Size = UDim2.new(0, 88, 1, 0),
            BackgroundColor3 = col or lib.Theme.Secondary, Text = txt,
            TextColor3 = lib.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12,
            BorderSizePixel = 0, AutoButtonColor = false, Parent = ar,
        })
        UI.Corner(6).Parent = b
        UI.Stroke(lib.Theme.Border, 1, 0.4).Parent = b
        b.MouseButton1Click:Connect(cb)
        return b
    end

    mkBtn("Save", Color3.fromRGB(50, 140, 80), function() self:Save(currentName); self:Refresh() end)
    mkBtn("Load", Color3.fromRGB(50, 100, 200), function() self:Load(currentName) end)
    mkBtn("Delete", Color3.fromRGB(180, 60, 60), function() self:Delete(currentName); self:Refresh() end)
    mkBtn("Refresh", lib.Theme.Secondary, function() self:Refresh() end)

    -- === AUTOSAVE TOGGLE ===
    local asRow = C("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = lib.Theme.Secondary, Text = "", BorderSizePixel = 0,
        AutoButtonColor = false, Parent = page,
    })
    UI.Corner(8).Parent = asRow
    UI.Stroke(lib.Theme.Border, 1, 0.3).Parent = asRow
    UI.Gradient(lib.Theme.Secondary, lib.Theme.Tertiary, 45).Parent = asRow

    C("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1, Text = "Auto-save every " .. self.AutoSaveInterval .. "s",
        TextColor3 = lib.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = asRow,
    })

    local abg = C("Frame", {
        Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = lib.Theme.Tertiary, BorderSizePixel = 0, Parent = asRow,
    })
    UI.Corner(11).Parent = abg
    local aknob = C("Frame", {
        Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Parent = abg,
    })
    UI.Corner(9).Parent = aknob

    local function setAuto(v)
        self._autosaveEnabled = v
        UI.Tween(abg, 0.2, {BackgroundColor3 = v and lib.Theme.Accent or lib.Theme.Tertiary})
        UI.Tween(aknob, 0.2, {
            Position = v and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        }, Enum.EasingStyle.Back)
        if v and not self._autosaveRunning then
            self._autosaveRunning = true
            task.spawn(function()
                while self._autosaveRunning and self._autosaveEnabled do
                    task.wait(self.AutoSaveInterval)
                    if self._autosaveRunning and self._autosaveEnabled then
                        pcall(function() self:Save(currentName .. "_auto") end)
                    end
                end
            end)
        elseif not v then
            self._autosaveRunning = false
        end
    end
    asRow.MouseButton1Click:Connect(function() setAuto(not self._autosaveEnabled) end)

    -- === SAVED LIST ===
    local lh = C("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = page,
    })
    C("UIListLayout", {
        Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = lh,
    })

    local function buildRow(info)
        local r = C("Frame", {
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = lib.Theme.Secondary, BorderSizePixel = 0, Parent = lh,
        })
        UI.Corner(8).Parent = r
        UI.Stroke(lib.Theme.Border, 1, 0.4).Parent = r
        UI.Gradient(lib.Theme.Secondary, lib.Theme.Tertiary, 45).Parent = r

        C("TextLabel", {
            Size = UDim2.new(1, -140, 0, 20), Position = UDim2.new(0, 12, 0, 4),
            BackgroundTransparency = 1, Text = info.name,
            TextColor3 = lib.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = r,
        })
        C("TextLabel", {
            Size = UDim2.new(1, -140, 0, 14), Position = UDim2.new(0, 12, 0, 24),
            BackgroundTransparency = 1,
            Text = humanTime(info.saved) .. " • " .. humanSize(info.size) .. " • " .. (info.flagCount or 0) .. " flags",
            TextColor3 = lib.Theme.SubText, Font = Enum.Font.Gotham, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = r,
        })

        local function rb(txt, x, col, cb)
            local b = C("TextButton", {
                Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(1, x, 0.5, -17),
                BackgroundColor3 = col, Text = txt, TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0,
                AutoButtonColor = false, Parent = r,
            })
            UI.Corner(6).Parent = b
            b.MouseButton1Click:Connect(cb)
        end

        rb("▶", -120, Color3.fromRGB(50, 100, 200), function()
            box.Text = info.name
            currentName = info.name
            self:Load(info.name)
        end)
        rb("✎", -82, lib.Theme.Tertiary, function()
            box.Text = info.name
            currentName = info.name
        end)
        rb("✕", -44, Color3.fromRGB(180, 60, 60), function()
            self:Delete(info.name); self:Refresh()
        end)
    end

    function SaveManager:Refresh()
        for _, c in ipairs(lh:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
        end
        if not hasIO() then
            C("TextLabel", {
                Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
                Text = "⚠ File I/O not supported",
                TextColor3 = Color3.fromRGB(255, 150, 80),
                Font = Enum.Font.Gotham, TextSize = 12, Parent = lh,
            })
            return
        end
        mkdirR(self.Folder)
        local names = self:List()
        if #names == 0 then
            C("TextLabel", {
                Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
                Text = "No configs saved yet",
                TextColor3 = lib.Theme.SubText, Font = Enum.Font.Gotham, TextSize = 12, Parent = lh,
            })
            return
        end
        local infos = {}
        for _, n in ipairs(names) do
            local i = self:GetInfo(n)
            if i then table.insert(infos, i) end
        end
        table.sort(infos, function(a, b) return (a.saved or 0) > (b.saved or 0) end)
        for _, i in ipairs(infos) do buildRow(i) end
    end

    task.spawn(function() self:Refresh() end)

    -- === IMPORT / EXPORT ===
    local eh = C("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = lib.Theme.Secondary, BorderSizePixel = 0, Parent = page,
    })
    UI.Corner(8).Parent = eh
    UI.Stroke(lib.Theme.Border, 1, 0.3).Parent = eh

    local eb = C("TextBox", {
        Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1, Text = "",
        PlaceholderText = "Paste JSON to import...",
        PlaceholderColor3 = lib.Theme.SubText, TextColor3 = lib.Theme.Text,
        Font = Enum.Font.Code, TextSize = 11, Parent = eh,
    })

    local ior = C("Frame", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = page,
    })
    C("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ior,
    })

    local function ioBtn(txt, cb)
        local b = C("TextButton", {
            Size = UDim2.new(0, 110, 1, 0),
            BackgroundColor3 = lib.Theme.Secondary, Text = txt,
            TextColor3 = lib.Theme.Text, Font = Enum.Font.Gotham, TextSize = 12,
            BorderSizePixel = 0, AutoButtonColor = false, Parent = ior,
        })
        UI.Corner(6).Parent = b
        UI.Stroke(lib.Theme.Border, 1, 0.4).Parent = b
        b.MouseButton1Click:Connect(cb)
    end

    ioBtn("Export", function()
        if not hasIO() then return end
        local p = cfgPath(self, currentName)
        if not isfile(p) then return end
        local ok, raw = pcall(readfile, p)
        if ok then
            eb.Text = raw
            if setclipboard then pcall(setclipboard, raw) end
        end
    end)

    ioBtn("Import", function()
        if not hasIO() then return end
        local raw = eb.Text
        if not raw or raw == "" then return end
        mkdirR(self.Folder)
        local t = currentName ~= "_default" and currentName or ("imported_" .. os.time())
        pcall(writefile, cfgPath(self, t), raw)
        self:Refresh()
    end)

    ioBtn("Copy", function()
        if setclipboard then pcall(setclipboard, eb.Text) end
    end)

    return {Page = page}
end

-- ============ PUBLIC BUILDER ============
function SaveManager:BuildConfigSection(target)
    local lib = self.Library
    if not lib then warn("[SaveManager] SetLibrary first"); return nil end
    if not target then warn("[SaveManager] Need a Tab or Page"); return nil end

    local page, tab

    -- Tab object? (has .Page or .AddSection)
    if type(target) == "table" then
        if target.Page then
            page = target.Page
            tab = target
        elseif target.AddSection then
            tab = target
            page = target.Page or target
        elseif target:IsA("ScrollingFrame") then
            page = target
        end
    elseif typeof(target) == "Instance" and target:IsA("ScrollingFrame") then
        page = target
    end

    if not page then warn("[SaveManager] Could not resolve page from target"); return nil end

    if tab and tab.AddSection then
        pcall(function() tab:AddSection("Save Manager") end)
    end

    return self:BuildInto(page)
end

return SaveManager
