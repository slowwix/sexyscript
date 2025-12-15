local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
Rayfield:Notify({
    Title = "UI 로딩 중...",
    Content = "세련된 디자인 + 보스 선택 UI + 평타 연타 + 높이 조절 적용 중",
    Duration = 3
})
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
-- ==================== 윈도우 생성 ====================
local Window = Rayfield:CreateWindow({
    Name = "제목 없는 RPG | Ultimate Hub",
    LoadingTitle = "Ultimate Hub 로딩 중...",
    LoadingSubtitle = "세련된 다크 테마 + 평타 연타 + 높이 조절",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "NamelessRPG_Ultimate",
        FileName = "UltimateConfig"
    },
    Discord = {Enabled = false},
    KeySystem = false
})
local MainTab = Window:CreateTab("🏠 메인 기능", 6035059441)
local BossTab = Window:CreateTab("👹 보스 오토", 6035036483)
local UtilityTab = Window:CreateTab("⚙️ 유틸리티", 6034953201)
-- ==================== Death Respawn ====================
MainTab:CreateSection("💀 Death Respawn System")
local respawnEnabled = false
local deathPosition = nil
local respawnHeight = 5
local respawnToggle = MainTab:CreateToggle({
    Name = "죽은 위치 자동 리스폰",
    Info = "죽으면 위치 저장 → 다음 리스폰 시 자동 복귀",
    CurrentValue = false,
    Flag = "DeathRespawn_Enabled",
    Callback = function(Value)
        respawnEnabled = Value
        if not Value then deathPosition = nil end
    end
})
MainTab:CreateSlider({
    Name = "리스폰 높이 조절 (studs)",
    Info = "리스폰 시 바닥에서 올라갈 높이",
    Range = {1, 100},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 5,
    Flag = "DeathRespawn_Height",
    Callback = function(Value)
        respawnHeight = Value
    end
})
MainTab:CreateParagraph({
    Title = "📌 사용 팁",
    Content = "보스전 중 죽어도 바로 복귀! 높이 ↑ = 낙하 대미지 방지"
})
-- ==================== 보스 오토 변수 ====================
local narakEnabled = false
local yetiEnabled = false
local frostWolfEnabled = false
local narakPositionConnection = nil
local yetiPositionConnection = nil
local frostWolfPositionConnection = nil
local frostWolfTargetNames = {"서리 늑대", "서리늑대", "frostWolf"}
local headHeight = 18 -- 머리 위 높이 기본값 (studs)
local targetMonsterNames = {"나락화 수호자", "나락화수호자", "나락화 수호자", "Narak Guardian"}
local yetiTargetNames = {"Yeti", "예티", "Snow Yeti", "Ice Yeti"}
-- ==================== 보스 탭 UI ====================
BossTab:CreateSection("👹 보스 선택 및 제어")
BossTab:CreateParagraph({
    Title = "📋 사용법",
    Content = "• 아래 버튼으로 보스 선택\n• 머리 위 고정 + E R T 폭딜 + 평타 0.5초 연타 자동 시작!\n• 높이 슬라이더로 조절 가능"
})
BossTab:CreateSlider({
    Name = "머리 위 높이 (studs)",
    Info = "보스 머리 위 고정 높이 조절 (랜덤 ±2 변동으로 안정화)",
    Range = {1, 40},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 18,
    Flag = "BossHeadHeight",
    Callback = function(Value)
        headHeight = Value
        Rayfield:Notify({
            Title = "높이 변경됨",
            Content = Value .. " studs로 설정 (즉시 적용)",
            Duration = 2
        })
    end
})
BossTab:CreateParagraph({
    Title = "⚔️ 특징 (공통)",
    Content = "• 100% 떨어짐 방지 (Heartbeat 고정)\n• E→R→T 초고속 + 평타 0.5초 연타\n• 높이 조절로 최적화 사냥"
})
local function pressKey(key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
end
local function clickMouse()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end
local function isGuardianAlive()
    for _, obj in workspace:GetDescendants() do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj.Humanoid.Health > 0 then
            for _, name in targetMonsterNames do
                if obj.Name == name then return true, obj end
            end
            if string.find(string.lower(obj.Name), "나락") and string.find(string.lower(obj.Name), "수호자") then
                return true, obj
            end
        end
    end
    return false
end
function narakLoop()
    spawn(function()
        while narakEnabled do
            local alive, boss = isGuardianAlive()
            if alive and boss then
                Rayfield:Notify({
                    Title = "🎯 나락화 수호자 포착!",
                    Content = "머리 위 " .. headHeight .. "studs 고정 + 풀오토 시작",
                    Duration = 3,
                    Image = 6035036483
                })
                if narakPositionConnection then narakPositionConnection:Disconnect() end
                local bossHead = boss:FindFirstChild("Head") or boss:FindFirstChild("HumanoidRootPart")
                local char = player.Character or player.CharacterAdded:Wait()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if bossHead and hrp then
                    narakPositionConnection = RunService.Heartbeat:Connect(function()
                        if not narakEnabled or not bossHead.Parent or bossHead.Parent.Humanoid.Health <= 0 then
                            if narakPositionConnection then narakPositionConnection:Disconnect() end
                            return
                        end
                        local offsetX = math.random(-20, 20)/10
                        local offsetY = headHeight + math.random(-2, 2)
                        local offsetZ = math.random(-15, 15)/10
                        local targetPos = bossHead.Position + Vector3.new(offsetX, offsetY, offsetZ)
                        hrp.CFrame = CFrame.lookAt(targetPos, bossHead.Position)
                    end)
                end
          
                pressKey(Enum.KeyCode.E)
                task.wait(0.13)
                pressKey(Enum.KeyCode.R)
                task.wait(0.13)
                pressKey(Enum.KeyCode.T)
                task.wait(0.3)
                spawn(function()
                    while narakEnabled and bossHead and bossHead.Parent and bossHead.Parent.Humanoid.Health > 0 do
                        clickMouse()
                        task.wait(0.5)
                    end
                end)
            end
            task.wait(0.05)
        end
    end)
end
local function isYetiAlive()
    for _, obj in workspace:GetDescendants() do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj.Humanoid.Health > 0 then
            for _, name in yetiTargetNames do
                if obj.Name == name then return true, obj end
            end
            if string.find(string.lower(obj.Name), "yeti") or string.find(string.lower(obj.Name), "예티") then
                return true, obj
            end
        end
    end
    return false
end
function yetiLoop()
    spawn(function()
        while yetiEnabled do
            local alive, boss = isYetiAlive()
            if alive and boss then
                Rayfield:Notify({
                    Title = "❄️ 예티 포착!",
                    Content = "머리 위 " .. headHeight .. "studs 고정 + 풀오토 시작",
                    Duration = 3,
                    Image = 6031075938
                })
                if yetiPositionConnection then yetiPositionConnection:Disconnect() end
                local bossHead = boss:FindFirstChild("Head") or boss:FindFirstChild("HumanoidRootPart")
                local char = player.Character or player.CharacterAdded:Wait()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if bossHead and hrp then
                    yetiPositionConnection = RunService.Heartbeat:Connect(function()
                        if not yetiEnabled or not bossHead.Parent or bossHead.Parent.Humanoid.Health <= 0 then
                            if yetiPositionConnection then yetiPositionConnection:Disconnect() end
                            return
                        end
                        local offsetX = math.random(-20, 20)/10
                        local offsetY = headHeight + math.random(-2, 2)
                        local offsetZ = math.random(-15, 15)/10
                        local targetPos = bossHead.Position + Vector3.new(offsetX, offsetY, offsetZ)
                        hrp.CFrame = CFrame.lookAt(targetPos, bossHead.Position)
                    end)
                end
     
                pressKey(Enum.KeyCode.E)
                task.wait(0.13)
                pressKey(Enum.KeyCode.R)
                task.wait(0.13)
                pressKey(Enum.KeyCode.T)
                task.wait(0.3)
                spawn(function()
                    while yetiEnabled and bossHead and bossHead.Parent and bossHead.Parent.Humanoid.Health > 0 do
                        clickMouse()
                        task.wait(0.5)
                    end
                end)
            end
            task.wait(0.05)
        end
    end)
end
local function isFrostWolfAlive()
    for _, obj in workspace:GetDescendants() do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj.Humanoid.Health > 0 then
            for _, name in frostWolfTargetNames do
                if obj.Name == name then return true, obj end
            end
            if string.find(string.lower(obj.Name), "서리") and string.find(string.lower(obj.Name), "늑대") then
                return true, obj
            end
        end
    end
    return false
end

function frostWolfLoop()
    spawn(function()
        while frostWolfEnabled do
            local alive, boss = isFrostWolfAlive()
            if alive and boss then
                Rayfield:Notify({
                    Title = "🐺 서리 늑대 포착!",
                    Content = "머리 위 " .. headHeight .. "studs 고정 + 풀오토 시작",
                    Duration = 3,
                    Image = 6031075938  -- 예티 이미지 재사용 (또는 새 이미지 ID)
                })
                if frostWolfPositionConnection then frostWolfPositionConnection:Disconnect() end
                local bossHead = boss:FindFirstChild("Head") or boss:FindFirstChild("HumanoidRootPart")
                local char = player.Character or player.CharacterAdded:Wait()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if bossHead and hrp then
                    frostWolfPositionConnection = RunService.Heartbeat:Connect(function()
                        if not frostWolfEnabled or not bossHead.Parent or bossHead.Parent.Humanoid.Health <= 0 then
                            if frostWolfPositionConnection then frostWolfPositionConnection:Disconnect() end
                            return
                        end
                        local offsetX = math.random(-20, 20)/10
                        local offsetY = headHeight + math.random(-2, 2)
                        local offsetZ = math.random(-15, 15)/10
                        local targetPos = bossHead.Position + Vector3.new(offsetX, offsetY, offsetZ)
                        hrp.CFrame = CFrame.lookAt(targetPos, bossHead.Position)
                    end)
                end

                pressKey(Enum.KeyCode.E)
                task.wait(0.13)
                pressKey(Enum.KeyCode.R)
                task.wait(0.13)
                pressKey(Enum.KeyCode.T)
                task.wait(0.3)
                spawn(function()
                    while frostWolfEnabled and bossHead and bossHead.Parent and bossHead.Parent.Humanoid.Health > 0 do
                        clickMouse()
                        task.wait(0.5)
                    end
                end)
            end
            task.wait(0.05)
        end
    end)
end
BossTab:CreateButton({
    Name = "🔥 나락화 수호자 오토 시작",
    Callback = function()
        yetiEnabled = false
        if yetiPositionConnection then yetiPositionConnection:Disconnect() end
        narakEnabled = true
        narakLoop()
        Rayfield:Notify({
            Title = "🎯 나락화 오토 시작!",
            Content = "높이 " .. headHeight .. "studs + 평타 0.5초 연타 포함",
            Duration = 4,
            Image = 6035036483
        })
    end
})
BossTab:CreateButton({
    Name = "❄️ 예티 오토 시작",
    Callback = function()
        narakEnabled = false
        if narakPositionConnection then narakPositionConnection:Disconnect() end
        yetiEnabled = true
        yetiLoop()
        Rayfield:Notify({
            Title = "❄️ 예티 오토 시작!",
            Content = "높이 " .. headHeight .. "studs + 평타 0.5초 연타 포함",
            Duration = 4,
            Image = 6031075938
        })
    end
})
BossTab:CreateButton({
    Name = "⏹️ 모든 보스 오토 중지",
    Callback = function()
        narakEnabled = false
        yetiEnabled = false
        frostWolf = false
        if frostWolfPositionConnection then frostWolfPositionConnection:Disconnect() end
        if narakPositionConnection then narakPositionConnection:Disconnect() end
        if yetiPositionConnection then yetiPositionConnection:Disconnect() end
        Rayfield:Notify({
            Title = "⏹️ 오토 완전 중지",
            Content = "모든 기능 안전하게 정지됨",
            Duration = 3,
            Image = 6035047407
        })
    end
})
local function setupDeathCharacter(char)
    local humanoid = char:WaitForChild("Humanoid")
    local rootPart = char:WaitForChild("HumanoidRootPart")
    humanoid.Died:Connect(function()
        if respawnEnabled then
            deathPosition = rootPart.Position
            Rayfield:Notify({
                Title = "💀 사망 위치 기록됨",
                Content = "다음 리스폰 시 자동 복귀!",
                Duration = 4,
                Image = 6035047407
            })
        end
    end)
    if deathPosition and respawnEnabled then
        rootPart.CFrame = CFrame.new(deathPosition + Vector3.new(0, respawnHeight, 0))
        Rayfield:Notify({
            Title = "✨ 자동 리스폰 완료",
            Content = "+" .. respawnHeight .. " studs 높이 복귀",
            Duration = 4,
            Image = 6031075938
        })
    end
end
if player.Character then setupDeathCharacter(player.Character) end
player.CharacterAdded:Connect(setupDeathCharacter)
UtilityTab:CreateSection("📊 상태 및 디버그")
UtilityTab:CreateLabel("✅ 스크립트 상태: 완벽 로드됨 (높이 조절 + 평타 버전)")
UtilityTab:CreateLabel("📏 현재 머리 위 높이: " .. headHeight .. " studs")
UtilityTab:CreateButton({
    Name = "UI 완전 재로드 (정말 됨)",
    Callback = function()
        narakEnabled = false
        yetiEnabled = false
        if narakPositionConnection then narakPositionConnection:Disconnect() end
        if yetiPositionConnection then yetiPositionConnection:Disconnect() end
       
        if Rayfield then
            Rayfield:Destroy()
        end
       
        task.wait(0.5)
       
        loadstring(game:HttpGet('https://raw.githubusercontent.com/voice2d/NamelessRPG_Ultimate/main/UltimateHub.lua'))()
       
        Rayfield:Notify({
            Title = "재로드 성공!",
            Content = "UI가 완전히 새로 로드되었습니다! 모든 기능 정상 작동",
            Duration = 5
        })
    end
})
UtilityTab:CreateButton({
    Name = "🔔 알림 테스트",
    Callback = function()
        Rayfield:Notify({
            Title = "테스트 알림",
            Content = "UI + 높이 조절 + 평타 완벽 작동 중! 😎",
            Duration = 4,
            Image = 6031075938
        })
    end
})
Rayfield:Notify({
    Title = "🎉 Ultimate Hub 완전 로드!",
    Content = "👹 나락화 / 예티 풀오토\n📏 머리 위 높이 슬라이더 추가!\n⚔️ + 평타 0.5초 연타\n즐거운 사냥 되세요! 🔥❄️",
    Duration = 7,
    Image = 6031075938
})
print("제목 없는 RPG Ultimate Hub (높이 조절 + 평타 연타 버전) 로드 완료!")
