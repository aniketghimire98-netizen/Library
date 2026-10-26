-- ██╗  ██╗███████╗███╗   ██╗    ██╗  ██╗██╗   ██╗██████╗
-- ╚██╗██╔╝██╔════╝████╗  ██║    ██║  ██║██║   ██║██╔══██╗
--  ╚███╔╝ █████╗  ██╔██╗ ██║    ███████║██║   ██║██████╔╝
--  ██╔██╗ ██╔══╝  ██║╚██╗██║    ██╔══██║██║   ██║██╔══██╗
-- ██╔╝ ██╗███████╗██║ ╚████║    ██║  ██║╚██████╔╝██████╔╝
-- ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
-- Xen Hub || Aimbot v2  |  Built with local Wind UI

-- ─────────────────────────────────────────────
--  SERVICES
-- ─────────────────────────────────────────────
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService     = game:GetService("HttpService")
local GuiService      = game:GetService("GuiService")
local Workspace       = game:GetService("Workspace")
local StarterGui      = game:GetService("StarterGui")
local LocalPlayer     = Players.LocalPlayer

-- ─────────────────────────────────────────────
--  CONFIG PERSISTENCE
-- ─────────────────────────────────────────────
local Config = {
    FileName = "XenHub-AimbotV2.json",
    Data     = {}
}

local function DefaultConfig()
    Config.Data = {
        FastAttack        = false,
        InfiniteEnergy    = false,
        UnbreakableSkills = false,
        AntiStun          = false,
        PlayerEsp         = false,
        WalkOnWater       = false,
        AutoRaceV3        = false,
        AutoRaceV4        = false,
        SpeedEnabled      = false,
        DashEnabled       = false,
        SpeedValue        = 16,
        DashValue         = 300,
        FADistance        = 100,
        AimbotSkillsPlayer = false,
        AimbotSkillsNPC    = false,
        PlayerTracers     = true,
        NPCTracers        = true,
        PredictionAmount  = 0.2,
        CamlockEnabled    = false,
    }
end

local function SaveConfig()
    pcall(function()
        writefile(Config.FileName, HttpService:JSONEncode(Config.Data))
    end)
end

local loaded = pcall(function()
    local raw = readfile(Config.FileName)
    local decoded = HttpService:JSONDecode(raw)
    assert(typeof(decoded) == "table")
    DefaultConfig()
    for k, v in pairs(decoded) do
        Config.Data[k] = v
    end
end)
if not loaded then
    DefaultConfig()
    SaveConfig()
end

-- propagate to globals
getgenv().Setting        = getgenv().Setting or {}
local Setting            = getgenv().Setting
Setting.PredictionAmount = Config.Data.PredictionAmount or 0.2
Setting.MaxDistance      = 1000

_G.FastAttackEnabled  = Config.Data.FastAttack
_G.InfiniteEnergy     = Config.Data.InfiniteEnergy
_G.UnbreakableSkills  = Config.Data.UnbreakableSkills
_G.AntiStun           = Config.Data.AntiStun
_G.PlayerEsp          = Config.Data.PlayerEsp
_G.WalkOnWater        = Config.Data.WalkOnWater
_G.AutoRaceV3         = Config.Data.AutoRaceV3
_G.AutoRaceV4         = Config.Data.AutoRaceV4
_G.FADistance         = Config.Data.FADistance or 100

local SpeedEnabled        = Config.Data.SpeedEnabled
local DashEnabled         = Config.Data.DashEnabled
local AimbotSkillsPlayer  = Config.Data.AimbotSkillsPlayer or false
local AimbotSkillsNPC     = Config.Data.AimbotSkillsNPC    or false
local PlayerTracers       = Config.Data.PlayerTracers
local NPCTracers          = Config.Data.NPCTracers
local CamlockEnabled      = Config.Data.CamlockEnabled or false

-- ─────────────────────────────────────────────
--  WIND UI  (local loader)
-- ─────────────────────────────────────────────
local WindUI
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/Footstepss/windui/main/wind.lua"
        ))()
    end)
    if ok then
        WindUI = result
    else
        -- fallback: try local cache
        WindUI = loadstring(readfile("WindUI.lua"))()
    end
end

-- ─────────────────────────────────────────────
--  CREATE WINDOW
-- ─────────────────────────────────────────────
local Window = WindUI:CreateWindow({
    Title        = "Xen Hub",
    SubTitle     = "Aimbot v2",
    TabWidth     = 160,
    Size         = UDim2.fromOffset(580, 460),
    Acrylic      = true,
    Theme        = "Dark",
    Icon         = "rbxassetid://103239668295637",
})

-- startup notification
StarterGui:SetCore("SendNotification", {
    Title    = "Xen Hub | Aimbot v2",
    Text     = "Config loaded — enjoy!",
    Duration = 3,
})

-- ─────────────────────────────────────────────
--  TABS
-- ─────────────────────────────────────────────
local TabCombat   = Window:CreateTab({ Title = "Combat",   Icon = "sword"        })
local TabAimbot   = Window:CreateTab({ Title = "Aimbot",   Icon = "crosshair"    })
local TabMovement = Window:CreateTab({ Title = "Movement", Icon = "footprints"   })
local TabVisual   = Window:CreateTab({ Title = "Visual",   Icon = "eye"          })
local TabMisc     = Window:CreateTab({ Title = "Misc",     Icon = "settings"     })

-- ══════════════════════════════════════════════
--  TAB 1 ── COMBAT
-- ══════════════════════════════════════════════
local SectionCombat = TabCombat:CreateSection("Combat Settings")

-- Fast Attack
TabCombat:CreateToggle({
    Title       = "Fast Attack",
    Description = "Reduces attack delay to reach targets faster.",
    Default     = Config.Data.FastAttack,
    Callback    = function(state)
        _G.FastAttackEnabled    = state
        Config.Data.FastAttack  = state
        SaveConfig()
    end,
})

-- FA Distance
TabCombat:CreateSlider({
    Title       = "Fast Attack Range",
    Description = "Maximum distance Fast Attack activates.",
    Default     = Config.Data.FADistance,
    Min         = 10,
    Max         = 500,
    Increment   = 5,
    Suffix      = " studs",
    Callback    = function(val)
        _G.FADistance        = val
        Config.Data.FADistance = val
        SaveConfig()
    end,
})

-- Infinite Energy
TabCombat:CreateToggle({
    Title       = "Infinite Energy",
    Description = "Prevents energy from depleting.",
    Default     = Config.Data.InfiniteEnergy,
    Callback    = function(state)
        _G.InfiniteEnergy          = state
        Config.Data.InfiniteEnergy = state
        SaveConfig()
    end,
})

-- Unbreakable Skills
TabCombat:CreateToggle({
    Title       = "Unbreakable Skills",
    Description = "Skills cannot be interrupted or broken.",
    Default     = Config.Data.UnbreakableSkills,
    Callback    = function(state)
        _G.UnbreakableSkills          = state
        Config.Data.UnbreakableSkills = state
        SaveConfig()
    end,
})

-- Anti Stun
TabCombat:CreateToggle({
    Title       = "Anti Stun",
    Description = "Continue moving even while stunned.",
    Default     = Config.Data.AntiStun,
    Callback    = function(state)
        _G.AntiStun          = state
        Config.Data.AntiStun = state
        SaveConfig()
    end,
})

TabCombat:CreateSection("Camlock")

-- Camlock
TabCombat:CreateToggle({
    Title       = "Camlock",
    Description = "Locks camera onto the nearest enemy player.",
    Default     = CamlockEnabled,
    Callback    = function(state)
        CamlockEnabled           = state
        Config.Data.CamlockEnabled = state
        SaveConfig()
        if not state and _G.CamlockConnection then
            _G.CamlockConnection:Disconnect()
            _G.CamlockConnection = nil
        end
    end,
})

TabCombat:CreateSection("Actions")

-- Soru button
TabCombat:CreateButton({
    Title       = "Soru to Nearest",
    Description = "Dash instantly to the nearest enemy.",
    Callback    = function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local closest, dist = nil, _G.FADistance or 100
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local orp = p.Character:FindFirstChild("HumanoidRootPart")
                if orp then
                    local d = (orp.Position - hrp.Position).Magnitude
                    if d < dist then
                        dist    = d
                        closest = orp
                    end
                end
            end
        end

        if closest then
            local cf = CFrame.new(closest.Position - (closest.CFrame.LookVector * 5))
            hrp.CFrame = cf
            pcall(function()
                ReplicatedStorage.Remotes.CommE:FireServer(
                    "Soru", cf, cf, workspace:GetServerTimeNow(), math.random(1, 900000000)
                )
            end)
        end
    end,
})

-- ══════════════════════════════════════════════
--  TAB 2 ── AIMBOT
-- ══════════════════════════════════════════════
TabAimbot:CreateSection("Skill Aimbot")

local AimbotPlayerToggle = TabAimbot:CreateToggle({
    Title       = "Aimbot Skills — Player",
    Description = "Auto-aims skills toward the nearest enemy player.",
    Default     = AimbotSkillsPlayer,
    Callback    = function(state)
        AimbotSkillsPlayer          = state
        Config.Data.AimbotSkillsPlayer = state
        SaveConfig()
        if not state then _G.AimbotPlayerTarget = nil end
    end,
})

TabAimbot:CreateToggle({
    Title       = "Aimbot Skills — NPC",
    Description = "Auto-aims skills toward the nearest NPC enemy.",
    Default     = AimbotSkillsNPC,
    Callback    = function(state)
        AimbotSkillsNPC          = state
        Config.Data.AimbotSkillsNPC = state
        SaveConfig()
        if not state then _G.AimbotNPCTarget = nil end
    end,
})

TabAimbot:CreateSection("Tracers")

TabAimbot:CreateToggle({
    Title       = "Player Tracers",
    Description = "Draw lines from your character to enemy players.",
    Default     = PlayerTracers,
    Callback    = function(state)
        PlayerTracers          = state
        Config.Data.PlayerTracers = state
        SaveConfig()
    end,
})

TabAimbot:CreateToggle({
    Title       = "NPC Tracers",
    Description = "Draw lines from your character to NPC enemies.",
    Default     = NPCTracers,
    Callback    = function(state)
        NPCTracers          = state
        Config.Data.NPCTracers = state
        SaveConfig()
    end,
})

TabAimbot:CreateSection("Prediction & Range")

TabAimbot:CreateSlider({
    Title       = "Prediction Amount",
    Description = "How far ahead targets are predicted (velocity offset).",
    Default     = math.floor(Config.Data.PredictionAmount * 100),
    Min         = 0,
    Max         = 100,
    Increment   = 1,
    Suffix      = "%",
    Callback    = function(val)
        local v                    = val / 100
        Setting.PredictionAmount   = v
        Config.Data.PredictionAmount = v
        SaveConfig()
    end,
})

TabAimbot:CreateSlider({
    Title       = "Max Target Distance",
    Description = "Aimbot ignores enemies beyond this range.",
    Default     = Setting.MaxDistance,
    Min         = 100,
    Max         = 2000,
    Increment   = 50,
    Suffix      = " studs",
    Callback    = function(val)
        Setting.MaxDistance = val
        SaveConfig()
    end,
})

-- ──────────────────────────────────────────────
--  Tracer Drawing Objects
-- ──────────────────────────────────────────────
local PlayerLine = Drawing.new("Line")
PlayerLine.Thickness  = 2.5
PlayerLine.Color      = Color3.fromRGB(0, 170, 255)
PlayerLine.Visible    = false

local NPCLine = Drawing.new("Line")
NPCLine.Thickness  = 2.5
NPCLine.Color      = Color3.fromRGB(255, 170, 0)
NPCLine.Visible    = false

-- helper: predict target position
local function PredictPosition(hrp)
    if not hrp then return nil end
    local hum = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed >= 8 then
        return hrp.Position + hrp.Velocity * Setting.PredictionAmount
    end
    return hrp.Position
end

-- find nearest enemy player
local function NearestPlayer(fromHRP)
    local best, bestDist = nil, Setting.MaxDistance
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local pvp = p:GetAttribute("PvpDisabled") or false
                if not pvp then
                    local d = (hrp.Position - fromHRP.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        best     = p
                    end
                end
            end
        end
    end
    return best
end

-- find nearest NPC
local function NearestNPC(fromHRP)
    local best, bestDist = nil, Setting.MaxDistance
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, npc in ipairs(enemies:GetChildren()) do
            local hum = npc:FindFirstChildOfClass("Humanoid")
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("UpperTorso")
            if hum and hum.Health > 0 and hrp then
                local d = (hrp.Position - fromHRP.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best     = npc
                end
            end
        end
    end
    return best
end

-- ══════════════════════════════════════════════
--  TAB 3 ── MOVEMENT
-- ══════════════════════════════════════════════
TabMovement:CreateSection("Speed")

local SpeedValueRef = { Value = Config.Data.SpeedValue or 16 }

TabMovement:CreateSlider({
    Title       = "Walk Speed",
    Description = "Custom walk speed value.",
    Default     = SpeedValueRef.Value,
    Min         = 1,
    Max         = 300,
    Increment   = 1,
    Suffix      = " WS",
    Callback    = function(val)
        SpeedValueRef.Value  = val
        Config.Data.SpeedValue = val
        SaveConfig()
    end,
})

TabMovement:CreateToggle({
    Title       = "Speed Hack",
    Description = "Apply custom walk speed every frame.",
    Default     = SpeedEnabled,
    Callback    = function(state)
        SpeedEnabled          = state
        Config.Data.SpeedEnabled = state
        SaveConfig()
    end,
})

TabMovement:CreateSection("Dash")

local DashValueRef = { Value = Config.Data.DashValue or 300 }

TabMovement:CreateSlider({
    Title       = "Dash Length",
    Description = "Custom dash/soru distance attribute.",
    Default     = DashValueRef.Value,
    Min         = 50,
    Max         = 2000,
    Increment   = 10,
    Suffix      = " units",
    Callback    = function(val)
        DashValueRef.Value   = val
        Config.Data.DashValue  = val
        SaveConfig()
    end,
})

TabMovement:CreateToggle({
    Title       = "Dash Boost",
    Description = "Apply custom dash length attribute every frame.",
    Default     = DashEnabled,
    Callback    = function(state)
        DashEnabled          = state
        Config.Data.DashEnabled = state
        SaveConfig()
    end,
})

TabMovement:CreateSection("Misc Movement")

TabMovement:CreateToggle({
    Title       = "Walk on Water",
    Description = "Expands the water base-plane so you can walk on it.",
    Default     = Config.Data.WalkOnWater,
    Callback    = function(state)
        _G.WalkOnWater          = state
        Config.Data.WalkOnWater = state
        SaveConfig()
    end,
})

-- ══════════════════════════════════════════════
--  TAB 4 ── VISUAL / ESP
-- ══════════════════════════════════════════════
TabVisual:CreateSection("Player ESP")

TabVisual:CreateToggle({
    Title       = "Player ESP",
    Description = "Shows name, level, HP, distance and PvP status above enemies.",
    Default     = Config.Data.PlayerEsp,
    Callback    = function(state)
        _G.PlayerEsp          = state
        Config.Data.PlayerEsp = state
        SaveConfig()
    end,
})

TabVisual:CreateSection("Tracers (Visual)")

TabVisual:CreateToggle({
    Title       = "Player Tracers",
    Description = "Blue lines drawn from you to each enemy player.",
    Default     = PlayerTracers,
    Callback    = function(state)
        PlayerTracers          = state
        Config.Data.PlayerTracers = state
        SaveConfig()
    end,
})

TabVisual:CreateToggle({
    Title       = "NPC Tracers",
    Description = "Orange lines drawn from you to each NPC enemy.",
    Default     = NPCTracers,
    Callback    = function(state)
        NPCTracers          = state
        Config.Data.NPCTracers = state
        SaveConfig()
    end,
})

-- ══════════════════════════════════════════════
--  TAB 5 ── MISC
-- ══════════════════════════════════════════════
TabMisc:CreateSection("Automation")

TabMisc:CreateToggle({
    Title       = "Auto Race V3",
    Description = "Automatically fires ActivateAbility every 30 seconds.",
    Default     = Config.Data.AutoRaceV3,
    Callback    = function(state)
        _G.AutoRaceV3          = state
        Config.Data.AutoRaceV3 = state
        SaveConfig()
    end,
})

TabMisc:CreateToggle({
    Title       = "Auto Race V4",
    Description = "Triggers Awakening when race energy reaches 90%%.",
    Default     = Config.Data.AutoRaceV4,
    Callback    = function(state)
        _G.AutoRaceV4          = state
        Config.Data.AutoRaceV4 = state
        SaveConfig()
    end,
})

TabMisc:CreateSection("Config")

TabMisc:CreateButton({
    Title       = "Save Config",
    Description = "Write current settings to XenHub-AimbotV2.json.",
    Callback    = function()
        SaveConfig()
        StarterGui:SetCore("SendNotification", {
            Title    = "Xen Hub",
            Text     = "Config saved!",
            Duration = 2,
        })
    end,
})

TabMisc:CreateButton({
    Title       = "Reset to Default",
    Description = "Restore all settings to their default values.",
    Callback    = function()
        DefaultConfig()
        SaveConfig()
        StarterGui:SetCore("SendNotification", {
            Title    = "Xen Hub",
            Text     = "Settings reset to default. Re-execute to apply.",
            Duration = 3,
        })
    end,
})

TabMisc:CreateSection("Info")

TabMisc:CreateLabel("Xen Hub  ||  Aimbot v2")
TabMisc:CreateLabel("Built with local Wind UI")

-- ══════════════════════════════════════════════
--  RUNTIME LOOPS
-- ══════════════════════════════════════════════

-- ── Player ESP ──────────────────────────────
RunService.RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local gui = p.Character:FindFirstChild("XenESP")
                or Instance.new("BillboardGui", p.Character)
            gui.Name         = "XenESP"
            gui.Size         = UDim2.new(0, 200, 0, 70)
            gui.StudsOffset  = Vector3.new(0, 2, 0)
            gui.AlwaysOnTop  = true
            gui.Adornee      = p.Character.Head
            gui.Enabled      = _G.PlayerEsp

            if _G.PlayerEsp then
                local lbl = gui:FindFirstChild("Label")
                    or Instance.new("TextLabel", gui)
                lbl.Name                  = "Label"
                lbl.BackgroundTransparency = 1
                lbl.Size                  = UDim2.new(1, 0, 1, 0)
                lbl.Font                  = Enum.Font.Jura
                lbl.RichText              = true
                lbl.TextSize              = 14
                lbl.TextStrokeTransparency = 0.4
                lbl.TextStrokeColor3      = Color3.new(0, 0, 0)

                local distM = math.floor(
                    (p.Character.Head.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                )
                local hum   = p.Character:FindFirstChildOfClass("Humanoid")
                local hp    = hum and math.floor(hum.Health) or 0
                local pvpOff = p:GetAttribute("PvpDisabled") or false
                local pvpTag = pvpOff
                    and '<font color="#FF4040">[PvP OFF]</font>'
                    or  '<font color="#00FF80">[PvP ON]</font>'

                local lvlObj = p:FindFirstChild("Data")
                local lvl    = (lvlObj and lvlObj:FindFirstChild("Level"))
                    and lvlObj.Level.Value or "?"

                lbl.Text = string.format(
                    "<b>%s</b> [Lv %s] %s\n%d HP  |  %d m",
                    p.Name, tostring(lvl), pvpTag, hp, distM
                )
                lbl.TextColor3 = (p.Team and p.Team.Name == "Marines")
                    and Color3.fromRGB(0, 80, 200)
                    or  Color3.fromRGB(220, 50, 50)
            end
        end
    end
end)

-- ── Speed / Dash / Anti-Stun ────────────────
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if SpeedEnabled and hum then
        hum.WalkSpeed = SpeedValueRef.Value
    end
    if DashEnabled and hrp then
        char:SetAttribute("DashLength", DashValueRef.Value)
    end
    if _G.AntiStun and hrp and hum and hum.MoveDirection.Magnitude > 0 then
        local stunned = hum.WalkSpeed == 0
        if not stunned then
            for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
                if t.IsPlaying and (
                    t.Animation.AnimationId:find("attack") or
                    t.Animation.AnimationId:find("skill")
                ) then
                    stunned = true
                    break
                end
            end
        end
        if not stunned then
            hrp.CFrame = hrp.CFrame + hum.MoveDirection.Unit * 1.7
        end
    end
end)

-- ── Aimbot target finders ────────────────────
task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            _G.AimbotPlayerTarget = AimbotSkillsPlayer and NearestPlayer(hrp) or nil
            _G.AimbotNPCTarget    = AimbotSkillsNPC    and NearestNPC(hrp)    or nil
        end
    end
end)

-- ── Tracer rendering ─────────────────────────
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")

    -- Player tracer
    local pt = _G.AimbotPlayerTarget
    local ptHRP = pt and pt.Character and pt.Character:FindFirstChild("HumanoidRootPart")
    if PlayerTracers and hrp and ptHRP then
        local fromPos, fromVis = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
        local toPos,   toVis   = workspace.CurrentCamera:WorldToViewportPoint(
            PredictPosition(ptHRP) or ptHRP.Position
        )
        if fromVis and toVis then
            PlayerLine.From    = Vector2.new(fromPos.X, fromPos.Y)
            PlayerLine.To      = Vector2.new(toPos.X,   toPos.Y)
            PlayerLine.Visible = true
        else
            PlayerLine.Visible = false
        end
    else
        PlayerLine.Visible = false
    end

    -- NPC tracer
    local nt = _G.AimbotNPCTarget
    local ntHRP = nt and (nt:FindFirstChild("HumanoidRootPart") or nt:FindFirstChild("UpperTorso"))
    if NPCTracers and hrp and ntHRP then
        local fromPos, fromVis = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
        local toPos,   toVis   = workspace.CurrentCamera:WorldToViewportPoint(
            PredictPosition(ntHRP) or ntHRP.Position
        )
        if fromVis and toVis then
            NPCLine.From    = Vector2.new(fromPos.X, fromPos.Y)
            NPCLine.To      = Vector2.new(toPos.X,   toPos.Y)
            NPCLine.Visible = true
        else
            NPCLine.Visible = false
        end
    else
        NPCLine.Visible = false
    end
end)

-- ── Camlock ──────────────────────────────────
RunService.RenderStepped:Connect(function()
    if not CamlockEnabled then return end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local target = NearestPlayer(hrp)
    local tHRP   = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if tHRP then
        local predicted = PredictPosition(tHRP) or tHRP.Position
        workspace.CurrentCamera.CFrame = CFrame.new(
            workspace.CurrentCamera.CFrame.Position, predicted
        )
    end
end)

-- ── Aimbot __namecall hook ───────────────────
pcall(function()
    local mt        = getrawmetatable(game)
    local oldNC     = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args   = { ... }

        if tostring(method) == "FireServer" then
            if tostring(self) == "RemoteEvent" then
                local arg2 = tostring(args[1] or "")
                if arg2 ~= "true" and arg2 ~= "false" then
                    local ptHRP = _G.AimbotPlayerTarget
                        and _G.AimbotPlayerTarget.Character
                        and _G.AimbotPlayerTarget.Character:FindFirstChild("HumanoidRootPart")
                    local ntHRP = _G.AimbotNPCTarget
                        and (_G.AimbotNPCTarget:FindFirstChild("HumanoidRootPart")
                             or _G.AimbotNPCTarget:FindFirstChild("UpperTorso"))

                    if AimbotSkillsPlayer and ptHRP then
                        args[1] = PredictPosition(ptHRP) or ptHRP.Position
                        return oldNC(self, table.unpack(args))
                    elseif AimbotSkillsNPC and ntHRP then
                        args[1] = PredictPosition(ntHRP) or ntHRP.Position
                        return oldNC(self, table.unpack(args))
                    end
                end
            end
        end
        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
end)

-- ── CombatUtil hook (GetTargetPosition) ──────
pcall(function()
    local origFn
    origFn = hookfunction(
        require(ReplicatedStorage.Modules.CombatUtil).GetTargetPosition,
        function(self, mouseHit, targetPos, ...)
            local ptHRP = _G.AimbotPlayerTarget
                and _G.AimbotPlayerTarget.Character
                and _G.AimbotPlayerTarget.Character:FindFirstChild("HumanoidRootPart")
            if AimbotSkillsPlayer and ptHRP then
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                local isMelee = tool and (tool:FindFirstChild("Melee") or tool.ToolTip == "Melee")
                if not isMelee then
                    targetPos = PredictPosition(ptHRP) or ptHRP.Position
                end
            end
            return origFn(self, mouseHit, targetPos, ...)
        end
    )
end)

-- ── Unbreakable Skills loop ───────────────────
task.spawn(function()
    while task.wait(0.1) do
        if _G.UnbreakableSkills and LocalPlayer.Character then
            pcall(function()
                LocalPlayer.Character:SetAttribute("UnbreakableAll", true)
            end)
        end
    end
end)

-- ── Walk on Water loop ────────────────────────
task.spawn(function()
    while task.wait(0.1) do
        local waterPlane = workspace:FindFirstChild("Map")
            and workspace.Map:FindFirstChild("Water Base-Plane")
        if waterPlane then
            waterPlane.Size = _G.WalkOnWater
                and Vector3.new(1000, 112, 1000)
                or  Vector3.new(1000, 10,  1000)
        end
    end
end)

-- ── Auto Race loops ───────────────────────────
task.spawn(function()
    while task.wait(0.5) do
        if _G.AutoRaceV3 then
            pcall(function()
                ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
            end)
            task.wait(30)
        end

        if _G.AutoRaceV4 then
            local pgui  = LocalPlayer:FindFirstChild("PlayerGui")
            local main  = pgui and pgui:FindFirstChild("Main")
            local fill  = main
                and main:FindFirstChild("RaceEnergy")
                and main.RaceEnergy:FindFirstChild("Fill")

            if fill and fill.Size.X.Scale >= 0.9 then
                local pack = LocalPlayer:FindFirstChild("Backpack")
                local char = LocalPlayer.Character
                local aw   = (pack and pack:FindFirstChild("Awakening"))
                    or (char and char:FindFirstChild("Awakening"))
                if aw then
                    local rf = aw:FindFirstChild("RemoteFunction")
                    if rf then
                        pcall(function() rf:InvokeServer(true) end)
                        task.wait(5)
                    end
                end
            end
        end
    end
end)

print("[Xen Hub | Aimbot v2] Fully loaded.")
