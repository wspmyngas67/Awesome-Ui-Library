local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local SaveManager = {}
SaveManager.__index = SaveManager

-- ============ CONFIG ============
SaveManager.Library = nil
SaveManager.Window = nil
SaveManager.Folder = "SimpleUI_Configs"
SaveManager.FileExtension = ".json"
SaveManager.AutoSaveInterval = 30
SaveManager.IgnoreIndexes = {}
SaveManager.IgnoreFlags = {}
SaveManager.AutoloadConfig = nil
SaveManager.SaveOnClose = false
SaveManager.Prefix = ""
SaveManager.RemoteRepo = nil
SaveManager.TabName = "Settings"
SaveManager._builtTab = nil
SaveManager._builtPage = nil
SaveManager._section = nil
SaveManager._autoloadEnabled = false
SaveManager._autosaveEnabled = false

-- ============ INTERNAL ============
local function hasIO()
    return isfolder and makefolder and writefile and readfile and isfile and listfiles and delfile
end

local function joinPath(a, b)
    if not a or a == "" then return b end
    if not b or b == "" then return a end
    return a .. "/" .. b
end

local function mkdirRecursive(path)
    if not hasIO() then return false end
    local parts = {}
    for part in path:gmatch("[^/\\]+") do table.insert(parts, part) end
    local cur = ""
    for i, p in ipairs(parts) do
        cur = (i == 1) and p or (cur .. "/" .. p)
        if not isfolder(cur) then
            local ok = pcall(makefolder, cur)
            if not ok then return false end
        end
    end
    return true
end

local function configPath(self, name)
    return joinPath(self.Folder, name .. self.FileExtension)
end

local function humanSize(bytes)
    if not bytes or bytes <= 0 then return "0 B" end
    if bytes < 1024 then return bytes .. " B" end
    if bytes < 1024 * 1024 then return string.format("%.1f KB", bytes / 1024) end
    return string.format("%.1f MB", bytes / 1024 / 1024)
end

local function humanTime(epoch)
    if not epoch then return "unknown" end
    local diff = os.time() - epoch
    if diff < 0 then diff = 0 end
    if diff < 60 then return diff .. "s ago" end
    if diff < 3600 then return math.floor(diff / 60) .. "m ago" end
    if diff < 86400 then return math.floor(diff / 3600) .. "h ago" end
    return math.floor(diff / 86400) .. "d ago"
end

-- ============ SETTERS ============
function SaveManager:SetLibrary(lib)
    self.Library = lib
    return self
end

function SaveManager:SetWindow(w)
    self.Window = w
    return self
end

function SaveManager:SetFolder(path)
    self.Folder = path or "SimpleUI_Configs"
    if hasIO() then mkdirRecursive(self.Folder) end
    return self
end

function SaveManager:SetFileExtension(ext)
    ext = ext or ".json"
    if ext:sub(1, 1) ~= "." then ext = "." .. ext end
    self.FileExtension = ext
    return self
end

function SaveManager:SetIgnoreIndexes(t)
    self.IgnoreIndexes = t or {}
    return self
end

function SaveManager:SetIgnoreFlags(t)
    self.IgnoreFlags = t or {}
    return self
end

function SaveManager:SetAutoSaveInterval(seconds)
    self.AutoSaveInterval = math.max(5, tonumber(seconds) or 30)
    return self
end

function SaveManager:SetAutoloadConfig(name)
    self.AutoloadConfig = name
    self._autoloadEnabled = name ~= nil
    return self
end

function SaveManager:SetSaveOnClose(enabled)
    self.SaveOnClose = enabled and true or false
    return self
end

function SaveManager:SetRemoteRepo(repo)
    self.RemoteRepo = repo
    return self
end

function SaveManager:SetPrefix(prefix)
    self.Prefix = prefix or ""
    return self
end

function SaveManager:SetTabName(name)
    self.TabName = name or "Settings"
    return self
end

function SaveManager:IgnoreThemeSettings()
    table.insert(self.IgnoreFlags, "ui_theme")
    table.insert(self.IgnoreFlags, "ui_theme_accent")
    return self
end

-- ============ CORE API ============
function SaveManager:Save(name)
    local lib = self.Library
    if not lib then warn("[SaveManager] Library not set"); return false end
    name = name or "default"
    if not hasIO() then
        if lib.Notify then lib:Notify({Title="Save Failed", Text="No file I/O", Duration=4}) end
        return false
    end
    if not mkdirRecursive(self.Folder) then return false end

    local ignoreSet = {}
    for _, v in ipairs(self.IgnoreIndexes) do ignoreSet[v] = true end
    for _, v in ipairs(self.IgnoreFlags) do ignoreSet[v] = true end

    local data = {_version = "4.0", _saved = os.time(), _folder = self.Folder, flags = {}}
    for k, v in pairs(lib.Flags) do
        if not ignoreSet[k] then
            if typeof(v) == "Color3" then
                data.flags[k] = {__type="Color3", r=v.R, g=v.G, b=v.B}
            elseif typeof(v) == "EnumItem" then
                data.flags[k] = {__type="Enum", name=v.Name, enumType=tostring(v.EnumType)}
            elseif typeof(v) == "Vector3" then
                data.flags[k] = {__type="Vector3", x=v.X, y=v.Y, z=v.Z}
            elseif typeof(v) == "CFrame" then
                data.flags[k] = {__type="CFrame", pos={v.X, v.Y, v.Z}}
            else
                data.flags[k] = v
            end
        end
    end

    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end
    local path = configPath(self, name)
    local wok = pcall(writefile, path, encoded)
    if wok then
        if lib.Notify then lib:Notify({Title="Config Saved", Text="'"..name.."'", Duration=3}) end
        return true
    end
    return false
end

function SaveManager:Load(name)
    local lib = self.Library
    if not lib then warn("[SaveManager] Library not set"); return false end
    name = name or "default"
    if not hasIO() then
        if lib.Notify then lib:Notify({Title="Load Failed", Text="No file I/O", Duration=4}) end
        return false
    end
    local path = configPath(self, name)
    if not isfile(path) then
        if lib.Notify then lib:Notify({Title="Not Found", Text="'"..name.."'", Duration=4}) end
        return false
    end

    local ok, raw = pcall(readfile, path)
    if not ok then return false end
    local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not dok or not data or not data.flags then return false end

    for k, v in pairs(data.flags) do
        if type(v) == "table" and v.__type == "Color3" then
            lib.Flags[k] = Color3.new(v.r, v.g, v.b)
        elseif type(v) == "table" and v.__type == "Enum" then
            local ok2, enum = pcall(function() return Enum[v.enumType][v.name] end)
            if not ok2 then pcall(function() lib.Flags[k] = Enum.KeyCode[v.name] end)
            else lib.Flags[k] = enum end
        elseif type(v) == "table" and v.__type == "Vector3" then
            lib.Flags[k] = Vector3.new(v.x, v.y, v.z)
        else
            lib.Flags[k] = v
        end

        local el = lib.ElementsByFlag and lib.ElementsByFlag[k]
        if el and el._applyLoaded then
            pcall(el._applyLoaded, lib.Flags[k])
        end
    end

    if lib.Notify then lib:Notify({Title="Loaded", Text="'"..name.."' applied", Duration=3}) end
    return true
end

function SaveManager:Delete(name)
    if not hasIO() then return false end
    local path = configPath(self, name)
    if isfile(path) then
        pcall(delfile, path)
        return true
    end
    return false
end

function SaveManager:List()
    if not hasIO() then return {} end
    if not isfolder(self.Folder) then return {} end
    local out = {}
    for _, f in ipairs(listfiles(self.Folder)) do
        local n = f:match("([^/\\]+)$")
        if n then
            local stripped = n:gsub(self.FileExtension:gsub("%.", "%%.") .. "$", "")
            if stripped ~= n then table.insert(out, stripped) end
        end
    end
    return out
end

function SaveManager:GetInfo(name)
    local path = configPath(self, name)
    if not hasIO() or not isfile(path) then return nil end
    local info = {name = name, size = 0}
    local ok, raw = pcall(readfile, path)
    if ok and raw then
        info.size = #raw
        local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if dok and data then
            info.saved = data._saved
            info.flagCount = 0
            if data.flags then
                for _ in pairs(data.flags) do info.flagCount += 1 end
            end
        end
    end
    return info
end

function SaveManager:LoadAutoloadConfig()
    if self.AutoloadConfig then
        task.spawn(function()
            task.wait(0.5)
            self:Load(self.AutoloadConfig)
        end)
    end
end

-- ============ UI HELPERS ============
local function makeUI(lib)
    local function Create(class, props)
        local i = Instance.new(class)
        for k, v in pairs(props or {}) do i[k] = v end
        return i
    end
    return {
        Create = Create,
        Corner = function(r) return Create("UICorner", {CornerRadius = UDim.new(0, r or 8)}) end,
        Stroke = function(c, t, tr) return Create("UIStroke", {Color = c or lib.Theme.Border, Thickness = t or 1, Transparency = tr or 0}) end,
        Gradient = function(c1, c2, rot) return Create("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rot or 45}) end,
        Tween = function(o, t, p, s, d)
            local tw = TweenService:Create(o, TweenInfo.new(t or 0.2, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p)
            tw:Play(); return tw
        end,
    }
end

-- ============ SECTION BUILDER ============
function SaveManager:BuildInto(page)
    local lib = self.Library
    if not lib then warn("[SaveManager] Library not set"); return nil end
    if not page then warn("[SaveManager] Need a ScrollingFrame page"); return nil end

    local UI = makeUI(lib)
    local Create = UI.Create

    local section = {Page = page, Rows = {}}
    self._section = section
    self._builtPage = page

    local currentName = self.AutoloadConfig or "_default"
    local nameBox

    -- ===== NAME INPUT =====
    local nameHolder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = lib.Theme.Secondary, BorderSizePixel = 0, Parent = page,
    })
    UI.Corner(8).Parent = nameHolder
    UI.Stroke(lib.Theme.Border, 1, 0.3).Parent = nameHolder
    UI.Gradient(lib.Theme.Secondary, lib.Theme.Tertiary, 45).Parent = nameHolder

    Create("TextLabel", {
        Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1, Text = "Config Name",
        TextColor3 = lib.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = nameHolder,
    })

    local box = Create("TextBox", {
        Size = UDim2.new(0.55, -14, 0, 26), Position = UDim2.new(0.45, 0, 0.5, -13),
        BackgroundColor3 = lib.Theme.Tertiary, Text = currentName,
        PlaceholderText = "myLoadout", PlaceholderColor3 = lib.Theme.SubText,
        TextColor3 = lib.Theme.Text, Font = Enum.Font.Gotham, TextSize = 12,
        BorderSizePixel = 0, ClearTextOnFocus = false, Parent = nameHolder,
    })
    UI.Corner(6).Parent = box

    box.Focused:Connect(function() UI.Tween(box, 0.15, {BackgroundColor3 = lib.Theme.Accent}) end)
    box.FocusLost:Connect(function()
        UI.Tween(box, 0.15, {BackgroundColor3 = lib.Theme.Tertiary})
        currentName = (box.Text ~= "" and box.Text) or "_default"
    end)

    nameBox = {
        Set = function(v) box.Text = v; currentName = v end,
        Get = function() return currentName end,
    }
    section.NameBox = nameBox

    -- ===== ACTION ROW =====
    local actionsRow = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = page,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = actionsRow,
    })

    local function mkBtn(text, color, cb)
        local btn = Create("TextButton", {
            Size = UDim2.new(0, 88, 1, 0),
            BackgroundColor3 = color or lib.Theme.Secondary, Text = text,
            TextColor3 = lib.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 12,
            BorderSizePixel = 0, AutoButtonColor = false, Parent = actionsRow,
        })
        UI.Corner(6).Parent = btn
        UI.Stroke(lib.Theme.Border, 1, 0.4).Parent = btn
        btn.MouseEnter:Connect(function()
            if not UserInputService.TouchEnabled then UI.Tween(btn, 0.15, {BackgroundColor3 = lib.Theme.Accent}) end
        end)
        btn.MouseLeave:Connect(function()
            UI.Tween(btn, 0.15, {BackgroundColor3 = color or lib.Theme.Secondary})
        end)
        btn.MouseButton1Click:Connect(cb)
        return btn
    end

    mkBtn("Save", Color3.fromRGB(50, 140, 80), function()
        self:Save(currentName); self:Refresh()
    end)
    mkBtn("Load", Color3.fromRGB(50, 100, 200), function()
        self:Load(currentName)
    end)
    mkBtn("Delete", Color3.fromRGB(180, 60, 60), function()
        self:Delete(currentName); self:Refresh()
    end)
    mkBtn("Refresh", lib.Theme.Secondary, function()
        self:Refresh()
    end)

    -- ===== AUTOSAVE TOGGLE =====
    local autosaveRow = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = lib.Theme.Secondary, Text = "", BorderSizePixel = 0,
        AutoButtonColor = false, Parent = page,
    })
    UI.Corner(8).Parent = autosaveRow
    UI.Stroke(lib.Theme.Border, 1, 0.3).Parent = autosaveRow
    UI.Gradient(lib.Theme.Secondary, lib.Theme.Tertiary, 45).Parent = autosaveRow

    Create("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1, Text = "Auto-save every " .. self.AutoSaveInterval .. "s",
        TextColor3 = lib.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = autosaveRow,
    })

    local autoBg = Create("Frame", {
        Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = self._autosaveEnabled and lib.Theme.Accent or lib.Theme.Tertiary,
        BorderSizePixel = 0, Parent = autosaveRow,
    })
    UI.Corner(11).Parent = autoBg
    local autoKnob = Create("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = self._autosaveEnabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Parent = autoBg,
    })
    UI.Corner(9).Parent = autoKnob

    local autosaveRunning = false

    local function setAuto(v)
        self._autosaveEnabled = v
        UI.Tween(autoBg, 0.2, {BackgroundColor3 = v and lib.Theme.Accent or lib.Theme.Tertiary})
        UI.Tween(autoKnob, 0.2, {Position = v and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}, Enum.EasingStyle.Back)

        if v and not autosaveRunning then
            autosaveRunning = true
            if lib.Notify then lib:Notify({Title = "Autosave ON", Text = "Every " .. self.AutoSaveInterval .. "s", Duration = 3}) end
            task.spawn(function()
                while autosaveRunning and self._autosaveEnabled do
                    task.wait(self.AutoSaveInterval)
                    if autosaveRunning and self._autosaveEnabled then
                        pcall(function() self:Save(currentName .. "_auto") end)
                    end
                end
            end)
        elseif not v then
            autosaveRunning = false
            if lib.Notify then lib:Notify({Title = "Autosave OFF", Duration = 2}) end
        end
    end

    autosaveRow.MouseButton1Click:Connect(function() setAuto(not self._autosaveEnabled) end)

    -- ===== AUTOLOAD DROPDOWN =====
    local autoloadHolder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = lib.Theme.Secondary, BorderSizePixel = 0, Parent = page,
    })
    UI.Corner(8).Parent = autoloadHolder
    UI.Stroke(lib.Theme.Border, 1, 0.3).Parent = autoloadHolder
    UI.Gradient(lib.Theme.Secondary, lib.Theme.Tertiary, 45).Parent = autoloadHolder

    Create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1, Text = "Autoload on start",
        TextColor3 = lib.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = autoloadHolder,
    })

    local autoloadBtn = Create("TextButton", {
        Size = UDim2.new(0, 140, 0, 26), Position = UDim2.new(1, -154, 0.5, -13),
        BackgroundColor3 = lib.Theme.Tertiary, Text = self.AutoloadConfig or "(none)",
        TextColor3 = lib.Theme.Text, Font = Enum.Font.Gotham, TextSize = 12,
        BorderSizePixel = 0, AutoButtonColor = false, Parent = autoloadHolder,
    })
    UI.Corner(6).Parent = autoloadBtn

    local autoloadPopup = Create("Frame", {
        Size = UDim2.new(0, 200, 0, 0), Position = UDim2.new(1, -154, 1, 4),
        BackgroundColor3 = lib.Theme.Tertiary, BorderSizePixel = 0,
        Visible = false, ZIndex = 60, Parent = autoloadHolder,
    })
    UI.Corner(8).Parent = autoloadPopup
    UI.Stroke(lib.Theme.Border, 1, 0.2).Parent = autoloadPopup
    Create("UIListLayout", {
        Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = autoloadPopup,
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = autoloadPopup,
    })

    local autoloadExpanded = false

    local function refreshAutoload()
        for _, c in ipairs(autoloadPopup:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local opts = {"(none)"}
        for _, n in ipairs(self:List()) do table.insert(opts, n) end

        for i, opt in ipairs(opts) do
            local oBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = (opt == self.AutoloadConfig) and lib.Theme.Accent or lib.Theme.Secondary,
                Text = "  " .. opt, TextColor3 = lib.Theme.Text,
                Font = Enum.Font.Gotham, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
                AutoButtonColor = false, LayoutOrder = i, ZIndex = 61, Parent = autoloadPopup,
            })
            UI.Corner(6).Parent = oBtn
            oBtn.MouseButton1Click:Connect(function()
                self.AutoloadConfig = (opt == "(none)") and nil or opt
                autoloadBtn.Text = self.AutoloadConfig or "(none)"
                autoloadExpanded = false
                autoloadPopup.Visible = false
                UI.Tween(autoloadPopup, 0.2, {Size = UDim2.new(0, 200, 0, 0)})
            end)
        end
    end

    autoloadBtn.MouseButton1Click:Connect(function()
        autoloadExpanded = not autoloadExpanded
        autoloadPopup.Visible = autoloadExpanded
        local h = (#self:List() + 1) * 27 + 8
        UI.Tween(autoloadPopup, 0.2, {
            Size = autoloadExpanded and UDim2.new(0, 200, 0, h) or UDim2.new(0, 200, 0, 0)
        }, Enum.EasingStyle.Quart)
        if autoloadExpanded then refreshAutoload() end
    end)

    -- ===== SAVED LIST =====
    local listHolder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = page,
    })
    Create("UIListLayout", {
        Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listHolder,
    })

    local function buildRow(info)
        local row = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundColor3 = lib.Theme.Secondary, BorderSizePixel = 0, Parent = listHolder,
        })
        UI.Corner(8).Parent = row
        UI.Stroke(lib.Theme.Border, 1, 0.4).Parent = row
        UI.Gradient(lib.Theme.Secondary, lib.Theme.Tertiary, 45).Parent = row

        Create("TextLabel", {
            Size = UDim2.new(1, -140, 0, 20), Position = UDim2.new(0, 12, 0, 4),
            BackgroundTransparency = 1, Text = info.name,
            TextColor3 = lib.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })

        Create("TextLabel", {
            Size = UDim2.new(1, -140, 0, 14), Position = UDim2.new(0, 12, 0, 24),
            BackgroundTransparency = 1,
            Text = string.format("%s • %s • %d flags",
                humanTime(info.saved), humanSize(info.size), info.flagCount or 0),
            TextColor3 = lib.Theme.SubText, Font = Enum.Font.Gotham, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })

        local function rowBtn(txt, x, col, cb)
            local b = Create("TextButton", {
                Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(1, x, 0.5, -17),
                BackgroundColor3 = col, Text = txt, TextColor3 = Color3.fromRGB(255,255,255),
                Font = Enum.Font.GothamBold, TextSize = 12,
                BorderSizePixel = 0, AutoButtonColor = false, Parent = row,
            })
            UI.Corner(6).Parent = b
            b.MouseButton1Click:Connect(cb)
        end

        rowBtn("▶", -120, Color3.fromRGB(50, 100, 200), function()
            currentName = info.name
            nameBox.Set(info.name)
            self:Load(info.name)
        end)
        rowBtn("✎", -82, lib.Theme.Tertiary, function()
            nameBox.Set(info.name)
            currentName = info.name
            if lib.Notify then lib:Notify({Title = "Rename", Text = "Type new name, Save, then Delete old", Duration = 4}) end
        end)
        rowBtn("✕", -44, Color3.fromRGB(180, 60, 60), function()
            self:Delete(info.name)
            if lib.Notify then lib:Notify({Title = "Deleted", Text = info.name, Duration = 2}) end
            self:Refresh()
        end)
    end

    -- ===== IMPORT/EXPORT =====
    local exportHolder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = lib.Theme.Secondary, BorderSizePixel = 0, Parent = page,
    })
    UI.Corner(8).Parent = exportHolder
    UI.Stroke(lib.Theme.Border, 1, 0.3).Parent = exportHolder

    local exportBox = Create("TextBox", {
        Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1, Text = "",
        PlaceholderText = "Paste JSON to import...",
        PlaceholderColor3 = lib.Theme.SubText, TextColor3 = lib.Theme.Text,
        Font = Enum.Font.Code, TextSize = 11, Parent = exportHolder,
    })

    local ioRow = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = page,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ioRow,
    })

    local function mkIOBtn(text, cb)
        local btn = Create("TextButton", {
            Size = UDim2.new(0, 110, 1, 0),
            BackgroundColor3 = lib.Theme.Secondary, Text = text,
            TextColor3 = lib.Theme.Text, Font = Enum.Font.Gotham, TextSize = 12,
            BorderSizePixel = 0, AutoButtonColor = false, Parent = ioRow,
        })
        UI.Corner(6).Parent = btn
        UI.Stroke(lib.Theme.Border, 1, 0.4).Parent = btn
        btn.MouseButton1Click:Connect(cb)
        return btn
    end

    mkIOBtn("Export Current", function()
        if not hasIO() then return end
        local path = configPath(self, currentName)
        if not isfile(path) then return end
        local ok, raw = pcall(readfile, path)
        if ok then
            exportBox.Text = raw
            if setclipboard then
                pcall(setclipboard, raw)
                if lib.Notify then lib:Notify({Title = "Exported", Text = "Copied!", Duration = 3}) end
            end
        end
    end)

    mkIOBtn("Import From Box", function()
        if not hasIO() then return end
        local raw = exportBox.Text
        if not raw or raw == "" then return end
        local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if not dok or not data or not data.flags then
            if lib.Notify then lib:Notify({Title = "Import Failed", Text = "Invalid JSON", Duration = 3}) end
            return
        end
        mkdirRecursive(self.Folder)
        local target = currentName ~= "_default" and currentName or ("imported_" .. os.time())
        pcall(writefile, configPath(self, target), raw)
        if lib.Notify then lib:Notify({Title = "Imported", Text = target, Duration = 3}) end
        self:Refresh()
    end)

    mkIOBtn("Copy To Clipboard", function()
        if setclipboard then
            pcall(setclipboard, exportBox.Text)
            if lib.Notify then lib:Notify({Title = "Copied", Duration = 2}) end
        end
    end)

    -- ===== REFRESH =====
    function SaveManager:Refresh()
        for _, c in ipairs(listHolder:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
        end

        if not hasIO() then
            Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
                Text = "⚠ File I/O not supported by this executor",
                TextColor3 = Color3.fromRGB(255, 150, 80),
                Font = Enum.Font.Gotham, TextSize = 12, Parent = listHolder,
            })
            return
        end

        mkdirRecursive(self.Folder)
        local names = self:List()
        if #names == 0 then
            Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
                Text = "No configs saved yet",
                TextColor3 = lib.Theme.SubText, Font = Enum.Font.Gotham, TextSize = 12,
                Parent = listHolder,
            })
            return
        end

        local infos = {}
        for _, n in ipairs(names) do
            local info = self:GetInfo(n)
            if info then table.insert(infos, info) end
        end
        table.sort(infos, function(a, b) return (a.saved or 0) > (b.saved or 0) end)
        for _, info in ipairs(infos) do buildRow(info) end

        if autoloadExpanded then refreshAutoload() end
    end

    section.Refresh = function() self:Refresh() end
    task.spawn(function() self:Refresh() end)

    return section
end

-- ============ RAYFIELD-STYLE API ============
-- Accepts either:
--   • a Tab object (has .Page)
--   • a ScrollingFrame page directly
function SaveManager:BuildConfigSection(target)
    local lib = self.Library
    if not lib then warn("[SaveManager] SetLibrary first!"); return nil end
    if not target then warn("[SaveManager] BuildConfigSection needs a Tab or Page"); return nil end

    local page = target
    local tab

    -- If it's a Tab object (has .Page), use its page and register the tab
    if type(target) == "table" and target.Page then
        page = target.Page
        tab = target
    end

    if not page then warn("[SaveManager] Invalid target"); return nil end

    -- Add a section header if this is a Tab object
    if tab and tab.AddSection then
        tab:AddSection("Save Manager")
    end

    local section = self:BuildInto(page)
    section.Tab = tab
    self._builtTab = tab
    self._builtPage = page

    if lib.Notify then
        task.delay(0.3, function()
            lib:Notify({Title = "Save Manager", Text = "Config section built", Duration = 3})
        end)
    end

    return section
end

-- ============ AUTO-CREATE / REUSE SETTINGS TAB ============
function SaveManager:_getOrCreateSettingsTab(Window)
    if not Window then return nil, false end
    for _, t in ipairs(Window.Tabs or {}) do
        if t.Name and t.Name:lower() == self.TabName:lower() then
            return t, false
        end
    end
    local t = Window:CreateTab(self.TabName)
    return t, true
end

-- Convenience wrapper — auto-creates "Settings" tab if missing
function SaveManager:Attach(Window)
    local lib = self.Library
    if not lib then warn("[SaveManager] SetLibrary first!"); return nil end
    if not Window then warn("[SaveManager] Attach needs a Window"); return nil end

    self.Window = Window
    local tab, created = self:_getOrCreateSettingsTab(Window)

    local section = self:BuildConfigSection(tab)
    if section then section.WasCreated = created end
    return tab, section
end

-- ============ REMOTE BROWSER ============
function SaveManager:ListRemote()
    if not self.RemoteRepo then return {} end
    local url = "https://api.github.com/repos/" .. self.RemoteRepo .. "/contents/"
    local ok, body = pcall(game.HttpGet, game, url)
    if not ok or not body then return {} end
    local dok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not dok or type(data) ~= "table" then return {} end
    local out = {}
    for _, item in ipairs(data) do
        if item.name:match("%.json$") then
            table.insert(out, {
                name = item.name:gsub("%.json$", ""),
                url = item.download_url,
                size = item.size,
            })
        end
    end
    return out
end

function SaveManager:DownloadRemote(url, saveAs)
    local ok, raw = pcall(game.HttpGet, game, url)
    if not ok or not raw then return false end
    if not mkdirRecursive(self.Folder) then return false end
    pcall(writefile, configPath(self, saveAs), raw)
    if self.Library and self.Library.Notify then
        self.Library:Notify({Title = "Downloaded", Text = saveAs, Duration = 3})
    end
    self:Refresh()
    return true
end

return SaveManagerBox.Set(info.name)
                Library:LoadConfig(info.name)
            end)

            -- Rename (just fills the name field)
            local renB = Create("TextButton", {
                Size = UDim2.new(0, 34, 0, 34),
                Position = UDim2.new(1, -82, 0.5, -17),
                BackgroundColor3 = Library.Theme.Tertiary,
                Text = "✎", TextColor3 = Library.Theme.Text,
                Font = Enum.Font.GothamBold, TextSize = 13,
                BorderSizePixel = 0, AutoButtonColor = false, Parent = row,
            })
            Corner(6).Parent = renB
            renB.MouseButton1Click:Connect(function()
                nameBox.Set(info.name)
                currentName = info.name
                Library:Notify({Title = "Rename", Text = "Type new name, click Save, then Delete old", Duration = 4})
            end)

            -- Delete
            local delB = Create("TextButton", {
                Size = UDim2.new(0, 34, 0, 34),
                Position = UDim2.new(1, -44, 0.5, -17),
                BackgroundColor3 = Color3.fromRGB(180, 60, 60),
                Text = "✕", TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold, TextSize = 12,
                BorderSizePixel = 0, AutoButtonColor = false, Parent = row,
            })
            Corner(6).Parent = delB
            delB.MouseButton1Click:Connect(function()
                Library:DeleteConfig(info.name)
                Library:Notify({Title = "Deleted", Text = info.name, Duration = 2})
                SaveManager:_Refresh()
            end)
        end
    end

    task.spawn(function() SaveManager:_Refresh() end)

    -- ============ IMPORT / EXPORT ============
    SaveTab:AddSection("Import / Export")

    local importBox
    importBox = SaveTab:AddTextbox({
        Text = "Data",
        Placeholder = "Paste JSON here to import...",
        Callback = function() end,
    })

    local ioRow = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Parent = SaveTab.Page,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ioRow,
    })

    local function mkIOBtn(text, cb)
        local btn = Create("TextButton", {
            Size = UDim2.new(0, 110, 1, 0),
            BackgroundColor3 = Library.Theme.Secondary,
            Text = text,
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Parent = ioRow,
        })
        Corner(6).Parent = btn
        Stroke(Library.Theme.Border, 1, 0.4).Parent = btn
        btn.MouseButton1Click:Connect(cb)
        return btn
    end

    mkIOBtn("Export Current", function()
        if not hasIO() then
            Library:Notify({Title = "Export Failed", Text = "No file I/O", Duration = 3}); return
        end
        local path = configPath(currentName)
        if not isfile(path) then
            Library:Notify({Title = "Export Failed", Text = "No such config", Duration = 3}); return
        end
        local ok, raw = pcall(readfile, path)
        if ok and raw then
            importBox.Set(raw)
            if setclipboard then
                pcall(setclipboard, raw)
                Library:Notify({Title = "Exported", Text = "Copied to clipboard!", Duration = 3})
            else
                Library:Notify({Title = "Exported", Text = "Shown in box above", Duration = 3})
            end
        end
    end)

    mkIOBtn("Import From Box", function()
        if not hasIO() then return end
        local raw = importBox.Get()
        if not raw or raw == "" then return end
        local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if not dok or not data or not data.flags then
            Library:Notify({Title = "Import Failed", Text = "Invalid JSON", Duration = 3}); return
        end
        ensureDir()
        local target = currentName ~= "_default" and currentName or ("imported_" .. os.time())
        pcall(writefile, configPath(target), raw)
        Library:Notify({Title = "Imported", Text = target, Duration = 3})
        SaveManager:_Refresh()
    end)

    mkIOBtn("Copy To Clipboard", function()
        if setclipboard then
            pcall(setclipboard, importBox.Get())
            Library:Notify({Title = "Copied", Text = "Config data copied", Duration = 2})
        else
            Library:Notify({Title = "Not Supported", Text = "No clipboard access", Duration = 3})
        end
    end)

    return SaveTab
end

return SaveManager
