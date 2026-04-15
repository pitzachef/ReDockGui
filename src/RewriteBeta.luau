warn("version 1.5")
local ReGui = {
    Version = "1.5",
    Author = "Depso",
    License = "MIT",
    Repository = "https://github.com/pitzachef/ReDockGui",
    Debug = false,
    PrefabsId = 71968920594655,
    DefaultTitle = "ReDockGui",
    ContainerName = "ReDockGui",
    DoubleClickThreshold = 0.3,
    TooltipOffset = 15,
    IniToSave = {
        "Value"
    },
    ClassIgnored = {
        "Visible",
        "Text"
    },
    Container = nil,
    Prefabs = nil,
    FocusedWindow = nil,
    HasTouchScreen = false,
    Services = nil,
    Elements = {},
    _FlagCache = {},
    _ErrorCache = {},
    Windows = {},
    ActiveTooltips = {},
    IniSettings = {},
    AnimationConnections = {}
}
local IDE = loadstring(game:HttpGet("https://raw.githubusercontent.com/pitzachef/ReDockGui/main/lib/ide.lua"))()
local Wrappers = loadstring(game:HttpGet("https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/classes/Wrappers.lua"))()
local Animation = loadstring(game:HttpGet("https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/classes/Animations.lua"))()
local Signaling = loadstring(game:HttpGet("https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/classes/Signaling.lua"))()
ReGui.DemoWindow = loadstring(game:HttpGet("https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/Demo Window.lua"))()
ReGui.Services = Wrappers.Services
ReGui.Animation = Animation
ReGui.Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/configurations/Icons.lua"))()
ReGui.Accent = loadstring(game:HttpGet("https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/configurations/Accent.lua"))()
ReGui.ThemeConfigs = loadstring(game:HttpGet("https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/configurations/Themes.lua"))()
ReGui.ElementFlags = loadstring(game:HttpGet("https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/configurations/Flags.lua"))()
local Tags = loadstring(game:HttpGet("https://raw.githubusercontent.com/pitzachef/ReDockGui/main/src/configurations/Tagging.lua"))()
ReGui.ElementColors = Tags.Coloring
ReGui.Animations = Tags.Animations
ReGui.Styles = Tags.Styles
Wrappers:CallOnInitConnections(ReGui)
ReGui.DynamicImages = {
    [ReGui.Icons.Arrow] = "ImageFollowsText",
    [ReGui.Icons.Close] = "ImageFollowsText",
    [ReGui.Icons.Dot] = "ImageFollowsText"
}
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
local Services = ReGui.Services
local HttpService = Services.HttpService
local Players = Services.Players
local UserInputService = Services.UserInputService
local RunService = Services.RunService
local InsertService = Services.InsertService
local LocalPlayer = Wrappers:NewReference(Players.LocalPlayer)
ReGui.PlayerGui = Wrappers:NewReference(LocalPlayer.PlayerGui)
ReGui.Mouse = Wrappers:NewReference(LocalPlayer:GetMouse())
local EmptyFunction = function()
    -- empty block
end
GetAndRemove = function(Key, Dict)
    local Value = Dict[Key]
    if Value then
        Dict[Key] = nil
    end
    return Value
end
MoveTableItem = function(Table, Item, NewPosition)
    local Index = table.find(Table, Item)
    if not Index then
        return
    end
    local Value = table.remove(Table, Index)
    table.insert(Table, NewPosition, Value)
end
Merge = function(Base, New)
    for Key, Value in next, New do
        Base[Key] = Value
    end
end
Copy = function(Original, Insert)
    local Table = table.clone(Original)
    if Insert then
        Merge(Table, Insert)
    end
    return Table
end
local function GetMatchPercentage(Value, Query)
    Value = tostring(Value):lower()
    Query = Query:lower()
    local Letters = Value:split("")
    local LetterCount = #Query
    local MatchedCount = 0
    for Index, Letter in Letters do
        local Match = Query:sub(Index, Index)
        if Letter == Match then
            MatchedCount += 1
        end
    end
    local Percentage = (MatchedCount / LetterCount) * 100
    return math.round(Percentage)
end
local function SortByQuery(Table, Query)
    local IsArray = Table[1]
    local Sorted = {}
    for A, B in Table do
        local Value = IsArray and B or A
        local Percentage = GetMatchPercentage(Value, Query)
        local Position = 100 - Percentage
        table.insert(Sorted, Position, Value)
    end
    return Sorted
end
function ReGui:Warn(...)
    warn("[ReDockGui]::", ...)
end
function ReGui:Error(...)
    local Concated = ReGui:Concat({
        ...
    }, " ")
    local Message = `\n[ReDockGui]:: {Concated}`
    coroutine.wrap(error)(Message)
end
function ReGui:IsDoubleClick(TickRange)
    local ClickThreshold = self.DoubleClickThreshold
    return TickRange < ClickThreshold
end
function ReGui:StyleContainers()
    local Container = self.Container
    local Overlays = Container.Overlays
    local Windows = Container.Windows
    self:SetProperties(Windows, {
        OnTopOfCoreBlur = true
    })
    self:SetProperties(Overlays, {
        OnTopOfCoreBlur = true
    })
end
function ReGui:Init(Overwrites)
    Overwrites = Overwrites or {}
    if self.Initialised then
        return
    end
    Merge(self, Overwrites)
    Merge(self, {
        Initialised = true,
        HasGamepad = self:IsConsoleDevice(),
        HasTouchScreen = self:IsMobileDevice()
    })
    self:CheckConfig(self, {
        ContainerParent = function()
            return Wrappers:ResolveUIParent()
        end,
        Prefabs = function()
            return self:LoadPrefabs()
        end
    }, true)
    self:CheckConfig(self, {
        Container = function()
            return self:InsertPrefab("Container", {
                Parent = self.ContainerParent,
                Name = self.ContainerName
            })
        end
    }, true)
    local Container = self.Container
    local TooltipOffset = self.TooltipOffset
    local ActiveTooltips = self.ActiveTooltips
    local Overlays = Container.Overlays
    local LastClick = 0
    self:StyleContainers()
    self.TooltipsContainer = self.Elements:Overlay({
        Parent = Overlays
    })
    UserInputService.InputBegan:Connect(function(Input)
        if not self:IsMouseEvent(Input, true) then
            return
        end
        local ClickTick = tick()
        local ClickRange = ClickTick - LastClick
        local IsDoubleClick = self:IsDoubleClick(ClickRange)
        LastClick = IsDoubleClick and 0 or ClickTick
        self:UpdateWindowFocuses()
    end)
    local function InputUpdate()
        local Tooltips = self.TooltipsContainer
        local Visible = #ActiveTooltips > 0
        Tooltips.Visible = Visible
        if not Visible then
            return
        end
        local X, Y = ReGui:GetMouseLocation()
        local Position = Overlays.AbsolutePosition
        Tooltips.Position = UDim2.fromOffset(X - Position.X + TooltipOffset, Y - Position.Y + TooltipOffset)
    end
    RunService.RenderStepped:Connect(InputUpdate)
end
function ReGui:CheckImportState()
    if self.Initialised then
        return
    end
    local PrefabsId = self.PrefabsId
    local PrefabsAssetUrl = Wrappers:CheckAssetUrl(PrefabsId)
    local Success, Prefabs = pcall(function()
        return Wrappers:NewReference(InsertService:LoadLocalAsset(PrefabsAssetUrl))
    end)
    self:Init({
        Prefabs = Success and Prefabs or nil
    })
end
function ReGui:GetVersion()
    return self.Version
end
function ReGui:IsMobileDevice()
    return UserInputService.TouchEnabled
end
function ReGui:IsConsoleDevice()
    return UserInputService.GamepadEnabled
end
function ReGui:GetScreenSize()
    return workspace.CurrentCamera.ViewportSize
end
function ReGui:LoadPrefabs()
    local PlayerGui = self.PlayerGui
    local Name = "ReGui-Prefabs"
    local ScriptUi = script:WaitForChild(Name, 2)
    if ScriptUi then
        return ScriptUi
    end
    local PlayerUI = PlayerGui:WaitForChild(Name, 2)
    if PlayerUI then
        return PlayerUI
    end
    return nil
end
function ReGui:CheckConfig(Source, Base, Call, IgnoreKeys)
    return Wrappers:CheckConfig(Source, Base, Call, IgnoreKeys)
end
function ReGui:CreateInstance(Class, Parent, Properties)
    local Object = Instance.new(Class, Parent)
    if Properties then
        local UseProps = Properties.UsePropertiesList
        if not UseProps then
            self:SetProperties(Object, Properties)
        else
            self:ApplyFlags({
                Object = Object,
                Class = Properties
            })
        end
    end
    return Object
end
function ReGui:ConnectMouseEvent(Object, Config)
    local Callback = Config.Callback
    local DoubleClick = Config.DoubleClick
    local OnlyMouseHovering = Config.OnlyMouseHovering
    local LastClick = 0
    local HoverSignal = nil
    if OnlyMouseHovering then
        HoverSignal = self:DetectHover(OnlyMouseHovering)
    end
    Object.Activated:Connect(function(...)
        local ClickTick = tick()
        local ClickRange = ClickTick - LastClick
        if HoverSignal and not HoverSignal.Hovering then
            return
        end
        if DoubleClick then
            if not ReGui:IsDoubleClick(ClickRange) then
                LastClick = ClickTick
                return
            end
            LastClick = 0
        end
        Callback(...)
    end)
end
function ReGui:GetAnimation(Animate)
    return Animate and self.Animation or TweenInfo.new(0)
end
function ReGui:DynamicImageTag(Object, Image, WindowClass)
    local Tags = self.DynamicImages
    local Tag = Tags[Image]
    if not Tag then
        return
    end
    if not WindowClass then
        return
    end
    WindowClass:TagElements({
        [Object] = Tag
    })
end
function ReGui:GetDictSize(Dict)
    local Count = 0
    for Key, Value in Dict do
        Count += 1
    end
    return Count
end
function ReGui:RemoveAnimations(Object)
    local Data = self:GetAnimationData(Object)
    local Connections = Data.Connections
    for _, Connection in next, Connections do
        Connection:Disconnect()
    end
end
function ReGui:GetAnimationData(Object)
    local Connections = self.AnimationConnections
    local Existing = Connections[Object]
    if Existing then
        return Existing
    end
    local Data = {
        Connections = {}
    }
    Connections[Object] = Data
    return Data
end
function ReGui:AddAnimationSignal(Object, Connection)
    local Data = self:GetAnimationData(Object)
    local Connections = Data.Connections
    table.insert(Connections, Connection)
end
function ReGui:SetAnimationsEnabled(Enabled)
    self.NoAnimations = not Enabled
end
function ReGui:SetAnimation(Object, Reference, Listener)
    Listener = Listener or Object
    local Animations = self.Animations
    local IsMobile = self.HasTouchScreen
    local Data = Reference
    if typeof(Reference) ~= "table" then
        Data = Animations[Reference]
    end
    assert(Data, `No animation data for Class {Reference}!`)
    self:RemoveAnimations(Listener)
    local Init = Data.Init
    local Connections = Data.Connections
    local Tweeninfo = Data.Tweeninfo
    local NoAnimation = Data.NoAnimation
    local StateData = self:GetAnimationData(Object)
    local State = StateData.State
    local InitFunc = nil
    local AnimationEnabled = true
    local CurrentSignal = nil
    local Signals = {}
    local Module = {}
    function Module:Reset(NoAnimation)
        if not InitFunc then
            return
        end
        InitFunc(NoAnimation)
    end
    function Module:FireSignal(SignalName, NoAnimation)
        Signals[SignalName](NoAnimation)
    end
    function Module:Refresh(NoAnimation)
        if not CurrentSignal then
            return
        end
        Signals[CurrentSignal](NoAnimation)
    end
    function Module:SetEnabled(Enabled)
        AnimationEnabled = Enabled
    end
    for SignalName, Properties in next, Connections do
        local function OnSignal(NoAnim)
            NoAnim = NoAnim == true
            CurrentSignal = SignalName
            local NoAnimations = self.NoAnimations
            if NoAnimations then
                return
            end
            if not AnimationEnabled then
                return
            end
            StateData.State = SignalName
            Animation:Tween({
                NoAnimation = NoAnim or NoAnimation,
                Object = Object,
                Tweeninfo = Tweeninfo,
                EndProperties = Properties
            })
        end
        local Signal = Listener[SignalName]
        if not IsMobile then
            local Connection = Signal:Connect(OnSignal)
            self:AddAnimationSignal(Listener, Connection)
        end
        Signals[SignalName] = OnSignal
        if SignalName == Init then
            InitFunc = OnSignal
        end
    end
    if State then
        Module:FireSignal(State)
    else
        Module:Reset(true)
    end
    return Module
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
function ReGui:ConnectDrag(Frame, Data)
    self:CheckConfig(Data, {
        DragStart = EmptyFunction,
        DragEnd = EmptyFunction,
        DragMovement = EmptyFunction,
        OnDragStateChange = EmptyFunction
    })
    local DragStart = Data.DragStart
    local DragEnd = Data.DragEnd
    local DragMovement = Data.DragMovement
    local OnDragStateChange = Data.OnDragStateChange
    local UserInputTypes = {
        StartAndEnd = {
            Enum.UserInputType.MouseButton1,
            Enum.UserInputType.Touch
        },
        Movement = {
            Enum.UserInputType.MouseMovement,
            Enum.UserInputType.Touch
        }
    }
    local IsDragging = false
    local function InputTypeAllowed(Key, Type)
        local InputType = Key.UserInputType
        return table.find(UserInputTypes[Type], InputType)
    end
    local function KeyToVector(Key)
        local InputPosition = Key.Position
        return Vector2.new(InputPosition.X, InputPosition.Y)
    end
    local function SetIsDragging(DraggingState)
        self._DraggingDisabled = DraggingState
        IsDragging = DraggingState
        OnDragStateChange(DraggingState)
    end
    local function MakeSignal(Data)
        local IsDraggingState = Data.IsDragging
        local InputType = Data.InputType
        local Callback = Data.Callback
        return function(Key)
            if Data.DraggingRequired ~= IsDragging then
                return
            end
            if Data.CheckDraggingDisabled and self._DraggingDisabled then
                return
            end
            if not InputTypeAllowed(Key, InputType) then
                return
            end
            if Data.UpdateState then
                SetIsDragging(IsDraggingState)
            end
            local InputVector = KeyToVector(Key)
            Callback(InputVector)
        end
    end
    Frame.InputBegan:Connect(MakeSignal({
        CheckDraggingDisabled = true,
        DraggingRequired = false,
        UpdateState = true,
        IsDragging = true,
        InputType = "StartAndEnd",
        Callback = DragStart
    }))
    UserInputService.InputEnded:Connect(MakeSignal({
        DraggingRequired = true,
        UpdateState = true,
        IsDragging = false,
        InputType = "StartAndEnd",
        Callback = DragEnd
    }))
    UserInputService.InputChanged:Connect(MakeSignal({
        DraggingRequired = true,
        InputType = "Movement",
        Callback = DragMovement
    }))
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
function ReGui:MakeDraggable(Config)
    local Move = Config.Move
    local Grab = Config.Grab
    local OnDragStateChange = Config.OnDragStateChange
    local PositionOrgin = nil
    local InputOrgin = nil
    local Interface = {}
    function Interface:SetEnabled(State)
        local StateChanged = Config.StateChanged
        self.Enabled = State
        if StateChanged then
            StateChanged(self)
        end
    end
    function Interface:CanDrag(Key)
        return self.Enabled
    end
    local function DragStart(InputVector)
        if not Interface:CanDrag() then
            return
        end
        local DragBegin = Config.DragBegin
        InputOrgin = InputVector
        DragBegin(InputOrgin)
    end
    local function DragMovement(InputVector)
        if not Interface:CanDrag() then
            return
        end
        local Delta = InputVector - InputOrgin
        local OnUpdate = Config.OnUpdate
        OnUpdate(Delta)
    end
    local function PositionBegan(Key)
        PositionOrgin = Move.Position
    end
    local function UpdatePosition(Delta)
        local Position = UDim2.new(PositionOrgin.X.Scale, PositionOrgin.X.Offset + Delta.X, PositionOrgin.Y.Scale, PositionOrgin.Y.Offset + Delta.Y)
        Config:SetPosition(Position)
    end
    local function SetPosition(self, Position)
        Animation:Tween({
            Object = Move,
            EndProperties = {
                Position = Position
            }
        })
    end
    self:CheckConfig(Config, {
        Enabled = true,
        OnUpdate = UpdatePosition,
        SetPosition = SetPosition,
        DragBegin = PositionBegan
    })
    self:ConnectDrag(Grab, {
        DragStart = DragStart,
        DragMovement = DragMovement,
        OnDragStateChange = OnDragStateChange
    })
    local Enabled = Config.Enabled
    Interface:SetEnabled(Enabled)
    return Interface
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
function ReGui:MakeResizable(Config)
    ReGui:CheckConfig(Config, {
        MinimumSize = Vector2.new(160, 90),
        MaximumSize = Vector2.new(math.huge, math.huge)
    })
    local MaximumSize = Config.MaximumSize
    local MinimumSize = Config.MinimumSize
    local Resize = Config.Resize
    local OnUpdate = Config.OnUpdate
    local SizeOrgin = nil
    local Grab = ReGui:InsertPrefab("ResizeGrab", {
        Parent = Resize
    })
    local function StateChanged(Interface)
        Grab.Visible = Interface.Enabled
    end
    local function UpdateSize(Delta)
        local NewSize = SizeOrgin + Delta
        local Size = UDim2.fromOffset(math.clamp(NewSize.X, MinimumSize.X, MaximumSize.X), math.clamp(NewSize.Y, MinimumSize.Y, MaximumSize.Y))
        if OnUpdate then
            OnUpdate(Size)
            return
        end
        Animation:Tween({
            Object = Resize,
            EndProperties = {
                Size = Size
            }
        })
    end
    local function ResizeBegin(InputPosition)
        SizeOrgin = Resize.AbsoluteSize
    end
    local DragDetection = self:MakeDraggable({
        Grab = Grab,
        OnUpdate = UpdateSize,
        DragBegin = ResizeBegin,
        StateChanged = StateChanged
    })
    DragDetection.Grab = Grab
    return DragDetection
end
function ReGui:IsMouseEvent(Input, IgnoreMovement)
    local Name = Input.UserInputType.Name
    if IgnoreMovement and Name:find("Movement") then
        return
    end
    return Name:find("Touch") or Name:find("Mouse")
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
function ReGui:DetectHover(Object, Configuration)
    local Config = Configuration or {}
    Config.Hovering = false
    local OnInput = Config.OnInput
    local OnHoverChange = Config.OnHoverChange
    local Anykey = Config.Anykey
    local MouseMove = Config.MouseMove
    local MouseEnter = Config.MouseEnter
    local MouseOnly = Config.MouseOnly
    local function Update(Input, IsHovering, IsMouseEvent)
        if Input and MouseOnly then
            if not ReGui:IsMouseEvent(Input, true) then
                return
            end
        end
        if IsHovering ~= nil then
            local Previous = Config.Hovering
            Config.Hovering = IsHovering
            if IsHovering ~= Previous and OnHoverChange then
                OnHoverChange(IsHovering)
            end
        end
        if not MouseEnter and IsMouseEvent then
            return
        end
        if OnInput then
            local Value = Config.Hovering
            OnInput(Value, Input)
            return
        end
    end
    local Connections = {
        Object.MouseEnter:Connect(function()
            Update(nil, true, true)
        end),
        Object.MouseLeave:Connect(function()
            Update(nil, false, true)
        end)
    }
    if Anykey or MouseOnly then
        table.insert(Connections, UserInputService.InputBegan:Connect(function(Input)
            Update(Input)
        end))
    end
    if MouseMove then
        local Connection = Object.MouseMoved:Connect(function()
            Update()
        end)
        table.insert(Connections, Connection)
    end
    function Config:Disconnect()
        for _, Connection in next, Connections do
            Connection:Disconnect()
        end
    end
    return Config
end
function ReGui:StackWindows()
    local Windows = self.Windows
    local Offset = 20
    for Index, Class in next, Windows do
        local Window = Class.WindowFrame
        local Position = UDim2.fromOffset(Offset * Index, Offset * Index)
        Class:Center()
        Window.Position += Position
    end
end
function ReGui:GetElementFlags(Object)
    local Cache = self._FlagCache
    return Cache[Object]
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
function ReGui:UpdateColors(Config)
    local Object = Config.Object
    local Tag = Config.Tag
    local NoAnimation = Config.NoAnimation
    local Elements = Config.TagsList
    local Theme = Config.Theme
    local Tweeninfo = Config.Tweeninfo
    local ElementColors = self.ElementColors
    local Flags = self:GetElementFlags(Object)
    local Debug = self.Debug
    local Coloring = ElementColors[Tag]
    if typeof(Coloring) == "string" then
        Coloring = ElementColors[Coloring]
    end
    if typeof(Tag) == "table" then
        Coloring = Tag
    elseif Elements then
        Elements[Object] = Tag
    end
    if not Coloring then
        return
    end
    local Properties = {}
    for Key, Name in next, Coloring do
        local Color = self:GetThemeKey(Theme, Name)
        if Flags and Flags[Key] then
            continue
        end
        if not Color then
            if Debug then
                self:Warn(`Color: '{Name}' does not exist!`)
            end
            continue
        end
        Properties[Key] = Color
    end
    Animation:Tween({
        Tweeninfo = Tweeninfo,
        Object = Object,
        NoAnimation = NoAnimation,
        EndProperties = Properties
    })
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
function ReGui:MultiUpdateColors(Config)
    local Objects = Config.Objects
    for Object, Tag in next, Objects do
        self:UpdateColors({
            TagsList = Config.TagsList,
            Theme = Config.Theme,
            NoAnimation = not Config.Animate,
            Tweeninfo = Config.Tweeninfo,
            Object = Object,
            Tag = Tag
        })
    end
end
function ReGui:ApplyStyle(Object, StyleName)
    local Styles = self.Styles
    local Style = Styles[StyleName]
    if not Style then
        return
    end
    self:ApplyFlags({
        Object = Object,
        Class = Style
    })
end
function ReGui:ClassIgnores(Key)
    local Ignores = self.ClassIgnored
    local Index = table.find(Ignores, Key)
    return Index and true or false
end
function ReGui:MergeMetatables(Class, Object)
    local Debug = self.Debug
    local Metadata = {}
    Metadata.__index = function(_, Key)
        local Ignored = self:ClassIgnores(Key)
        local Value = Class[Key]
        if Value ~= nil and not Ignored then
            return Value
        end
        local Success, ObjectValue = pcall(function()
            local Value = Object[Key]
            return self:PatchSelf(Object, Value)
        end)
        return Success and ObjectValue or nil
    end
    Metadata.__newindex = function(_, Key, Value)
        local Ignored = self:ClassIgnores(Key)
        local IsFunc = typeof(Value) == "function"
        local IsClass = Class[Key] ~= nil or IsFunc
        if IsClass and not Ignored then
            Class[Key] = Value
            return
        end
        xpcall(function()
            Object[Key] = Value
        end, function(err)
            if Debug then
                self:Warn(`Newindex Error: {Object}.{Key} = {Value}\n{err}`)
            end
            Class[Key] = Value
        end)
    end
    return setmetatable({}, Metadata)
end
function ReGui:Concat(Table, Separator)
    local Concatenated = ""
    for Index, String in next, Table do
        Concatenated ..= tostring(String) .. (Index ~= #Table and Separator or "")
    end
    return Concatenated
end
function ReGui:GetValueFromAliases(Aliases, Table)
    for _, Alias in Aliases do
        local Value = Table[Alias]
        if Value ~= nil then
            return Value
        end
    end
    return nil
end
function ReGui:RecursiveCall(Object, Func)
    for _, Child in next, Object:GetDescendants() do
        Func(Child)
    end
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
function ReGui:ApplyFlags(Config)
    local Properties = self.ElementFlags
    local Object = Config.Object
    local Class = Config.Class
    local WindowClass = Config.WindowClass
    function Config:GetThemeKey(Tag)
        if WindowClass then
            return WindowClass:GetThemeKey(Tag)
        else
            return ReGui:GetThemeKey(nil, Tag)
        end
    end
    self:SetProperties(Object, Class)
    for _, Flag in next, Properties do
        local Aliases = Flag.Properties
        local Callback = Flag.Callback
        local Recursive = Flag.Recursive
        local WindowFlags = Flag.WindowProperties
        local Value = self:GetValueFromAliases(Aliases, Class)
        if WindowClass and WindowFlags and Value == nil then
            Value = self:GetValueFromAliases(WindowFlags, WindowClass)
        end
        if Value == nil then
            continue
        end
        Callback(Config, Object, Value)
        if Recursive then
            self:RecursiveCall(Object, function(Child)
                Callback(Config, Child, Value)
            end)
        end
    end
end
function ReGui:SetProperties(Object, Properties)
    return Wrappers:SetProperties(Object, Properties)
end
function ReGui:InsertPrefab(Name, Properties)
    local Folder = self.Prefabs
    local Prefabs = Folder.Prefabs
    local Object = Wrappers:NewReference(Prefabs:WaitForChild(Name):Clone())
    if Properties then
        local UseProps = Properties.UsePropertiesList
        if not UseProps then
            self:SetProperties(Object, Properties)
        else
            self:ApplyFlags({
                Object = Object,
                Class = Properties
            })
        end
    end
    return Object
end
function ReGui:GetContentSize(Object, IngoreUIList)
    local UIListLayout = Object:FindFirstChildOfClass("UIListLayout")
    local UIPadding = Object:FindFirstChildOfClass("UIPadding")
    local UIStroke = Object:FindFirstChildOfClass("UIStroke")
    local ContentSize
    if UIListLayout and not IngoreUIList then
        ContentSize = UIListLayout.AbsoluteContentSize
    else
        ContentSize = Object.AbsoluteSize
    end
    if UIPadding then
        local Top = UIPadding.PaddingTop.Offset
        local Bottom = UIPadding.PaddingBottom.Offset
        local Left = UIPadding.PaddingLeft.Offset
        local Right = UIPadding.PaddingRight.Offset
        ContentSize += Vector2.new(Left + Right, Top + Bottom)
    end
    if UIStroke then
        local Thickness = UIStroke.Thickness
        ContentSize += Vector2.new(Thickness / 2, Thickness / 2)
    end
    return ContentSize
end
function ReGui:PatchSelf(Self, Func, ...)
    if typeof(Func) ~= "function" then
        return Func, ...
    end
    return function(_, ...)
        return Func(Self, ...)
    end
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
function ReGui:MakeCanvas(Config)
    local ElementsClass = self.Elements
    local Debug = self.Debug
    local Element = Config.Element
    local WindowClass = Config.WindowClass
    local Class = Config.Class
    local OnChildChange = Config.OnChildChange
    local ChildChangeSignal = Signaling:NewSignal()
    if OnChildChange then
        ChildChangeSignal:Connect(OnChildChange)
    end
    if not WindowClass and Debug then
        self:Warn(`No WindowClass for {Element}`)
        self:Warn(Config)
    end
    local Canvas = Wrappers:NewClass(ElementsClass, {
        Class = Class,
        RawObject = Element,
        WindowClass = WindowClass or false,
        OnChildChange = ChildChangeSignal,
        Elements = {}
    })
    local Meta = {
        __index = function(_, Key)
            local CanvasValue = Canvas[Key]
            if CanvasValue ~= nil then
                return self:PatchSelf(Canvas, CanvasValue)
            end
            local ClassValue = Class[Key]
            if ClassValue ~= nil then
                return self:PatchSelf(Class, ClassValue)
            end
            local ElementValue = Element[Key]
            return self:PatchSelf(Element, ElementValue)
        end,
        __newindex = function(self, Key, Value)
            local IsClassValue = Class[Key] ~= nil
            if IsClassValue then
                Class[Key] = Value
            else
                Element[Key] = Value
            end
        end
    }
    return setmetatable({}, Meta)
end
function ReGui:GetIniData(Class)
    local IniToSave = self.IniToSave
    local Ini = {}
    for _, Name in next, IniToSave do
        Ini[Name] = Class[Name]
    end
    return Ini
end
function ReGui:DumpIni(JsonEncode)
    local IniSettings = self.IniSettings
    local Parsed = {}
    for Flag, Element in next, IniSettings do
        Parsed[Flag] = self:GetIniData(Element)
    end
    if JsonEncode then
        return HttpService:JSONEncode(Parsed)
    end
    return Parsed
end
function ReGui:LoadIniIntoElement(Element, Values)
    local ValueFunctions = {
        ["Value"] = function(Value)
            Element:SetValue(Value)
        end
    }
    for Name, Value in next, Values do
        local SetValue = ValueFunctions[Name]
        if SetValue then
            SetValue(Value)
            continue
        end
        Element[Name] = Value
    end
end
function ReGui:LoadIni(NewSettings, JsonEncoded)
    local IniSettings = self.IniSettings
    assert(NewSettings, "No Ini configuration was passed")
    if JsonEncoded then
        NewSettings = HttpService:JSONDecode(NewSettings)
    end
    for Flag, Values in next, NewSettings do
        local Element = IniSettings[Flag]
        self:LoadIniIntoElement(Element, Values)
    end
end
function ReGui:AddIniFlag(Flag, Element)
    local IniSettings = self.IniSettings
    IniSettings[Flag] = Element
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
function ReGui:OnElementCreate(Data)
    local FlagCache = self._FlagCache
    local Flags = Data.Flags
    local Object = Data.Object
    local Canvas = Data.Canvas
    local Class = Data.Class
    local WindowClass = Canvas.WindowClass
    local NoAutoTag = Flags.NoAutoTag
    local NoAutoFlags = Flags.NoAutoFlags
    local ColorTag = Flags.ColorTag
    local NoStyle = Flags.NoStyle
    local IniFlag = Flags.IniFlag
    FlagCache[Object] = Flags
    if IniFlag then
        self:AddIniFlag(IniFlag, Class)
    end
    if NoStyle then
        return
    end
    if not NoAutoTag and WindowClass then
        WindowClass:TagElements({
            [Object] = ColorTag
        })
    end
    if WindowClass then
        WindowClass:LoadStylesIntoElement(Data)
    end
    if not NoAutoFlags then
        self:ApplyFlags({
            Object = Object,
            Class = Flags,
            WindowClass = WindowClass
        })
    end
end
function ReGui:VisualError(Canvas, Parent, Message)
    local Visual = self.Initialised and Canvas.Error
    if not Visual then
        self:Error("Class:", Message)
        return
    end
    Canvas:Error({
        Parent = Parent,
        Text = Message
    })
end
function ReGui:WrapGeneration(Function, Data)
    local ErrorCache = self._ErrorCache
    local Base = Data.Base
    local IgnoreDefaults = Data.IgnoreDefaults
    return function(Canvas, Flags, ...)
        Flags = Flags or {}
        self:CheckConfig(Flags, Base)
        local CloneTable = Flags.CloneTable
        if CloneTable then
            Flags = table.clone(Flags)
        end
        local Parent = Canvas.RawObject
        local Elements = Canvas.Elements
        local OnChildChange = Canvas.OnChildChange
        self:CheckConfig(Flags, {
            Parent = Parent,
            Name = Flags.ColorTag
        }, nil, IgnoreDefaults)
        if Canvas == self then
            Canvas = self.Elements
        end
        local Success, Class, Element = pcall(Function, Canvas, Flags, ...)
        if Success == false then
            if Parent then
                if ErrorCache[Parent] then
                    return
                end
                ErrorCache[Parent] = Class
            end
            self:VisualError(Canvas, Parent, Class)
            self:Error("Class:", Class)
            self:Error(debug.traceback())
        end
        if Element == nil then
            Element = Class
        end
        if OnChildChange then
            OnChildChange:Fire(Class)
        end
        if Element then
            if Elements then
                table.insert(Elements, Element)
            end
            self:OnElementCreate({
                Object = Element,
                Flags = Flags,
                Class = Class,
                Canvas = Canvas
            })
        end
        return Class, Element
    end
end
function ReGui:DefineElement(Name, Data)
    local Elements = self.Elements
    local Themes = self.ThemeConfigs
    local ElementColors = self.ElementColors
    local BaseTheme = Themes.DarkTheme
    local Base = Data.Base
    local Create = Data.Create
    local Export = Data.Export
    local ThemeTags = Data.ThemeTags
    local ColorData = Data.ColorData
    self:CheckConfig(Base, {
        ColorTag = Name,
        ElementStyle = Name
    })
    if ThemeTags then
        Merge(BaseTheme, ThemeTags)
    end
    if ColorData then
        Merge(ElementColors, ColorData)
    end
    local Generate = self:WrapGeneration(Create, Data)
    if Export then
        self[Name] = Generate
    end
    Elements[Name] = Generate
    return Generate
end
function ReGui:DefineGlobalFlag(Flag)
    local Flags = self.ElementFlags
    table.insert(Flags, Flag)
end
function ReGui:DefineTheme(Name, ThemeData)
    local Themes = self.ThemeConfigs
    self:CheckConfig(ThemeData, {
        BaseTheme = Themes.DarkTheme
    })
    local BaseTheme = GetAndRemove("BaseTheme", ThemeData)
    local Theme = {
        BaseTheme = BaseTheme,
        Values = ThemeData
    }
    Themes[Name] = Theme
    return Theme
end
function ReGui:GetMouseLocation()
    local Mouse = self.Mouse
    return Mouse.X, Mouse.Y
end
function ReGui:SetWindowFocusesEnabled(Enabled)
    self.WindowFocusesEnabled = Enabled
end
function ReGui:UpdateWindowFocuses()
    local Windows = self.Windows
    local FocusesEnabled = self.WindowFocusesEnabled
    if not FocusesEnabled then
        return
    end
    for _, Class in Windows do
        local Connection = Class.HoverConnection
        if not Connection then
            continue
        end
        local Hovering = Connection.Hovering
        if Hovering then
            self:SetFocusedWindow(Class)
            return
        end
    end
    self:SetFocusedWindow(nil)
end
function ReGui:WindowCanFocus(WindowClass)
    if WindowClass.NoSelect then
        return false
    end
    if WindowClass.Collapsed then
        return false
    end
    if WindowClass._SelectDisabled then
        return false
    end
    return true
end
function ReGui:GetFocusedWindow()
    return self.FocusedWindow
end
function ReGui:BringWindowToFront(WindowClass)
    local Windows = self.Windows
    local NoBringToFront = WindowClass.NoBringToFrontOnFocus
    if NoBringToFront then
        return
    end
    MoveTableItem(Windows, WindowClass, 1)
end
function ReGui:SetFocusedWindow(ActiveClass)
    local Previous = self:GetFocusedWindow()
    local Windows = self.Windows
    if Previous == ActiveClass then
        return
    end
    self.FocusedWindow = ActiveClass
    if ActiveClass then
        local CanSelect = self:WindowCanFocus(ActiveClass)
        if not CanSelect then
            return
        end
        self:BringWindowToFront(ActiveClass)
    end
    local ZIndex = #Windows
    for _, Class in Windows do
        local CanSelect = self:WindowCanFocus(Class)
        local Window = Class.WindowFrame
        if not CanSelect then
            continue
        end
        ZIndex -= 1
        if ZIndex then
            Window.ZIndex = ZIndex
        end
        local Active = Class == ActiveClass
        Class:SetFocused(Active, ZIndex)
    end
end
function ReGui:SetItemTooltip(Parent, Render)
    local Elements = self.Elements
    local Tooltips = self.TooltipsContainer
    local ActiveTooltips = self.ActiveTooltips
    local Canvas, Object = Tooltips:Canvas({
        Visible = false,
        UiPadding = UDim.new()
    })
    task.spawn(Render, Canvas)
    ReGui:DetectHover(Parent, {
        MouseMove = true,
        MouseEnter = true,
        OnHoverChange = function(Hovering)
            if Hovering then
                table.insert(ActiveTooltips, Canvas)
                return
            end
            local Index = table.find(ActiveTooltips, Canvas)
            table.remove(ActiveTooltips, Index)
        end,
        OnInput = function(Hovering, Input)
            Object.Visible = Hovering
        end
    })
end
function ReGui:CheckFlags(Flags, Config)
    for Name, Func in next, Flags do
        local Value = Config[Name]
        if not Value then
            continue
        end
        Func(Value)
    end
end
function ReGui:GetThemeKey(Theme, Key)
    local Themes = self.ThemeConfigs
    if typeof(Theme) == "string" then
        Theme = Themes[Theme]
    end
    local DarkTheme = Themes.DarkTheme
    Theme = Theme or DarkTheme
    local BaseTheme = Theme.BaseTheme
    local Values = Theme.Values
    local Value = Values[Key]
    if Value then
        return Value
    end
    if BaseTheme then
        return self:GetThemeKey(BaseTheme, Key)
    end
    return
end
function ReGui:SelectionGroup(Elements)
    local Previous = nil
    local Debounce = false
    local function ForEach(Func, Ignore)
        for _, Element in next, Elements do
            if typeof(Element) == "Instance" then
                continue
            end
            if Element == Ignore then
                continue
            end
            Func(Element)
        end
    end
    local function Callback(self)
        if Debounce then
            return
        end
        Debounce = true
        local Value = Previous
        Previous = self:GetValue()
        if not Value then
            Value = Previous
        end
        ForEach(function(Element)
            Element:SetValue(Value)
        end, self)
        Debounce = false
    end
    ForEach(function(Element)
        Element.Callback = Callback
    end)
end
local Elements = ReGui.Elements
Elements.__index = Elements
function Elements:GetObject()
    return self.RawObject
end
function Elements:ApplyFlags(Object, Flags)
    local WindowClass = self.WindowClass
    ReGui:ApplyFlags({
        WindowClass = WindowClass,
        Object = Object,
        Class = Flags
    })
end
function Elements:Remove()
    local OnChildChange = self.OnChildChange
    local Object = self:GetObject()
    local Class = self.Class
    local ClassRemove = Class.Remove
    if ClassRemove then
        return ClassRemove(Class)
    end
    if OnChildChange then
        OnChildChange:Fire(Class or self)
    end
    if Class then
        table.clear(Class)
    end
    Object:Destroy()
    table.clear(self)
end
function Elements:GetChildElements()
    local Elements = self.Elements
    return Elements
end
function Elements:ClearChildElements()
    local Elements = self:GetChildElements()
    for _, Object in next, Elements do
        Object:Destroy()
    end
end
function Elements:TagElements(Objects)
    local WindowClass = self.WindowClass
    local Debug = ReGui.Debug
    if not WindowClass then
        if Debug then
            ReGui:Warn("No WindowClass for TagElements:", Objects)
        end
        return
    end
    WindowClass:TagElements(Objects)
end
function Elements:GetThemeKey(Key)
    local WindowClass = self.WindowClass
    if WindowClass then
        return WindowClass:GetThemeKey(Key)
    end
    return ReGui:GetThemeKey(nil, Key)
end
function Elements:SetColorTags(Objects, Animate)
    local WindowClass = self.WindowClass
    if not WindowClass then
        return
    end
    local Elements = WindowClass.TagsList
    local Theme = WindowClass.Theme
    ReGui:MultiUpdateColors({
        Animate = Animate,
        Theme = Theme,
        TagsList = Elements,
        Objects = Objects
    })
end
function Elements:SetElementFocused(Object, Data)
    local WindowClass = self.WindowClass
    local IsMobileDevice = ReGui.HasTouchScreen
    local Focused = Data.Focused
    local Animation = Data.Animation
    ReGui:SetAnimationsEnabled(not Focused)
    if not Focused and Animation then
        Animation:Refresh()
    end
    if not WindowClass then
        return
    end
    if not IsMobileDevice then
        return
    end
    local ContentCanvas = WindowClass.ContentCanvas
    ContentCanvas.Interactable = not Focused
end
ReGui:DefineElement("Dropdown", {
    Base = {
        ColorTag = "PopupCanvas",
        Disabled = false,
        AutoClose = true,
        OnSelected = EmptyFunction
    },
    Create = function(Canvas, Config)
        Config.Parent = ReGui.Container.Overlays
        local Selected = Config.Selected
        local Items = Config.Items
        local OnSelected = Config.OnSelected
        local Popup, Object = Canvas:PopupCanvas(Config)
        local Class = ReGui:MergeMetatables(Config, Popup)
        local Entries = {}
        local function SetValue(Value)
            OnSelected(Value)
        end
        function Config:ClearEntries()
            for _, Entry in Entries do
                Entry:Remove()
            end
        end
        function Config:SetItems(Items, Selected)
            local IsArray = Items[1]
            self:ClearEntries()
            for A, B in Items do
                local Value = IsArray and B or A
                local IsSelected = A == Selected or B == Selected
                local Entry = Popup:Selectable({
                    Text = tostring(Value),
                    Selected = IsSelected,
                    ZIndex = 6,
                    Callback = function()
                        return SetValue(Value)
                    end
                })
                table.insert(Entries, Entry)
            end
        end
        if Items then
            Config:SetItems(Items, Selected)
        end
        return Class, Object
    end
})
ReGui:DefineElement("OverlayScroll", {
    Base = {
        ElementClass = "OverlayScroll",
        Spacing = UDim.new(0, 4)
    },
    Create = function(self, Config)
        local WindowClass = self.WindowClass
        local ElementClass = Config.ElementClass
        local Spacing = Config.Spacing
        local Object = ReGui:InsertPrefab(ElementClass, Config)
        local ContentFrame = Object:FindFirstChild("ContentFrame") or Object
        local ListLayout = Object:FindFirstChild("UIListLayout", true)
        ListLayout.Padding = Spacing
        local Class = ReGui:MergeMetatables(self, Config)
        local Canvas = ReGui:MakeCanvas({
            Element = ContentFrame,
            WindowClass = WindowClass,
            Class = Class
        })
        function Config:GetCanvasSize()
            return ContentFrame.AbsoluteCanvasSize
        end
        return Canvas, Object
    end
})
ReGui:DefineElement("Overlay", {
    Base = {
        ElementClass = "Overlay"
    },
    Create = Elements.OverlayScroll
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Image", {
    Base = {
        Image = "",
        Callback = EmptyFunction
    },
    Create = function(self, Config)
        local Object = ReGui:InsertPrefab("Image", Config)
        Object.Activated:Connect(function(...)
            local Func = Config.Callback
            return Func(Object, ...)
        end)
        return Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("VideoPlayer", {
    Base = {
        Video = "",
        Callback = EmptyFunction
    },
    Create = function(self, Config)
        local Video = Config.Video
        Config.Video = Wrappers:CheckAssetUrl(Video)
        local Object = ReGui:InsertPrefab("VideoPlayer", Config)
        return Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Button", {
    Base = {
        Text = "Button",
        DoubleClick = false,
        Callback = EmptyFunction
    },
    Create = function(self, Config)
        local Object = ReGui:InsertPrefab("Button", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        local DoubleClick = Config.DoubleClick
        function Config:SetDisabled(Disabled)
            self.Disabled = Disabled
        end
        ReGui:ConnectMouseEvent(Object, {
            DoubleClick = DoubleClick,
            Callback = function(...)
                if Config.Disabled then
                    return
                end
                local Func = Config.Callback
                return Func(Class, ...)
            end
        })
        return Class, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Selectable", {
    Base = {
        Text = "Selectable",
        Callback = EmptyFunction,
        Selected = false,
        Disabled = false,
        Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextXAlignment = Enum.TextXAlignment.Left,
        AnimationTags = {
            Selected = "Buttons",
            Unselected = "TransparentButtons"
        }
    },
    Create = function(self, Config)
        local AfterClick = self.Class.AfterClick
        local Selected = Config.Selected
        local Disabled = Config.Disabled
        local Object = ReGui:InsertPrefab("Button", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        Object.Activated:Connect(function(...)
            local Func = Config.Callback
            Func(Object, ...)
            if AfterClick then
                AfterClick(Object, ...)
            end
        end)
        function Config:SetSelected(Selected)
            local Animations = self.AnimationTags
            local Animation = Selected and Animations.Selected or Animations.Unselected
            self.Selected = Selected
            ReGui:SetAnimation(Object, Animation)
            return self
        end
        function Config:SetDisabled(Disabled)
            self.Disabled = Disabled
            Object.Interactable = not Disabled
            return self
        end
        Config:SetSelected(Selected)
        Config:SetDisabled(Disabled)
        return Class, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("ImageButton", {
    Base = {
        ElementStyle = "Button",
        Callback = EmptyFunction
    },
    Create = Elements.Image
})
ReGui:DefineElement("SmallButton", {
    Base = {
        Text = "Button",
        PaddingTop = UDim.new(),
        PaddingBottom = UDim.new(),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 2),
        ColorTag = "Button",
        ElementStyle = "Button",
        Callback = EmptyFunction
    },
    Create = Elements.Button
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Keybind", {
    Base = {
        Label = "Keybind",
        ColorTag = "Frame",
        Value = nil,
        DeleteKey = Enum.KeyCode.Backspace,
        IgnoreGameProcessed = true,
        Enabled = true,
        Disabled = false,
        Callback = EmptyFunction,
        OnKeybindSet = EmptyFunction,
        OnBlacklistedKeybindSet = EmptyFunction,
        KeyBlacklist = {},
        UiPadding = UDim.new(),
        AutomaticSize = Enum.AutomaticSize.None,
        Size = UDim2.new(0.3, 0, 0, 19)
    },
    Create = function(Canvas, Config)
        local Value = Config.Value
        local LabelText = Config.Label
        local Disabled = Config.Disabled
        local KeyBlacklist = Config.KeyBlacklist
        local Object = ReGui:InsertPrefab("Button", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        local Label = Canvas:Label({
            Parent = Object,
            Text = LabelText,
            Position = UDim2.new(1, 4, 0.5),
            AnchorPoint = Vector2.new(0, 0.5)
        })
        local function Callback(Func, ...)
            return Func(Object, ...)
        end
        local function KeyIsBlacklisted(KeyId)
            return table.find(KeyBlacklist, KeyId)
        end
        function Config:SetDisabled(Disabled)
            self.Disabled = Disabled
            Object.Interactable = not Disabled
            Canvas:SetColorTags({
                [Label] = Disabled and "LabelDisabled" or "Label"
            }, true)
            return self
        end
        function Config:SetValue(KeyId)
            local OnKeybindSet = self.OnKeybindSet
            local DeleteKey = self.DeleteKey
            if KeyId == DeleteKey then
                KeyId = nil
            end
            self.Value = KeyId
            Object.Text = KeyId and KeyId.Name or "Not set"
            Callback(OnKeybindSet, KeyId)
            return self
        end
        function Config:WaitForNewKey()
            self._WaitingForNewKey = true
            Object.Text = "..."
            Object.Interactable = false
        end
        local function GetKeyId(Input)
            local KeyCode = Input.KeyCode
            local InputType = Input.UserInputType
            if InputType ~= Enum.UserInputType.Keyboard then
                return InputType
            end
            return KeyCode
        end
        local function CheckNewKey(Input)
            local OnBlacklistedKeybindSet = Config.OnBlacklistedKeybindSet
            local Previous = Config.Value
            local KeyId = GetKeyId(Input)
            if not UserInputService.WindowFocused then
                return
            end
            if KeyIsBlacklisted(KeyId) then
                Callback(OnBlacklistedKeybindSet, KeyId)
                return
            end
            Object.Interactable = true
            Config._WaitingForNewKey = false
            if KeyId.Name == "Unknown" then
                return Config:SetValue(Previous)
            end
            Config:SetValue(KeyId)
            return
        end
        local function InputBegan(Input, GameProcessed)
            local IgnoreGameProcessed = Config.IgnoreGameProcessed
            local DeleteKey = Config.DeleteKey
            local Enabled = Config.Enabled
            local Value = Config.Value
            local Func = Config.Callback
            local KeyId = GetKeyId(Input)
            if Config._WaitingForNewKey then
                CheckNewKey(Input)
                return
            end
            if not Enabled and Object.Interactable then
                return
            end
            if not IgnoreGameProcessed and GameProcessed then
                return
            end
            if not Value then
                return
            end
            if KeyId == DeleteKey then
                return
            end
            if KeyId.Name ~= Value.Name then
                return
            end
            Callback(Func, KeyId)
        end
        Config:SetValue(Value)
        Config:SetDisabled(Disabled)
        Config.Connection = UserInputService.InputBegan:Connect(InputBegan)
        Object.Activated:Connect(function()
            Config:WaitForNewKey()
        end)
        ReGui:SetAnimation(Object, "Inputs")
        return Class, Object
    end
})
ReGui:DefineElement("ArrowButton", {
    Base = {
        Direction = "Left",
        ColorTag = "Button",
        Icon = ReGui.Icons.Arrow,
        Size = UDim2.fromOffset(21, 21),
        IconSize = UDim2.fromScale(1, 1),
        IconPadding = UDim.new(0, 4),
        Rotations = {
            Left = 180,
            Right = 0
        }
    },
    Create = function(self, Config)
        local Direction = Config.Direction
        local Rotations = Config.Rotations
        local Rotation = Rotations[Direction]
        Config.IconRotation = Rotation
        local Object = ReGui:InsertPrefab("ArrowButton", Config)
        Object.Activated:Connect(function(...)
            local Func = Config.Callback
            return Func(Object, ...)
        end)
        return Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Label", {
    Base = {
        Font = "Inconsolata"
    },
    ColorData = {
        ["LabelPadding"] = {
            PaddingTop = "LabelPaddingTop",
            PaddingBottom = "LabelPaddingBottom"
        }
    },
    Create = function(self, Config)
        local IsBold = Config.Bold
        local IsItalic = Config.Italic
        local FontName = Config.Font
        local FontFace = Config.FontFace
        local Medium = Enum.FontWeight.Medium
        local Bold = Enum.FontWeight.Bold
        local Normal = Enum.FontStyle.Normal
        local Italic = Enum.FontStyle.Italic
        local Weight = IsBold and Bold or Medium
        local Style = IsItalic and Italic or Normal
        local AddFlag = IsBold or IsItalic
        if not FontFace and AddFlag then
            Config.FontFace = Font.fromName(FontName, Weight, Style)
        end
        local Label = ReGui:InsertPrefab("Label", Config)
        local Padding = Label:FindFirstChildOfClass("UIPadding")
        self:TagElements({
            [Padding] = "LabelPadding"
        })
        return Label
    end
})
ReGui:DefineElement("Error", {
    Base = {
        RichText = true,
        TextWrapped = true
    },
    ColorData = {
        ["Error"] = {
            TextColor3 = "ErrorText",
            FontFace = "TextFont"
        }
    },
    Create = function(self, Config)
        local Message = Config.Text
        Config.Text = `<b>\226\155\148 Error:</b> {Message}`
        return self:Label(Config)
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("CodeEditor", {
    Base = {
        Editable = true,
        Fill = true,
        Text = ""
    },
    Create = function(self, Config)
        local Window = self.WindowClass
        local CodeEditor = IDE.CodeFrame.new(Config)
        local Frame = CodeEditor.Gui
        Config.Parent = self:GetObject()
        ReGui:ApplyFlags({
            Object = Frame,
            WindowClass = Window,
            Class = Config
        })
        return CodeEditor, Frame
    end
})
local MenuBar = {
    Engaged = false
}
MenuBar.__index = MenuBar
function MenuBar:SetEngaged(Engaged)
    local Window = self.WindowClass
    self.Engaged = Engaged
    if Window then
        Window:SetCanvasInteractable(not Engaged)
    end
end
function MenuBar:IsHovering()
    local Hovering = false
    self:Foreach(function(Data)
        Hovering = Data.Popup:IsMouseHovering()
        return Hovering
    end)
    return Hovering
end
function MenuBar:Foreach(Func)
    local Menus = self.Menus
    for _, Data in next, Menus do
        local Break = Func(Data)
        if Break then
            break
        end
    end
end
function MenuBar:SetFocusedMenu(Menu)
    self:Foreach(function(Data)
        local Active = Data == Menu
        Data:SetActiveState(Active)
    end)
end
function MenuBar:Close()
    self:SetEngaged(false)
    self:SetFocusedMenu(nil)
end
function MenuBar:MenuItem(Config)
    local Canvas = self.Canvas
    local Menus = self.Menus
    local Selectable = Canvas:MenuButton(Config)
    local Popup = Canvas:PopupCanvas({
        RelativeTo = Selectable,
        MaxSizeX = 210,
        Visible = false,
        AutoClose = false,
        AfterClick = function()
            self:Close()
        end
    })
    local MenuData = {
        Popup = Popup,
        Button = Selectable
    }
    ReGui:DetectHover(Selectable, {
        MouseEnter = true,
        OnInput = function()
            if not self.Engaged then
                return
            end
            self:SetFocusedMenu(MenuData)
        end
    })
    function MenuData:SetActiveState(Active)
        Popup:SetPopupVisible(Active)
        Selectable:SetSelected(Active)
    end
    Selectable.Activated:Connect(function()
        self:SetFocusedMenu(MenuData)
        self:SetEngaged(true)
    end)
    table.insert(Menus, MenuData)
    return Popup, MenuData
end
ReGui:DefineElement("MenuBar", {
    Base = {},
    Create = function(self, Config)
        local WindowClass = self.WindowClass
        local Object = ReGui:InsertPrefab("MenuBar", Config)
        local Canvas = ReGui:MakeCanvas({
            Element = Object,
            WindowClass = WindowClass,
            Class = Config
        })
        local Class = Wrappers:NewClass(MenuBar, {
            WindowClass = WindowClass,
            Canvas = Canvas,
            Object = Object,
            Menus = {}
        })
        Merge(Class, Config)
        ReGui:DetectHover(Object, {
            MouseOnly = true,
            OnInput = function()
                if not Class.Engaged then
                    return
                end
                if Class:IsHovering() then
                    return
                end
                Class:Close()
            end
        })
        local Meta = ReGui:MergeMetatables(Class, Canvas)
        return Meta, Object
    end
})
ReGui:DefineElement("MenuButton", {
    Base = {
        Text = "MenuButton",
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Size = UDim2.fromOffset(0, 19),
        AutomaticSize = Enum.AutomaticSize.XY
    },
    Create = Elements.Selectable
})
local TabBarClass = {
    ColorTags = {
        BGSelected = {
            [true] = "SelectedTab",
            [false] = "DeselectedTab"
        },
        LabelSelected = {
            [true] = "SelectedTabLabel",
            [false] = "DeselectedTabLabel"
        }
    }
}
function TabBarClass:SetButtonSelected(Tab, Selected)
    if Tab.IsSelected == Selected then
        return
    end
    Tab.IsSelected = Selected
    local NoAnimation = self.NoAnimation
    local WindowClass = self.WindowClass
    local ColorTags = self.ColorTags
    local Theme = WindowClass.Theme
    local Elements = WindowClass.TagsList
    local BGSelected = ColorTags.BGSelected
    local LabelSelected = ColorTags.LabelSelected
    local TabButton = Tab.TabButton
    local Button = TabButton.Button
    local Label = Button.Label
    ReGui:MultiUpdateColors({
        Animate = not NoAnimation,
        Theme = Theme,
        TagsList = Elements,
        Objects = {
            [Button] = BGSelected[Selected],
            [Label] = LabelSelected[Selected]
        }
    })
end
function TabBarClass:CompareTabs(Tab, Match)
    if not Tab then
        return false
    end
    return Tab.MatchBy == Match or Tab == Match
end
function TabBarClass:ForEachTab(Match, Func)
    local CompareName = typeof(Match) == "string"
    local Tabs = self.Tabs
    for Index, Tab in Tabs do
        local Name = Tab.Name
        local IsMatch = false
        if CompareName then
            IsMatch = Name == Match
        else
            IsMatch = self:CompareTabs(Tab, Match)
        end
        Func(Tab, IsMatch, Index)
    end
end
function TabBarClass:RemoveTab(Target)
    local OnTabRemove = self.OnTabRemove
    local Tabs = self.Tabs
    self:ForEachTab(Target, function(Tab, IsMatch, Index)
        if not IsMatch then
            return
        end
        local TabButton = Tab.TabButton
        local OnClosure = Tab.OnClosure
        table.remove(Tabs, Index)
        TabButton:Destroy()
        OnTabRemove(self, Tab)
        OnClosure(Tab)
    end)
    return self
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
function TabBarClass:CreateTab(Config)
    Config = Config or {}
    ReGui:CheckConfig(Config, {
        Name = "Tab",
        AutoSize = "Y",
        Focused = false,
        OnClosure = EmptyFunction
    })
    local AutoSelectNewTabs = self.AutoSelectNewTabs
    local WindowClass = self.WindowClass
    local ParentCanvas = self.ParentCanvas
    local Tabs = self.Tabs
    local TabsFrame = self.TabsFrame
    local OnTabCreate = self.OnTabCreate
    local Focused = Config.Focused
    local Name = Config.Name
    local Icon = Config.Icon
    local IsFocused = Focused or #Tabs <= 0 and AutoSelectNewTabs
    local TabButton = ReGui:InsertPrefab("TabButton", Config)
    TabButton.Parent = TabsFrame
    local Button = TabButton.Button
    local TextPadding = Button:FindFirstChildOfClass("UIPadding")
    local Label = Button.Label
    Label.Text = tostring(Name)
    Merge(Config, {
        TabButton = TabButton
    })
    local function SetActive()
        self:SetActiveTab(Config)
    end
    local ExtraFlags = {
        ["Closeable"] = function()
            local Button = ParentCanvas:RadioButton({
                Parent = Button,
                Visible = not self.NoClose,
                Icon = ReGui.Icons.Close,
                IconSize = UDim2.fromOffset(11, 11),
                LayoutOrder = 3,
                ZIndex = 2,
                UsePropertiesList = true,
                Callback = function()
                    self:RemoveTab(Config)
                end
            })
            local Icon = Button.Icon
            ReGui:SetAnimation(Icon, {
                Connections = {
                    MouseEnter = {
                        ImageTransparency = 0
                    },
                    MouseLeave = {
                        ImageTransparency = 1
                    }
                },
                Init = "MouseLeave"
            }, TabButton)
        end
    }
    Button.Activated:Connect(SetActive)
    ReGui:CheckFlags(ExtraFlags, Config)
    table.insert(Tabs, Config)
    if WindowClass then
        WindowClass:TagElements({
            [TextPadding] = "TabPadding"
        })
    end
    ReGui:SetAnimation(Button, "Buttons")
    self:SetButtonSelected(Config, IsFocused)
    ParentCanvas:ApplyFlags(TabButton, Config)
    local Responce = OnTabCreate(self, Config)
    if IsFocused then
        self:SetActiveTab(Config)
    end
    return Responce or Config
end
function TabBarClass:SetActiveTab(Target)
    local Tabs = self.Tabs
    local NoAnimation = self.NoAnimation
    local Previous = self.ActiveTab
    local OnActiveTabChange = self.OnActiveTabChange
    local MatchName = typeof(Target) == "string"
    local MatchedTab = nil
    local IsVisible = false
    self:ForEachTab(Target, function(Tab, IsMatch, Index)
        if IsMatch then
            MatchedTab = Tab
        end
        self:SetButtonSelected(Tab, IsMatch)
    end)
    if not MatchedTab then
        return self
    end
    if self:CompareTabs(MatchedTab, Previous) then
        return self
    end
    self.ActiveTab = MatchedTab
    OnActiveTabChange(self, MatchedTab, Previous)
    return self
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("TabBar", {
    Base = {
        AutoSelectNewTabs = true,
        OnActiveTabChange = EmptyFunction,
        OnTabCreate = EmptyFunction,
        OnTabRemove = EmptyFunction
    },
    ColorData = {
        ["DeselectedTab"] = {
            BackgroundColor3 = "TabBg"
        },
        ["SelectedTab"] = {
            BackgroundColor3 = "TabBgActive"
        },
        ["DeselectedTabLabel"] = {
            FontFace = "TextFont",
            TextColor3 = "TabText"
        },
        ["SelectedTabLabel"] = {
            FontFace = "TextFont",
            TextColor3 = "TabTextActive"
        },
        ["TabsBarSeparator"] = {
            BackgroundColor3 = "TabBgActive"
        },
        ["TabPadding"] = {
            PaddingTop = "TabTextPaddingTop",
            PaddingBottom = "TabTextPaddingBottom"
        },
        ["TabPagePadding"] = {
            PaddingBottom = "TabPagePadding",
            PaddingLeft = "TabPagePadding",
            PaddingRight = "TabPagePadding",
            PaddingTop = "TabPagePadding"
        }
    },
    Create = function(self, Config)
        local WindowClass = self.WindowClass
        local Object = ReGui:InsertPrefab("TabsBar", Config)
        local Class = Wrappers:NewClass(TabBarClass)
        local Separator = Object.Separator
        local TabsFrame = Object.TabsFrame
        local TabsRailCanvas = ReGui:MakeCanvas({
            Element = TabsFrame,
            WindowClass = WindowClass,
            Class = Class
        })
        Merge(Class, Config)
        Merge(Class, {
            ParentCanvas = self,
            Object = Object,
            TabsFrame = TabsFrame,
            WindowClass = WindowClass,
            Tabs = {}
        })
        self:TagElements({
            [Object] = "TabsBar",
            [Separator] = "TabsBarSeparator"
        })
        local Merged = ReGui:MergeMetatables(TabsRailCanvas, Object)
        return Merged, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("TabSelector", {
    Base = {
        NoTabsBar = false,
        OnActiveTabChange = EmptyFunction,
        OnTabCreate = EmptyFunction,
        OnTabRemove = EmptyFunction
    },
    Create = function(Canvas, Config)
        local WindowClass = Canvas.WindowClass
        local NoTabsBar = Config.NoTabsBar
        local NoAnimation = Config.NoAnimation
        local Object = ReGui:InsertPrefab("TabSelector", Config)
        local Body = Object.Body
        local PageTemplate = Body.PageTemplate
        PageTemplate.Visible = false
        local function OnTabCreate(self, Tab, ...)
            local AutoSize = Tab.AutoSize
            local Name = Tab.Name
            local Page = PageTemplate:Clone()
            local PagePadding = Wrappers:GetChildOfClass(Page, "UIPadding")
            ReGui:SetProperties(Page, {
                Parent = Body,
                Name = Name,
                AutomaticSize = Enum.AutomaticSize[AutoSize],
                Size = UDim2.fromScale(AutoSize == "Y" and 1 or 0, AutoSize == "X" and 1 or 0)
            })
            Canvas:TagElements({
                [PagePadding] = "TabPagePadding"
            })
            local Canvas = ReGui:MakeCanvas({
                Element = Page,
                WindowClass = WindowClass,
                Class = Tab
            })
            Config.OnTabCreate(self, Tab, ...)
            Merge(Tab, {
                Page = Page,
                MatchBy = Canvas
            })
            return Canvas
        end
        local function OnActiveTabChange(self, Tab, ...)
            self:ForEachTab(Tab, function(Tab, IsMatch, Index)
                local Page = Tab.Page
                Page.Visible = IsMatch
                if not IsMatch then
                    return
                end
                local Tweeninfo = Canvas:GetThemeKey("AnimationTweenInfo")
                Animation:Tween({
                    Object = Page,
                    Tweeninfo = Tweeninfo,
                    NoAnimation = NoAnimation,
                    StartProperties = {
                        Position = UDim2.fromOffset(0, 4)
                    },
                    EndProperties = {
                        Position = UDim2.fromOffset(0, 0)
                    }
                })
            end)
            Config.OnActiveTabChange(self, Tab, ...)
        end
        local TabsBar = Canvas:TabBar({
            Parent = Object,
            Visible = not NoTabsBar,
            OnTabCreate = OnTabCreate,
            OnActiveTabChange = OnActiveTabChange,
            OnTabRemove = function(self, Tab, ...)
                Tab.Page:Remove()
                Config.OnTabRemove(...)
            end
        })
        local Class = ReGui:MergeMetatables(TabsBar, Object)
        return Class, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("RadioButton", {
    Base = {
        Callback = EmptyFunction
    },
    Create = function(self, Config)
        local Object = ReGui:InsertPrefab("RadioButton", Config)
        Object.Activated:Connect(function(...)
            local Callback = Config.Callback
            return Callback(Object, ...)
        end)
        return Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Checkbox", {
    Base = {
        Label = "Checkbox",
        IsRadio = false,
        Value = false,
        NoAutoTag = true,
        TickedImageSize = UDim2.fromScale(1, 1),
        UntickedImageSize = UDim2.fromScale(0, 0),
        Callback = EmptyFunction,
        Disabled = false
    },
    Create = function(Canvas, Config)
        local IsRadio = Config.IsRadio
        local Value = Config.Value
        local Text = Config.Label
        local TickedSize = Config.TickedImageSize
        local UntickedSize = Config.UntickedImageSize
        local Disabled = Config.Disabled
        local Object = ReGui:InsertPrefab("CheckBox", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        local Tickbox = Object.Tickbox
        local Tick = Tickbox.Tick
        Tick.Image = ReGui.Icons.Checkmark
        local UIPadding = Tickbox:FindFirstChildOfClass("UIPadding")
        local UICorner = Wrappers:GetChildOfClass(Tickbox, "UICorner")
        local Label = Canvas:Label({
            Text = Text,
            Parent = Object,
            LayoutOrder = 2
        })
        local PaddingSize = UDim.new(0, 3)
        if IsRadio then
            Tick.ImageTransparency = 1
            Tick.BackgroundTransparency = 0
            UICorner.CornerRadius = UDim.new(1, 0)
        else
            PaddingSize = UDim.new(0, 2)
        end
        ReGui:SetProperties(UIPadding, {
            PaddingBottom = PaddingSize,
            PaddingLeft = PaddingSize,
            PaddingRight = PaddingSize,
            PaddingTop = PaddingSize
        })
        local function Callback(...)
            local func = Config.Callback
            return func(Class, ...)
        end
        local function SetStyle(Value, NoAnimation)
            local Tweeninfo = Canvas:GetThemeKey("AnimationTweenInfo")
            local Size = Value and TickedSize or UntickedSize
            Animation:Tween({
                Object = Tick,
                Tweeninfo = Tweeninfo,
                NoAnimation = NoAnimation,
                EndProperties = {
                    Size = Size
                }
            })
        end
        function Config:SetDisabled(Disabled)
            self.Disabled = Disabled
            Object.Interactable = not Disabled
            Canvas:SetColorTags({
                [Label] = Disabled and "LabelDisabled" or "Label"
            }, true)
            return self
        end
        function Config:SetValue(Value, NoAnimation)
            self.Value = Value
            SetStyle(Value, NoAnimation)
            Callback(Value)
            return self
        end
        function Config:SetTicked(...)
            ReGui:Warn("Checkbox:SetTicked is deprecated, please use :SetValue")
            return self:SetValue(...)
        end
        function Config:Toggle()
            local Value = not self.Value
            self.Value = Value
            self:SetValue(Value)
            return self
        end
        local function Clicked()
            Config:Toggle()
        end
        Object.Activated:Connect(Clicked)
        Tickbox.Activated:Connect(Clicked)
        Config:SetValue(Value, true)
        Config:SetDisabled(Disabled)
        ReGui:SetAnimation(Tickbox, "Buttons", Object)
        Canvas:TagElements({
            [Tick] = "CheckMark",
            [Tickbox] = "Checkbox"
        })
        return Class, Object
    end
})
ReGui:DefineElement("Radiobox", {
    Base = {
        IsRadio = true,
        CornerRadius = UDim.new(1, 0)
    },
    Create = Elements.Checkbox
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("PlotHistogram", {
    Base = {
        ColorTag = "Frame",
        Label = "Histogram"
    },
    Create = function(Canvas, Config)
        local LabelText = Config.Label
        local Points = Config.Points
        local Object = ReGui:InsertPrefab("Histogram", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        local GraphCanvas = Object.Canvas
        local PointTemplate = GraphCanvas.PointTemplate
        PointTemplate.Visible = false
        Canvas:Label({
            Text = LabelText,
            Parent = Object,
            Position = UDim2.new(1, 4)
        })
        local ValueLabel = nil
        ReGui:SetItemTooltip(Object, function(Canvas)
            ValueLabel = Canvas:Label()
        end)
        Merge(Config, {
            _Plots = {},
            _Cache = {}
        })
        function Config:GetBaseValues()
            local Minimum = self.Minimum
            local Maximum = self.Maximum
            if Minimum and Maximum then
                return Minimum, Maximum
            end
            local Plots = self._Plots
            for _, Data in Plots do
                local Value = Data.Value
                if not Minimum or Value < Minimum then
                    Minimum = Value
                end
                if not Maximum or Value > Maximum then
                    Maximum = Value
                end
            end
            return Minimum, Maximum
        end
        function Config:UpdateGraph()
            local Plots = self._Plots
            local Minimum, Maximum = self:GetBaseValues()
            if not Minimum or not Maximum then
                return
            end
            local Difference = Maximum - Minimum
            for _, Data in Plots do
                local Point = Data.Point
                local Value = Data.Value
                local Scale = (Value - Minimum) / Difference
                Scale = math.clamp(Scale, 0.05, 1)
                Point.Size = UDim2.fromScale(1, Scale)
            end
            return self
        end
        function Config:Plot(Value)
            local Plots = self._Plots
            local Module = {}
            local Plot = PointTemplate:Clone()
            local Point = Plot.Bar
            ReGui:SetProperties(Plot, {
                Parent = GraphCanvas,
                Visible = true
            })
            local HoverConnection = ReGui:DetectHover(Plot, {
                MouseEnter = true,
                OnInput = function()
                    Module:UpdateTooltip()
                end
            })
            local Data = {
                Object = Plot,
                Point = Point,
                Value = Value
            }
            function Module:UpdateTooltip()
                local Index = Module:GetPointIndex()
                ValueLabel.Text = `{Index}:\t{Data.Value}`
            end
            function Module:SetValue(Value)
                Data.Value = Value
                Config:UpdateGraph()
                if HoverConnection.Hovering then
                    self:UpdateTooltip()
                end
            end
            function Module:GetPointIndex()
                return table.find(Plots, Data)
            end
            function Module:Remove(Value)
                table.remove(Plots, self:GetPointIndex())
                Plot:Remove()
                Config:UpdateGraph()
            end
            table.insert(Plots, Data)
            self:UpdateGraph()
            ReGui:SetAnimation(Point, "Plots", Plot)
            Canvas:TagElements({
                [Point] = "Plot"
            })
            return Module
        end
        function Config:PlotGraph(Points)
            local Cache = self._Cache
            local Extra = #Cache - #Points
            if Extra >= 1 then
                for Index = 1, Extra do
                    local Point = table.remove(Cache, Index)
                    if Point then
                        Point:Remove()
                    end
                end
            end
            for Index, Value in Points do
                local Point = Cache[Index]
                if Point then
                    Point:SetValue(Value)
                    continue
                end
                Cache[Index] = self:Plot(Value)
            end
            return self
        end
        if Points then
            Config:PlotGraph(Points)
        end
        return Class, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Viewport", {
    Base = {
        IsRadio = true
    },
    Create = function(self, Config)
        local Model = Config.Model
        local Camera = Config.Camera
        local Object = ReGui:InsertPrefab("Viewport", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        local Viewport = Object.Viewport
        local WorldModel = Viewport.WorldModel
        if not Camera then
            Camera = ReGui:CreateInstance("Camera", Viewport)
            Camera.CFrame = CFrame.new(0, 0, 0)
        end
        Merge(Config, {
            Camera = Camera,
            WorldModel = WorldModel,
            Viewport = Viewport
        })
        function Config:SetCamera(Camera)
            self.Camera = Camera
            Viewport.CurrentCamera = Camera
            return self
        end
        function Config:SetModel(Model, PivotTo)
            local CreateClone = self.Clone
            WorldModel:ClearAllChildren()
            if CreateClone then
                Model = Model:Clone()
            end
            if PivotTo then
                Model:PivotTo(PivotTo)
            end
            Model.Parent = WorldModel
            self.Model = Model
            return Model
        end
        if Model then
            Config:SetModel(Model)
        end
        Config:SetCamera(Camera)
        return Class, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("InputText", {
    Base = {
        Value = "",
        Placeholder = "",
        Label = "Input text",
        Callback = EmptyFunction,
        MultiLine = false,
        NoAutoTag = true,
        Disabled = false
    },
    Create = function(Canvas, Config)
        local MultiLine = Config.MultiLine
        local Placeholder = Config.Placeholder
        local Label = Config.Label
        local Disabled = Config.Disabled
        local Value = Config.Value
        local Object = ReGui:InsertPrefab("InputBox", Config)
        local Frame = Object.Frame
        local TextBox = Frame.Input
        local Class = ReGui:MergeMetatables(Config, Object)
        Canvas:Label({
            Parent = Object,
            Text = Label,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 19),
            Position = UDim2.new(1, 4),
            LayoutOrder = 2
        })
        ReGui:SetProperties(TextBox, {
            PlaceholderText = Placeholder,
            MultiLine = MultiLine
        })
        local function Callback(...)
            local Func = Config.Callback
            Func(Class, ...)
        end
        function Config:SetValue(Value)
            TextBox.Text = tostring(Value)
            self.Value = Value
            return self
        end
        function Config:SetDisabled(Disabled)
            self.Disabled = Disabled
            Object.Interactable = not Disabled
            Canvas:SetColorTags({
                [Label] = Disabled and "LabelDisabled" or "Label"
            }, true)
            return self
        end
        function Config:Clear()
            TextBox.Text = ""
            return self
        end
        local function TextChanged()
            local Value = TextBox.Text
            Config.Value = Value
            Callback(Value)
        end
        TextBox:GetPropertyChangedSignal("Text"):Connect(TextChanged)
        Config:SetDisabled(Disabled)
        Config:SetValue(Value)
        Canvas:TagElements({
            [TextBox] = "Frame"
        })
        return Class, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("InputInt", {
    Base = {
        Value = 0,
        Increment = 1,
        Placeholder = "",
        Label = "Input Int",
        Callback = EmptyFunction
    },
    Create = function(Canvas, Config)
        local Value = Config.Value
        local Placeholder = Config.Placeholder
        local LabelText = Config.Label
        local Disabled = Config.Disabled
        local NoButtons = Config.NoButtons
        local Object = ReGui:InsertPrefab("InputBox", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        local Frame = Object.Frame
        local TextBox = Frame.Input
        TextBox.PlaceholderText = Placeholder
        local Decrease = Canvas:Button({
            Text = "-",
            Parent = Frame,
            LayoutOrder = 2,
            Ratio = 1,
            AutomaticSize = Enum.AutomaticSize.None,
            FlexMode = Enum.UIFlexMode.None,
            Size = UDim2.fromScale(1, 1),
            Visible = not NoButtons,
            Callback = function()
                Config:Decrease()
            end
        })
        local Increase = Canvas:Button({
            Text = "+",
            Parent = Frame,
            LayoutOrder = 3,
            Ratio = 1,
            AutomaticSize = Enum.AutomaticSize.None,
            FlexMode = Enum.UIFlexMode.None,
            Size = UDim2.fromScale(1, 1),
            Visible = not NoButtons,
            Callback = function()
                Config:Increase()
            end
        })
        local Label = Canvas:Label({
            Parent = Object,
            Text = LabelText,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 19),
            Position = UDim2.new(1, 4),
            LayoutOrder = 4
        })
        local function Callback(...)
            local Func = Config.Callback
            Func(Class, ...)
        end
        function Config:Increase()
            local Value = self.Value
            local Increment = self.Increment
            Config:SetValue(Value + Increment)
        end
        function Config:Decrease()
            local Value = self.Value
            local Increment = self.Increment
            Config:SetValue(Value - Increment)
        end
        function Config:SetDisabled(Disabled)
            self.Disabled = Disabled
            Object.Interactable = not Disabled
            Canvas:SetColorTags({
                [Label] = Disabled and "LabelDisabled" or "Label"
            }, true)
            return self
        end
        function Config:SetValue(Value)
            local Previous = self.Value
            local Minimum = self.Minimum
            local Maximum = self.Maximum
            Value = tonumber(Value)
            if not Value then
                Value = Previous
            end
            if Minimum and Maximum then
                Value = math.clamp(Value, Minimum, Maximum)
            end
            TextBox.Text = Value
            Config.Value = Value
            Callback(Value)
            return self
        end
        local function TextChanged()
            local New = TextBox.Text
            Config:SetValue(New)
        end
        Config:SetValue(Value)
        Config:SetDisabled(Disabled)
        TextBox.FocusLost:Connect(TextChanged)
        Canvas:TagElements({
            [Increase] = "Button",
            [Decrease] = "Button",
            [TextBox] = "Frame"
        })
        return Class, Object
    end
})
ReGui:DefineElement("InputTextMultiline", {
    Base = {
        Label = "",
        Size = UDim2.new(1, 0, 0, 39),
        Border = false,
        ColorTag = "Frame"
    },
    Create = function(self, Config)
        return self:Console(Config)
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Console", {
    Base = {
        Enabled = true,
        Value = "",
        TextWrapped = false,
        Border = true,
        MaxLines = 300,
        LinesFormat = "%s",
        Callback = EmptyFunction
    },
    Create = function(self, Config)
        local ReadOnly = Config.ReadOnly
        local LineNumbers = Config.LineNumbers
        local Value = Config.Value
        local Placeholder = Config.Placeholder
        local Object = ReGui:InsertPrefab("Console", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        local Source = Object.Source
        local Lines = Object.Lines
        Lines.Visible = LineNumbers
        function Config:CountLines(ExcludeEmpty)
            local Lines = Source.Text:split("\n")
            local Count = #Lines
            if Count == 1 and Lines[1] == "" then
                return 0
            end
            return Count
        end
        function Config:UpdateLineNumbers()
            local LineNumbers = self.LineNumbers
            local Format = self.LinesFormat
            if not LineNumbers then
                return
            end
            local LinesCount = self:CountLines()
            Lines.Text = ""
            for Line = 1, LinesCount do
                local Text = Format:format(Line)
                local End = Line ~= LinesCount and "\n" or ""
                Lines.Text ..= `{Text}{End}`
            end
            local LinesWidth = Lines.AbsoluteSize.X
            Source.Size = UDim2.new(1, -LinesWidth, 0, 0)
            return self
        end
        function Config:CheckLineCount()
            local MaxLines = Config.MaxLines
            if not MaxLines then
                return
            end
            local Text = Source.Text
            local Lines = Text:split("\n")
            if #Lines > MaxLines then
                local Line = `{Lines[1]}\\n`
                local Cropped = Text:sub(#Line)
                self:SetValue(Cropped)
            end
            return self
        end
        function Config:UpdateScroll()
            local CanvasSize = Object.AbsoluteCanvasSize
            Object.CanvasPosition = Vector2.new(0, CanvasSize.Y)
            return self
        end
        function Config:SetValue(Text)
            if not self.Enabled then
                return
            end
            Source.Text = tostring(Text)
            self:Update()
            return self
        end
        function Config:GetValue()
            return Source.Text
        end
        function Config:Clear()
            Source.Text = ""
            self:Update()
            return self
        end
        function Config:AppendText(...)
            local Lines = self:CountLines(true)
            local Concated = ReGui:Concat({
                ...
            }, " ")
            if Lines == 0 then
                return self:SetValue(Concated)
            end
            local Value = self:GetValue()
            local NewString = `{Value}\n{Concated}`
            self:SetValue(NewString)
            return self
        end
        function Config:Update()
            local AutoScroll = self.AutoScroll
            self:CheckLineCount()
            self:UpdateLineNumbers()
            if AutoScroll then
                self:UpdateScroll()
            end
        end
        local function Changed()
            local Value = Config:GetValue()
            Config:Update()
            Config:Callback(Value)
        end
        Config:SetValue(Value)
        ReGui:SetProperties(Source, Config)
        ReGui:SetProperties(Source, {
            TextEditable = not ReadOnly,
            Parent = Object,
            PlaceholderText = Placeholder
        })
        self:TagElements({
            [Source] = "ConsoleText",
            [Lines] = "ConsoleLineNumbers"
        })
        Source:GetPropertyChangedSignal("Text"):Connect(Changed)
        return Class, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Table", {
    Base = {
        VerticalAlignment = Enum.VerticalAlignment.Top,
        RowBackground = false,
        RowBgTransparency = 0.87,
        Border = false,
        Spacing = UDim.new(0, 4)
    },
    Create = function(Canvas, Config)
        local WindowClass = Canvas.WindowClass
        local RowTransparency = Config.RowBgTransparency
        local RowBackground = Config.RowBackground
        local Border = Config.Border
        local VerticalAlignment = Config.VerticalAlignment
        local MaxColumns = Config.MaxColumns
        local Spacing = Config.Spacing
        local Object = ReGui:InsertPrefab("Table", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        local RowTemplate = Object.RowTemp
        local RowsCount = 0
        local Rows = {}
        local HasStyling = Border and RowBackground
        function Config:Row(Config)
            Config = Config or {}
            local IsHeader = Config.IsHeader
            local ColumnIndex = 0
            local Columns = {}
            local Row = RowTemplate:Clone()
            ReGui:SetProperties(Row, {
                Name = "Row",
                Visible = true,
                Parent = Object
            })
            local UIListLayout = Row:FindFirstChildOfClass("UIListLayout")
            ReGui:SetProperties(UIListLayout, {
                VerticalAlignment = VerticalAlignment,
                Padding = not HasStyling and Spacing or UDim.new(0, 1)
            })
            if IsHeader then
                Canvas:TagElements({
                    [Row] = "Header"
                })
            else
                RowsCount += 1
            end
            if RowBackground and not IsHeader then
                local Transparency = RowsCount % 2 ~= 1 and RowTransparency or 1
                Row.BackgroundTransparency = Transparency
            end
            local RowClass = {}
            local Class = ReGui:MergeMetatables(RowClass, Row)
            function RowClass:Column(Config)
                Config = Config or {}
                ReGui:CheckConfig(Config, {
                    HorizontalAlign = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Top
                })
                local Column = Row.ColumnTemp:Clone()
                local ListLayout = Column:FindFirstChildOfClass("UIListLayout")
                ReGui:SetProperties(ListLayout, Config)
                local Stroke = Column:FindFirstChildOfClass("UIStroke")
                Stroke.Enabled = Border
                local UIPadding = Column:FindFirstChildOfClass("UIPadding")
                if not HasStyling then
                    UIPadding:Destroy()
                end
                ReGui:SetProperties(Column, {
                    Parent = Row,
                    Visible = true,
                    Name = "Column"
                })
                return ReGui:MakeCanvas({
                    Element = Column,
                    WindowClass = WindowClass,
                    Class = Class
                })
            end
            function RowClass:NextColumn()
                ColumnIndex += 1
                local Index = ColumnIndex % MaxColumns + 1
                local Column = Columns[Index]
                if not Column then
                    Column = self:Column()
                    Columns[Index] = Column
                end
                return Column
            end
            table.insert(Rows, RowClass)
            return Class
        end
        function Config:NextRow()
            return self:Row()
        end
        function Config:HeaderRow()
            return self:Row({
                IsHeader = true
            })
        end
        function Config:ClearRows()
            RowsCount = 0
            for _, Row in next, Object:GetChildren() do
                if not Row:IsA("Frame") then
                    continue
                end
                if Row == RowTemplate then
                    continue
                end
                Row:Destroy()
            end
            return Config
        end
        return Class, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("List", {
    Base = {
        Spacing = 4,
        HorizontalFlex = Enum.UIFlexAlignment.None,
        VerticalFlex = Enum.UIFlexAlignment.None,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        FillDirection = Enum.FillDirection.Horizontal
    },
    Create = function(self, Config)
        local WindowClass = self.WindowClass
        local Spacing = Config.Spacing
        local HorizontalFlex = Config.HorizontalFlex
        local VerticalFlex = Config.VerticalFlex
        local HorizontalAlignment = Config.HorizontalAlignment
        local VerticalAlignment = Config.VerticalAlignment
        local FillDirection = Config.FillDirection
        local Object = ReGui:InsertPrefab("List", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        local ListLayout = Object.UIListLayout
        ReGui:SetProperties(ListLayout, {
            Padding = UDim.new(0, Spacing),
            HorizontalFlex = HorizontalFlex,
            VerticalFlex = VerticalFlex,
            HorizontalAlignment = HorizontalAlignment,
            VerticalAlignment = VerticalAlignment,
            FillDirection = FillDirection
        })
        local Canvas = ReGui:MakeCanvas({
            Element = Object,
            WindowClass = WindowClass,
            Class = Class
        })
        return Canvas, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("CollapsingHeader", {
    Base = {
        Title = "Collapsing Header",
        CollapseIcon = ReGui.Icons.Arrow,
        Collapsed = true,
        Offset = 0,
        NoAutoTag = true,
        NoAutoFlags = true,
        IconPadding = UDim.new(0, 4),
        Activated = EmptyFunction
    },
    Create = function(Canvas, Config)
        local Title = Config.Title
        local Collapsed = Config.Collapsed
        local Style = Config.ElementStyle
        local Offset = Config.Offset
        local TitleProperties = Config.TitleBarProperties
        local OpenOnDoubleClick = Config.OpenOnDoubleClick
        local OpenOnArrow = Config.OpenOnArrow
        local CollapseIcon = Config.CollapseIcon
        local IconPadding = Config.IconPadding
        local Icon = Config.Icon
        local NoArrow = Config.NoArrow
        local Object = ReGui:InsertPrefab("CollapsingHeader", Config)
        local Titlebar = Object.TitleBar
        local Collapse = Titlebar.Collapse
        local IconImage = Titlebar.Icon
        Canvas:ApplyFlags(IconImage, {
            Image = Icon
        })
        local CollapseButton = Collapse.CollapseIcon
        local CollapsePadding = Collapse.UIPadding
        Wrappers:SetPadding(CollapsePadding, IconPadding)
        Canvas:ApplyFlags(CollapseButton, {
            Image = CollapseIcon
        })
        local TitleText = Canvas:Label({
            ColorTag = "CollapsingHeader",
            Parent = Titlebar,
            LayoutOrder = 2
        })
        local Canvas, ContentFrame = Canvas:Indent({
            Class = Config,
            Parent = Object,
            Offset = Offset,
            LayoutOrder = 2,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.None,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 1)
        })
        local function Activated()
            local Callback = Config.Activated
            Callback(Canvas)
        end
        function Config:Remove()
            Object:Destroy()
            table.clear(self)
        end
        function Config:SetArrowVisible(Visible)
            CollapseButton.Visible = Visible
        end
        function Config:SetTitle(Title)
            TitleText.Text = Title
        end
        function Config:SetVisible(Visible)
            Object.Visible = Visible
        end
        function Config:SetIcon(Icon)
            local Visible = Icon and Icon ~= ""
            IconImage.Visible = Visible
            if Visible then
                IconImage.Image = Wrappers:CheckAssetUrl(Icon)
            end
        end
        function Config:SetCollapsed(Collapsed)
            self.Collapsed = Collapsed
            local ContentSize = ReGui:GetContentSize(ContentFrame)
            local Tweeninfo = Canvas:GetThemeKey("AnimationTweenInfo")
            local ClosedSize = UDim2.fromScale(1, 0)
            local OpenSize = ClosedSize + UDim2.fromOffset(0, ContentSize.Y)
            Animation:HeaderCollapse({
                Tweeninfo = Tweeninfo,
                Collapsed = Collapsed,
                Toggle = CollapseButton,
                Resize = ContentFrame,
                Hide = ContentFrame,
                ClosedSize = ClosedSize,
                OpenSize = OpenSize
            })
            return self
        end
        local function Toggle()
            Config:SetCollapsed(not Config.Collapsed)
        end
        if TitleProperties then
            Canvas:ApplyFlags(Titlebar, TitleProperties)
        end
        if not OpenOnArrow then
            ReGui:ConnectMouseEvent(Titlebar, {
                DoubleClick = OpenOnDoubleClick,
                Callback = Toggle
            })
        end
        CollapseButton.Activated:Connect(Toggle)
        Titlebar.Activated:Connect(Activated)
        Config:SetCollapsed(Collapsed)
        Config:SetTitle(Title)
        Config:SetArrowVisible(not NoArrow)
        ReGui:ApplyStyle(Titlebar, Style)
        Canvas:TagElements({
            [Titlebar] = "CollapsingHeader"
        })
        return Canvas, Object
    end
})
ReGui:DefineElement("TreeNode", {
    Base = {
        Offset = 21,
        IconPadding = UDim.new(0, 2),
        TitleBarProperties = {
            Size = UDim2.new(1, 0, 0, 13)
        }
    },
    Create = Elements.CollapsingHeader
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Separator", {
    Base = {
        NoAutoTag = true,
        NoAutoTheme = true
    },
    Create = function(self, Config)
        local Text = Config.Text
        local Object = ReGui:InsertPrefab("SeparatorText", Config)
        self:Label({
            Text = tostring(Text),
            Visible = Text ~= nil,
            Parent = Object,
            LayoutOrder = 2,
            Size = UDim2.new(),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4)
        })
        self:TagElements({
            [Object.Left] = "Separator",
            [Object.Right] = "Separator"
        })
        return Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Canvas", {
    Base = {},
    Create = function(self, Config)
        local WindowClass = self.WindowClass
        local Scroll = Config.Scroll
        local Class = Config.Class or Config
        local ObjectClass = Scroll and "ScrollingCanvas" or "Canvas"
        local Object = ReGui:InsertPrefab(ObjectClass, Config)
        local Canvas = ReGui:MakeCanvas({
            Element = Object,
            WindowClass = WindowClass,
            Class = Class
        })
        return Canvas, Object
    end
})
ReGui:DefineElement("ScrollingCanvas", {
    Base = {
        Scroll = true
    },
    Create = Elements.Canvas
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Region", {
    Base = {
        Scroll = false,
        AutomaticSize = Enum.AutomaticSize.Y
    },
    Create = function(self, Config)
        local WindowClass = self.WindowClass
        local Scroll = Config.Scroll
        local Class = Scroll and "ScrollingCanvas" or "Canvas"
        local Object = ReGui:InsertPrefab(Class, Config)
        local Canvas = ReGui:MakeCanvas({
            Element = Object,
            WindowClass = WindowClass,
            Class = Config
        })
        return Canvas, Object
    end
})
ReGui:DefineElement("Group", {
    Base = {
        Scroll = false,
        AutomaticSize = Enum.AutomaticSize.Y
    },
    Create = function(self, Config)
        local WindowClass = self.WindowClass
        local Object = ReGui:InsertPrefab("Group", Config)
        local Canvas = ReGui:MakeCanvas({
            Element = Object,
            WindowClass = WindowClass,
            Class = Config
        })
        return Canvas, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Indent", {
    Base = {
        Offset = 15,
        PaddingTop = UDim.new(),
        PaddingBottom = UDim.new(),
        PaddingRight = UDim.new()
    },
    Create = function(self, Config)
        local Offset = Config.Offset
        Config.PaddingLeft = UDim.new(0, Offset)
        return self:Canvas(Config)
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("BulletText", {
    Base = {},
    Create = function(self, Config)
        local Rows = Config.Rows
        for _, Text in next, Rows do
            local Object = self:Bullet(Config)
            Object:Label({
                Text = tostring(Text),
                LayoutOrder = 2,
                Size = UDim2.fromOffset(0, 14)
            })
        end
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Bullet", {
    Base = {
        Padding = 3,
        Icon = ReGui.Icons.Dot,
        IconSize = UDim2.fromOffset(5, 5)
    },
    Create = function(self, Config)
        local WindowClass = self.WindowClass
        local Padding = Config.Padding
        local Object = ReGui:InsertPrefab("Bullet", Config)
        local Canvas = ReGui:MakeCanvas({
            Element = Object,
            WindowClass = WindowClass,
            Class = self
        })
        local ListLayout = Object.UIListLayout
        ListLayout.Padding = UDim.new(0, Padding)
        return Canvas, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Row", {
    Base = {
        Spacing = 4,
        Expanded = false,
        HorizontalFlex = Enum.UIFlexAlignment.None,
        VerticalFlex = Enum.UIFlexAlignment.None
    },
    Create = function(self, Config)
        local WindowClass = self.WindowClass
        local Spacing = Config.Spacing
        local Expanded = Config.Expanded
        local HorizontalFlex = Config.HorizontalFlex
        local VerticalFlex = Config.VerticalFlex
        local Object = ReGui:InsertPrefab("Row", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        local UIListLayout = Object:FindFirstChildOfClass("UIListLayout")
        UIListLayout.Padding = UDim.new(0, Spacing)
        UIListLayout.HorizontalFlex = HorizontalFlex
        UIListLayout.VerticalFlex = VerticalFlex
        local Canvas = ReGui:MakeCanvas({
            Element = Object,
            WindowClass = WindowClass,
            Class = Class
        })
        function Config:Expand()
            UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
            return self
        end
        if Expanded then
            Config:Expand()
        end
        return Canvas, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("SliderBase", {
    Base = {
        Format = "%.f",
        Label = "",
        Type = "Slider",
        Callback = EmptyFunction,
        NoGrab = false,
        NoClick = false,
        Minimum = 0,
        Maximum = 100,
        ColorTag = "Frame",
        Disabled = false
    },
    Create = function(Canvas, Config)
        local Value = Config.Value or Config.Minimum
        local Format = Config.Format
        local LabelText = Config.Label
        local NoAnimation = Config.NoAnimation
        local NoGrab = Config.NoGrab
        local NoClick = Config.NoClick
        local Type = Config.Type
        local Disabled = Config.Disabled
        local Object = ReGui:InsertPrefab("Slider")
        local Track = Object.Track
        local Grab = Track.Grab
        local ValueText = Track.ValueText
        local Class = ReGui:MergeMetatables(Config, Object)
        local GrabSize = Grab.AbsoluteSize
        local HoverAnimation = ReGui:SetAnimation(Object, "Inputs")
        local Label = Canvas:Label({
            Parent = Object,
            Text = LabelText,
            Position = UDim2.new(1, 4),
            Size = UDim2.fromScale(0, 1)
        })
        Merge(Config, {
            Grab = Grab,
            Name = LabelText
        })
        if Type == "Slider" then
            Track.Position = UDim2.fromOffset(GrabSize.X / 2, 0)
            Track.Size = UDim2.new(1, -GrabSize.X, 1, 0)
        end
        local Types = {
            ["Slider"] = function(Percentage)
                return {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(Percentage, 0.5)
                }
            end,
            ["Progress"] = function(Percentage)
                return {
                    Size = UDim2.fromScale(Percentage, 1)
                }
            end,
            ["Snap"] = function(Percentage, Value, Minimum, Maximum)
                local X = (math.round(Value) - Minimum) / Maximum
                return {
                    Size = UDim2.fromScale(1 / Maximum, 1),
                    Position = UDim2.fromScale(X, 0.5)
                }
            end
        }
        local function Callback(...)
            local func = Config.Callback
            return func(Class, ...)
        end
        function Config:SetDisabled(Disabled)
            self.Disabled = Disabled
            Object.Interactable = not Disabled
            Canvas:SetColorTags({
                [Label] = Disabled and "LabelDisabled" or "Label"
            }, true)
            return self
        end
        function Config:SetValueText(Text)
            ValueText.Text = tostring(Text)
        end
        function Config:SetValue(Value, IsPercentage)
            local Tweeninfo = Canvas:GetThemeKey("AnimationTweenInfo")
            local Minimum = Config.Minimum
            local Maximum = Config.Maximum
            local Percentage = Value
            local Difference = Maximum - Minimum
            if not IsPercentage then
                Percentage = (Value - Minimum) / Difference
            else
                Value = Minimum + (Difference * Percentage)
            end
            Percentage = math.clamp(Percentage, 0, 1)
            local Props = Types[Type](Percentage, Value, Minimum, Maximum)
            Animation:Tween({
                Object = Grab,
                Tweeninfo = Tweeninfo,
                NoAnimation = NoAnimation,
                EndProperties = Props
            })
            self.Value = Value
            self:SetValueText(Format:format(Value, Maximum))
            Callback(Value)
            return self
        end
        local function SetFocused(Focused)
            Canvas:SetColorTags({
                [Object] = Focused and "FrameActive" or "Frame"
            }, true)
            Canvas:SetElementFocused(Object, {
                Focused = Focused,
                Animation = HoverAnimation
            })
        end
        local function CanDrag()
            if Config.Disabled then
                return
            end
            if Config.ReadOnly then
                return
            end
            return true
        end
        local function DragMovement(InputPosition)
            if not CanDrag() then
                return
            end
            local TrackLeft = Track.AbsolutePosition.X
            local TrackWidth = Track.AbsoluteSize.X
            local MouseX = InputPosition.X
            local RelativeX = MouseX - TrackLeft
            local Percentage = math.clamp(RelativeX / TrackWidth, 0, 1)
            Config:SetValue(Percentage, true)
        end
        local function DragBegan(...)
            if not CanDrag() then
                return
            end
            SetFocused(true)
            if not NoClick then
                DragMovement(...)
            end
        end
        local function DragEnded()
            SetFocused(false)
        end
        Grab.Visible = not NoGrab
        Config:SetValue(Value)
        Config:SetDisabled(Disabled)
        Canvas:TagElements({
            [ValueText] = "Label",
            [Grab] = "SliderGrab"
        })
        ReGui:ConnectDrag(Track, {
            DragStart = DragBegan,
            DragMovement = DragMovement,
            DragEnd = DragEnded
        })
        return Class, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("SliderEnum", {
    Base = {
        Items = {},
        Label = "Slider Enum",
        Type = "Snap",
        Minimum = 1,
        Maximum = 10,
        Value = 1,
        Callback = EmptyFunction,
        ColorTag = "Frame"
    },
    Create = function(self, Config)
        local Callback = Config.Callback
        local Value = Config.Value
        local function Calculate(self, Value)
            Value = math.round(Value)
            local Items = self.Items
            self.Maximum = #Items
            return Items[Value]
        end
        Config.Callback = function(self, Index)
            local Value = Calculate(self, Index)
            self:SetValueText(Value)
            Config.Value = Value
            return Callback(self, Value)
        end
        Calculate(Config, Value)
        return self:SliderBase(Config)
    end
})
ReGui:DefineElement("SliderInt", {
    Base = {
        Label = "Slider Int",
        ColorTag = "Frame"
    },
    Create = Elements.SliderBase
})
ReGui:DefineElement("SliderFloat", {
    Base = {
        Label = "Slider Float",
        Format = "%.3f",
        ColorTag = "Frame"
    },
    Create = Elements.SliderBase
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("DragInt", {
    Base = {
        Format = "%.f",
        Label = "Drag Int",
        Callback = EmptyFunction,
        Minimum = 0,
        Maximum = 100,
        ColorTag = "Frame",
        Disabled = false
    },
    Create = function(Canvas, Config)
        local Value = Config.Value or Config.Minimum
        local Format = Config.Format
        local LabelText = Config.Label
        local Disabled = Config.Disabled
        local Object = ReGui:InsertPrefab("Slider")
        local Class = ReGui:MergeMetatables(Config, Object)
        local Track = Object.Track
        local ValueText = Track.ValueText
        local Grab = Track.Grab
        Grab.Visible = false
        local Label = Canvas:Label({
            Parent = Object,
            Text = LabelText,
            Position = UDim2.new(1, 7),
            Size = UDim2.fromScale(0, 1)
        })
        local InputBeganPosition = nil
        local Percentage = 0
        local BeganPercentage = 0
        local HoverAnimation = ReGui:SetAnimation(Object, "Inputs")
        local function Callback(...)
            local Func = Config.Callback
            return Func(Class, ...)
        end
        function Config:SetValue(Value, IsPercentage)
            local Minimum = self.Minimum
            local Maximum = self.Maximum
            local Difference = Maximum - Minimum
            if not IsPercentage then
                Percentage = ((Value - Minimum) / Difference) * 100
            else
                Value = Minimum + (Difference * (Percentage / 100))
            end
            Value = math.clamp(Value, Minimum, Maximum)
            self.Value = Value
            ValueText.Text = Format:format(Value, Maximum)
            Callback(Value)
            return self
        end
        function Config:SetDisabled(Disabled)
            self.Disabled = Disabled
            Canvas:SetColorTags({
                [Label] = Disabled and "LabelDisabled" or "Label"
            }, true)
            return self
        end
        local function SetFocused(Focused)
            Canvas:SetColorTags({
                [Object] = Focused and "FrameActive" or "Frame"
            }, true)
            Canvas:SetElementFocused(Object, {
                Focused = Focused,
                Animation = HoverAnimation
            })
        end
        local function CanDrag()
            if Config.Disabled then
                return
            end
            if Config.ReadOnly then
                return
            end
            return true
        end
        local function DragStart(InputPosition)
            if not CanDrag() then
                return
            end
            SetFocused(true)
            InputBeganPosition = InputPosition
            BeganPercentage = Percentage
        end
        local function DragMovement(InputPosition)
            if not CanDrag() then
                return
            end
            local Delta = InputPosition.X - InputBeganPosition.X
            local New = BeganPercentage + (Delta / 2)
            Percentage = math.clamp(New, 0, 100)
            Config:SetValue(Percentage, true)
        end
        local function DragEnded()
            SetFocused(false)
        end
        Config:SetValue(Value)
        Config:SetDisabled(Disabled)
        ReGui:ConnectDrag(Track, {
            DragStart = DragStart,
            DragEnd = DragEnded,
            DragMovement = DragMovement
        })
        Canvas:TagElements({
            [ValueText] = "Label"
        })
        return Class, Object
    end
})
ReGui:DefineElement("DragFloat", {
    Base = {
        Format = "%.3f",
        Label = "Drag Float",
        ColorTag = "Frame"
    },
    Create = Elements.DragInt
})
ReGui:DefineElement("MultiElement", {
    Base = {
        Callback = EmptyFunction,
        Label = "",
        Disabled = false,
        BaseInputConfig = {},
        InputConfigs = {},
        Value = {},
        Minimum = {},
        Maximum = {},
        MultiCallback = EmptyFunction
    },
    Create = function(Canvas, Config)
        local LabelText = Config.Label
        local BaseInputConfig = Config.BaseInputConfig
        local InputConfigs = Config.InputConfigs
        local InputType = Config.InputType
        local Disabled = Config.Disabled
        local Value = Config.Value
        local Minimum = Config.Minimum
        local Maximum = Config.Maximum
        assert(InputType, "No input type provided for MultiElement")
        local ContainerRow, Object = Canvas:Row({
            Spacing = 4
        })
        local Row = ContainerRow:Row({
            Size = UDim2.fromScale(0.65, 0),
            Expanded = true
        })
        local Label = ContainerRow:Label({
            Size = UDim2.fromScale(0.35, 0),
            LayoutOrder = 2,
            Text = LabelText
        })
        local Class = ReGui:MergeMetatables(Config, ContainerRow)
        local Inputs = {}
        local _CallbackEnabled = false
        local function GetValue()
            local Value = {}
            for Index, Input in Inputs do
                Value[Index] = Input:GetValue()
            end
            Config.Value = Value
            return Value
        end
        local function Callback(...)
            local Callback = Config.MultiCallback
            Callback(Class, ...)
        end
        local function InputChanged()
            if #Inputs ~= #InputConfigs then
                return
            end
            if not _CallbackEnabled then
                return
            end
            local Values = GetValue()
            Callback(Values)
        end
        function Config:SetDisabled(Disabled)
            self.Disabled = Disabled
            Canvas:SetColorTags({
                [Label] = Disabled and "LabelDisabled" or "Label"
            }, true)
            for _, Input in Inputs do
                Input:SetDisabled(Disabled)
            end
        end
        function Config:SetValue(Values)
            _CallbackEnabled = false
            for Index, Value in Values do
                local Input = Inputs[Index]
                assert(Input, `No input object for index: {Index}`)
                Input:SetValue(Value)
            end
            _CallbackEnabled = true
            Callback(Values)
        end
        BaseInputConfig = Copy(BaseInputConfig, {
            Size = UDim2.new(1, 0, 0, 19),
            Label = "",
            Callback = InputChanged
        })
        for Index, Overwrites in InputConfigs do
            local Flags = Copy(BaseInputConfig, Overwrites)
            ReGui:CheckConfig(Flags, {
                Minimum = Minimum[Index],
                Maximum = Maximum[Index]
            })
            local Input = Row[InputType](Row, Flags)
            table.insert(Inputs, Input)
        end
        Merge(Config, {
            Row = Row,
            Inputs = Inputs
        })
        _CallbackEnabled = true
        Config:SetDisabled(Disabled)
        Config:SetValue(Value)
        return Class, Object
    end
})
local function GenerateMultiInput(Name, Class, InputCount, Extra)
    ReGui:DefineElement(Name, {
        Base = {
            Label = Name,
            Callback = EmptyFunction,
            InputType = Class,
            InputConfigs = table.create(InputCount, {}),
            BaseInputConfig = {}
        },
        Create = function(self, Config)
            local BaseInputConfig = Config.BaseInputConfig
            local Object = nil
            if Extra then
                Merge(BaseInputConfig, Extra)
            end
            ReGui:CheckConfig(BaseInputConfig, {
                ReadOnly = Config.ReadOnly,
                Format = Config.Format
            })
            Config.MultiCallback = function(...)
                local Callback = Config.Callback
                Callback(...)
            end
            return self:MultiElement(Config)
        end
    })
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
local function GenerateColor3Input(Name, InputType)
    ReGui:DefineElement(Name, {
        Base = {
            Label = Name,
            Callback = EmptyFunction,
            Value = ReGui.Accent.Light,
            Disabled = false,
            Minimum = {
                0,
                0,
                0
            },
            Maximum = {
                255,
                255,
                255,
                100
            },
            BaseInputConfig = {},
            InputConfigs = {
                [1] = {
                    Format = "R: %.f"
                },
                [2] = {
                    Format = "G: %.f"
                },
                [3] = {
                    Format = "B: %.f"
                }
            }
        },
        Create = function(self, Config)
            local Value = Config.Value
            local InputConfig = Copy(Config, {
                Value = {
                    1,
                    1,
                    1
                },
                Callback = function(self, ...)
                    if Config.ValueChanged then
                        Config:ValueChanged(...)
                    end
                end
            })
            local Element, Object = self[InputType](self, InputConfig)
            local Class = ReGui:MergeMetatables(Config, Element)
            local Row = Element.Row
            local Preview = Row:Button({
                BackgroundTransparency = 0,
                Size = UDim2.fromOffset(19, 19),
                UiPadding = 0,
                Text = "",
                Ratio = 1,
                ColorTag = "",
                ElementStyle = ""
            })
            local function Callback(...)
                local func = Config.Callback
                return func(Class, ...)
            end
            local function SetPreview(Color)
                Preview.BackgroundColor3 = Color
                Callback(Color)
            end
            function Config:ValueChanged(Value)
                local R, G, B = Value[1], Value[2], Value[3]
                local Color = Color3.fromRGB(R, G, B)
                self.Value = Color
                SetPreview(Color)
            end
            function Config:SetValue(Color)
                self.Value = Color
                SetPreview(Color)
                Element:SetValue({
                    math.round(Color.R * 255),
                    math.round(Color.G * 255),
                    math.round(Color.B * 255)
                })
            end
            Config:SetValue(Value)
            return Class, Object
        end
    })
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
local function GenerateCFrameInput(Name, InputType)
    ReGui:DefineElement(Name, {
        Base = {
            Label = Name,
            Callback = EmptyFunction,
            Disabled = false,
            Value = CFrame.new(10, 10, 10),
            Minimum = CFrame.new(0, 0, 0),
            Maximum = CFrame.new(100, 100, 100),
            BaseInputConfig = {},
            InputConfigs = {
                [1] = {
                    Format = "X: %.f"
                },
                [2] = {
                    Format = "Y: %.f"
                },
                [3] = {
                    Format = "Z: %.f"
                }
            }
        },
        Create = function(self, Config)
            local Value = Config.Value
            local Maximum = Config.Maximum
            local Minimum = Config.Minimum
            local InputConfig = Copy(Config, {
                Maximum = {
                    Maximum.X,
                    Maximum.Y,
                    Maximum.Z
                },
                Minimum = {
                    Minimum.X,
                    Minimum.Y,
                    Minimum.Z
                },
                Value = {
                    Value.X,
                    Value.Y,
                    Value.Z
                },
                Callback = function(self, ...)
                    if Config.ValueChanged then
                        Config:ValueChanged(...)
                    end
                end
            })
            local Element, Object = self[InputType](self, InputConfig)
            local Class = ReGui:MergeMetatables(Config, Element)
            local function Callback(...)
                local func = Config.Callback
                return func(Class, ...)
            end
            function Config:ValueChanged(Values)
                local X, Y, Z = Values[1], Values[2], Values[3]
                local Value = CFrame.new(X, Y, Z)
                self.Value = Value
                Callback(Value)
            end
            function Config:SetValue(Value)
                self.Value = Value
                Element:SetValue({
                    math.round(Value.X),
                    math.round(Value.Y),
                    math.round(Value.Z)
                })
            end
            Config:SetValue(Value)
            return Class, Object
        end
    })
end
ReGui:DefineElement("SliderProgress", {
    Base = {
        Label = "Slider Progress",
        Type = "Progress",
        ColorTag = "Frame"
    },
    Create = Elements.SliderBase
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("ProgressBar", {
    Base = {
        Label = "Progress Bar",
        Type = "Progress",
        ReadOnly = true,
        MinValue = 0,
        MaxValue = 100,
        Format = "% i%%",
        Interactable = false,
        ColorTag = "Frame"
    },
    Create = function(self, Config)
        function Config:SetPercentage(Value)
            Config:SetValue(Value)
        end
        local Slider, Object = self:SliderBase(Config)
        local Grab = Slider.Grab
        self:TagElements({
            [Grab] = {
                BackgroundColor3 = "ProgressBar"
            }
        })
        return Slider, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Combo", {
    Base = {
        Value = "",
        Placeholder = "",
        Callback = EmptyFunction,
        Items = {},
        Disabled = false,
        WidthFitPreview = false,
        Label = "Combo"
    },
    Create = function(Canvas, Config)
        local Placeholder = Config.Placeholder
        local NoAnimation = Config.NoAnimation
        local Selected = Config.Selected
        local LabelText = Config.Label
        local Disabled = Config.Disabled
        local WidthFitPreview = Config.WidthFitPreview
        local Object = ReGui:InsertPrefab("Combo", Config)
        local Class = ReGui:MergeMetatables(Config, Object)
        local Combo = Object.Combo
        local Dropdown = nil
        local ValueText = Canvas:Label({
            Text = tostring(Placeholder),
            Parent = Combo,
            Name = "ValueText"
        })
        local ArrowButton = Canvas:ArrowButton({
            Parent = Combo,
            Interactable = false,
            Size = UDim2.fromOffset(19, 19),
            LayoutOrder = 2
        })
        local Label = Canvas:Label({
            Text = LabelText,
            Parent = Object,
            LayoutOrder = 2
        })
        if WidthFitPreview then
            ReGui:SetProperties(Object, {
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = UDim2.new(0, 0, 0, 0)
            })
            ReGui:SetProperties(Combo, {
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = UDim2.fromScale(0, 1)
            })
        end
        local function Callback(Value, ...)
            Config:SetOpen(false)
            return Config.Callback(Class, Value, ...)
        end
        local function SetAnimationState(Open, NoAnimation)
            local Tweeninfo = Canvas:GetThemeKey("AnimationTweenInfo")
            Object.Interactable = not Open
            Animation:HeaderCollapseToggle({
                Tweeninfo = Tweeninfo,
                NoAnimation = NoAnimation,
                Collapsed = not Open,
                Toggle = ArrowButton.Icon
            })
        end
        local function GetItems()
            local GetItems = Config.GetItems
            local Items = Config.Items
            if GetItems then
                return GetItems()
            end
            return Items
        end
        function Config:SetValueText(Value)
            ValueText.Text = tostring(Value)
        end
        function Config:ClosePopup()
            if not Dropdown then
                return
            end
            Dropdown:ClosePopup(true)
        end
        function Config:SetDisabled(Disabled)
            self.Disabled = Disabled
            Object.Interactable = not Disabled
            Canvas:SetColorTags({
                [Label] = Disabled and "LabelDisabled" or "Label"
            }, true)
            return self
        end
        function Config:SetValue(Selected)
            local Items = GetItems()
            local DictValue = Items[Selected]
            local Value = DictValue or Selected
            self.Selected = Selected
            self.Value = Value
            self:ClosePopup()
            if typeof(Selected) == "number" then
                self:SetValueText(Value)
            else
                self:SetValueText(Selected)
            end
            Callback(Selected, Value)
            return self
        end
        function Config:SetOpen(Open)
            local Selected = self.Selected
            self.Open = Open
            SetAnimationState(Open, NoAnimation)
            if not Open then
                self:ClosePopup()
                return
            end
            Dropdown = Canvas:Dropdown({
                RelativeTo = Combo,
                Items = GetItems(),
                Selected = Selected,
                OnSelected = function(...)
                    Config:SetValue(...)
                end,
                OnClosed = function()
                    self:SetOpen(false)
                end
            })
            return self
        end
        local function ToggleOpen()
            local IsOpen = Config.Open
            Config:SetOpen(not IsOpen)
        end
        Combo.Activated:Connect(ToggleOpen)
        SetAnimationState(false, true)
        Config:SetDisabled(Disabled)
        if Selected then
            Config:SetValue(Selected)
        end
        ReGui:SetAnimation(Combo, "Inputs")
        Canvas:TagElements({
            [Combo] = "Frame"
        })
        return Class, Object
    end
})
local WindowClass = {
    TileBarConfig = {
        Close = {
            Image = ReGui.Icons.Close,
            IconPadding = UDim.new(0, 3)
        },
        Collapse = {
            Image = ReGui.Icons.Arrow,
            IconPadding = UDim.new(0, 3)
        }
    },
    CloseCallback = EmptyFunction,
    Collapsible = true,
    Open = true,
    Focused = false
}
function WindowClass:Tween(Data)
    ReGui:CheckConfig(Data, {
        Tweeninfo = self:GetThemeKey("AnimationTweenInfo")
    })
    return Animation:Tween(Data)
end
function WindowClass:TagElements(Objects)
    local Elements = self.TagsList
    local Theme = self.Theme
    ReGui:MultiUpdateColors({
        Theme = Theme,
        TagsList = Elements,
        Objects = Objects
    })
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
function WindowClass:MakeTitleBarCanvas()
    local TitleBar = self.TitleBar
    local Canvas = ReGui:MakeCanvas({
        WindowClass = self,
        Element = TitleBar
    })
    self.TitleBarCanvas = Canvas
    return Canvas
end
function WindowClass:AddDefaultTitleButtons()
    local Config = self.TileBarConfig
    local Toggle = Config.Collapse
    local Close = Config.Close
    local Canvas = self.TitleBarCanvas
    if not Canvas then
        Canvas = self:MakeTitleBarCanvas()
    end
    ReGui:CheckConfig(self, {
        Toggle = Canvas:RadioButton({
            Icon = Toggle.Image,
            IconPadding = Toggle.IconPadding,
            LayoutOrder = 1,
            Ratio = 1,
            Size = UDim2.new(0, 0),
            Callback = function()
                self:ToggleCollapsed()
            end
        }),
        CloseButton = Canvas:RadioButton({
            Icon = Close.Image,
            IconPadding = Close.IconPadding,
            LayoutOrder = 3,
            Ratio = 1,
            Size = UDim2.new(0, 0),
            Callback = function()
                self:SetVisible(false)
            end
        }),
        TitleLabel = Canvas:Label({
            ColorTag = "Title",
            LayoutOrder = 2,
            Size = UDim2.new(1, 0),
            Active = false,
            Fill = true,
            ClipsDescendants = true,
            AutomaticSize = Enum.AutomaticSize.XY
        })
    })
    self:TagElements({
        [self.TitleLabel] = "WindowTitle"
    })
end
function WindowClass:Close()
    local Callback = self.CloseCallback
    if Callback then
        local ShouldClose = Callback(self)
        if ShouldClose == false then
            return
        end
    end
    self:Remove()
    self.IsClosed = true
end
function WindowClass:SetVisible(Visible)
    local Window = self.WindowFrame
    local NoFocusOnAppearing = self.NoFocusOnAppearing
    self.Visible = Visible
    Window.Visible = Visible
    if Visible and not NoFocusOnAppearing then
        ReGui:SetFocusedWindow(self)
    end
    return self
end
function WindowClass:ToggleVisibility(Visible)
    local IsVisible = self.Visible
    self:SetVisible(not IsVisible)
end
function WindowClass:GetWindowSize()
    return self.WindowFrame.AbsoluteSize
end
function WindowClass:GetTitleBarSizeY()
    local TitleBar = self.TitleBar
    return TitleBar.Visible and TitleBar.AbsoluteSize.Y or 0
end
function WindowClass:SetTitle(Text)
    self.TitleLabel.Text = tostring(Text)
    return self
end
function WindowClass:SetPosition(Position)
    self.WindowFrame.Position = Position
    return self
end
function WindowClass:SetSize(Size, NoAnimation)
    local Window = self.WindowFrame
    if typeof(Size) == "Vector2" then
        Size = UDim2.fromOffset(Size.X, Size.Y)
    end
    Window.Size = Size
    self.Size = Size
    return self
end
function WindowClass:SetCanvasInteractable(Interactable)
    local Body = self.Body
    Body.Interactable = Interactable
end
function WindowClass:Center()
    local Size = self:GetWindowSize() / 2
    local Position = UDim2.new(0.5, -Size.X, 0.5, -Size.Y)
    self:SetPosition(Position)
    return self
end
function WindowClass:LoadStylesIntoElement(Data)
    local Flags = Data.Flags
    local Object = Data.Object
    local Canvas = Data.Canvas
    local TagFunctions = {
        ["FrameRounding"] = function()
            if Flags.CornerRadius then
                return
            end
            if not Canvas then
                return
            end
            local UICorner = Object:FindFirstChild("FrameRounding", true)
            if not UICorner then
                return
            end
            Canvas:TagElements({
                [UICorner] = "FrameRounding"
            })
        end
    }
    for Tag, Func in TagFunctions do
        local Value = self:GetThemeKey(Tag)
        if Value == nil then
            continue
        end
        task.spawn(Func, Value)
    end
end
function WindowClass:SetTheme(ThemeName)
    local Themes = ReGui.ThemeConfigs
    local Elements = self.TagsList
    local WindowState = self.WindowState
    ThemeName = ThemeName or self.Theme
    assert(Themes[ThemeName], `{ThemeName} is not a valid theme!`)
    self.Theme = ThemeName
    ReGui:MultiUpdateColors({
        Animate = false,
        Theme = ThemeName,
        Objects = Elements
    })
    self:SetFocusedColors(WindowState)
    return self
end
function WindowClass:SetFocusedColors(State)
    local WindowFrame = self.WindowFrame
    local TitleBar = self.TitleBar
    local Theme = self.Theme
    local TitleLabel = self.TitleLabel
    local Tweeninfo = self:GetThemeKey("AnimationTweenInfo")
    local Border = WindowFrame:FindFirstChildOfClass("UIStroke")
    local Tags = {
        Focused = {
            [Border] = "BorderActive",
            [TitleBar] = "TitleBarBgActive",
            [TitleLabel] = {
                TextColor3 = "TitleActive"
            }
        },
        UnFocused = {
            [Border] = "Border",
            [TitleBar] = "TitleBarBg",
            [TitleLabel] = {
                TextColor3 = "Title"
            }
        },
        Collapsed = {
            [Border] = "Border",
            [TitleBar] = "TitleBarBgCollapsed",
            [TitleLabel] = {
                TextColor3 = "Title"
            }
        }
    }
    ReGui:MultiUpdateColors({
        Tweeninfo = Tweeninfo,
        Animate = true,
        Objects = Tags[State],
        Theme = Theme
    })
end
function WindowClass:SetFocused(Focused)
    Focused = Focused == nil and true or Focused
    local Collapsed = self.Collapsed
    local CurrentState = self.WindowState
    if Focused then
        ReGui:SetFocusedWindow(self)
    end
    local NewState = Collapsed and "Collapsed" or Focused and "Focused" or "UnFocused"
    if NewState == CurrentState then
        return
    end
    self.Focused = Focused
    self.WindowState = NewState
    self:SetFocusedColors(NewState)
end
function WindowClass:GetThemeKey(Key)
    return ReGui:GetThemeKey(self.Theme, Key)
end
function WindowClass:SetCollapsible(Collapsible)
    self.Collapsible = Collapsible
    return self
end
function WindowClass:ToggleCollapsed(NoCheck)
    local Collapsed = self.Collapsed
    local Collapsible = self.Collapsible
    if not NoCheck and not Collapsible then
        return self
    end
    self:SetCollapsed(not Collapsed)
    return self
end
function WindowClass:SetCollapsed(Collapsed, NoAnimation)
    local Window = self.WindowFrame
    local Body = self.Body
    local Toggle = self.Toggle
    local ResizeGrab = self.ResizeGrab
    local OpenSize = self.Size
    local AutoSize = self.AutoSize
    local Tweeninfo = self:GetThemeKey("AnimationTweenInfo")
    local WindowSize = self:GetWindowSize()
    local TitleBarSizeY = self:GetTitleBarSizeY()
    local ToggleIcon = Toggle.Icon
    local ClosedSize = UDim2.fromOffset(WindowSize.X, TitleBarSizeY)
    self.Collapsed = Collapsed
    self:SetCollapsible(false)
    self:SetFocused(not Collapsed)
    Animation:HeaderCollapse({
        Tweeninfo = Tweeninfo,
        NoAnimation = NoAnimation,
        Collapsed = Collapsed,
        Toggle = ToggleIcon,
        Resize = Window,
        NoAutomaticSize = not AutoSize,
        Hide = Body,
        ClosedSize = ClosedSize,
        OpenSize = OpenSize,
        Completed = function()
            self:SetCollapsible(true)
        end
    })
    self:Tween({
        Object = ResizeGrab,
        NoAnimation = NoAnimation,
        EndProperties = {
            TextTransparency = Collapsed and 1 or 0.6,
            Interactable = not Collapsed
        }
    })
    return self
end
function WindowClass:UpdateConfig(Config)
    local Flags = {
        NoTitleBar = function(Value)
            local Object = self.TitleBar
            Object.Visible = not Value
        end,
        NoClose = function(Value)
            local Object = self.CloseButton
            Object.Visible = not Value
        end,
        NoCollapse = function(Value)
            local Object = self.Toggle
            Object.Visible = not Value
        end,
        NoTabsBar = function(Value)
            local Object = self.WindowTabSelector
            if not Object then
                return
            end
            local TabsBar = Object.TabsBar
            TabsBar.Visible = not Value
        end,
        NoScrollBar = function(Value)
            local ScrollBarThickness = Value and 0 or 9
            local NoScroll = self.NoScroll
            local TabSelector = self.WindowTabSelector
            local ContentCanvas = self.ContentCanvas
            if TabSelector then
                TabSelector.Body.ScrollBarThickness = ScrollBarThickness
            end
            if not NoScroll then
                ContentCanvas.ScrollBarThickness = ScrollBarThickness
            end
        end,
        NoScrolling = function(Value)
            local NoScroll = self.NoScroll
            local TabSelector = self.WindowTabSelector
            local ContentCanvas = self.ContentCanvas
            if TabSelector then
                TabSelector.Body.ScrollingEnabled = not Value
            end
            if not NoScroll then
                ContentCanvas.ScrollingEnabled = not Value
            end
        end,
        NoMove = function(Value)
            local Drag = self.DragConnection
            Drag:SetEnabled(not Value)
        end,
        NoResize = function(Value)
            local Drag = self.ResizeConnection
            Drag:SetEnabled(not Value)
        end,
        NoBackground = function(Value)
            local Transparency = self:GetThemeKey("WindowBgTransparency")
            local Frame = self.CanvasFrame
            Frame.BackgroundTransparency = Value and 1 or Transparency
        end
    }
    Merge(self, Config)
    for Key, Value in Config do
        local Func = Flags[Key]
        if Func then
            Func(Value)
        end
    end
    return self
end
function WindowClass:Remove()
    local Window = self.WindowFrame
    local WindowClass = self.WindowClass
    local Windows = ReGui.Windows
    local Index = table.find(Windows, WindowClass)
    if Index then
        table.remove(Windows, Index)
    end
    Window:Destroy()
end
function WindowClass:MenuBar(Config, ...)
    local ContentCanvas = self.ContentCanvas
    local ContentFrame = self.ContentFrame
    Config = Config or {}
    Merge(Config, {
        Parent = ContentFrame,
        Layout = -1
    })
    return ContentCanvas:MenuBar(Config, ...)
end
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("Window", {
    Export = true,
    Base = {
        Theme = "DarkTheme",
        NoSelect = false,
        NoTabs = true,
        NoScroll = false,
        Collapsed = false,
        Visible = true,
        AutoSize = false,
        MinimumSize = Vector2.new(160, 90),
        OpenOnDoubleClick = true,
        NoAutoTheme = true,
        NoWindowRegistor = false,
        NoBringToFrontOnFocus = false,
        IsDragging = false,
        IsDocking = false,
        DockEnabled = true,
        DockPadding = 6,
        DockThreshold = 28,
        DockAnimationTime = 0.18,
        DockToEdges = true,
        DockToWindows = true,
        SnapPreview = false
    },
    Create = function(self, Config)
        ReGui:CheckImportState()
        local Windows = ReGui.Windows
        local WindowsContainer = ReGui.Container.Windows
        ReGui:CheckConfig(Config, {
            Parent = WindowsContainer,
            Title = ReGui.DefaultTitle
        })
        local NoTitleButtons = Config.NoDefaultTitleBarButtons
        local Collapsed = Config.Collapsed
        local MinimumSize = Config.MinimumSize
        local Title = Config.Title
        local NoTabs = Config.NoTabs
        local NoScroll = Config.NoScroll
        local Theme = Config.Theme
        local AutomaticSize = Config.AutomaticSize
        local NoWindowRegistor = Config.NoWindowRegistor
        local AutoSelectNewTabs = Config.AutoSelectNewTabs
        local DockEnabled = Config.DockEnabled
        local DockPadding = Config.DockPadding
        local DockThreshold = Config.DockThreshold
        local DockAnimationTime = Config.DockAnimationTime
        local DockToEdges = Config.DockToEdges
        local DockToWindows = Config.DockToWindows
        local _SelectDisabled = Config.Parent ~= WindowsContainer
        local DockState = {
            Active = false,
            Target = nil
        }
        local function getDockTarget(pos, size)
            local viewport = workspace.CurrentCamera.ViewportSize
            local pad = DockPadding or 6
            local threshold = DockThreshold or 28
            local best = nil
            local bestDist = math.huge
            if DockToEdges then
                local left = Vector2.new(pad, pos.Y)
                local right = Vector2.new(viewport.X - size.X - pad, pos.Y)
                local top = Vector2.new(pos.X, pad)
                local bottom = Vector2.new(pos.X, viewport.Y - size.Y - pad)
                local candidates = {
                    left,
                    right,
                    top,
                    bottom
                }
                for _, c in ipairs(candidates) do
                    local d = (pos - c).Magnitude
                    if d < threshold and d < bestDist then
                        bestDist = d
                        best = c
                    end
                end
            end
            return best
        end
        local CanvasConfig = {
            Scroll = not NoScroll,
            Fill = not AutomaticSize and true or nil,
            UiPadding = UDim.new(0, NoTabs and 8 or 0),
            AutoSelectNewTabs = AutoSelectNewTabs
        }
        if AutomaticSize then
            Merge(CanvasConfig, {
                AutomaticSize = AutomaticSize,
                Size = UDim2.new(1, 0)
            })
        end
        local Window = ReGui:InsertPrefab("Window", Config)
        local ContentFrame = Window.Content
        local TitleBar = ContentFrame.TitleBar
        local Class = Wrappers:NewClass(WindowClass)
        local BaseCanvas = ReGui:MakeCanvas({
            Element = ContentFrame,
            WindowClass = Class,
            Class = Class
        })
        local Canvas, Body, WindowClass = nil, nil, nil
        local WindowCanvas, CanvasFrame = BaseCanvas:Canvas(Copy(CanvasConfig, {
            Parent = ContentFrame,
            CornerRadius = UDim.new(0, 0)
        }))
        local ResizeConnection = ReGui:MakeResizable({
            MinimumSize = MinimumSize,
            Resize = Window,
            OnUpdate = function(Size)
                Class:SetSize(Size, true)
            end
        })
        Merge(Class, Config)
        Merge(Class, {
            WindowFrame = Window,
            ContentFrame = ContentFrame,
            CanvasFrame = CanvasFrame,
            ResizeGrab = ResizeConnection.Grab,
            TitleBar = TitleBar,
            Elements = Elements,
            TagsList = {},
            _SelectDisabled = _SelectDisabled,
            ResizeConnection = ResizeConnection,
            HoverConnection = ReGui:DetectHover(ContentFrame),
            DragConnection = ReGui:MakeDraggable({
                Grab = ContentFrame,
                Move = Window,
                SetPosition = function(self, Position)
                    local Tweeninfo = Canvas:GetThemeKey("AnimationTweenInfo")
                    Animation:Tween({
                        Tweeninfo = Tweeninfo,
                        Object = self.Move,
                        EndProperties = {
                            Position = Position
                        }
                    })
                end,
                OnDragStateChange = function(IsDragging)
                    Class.IsDragging = IsDragging
                    CanvasFrame.Interactable = not IsDragging
                    if IsDragging then
                        ReGui:SetFocusedWindow(WindowClass)
                        ReGui:SetWindowFocusesEnabled(false)
                    else
                        ReGui:SetWindowFocusesEnabled(true)
                        if DockEnabled then
                            local absPos = Window.AbsolutePosition
                            local absSize = Window.AbsoluteSize
                            local target = getDockTarget(absPos, absSize)
                            if target then
                                local tweenInfo = TweenInfo.new(DockAnimationTime or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                                TweenService:Create(Window, tweenInfo, {
                                    Position = UDim2.fromOffset(target.X, target.Y)
                                }):Play()
                                DockState.Active = true
                                DockState.Target = target
                            else
                                DockState.Active = false
                                DockState.Target = nil
                            end
                        end
                    end
                end
            })
        })
        if NoTabs then
            Canvas, Body = WindowCanvas, CanvasFrame
        else
            Canvas, Body = WindowCanvas:TabSelector(CanvasConfig)
            Class.WindowTabSelector = Canvas
        end
        WindowClass = ReGui:MergeMetatables(Class, Canvas)
        Merge(Class, {
            ContentCanvas = Canvas,
            WindowClass = WindowClass,
            Body = Body
        })
        ReGui:ConnectMouseEvent(ContentFrame, {
            DoubleClick = true,
            OnlyMouseHovering = TitleBar,
            Callback = function(...)
                if not Class.OpenOnDoubleClick then
                    return
                end
                if Class.NoCollapse then
                    return
                end
                Class:ToggleCollapsed()
            end
        })
        if not NoTitleButtons then
            Class:AddDefaultTitleButtons()
        end
        Class:SetTitle(Title)
        Class:SetCollapsed(Collapsed, true)
        Class:SetTheme(Theme)
        Class:UpdateConfig(Config)
        Class:SetFocused()
        if not NoWindowRegistor then
            table.insert(Windows, WindowClass)
        end
        local ResizeGrab = ResizeConnection.Grab
        ReGui:SetAnimation(ResizeGrab, "TextButtons")
        ReGui:SetFocusedWindow(WindowClass)
        WindowClass:TagElements({
            [ResizeGrab] = "ResizeGrab",
            [TitleBar] = "TitleBar",
            [CanvasFrame] = "Window"
        })
        return WindowClass, Window
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("TabsWindow", {
    Export = true,
    Base = {
        NoTabs = false,
        AutoSelectNewTabs = true
    },
    Create = function(self, Config)
        return self:Window(Config)
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("PopupCanvas", {
    Base = {
        AutoClose = false,
        Scroll = false,
        Visible = true,
        Spacing = UDim.new(0, 1),
        AutomaticSize = Enum.AutomaticSize.XY,
        MaxSizeY = 150,
        MinSizeX = 100,
        MaxSizeX = math.huge,
        OnClosed = EmptyFunction
    },
    Create = function(self, Config)
        local RelativeTo = Config.RelativeTo
        local MaxSizeY = Config.MaxSizeY
        local MinSizeX = Config.MinSizeX
        local MaxSizeX = Config.MaxSizeX
        local Visible = Config.Visible
        local AutoClose = Config.AutoClose
        local NoAnimation = Config.NoAnimation
        Config.Parent = ReGui.Container.Overlays
        local Canvas, Object = self:OverlayScroll(Config)
        local UIStroke = Object.UIStroke
        local Padding = UIStroke.Thickness
        local Relative = Object.Parent.AbsolutePosition
        local Position, Size, YSize, XSize
        local Hover = ReGui:DetectHover(Object, {
            MouseOnly = true,
            OnInput = function(MouseHovering, Input)
                if MouseHovering then
                    return
                end
                if not Object.Visible then
                    return
                end
                Config:OnFocusLost()
            end
        })
        function Config:FetchScales()
            local CanvasSize = Canvas:GetCanvasSize()
            Position = RelativeTo.AbsolutePosition
            Size = RelativeTo.AbsoluteSize
            YSize = math.clamp(CanvasSize.Y, Size.Y, MaxSizeY)
            XSize = math.clamp(Size.X, MinSizeX, MaxSizeX)
        end
        function Config:UpdatePosition()
            Object.Position = UDim2.fromOffset(Position.X - Relative.X + Padding, Position.Y - Relative.Y + Size.Y)
        end
        function Config:GetScale(Visible)
            local OpenSize = UDim2.fromOffset(XSize, YSize)
            local ClosedSize = UDim2.fromOffset(XSize, 0)
            return Visible and OpenSize or ClosedSize
        end
        function Config:IsMouseHovering()
            return Hover.Hovering
        end
        function Config:OnFocusLost()
            local OnClosed = self.OnClosed
            self:SetPopupVisible(false)
            OnClosed(self)
            if AutoClose then
                self:ClosePopup()
            end
        end
        function Config:ClosePopup(Wait)
            self:SetPopupVisible(false, NoAnimation, Wait)
            Hover:Disconnect()
            Object:Remove()
        end
        function Config:SetPopupVisible(Visible, Wait)
            if Object.Visible == Visible then
                return
            end
            RelativeTo.Interactable = not Visible
            self:UpdateScales(Visible, NoAnimation, Wait)
            self.Visible = Visible
        end
        function Config:UpdateScales(Visible, NoAnimation, Wait)
            local Tweeninfo = Canvas:GetThemeKey("AnimationTweenInfo")
            Visible = Visible == nil and Object.Visible or Visible
            Config:FetchScales()
            Config:UpdatePosition()
            local Tween = Animation:Tween({
                Tweeninfo = Tweeninfo,
                Object = Object,
                NoAnimation = NoAnimation,
                EndProperties = {
                    Size = Config:GetScale(Visible),
                    Visible = Visible
                }
            })
            if Tween and Wait then
                Tween.Completed:Wait()
            end
        end
        Config:UpdateScales(false, true)
        Config:SetPopupVisible(Visible)
        Canvas.OnChildChange:Connect(Config.UpdateScales)
        return Canvas, Object
    end
})
--[=[ failed formatStat: unhandled stat with class index 35 ]=]
ReGui:DefineElement("PopupModal", {
    Export = true,
    Base = {
        NoAnimation = false,
        NoCollapse = true,
        NoClose = true,
        NoResize = true,
        NoSelect = true,
        NoAutoFlags = true,
        NoWindowRegistor = true,
        NoScroll = true
    },
    Create = function(self, Config)
        local WindowClass = self.WindowClass
        local NoAnimation = Config.NoAnimation
        local WindowDimTweenInfo = nil
        Config.Parent = ReGui.Container.Overlays
        if WindowClass then
            WindowDimTweenInfo = WindowClass:GetThemeKey("ModalWindowDimTweenInfo")
            Config.Theme = WindowClass.Theme
        end
        local ModalEffect = ReGui:InsertPrefab("ModalEffect", Config)
        local Window = self:Window(Copy(Config, {
            NoAutoFlags = false,
            Parent = ModalEffect,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(372, 38),
            AutomaticSize = Enum.AutomaticSize.Y
        }))
        function Config:ClosePopup()
            Animation:Tween({
                Object = ModalEffect,
                Tweeninfo = WindowDimTweenInfo,
                NoAnimation = NoAnimation,
                EndProperties = {
                    BackgroundTransparency = 1
                },
                Completed = function()
                    ModalEffect:Destroy()
                end
            })
            Window:Close()
        end
        Animation:Tween({
            Object = ModalEffect,
            Tweeninfo = WindowDimTweenInfo,
            NoAnimation = NoAnimation,
            StartProperties = {
                BackgroundTransparency = 1
            },
            EndProperties = {
                BackgroundTransparency = 0.8
            }
        })
        self:TagElements({
            [ModalEffect] = "ModalWindowDim"
        })
        local ModalClass = ReGui:MergeMetatables(Config, Window)
        return ModalClass, ModalEffect
    end
})
GenerateMultiInput("InputInt2", "InputInt", 2, {
    NoButtons = true
})
GenerateMultiInput("InputInt3", "InputInt", 3, {
    NoButtons = true
})
GenerateMultiInput("InputInt4", "InputInt", 4, {
    NoButtons = true
})
GenerateMultiInput("SliderInt2", "SliderInt", 2)
GenerateMultiInput("SliderInt3", "SliderInt", 3)
GenerateMultiInput("SliderInt4", "SliderInt", 4)
GenerateMultiInput("SliderFloat2", "SliderFloat", 2)
GenerateMultiInput("SliderFloat3", "SliderFloat", 3)
GenerateMultiInput("SliderFloat4", "SliderFloat", 4)
GenerateMultiInput("DragInt2", "DragInt", 2)
GenerateMultiInput("DragInt3", "DragInt", 3)
GenerateMultiInput("DragInt4", "DragInt", 4)
GenerateMultiInput("DragFloat2", "DragFloat", 2)
GenerateMultiInput("DragFloat3", "DragFloat", 3)
GenerateMultiInput("DragFloat4", "DragFloat", 4)
GenerateColor3Input("InputColor3", "InputInt3")
GenerateColor3Input("SliderColor3", "SliderInt3")
GenerateColor3Input("DragColor3", "DragInt3")
GenerateCFrameInput("InputCFrame", "InputInt3")
GenerateCFrameInput("SliderCFrame", "SliderInt3")
GenerateCFrameInput("DragCFrame", "DragInt3")
return ReGui
