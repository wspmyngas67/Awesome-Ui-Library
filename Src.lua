local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ============ PARENT DETECTION ============
local function GetParent()
    if gethui then local ok, ui = pcall(gethui); if ok and ui then return ui end end
    if syn and syn.protect_gui then
        local ok, sg = pcall(function() local g = Instance.new("ScreenGui"); syn.protect_gui(g); return g end)
        if ok then return sg end
    end
    if get_hidden_gui then local ok, h = pcall(get_hidden_gui); if ok and h then return h end end
    local ok, cg = pcall(function() return CoreGui end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ============ LIBRARY ============
local Library = {}
Library.__index = Library
Library.Flags = {}
Library.Opened = true
Library.ToggleKey = Enum.KeyCode.RightShift
Library.Elements = {}
Library.ElementsByFlag = {}
Library._notifyQueue = {}
Library._notifyActive = false

-- ============ THEMES ============
local Themes = {
    Dark = {
        Background=Color3.fromRGB(20,20,25), Secondary=Color3.fromRGB(30,30,38),
        Tertiary=Color3.fromRGB(42,42,52), Accent=Color3.fromRGB(120,100,255),
        Accent2=Color3.fromRGB(200,90,255), Text=Color3.fromRGB(245,245,250),
        SubText=Color3.fromRGB(150,150,165), Border=Color3.fromRGB(60,60,75),
        Glow=Color3.fromRGB(120,100,255),
    },
    Neon = {
        Background=Color3.fromRGB(10,8,20), Secondary=Color3.fromRGB(18,15,32),
        Tertiary=Color3.fromRGB(30,25,50), Accent=Color3.fromRGB(0,255,200),
        Accent2=Color3.fromRGB(255,0,200), Text=Color3.fromRGB(240,255,250),
        SubText=Color3.fromRGB(120,200,180), Border=Color3.fromRGB(40,80,80),
        Glow=Color3.fromRGB(0,255,200),
    },
    Midnight = {
        Background=Color3.fromRGB(8,12,30), Secondary=Color3.fromRGB(15,20,45),
        Tertiary=Color3.fromRGB(25,32,65), Accent=Color3.fromRGB(80,140,255),
        Accent2=Color3.fromRGB(140,80,255), Text=Color3.fromRGB(235,240,255),
        SubText=Color3.fromRGB(140,155,200), Border=Color3.fromRGB(45,60,110),
        Glow=Color3.fromRGB(80,140,255),
    },
    Blood = {
        Background=Color3.fromRGB(15,8,10), Secondary=Color3.fromRGB(28,12,15),
        Tertiary=Color3.fromRGB(45,18,22), Accent=Color3.fromRGB(255,45,60),
        Accent2=Color3.fromRGB(255,100,40), Text=Color3.fromRGB(255,240,240),
        SubText=Color3.fromRGB(200,140,140), Border=Color3.fromRGB(90,30,35),
        Glow=Color3.fromRGB(255,45,60),
    },
    Ocean = {
        Background=Color3.fromRGB(8,18,28), Secondary=Color3.fromRGB(14,28,42),
        Tertiary=Color3.fromRGB(22,42,62), Accent=Color3.fromRGB(50,200,255),
        Accent2=Color3.fromRGB(100,120,255), Text=Color3.fromRGB(230,245,255),
        SubText=Color3.fromRGB(130,170,200), Border=Color3.fromRGB(35,75,105),
        Glow=Color3.fromRGB(50,200,255),
    },
    Light = {
        Background=Color3.fromRGB(245,245,250), Secondary=Color3.fromRGB(230,230,240),
        Tertiary=Color3.fromRGB(215,215,230), Accent=Color3.fromRGB(120,100,255),
        Accent2=Color3.fromRGB(200,90,255), Text=Color3.fromRGB(25,25,35),
        SubText=Color3.fromRGB(90,90,110), Border=Color3.fromRGB(200,200,215),
        Glow=Color3.fromRGB(120,100,255),
    },
}
Library.Theme = Themes.Dark

-- ============ HELPERS ============
local function Create(class, props)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do i[k] = v end
    return i
end

local function Corner(r)
    return Create("UICorner", {CornerRadius = UDim.new(0, r or 8)})
end

local function Stroke(c, t, tr)
    return Create("UIStroke", {Color = c or Library.Theme.Border, Thickness = t or 1, Transparency = tr or 0})
end

local function Gradient(c1, c2, rot)
    return Create("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rot or 45})
end

local function Tween(o, t, p, s, d)
    local tw = TweenService:Create(o, TweenInfo.new(t or 0.2, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p)
    tw:Play()
    return tw
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
end

-- ============ TOAST QUEUE ============
function Library:_ProcessQueue()
    if Library._notifyActive then return end
    if #Library._notifyQueue == 0 then return end
    Library._notifyActive = true
    local item = table.remove(Library._notifyQueue, 1)
    Library:_ShowToast(item)
end

function Library:_ShowToast(config)
    if not Library.Gui then Library._notifyActive = false; return end
    local parent = Library.Gui

    local note = Create("Frame", {
        Size = UDim2.new(0, 300, 0, 64),
        Position = UDim2.new(1, 340, 0, 20),
        BackgroundColor3 = Library.Theme.Secondary,
        BorderSizePixel = 0,
        Parent = parent,
        ZIndex = 200,
    })
    Corner(10).Parent = note
    Stroke(Library.Theme.Accent, 1.5, 0.3).Parent = note

    local bar = Create("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        Parent = note,
        ZIndex = 201,
    })
    Corner(10).Parent = bar
    Gradient(Library.Theme.Accent, Library.Theme.Accent2, 90).Parent = bar

    Create("TextLabel", {
        Size=UDim2.new(1,-24,0,22), Position=UDim2.new(0,16,0,8),
        BackgroundTransparency=1, Text=config.Title,
        TextColor3=Library.Theme.Text, Font=Enum.Font.GothamBold, TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=note, ZIndex=201,
    })
    Create("TextLabel", {
        Size=UDim2.new(1,-24,0,24), Position=UDim2.new(0,16,0,30),
        BackgroundTransparency=1, Text=config.Text,
        TextColor3=Library.Theme.SubText, Font=Enum.Font.Gotham, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, Parent=note, ZIndex=201,
    })

    local progBg = Create("Frame", {
        Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=Library.Theme.Tertiary, BorderSizePixel=0, Parent=note, ZIndex=201,
    })
    local progFill = Create("Frame", {
        Size=UDim2.new(1,0,1,0), BackgroundColor3=Library.Theme.Accent,
        BorderSizePixel=0, Parent=progBg, ZIndex=202,
    })
    Gradient(Library.Theme.Accent, Library.Theme.Accent2, 0).Parent = progFill

    Tween(note, 0.4, {Position = UDim2.new(1, -320, 0, 20)}, Enum.EasingStyle.Back)
    Tween(progFill, config.Duration or 4, {Size = UDim2.new(0,0,1,0)}, Enum.EasingStyle.Linear)

    task.delay(config.Duration or 4, function()
        if note and note.Parent then
            Tween(note, 0.3, {Position = UDim2.new(1, 340, 0, 20)})
            task.wait(0.35)
            if note then note:Destroy() end
        end
        Library._notifyActive = false
        task.wait(0.1)
        Library:_ProcessQueue()
    end)
end

function Library:Notify(config)
    config = config or {}
    config.Title = config.Title or "Notification"
    config.Text = config.Text or ""
    config.Duration = config.Duration or 4
    table.insert(Library._notifyQueue, config)
    Library:_ProcessQueue()
end

-- ============ CONFIG SAVE/LOAD ============
local CONFIG_FOLDER = "SimpleUI_Configs"

local function ensureFolder()
    if not isfolder or not makefolder then return false end
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    return true
end

function Library:SaveConfig(name)
    name = name or "default"
    if not (writefile and HttpService) then
        self:Notify({Title="Save Failed", Text="Executor doesn't support file I/O", Duration=4})
        return false
    end
    if not ensureFolder() then return false end

    local data = {_version = "3.0", _saved = os.time(), flags = {}}
    for k, v in pairs(Library.Flags) do
        if typeof(v) == "Color3" then
            data.flags[k] = {__type = "Color3", r = v.R, g = v.G, b = v.B}
        elseif typeof(v) == "EnumItem" then
            data.flags[k] = {__type = "Enum", name = v.Name, enumType = tostring(v.EnumType)}
        else
            data.flags[k] = v
        end
    end

    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end

    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    local wok = pcall(function() writefile(path, encoded) end)
    if wok then
        self:Notify({Title="Config Saved", Text="'"..name.."' saved", Duration=3})
        return true
    end
    return false
end

function Library:LoadConfig(name)
    name = name or "default"
    if not (readfile and isfile and HttpService) then
        self:Notify({Title="Load Failed", Text="No file I/O support", Duration=4})
        return false
    end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    if not isfile(path) then
        self:Notify({Title="Config Missing", Text="'"..name.."' not found", Duration=4})
        return false
    end

    local ok, raw = pcall(function() return readfile(path) end)
    if not ok then return false end
    local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not dok or not data or not data.flags then return false end

    for k, v in pairs(data.flags) do
        if type(v) == "table" and v.__type == "Color3" then
            Library.Flags[k] = Color3.new(v.r, v.g, v.b)
        elseif type(v) == "table" and v.__type == "Enum" then
            local ok2, enum = pcall(function() return Enum[v.enumType][v.name] end)
            if ok2 then Library.Flags[k] = enum
            else pcall(function() Library.Flags[k] = Enum.KeyCode[v.name] end) end
        else
            Library.Flags[k] = v
        end

        local el = Library.ElementsByFlag[k]
        if el and el._applyLoaded then
            pcall(el._applyLoaded, Library.Flags[k])
        end
    end

    self:Notify({Title="Config Loaded", Text="'"..name.."' applied", Duration=3})
    return true
end

function Library:ListConfigs()
    if not (listfiles and isfolder) then return {} end
    if not isfolder(CONFIG_FOLDER) then return {} end
    local out = {}
    for _, f in ipairs(listfiles(CONFIG_FOLDER)) do
        local n = f:match("([^/\\]+)%.json$")
        if n then table.insert(out, n) end
    end
    return out
end

function Library:DeleteConfig(name)
    if not (delfile and isfile) then return false end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    if isfile(path) then
        pcall(function() delfile(path) end)
        return true
    end
    return false
end

-- ============ WINDOW ============
function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "SimpleUI"
    local subtitle = config.Subtitle or "v3.0"
    local themeName = config.Theme or "Dark"
    Library.Theme = Themes[themeName] or Themes.Dark
    Library.Elements = {}
    Library.ElementsByFlag = {}

    if Library.Gui then pcall(function() Library.Gui:Destroy() end) end

    local parent = GetParent()
    local gui = Create("ScreenGui", {
        Name = "SimpleUI_" .. tostring(math.random(1000, 9999)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
    })
    gui.Parent = parent
    Library.Gui = gui

    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local defaultSize = isMobile and UDim2.new(0, 320, 0, 420) or UDim2.new(0, 580, 0, 400)

    -- Shadow
    local shadow = Create("Frame", {
        Size = defaultSize, Position = UDim2.new(0.5,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = Library.Theme.Glow, BackgroundTransparency = 0.6,
        BorderSizePixel = 0, ZIndex = 0, Parent = gui,
    })
    Corner(16).Parent = shadow
    Gradient(Library.Theme.Glow, Library.Theme.Accent2, 45).Parent = shadow

    -- Main
    local main = Create("Frame", {
        Name = "Main", Size = defaultSize, Position = UDim2.new(0.5,0,0.5,0),
        AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0, Parent = gui,
    })
    Corner(14).Parent = main
    Stroke(Library.Theme.Border, 1.5, 0.3).Parent = main
    Gradient(Library.Theme.Background, Library.Theme.Secondary, 135).Parent = main

    -- Top bar
    local topBar = Create("Frame", {
        Name = "TopBar", Size = UDim2.new(1,0,0,45),
        BackgroundColor3 = Library.Theme.Secondary, BorderSizePixel = 0, Parent = main,
    })
    Corner(14).Parent = topBar
    Create("Frame", {
        Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-14),
        BackgroundColor3=Library.Theme.Secondary, BorderSizePixel=0, Parent=topBar,
    })

    local accentLine = Create("Frame", {
        Size=UDim2.new(1,-20,0,1.5), Position=UDim2.new(0,10,1,-1),
        BackgroundColor3=Library.Theme.Accent, BorderSizePixel=0, Parent=topBar,
    })
    Gradient(Library.Theme.Accent, Library.Theme.Accent2, 0).Parent = accentLine

    local logo = Create("Frame", {
        Size=UDim2.new(0,10,0,10), Position=UDim2.new(0,14,0.5,-5),
        BackgroundColor3=Library.Theme.Accent, BorderSizePixel=0, Parent=topBar,
    })
    Corner(5).Parent = logo
    Gradient(Library.Theme.Accent, Library.Theme.Accent2, 45).Parent = logo

    task.spawn(function()
        while logo.Parent do
            Tween(logo, 1, {BackgroundTransparency = 0.4}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut); task.wait(1)
            Tween(logo, 1, {BackgroundTransparency = 0}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut); task.wait(1)
        end
    end)

    Create("TextLabel", {
        Size=UDim2.new(1,-160,0,20), Position=UDim2.new(0,32,0,5),
        BackgroundTransparency=1, Text=title, TextColor3=Library.Theme.Text,
        Font=Enum.Font.GothamBold, TextSize=15,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=topBar,
    })
    Create("TextLabel", {
        Size=UDim2.new(1,-160,0,14), Position=UDim2.new(0,32,0,24),
        BackgroundTransparency=1, Text=subtitle, TextColor3=Library.Theme.SubText,
        Font=Enum.Font.Gotham, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=topBar,
    })

    local btnHolder = Create("Frame", {
        Size=UDim2.new(0,110,1,0), Position=UDim2.new(1,-120,0,0),
        BackgroundTransparency=1, Parent=topBar,
    })

    local searchBtn = Create("TextButton", {
        Size=UDim2.new(0,28,0,28), Position=UDim2.new(0,0,0.5,-14),
        BackgroundColor3=Library.Theme.Tertiary, Text="🔍", TextColor3=Library.Theme.Text,
        Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0,
        AutoButtonColor=false, Parent=btnHolder,
    })
    Corner(8).Parent = searchBtn

    local minimizeBtn = Create("TextButton", {
        Size=UDim2.new(0,28,0,28), Position=UDim2.new(0,34,0.5,-14),
        BackgroundColor3=Library.Theme.Tertiary, Text="—", TextColor3=Library.Theme.Text,
        Font=Enum.Font.GothamBold, TextSize=14, BorderSizePixel=0,
        AutoButtonColor=false, Parent=btnHolder,
    })
    Corner(8).Parent = minimizeBtn

    local closeBtn = Create("TextButton", {
        Size=UDim2.new(0,28,0,28), Position=UDim2.new(0,68,0.5,-14),
        BackgroundColor3=Color3.fromRGB(220,60,80), Text="✕", TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextSize=12, BorderSizePixel=0,
        AutoButtonColor=false, Parent=btnHolder,
    })
    Corner(8).Parent = closeBtn

    MakeDraggable(main, topBar)
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local conn
            conn = RunService.RenderStepped:Connect(function() shadow.Position = main.Position end)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if conn then conn:Disconnect() end
                    shadow.Position = main.Position
                end
            end)
        end
    end)

    -- Search bar
    local searchBar = Create("Frame", {
        Size = UDim2.new(1, -24, 0, 0), Position = UDim2.new(0, 12, 0, 51),
        BackgroundColor3 = Library.Theme.Secondary, BorderSizePixel = 0,
        Visible = false, ClipsDescendants = true, Parent = main, ZIndex = 50,
    })
    Corner(8).Parent = searchBar
    Stroke(Library.Theme.Accent, 1.5, 0.3).Parent = searchBar

    local searchBox = Create("TextBox", {
        Size = UDim2.new(1, -16, 1, -4), Position = UDim2.new(0, 8, 0, 2),
        BackgroundTransparency = 1, Text = "",
        PlaceholderText = "Search elements...",
        PlaceholderColor3 = Library.Theme.SubText, TextColor3 = Library.Theme.Text,
        Font = Enum.Font.Gotham, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
        Parent = searchBar,
    })

    -- Nav bar
    local navBar = Create("Frame", {
        Name = "NavBar", Size = UDim2.new(0,130,1,-60),
        Position = UDim2.new(0,8,0,53), BackgroundTransparency = 1, Parent = main,
    })
    Create("UIListLayout", {
        Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder, Parent=navBar,
    })

    local pageHolder = Create("Frame", {
        Name = "PageHolder", Size = UDim2.new(1,-155,1,-60),
        Position = UDim2.new(0,147,0,53), BackgroundTransparency = 1, Parent = main,
    })

    local minimized = false
    local searchOpen = false

    closeBtn.MouseButton1Click:Connect(function()
        pcall(function()
            Tween(main, 0.25, {Size=UDim2.new(0,0,0,0), BackgroundTransparency=1})
            Tween(shadow, 0.25, {Size=UDim2.new(0,0,0,0), BackgroundTransparency=1})
            task.wait(0.3)
            gui:Destroy()
        end)
    end)

    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        local targetSize = minimized and UDim2.new(0, 580, 0, 45) or defaultSize
        Tween(main, 0.3, {Size=targetSize}, Enum.EasingStyle.Back)
        Tween(shadow, 0.3, {Size=targetSize}, Enum.EasingStyle.Back)
        navBar.Visible = not minimized
        pageHolder.Visible = not minimized
        searchBar.Visible = false
        searchOpen = false
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Library.ToggleKey then
            Library.Opened = not Library.Opened
            main.Visible = Library.Opened
            shadow.Visible = Library.Opened
        end
    end)

    -- Mobile toggle
    local mobileToggle = Create("TextButton", {
        Size=UDim2.new(0,55,0,55), Position=UDim2.new(0,15,0.5,-27),
        BackgroundColor3=Library.Theme.Accent, Text="✦", TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextSize=22, BorderSizePixel=0,
        Visible=isMobile, AutoButtonColor=false, Parent=gui, ZIndex=100,
    })
    Corner(28).Parent = mobileToggle
    Gradient(Library.Theme.Accent, Library.Theme.Accent2, 45).Parent = mobileToggle
    Stroke(Color3.fromRGB(255,255,255), 1.5, 0.5).Parent = mobileToggle

    task.spawn(function()
        while mobileToggle.Parent do
            Tween(mobileToggle, 1.2, {
                Size=UDim2.new(0,60,0,60),
                Position=UDim2.new(mobileToggle.Position.X.Scale, mobileToggle.Position.X.Offset-2.5,
                                   mobileToggle.Position.Y.Scale, mobileToggle.Position.Y.Offset-2.5),
            }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
            Tween(mobileToggle, 1.2, {
                Size=UDim2.new(0,55,0,55),
                Position=UDim2.new(mobileToggle.Position.X.Scale, mobileToggle.Position.X.Offset+2.5,
                                   mobileToggle.Position.Y.Scale, mobileToggle.Position.Y.Offset+2.5),
            }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
        end
    end)

    local mtDrag, mtStart
    mobileToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            mtDrag = input.Position; mtStart = mobileToggle.Position
        end
    end)
    mobileToggle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and mtDrag then
            local d = input.Position - mtDrag
            if d.Magnitude > 10 then
                mobileToggle.Position = UDim2.new(mtStart.X.Scale, mtStart.X.Offset+d.X,
                                                   mtStart.Y.Scale, mtStart.Y.Offset+d.Y)
            end
        end
    end)
    mobileToggle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - mtDrag
            if d.Magnitude <= 10 then
                Library.Opened = not Library.Opened
                main.Visible = Library.Opened
                shadow.Visible = Library.Opened
            end
            mtDrag = nil
        end
    end)

    -- ===== WINDOW OBJECT =====
    local Window = {}
    Window.Tabs = {}
    Window.ActiveTab = nil
    Window.Gui = gui
    Window.Main = main

    function Window:SelectTab(tab)
        if Window.ActiveTab == tab then return end
        if Window.ActiveTab then
            Window.ActiveTab.Button.BackgroundColor3 = Library.Theme.Background
            Window.ActiveTab.Button.BackgroundTransparency = 0.6
            if Window.ActiveTab.Indicator then Window.ActiveTab.Indicator.Visible = false end
            Window.ActiveTab.Page.Visible = false
        end
        Window.ActiveTab = tab
        tab.Button.BackgroundColor3 = Library.Theme.Secondary
        tab.Button.BackgroundTransparency = 0
        if tab.Indicator then tab.Indicator.Visible = true end
        tab.Page.Visible = true
    end

    function Window:SetToggleKey(key) Library.ToggleKey = key end

    -- Search toggle
    searchBtn.MouseButton1Click:Connect(function()
        searchOpen = not searchOpen
        if searchOpen then
            Tween(searchBar, 0.25, {Size = UDim2.new(1,-24,0,32)}, Enum.EasingStyle.Quart)
            searchBar.Visible = true
            Tween(navBar, 0.25, {Position = UDim2.new(0,8,0,91)})
            Tween(pageHolder, 0.25, {Position = UDim2.new(0,147,0,91), Size = UDim2.new(1,-155,1,-98)})
            task.wait(0.15)
            searchBox:CaptureFocus()
        else
            Tween(searchBar, 0.25, {Size = UDim2.new(1,-24,0,0)}, Enum.EasingStyle.Quart)
            searchBox.Text = ""
            for _, el in pairs(Library.Elements) do
                if el.Frame and el.Frame.Parent then el.Frame.Visible = true end
            end
            task.wait(0.25)
            searchBar.Visible = false
            Tween(navBar, 0.25, {Position = UDim2.new(0,8,0,53)})
            Tween(pageHolder, 0.25, {Position = UDim2.new(0,147,0,53), Size = UDim2.new(1,-155,1,-60)})
        end
    end)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchBox.Text:lower()
        for _, el in pairs(Library.Elements) do
            if el.Frame and el.Frame.Parent then
                if query == "" then
                    el.Frame.Visible = true
                else
                    el.Frame.Visible = (el.Name or ""):lower():find(query, 1, true) ~= nil
                end
            end
        end
    end)

    -- ===== CREATE TAB =====
    function Window:CreateTab(name)
        local tab = {Name = name}
        local button = Create("TextButton", {
            Size=UDim2.new(1,0,0,36),
            BackgroundColor3=Library.Theme.Background, BackgroundTransparency=0.6,
            Text="   "..name, TextColor3=Library.Theme.Text,
            Font=Enum.Font.GothamMedium, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left, BorderSizePixel=0,
            AutoButtonColor=false, Parent=navBar,
        })
        Corner(8).Parent = button

        local indicator = Create("Frame", {
            Size=UDim2.new(0,3,0.6,0), Position=UDim2.new(0,0,0.5,0),
            AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=Library.Theme.Accent,
            BorderSizePixel=0, Visible=false, Parent=button,
        })
        Corner(2).Parent = indicator
        Gradient(Library.Theme.Accent, Library.Theme.Accent2, 90).Parent = indicator

        button.MouseEnter:Connect(function()
            if not UserInputService.TouchEnabled and Window.ActiveTab ~= tab then
                Tween(button, 0.15, {BackgroundTransparency=0.3})
            end
        end)
        button.MouseLeave:Connect(function()
            if Window.ActiveTab ~= tab then
                Tween(button, 0.15, {BackgroundTransparency=0.6})
            end
        end)

        local page = Create("ScrollingFrame", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0,
            ScrollBarThickness=3, ScrollBarImageColor3=Library.Theme.Accent,
            CanvasSize=UDim2.new(0,0,0,0), Visible=false, Parent=pageHolder,
        })
        local layout = Create("UIListLayout", {
            Padding=UDim.new(0,7), SortOrder=Enum.SortOrder.LayoutOrder, Parent=page,
        })
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+10)
        end)
        Create("UIPadding", {
            PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,6), Parent=page,
        })

        button.MouseButton1Click:Connect(function() Window:SelectTab(tab) end)

        tab.Button = button
        tab.Page = page
        tab.Window = Window
        tab.Indicator = indicator

        local function RegisterElement(frame, name, flag)
            local entry = {Frame=frame, Name=name, Flag=flag}
            table.insert(Library.Elements, entry)
            if flag then Library.ElementsByFlag[flag] = entry end
            return entry
        end

        local function AttachContextMenu(frame, getters)
            if not UserInputService.MouseEnabled then return end
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    local menu = Create("Frame", {
                        Size=UDim2.new(0,170,0,#getters * 28 + 10),
                        Position=UDim2.new(0, input.Position.X, 0, input.Position.Y),
                        BackgroundColor3=Library.Theme.Secondary, BorderSizePixel=0,
                        Parent=gui, ZIndex=500,
                    })
                    Corner(8).Parent = menu
                    Stroke(Library.Theme.Accent, 1.5, 0.3).Parent = menu
                    Create("UIListLayout", {
                        Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder, Parent=menu,
                    })
                    Create("UIPadding", {
                        PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4),
                        PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4), Parent=menu,
                    })

                    local closed = false
                    local function close() if not closed then closed = true; menu:Destroy() end end

                    for i, item in ipairs(getters) do
                        local mBtn = Create("TextButton", {
                            Size=UDim2.new(1,0,0,24),
                            BackgroundColor3=Library.Theme.Tertiary, BackgroundTransparency=0.3,
                            Text="  "..item.Label, TextColor3=Library.Theme.Text,
                            Font=Enum.Font.Gotham, TextSize=12,
                            TextXAlignment=Enum.TextXAlignment.Left, BorderSizePixel=0,
                            AutoButtonColor=false, LayoutOrder=i, Parent=menu,
                        })
                        Corner(6).Parent = mBtn
                        mBtn.MouseEnter:Connect(function()
                            Tween(mBtn, 0.1, {BackgroundColor3=Library.Theme.Accent, BackgroundTransparency=0})
                        end)
                        mBtn.MouseLeave:Connect(function()
                            Tween(mBtn, 0.1, {BackgroundColor3=Library.Theme.Tertiary, BackgroundTransparency=0.3})
                        end)
                        mBtn.MouseButton1Click:Connect(function()
                            close()
                            if item.OnClick then pcall(item.OnClick) end
                        end)
                    end

                    local endConn
                    endConn = UserInputService.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1
                        or inp.UserInputType == Enum.UserInputType.Touch then
                            close()
                            if endConn then endConn:Disconnect() end
                        end
                    end)
                end
            end)
        end

        -- ===== SECTION =====
        function tab:AddSection(text)
            local sectionHolder = Create("Frame", {
                Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, Parent=page,
            })
            local dot = Create("Frame", {
                Size=UDim2.new(0,3,0,14), Position=UDim2.new(0,2,0.5,-7),
                BackgroundColor3=Library.Theme.Accent, BorderSizePixel=0, Parent=sectionHolder,
            })
            Corner(2).Parent = dot
            Gradient(Library.Theme.Accent, Library.Theme.Accent2, 90).Parent = dot
            Create("TextLabel", {
                Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,12,0,0),
                BackgroundTransparency=1, Text=string.upper(text),
                TextColor3=Library.Theme.SubText, Font=Enum.Font.GothamBold, TextSize=11,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=sectionHolder,
            })
            return sectionHolder
        end

        -- ===== LABEL =====
        function tab:AddLabel(text)
            local label = Create("TextLabel", {
                Size=UDim2.new(1,0,0,30), BackgroundColor3=Library.Theme.Secondary,
                BackgroundTransparency=0.5, Text="  "..text, TextColor3=Library.Theme.Text,
                Font=Enum.Font.Gotham, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left, BorderSizePixel=0, Parent=page,
            })
            Corner(8).Parent = label
            RegisterElement(label, text)
            return label
        end

        -- ===== BUTTON =====
        function tab:AddButton(config)
            config = config or {}
            local btn = Create("TextButton", {
                Size=UDim2.new(1,0,0,36), BackgroundColor3=Library.Theme.Secondary,
                Text="", BorderSizePixel=0, AutoButtonColor=false, Parent=page,
            })
            Corner(8).Parent = btn
            Stroke(Library.Theme.Border, 1, 0.3).Parent = btn
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = btn

            Create("TextLabel", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                Text=config.Text or "Button", TextColor3=Library.Theme.Text,
                Font=Enum.Font.GothamMedium, TextSize=13, Parent=btn, ZIndex=2,
            })

            local function ripple(x, y)
                local r = Create("Frame", {
                    Size=UDim2.new(0,0,0,0),
                    Position=UDim2.new(0, x-btn.AbsolutePosition.X, 0, y-btn.AbsolutePosition.Y),
                    AnchorPoint=Vector2.new(0.5,0.5),
                    BackgroundColor3=Library.Theme.Text, BackgroundTransparency=0.7,
                    BorderSizePixel=0, ZIndex=1, Parent=btn,
                })
                Corner(100).Parent = r
                Tween(r, 0.6, {
                    Size=UDim2.new(0, btn.AbsoluteSize.X*2.5, 0, btn.AbsoluteSize.X*2.5),
                    BackgroundTransparency=1,
                })
                task.delay(0.6, function() r:Destroy() end)
            end

            btn.MouseEnter:Connect(function()
                if not UserInputService.TouchEnabled then
                    Tween(btn, 0.2, {BackgroundColor3=Library.Theme.Accent})
                end
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, 0.2, {BackgroundColor3=Library.Theme.Secondary})
            end)
            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    ripple(input.Position.X, input.Position.Y)
                end
            end)
            btn.MouseButton1Click:Connect(function()
                if config.Callback then
                    local ok, err = pcall(config.Callback)
                    if not ok then warn("[SimpleUI] "..tostring(err)) end
                end
            end)

            RegisterElement(btn, config.Text or "Button", config.Flag)
            if config.Config and config.Config.ContextMenu then
                AttachContextMenu(btn, config.Config.ContextMenu)
            end
            return btn
        end

        -- ===== TOGGLE =====
        function tab:AddToggle(config)
            config = config or {}
            local flag = config.Flag
            local callback = config.Callback or function() end

            local holder = Create("TextButton", {
                Size=UDim2.new(1,0,0,36), BackgroundColor3=Library.Theme.Secondary,
                Text="", BorderSizePixel=0, AutoButtonColor=false, Parent=page,
            })
            Corner(8).Parent = holder
            Stroke(Library.Theme.Border, 1, 0.3).Parent = holder
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = holder

            Create("TextLabel", {
                Size=UDim2.new(1,-70,1,0), Position=UDim2.new(0,14,0,0),
                BackgroundTransparency=1, Text=config.Text or "Toggle",
                TextColor3=Library.Theme.Text, Font=Enum.Font.Gotham, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=holder,
            })

            local state = config.Default or false
            local toggleBg = Create("Frame", {
                Size=UDim2.new(0,40,0,22), Position=UDim2.new(1,-54,0.5,-11),
                BackgroundColor3=state and Library.Theme.Accent or Library.Theme.Tertiary,
                BorderSizePixel=0, Parent=holder,
            })
            Corner(11).Parent = toggleBg
            local bgGrad = Gradient(
                state and Library.Theme.Accent or Library.Theme.Tertiary,
                state and Library.Theme.Accent2 or Library.Theme.Tertiary, 0)
            bgGrad.Parent = toggleBg

            local knob = Create("Frame", {
                Size=UDim2.new(0,18,0,18),
                Position=state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9),
                BackgroundColor3=Color3.fromRGB(255,255,255),
                BorderSizePixel=0, Parent=toggleBg,
            })
            Corner(9).Parent = knob

            local function setState(v, fire)
                state = v
                if bgGrad then bgGrad:Destroy() end
                bgGrad = Gradient(
                    state and Library.Theme.Accent or Library.Theme.Tertiary,
                    state and Library.Theme.Accent2 or Library.Theme.Tertiary, 0)
                bgGrad.Parent = toggleBg
                Tween(toggleBg, 0.2, {BackgroundColor3=state and Library.Theme.Accent or Library.Theme.Tertiary})
                Tween(knob, 0.2, {
                    Position=state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
                }, Enum.EasingStyle.Back)
                if flag then Library.Flags[flag] = state end
                if fire ~= false then
                    local ok, err = pcall(callback, state)
                    if not ok then warn("[SimpleUI] "..tostring(err)) end
                end
            end

            holder.MouseButton1Click:Connect(function() setState(not state) end)
            if flag then Library.Flags[flag] = state end

            local entry = RegisterElement(holder, config.Text or "Toggle", flag)
            entry._applyLoaded = function(v) setState(v, true) end

            if config.Config and config.Config.ContextMenu then
                AttachContextMenu(holder, config.Config.ContextMenu)
            end

            return {Set = function(v) setState(v) end, Get = function() return state end}
        end

        -- ===== SLIDER =====
        function tab:AddSlider(config)
            config = config or {}
            local min = config.Min or 0
            local max = config.Max or 100
            local default = config.Default or min
            local suffix = config.Suffix or ""
            local decimals = config.Decimals or 0
            local flag = config.Flag
            local callback = config.Callback or function() end

            local holder = Create("Frame", {
                Size=UDim2.new(1,0,0,55), BackgroundColor3=Library.Theme.Secondary,
                BorderSizePixel=0, Parent=page,
            })
            Corner(8).Parent = holder
            Stroke(Library.Theme.Border, 1, 0.3).Parent = holder
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = holder

            Create("TextLabel", {
                Size=UDim2.new(0.7,0,0,22), Position=UDim2.new(0,14,0,6),
                BackgroundTransparency=1, Text=config.Text or "Slider",
                TextColor3=Library.Theme.Text, Font=Enum.Font.Gotham, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=holder,
            })

            local valueLabel = Create("TextLabel", {
                Size=UDim2.new(0.3,-14,0,22), Position=UDim2.new(0.7,0,0,6),
                BackgroundTransparency=1, Text=tostring(default)..suffix,
                TextColor3=Library.Theme.Accent, Font=Enum.Font.GothamBold, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Right, Parent=holder,
            })

            local barBg = Create("Frame", {
                Size=UDim2.new(1,-28,0,8), Position=UDim2.new(0,14,1,-22),
                BackgroundColor3=Library.Theme.Tertiary, BorderSizePixel=0, Parent=holder,
            })
            Corner(4).Parent = barBg
            local barFill = Create("Frame", {
                Size=UDim2.new(0,0,1,0), BackgroundColor3=Library.Theme.Accent,
                BorderSizePixel=0, Parent=barBg,
            })
            Corner(4).Parent = barFill
            Gradient(Library.Theme.Accent, Library.Theme.Accent2, 0).Parent = barFill

            local knob = Create("Frame", {
                Size=UDim2.new(0,16,0,16), AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(0,0,0.5,0), BackgroundColor3=Color3.fromRGB(255,255,255),
                BorderSizePixel=0, Parent=barBg,
            })
            Corner(8).Parent = knob
            Stroke(Library.Theme.Accent, 2).Parent = knob

            local value = default
            local dragging = false

            local function round(n)
                local m = 10^decimals
                return math.floor(n*m+0.5)/m
            end

            local function updateFromX(x)
                local rel = math.clamp((x - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                value = round(min + (max-min)*rel)
                barFill.Size = UDim2.new(rel,0,1,0)
                knob.Position = UDim2.new(rel,0,0.5,0)
                valueLabel.Text = tostring(value)..suffix
                if flag then Library.Flags[flag] = value end
                local ok, err = pcall(callback, value)
                if not ok then warn("[SimpleUI] "..tostring(err)) end
            end

            local function set(v, fire)
                v = math.clamp(v, min, max)
                value = round(v)
                local rel = (value - min) / (max - min)
                barFill.Size = UDim2.new(rel,0,1,0)
                knob.Position = UDim2.new(rel,0,0.5,0)
                valueLabel.Text = tostring(value)..suffix
                if flag then Library.Flags[flag] = value end
                if fire ~= false then
                    local ok, err = pcall(callback, value)
                    if not ok then warn("[SimpleUI] "..tostring(err)) end
                end
            end

            barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateFromX(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromX(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            set(default, false)

            local entry = RegisterElement(holder, config.Text or "Slider", flag)
            entry._applyLoaded = function(v) set(v, true) end

            return {Set = function(v) set(v) end, Get = function() return value end}
        end

        -- ===== DROPDOWN =====
        function tab:AddDropdown(config)
            config = config or {}
            local options = config.Options or {}
            local multi = config.Multi or false
            local flag = config.Flag
            local callback = config.Callback or function() end
            local selected = {}

            if config.Default then
                if type(config.Default) == "table" then
                    for _, v in ipairs(config.Default) do selected[v] = true end
                else
                    selected[config.Default] = true
                end
            end

            local holder = Create("Frame", {
                Size=UDim2.new(1,0,0,36), BackgroundColor3=Library.Theme.Secondary,
                BorderSizePixel=0, Parent=page, ClipsDescendants=false, ZIndex=5,
            })
            Corner(8).Parent = holder
            Stroke(Library.Theme.Border, 1, 0.3).Parent = holder
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = holder

            local btn = Create("TextButton", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="",
                AutoButtonColor=false, ZIndex=6, Parent=holder,
            })

            Create("TextLabel", {
                Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,14,0,0),
                BackgroundTransparency=1, Text=config.Text or "Dropdown",
                TextColor3=Library.Theme.Text, Font=Enum.Font.Gotham, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6, Parent=btn,
            })

            local valueLabel = Create("TextLabel", {
                Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(1,-50,0,0),
                AnchorPoint=Vector2.new(1,0), BackgroundTransparency=1, Text="None",
                TextColor3=Library.Theme.Accent, Font=Enum.Font.GothamBold, TextSize=12,
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=6, Parent=btn,
            })

            local arrow = Create("TextLabel", {
                Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-26,0,0),
                BackgroundTransparency=1, Text="▼", TextColor3=Library.Theme.SubText,
                Font=Enum.Font.Gotham, TextSize=10, ZIndex=6, Parent=btn,
            })

            local list = Create("Frame", {
                Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,1,4),
                BackgroundColor3=Library.Theme.Tertiary, BorderSizePixel=0,
                Visible=false, ZIndex=50, Parent=holder,
            })
            Corner(8).Parent = list
            Stroke(Library.Theme.Border, 1, 0.2).Parent = list
            Create("UIListLayout", {
                Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder, Parent=list,
            })
            Create("UIPadding", {
                PaddingTop=UDim.new(0,5), PaddingBottom=UDim.new(0,5),
                PaddingLeft=UDim.new(0,5), PaddingRight=UDim.new(0,5), Parent=list,
            })

            local optionButtons = {}
            local expanded = false

            local function updateDisplay()
                local l = {}
                for k, v in pairs(selected) do if v then table.insert(l, k) end end
                if #l == 0 then valueLabel.Text = "None"
                elseif #l == 1 then valueLabel.Text = l[1]
                else valueLabel.Text = l[1].." (+"..(#l-1)..")" end
                local ret = multi and l or l[1]
                if flag then Library.Flags[flag] = ret end
                local ok, err = pcall(callback, ret)
                if not ok then warn("[SimpleUI] "..tostring(err)) end
            end

            local function setExpanded(s)
                expanded = s
                list.Visible = s
                local h = #options * 28 + 10
                Tween(list, 0.25, {
                    Size = s and UDim2.new(1,0,0,h) or UDim2.new(1,0,0,0)
                }, Enum.EasingStyle.Quart)
                arrow.Text = s and "▲" or "▼"
            end

            local function refreshOptions(newOptions)
                options = newOptions or options
                for _, b in pairs(optionButtons) do b:Destroy() end
                optionButtons = {}
                for i, opt in ipairs(options) do
                    local optBtn = Create("TextButton", {
                        Size=UDim2.new(1,0,0,26),
                        BackgroundColor3=selected[opt] and Library.Theme.Accent or Library.Theme.Secondary,
                        BackgroundTransparency=selected[opt] and 0 or 0.4,
                        Text="   "..tostring(opt), TextColor3=Library.Theme.Text,
                        Font=Enum.Font.Gotham, TextSize=12,
                        TextXAlignment=Enum.TextXAlignment.Left, BorderSizePixel=0,
                        LayoutOrder=i, AutoButtonColor=false, ZIndex=51, Parent=list,
                    })
                    Corner(6).Parent = optBtn
                    optBtn.MouseEnter:Connect(function()
                        if not UserInputService.TouchEnabled and not selected[opt] then
                            Tween(optBtn, 0.15, {BackgroundTransparency=0.15})
                        end
                    end)
                    optBtn.MouseLeave:Connect(function()
                        if not selected[opt] then
                            Tween(optBtn, 0.15, {BackgroundTransparency=0.4})
                        end
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        if multi then
                            selected[opt] = not selected[opt] or nil
                            optBtn.BackgroundColor3 = selected[opt] and Library.Theme.Accent or Library.Theme.Secondary
                            optBtn.BackgroundTransparency = selected[opt] and 0 or 0.4
                        else
                            for k in pairs(selected) do selected[k] = nil end
                            selected[opt] = true
                            for o, b in pairs(optionButtons) do
                                b.BackgroundColor3 = (o == opt) and Library.Theme.Accent or Library.Theme.Secondary
                                b.BackgroundTransparency = (o == opt) and 0 or 0.4
                            end
                            setExpanded(false)
                        end
                        updateDisplay()
                    end)
                    optionButtons[opt] = optBtn
                end
            end

            btn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)
            refreshOptions()
            if next(selected) then updateDisplay() end

            local entry = RegisterElement(holder, config.Text or "Dropdown", flag)

            return {
                Set = function(v)
                    for k in pairs(selected) do selected[k] = nil end
                    if type(v) == "table" then
                        for _, val in ipairs(v) do selected[val] = true end
                    else
                        selected[v] = true
                    end
                    for o, b in pairs(optionButtons) do
                        b.BackgroundColor3 = selected[o] and Library.Theme.Accent or Library.Theme.Secondary
                        b.BackgroundTransparency = selected[o] and 0 or 0.4
                    end
                    updateDisplay()
                end,
                Refresh = function(newOpts) refreshOptions(newOpts) end,
                Get = function()
                    local l = {}
                    for k, v in pairs(selected) do if v then table.insert(l, k) end end
                    return multi and l or l[1]
                end
            }
        end

        -- ===== TEXTBOX =====
        function tab:AddTextbox(config)
            config = config or {}
            local flag = config.Flag
            local callback = config.Callback or function() end

            local holder = Create("Frame", {
                Size=UDim2.new(1,0,0,36), BackgroundColor3=Library.Theme.Secondary,
                BorderSizePixel=0, Parent=page,
            })
            Corner(8).Parent = holder
            Stroke(Library.Theme.Border, 1, 0.3).Parent = holder
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = holder

            Create("TextLabel", {
                Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(0,14,0,0),
                BackgroundTransparency=1, Text=config.Text or "Input",
                TextColor3=Library.Theme.Text, Font=Enum.Font.Gotham, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=holder,
            })

            local box = Create("TextBox", {
                Size=UDim2.new(0.55,-14,0,26), Position=UDim2.new(0.45,0,0.5,-13),
                BackgroundColor3=Library.Theme.Tertiary, Text=config.Default or "",
                PlaceholderText=config.Placeholder or "Type here...",
                PlaceholderColor3=Library.Theme.SubText, TextColor3=Library.Theme.Text,
                Font=Enum.Font.Gotham, TextSize=12, BorderSizePixel=0,
                ClearTextOnFocus=false, Parent=holder,
            })
            Corner(6).Parent = box

            box.Focused:Connect(function()
                Tween(box, 0.15, {BackgroundColor3=Library.Theme.Accent})
            end)
            box.FocusLost:Connect(function()
                Tween(box, 0.15, {BackgroundColor3=Library.Theme.Tertiary})
                if flag then Library.Flags[flag] = box.Text end
                local ok, err = pcall(callback, box.Text)
                if not ok then warn("[SimpleUI] "..tostring(err)) end
            end)

            local entry = RegisterElement(holder, config.Text or "Textbox", flag)
            entry._applyLoaded = function(v) box.Text = v end

            return {
                Set = function(v) box.Text = v; if flag then Library.Flags[flag] = v end end,
                Get = function() return box.Text end
            }
        end

        -- ===== KEYBIND =====
        function tab:AddKeybind(config)
            config = config or {}
            local default = config.Default or Enum.KeyCode.E
            local flag = config.Flag
            local callback = config.Callback or function() end

            local holder = Create("Frame", {
                Size=UDim2.new(1,0,0,36), BackgroundColor3=Library.Theme.Secondary,
                BorderSizePixel=0, Parent=page,
            })
            Corner(8).Parent = holder
            Stroke(Library.Theme.Border, 1, 0.3).Parent = holder
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = holder

            Create("TextLabel", {
                Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,14,0,0),
                BackgroundTransparency=1, Text=config.Text or "Keybind",
                TextColor3=Library.Theme.Text, Font=Enum.Font.Gotham, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=holder,
            })

            local keyBtn = Create("TextButton", {
                Size=UDim2.new(0,90,0,26), Position=UDim2.new(1,-104,0.5,-13),
                BackgroundColor3=Library.Theme.Tertiary, Text=default.Name,
                TextColor3=Library.Theme.Text, Font=Enum.Font.GothamBold, TextSize=12,
                BorderSizePixel=0, AutoButtonColor=false, Parent=holder,
            })
            Corner(6).Parent = keyBtn

            local current = default
            local listening = false

            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyBtn.Text = "..."
                Tween(keyBtn, 0.2, {BackgroundColor3=Library.Theme.Accent})
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    current = input.KeyCode
                    keyBtn.Text = current.Name
                    listening = false
                    Tween(keyBtn, 0.2, {BackgroundColor3=Library.Theme.Tertiary})
                    if flag then Library.Flags[flag] = current end
                    local ok, err = pcall(callback, current)
                    if not ok then warn("[SimpleUI] "..tostring(err)) end
                end
            end)

            local entry = RegisterElement(holder, config.Text or "Keybind", flag)
            entry._applyLoaded = function(v)
                if typeof(v) == "EnumItem" then
                    current = v
                    keyBtn.Text = v.Name
                end
            end

            return {
                Get = function() return current end,
                Set = function(k) current = k; keyBtn.Text = k.Name end
            }
        end

        -- ===== COLOR PICKER =====
        function tab:AddColorPicker(config)
            config = config or {}
            local flag = config.Flag
            local callback = config.Callback or function() end

            local color = config.Default or Color3.fromRGB(255,255,255)
            local h, s, v = Color3.toHSV(color)

            local holder = Create("Frame", {
                Size=UDim2.new(1,0,0,36), BackgroundColor3=Library.Theme.Secondary,
                BorderSizePixel=0, Parent=page, ClipsDescendants=false, ZIndex=5,
            })
            Corner(8).Parent = holder
            Stroke(Library.Theme.Border, 1, 0.3).Parent = holder
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = holder

            Create("TextLabel", {
                Size=UDim2.new(1,-70,1,0), Position=UDim2.new(0,14,0,0),
                BackgroundTransparency=1, Text=config.Text or "Color",
                TextColor3=Library.Theme.Text, Font=Enum.Font.Gotham, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=holder,
            })

            local preview = Create("Frame", {
                Size=UDim2.new(0,32,0,22), Position=UDim2.new(1,-46,0.5,-11),
                BackgroundColor3=color, BorderSizePixel=0, ZIndex=6, Parent=holder,
            })
            Corner(6).Parent = preview
            Stroke(Color3.fromRGB(255,255,255), 1, 0.5).Parent = preview

            local popup = Create("Frame", {
                Size=UDim2.new(0,220,0,0), Position=UDim2.new(0,0,1,4),
                BackgroundColor3=Library.Theme.Tertiary, BorderSizePixel=0,
                Visible=false, ClipsDescendants=true, ZIndex=60, Parent=holder,
            })
            Corner(8).Parent = popup
            Stroke(Library.Theme.Border, 1, 0.2).Parent = popup

            local svBg = Create("Frame", {
                Size=UDim2.new(1,-20,0,130), Position=UDim2.new(0,10,0,10),
                BackgroundColor3=Color3.fromRGB(255,0,0), BorderSizePixel=0,
                ZIndex=61, Parent=popup,
            })
            Corner(6).Parent = svBg

            local whiteGrad = Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255,0)),
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            })
            whiteGrad.Parent = svBg
            whiteGrad.Rotation = 0

            local blackGrad = Create("Frame", {
                Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(0,0,0),
                BorderSizePixel=0, ZIndex=62, Parent=svBg,
            })
            Corner(6).Parent = blackGrad
            local bg2 = Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0,0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
                }),
                Rotation = 90,
            })
            bg2.Parent = blackGrad

            local svCursor = Create("Frame", {
                Size=UDim2.new(0,10,0,10), AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(s,0,1-v,0), BackgroundColor3=Color3.fromRGB(255,255,255),
                BorderSizePixel=0, ZIndex=64, Parent=svBg,
            })
            Corner(5).Parent = svCursor
            Stroke(Color3.fromRGB(0,0,0), 2).Parent = svCursor

            local hueBar = Create("Frame", {
                Size=UDim2.new(1,-20,0,16), Position=UDim2.new(0,10,0,148),
                BackgroundColor3=Color3.fromRGB(255,0,0), BorderSizePixel=0,
                ZIndex=61, Parent=popup,
            })
            Corner(8).Parent = hueBar
            local hueGrad = Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
                }),
                Rotation = 0,
            })
            hueGrad.Parent = hueBar

            local hueCursor = Create("Frame", {
                Size=UDim2.new(0,6,1.4,0), AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(h,0,0.5,0), BackgroundColor3=Color3.fromRGB(255,255,255),
                BorderSizePixel=0, ZIndex=64, Parent=hueBar,
            })
            Corner(3).Parent = hueCursor
            Stroke(Color3.fromRGB(0,0,0), 1.5).Parent = hueCursor

            local hexBox = Create("TextBox", {
                Size=UDim2.new(1,-20,0,26), Position=UDim2.new(0,10,0,172),
                BackgroundColor3=Library.Theme.Secondary, Text="", PlaceholderText="#FFFFFF",
                PlaceholderColor3=Library.Theme.SubText, TextColor3=Library.Theme.Text,
                Font=Enum.Font.Code, TextSize=12, BorderSizePixel=0,
                ClearTextOnFocus=false, ZIndex=62, Parent=popup,
            })
            Corner(6).Parent = hexBox

            local function updateColor(fire)
                color = Color3.fromHSV(h, s, v)
                preview.BackgroundColor3 = color
                svBg.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                hexBox.Text = string.format("#%02X%02X%02X",
                    math.floor(color.R*255+0.5),
                    math.floor(color.G*255+0.5),
                    math.floor(color.B*255+0.5))
                if flag then Library.Flags[flag] = color end
                if fire ~= false then
                    local ok, err = pcall(callback, color)
                    if not ok then warn("[SimpleUI] "..tostring(err)) end
                end
            end

            local svDragging = false
            svBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    svDragging = true
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if svDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    local relX = math.clamp((input.Position.X - svBg.AbsolutePosition.X) / svBg.AbsoluteSize.X, 0, 1)
                    local relY = math.clamp((input.Position.Y - svBg.AbsolutePosition.Y) / svBg.AbsoluteSize.Y, 0, 1)
                    s = relX
                    v = 1 - relY
                    svCursor.Position = UDim2.new(s, 0, 1-v, 0)
                    updateColor()
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    svDragging = false
                end
            end)

            local hueDragging = false
            hueBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    hueDragging = true
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    local relX = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                    h = relX
                    hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                    updateColor()
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    hueDragging = false
                end
            end)

            hexBox.FocusLost:Connect(function()
                local t = hexBox.Text:gsub("#","")
                if #t == 6 then
                    local r = tonumber(t:sub(1,2), 16)
                    local g = tonumber(t:sub(3,4), 16)
                    local b = tonumber(t:sub(5,6), 16)
                    if r and g and b then
                        color = Color3.fromRGB(r, g, b)
                        h, s, v = Color3.toHSV(color)
                        svCursor.Position = UDim2.new(s, 0, 1-v, 0)
                        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                        updateColor()
                    end
                end
            end)

            local expanded = false
            holder.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    expanded = not expanded
                    popup.Visible = expanded
                    Tween(popup, 0.3, {
                        Size = expanded and UDim2.new(0,220,0,206) or UDim2.new(0,220,0,0)
                    }, Enum.EasingStyle.Quart)
                end
            end)

            updateColor(false)

            local entry = RegisterElement(holder, config.Text or "Color", flag)
            entry._applyLoaded = function(v)
                if typeof(v) == "Color3" then
                    color = v
                    h, s, v = Color3.toHSV(color)
                    svCursor.Position = UDim2.new(s, 0, 1-v, 0)
                    hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                    updateColor(true)
                end
            end

            return {
                Set = function(c)
                    color = c
                    h, s, v = Color3.toHSV(c)
                    svCursor.Position = UDim2.new(s, 0, 1-v, 0)
                    hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                    updateColor()
                end,
                Get = function() return color end
            }
        end

        if not Window.ActiveTab then Window:SelectTab(tab) end
        table.insert(Window.Tabs, tab)
        return tab
    end

    -- ===== LIVE STATS PANEL =====
    function Window:EnableStats()
        if Window._statsFrame then return end
        local panel = Create("Frame", {
            Size=UDim2.new(0,150,0,80), Position=UDim2.new(1,-160,1,10),
            BackgroundColor3=Library.Theme.Secondary, BorderSizePixel=0,
            ZIndex=90, Parent=main,
        })
        Corner(10).Parent = panel
        Stroke(Library.Theme.Accent, 1.5, 0.3).Parent = panel

        Create("TextLabel", {
            Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,0,4),
            BackgroundTransparency=1, Text="LIVE STATS",
            TextColor3=Library.Theme.Accent, Font=Enum.Font.GothamBold,
            TextSize=10, Parent=panel,
        })

        local rows = {}
        local labels = {"FPS", "Ping", "Memory"}
        for i, name in ipairs(labels) do
            Create("TextLabel", {
                Size=UDim2.new(0.5,-6,0,16),
                Position=UDim2.new(0,8,0,24+((i-1)*16)),
                BackgroundTransparency=1, Text=name,
                TextColor3=Library.Theme.SubText, Font=Enum.Font.Gotham, TextSize=11,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=panel,
            })
            rows[name] = Create("TextLabel", {
                Size=UDim2.new(0.5,-6,0,16),
                Position=UDim2.new(0.5,0,0,24+((i-1)*16)),
                BackgroundTransparency=1, Text="--",
                TextColor3=Library.Theme.Text, Font=Enum.Font.GothamBold, TextSize=11,
                TextXAlignment=Enum.TextXAlignment.Right, Parent=panel,
            })
        end

        local frameCount, lastTime, fps = 0, tick(), 60
        RunService.RenderStepped:Connect(function()
            frameCount += 1
            local now = tick()
            if now - lastTime >= 1 then
                fps = frameCount
                frameCount = 0
                lastTime = now
            end
        end)

        task.spawn(function()
            while panel.Parent do
                if rows.FPS then rows.FPS.Text = tostring(math.floor(fps)) end
                local ok, ping = pcall(function()
                    return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                end)
                if rows.Ping then
                    rows.Ping.Text = ok and string.format("%.0f ms", ping) or "--"
                end
                local ok2, mem = pcall(function()
                    return Stats:GetTotalMemoryUsageMb()
                end)
                if rows.Memory then
                    rows.Memory.Text = ok2 and string.format("%.0f MB", mem) or "--"
                end
                task.wait(0.5)
            end
        end)

        Window._statsFrame = panel
        return panel
    end

    -- ===== OPEN ANIMATION =====
    main.Size = UDim2.new(0,0,0,0)
    main.BackgroundTransparency = 1
    shadow.Size = UDim2.new(0,0,0,0)
    task.wait(0.05)
    Tween(shadow, 0.5, {Size=defaultSize}, Enum.EasingStyle.Back)
    Tween(main, 0.5, {Size=defaultSize, BackgroundTransparency=0}, Enum.EasingStyle.Back)

    return Window
end

return Library
