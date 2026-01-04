local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- =====================================================================
--  설정값들
-- =====================================================================
getgenv().Settings = {
    ESP_Enabled = false,
    ESP_Tracers = false,
    ESP_Names = false,
    ESP_Distance = false,
    ESP_Boxes = false,
    Fly_Enabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    Noclip_Enabled = false,
    AntiVoid_Enabled = false
}

-- =====================================================================
--  기본 변수
-- =====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local drawingObjects = {} -- ESP용 Drawing 객체 저장

-- =====================================================================
--  Fluent GUI 생성
-- =====================================================================
local Window = Fluent:CreateWindow({
    Title = "Bgns1-Hub | Blindshot",
    SubTitle = "guns.lol/bgsn1",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "Amethyst"
})

local Tabs = {
    Visuals = Window:AddTab({ Title = "Visuals" }),
    Movement = Window:AddTab({ Title = "Movement" }),
    Misc = Window:AddTab({ Title = "Misc" })
}

-- 알림
Fluent:Notify({
    Title = "Bgns1-Hub | Blindshot Loaded",
    Content = "guns.lol/bgsn1",
    Duration = 6
})

-- =====================================================================
--  ESP (Unnamed-ESP 스타일 Drawing 기반)
-- =====================================================================

local function hideAllESP()
    for player, objects in pairs(drawingObjects) do
        if objects then
            for _, obj in pairs(objects) do
                obj.Visible = false
                obj.Transparency = 1
            end
        end
    end
end

local function createESP(player)
    if drawingObjects[player] then return end

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Transparency = 1
    box.Visible = false

    local name = Drawing.new("Text")
    name.Size = 14
    name.Center = true
    name.Outline = true
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Visible = false

    local distance = Drawing.new("Text")
    distance.Size = 12
    distance.Center = true
    distance.Outline = true
    distance.Color = Color3.fromRGB(200, 200, 200)
    distance.Visible = false

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Color = Color3.fromRGB(255, 0, 0)
    tracer.Transparency = 1
    tracer.Visible = false

    drawingObjects[player] = {box = box, name = name, distance = distance, tracer = tracer}
end

-- ESP 업데이트 함수
local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") then
            local root = player.Character.HumanoidRootPart
            local head = player.Character.Head
            local hum = player.Character:FindFirstChild("Humanoid")

            if not hum or hum.Health <= 0 then
                if drawingObjects[player] then
                    for _, v in pairs(drawingObjects[player]) do v.Visible = false end
                end
                continue
            end

            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if not onScreen then
                if drawingObjects[player] then
                    for _, v in pairs(drawingObjects[player]) do v.Visible = false end
                end
                continue
            end

            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            local sizeY = math.abs(headPos.Y - legPos.Y)
            local sizeX = sizeY * 0.5

            local obj = drawingObjects[player] or createESP(player)
            obj = drawingObjects[player]

            -- Boxes
            if Settings.ESP_Boxes then
                obj.box.Size = Vector2.new(sizeX, sizeY)
                obj.box.Position = Vector2.new(rootPos.X - sizeX/2, rootPos.Y - sizeY/2)
                obj.box.Visible = true
            else
                obj.box.Visible = false
            end

            -- Names + Health
            if Settings.ESP_Names then
                obj.name.Text = player.Name .. " [" .. math.floor(hum.Health) .. "]"
                obj.name.Position = Vector2.new(rootPos.X, rootPos.Y - sizeY/2 - 16)
                obj.name.Visible = true
            else
                obj.name.Visible = false
            end

            -- Distance
            if Settings.ESP_Distance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                obj.distance.Text = math.floor(dist) .. "m"
                obj.distance.Position = Vector2.new(rootPos.X, rootPos.Y + sizeY/2 + 2)
                obj.distance.Visible = true
            else
                obj.distance.Visible = false
            end

            -- Tracers
            if Settings.ESP_Tracers then
                obj.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                obj.tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                obj.tracer.Visible = true
            else
                obj.tracer.Visible = false
            end
        else
            -- 캐릭터 없음 → 숨김
            if drawingObjects[player] then
                for _, v in pairs(drawingObjects[player]) do
                    v.Visible = false
                end
            end
        end
    end
end

-- 플레이어 이벤트
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        createESP(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if drawingObjects[player] then
        for _, obj in pairs(drawingObjects[player]) do
            pcall(function() obj:Remove() end)
        end
        drawingObjects[player] = nil
    end
end)

-- 기존 플레이어들
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        if player.Character then createESP(player) end
        player.CharacterAdded:Connect(function() task.wait(0.1) createESP(player) end)
    end
end

-- =====================================================================
-- View Direction Tracer 추가 (기존 Screen Tracers와 완전 독립)
-- =====================================================================

local viewTracerSettings = {
    Enabled = false,
    Color = Color3.fromRGB(13, 5, 242),
    Thickness = 2,
    AutoThickness = true,
    MinThickness = 0.8,
    MaxThickness = 5,
    Length = 20,  -- 시선 방향 길이 (studs)
    TeamCheck = true
}

local viewTracers = {}  -- 각 플레이어당 Drawing Line 저장

local function createViewTracer()
    local line = Drawing.new("Line")
    line.Color = viewTracerSettings.Color
    line.Thickness = viewTracerSettings.Thickness
    line.Transparency = 1
    line.Visible = false
    return line
end

local function shouldShowViewTracer(targetPlr)
    if not viewTracerSettings.TeamCheck then return true end
    if not LocalPlayer.Team or not targetPlr.Team then return true end
    return LocalPlayer.Team ~= targetPlr.Team
end

local function updateViewTracers()
    if not viewTracerSettings.Enabled then
        for _, line in pairs(viewTracers) do
            line.Visible = false
        end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") 
        and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.Humanoid.Health > 0 
        and shouldShowViewTracer(player) then

            local head = player.Character.Head
            local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
            local lookVec = head.CFrame.LookVector
            local endWorld = head.Position + lookVec * viewTracerSettings.Length
            local endPos, endOnScreen = Camera:WorldToViewportPoint(endWorld)

            local line = viewTracers[player]
            if not line then
                line = createViewTracer()
                viewTracers[player] = line
            end

            if headOnScreen or endOnScreen then
                line.From = Vector2.new(headPos.X, headPos.Y)
                line.To = Vector2.new(endPos.X, endPos.Y)
                line.Visible = true

                if viewTracerSettings.AutoThickness and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    line.Thickness = math.clamp(120 / dist, viewTracerSettings.MinThickness, viewTracerSettings.MaxThickness)
                end
            else
                line.Visible = false
            end
        else
            if viewTracers[player] then
                viewTracers[player].Visible = false
            end
        end
    end
end

-- 플레이어 정리
Players.PlayerRemoving:Connect(function(player)
    if viewTracers[player] then
        viewTracers[player]:Remove()
        viewTracers[player] = nil
    end
end)

-- =====================================================================
--  GUI 요소들
-- =====================================================================

local espSection = Tabs.Visuals:AddSection("Player ESP")
local tracerSection = Tabs.Visuals:AddSection("Tracers & Extras")

-- 메인 ESP 토글
espSection:AddToggle("ESP", {
    Title = "Enable ESP",
    Default = false,
    Callback = function(v)
        Settings.ESP_Enabled = v
        if v then
            Fluent:Notify({
                Title = "ESP ON",
                Content = "ESP Enabled",
                Duration = 3
            })
        else
            hideAllESP()  -- 강제 모든 ESP 청소
            Fluent:Notify({
                Title = "ESP OFF", 
                Content = "ESP Disabled",
                Duration = 3
            })
        end
    end
})

-- 개별 옵션들
espSection:AddToggle("Boxes", {
    Title = "ESP Boxes",
    Default = true,
    Callback = function(v) Settings.ESP_Boxes = v end
})

espSection:AddToggle("Names", {
    Title = "Names + Health",
    Default = true,
    Callback = function(v) Settings.ESP_Names = v end
})

espSection:AddToggle("Distance", {
    Title = "Distance",
    Default = true,
    Callback = function(v) Settings.ESP_Distance = v end
})

espSection:AddToggle("ViewTracer", {
    Title = "ViewTracer",
    Default = true,
    Callback = function(v)
        viewTracerSettings.Enabled = v
    end
})

-- Tracer 섹션
tracerSection:AddToggle("Tracers", {
    Title = "Tracers",
    Default = false,
    Callback = function(v) 
        Settings.ESP_Tracers = v
        if v then
            Fluent:Notify({Title="Tracers", Content="Tracer Enabled", Duration=2})
        end
    end
})

-- ESP 성능 최적화 토글
tracerSection:AddToggle("ESP_Optimized", {
    Title = "Fps optimization",
    Default = false,
    Callback = function(v)
        getgenv().ESP_LowPerf = v
        Fluent:Notify({Title="Performance", Content=v and "FPS optimization ON" or "FPS optimization OFF", Duration=2})
    end
})

-- =====================================================================
-- Movement 탭 완전 복구 (이 개새끼야, 이거 없어서 탭이 비어버린 거다 씨발)
-- =====================================================================

local moveSection = Tabs.Movement:AddSection("Movement Cheats")

-- Fly 토글
moveSection:AddToggle("Fly", {
    Title = "Fly Hack (X to toggle)",
    Default = false,
    Callback = function(v)
        Settings.Fly_Enabled = v
        Fluent:Notify({
            Title = "Fly",
            Content = v and "Fly Enabled" or "Fly Disabled",
            Duration = 3
        })
    end
})

-- WalkSpeed 슬라이더
moveSection:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Min = 16,
    Max = 300,
    Default = 16,
    Rounding = 1,
    Callback = function(v)
        Settings.WalkSpeed = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
        Fluent:Notify({Title="Speed", Content="Current speed: "..v.." studs/s", Duration=2})
    end
})

-- JumpPower 슬라이더
moveSection:AddSlider("JumpPower", {
    Title = "Jump Power",
    Min = 50,
    Max = 300,
    Default = 50,
    Rounding = 1,
    Callback = function(v)
        Settings.JumpPower = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = v
        end
    end
})

-- Noclip 토글
moveSection:AddToggle("Noclip", {
    Title = "Noclip",
    Default = false,
    Callback = function(v)
        Settings.Noclip_Enabled = v
        Fluent:Notify({
            Title = "Noclip",
            Content = v and "Noclip Enabled" or "Noclip Disabled",
            Duration = 3
        })
    end
})

-- Anti-Void 토글
moveSection:AddToggle("AntiVoid", {
    Title = "Anti-Void / Anti-Fall",
    Default = true,
    Callback = function(v)
        Settings.AntiVoid_Enabled = v
        Fluent:Notify({
            Title = "Anti-Void",
            Content = v and "Anti-Void Enable" or "Anti-Void Disabled",
            Duration = 2
        })
    end
})

-- InfiniteJump 토글
moveSection:AddToggle("InfiniteJump", {
    Title = "Infinite Jump",
    Default = false,
    Callback = function(v)
        getgenv().InfJumpEnabled = v
        if v then
            Fluent:Notify({Title="Infinite Jump", Content="InfiniteJump Enabled", Duration=3})
        end
    end
})

-- =====================================================================
--  메인 루프
-- =====================================================================
RunService.RenderStepped:Connect(function()
    if Settings.ESP_Enabled then
        if getgenv().ESP_LowPerf then
            if tick() % 0.1 < 0.016 then
                updateESP()
            end
        else
            updateESP()  -- 기존 ESP 업데이트
        end
        updateViewTracers()
    else
        if tick() % 0.08 < 0.016 then
            hideAllESP()
        end
    end

    -- Fly
    if Settings.Fly_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.new()

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end

        hrp.Velocity = moveDir * 60
    end

    -- Noclip
    if Settings.Noclip_Enabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- Anti-Void
    if Settings.AntiVoid_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        if hrp.Position.Y < -10 then
            hrp.CFrame = CFrame.new(hrp.Position.X, 50, hrp.Position.Z)
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if getgenv().InfJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState("Jumping")
    end
end)

-- Fly 토글 키 (X)
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.X then
        Settings.Fly_Enabled = not Settings.Fly_Enabled
        Fluent:Notify({Title="Fly", Content="Fly "..(Settings.Fly_Enabled and "ON" or "OFF")})
    end
end)

-- =====================================================================
--  Misc 탭 기능 추가 (Rejoin / Server Hop)
-- =====================================================================
local miscSection = Tabs.Misc:AddSection("Server Control")

-- 1. Rejoin (재접속) 버튼
miscSection:AddButton({
    Title = "Rejoin Server",
    Description = "현재 게임에 재접속합니다.",
    Callback = function()
        local ts = game:GetService("TeleportService")
        local p = game:GetService("Players").LocalPlayer
        ts:Teleport(game.PlaceId, p)
    end
})

-- 2. Server Hop (다른 서버로 이동) 버튼
miscSection:AddButton({
    Title = "Server Hop",
    Description = "사람이 있는 다른 서버로 이동합니다.",
    Callback = function()
        local Http = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local Api = "https://games.roblox.com/v1/games/"
        
        local _place = game.PlaceId
        local _servers = Api.._place.."/servers/Public?sortOrder=Desc&limit=100"
        
        -- 서버 목록 가져오기 함수
        local function ListServers(cursor)
            local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
            return Http:JSONDecode(Raw)
        end
        
        local Server, Next
        local attempts = 0
        
        Fluent:Notify({Title="Server Hop", Content="Finding a new server...", Duration=2})

        -- 적절한 서버를 찾을 때까지 반복
        repeat
            local Servers = ListServers(Next)
            for _, v in pairs(Servers.data) do
                -- 꽉 차지 않았고(playing < max), 현재 서버(JobId)가 아닌 곳
                if v.playing ~= v.maxPlayers and v.id ~= game.JobId then
                    Server = v
                    break
                end
            end
            Next = Servers.nextPageCursor
            attempts = attempts + 1
        until Server or not Next or attempts > 5 -- 너무 오래 걸리면 중단
        
        if Server then
            TPS:TeleportToPlaceInstance(_place, Server.id, game:GetService("Players").LocalPlayer)
        else
            Fluent:Notify({Title="Server Hop", Content="이동할 서버를 찾지 못했습니다.", Duration=3})
        end
    end
})

-- =====================================================================
--  Save Manager & Interface Manager
-- =====================================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:BuildInterfaceSection(Tabs.Misc)
InterfaceManager:BuildInterfaceSection(Tabs.Misc)

SaveManager:LoadAutoloadConfig()

-- =====================================================================
--  종료 시 정리
-- =====================================================================
game:BindToClose(function()
    for _, objects in pairs(drawingObjects) do
        for _, obj in pairs(objects) do
            obj:Remove()
        end
    end
end)