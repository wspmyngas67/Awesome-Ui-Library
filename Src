local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ PARENT DETECTION ============
local function GetParent()
    if gethui then
        local ok, ui = pcall(gethui)
        if ok and ui then return ui end
    end
    if syn and syn.protect_gui then
        local ok, sg = pcall(function()
            local g = Instance.new("ScreenGui")
            syn.protect_gui(g)
            return g
        end)
        if ok then return sg end
    end
    if get_hidden_gui then
        local ok, h = pcall(get_hidden_gui)
        if ok and h then return h end
    end
    local ok, cg = pcall(function() return CoreGui end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local Library = {}
Library.__index = Library
Library.Flags = {}
Library.Opened = true
Library.ToggleKey = Enum.KeyCode.RightShift

-- ============ THEMES ============
local Themes = {
    Dark = {
        Background = Color3.fromRGB(20, 20, 25),
        Secondary = Color3.fromRGB(30, 30, 38),
        Tertiary = Color3.fromRGB(42, 42, 52),
        Accent = Color3.fromRGB(120, 100, 255),
        Accent2 = Color3.fromRGB(200, 90, 255),
        Text = Color3.fromRGB(245, 245, 250),
        SubText = Color3.fromRGB(150, 150, 165),
        Border = Color3.fromRGB(60, 60, 75),
        Glow = Color3.fromRGB(120, 100, 255),
    },
    Neon = {
        Background = Color3.fromRGB(10, 8, 20),
        Secondary = Color3.fromRGB(18, 15, 32),
        Tertiary = Color3.fromRGB(30, 25, 50),
        Accent = Color3.fromRGB(0, 255, 200),
        Accent2 = Color3.fromRGB(255, 0, 200),
        Text = Color3.fromRGB(240, 255, 250),
        SubText = Color3.fromRGB(120, 200, 180),
        Border = Color3.fromRGB(40, 80, 80),
        Glow = Color3.fromRGB(0, 255, 200),
    },
    Midnight = {
        Background = Color3.fromRGB(8, 12, 30),
        Secondary = Color3.fromRGB(15, 20, 45),
        Tertiary = Color3.fromRGB(25, 32, 65),
        Accent = Color3.fromRGB(80, 140, 255),
        Accent2 = Color3.fromRGB(140, 80, 255),
        Text = Color3.fromRGB(235, 240, 255),
        SubText = Color3.fromRGB(140, 155, 200),
        Border = Color3.fromRGB(45, 60, 110),
        Glow = Color3.fromRGB(80, 140, 255),
    },
    Blood = {
        Background = Color3.fromRGB(15, 8, 10),
        Secondary = Color3.fromRGB(28, 12, 15),
        Tertiary = Color3.fromRGB(45, 18, 22),
        Accent = Color3.fromRGB(255, 45, 60),
        Accent2 = Color3.fromRGB(255, 100, 40),
        Text = Color3.fromRGB(255, 240, 240),
        SubText = Color3.fromRGB(200, 140, 140),
        Border = Color3.fromRGB(90, 30, 35),
        Glow = Color3.fromRGB(255, 45, 60),
    },
    Ocean = {
        Background = Color3.fromRGB(8, 18, 28),
        Secondary = Color3.fromRGB(14, 28, 42),
        Tertiary = Color3.fromRGB(22, 42, 62),
        Accent = Color3.fromRGB(50, 200, 255),
        Accent2 = Color3.fromRGB(100, 120, 255),
        Text = Color3.fromRGB(230, 245, 255),
        SubText = Color3.fromRGB(130, 170, 200),
        Border = Color3.fromRGB(35, 75, 105),
        Glow = Color3.fromRGB(50, 200, 255),
    },
    Light = {
        Background = Color3.fromRGB(245, 245, 250),
        Secondary = Color3.fromRGB(230, 230, 240),
        Tertiary = Color3.fromRGB(215, 215, 230),
        Accent = Color3.fromRGB(120, 100, 255),
        Accent2 = Color3.fromRGB(200, 90, 255),
        Text = Color3.fromRGB(25, 25, 35),
        SubText = Color3.fromRGB(90, 90, 110),
        Border = Color3.fromRGB(200, 200, 215),
        Glow = Color3.fromRGB(120, 100, 255),
    },
}

Library.Theme = Themes.Dark

-- ============ HELPERS ============
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    return inst
end

local function Corner(r)
    return Create("UICorner", {CornerRadius = UDim.new(0, r or 8)})
end

local function Stroke(color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Library.Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    })
end

local function Gradient(c1, c2, rotation)
    return Create("UIGradient", {
        Color = ColorSequence.new(c1, c2),
        Rotation = rotation or 45,
    })
end

local function Tween(obj, t, props, style, dir)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
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
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ============ NOTIFICATIONS ============
function Library:Notify(config)
    config = config or {}
    local title = config.Title or "Notification"
    local text = config.Text or ""
    local duration = config.Duration or 4
    local parent = Library.Gui
    if not parent then return end

    local note = Create("Frame", {
        Size = UDim2.new(0, 280, 0, 60),
        Position = UDim2.new(1, 320, 0, 20 + (#(Library._notes or {}) * 70)),
        BackgroundColor3 = Library.Theme.Secondary,
        BorderSizePixel = 0,
        Parent = parent,
    })
    Corner(10).Parent = note
    Stroke(Library.Theme.Accent, 1.5, 0.3).Parent = note

    local accentBar = Create("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        Parent = note,
    })
    Corner(10).Parent = accentBar
    Gradient(Library.Theme.Accent, Library.Theme.Accent2, 90).Parent = accentBar

    Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 14, 0, 6),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Library.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = note,
    })

    Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 14, 0, 28),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Library.Theme.SubText,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = note,
    })

    Library._notes = Library._notes or {}
    table.insert(Library._notes, note)

    Tween(note, 0.35, {Position = UDim2.new(1, -300, 0, 20 + (#Library._notes - 1) * 70)}, Enum.EasingStyle.Back)

    task.delay(duration, function()
        Tween(note, 0.3, {Position = UDim2.new(1, 320, 0, note.Position.Y.Offset)})
        task.wait(0.35)
        for i, n in ipairs(Library._notes) do
            if n == note then table.remove(Library._notes, i) break end
        end
        note:Destroy()
    end)
end

-- ============ WINDOW ============
function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "SimpleUI"
    local subtitle = config.Subtitle or "v2.0 Cool Edition"
    local themeName = config.Theme or "Dark"
    Library.Theme = Themes[themeName] or Themes.Dark

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
    local defaultSize = isMobile and UDim2.new(0, 320, 0, 400) or UDim2.new(0, 560, 0, 380)

    -- ===== GLOW SHADOW =====
    local shadow = Create("Frame", {
        Size = defaultSize,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Library.Theme.Glow,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = gui,
    })
    Corner(16).Parent = shadow
    local shadowGrad = Gradient(Library.Theme.Glow, Library.Theme.Accent2, 45)
    shadowGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(1, 0.9),
    })
    shadowGrad.Parent = shadow

    -- ===== MAIN FRAME =====
    local main = Create("Frame", {
        Name = "Main",
        Size = defaultSize,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0,
        Parent = gui,
    })
    Corner(14).Parent = main
    Stroke(Library.Theme.Border, 1.5, 0.3).Parent = main
    Gradient(Library.Theme.Background, Library.Theme.Secondary, 135).Parent = main

    -- ===== TOP BAR =====
    local topBar = Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = Library.Theme.Secondary,
        BorderSizePixel = 0,
        Parent = main,
    })
    Corner(14).Parent = topBar
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = Library.Theme.Secondary,
        BorderSizePixel = 0,
        Parent = topBar,
    })

    -- Accent line under top bar
    local accentLine = Create("Frame", {
        Size = UDim2.new(1, -20, 0, 1.5),
        Position = UDim2.new(0, 10, 1, -1),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        Parent = topBar,
    })
    Gradient(Library.Theme.Accent, Library.Theme.Accent2, 0).Parent = accentLine

    -- Logo dot
    local logo = Create("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 14, 0.5, -5),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        Parent = topBar,
    })
    Corner(5).Parent = logo
    Gradient(Library.Theme.Accent, Library.Theme.Accent2, 45).Parent = logo

    -- Pulsing animation on logo
    task.spawn(function()
        while logo.Parent do
            Tween(logo, 1, {BackgroundTransparency = 0.4}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1)
            Tween(logo, 1, {BackgroundTransparency = 0}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1)
        end
    end)

    Create("TextLabel", {
        Size = UDim2.new(1, -140, 0, 20),
        Position = UDim2.new(0, 32, 0, 5),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Library.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })
    Create("TextLabel", {
        Size = UDim2.new(1, -140, 0, 14),
        Position = UDim2.new(0, 32, 0, 24),
        BackgroundTransparency = 1,
        Text = subtitle,
        TextColor3 = Library.Theme.SubText,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })

    -- Buttons
    local btnHolder = Create("Frame", {
        Size = UDim2.new(0, 70, 1, 0),
        Position = UDim2.new(1, -80, 0, 0),
        BackgroundTransparency = 1,
        Parent = topBar,
    })

    local minimizeBtn = Create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(0, 0, 0.5, -14),
        BackgroundColor3 = Library.Theme.Tertiary,
        Text = "—",
        TextColor3 = Library.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = btnHolder,
    })
    Corner(8).Parent = minimizeBtn

    local closeBtn = Create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(0, 34, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(220, 60, 80),
        Text = "✕",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = btnHolder,
    })
    Corner(8).Parent = closeBtn

    for _, btn in ipairs({minimizeBtn, closeBtn}) do
        btn.MouseEnter:Connect(function()
            if not UserInputService.TouchEnabled then
                Tween(btn, 0.15, {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(btn.Position.X.Scale, btn.Position.X.Offset - 1, 0.5, -15)})
            end
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.15, {Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(btn.Position.X.Scale, btn.Position.X.Offset + 1, 0.5, -14)})
        end)
    end

    MakeDraggable(main, topBar)
    -- Also drag shadow
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local conn
            conn = RunService.RenderStepped:Connect(function()
                shadow.Position = main.Position
            end)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if conn then conn:Disconnect() end
                    shadow.Position = main.Position
                end
            end)
        end
    end)

    -- ===== NAV BAR =====
    local navBar = Create("Frame", {
        Name = "NavBar",
        Size = UDim2.new(0, 130, 1, -60),
        Position = UDim2.new(0, 8, 0, 53),
        BackgroundTransparency = 1,
        Parent = main,
    })
    Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = navBar,
    })

    local pageHolder = Create("Frame", {
        Name = "PageHolder",
        Size = UDim2.new(1, -155, 1, -60),
        Position = UDim2.new(0, 147, 0, 53),
        BackgroundTransparency = 1,
        Parent = main,
    })

    -- ===== CONTROLS =====
    local minimized = false
    closeBtn.MouseButton1Click:Connect(function()
        pcall(function()
            Tween(main, 0.25, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
            Tween(shadow, 0.25, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
            task.wait(0.3)
            gui:Destroy()
        end)
    end)

    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        local targetSize = minimized and UDim2.new(0, 560, 0, 45) or defaultSize
        Tween(main, 0.3, {Size = targetSize}, Enum.EasingStyle.Back)
        Tween(shadow, 0.3, {Size = targetSize}, Enum.EasingStyle.Back)
        navBar.Visible = not minimized
        pageHolder.Visible = not minimized
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Library.ToggleKey then
            Library.Opened = not Library.Opened
            main.Visible = Library.Opened
            shadow.Visible = Library.Opened
        end
    end)

    -- ===== MOBILE FLOATING BUTTON =====
    local mobileToggle = Create("TextButton", {
        Size = UDim2.new(0, 55, 0, 55),
        Position = UDim2.new(0, 15, 0.5, -27),
        BackgroundColor3 = Library.Theme.Accent,
        Text = "✦",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        BorderSizePixel = 0,
        Visible = isMobile,
        AutoButtonColor = false,
        Parent = gui,
        ZIndex = 100,
    })
    Corner(28).Parent = mobileToggle
    Gradient(Library.Theme.Accent, Library.Theme.Accent2, 45).Parent = mobileToggle
    Stroke(Color3.fromRGB(255, 255, 255), 1.5, 0.5).Parent = mobileToggle

    -- Pulse
    task.spawn(function()
        while mobileToggle.Parent do
            Tween(mobileToggle, 1.2, {Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(mobileToggle.Position.X.Scale, mobileToggle.Position.X.Offset - 2.5, mobileToggle.Position.Y.Scale, mobileToggle.Position.Y.Offset - 2.5)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
            Tween(mobileToggle, 1.2, {Size = UDim2.new(0, 55, 0, 55), Position = UDim2.new(mobileToggle.Position.X.Scale, mobileToggle.Position.X.Offset + 2.5, mobileToggle.Position.Y.Scale, mobileToggle.Position.Y.Offset + 2.5)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
        end
    end)

    local toggleDragStart, toggleStartPos
    mobileToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            toggleDragStart = input.Position
            toggleStartPos = mobileToggle.Position
        end
    end)
    mobileToggle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and toggleDragStart then
            local d = input.Position - toggleDragStart
            if d.Magnitude > 10 then
                mobileToggle.Position = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + d.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + d.Y)
            end
        end
    end)
    mobileToggle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - toggleDragStart
            if d.Magnitude <= 10 then
                Library.Opened = not Library.Opened
                main.Visible = Library.Opened
                shadow.Visible = Library.Opened
            end
            toggleDragStart = nil
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
            if Window.ActiveTab.Indicator then
                Window.ActiveTab.Indicator.Visible = false
            end
            Window.ActiveTab.Page.Visible = false
        end
        Window.ActiveTab = tab
        tab.Button.BackgroundColor3 = Library.Theme.Secondary
        tab.Button.BackgroundTransparency = 0
        if tab.Indicator then tab.Indicator.Visible = true end
        tab.Page.Visible = true
    end

    function Window:SetToggleKey(key)
        Library.ToggleKey = key
    end

    function Window:CreateTab(name)
        local tab = {Name = name}

        local button = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Library.Theme.Background,
            BackgroundTransparency = 0.6,
            Text = "   " .. name,
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Parent = navBar,
        })
        Corner(8).Parent = button

        local indicator = Create("Frame", {
            Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
            Parent = button,
        })
        Corner(2).Parent = indicator
        Gradient(Library.Theme.Accent, Library.Theme.Accent2, 90).Parent = indicator

        button.MouseEnter:Connect(function()
            if not UserInputService.TouchEnabled and Window.ActiveTab ~= tab then
                Tween(button, 0.15, {BackgroundTransparency = 0.3})
            end
        end)
        button.MouseLeave:Connect(function()
            if Window.ActiveTab ~= tab then
                Tween(button, 0.15, {BackgroundTransparency = 0.6})
            end
        end)

        local page = Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            Parent = pageHolder,
        })
        local layout = Create("UIListLayout", {
            Padding = UDim.new(0, 7),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page,
        })
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 6),
            Parent = page,
        })

        button.MouseButton1Click:Connect(function() Window:SelectTab(tab) end)

        tab.Button = button
        tab.Page = page
        tab.Window = Window
        tab.Indicator = indicator

        -- ===== SECTION =====
        function tab:AddSection(text)
            local sectionHolder = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                Parent = page,
            })
            Create("Frame", {
                Size = UDim2.new(0, 3, 0, 14),
                Position = UDim2.new(0, 2, 0.5, -7),
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
                Parent = sectionHolder,
            })
            local dot = Create("Frame", {
                Size = UDim2.new(0, 3, 0, 14),
                Position = UDim2.new(0, 2, 0.5, -7),
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
                Parent = sectionHolder,
            })
            Corner(2).Parent = dot
            Gradient(Library.Theme.Accent, Library.Theme.Accent2, 90).Parent = dot

            Create("TextLabel", {
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = string.upper(text),
                TextColor3 = Library.Theme.SubText,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = sectionHolder,
            })
            return sectionHolder
        end

        -- ===== LABEL =====
        function tab:AddLabel(text)
            local label = Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Library.Theme.Secondary,
                BackgroundTransparency = 0.5,
                Text = "  " .. text,
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                Parent = page,
            })
            Corner(8).Parent = label
            return label
        end

        -- ===== BUTTON =====
        function tab:AddButton(config)
            config = config or {}
            local btn = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Library.Theme.Secondary,
                Text = "",
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Parent = page,
            })
            Corner(8).Parent = btn
            Stroke(Library.Theme.Border, 1, 0.3).Parent = btn
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = btn

            local label = Create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = config.Text or "Button",
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                Parent = btn,
                ZIndex = 2,
            })

            -- Ripple effect
            local function ripple(x, y)
                local r = Create("Frame", {
                    Size = UDim2.new(0, 0, 0, 0),
                    Position = UDim2.new(0, x - btn.AbsolutePosition.X, 0, y - btn.AbsolutePosition.Y),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Library.Theme.Text,
                    BackgroundTransparency = 0.7,
                    BorderSizePixel = 0,
                    ZIndex = 1,
                    Parent = btn,
                })
                Corner(100).Parent = r
                Tween(r, 0.6, {Size = UDim2.new(0, btn.AbsoluteSize.X * 2.5, 0, btn.AbsoluteSize.X * 2.5), BackgroundTransparency = 1})
                task.delay(0.6, function() r:Destroy() end)
            end

            btn.MouseEnter:Connect(function()
                if not UserInputService.TouchEnabled then
                    Tween(btn, 0.2, {BackgroundColor3 = Library.Theme.Accent})
                    Tween(btn, 0.2, {Size = UDim2.new(1, 4, 0, 38), Position = UDim2.new(0, -2, 0, -1)})
                end
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, 0.2, {BackgroundColor3 = Library.Theme.Secondary})
                Tween(btn, 0.2, {Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 0)})
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
                    if not ok then warn("[SimpleUI] Button error: " .. tostring(err)) end
                end
            end)
            return btn
        end

        -- ===== TOGGLE =====
        function tab:AddToggle(config)
            config = config or {}
            local flag = config.Flag
            local callback = config.Callback or function() end

            local holder = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Library.Theme.Secondary,
                Text = "",
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Parent = page,
            })
            Corner(8).Parent = holder
            Stroke(Library.Theme.Border, 1, 0.3).Parent = holder
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = holder

            Create("TextLabel", {
                Size = UDim2.new(1, -70, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text = config.Text or "Toggle",
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local state = config.Default or false
            local toggleBg = Create("Frame", {
                Size = UDim2.new(0, 40, 0, 22),
                Position = UDim2.new(1, -54, 0.5, -11),
                BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Tertiary,
                BorderSizePixel = 0,
                Parent = holder,
            })
            Corner(11).Parent = toggleBg
            local bgGrad = state and Gradient(Library.Theme.Accent, Library.Theme.Accent2, 0) or Gradient(Library.Theme.Tertiary, Library.Theme.Tertiary, 0)
            bgGrad.Parent = toggleBg

            local knob = Create("Frame", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = toggleBg,
            })
            Corner(9).Parent = knob

            local function setState(v, fire)
                state = v
                if bgGrad then bgGrad:Destroy() end
                bgGrad = state and Gradient(Library.Theme.Accent, Library.Theme.Accent2, 0) or Gradient(Library.Theme.Tertiary, Library.Theme.Tertiary, 0)
                bgGrad.Parent = toggleBg
                Tween(toggleBg, 0.2, {BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Tertiary})
                Tween(knob, 0.2, {Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}, Enum.EasingStyle.Back)
                if flag then Library.Flags[flag] = state end
                if fire ~= false then
                    local ok, err = pcall(callback, state)
                    if not ok then warn("[SimpleUI] Toggle error: " .. tostring(err)) end
                end
            end

            holder.MouseButton1Click:Connect(function() setState(not state) end)
            if flag then Library.Flags[flag] = state end

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
                Size = UDim2.new(1, 0, 0, 55),
                BackgroundColor3 = Library.Theme.Secondary,
                BorderSizePixel = 0,
                Parent = page,
            })
            Corner(8).Parent = holder
            Stroke(Library.Theme.Border, 1, 0.3).Parent = holder
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = holder

            Create("TextLabel", {
                Size = UDim2.new(0.7, 0, 0, 22),
                Position = UDim2.new(0, 14, 0, 6),
                BackgroundTransparency = 1,
                Text = config.Text or "Slider",
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local valueLabel = Create("TextLabel", {
                Size = UDim2.new(0.3, -14, 0, 22),
                Position = UDim2.new(0.7, 0, 0, 6),
                BackgroundTransparency = 1,
                Text = tostring(default) .. suffix,
                TextColor3 = Library.Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = holder,
            })

            local barBg = Create("Frame", {
                Size = UDim2.new(1, -28, 0, 8),
                Position = UDim2.new(0, 14, 1, -22),
                BackgroundColor3 = Library.Theme.Tertiary,
                BorderSizePixel = 0,
                Parent = holder,
            })
            Corner(4).Parent = barBg

            local barFill = Create("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
                Parent = barBg,
            })
            Corner(4).Parent = barFill
            Gradient(Library.Theme.Accent, Library.Theme.Accent2, 0).Parent = barFill

            local knob = Create("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = barBg,
            })
            Corner(8).Parent = knob
            Stroke(Library.Theme.Accent, 2).Parent = knob

            local value = default
            local dragging = false

            local function round(n)
                local m = 10 ^ decimals
                return math.floor(n * m + 0.5) / m
            end

            local function updateFromX(x)
                local rel = math.clamp((x - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                value = round(min + (max - min) * rel)
                barFill.Size = UDim2.new(rel, 0, 1, 0)
                knob.Position = UDim2.new(rel, 0, 0.5, 0)
                valueLabel.Text = tostring(value) .. suffix
                if flag then Library.Flags[flag] = value end
                local ok, err = pcall(callback, value)
                if not ok then warn("[SimpleUI] Slider error: " .. tostring(err)) end
            end

            local function set(v, fire)
                v = math.clamp(v, min, max)
                value = round(v)
                local rel = (value - min) / (max - min)
                barFill.Size = UDim2.new(rel, 0, 1, 0)
                knob.Position = UDim2.new(rel, 0, 0.5, 0)
                valueLabel.Text = tostring(value) .. suffix
                if flag then Library.Flags[flag] = value end
                if fire ~= false then
                    local ok, err = pcall(callback, value)
                    if not ok then warn("[SimpleUI] Slider error: " .. tostring(err)) end
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
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Library.Theme.Secondary,
                BorderSizePixel = 0,
                Parent = page,
                ClipsDescendants = false,
                ZIndex = 5,
            })
            Corner(8).Parent = holder
            Stroke(Library.Theme.Border, 1, 0.3).Parent = holder
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = holder

            local btn = Create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 6,
                Parent = holder,
            })

            Create("TextLabel", {
                Size = UDim2.new(0.5, 0, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text = config.Text or "Dropdown",
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6,
                Parent = btn,
            })

            local valueLabel = Create("TextLabel", {
                Size = UDim2.new(0.4, 0, 1, 0),
                Position = UDim2.new(1, -50, 0, 0),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Text = "None",
                TextColor3 = Library.Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 6,
                Parent = btn,
            })

            local arrow = Create("TextLabel", {
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -26, 0, 0),
                BackgroundTransparency = 1,
                Text = "▼",
                TextColor3 = Library.Theme.SubText,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                ZIndex = 6,
                Parent = btn,
            })

            local list = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 4),
                BackgroundColor3 = Library.Theme.Tertiary,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 50,
                Parent = holder,
            })
            Corner(8).Parent = list
            Stroke(Library.Theme.Border, 1, 0.2).Parent = list

            Create("UIListLayout", {
                Padding = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = list,
            })
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                Parent = list,
            })

            local optionButtons = {}
            local expanded = false

            local function updateDisplay()
                local l = {}
                for k, v in pairs(selected) do if v then table.insert(l, k) end end
                if #l == 0 then valueLabel.Text = "None"
                elseif #l == 1 then valueLabel.Text = l[1]
                else valueLabel.Text = l[1] .. " (+" .. (#l - 1) .. ")" end
                local ret = multi and l or l[1]
                if flag then Library.Flags[flag] = ret end
                local ok, err = pcall(callback, ret)
                if not ok then warn("[SimpleUI] Dropdown error: " .. tostring(err)) end
            end

            local function setExpanded(s)
                expanded = s
                list.Visible = s
                local h = #options * 28 + 10
                Tween(list, 0.25, {Size = s and UDim2.new(1, 0, 0, h) or UDim2.new(1, 0, 0, 0)}, Enum.EasingStyle.Quart)
                arrow.Text = s and "▲" or "▼"
            end

            local function refreshOptions(newOptions)
                options = newOptions or options
                for _, b in pairs(optionButtons) do b:Destroy() end
                optionButtons = {}
                for i, opt in ipairs(options) do
                    local optBtn = Create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 26),
                        BackgroundColor3 = selected[opt] and Library.Theme.Accent or Library.Theme.Secondary,
                        BackgroundTransparency = selected[opt] and 0 or 0.4,
                        Text = "   " .. tostring(opt),
                        TextColor3 = Library.Theme.Text,
                        Font = Enum.Font.Gotham,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BorderSizePixel = 0,
                        LayoutOrder = i,
                        AutoButtonColor = false,
                        ZIndex = 51,
                        Parent = list,
                    })
                    Corner(6).Parent = optBtn

                    optBtn.MouseEnter:Connect(function()
                        if not UserInputService.TouchEnabled and not selected[opt] then
                            Tween(optBtn, 0.15, {BackgroundTransparency = 0.15})
                        end
                    end)
                    optBtn.MouseLeave:Connect(function()
                        if not selected[opt] then
                            Tween(optBtn, 0.15, {BackgroundTransparency = 0.4})
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

            return {
                Set = function(v)
                    for k in pairs(selected) do selected[k] = nil end
                    if type(v) == "table" then for _, val in ipairs(v) do selected[val] = true end
                    else selected[v] = true end
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
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Library.Theme.Secondary,
                BorderSizePixel = 0,
                Parent = page,
            })
            Corner(8).Parent = holder
            Stroke(Library.Theme.Border, 1, 0.3).Parent = holder
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = holder

            Create("TextLabel", {
                Size = UDim2.new(0.4, 0, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text = config.Text or "Input",
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local box = Create("TextBox", {
                Size = UDim2.new(0.55, -14, 0, 26),
                Position = UDim2.new(0.45, 0, 0.5, -13),
                BackgroundColor3 = Library.Theme.Tertiary,
                Text = config.Default or "",
                PlaceholderText = config.Placeholder or "Type here...",
                PlaceholderColor3 = Library.Theme.SubText,
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                Parent = holder,
            })
            Corner(6).Parent = box

            box.Focused:Connect(function()
                Tween(box, 0.15, {BackgroundColor3 = Library.Theme.Accent})
            end)
            box.FocusLost:Connect(function()
                Tween(box, 0.15, {BackgroundColor3 = Library.Theme.Tertiary})
                if flag then Library.Flags[flag] = box.Text end
                local ok, err = pcall(callback, box.Text)
                if not ok then warn("[SimpleUI] Textbox error: " .. tostring(err)) end
            end)

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
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Library.Theme.Secondary,
                BorderSizePixel = 0,
                Parent = page,
            })
            Corner(8).Parent = holder
            Stroke(Library.Theme.Border, 1, 0.3).Parent = holder
            Gradient(Library.Theme.Secondary, Library.Theme.Tertiary, 45).Parent = holder

            Create("TextLabel", {
                Size = UDim2.new(0.5, 0, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text = config.Text or "Keybind",
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })

            local keyBtn = Create("TextButton", {
                Size = UDim2.new(0, 90, 0, 26),
                Position = UDim2.new(1, -104, 0.5, -13),
                BackgroundColor3 = Library.Theme.Tertiary,
                Text = default.Name,
                TextColor3 = Library.Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Parent = holder,
            })
            Corner(6).Parent = keyBtn

            local current = default
            local listening = false

            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyBtn.Text = "..."
                Tween(keyBtn, 0.2, {BackgroundColor3 = Library.Theme.Accent})
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    current = input.KeyCode
                    keyBtn.Text = current.Name
                    listening = false
                    Tween(keyBtn, 0.2, {BackgroundColor3 = Library.Theme.Tertiary})
                    if flag then Library.Flags[flag] = current end
                    local ok, err = pcall(callback, current)
                    if not ok then warn("[SimpleUI] Keybind error: " .. tostring(err)) end
                end
            end)

            return {
                Get = function() return current end,
                Set = function(k) current = k; keyBtn.Text = k.Name end
            }
        end

        if not Window.ActiveTab then Window:SelectTab(tab) end
        table.insert(Window.Tabs, tab)
        return tab
    end

    -- ===== OPEN ANIMATION =====
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1
    shadow.Size = UDim2.new(0, 0, 0, 0)
    task.wait(0.05)
    Tween(shadow, 0.5, {Size = defaultSize}, Enum.EasingStyle.Back)
    Tween(main, 0.5, {Size = defaultSize, BackgroundTransparency = 0}, Enum.EasingStyle.Back)

    return Window
end

return Library
