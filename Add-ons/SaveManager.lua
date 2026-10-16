local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local SaveManager = {}
SaveManager.__index = SaveManager

local CONFIG_DIR = "SimpleUI_Configs"

-- ============ UTILS ============
local function hasIO()
    return isfolder and makefolder and writefile and readfile and isfile and listfiles
end

local function ensureDir()
    if not hasIO() then return false end
    if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
    return true
end

local function configPath(name)
    return CONFIG_DIR .. "/" .. name .. ".json"
end

local function humanSize(bytes)
    if not bytes then return "0 B" end
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

local function getConfigInfo(name)
    local path = configPath(name)
    if not isfile(path) then return nil end
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

-- ============ CORE ============
function SaveManager:Attach(Library, Window)
    if not Library or not Window then
        warn("[SaveManager] Need Library + Window")
        return nil
    end
    self.Library = Library
    self.Window = Window

    local SaveTab = Window:CreateTab("💾 Save Manager")
    SaveTab:AddSection("Active Config")

    -- Helper wrappers to Library methods
    local function Create(class, props) local i=Instance.new(class); for k,v in pairs(props or {}) do i[k]=v end; return i end
    local function Corner(r) return Create("UICorner",{CornerRadius=UDim.new(0,r or 8)}) end
    local function Stroke(c,t,tr) return Create("UIStroke",{Color=c or Library.Theme.Border,Thickness=t or 1,Transparency=tr or 0}) end
    local function Gradient(c1,c2,rot) return Create("UIGradient",{Color=ColorSequence.new(c1,c2),Rotation=rot or 45}) end
    local function Tween(o,t,p,s,d) local tw=TweenService:Create(o,TweenInfo.new(t or 0.2,s or Enum.EasingStyle.Quad,d or Enum.EasingDirection.Out),p); tw:Play(); return tw end

    -- ============ STATE ============
    local currentName = "_default"
    local nameBox

    nameBox = SaveTab:AddTextbox({
        Text = "Config Name",
        Placeholder = "myLoadout",
        Default = currentName,
        Callback = function(v)
            currentName = (v ~= "" and v) or "_default"
        end,
    })

    -- ============ ACTION ROW ============
    local actionsRow = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Parent = SaveTab.Page,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = actionsRow,
    })

    local function mkActionBtn(text, color, callback)
        local btn = Create("TextButton", {
            Size = UDim2.new(0, 90, 1, 0),
            BackgroundColor3 = color or Library.Theme.Secondary,
            Text = text,
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Parent = actionsRow,
        })
        Corner(6).Parent = btn
        Stroke(Library.Theme.Border, 1, 0.4).Parent = btn
        btn.MouseEnter:Connect(function()
            if not UserInputService.TouchEnabled then Tween(btn, 0.15, {BackgroundColor3 = Library.Theme.Accent}) end
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.15, {BackgroundColor3 = color or Library.Theme.Secondary})
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    mkActionBtn("Save", Color3.fromRGB(50, 140, 80), function()
        Library:SaveConfig(currentName)
        SaveManager:_Refresh()
    end)

    mkActionBtn("Load", Color3.fromRGB(50, 100, 200), function()
        Library:LoadConfig(currentName)
    end)

    mkActionBtn("Delete", Color3.fromRGB(180, 60, 60), function()
        Library:DeleteConfig(currentName)
        SaveManager:_Refresh()
    end)

    -- ============ AUTOSAVE ============
    local autosaveRunning = false

    SaveTab:AddToggle({
        Text = "Auto-save every 30s",
        Default = false,
        Flag = "autosave_enabled",
        Callback = function(v)
            if v and not autosaveRunning then
                autosaveRunning = true
                Library:Notify({Title = "Autosave ON", Text = "Saving to '" .. currentName .. "_auto'", Duration = 3})
                task.spawn(function()
                    while autosaveRunning and Library.Flags.autosave_enabled do
                        task.wait(30)
                        if autosaveRunning and Library.Flags.autosave_enabled then
                            pcall(Library.SaveConfig, Library, currentName .. "_auto")
                        end
                    end
                end)
            elseif not v then
                autosaveRunning = false
                Library:Notify({Title = "Autosave OFF", Duration = 2})
            end
        end,
    })

    -- ============ SAVED LIST ============
    SaveTab:AddSection("Saved Configs")

    local listHolder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = SaveTab.Page,
    })
    Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = listHolder,
    })

    function SaveManager:_Refresh()
        for _, child in ipairs(listHolder:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end

        if not hasIO() then
            Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Text = "⚠ File I/O not supported by this executor",
                TextColor3 = Color3.fromRGB(255, 150, 80),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                Parent = listHolder,
            })
            return
        end

        ensureDir()
        local names = Library:ListConfigs()
        if #names == 0 then
            Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Text = "No configs saved yet",
                TextColor3 = Library.Theme.SubText,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                Parent = listHolder,
            })
            return
        end

        local infos = {}
        for _, n in ipairs(names) do
            local info = getConfigInfo(n)
            if info then table.insert(infos, info) end
        end
        table.sort(infos, function(a, b) return (a.saved or 0) > (b.saved or 0) end)

        for _, info in ipairs(infos) do
            local row = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 46),
                BackgroundColor3 = Library.Theme.Secondary,
                BorderSizePixel = 0,
                Parent = listHolder,
            })
            Corner(8).Parent = row
            Stroke(Library.Theme.Border, 1, 0.4).Parent = row
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = row

            Create("TextLabel", {
                Size = UDim2.new(1, -140, 0, 20),
                Position = UDim2.new(0, 12, 0, 4),
                BackgroundTransparency = 1,
                Text = info.name,
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local meta = string.format("%s • %s • %d flags",
                humanTime(info.saved),
                humanSize(info.size),
                info.flagCount or 0
            )
            Create("TextLabel", {
                Size = UDim2.new(1, -140, 0, 14),
                Position = UDim2.new(0, 12, 0, 24),
                BackgroundTransparency = 1,
                Text = meta,
                TextColor3 = Library.Theme.SubText,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            -- Load
            local loadB = Create("TextButton", {
                Size = UDim2.new(0, 34, 0, 34),
                Position = UDim2.new(1, -120, 0.5, -17),
                BackgroundColor3 = Color3.fromRGB(50, 100, 200),
                Text = "▶", TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold, TextSize = 13,
                BorderSizePixel = 0, AutoButtonColor = false, Parent = row,
            })
            Corner(6).Parent = loadB
            loadB.MouseButton1Click:Connect(function()
                currentName = info.name
                nameBox.Set(info.name)
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
