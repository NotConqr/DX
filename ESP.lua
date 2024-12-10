--[[ Configuration ]]
local Settings = {
    Box_Color = Color3.fromRGB(255, 0, 0),
    Tracer_Color = Color3.fromRGB(255, 0, 0),
    Tracer_Thickness = 1,
    Box_Thickness = 1,
    Tracer_Origin = "Bottom", -- "Middle" or "Bottom"
    Tracer_FollowMouse = false,
    Tracers = true
}
local Team_Check = {
    TeamCheck = false,
    Green = Color3.fromRGB(0, 255, 0),
    Red = Color3.fromRGB(255, 0, 0)
}
local TeamColor = true

--[[ Main Script ]]
local player = game:GetService("Players").LocalPlayer
local camera = game:GetService("Workspace").CurrentCamera
local mouse = player:GetMouse()
local activePlayers = {} -- Tracks players with active ESP

local function NewQuad(thickness, color)
    local quad = Drawing.new("Quad")
    quad.Visible = false
    quad.PointA = Vector2.new(0, 0)
    quad.PointB = Vector2.new(0, 0)
    quad.PointC = Vector2.new(0, 0)
    quad.PointD = Vector2.new(0, 0)
    quad.Color = color
    quad.Filled = false
    quad.Thickness = thickness
    quad.Transparency = 1
    return quad
end

local function NewLine(thickness, color)
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(0, 0)
    line.Color = color
    line.Thickness = thickness
    line.Transparency = 1
    return line
end

local function Visibility(state, lib)
    for _, x in pairs(lib) do
        x.Visible = state
    end
end

local function ToColor3(col)
    return Color3.new(col.r, col.g, col.b)
end

local black = Color3.fromRGB(0, 0, 0)

local function ESP(plr)
    if activePlayers[plr] then return end -- Prevent duplicate ESP for the same player
    activePlayers[plr] = true

    local library = {
        blacktracer = NewLine(Settings.Tracer_Thickness * 2, black),
        tracer = NewLine(Settings.Tracer_Thickness, Settings.Tracer_Color),
        black = NewQuad(Settings.Box_Thickness * 2, black),
        box = NewQuad(Settings.Box_Thickness, Settings.Box_Color),
        healthbar = NewLine(3, black),
        greenhealth = NewLine(1.5, black)
    }

    local function Colorize(color)
        for _, x in pairs(library) do
            if x ~= library.healthbar and x ~= library.greenhealth and x ~= library.blacktracer and x ~= library.black then
                x.Color = color
            end
        end
    end

    local function Updater()
        local connection
        connection = game:GetService("RunService").RenderStepped:Connect(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
                local humanoid = plr.Character:FindFirstChild("Humanoid")
                if humanoid.Health > 0 then
                    local HumPos, OnScreen = camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                    if OnScreen then
                        local head = plr.Character:FindFirstChild("Head")
                        local upperTorso = plr.Character:FindFirstChild("UpperTorso")
                        local torsoPos = camera:WorldToViewportPoint(upperTorso and upperTorso.Position or plr.Character.HumanoidRootPart.Position)
                        local headPos = camera:WorldToViewportPoint(head and head.Position or plr.Character.HumanoidRootPart.Position)

                        local DistanceY = math.clamp((Vector2.new(headPos.X, headPos.Y) - Vector2.new(torsoPos.X, torsoPos.Y)).magnitude, 2, math.huge)

                        local function Size(item)
                            item.PointA = Vector2.new(HumPos.X + DistanceY, HumPos.Y - DistanceY * 2)
                            item.PointB = Vector2.new(HumPos.X - DistanceY, HumPos.Y - DistanceY * 2)
                            item.PointC = Vector2.new(HumPos.X - DistanceY, HumPos.Y + DistanceY * 2)
                            item.PointD = Vector2.new(HumPos.X + DistanceY, HumPos.Y + DistanceY * 2)
                        end
                        Size(library.box)
                        Size(library.black)

                        if Settings.Tracers then
                            if Settings.Tracer_Origin == "Middle" then
                                library.tracer.From = camera.ViewportSize * 0.5
                                library.blacktracer.From = camera.ViewportSize * 0.5
                            elseif Settings.Tracer_Origin == "Bottom" then
                                library.tracer.From = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y)
                                library.blacktracer.From = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y)
                            end
                            if Settings.Tracer_FollowMouse then
                                library.tracer.From = Vector2.new(mouse.X, mouse.Y + 36)
                                library.blacktracer.From = Vector2.new(mouse.X, mouse.Y + 36)
                            end
                            library.tracer.To = Vector2.new(HumPos.X, HumPos.Y + DistanceY * 2)
                            library.blacktracer.To = Vector2.new(HumPos.X, HumPos.Y + DistanceY * 2)
                        else
                            Visibility(false, library)
                        end

                        local d = (Vector2.new(HumPos.X - DistanceY, HumPos.Y - DistanceY * 2) - Vector2.new(HumPos.X - DistanceY, HumPos.Y + DistanceY * 2)).magnitude
                        local healthoffset = humanoid.Health / humanoid.MaxHealth * d

                        library.greenhealth.From = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY * 2)
                        library.greenhealth.To = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY * 2 - healthoffset)

                        library.healthbar.From = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY * 2)
                        library.healthbar.To = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y - DistanceY * 2)

                        local green = Color3.fromRGB(0, 255, 0)
                        local red = Color3.fromRGB(255, 0, 0)
                        library.greenhealth.Color = red:lerp(green, humanoid.Health / humanoid.MaxHealth)

                        if Team_Check.TeamCheck then
                            if plr.TeamColor == player.TeamColor then
                                Colorize(Team_Check.Green)
                            else
                                Colorize(Team_Check.Red)
                            end
                        elseif TeamColor then
                            Colorize(plr.TeamColor.Color)
                        else
                            Colorize(Settings.Box_Color)
                        end

                        Visibility(true, library)
                    else
                        Visibility(false, library)
                    end
                else
                    Visibility(false, library)
                end
            else
                Visibility(false, library)
                if not game:GetService("Players"):FindFirstChild(plr.Name) then
                    connection:Disconnect()
                    activePlayers[plr] = nil -- Remove from active players
                end
            end
        end)
    end

    coroutine.wrap(Updater)()
end

for _, v in pairs(game:GetService("Players"):GetPlayers()) do
    if v.Name ~= player.Name then
        ESP(v)
    end
end

game:GetService("Players").PlayerAdded:Connect(function(newplr)
    if newplr.Name ~= player.Name then
        ESP(newplr)
    end
end)
