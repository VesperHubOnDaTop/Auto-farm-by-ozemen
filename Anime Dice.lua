--[[
    OZEMEN HUB × ANIME DICE — v2.1 (Bug Fixed)
    Discord: https://discord.gg/4Yg72kYT6s

    ═══════════════════════════════════════════════════════════
    ★ CONFIG — ตั้งค่าได้ 2 ทาง:
    1) คอนฟิกไฟล์ → ใส่ในโฟลเดอร์ "Ozemen/AnimeDice" (หน้า UI)
    2) ตัวแปร → ตั้ง getgenv().AnimeDiceConfig = { ... } ก่อนรัน

    ตารางคีย์ที่ใช้ (ชื่อคีย์ = ตรงตาม getgenv().AnimeDiceConfig):

    ShowUI          = false   -- true=เปิด UI  | false=Overlay กลางจอ
    AntiAFK         = true    -- ป้องกันหลุด 24/7
    FpsBoost        = true    -- ลดคุณภาพกราฟิก เพิ่ม FPS
    UltraFpsBoost   = false   -- 🔥 ลบทุกอย่างในแมพ เหลือแค่เพลตเรา (FPS ขั้นสุด)
    HideCutscene    = true    -- ซ่อน Cutscene สุ่มเต๋า

    -- แท่นเงิน / สุ่มเต๋า
    AutoCollect     = true    -- ดูดเงินอัตโนมัติ
    CollectInterval = 0.5     -- ความถี่ดูดเงิน (วิ)   [0.5 แนะนำ]
    AutoEquipBest   = true    -- ใส่ตัวเก่งสุดอัตโนมัติ
    AutoLevelUnit   = true    -- อัปเลเวลหน่วยอัตโนมัติ
    MaxUnitLevel    = 20      -- เพดานเลเวล (เก็บเงินเผื่อจุติ)  [20 แนะนำ]
    AutoRoll        = true    -- สุ่มเต๋าอัตโนมัติ

    -- จุติ / อัปเกรด / รางวัล
    AutoRebirth     = true    -- จุติอัตโนมัติ
    RebirthTarget   = 999     -- เพดานจุติ
    AutoUpgrade     = true    -- ซื้ออัปเกรดอัตโนมัติ
    AutoDice        = true    -- ซื้อเต๋าใหม่
    AutoReward      = true    -- รับของฟรีทั้งหมด
    AutoQuest       = true    -- รับเควสที่ทำครบ
    AutoBoost       = true    -- ใช้น้ำยา tier สูงสุด

    -- ขาย / Smart Trash
    AutoSell        = true    -- ขายอัตโนมัติ
    AutoFilterTrash = true    -- ไต่ tier อัตโนมัติ
    TrashUpgradeAt  = 5       -- ไต่ tier เมื่อมีกี่ตัว  [5 แนะนำ]
    TrashStartTier  = "Common"-- tier เริ่มต้นหลังจุติ
    SellKeepBuffer  = 6       -- เหลือที่ว่างขั้นต่ำในคลัง
    SellKeepIncome  = 1000000 -- เก็บตัวที่มีรายได้เกินนี้ (มากกว่าไม่ขาย)

    -- เว็บฮุก
    WebhookURL      = ""      -- URL Discord webhook
    WebhookEnabled  = false   -- เปิด/ปิด

    -- หอคอย
    AutoTower       = true    -- ลงหอคอยอัตโนมัติ
    TowerMode       = "auto"  -- auto | Dragon|Cursed|Pirate|Hidden Leaf|Infinity Tower

    -- เทรด (ยังไม่สมบูรณ์ — เกมเปลี่ยน Remote เป็น ChangeOffer)
    AutoTrade       = false
    TradeHost       = {}      -- เช่น {"PlayerName1","PlayerName2"}
    TradeSendMode   = "none"  -- none | keep_slotted | all

    ═══════════════════════════════════════════════════════════
]]

if _G.OzemenCleanup then pcall(_G.OzemenCleanup) end
_G.OzemenRunning = false

local waitStart = os.clock()
while (getgenv().AnimeDiceConfig == nil and getgenv().OzemenConfig == nil) and (os.clock() - waitStart < 3) do
    task.wait(0.05)
end

local CFG = getgenv().AnimeDiceConfig or getgenv().OzemenConfig or {}
local function cfg(k, d) return (CFG[k] ~= nil) and CFG[k] or d end

local HAS_CONFIG = (type(CFG) == "table") and (next(CFG) ~= nil)
print("[Ozemen] ShowUI:", tostring(CFG.ShowUI), "| HasConfig:", HAS_CONFIG)

local MODE = "UI"
if HAS_CONFIG and CFG.ShowUI == false then MODE = "OVERLAY" end
print("[Ozemen] Mode:", MODE)

local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local CoreGui          = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local TeleportService  = game:GetService("TeleportService")
local VirtualUser      = game:GetService("VirtualUser")
local Lighting         = game:GetService("Lighting")

local LP = Players.LocalPlayer
local _conns = {}
_G.OzemenRunning = true

local httpRequest = (request or http_request or (syn and syn.request) or (http and http.request))

_G.OzemenCleanup = function()
    _G.OzemenRunning = false
    for _, c in ipairs(_conns) do pcall(function() c:Disconnect() end) end
    table.clear(_conns)
    if _G.OzemenWindow  then pcall(function() _G.OzemenWindow:Destroy()  end) end
    if _G.OzemenOverlay then pcall(function() _G.OzemenOverlay:Destroy() end) end
    if _G.OzemenMinGui  then pcall(function() _G.OzemenMinGui:Destroy()  end) end
end

local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

-- ═══════ NETWORK ═══════
local network = RS:WaitForChild("Network")
local RollService            = network:WaitForChild("RollService")
local PlotService            = network:WaitForChild("PlotService")
local RebirthService         = network:WaitForChild("RebirthService")
local DiceShopService        = network:WaitForChild("DiceShopService")
local DailyRewardService     = network:WaitForChild("DailyRewardService")
local GroupRewardService     = network:WaitForChild("GroupRewardService")
local OfflineEarningsService = network:WaitForChild("OfflineEarningsService")
local SpinService            = network:WaitForChild("SpinService")
local UpgradeServiceRE       = network:WaitForChild("RE"):WaitForChild("BuyUpgrade")

local TowerNetwork         = network:FindFirstChild("Towers")
local EquipBestTowerTeamRE = TowerNetwork and TowerNetwork:FindFirstChild("RE") and TowerNetwork.RE:FindFirstChild("EquipBestTowerTeam")
local PlayTowerRF          = TowerNetwork and TowerNetwork:FindFirstChild("RF") and TowerNetwork.RF:FindFirstChild("PlayTower")
local CancelTowerRF        = TowerNetwork and TowerNetwork:FindFirstChild("RF") and TowerNetwork.RF:FindFirstChild("CancelTower")

local GradeNetwork        = network:FindFirstChild("GradeService")
local SetGradeProtectedRE = GradeNetwork and GradeNetwork:FindFirstChild("RE") and GradeNetwork.RE:FindFirstChild("SetGradeProtected")
local RollGradeRE         = GradeNetwork and GradeNetwork:FindFirstChild("RE") and GradeNetwork.RE:FindFirstChild("Roll")

local SellNetwork      = network:FindFirstChild("SellService")
local SellInventoryRF  = SellNetwork and SellNetwork:FindFirstChild("RF") and SellNetwork.RF:FindFirstChild("SellInventory")
local UpdateAutoSellRE = SellNetwork and SellNetwork:FindFirstChild("RE") and SellNetwork.RE:FindFirstChild("UpdateAutoSell")

local QuestNetwork = network:FindFirstChild("QuestService")
local ClaimQuestRE = QuestNetwork and QuestNetwork:FindFirstChild("RE") and QuestNetwork.RE:FindFirstChild("Claim")
local BoostNetwork = network:FindFirstChild("BoostService")
local UseBoostRE   = BoostNetwork and BoostNetwork:FindFirstChild("RE") and BoostNetwork.RE:FindFirstChild("Use")

-- ═══════ MODULES ═══════
local function safeRequire(path)
    if not path then return nil end
    local ok, mod = pcall(function() return require(path) end)
    if ok then return mod end
    return nil
end

local DataController    = safeRequire(RS.Framework.Features.Data.DataController)
local BuffController    = safeRequire(RS.Framework.Features.Buffs.BuffController)
local UnitUtil          = safeRequire(RS.Framework.Features.Inventory.Kinds.Unit.UnitUtil)
local EntryRegistry     = safeRequire(RS.Framework.Features.Inventory.EntryRegistry)
local TreeStructure     = safeRequire(RS.Framework.Features.Upgrades.TreeStructure)
local RebirthsModule    = safeRequire(RS.Framework.Features.Rebirth.Rebirths)
local UpgradesModule    = safeRequire(RS.Framework.Features.Upgrades.Upgrades)
local DiceModule        = safeRequire(RS.Framework.Features.Rolling.Dice)
local GroupRewardConfig = safeRequire(RS.Framework.Features.Rewards.GroupRewardConfig)
local NumberFormatter   = safeRequire(RS.Packages.NumberFormatter)

if not NumberFormatter then
    NumberFormatter = {
        FormatCompact = function(n)
            n = tonumber(n) or 0
            if n >= 1e15 then return string.format("%.1fqa", n/1e15)
            elseif n >= 1e12 then return string.format("%.1ft", n/1e12)
            elseif n >= 1e9 then return string.format("%.1fb", n/1e9)
            elseif n >= 1e6 then return string.format("%.1fm", n/1e6)
            elseif n >= 1e3 then return string.format("%.1fk", n/1e3)
            else return tostring(math.floor(n)) end
        end
    }
end

local TowerController = safeRequire(RS.Framework.Features.Towers.TowerController)
local UIReferences    = safeRequire(RS.Framework.Features.UI.UIReferences)

print("[Ozemen] Modules: DC="..tostring(DataController~=nil).." Dice="..tostring(DiceModule~=nil))

-- ═══════ ACCESSORS ═══════
local function getX(key)
    if not DataController or not DataController.___X then return nil end
    return DataController.___X[key] or nil
end

local function callSignal(name)
    if not DataController or not DataController.___C then return nil end
    local sig = DataController.___C[name]
    if type(sig) ~= "table" then return nil end
    local mt = getmetatable(sig)
    if mt and type(mt.__call) == "function" then
        local ok, v = pcall(mt.__call, sig)
        if ok then return v end
    end
    return nil
end

-- ═══════ MAPPINGS ═══════
local UpgradeCategories = {
    ["Luck & Fortune"] = {"Luck", "Fortune"},
    ["Roll Speed"]     = {"Roll Speed"},
    ["Money"]          = {"Money"},
    ["Unit Storage"]   = {"Unit Storage"},
    ["Damage"]         = {"Damage"},
    ["Health"]         = {"Health"},
    ["Walkspeed"]      = {"Walkspeed"},
    ["Sell"]           = {"Sell"},
}
local function getCategoryOfKey(key)
    for cat, prefixes in pairs(UpgradeCategories) do
        for _, p in ipairs(prefixes) do
            if key:sub(1, #p) == p then return cat end
        end
    end
    return "Other"
end

local TowerOptions = {"auto","Dragon Tower","Cursed Tower","Pirate Tower","Hidden Leaf Tower","Infinity Tower"}
local GradeOrder  = {["D"]=1,["C"]=2,["B"]=3,["A"]=4,["A+"]=5,["S"]=6,["S+"]=7,["Z"]=8,["Z+"]=9,["神"]=10}
local RarityOrder = {["Common"]=1,["Uncommon"]=2,["Rare"]=3,["Epic"]=4,["Legendary"]=5,["Mythical"]=6,["Secret I"]=7,["Secret"]=7,["Exotic"]=8,["Celestial"]=9,["Divine"]=10,["Exclusive"]=11}

-- ══════════════════════════════════════════════════════════════════════════
--  ★★★ SMART TRASH SYSTEM v2.1 — FIXED
-- ══════════════════════════════════════════════════════════════════════════
local TrashTierOrder = {
    "Common","Uncommon","Rare","Epic","Legendary",
    "Mythical","Secret","Exotic","Celestial","Divine","Exclusive"
}
local TrashTierIndex = {}
for i, t in ipairs(TrashTierOrder) do TrashTierIndex[t] = i end

-- ★ เงินขั้นต่ำต่อ tier
local TrashTierMinMoney = {
    Common    = 0,
    Uncommon  = 1e6,
    Rare      = 1e8,
    Epic      = 1e10,
    Legendary = 1e11,
    Mythical  = 1e12,
    Secret    = 1e13,
    Exotic    = 1e14,
    Celestial = 1e15,
    Divine    = 1e16,
    Exclusive = 1e17,
}

-- ★ เงินสำหรับ Force Escalate (ไม่ต้องรอ count)
local TrashTierForceMoney = {
    Common    = 0,
    Uncommon  = 1e7,      -- 10M
    Rare      = 1e9,      -- 1B
    Epic      = 1e10,     -- 10B
    Legendary = 1e11,     -- 100B
    Mythical  = 1e12,     -- 1T
    Secret    = 1e13,     -- 10T
    Exotic    = 1e14,     -- 100T
    Celestial = 1e15,
    Divine    = 1e16,
    Exclusive = 1e17,
}

local TrashState = {
    currentTier  = "Common",
    currentIndex = 1,
    escalate     = true,
    upgradeAt    = cfg("TrashUpgradeAt", 5),   -- ★ ลดจาก 8 → 5
    lastCheck    = 0,
    startTier    = cfg("TrashStartTier", "Common"),
    lastRebirth  = 0,
}

local function countByRarity()
    local counts = {}
    local inv = DataController and DataController.Inventory and DataController.Inventory()
    if type(inv) ~= "table" then return counts end
    for id, unit in pairs(inv) do
        if type(unit) == "table" and unit.name and EntryRegistry then
            local c = EntryRegistry.getEntryConfig(unit.name)
            local rarity = (c and c.rarity) or "Unknown"
            counts[rarity] = (counts[rarity] or 0) + 1
        end
    end
    return counts
end

local function getStorageCount()
    local inv = DataController and DataController.Inventory and DataController.Inventory()
    if type(inv) ~= "table" then return 0 end
    local c = 0
    for id, unit in pairs(inv) do
        if type(unit) == "table" and unit.name and unit.attributes then c = c + 1 end
    end
    return c
end

local function checkRebirthReset()
    if not DataController then return end
    local curRebirth = DataController.Rebirth() or 0
    if curRebirth > TrashState.lastRebirth then
        TrashState.lastRebirth = curRebirth
        TrashState.currentIndex = TrashTierIndex[TrashState.startTier] or 1
        TrashState.currentTier  = TrashState.startTier
        print("[Trash] 🔄 Rebirth ใหม่ → Reset tier เป็น "..TrashState.startTier)
    end
end

-- ★★★ FIXED — ไต่ข้ามได้ ไม่ break
local function checkTrashEscalate()
    if not TrashState.escalate then return end
    if os.clock() - TrashState.lastCheck < 15 then return end
    TrashState.lastCheck = os.clock()

    checkRebirthReset()

    local counts = countByRarity()
    local money  = getX("Money") or 0

    local newIdx = TrashState.currentIndex

    -- ★ หา tier สูงสุดที่ไต่ได้ (จาก count)
    for i = TrashState.currentIndex + 1, #TrashTierOrder do
        local tname    = TrashTierOrder[i]
        local cnt      = counts[tname] or 0
        local minMoney = TrashTierMinMoney[tname] or 0

        if cnt >= TrashState.upgradeAt and money >= minMoney then
            newIdx = i  -- ผ่าน — จำไว้ แล้วเช็ค tier ถัดไปต่อ (ไม่ break!)
        end
        -- ★ ถ้าไม่ผ่าน → continue ตรวจต่อ (ไม่ break)
    end

    -- ★ Force Escalate — ถ้าเงินเยอะมาก ไม่ต้องรอ count
    for i = TrashState.currentIndex + 1, #TrashTierOrder do
        local tname     = TrashTierOrder[i]
        local forceMin  = TrashTierForceMoney[tname] or math.huge
        if money >= forceMin then
            if i > newIdx then newIdx = i end
        end
    end

    if newIdx > TrashState.currentIndex then
        local old = TrashState.currentTier
        TrashState.currentIndex = newIdx
        TrashState.currentTier  = TrashTierOrder[newIdx] or "Common"
        print(string.format("[Trash] ⬆️ ไต่ tier: %s → %s (เงิน $%s)",
            old, TrashState.currentTier,
            NumberFormatter.FormatCompact(money)))
    end
end

-- ★★★ Smart Sell
local function sellSelectedUnits()
    local sold, earned = 0, 0
    pcall(function()
        if not SellInventoryRF or not DataController then return end
        local inv = DataController.Inventory and DataController.Inventory()
        if not inv then return end

        checkTrashEscalate()

        local storageUsed = getStorageCount()
        -- ★ Safety: ห้ามขายถ้าคลังเหลือ < 20
        if storageUsed < 20 then return end

        local plotted = {}
        for slot = 1, 14 do
            local s = DataController.Slots[tostring(slot)] and DataController.Slots[tostring(slot)]()
            if s and s.unitId then plotted[s.unitId] = true end
        end
        local towerTeam = {}
        if DataController.TowerTeam then
            local tt = DataController.TowerTeam()
            if type(tt)=="table" then
                for _, uid in pairs(tt) do if type(uid)=="string" then towerTeam[uid]=true end end
            end
        end

        local keepIncome = State.SellKeepIncome or 0
        local currentIdx = TrashState.currentIndex

        local toSell = {}
        local breakdown = {}

        for id, unit in pairs(inv) do
            if type(unit)=="table" and unit.name and unit.attributes then
                local canSell = true

                if State.ProtectPlottedUnits and (plotted[id] or towerTeam[id]) then canSell = false end
                if State.ProtectLockedUnits and unit.attributes.locked then canSell = false end
                if State.ProtectGradeSPlus and unit.attributes.grade then
                    if (GradeOrder[unit.attributes.grade] or 0) >= 6 then canSell = false end
                end
                if keepIncome > 0 then
                    local inc = tonumber(unit.attributes.income) or 0
                    if inc >= keepIncome then canSell = false end
                end

                local rarity = "Unknown"
                if EntryRegistry then
                    local c = EntryRegistry.getEntryConfig(unit.name)
                    rarity = (c and c.rarity) or "Unknown"
                end
                if rarity == "Divine" or rarity == "Exclusive" then canSell = false end

                local unitIdx = TrashTierIndex[rarity] or 0
                local income = tonumber(unit.attributes.income) or 0
                if income >= 1e8 then canSell = false end  -- 100M/s ห้ามขาย

                if canSell then
                    local shouldSell = false
                    if State.AutoFilterTrash then
                        if unitIdx > 0 and unitIdx < currentIdx then shouldSell = true end
                    else
                        for sel, isSel in pairs(State.SelectedSellRarities) do
                            if isSel and (sel == rarity or string.find(sel, rarity, 1, true)) then
                                shouldSell = true; break
                            end
                        end
                    end

                    if shouldSell then
                        table.insert(toSell, id)
                        breakdown[rarity] = (breakdown[rarity] or 0) + 1
                        if #toSell >= 50 then break end
                    end
                end
            end
        end

        if #toSell > 0 then
            local r1, r2 = SellInventoryRF:InvokeServer(toSell)
            earned = r1 or 0
            sold = r2 or #toSell
            local parts = {}
            for r, c in pairs(breakdown) do table.insert(parts, r.."×"..c) end
            print(string.format("[Trash] 🗑️ ขาย %d ตัว (เก็บ %s+): %s → $%s",
                sold, TrashState.currentTier, table.concat(parts, ", "),
                NumberFormatter.FormatCompact(earned)))
        end
    end)
    return sold, earned
end

-- ★★★ EMERGENCY SELL — ขายเมื่อ storage เกิน
local function emergencySell()
    pcall(function()
        if not SellInventoryRF or not DataController then return end

        local storageUsed = getStorageCount()
        -- ★ Dynamic storage max (buff) — fallback 150
        local maxStorage = 150
        pcall(function()
            if BuffController and BuffController.GetBuff then
                local s = BuffController.GetBuff("Unit Storage")
                if type(s) == "number" and s > 0 then maxStorage = s end
            end
        end)
        if storageUsed < maxStorage - 2 then return end  -- ★ เกินหรือใกล้เกิน

        print(string.format("[Trash] 🚨 Storage %d/%d — Emergency Sell!", storageUsed, maxStorage))

        local inv = DataController.Inventory and DataController.Inventory()
        if not inv then return end

        local plotted = {}
        for slot = 1, 14 do
            local s = DataController.Slots[tostring(slot)] and DataController.Slots[tostring(slot)]()
            if s and s.unitId then plotted[s.unitId] = true end
        end

        local toSell = {}
        for id, unit in pairs(inv) do
            if type(unit) == "table" and unit.name and unit.attributes then
                if not plotted[id] and not unit.attributes.locked then
                    local grade = unit.attributes.grade or "D"
                    local rarity = "Unknown"
                    if EntryRegistry then
                        local c = EntryRegistry.getEntryConfig(unit.name)
                        rarity = (c and c.rarity) or "Unknown"
                    end
                    -- ★ ขายพวกเกรดต่ำ + rarity ต่ำ
                    local gOrder = GradeOrder[grade] or 1
                    local rOrder = RarityOrder[rarity] or 0
                    if gOrder < 5 and rOrder <= 4 then  -- เกรดต่ำกว่า A+ และ rarity ≤ Epic
                        table.insert(toSell, id)
                        if #toSell >= 50 then break end
                    end
                end
            end
        end

        if #toSell > 0 then
            SellInventoryRF:InvokeServer(toSell)
            print("[Trash] 🚨 Emergency ขาย "..#toSell.." ตัว")
        end
    end)
end

-- ═══════ STATE ═══════
local State = {
    AntiAFK = cfg("AntiAFK", true),
    FpsBoost = cfg("FpsBoost", true),
    UltraFpsBoost = cfg("UltraFpsBoost", false),
    HideCutscene = cfg("HideCutscene", true),

    AutoRoll = cfg("AutoRoll", true),
    AutoCollect = cfg("AutoCollect", true),
    CollectInterval = cfg("CollectInterval", 0.5),
    AutoEquipBest = cfg("AutoEquipBest", true),
    EquipInterval = 3.0,
    AutoLevelSlots = cfg("AutoLevelUnit", true),
    TargetUnitLevel = cfg("MaxUnitLevel", 20),

    AutoRebirth = cfg("AutoRebirth", true),
    TargetRebirth = cfg("RebirthTarget", 999),
    AutoUpgrades = cfg("AutoUpgrade", true),
    AutoBuyDice = cfg("AutoDice", true),
    AutoClaim = cfg("AutoReward", true),
    AutoQuest = cfg("AutoQuest", true),
    AutoBoost = cfg("AutoBoost", true),
    SelectedUpgradeCategories = { ["Luck & Fortune"]=true, ["Roll Speed"]=true, ["Money"]=true },

    AutoSellUnits = cfg("AutoSell", true),
    AutoFilterTrash = cfg("AutoFilterTrash", true),
    SellInterval = 5,
    SellKeepBuffer = cfg("SellKeepBuffer", 6),
    SellKeepIncome = cfg("SellKeepIncome", 1e6),
    SelectedSellRarities = { ["Common"]=true, ["Uncommon"]=true, ["Rare"]=true },
    ProtectPlottedUnits = true,
    ProtectGradeSPlus = true,
    ProtectLockedUnits = true,

    AutoRerollGrade = false,
    TargetGradeUnitKey = "",
    TargetGrade = "S",
    GradeRollDelay = 0.35,

    WebhookURL = cfg("WebhookURL", ""),
    WebhookEnabled = cfg("WebhookEnabled", false),

    AutoTower = cfg("AutoTower", true),
    SelectedTower = cfg("TowerMode", "auto"),
    HideTowerScreen = true,

    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false,
    Noclip = false,

    AutoTrade = cfg("AutoTrade", false),
    TradeHost = cfg("TradeHost", {}),
    TradeSendMode = cfg("TradeSendMode", "none"),

    SessionStart = os.clock(),
    TowerFloorsDone = 0,
}

-- ═══════ CORE LOGIC ═══════
local function collectAllSlots()
    pcall(function()
        for slot = 1, 14 do PlotService.RE.CollectBalance:FireServer(slot) end
    end)
end

local function equipBestUnits()
    pcall(function() PlotService.RE.EquipBest:FireServer() end)
end

local function levelUpAllSlots()
    pcall(function()
        if not DataController then return end
        local curMoney = DataController.Money and DataController.Money()
        if not curMoney or curMoney <= 0 then return end
        local targetLvl = tonumber(State.TargetUnitLevel) or 20
        for slot = 1, 14 do
            local slotData = DataController.Slots[tostring(slot)] and DataController.Slots[tostring(slot)]()
            if slotData and slotData.unitId then
                local unitData = DataController.Inventory[slotData.unitId] and DataController.Inventory[slotData.unitId]()
                if unitData and UnitUtil and UnitUtil.GetLevelPrice then
                    local curLvl = (unitData.attributes and unitData.attributes.level) or 1
                    if curLvl < targetLvl then
                        local price = UnitUtil.GetLevelPrice(unitData.name, unitData.attributes)
                        if price and curMoney >= price then
                            curMoney = curMoney - price
                            PlotService.RE.LevelUpSlot:FireServer(slot)
                        end
                    end
                end
            end
        end
    end)
end

local function checkAndRebirth()
    pcall(function()
        if not DataController or not RebirthsModule then return end
        local cur = DataController.Rebirth()
        local target = tonumber(State.TargetRebirth) or 999
        if cur >= target then return end
        local money = DataController.Money()
        local nextData = RebirthsModule.GetNext(cur)
        if nextData and nextData.cost and money >= nextData.cost then
            RebirthService.RE.Rebirth:FireServer()
        end
    end)
end

local function rollGradeForSelectedUnit()
    local ok = false
    pcall(function()
        if not RollGradeRE or not State.TargetGradeUnitKey or State.TargetGradeUnitKey=="" then return end
        if not DataController then return end
        local inv = DataController.Inventory
        if not inv then return end
        local unit = inv[State.TargetGradeUnitKey] and inv[State.TargetGradeUnitKey]()
        if not unit or not unit.attributes then return end
        local cur = GradeOrder[unit.attributes.grade or "D"] or 1
        local tgt = GradeOrder[State.TargetGrade] or 6
        if cur >= tgt then return end
        RollGradeRE:FireServer(State.TargetGradeUnitKey, true)
        ok = true
    end)
    return ok
end

local function buyPrioritizedUpgrades()
    pcall(function()
        if not UpgradesModule or not TreeStructure or not DataController then return end
        local money = DataController.Money()
        if not money or money <= 0 then return end
        local avail = {}
        for key, data in pairs(UpgradesModule) do
            local owned = DataController.Upgrades[key] and DataController.Upgrades[key]()
            if not owned then
                local parent = TreeStructure.GetParent(key)
                local unlocked = (not parent or parent=="Start") or (DataController.Upgrades[parent] and DataController.Upgrades[parent]())
                if unlocked and data.price and money >= data.price then
                    table.insert(avail, {key=key, price=data.price, cat=getCategoryOfKey(key)})
                end
            end
        end
        if #avail == 0 then return end
        local focus, other = {}, {}
        for _, i in ipairs(avail) do
            if State.SelectedUpgradeCategories[i.cat] then table.insert(focus, i)
            else table.insert(other, i) end
        end
        table.sort(focus, function(a,b) return a.price < b.price end)
        table.sort(other, function(a,b) return a.price < b.price end)
        for _, i in ipairs(focus) do
            if money >= i.price then
                money = money - i.price
                UpgradeServiceRE:FireServer(i.key)
                task.wait(0.12)
            end
        end
        for _, i in ipairs(other) do
            if money >= i.price then
                money = money - i.price
                UpgradeServiceRE:FireServer(i.key)
                task.wait(0.12)
            end
        end
    end)
end

local function buyAffordableDice()
    pcall(function()
        if not DiceModule or not DataController then return end
        local all = DiceModule.GetAll()
        local money = DataController.Money()
        for name, data in pairs(all) do
            local owned = DataController.OwnedDice[name] and DataController.OwnedDice[name]()
            if not owned and data.price and data.price <= money then
                DiceShopService.RE.BuyDice:FireServer(name)
                task.wait(0.4)
            end
        end
    end)
end

local function claimAllFreebies()
    pcall(function()
        DailyRewardService.RE.Claim:FireServer()
        OfflineEarningsService.RE.Claim:FireServer()
        SpinService.RE.Use:FireServer()
        if GroupRewardConfig and GroupRewardConfig.GroupId and DataController then
            local inGroup = false
            pcall(function() inGroup = LP:IsInGroup(GroupRewardConfig.GroupId) end)
            if inGroup and DataController.ClaimedGroupReward and not DataController.ClaimedGroupReward() then
                GroupRewardService.RE.Claim:FireServer()
            end
        end
    end)
end

-- ★ Boost — ตรวจจาก attributes.kind เท่านั้น
local function autoUseBoosts()
    pcall(function()
        if not State.AutoBoost then return end
        if not DataController or not UseBoostRE then return end

        local inv = DataController.Inventory and DataController.Inventory()
        if type(inv) ~= "table" then return end

        local byCategory = {}
        for id, item in pairs(inv) do
            if type(item) == "table" and item.attributes and item.name then
                local kind = item.attributes.kind
                -- ★ เข้มงวด: kind ต้องเป็น Boost เท่านั้น
                if kind == "Boost" or kind == "boost" then
                    local cat = item.attributes.category or "Unknown"
                    local tier = item.attributes.tier or 0
                    if not byCategory[cat] or tier > byCategory[cat].tier then
                        byCategory[cat] = { id = id, tier = tier, name = item.name }
                    end
                end
            end
        end

        for cat, info in pairs(byCategory) do
            UseBoostRE:FireServer(info.id)
            task.wait(0.15)
        end
    end)
end

-- ★ Quest
local claimedQuests = {}
local function autoClaimQuests()
    pcall(function()
        if not State.AutoQuest then return end
        if not ClaimQuestRE then return end
        for _, qname in ipairs({"Playtime","Rolls","Towers","UnitsSold"}) do
            local key = qname .. "_" .. math.floor(os.time() / 60)
            if not claimedQuests[key] then
                pcall(function() ClaimQuestRE:FireServer(qname) end)
                claimedQuests[key] = true
                task.wait(0.15)
            end
        end
    end)
end

local function hideCutscene()
    pcall(function()
        if not State.HideCutscene then return end
        local pg = LP:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, name in ipairs({"Cutscene","RollCutscene","AnimationScreen","RollAnimation","CutsceneGui"}) do
            local s = pg:FindFirstChild(name)
            if s and s:IsA("ScreenGui") then s.Enabled = false end
        end
    end)
end

local function resolveAutoTower()
    local money = 0
    pcall(function() if DataController then money = DataController.Money() or 0 end end)
    if money >= 1e12 then return "Infinity Tower"
    elseif money >= 1e9 then return "Pirate Tower"
    elseif money >= 1e6 then return "Cursed Tower"
    else return "Dragon Tower" end
end

local function handleAutoTower()
    pcall(function()
        if not State.AutoTower then return end
        local screen = UIReferences and UIReferences.Root and UIReferences.Root.Tower and UIReferences.Root.Tower.Screen
        local hidden = screen and screen.Parent and screen.Parent:FindFirstChild("Hidden")
        local inTower = (hidden and hidden.Visible) or (screen and screen.Visible)
        if inTower then
            if State.HideTowerScreen and screen and screen.Visible and hidden and firesignal then
                pcall(function() firesignal(hidden.Activated) end)
            end
            if screen and screen:FindFirstChild("Buttons") and screen.Buttons:FindFirstChild("Auto") then
                local btn = screen.Buttons.Auto
                local grad = btn:FindFirstChildOfClass("UIGradient")
                local isGreen = grad and tostring(grad.Color):find("0.298")
                if not isGreen and firesignal then pcall(function() firesignal(btn.Activated) end) end
            end
            State.TowerFloorsDone = State.TowerFloorsDone + 1
        else
            if EquipBestTowerTeamRE then
                pcall(function() EquipBestTowerTeamRE:FireServer() end); task.wait(0.3)
            end
            local target = State.SelectedTower or "auto"
            if target == "auto" then target = resolveAutoTower() end
            local started = false
            if TowerController and TowerController.startTower then started = TowerController.startTower(target) end
            if not started and PlayTowerRF then PlayTowerRF:InvokeServer(target) end
            task.wait(1.2)
            if State.HideTowerScreen and screen and screen.Visible and hidden and firesignal then
                pcall(function() firesignal(hidden.Activated) end)
            end
        end
    end)
end

function sendDiscordWebhook(title, desc, color, fields)
    if not State.WebhookEnabled or State.WebhookURL == "" or not httpRequest then return end
    task.spawn(function()
        pcall(function()
            local payload = {
                username = "Ozemen Hub | Anime Dice",
                embeds = {{
                    title = title, description = desc, color = color or 0x00FFE0,
                    fields = fields or {}, footer = {text = "Ozemen Hub • "..os.date("%X")},
                    timestamp = DateTime.now():ToIsoDate()
                }}
            }
            httpRequest({Url=State.WebhookURL, Method="POST",
                Headers={["Content-Type"]="application/json"},
                Body=HttpService:JSONEncode(payload)})
        end)
    end)
end

-- ═══════ ANTI-AFK ═══════
local function neutralizeGameAFK()
    pcall(function()
        local afk = LP.PlayerScripts:FindFirstChild("AFK")
        if afk then afk.Disabled = true; afk:Destroy() end
    end)
end
neutralizeGameAFK()

table.insert(_conns, LP.PlayerScripts.ChildAdded:Connect(function(child)
    if child.Name=="AFK" and child:IsA("LocalScript") then
        pcall(function() child.Disabled=true; child:Destroy() end)
    end
end))

pcall(function()
    if getconnections then
        for _, c in ipairs(getconnections(LP.Idled)) do pcall(function() c:Disable() end) end
    end
end)

table.insert(_conns, LP.Idled:Connect(function()
    if not State.AntiAFK then return end
    pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.zero) end)
end))

task.spawn(function()
    while _G.OzemenRunning do
        task.wait(40)
        if State.AntiAFK then
            pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.zero) end)
            neutralizeGameAFK()
        end
    end
end)

-- ═══════ FPS BOOST — FIXED ═══════
local function applyFpsBoost()
    if not State.FpsBoost then return end
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function()
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") then
                effect.Enabled = false
            end
        end
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                -- ★ FIX: skip เฉพาะ character ของเรา
                if LP.Character and obj:IsDescendantOf(LP.Character) then
                    -- skip — ตัวเรา
                else
                    obj.CastShadow = false
                end
            end
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = false
            end
        end
    end)
end
applyFpsBoost()

-- ═══════ ULTRA FPS BOOST — ลบทุกอย่างเหลือแค่ Plot ═══════
-- ลบ/ซ่อนทุกอย่างใน workspace ยกเว้น Plots + ตัวเรา เพื่อ FPS แบบขั้นสุด
local function isOurPlotModel(child)
    -- เช็คว่าเป็น plot เราจริงไหม (กันลบเพลตตัวเอง)
    local mine = false
    pcall(function()
        local ownerAttr = child:GetAttribute("Owner")
        if ownerAttr ~= nil then
            mine = tostring(ownerAttr) == tostring(LP.Name)
        end
    end)
    if mine then return true end
    local ownerLbl = child:FindFirstChild("OwnerName") or child:FindFirstChild("Owner")
    return ownerLbl and tostring(ownerLbl.Value) == tostring(LP.Name)
end

local function hideInstanceUltra(inst)
    pcall(function()
        if inst:IsA("Model") then
            for _, part in ipairs(inst:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                    part.CanCollide = false
                    part.CanQuery = false
                    part.CastShadow = false
                elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") or part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") then
                    part.Enabled = false
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    pcall(function() part.Transparency = 1 end)
                end
            end
        elseif inst:IsA("BasePart") then
            inst.Transparency = 1
            inst.CanCollide = false
            inst.CanQuery = false
            inst.CastShadow = false
        elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
            inst.Enabled = false
        end
    end)
end

local function ultraFpsBoost()
    if not State.UltraFpsBoost then return end
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function()
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then effect.Enabled = false end
        end
        if Lighting:FindFirstChildOfClass("Atmosphere") then Lighting:FindFirstChildOfClass("Atmosphere").Enabled = false end
        if Lighting:FindFirstChildOfClass("Sky") then Lighting:FindFirstChildOfClass("Sky").Parent = nil end
    end)
    pcall(function()
        if workspace:FindFirstChildOfClass("Terrain") then
            workspace:FindFirstChildOfClass("Terrain").WaterWaveSize = 0
            workspace:FindFirstChildOfClass("Terrain").WaterWaveSpeed = 0
            workspace:FindFirstChildOfClass("Terrain").WaterTransparency = 1
        end
    end)
end

-- nuke ทั้งหมด ยกเว้น Terrain + Plots (ลบผู้เล่นอื่น/โมเดลขยะ + ซ่อนของใน Folder แมพ)
local function ultraNukeAll()
    if not State.UltraFpsBoost then return end
    pcall(function()
        for _, child in ipairs(workspace:GetChildren()) do
            local keep = child == workspace.Terrain or child.Name == "Plots"
            if not keep then
                local isOurs = LP.Character and (child == LP.Character or child:IsDescendantOf(LP.Character))
                if isOurs then
                    -- ตัวเรา — ข้าม
                elseif child:IsA("Model") then
                    pcall(function() child:Destroy() end)
                elseif child:IsA("Folder") then
                    -- ซ่อนทุกอย่างใน folder แมพ (Map, Players, Leaderboards, ...)
                    for _, part in ipairs(child:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                            part.CanCollide = false
                            part.CanQuery = false
                            part.CastShadow = false
                        elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") or part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") then
                            part.Enabled = false
                        elseif part:IsA("Decal") or part:IsA("Texture") then
                            pcall(function() part.Transparency = 1 end)
                        end
                    end
                elseif child:IsA("BasePart") then
                    child.Transparency = 1
                    child.CanCollide = false
                    child.CastShadow = false
                end
            end
        end
    end)
end

-- วนลบ/ซ่อนของใหม่ที่โผล่เข้ามาเรื่อยๆ + ซ่อน plot คนอื่น (กัน FPS drop)
task.spawn(function()
    while _G.OzemenRunning do
        if State.UltraFpsBoost then
            ultraFpsBoost()
            ultraNukeAll()
            pcall(function()
                local plots = workspace:FindFirstChild("Plots")
                if plots then
                    for _, sub in ipairs(plots:GetChildren()) do
                        if sub:IsA("Model") and not isOurPlotModel(sub) then
                            hideInstanceUltra(sub)
                        end
                    end
                end
            end)
        end
        task.wait(5)
    end
end)

-- ═══════ AUTOMATION THREADS ═══════
task.spawn(function()
    while _G.OzemenRunning do
        if State.AutoCollect then collectAllSlots() end
        task.wait(math.max(State.CollectInterval or 0.5, 0.1))
    end
end)

task.spawn(function()
    while _G.OzemenRunning do
        if State.AutoEquipBest then equipBestUnits() end
        task.wait(math.max(State.EquipInterval or 3, 1))
    end
end)

task.spawn(function()
    while _G.OzemenRunning do
        task.wait(0.7)
        if State.AutoLevelSlots then levelUpAllSlots() end
    end
end)

task.spawn(function()
    local lastRoll = 0
    while _G.OzemenRunning do
        task.wait(0.1)
        if State.AutoRoll then
            pcall(function()
                if DataController and not DataController.AutoRoll() then
                    RollService.RE.SetAutoRoll:FireServer(true)
                end
            end)
            local dur = 1.9
            pcall(function()
                if BuffController and BuffController.GetBuff then
                    local d = BuffController.GetBuff("Roll Duration")
                    if type(d)=="number" and d>0 then dur = d end
                end
            end)
            if os.clock()-lastRoll >= dur+0.1 then
                lastRoll = os.clock()
                pcall(function() RollService.RF.RollDice:InvokeServer() end)
            end
        else
            pcall(function()
                if DataController and DataController.AutoRoll() then
                    RollService.RE.SetAutoRoll:FireServer(false)
                end
            end)
        end
    end
end)

task.spawn(function()
    while _G.OzemenRunning do
        task.wait(1.5)
        if State.AutoRebirth then checkAndRebirth() end
        if State.AutoUpgrades then buyPrioritizedUpgrades() end
        if State.AutoBuyDice then buyAffordableDice() end
        if State.AutoClaim then claimAllFreebies() end
    end
end)

task.spawn(function()
    while _G.OzemenRunning do
        task.wait(1.5)
        if State.AutoTower then handleAutoTower() end
    end
end)

-- ★ Auto Sell + Emergency
task.spawn(function()
    while _G.OzemenRunning do
        task.wait(math.max(State.SellInterval or 5, 1))
        if State.AutoSellUnits then
            pcall(sellSelectedUnits)
            pcall(emergencySell)  -- ★ Emergency ทุกครั้ง
        end
    end
end)

task.spawn(function()
    while _G.OzemenRunning do
        task.wait(State.GradeRollDelay or 0.35)
        if State.AutoRerollGrade then
            if not rollGradeForSelectedUnit() then State.AutoRerollGrade = false end
        end
    end
end)

-- ★ Boost — 30 วิ (ไม่ spam)
task.spawn(function()
    task.wait(10)
    while _G.OzemenRunning do
        if State.AutoBoost then autoUseBoosts() end
        task.wait(30)
    end
end)

-- ★ Quest — 15 วิ
task.spawn(function()
    task.wait(3)
    while _G.OzemenRunning do
        if State.AutoQuest then autoClaimQuests() end
        task.wait(15)
    end
end)

task.spawn(function()
    while _G.OzemenRunning do
        hideCutscene()
        task.wait(0.5)
    end
end)

-- ★ Trash Escalate — 15 วิ
task.spawn(function()
    while _G.OzemenRunning do
        checkTrashEscalate()
        task.wait(15)
    end
end)

-- ═══════ AUTO TRADE ═══════
task.spawn(function()
    while _G.OzemenRunning do
        task.wait(5)
        if State.AutoTrade and State.TradeSendMode ~= "none" then
            pcall(function()
                local hosts = State.TradeHost
                if type(hosts)=="string" then hosts = {hosts} end
                if type(hosts) ~= "table" or #hosts == 0 then return end
                local target = nil
                for _, h in ipairs(hosts) do
                    local plr = Players:FindFirstChild(tostring(h))
                    if plr then target = plr; break end
                end
                if not target then return end
                local TS = network:FindFirstChild("TradeService")
                if not TS then return end
                local SendRE = TS:FindFirstChild("RE") and TS.RE:FindFirstChild("Send")
                if not SendRE then return end
                local toSend = {}
                local inv = DataController and DataController.Inventory and DataController.Inventory()
                if type(inv) ~= "table" then return end
                if State.TradeSendMode == "all" then
                    for id in pairs(inv) do table.insert(toSend, id) end
                elseif State.TradeSendMode == "keep_slotted" then
                    local slotted = {}
                    for s=1,14 do
                        local sd = DataController.Slots[tostring(s)] and DataController.Slots[tostring(s)]()
                        if sd and sd.unitId then slotted[sd.unitId]=true end
                    end
                    for id in pairs(inv) do
                        if not slotted[id] then table.insert(toSend, id) end
                    end
                end
                if #toSend > 0 then SendRE:FireServer(target, toSend) end
            end)
        end
    end
end)

-- ═══════ MOVEMENT ═══════
table.insert(_conns, RunService.Stepped:Connect(function()
    if not _G.OzemenRunning then return end
    local char = LP.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.WalkSpeed ~= State.WalkSpeed and State.WalkSpeed > 16 then hum.WalkSpeed = State.WalkSpeed end
        if hum.JumpPower ~= State.JumpPower and State.JumpPower > 50 then hum.JumpPower = State.JumpPower end
    end
    if State.Noclip then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
end))

table.insert(_conns, UserInputService.JumpRequest:Connect(function()
    if State.InfJump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- ══════════════════════════════════════════════════════════════════════════
--  OVERLAY (MODE = "OVERLAY")
-- ══════════════════════════════════════════════════════════════════════════
local overlayGui, panel, overlay = nil, nil, nil

if MODE == "OVERLAY" then
    local function getGuiContainer()
        if gethui then
            local ok, hui = pcall(gethui)
            if ok and hui then return hui end
        end
        local ok, cg = pcall(function() return CoreGui end)
        if ok and cg then return cg end
        return LP:WaitForChild("PlayerGui")
    end

    overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "OzemenOverlay"
    overlayGui.ResetOnSpawn = false
    overlayGui.IgnoreGuiInset = true
    overlayGui.Parent = getGuiContainer()
    _G.OzemenOverlay = overlayGui

    panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.Size = UDim2.new(0, 700, 0, 400)
    panel.BackgroundTransparency = 1
    panel.Parent = overlayGui

    overlay = Instance.new("TextLabel")
    overlay.Name = "Text"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundTransparency = 1
    overlay.RichText = true
    overlay.TextXAlignment = Enum.TextXAlignment.Center
    overlay.TextYAlignment = Enum.TextYAlignment.Center
    overlay.Font = Enum.Font.GothamBlack
    overlay.TextSize = 22
    overlay.TextColor3 = Color3.fromRGB(255, 255, 255)
    overlay.TextStrokeTransparency = 0.35
    overlay.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    overlay.Text = ""
    overlay.Visible = true
    overlay.Parent = panel

    local function formatTime(sec)
        local h = math.floor(sec / 3600)
        local m = math.floor((sec % 3600) / 60)
        local s = math.floor(sec % 60)
        return string.format("%02d:%02d:%02d", h, m, s)
    end

    local function getTraitReroll()
        local inv = getX("Inventory")
        if type(inv) ~= "table" then return 0 end
        local item = inv["Trait Reroll"]
        if type(item) == "table" then return item.amount or 1 end
        return 0
    end

    local function getGems()
        local inv = getX("Inventory")
        if type(inv) ~= "table" then return 0 end
        local item = inv["Gems"]
        if type(item) == "table" then return item.amount or 0 end
        return 0
    end

    local function getBaseIncome()
        local total = 0
        pcall(function()
            local plots = workspace:FindFirstChild("Plots")
            if not plots then return end
            local claimed = plots:FindFirstChild("Claimed")
            if not claimed then return end
            for _, plot in ipairs(claimed:GetChildren()) do
                local slots = plot:FindFirstChild("Slots")
                if slots then
                    for _, slot in ipairs(slots:GetChildren()) do
                        for _, unit in ipairs(slot:GetChildren()) do
                            local hrp = unit:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local info = hrp:FindFirstChild("Info")
                                if info then
                                    local unitInfo = info:FindFirstChild("UnitInfo")
                                    if unitInfo then
                                        local incomeLbl = unitInfo:FindFirstChild("Income")
                                        if incomeLbl and incomeLbl:IsA("TextLabel") then
                                            local txt = incomeLbl.Text or ""
                                            local val, suffix = txt:match("%$(%d+%.?%d*)([kKmMbBtTqQ]?)%s*/%s*s")
                                            if val then
                                                local num = tonumber(val) or 0
                                                suffix = (suffix or ""):lower()
                                                local mult = 1
                                                if suffix == "k" then mult = 1e3
                                                elseif suffix == "m" then mult = 1e6
                                                elseif suffix == "b" then mult = 1e9
                                                elseif suffix == "t" then mult = 1e12
                                                elseif suffix == "q" then mult = 1e15
                                                end
                                                total = total + (num * mult)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        return total
    end

    local cachedFloor = "?"
    local function getTowerFloor()
        pcall(function()
            local pg = LP:FindFirstChild("PlayerGui")
            if not pg then return end
            local root = pg:FindFirstChild("Root")
            if not root then return end
            local tower = root:FindFirstChild("Tower")
            if not tower then return end
            local screen = tower:FindFirstChild("Screen")
            if not screen then return end
            local floorLbl = screen:FindFirstChild("Floor")
            if floorLbl and floorLbl:IsA("TextLabel") then
                local num = floorLbl.Text:match("(%d+)")
                if num then cachedFloor = num; return end
            end
            local labelLbl = screen:FindFirstChild("Label")
            if labelLbl and labelLbl:IsA("TextLabel") then
                local num = labelLbl.Text:match("(%d+)")
                if num then cachedFloor = num; return end
            end
        end)
        return cachedFloor
    end

    local function resolveAutoTowerName()
        local mode = State.SelectedTower or "auto"
        if mode == "auto" then return resolveAutoTower() end
        return mode
    end

    -- ★ Overlay update — 1.5 วิ (ลด CPU)
    task.spawn(function()
        while _G.OzemenRunning do
            task.wait(1.5)
            if overlay.Visible then
                pcall(function()
                    local money    = getX("Money") or 0
                    local rebirth  = getX("Rebirth") or 0
                    local dice     = getX("Dice") or "Default"
                    local rolls    = getX("Rolls") or 0
                    local unitCount = getStorageCount()
                    local traitReroll = getTraitReroll()
                    local gems = getGems()
                    local income = getBaseIncome()
                    local floor = getTowerFloor()
                    local towerName = resolveAutoTowerName()
                    local runtime = formatTime(os.clock() - (State.SessionStart or 0))

                    local maxStorage = 150
                    pcall(function()
                        if BuffController and BuffController.GetBuff then
                            local s = BuffController.GetBuff("Unit Storage")
                            if type(s) == "number" and s > 0 then maxStorage = s end
                        end
                    end)

                    local moneyStr   = "$" .. NumberFormatter.FormatCompact(money)
                    local incomeStr  = "$" .. NumberFormatter.FormatCompact(income) .. "/s"

                    local tradeStatus = "ปิด"
                    if State.AutoTrade and #(State.TradeHost or {}) > 0 then
                        tradeStatus = "→ " .. table.concat(State.TradeHost, ", ")
                    end

                    local towerDisplay
                    if State.AutoTower then
                        local tName = towerName:gsub(" Tower","")
                        if floor ~= "?" then
                            towerDisplay = tName .. " • ชั้น " .. floor
                        else
                            towerDisplay = tName .. " • รอเริ่ม"
                        end
                    else
                        towerDisplay = "ไม่ฟาร์ม"
                    end

                    overlay.Text = string.format(
                        "<font size='34' color='#FFD54A'>Ozemen Hub</font>\n"..
                        "<font size='20' color='#00E5FF'>Status: กำลังฟาร์ม | รันมา %s</font>\n"..
                        "\n"..
                        "💰 เงินในตัว: <font color='#00FF88'>%s</font>\n"..
                        "📈 รายได้รวม: <font color='#00FF88'>%s</font>\n"..
                        "💎 เพชร: <font color='#FF7AD9'>%d</font>   🎫 Trait Reroll: <font color='#FFD700'>%d</font>\n"..
                        "🔄 Rebirth: <font color='#FFD700'>%d</font>   🎯 เต๋า: <font color='#00E5FF'>%s</font>\n"..
                        "🗼 Tower: <font color='#A0E7FF'>%s</font>\n"..
                        "📦 Storage: <font color='#FF7AD9'>%d / %d</font>\n"..
                        "🎰 Rolls: <font color='#FFD700'>%d</font>\n"..
                        "🤝 Trade: <font color='#A0E7FF'>%s</font>",
                        runtime, moneyStr, incomeStr, gems, traitReroll,
                        rebirth, dice, towerDisplay, unitCount, maxStorage, rolls, tradeStatus
                    )
                end)
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            panel.Visible = not panel.Visible
        end
    end)

    print("[Ozemen] ✅ Overlay mode")
end

-- ═══════ CONFIG ENGINE ═══════
local ConfigFolder = "Ozemen/AnimeDice"
local AutoloadFile = ConfigFolder .. "/autoload.txt"

local function ensureConfigFolder()
    pcall(function()
        if makefolder and isfolder then
            if not isfolder("Ozemen") then makefolder("Ozemen") end
            if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
        end
    end)
end

local function listConfigs()
    ensureConfigFolder()
    local list = {}
    pcall(function()
        if listfiles then
            for _, path in ipairs(listfiles(ConfigFolder)) do
                local fname = string.match(path, "([^/\\]+)%.json$")
                if fname and fname ~= "" then table.insert(list, fname) end
            end
        end
    end)
    table.sort(list)
    if #list == 0 then table.insert(list, "ไม่มีคอนฟิก (ว่าง)") end
    return list
end

local function getAutoloadConfigName()
    ensureConfigFolder()
    local autoName = nil
    pcall(function()
        if isfile and isfile(AutoloadFile) and readfile then
            local c = readfile(AutoloadFile)
            if c and #c > 0 then autoName = string.gsub(c, "%s+", "") end
        end
    end)
    return autoName
end

local function saveConfigFile(configName)
    ensureConfigFolder()
    if not configName or configName=="" or configName=="ไม่มีคอนฟิก (ว่าง)" then
        return false, "ชื่อคอนฟิกไม่ถูกต้อง"
    end
    local safeName = string.gsub(configName, "[^%w_%-]", "")
    if #safeName == 0 then return false, "ชื่อต้องมีตัวอักษรหรือตัวเลข" end
    local dataToSave = { Version="1.0", Timestamp=os.time(), State=State }
    local ok, encoded = pcall(function() return HttpService:JSONEncode(dataToSave) end)
    if not ok or not encoded then return false, "แปลง JSON ไม่สำเร็จ" end
    local path = ConfigFolder .. "/" .. safeName .. ".json"
    local wok = pcall(function() writefile(path, encoded) end)
    if not wok then return false, "เขียนไฟล์ไม่สำเร็จ" end
    return true, safeName
end

local function loadConfigFile(configName)
    ensureConfigFolder()
    if not configName or configName=="" or configName=="ไม่มีคอนฟิก (ว่าง)" then
        return false, "เลือกคอนฟิกก่อน"
    end
    local safeName = string.gsub(configName, "[^%w_%-]", "")
    local path = ConfigFolder .. "/" .. safeName .. ".json"
    if not isfile(path) then return false, "ไม่พบไฟล์ " .. safeName end
    local content
    local rok = pcall(function() content = readfile(path) end)
    if not rok or not content or #content == 0 then return false, "อ่านไฟล์ไม่สำเร็จ" end
    local dok, decoded = pcall(function() return HttpService:JSONDecode(content) end)
    if not dok or type(decoded) ~= "table" then return false, "โครงสร้างไฟล์เสียหาย" end
    local loaded = decoded.State or decoded
    if type(loaded) ~= "table" then return false, "ไม่พบข้อมูล State" end
    for k, v in pairs(loaded) do
        if State[k] ~= nil and not string.find(tostring(k), "^_") then State[k] = v end
    end
    return true, safeName
end

local function deleteConfigFile(configName)
    ensureConfigFolder()
    if not configName or configName=="" or configName=="ไม่มีคอนฟิก (ว่าง)" then
        return false, "เลือกคอนฟิกก่อน"
    end
    local safeName = string.gsub(configName, "[^%w_%-]", "")
    local path = ConfigFolder .. "/" .. safeName .. ".json"
    if not isfile(path) then return false, "ไม่พบไฟล์" end
    local ok = pcall(function() delfile(path) end)
    if not ok then return false, "ลบไม่สำเร็จ" end
    return true, safeName
end

local function setAutoloadConfig(configName)
    ensureConfigFolder()
    if not configName or configName=="" or configName=="ไม่มีคอนฟิก (ว่าง)" then
        pcall(function() if isfile(AutoloadFile) then delfile(AutoloadFile) end end)
        return false, "ล้าง AutoLoad เรียบร้อย"
    end
    local safeName = string.gsub(configName, "[^%w_%-]", "")
    local ok = pcall(function() writefile(AutoloadFile, safeName) end)
    if not ok then return false, "บันทึก AutoLoad ไม่สำเร็จ" end
    return true, safeName
end

-- ══════════════════════════════════════════════════════════════════════════
--  UI (MODE = "UI")
-- ══════════════════════════════════════════════════════════════════════════
if MODE == "UI" then
    local EasyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/VesperHubOnDaTop/Ui/refs/heads/main/UI.lua"))()

    local Window = EasyUI.CreateWindow({
        Title    = "Ozemen Hub",
        SubTitle = "Anime Dice v2.1 • discord.gg/4Yg72kYT6s",
        Badge    = "OZ",
        Accent   = Color3.fromRGB(0, 205, 255),
    })
    _G.OzemenWindow = Window

    local function addSection(tab, text)
        pcall(function()
            if type(tab.Label) == "function" then
                local ok = pcall(function() tab:Label(text, "") end)
                if ok then return end
            end
            if type(tab.Paragraph) == "function" then
                local ok = pcall(function() tab:Paragraph(text, "") end)
                if ok then return end
                pcall(function() tab:Paragraph({Title=text, Content=""}) end)
            end
        end)
    end

    local Main = Window:Tab("หลัก", "zap")
    addSection(Main, "── สุ่มเต๋า ──")
    Main:Toggle("autoRoll", "สุ่มเต๋าอัตโนมัติ", "", State.AutoRoll,
        function(v) State.AutoRoll = v end)
    Main:Toggle("hideCutscene", "ซ่อน Cutscene", "", State.HideCutscene,
        function(v) State.HideCutscene = v end)
    addSection(Main, "── จุติ & รางวัล ──")
    Main:Toggle("autoRebirth", "จุติอัตโนมัติ", "", State.AutoRebirth,
        function(v) State.AutoRebirth = v end)
    Main:Slider("rebirthTarget", "เพดานจุติ", "", 1, 100, State.TargetRebirth, 0,
        function(v) State.TargetRebirth = v end)
    Main:Toggle("autoClaim", "รับของฟรีทั้งหมด", "", State.AutoClaim,
        function(v) State.AutoClaim = v end)
    Main:Toggle("autoQuest", "รับเควสที่ทำครบ", "", State.AutoQuest,
        function(v) State.AutoQuest = v end)
    Main:Toggle("autoBoost", "ใช้น้ำยา tier สูงสุด", "", State.AutoBoost,
        function(v) State.AutoBoost = v end)
    addSection(Main, "── ความปลอดภัย ──")
    Main:Toggle("antiAFK", "ป้องกันหลุด 24/7", "", State.AntiAFK,
        function(v) State.AntiAFK = v end)
    Main:Toggle("fpsBoost", "FPS Boost", "", State.FpsBoost,
        function(v) State.FpsBoost = v; if v then applyFpsBoost() end end)
    Main:Toggle("ultraFpsBoost", "Ultra FPS (ลบทุกอย่างเหลือ Plot)", "ลบทุกอย่างยกเว้นเพลตเรา — FPS ขั้นสุด", State.UltraFpsBoost,
        function(v) State.UltraFpsBoost = v; if v then ultraFpsBoost(); ultraNukeAll() end end)

    local Plot = Window:Tab("แท่นเงิน", "home")
    addSection(Plot, "── ดูดเงิน ──")
    Plot:Toggle("autoCollect", "ดูดเงินอัตโนมัติ", "", State.AutoCollect,
        function(v) State.AutoCollect = v end)
    Plot:Slider("collectInterval", "ความถี่ (วินาที)", "", 0.1, 5, State.CollectInterval, 1,
        function(v) State.CollectInterval = v end)
    addSection(Plot, "── ตัวละคร ──")
    Plot:Toggle("autoEquip", "ใส่ตัวเก่งสุดอัตโนมัติ", "", State.AutoEquipBest,
        function(v) State.AutoEquipBest = v end)
    Plot:Toggle("autoLevel", "อัปเวลอัตโนมัติ", "", State.AutoLevelSlots,
        function(v) State.AutoLevelSlots = v end)
    Plot:Slider("targetLevel", "เพดานเลเวล", "ล็อคไว้ที่ 20 เพื่อไม่ดูดเงิน", 10, 150, State.TargetUnitLevel, 0,
        function(v) State.TargetUnitLevel = v end)

    local Tower = Window:Tab("หอคอย", "shield")
    addSection(Tower, "── Auto Tower ──")
    Tower:Dropdown("selectTower", "เลือกหอคอย", TowerOptions, State.SelectedTower, false,
        function(v) State.SelectedTower = v end)
    Tower:Toggle("autoTower", "ลงหอคอยอัตโนมัติ", "", State.AutoTower,
        function(v) State.AutoTower = v end)
    Tower:Toggle("hideTowerScreen", "ซ่อนหน้าจอต่อสู้", "", State.HideTowerScreen,
        function(v) State.HideTowerScreen = v end)

    local Sell = Window:Tab("ขายตัว", "trash-2")
    addSection(Sell, "── ขายอัตโนมัติ ──")
    Sell:Toggle("autoSell", "ขายอัตโนมัติ", "", State.AutoSellUnits,
        function(v) State.AutoSellUnits = v end)
    Sell:Slider("sellInterval", "ความถี่สแกน (วินาที)", "", 1, 30, State.SellInterval, 0,
        function(v) State.SellInterval = v end)

    addSection(Sell, "── Smart Trash v2.1 ──")
    Sell:Toggle("autoFilterTrash", "เปิดไต่ Tier อัตโนมัติ", "ข้าม tier ได้ + Force by money", State.AutoFilterTrash,
        function(v) State.AutoFilterTrash = v end)
    Sell:Slider("trashUpgradeAt", "ไต่ tier เมื่อมี", "ตัวใน tier ถัดไป", 3, 20, TrashState.upgradeAt, 0,
        function(v) TrashState.upgradeAt = v end)

    addSection(Sell, "── Safety ──")
    Sell:Toggle("protectPlot", "ป้องกันตัวบนแท่น", "", State.ProtectPlottedUnits,
        function(v) State.ProtectPlottedUnits = v end)
    Sell:Toggle("protectGradeS", "ป้องกันเกรด S+", "", State.ProtectGradeSPlus,
        function(v) State.ProtectGradeSPlus = v end)
    Sell:Toggle("protectLocked", "ป้องกันตัวที่ล็อคไว้", "", State.ProtectLockedUnits,
        function(v) State.ProtectLockedUnits = v end)
    Sell:Button("ขายทันที 1 รอบ", "", function()
        local c, e = sellSelectedUnits()
        Window:Notify("ขายตัว", c>0 and string.format("ขาย %d ตัว ได้ $%s", c, NumberFormatter.FormatCompact(e)) or "ไม่พบตัวที่ตรงเงื่อนไข", 3)
    end)
    Sell:Button("🚨 Emergency Sell", "ขายตัวเกรดต่ำทันที ถ้าคลังใกล้เต็ม", function()
        emergencySell()
        Window:Notify("Emergency", "Emergency sell เสร็จสิ้น", 2)
    end)

    local Upgrades = Window:Tab("อัปเกรด", "arrow-up-circle")
    addSection(Upgrades, "── ซื้ออัปเกรด ──")
    Upgrades:Toggle("autoUpgrades", "ซื้ออัปเกรดอัตโนมัติ", "", State.AutoUpgrades,
        function(v) State.AutoUpgrades = v end)
    Upgrades:Dropdown("upgradeFocus", "หมวดที่เน้น",
        {"Luck & Fortune","Roll Speed","Money","Unit Storage","Damage","Health","Walkspeed","Sell"},
        "Luck & Fortune", false,
        function(v)
            table.clear(State.SelectedUpgradeCategories)
            if v and v ~= "" then State.SelectedUpgradeCategories[v] = true end
        end)
    addSection(Upgrades, "── ลูกเต๋า ──")
    Upgrades:Toggle("autoBuyDice", "ซื้อเต๋าใหม่", "", State.AutoBuyDice,
        function(v) State.AutoBuyDice = v end)

    local Grade = Window:Tab("เกรด", "award")
    local function getInvUnitOptions()
        local opts, map = {}, {}
        pcall(function()
            if not DataController then return end
            local inv = DataController.Inventory and DataController.Inventory()
            if not inv then return end
            for id, item in pairs(inv) do
                if type(item)=="table" and item.name and EntryRegistry then
                    local c = EntryRegistry.getEntryConfig(item.name)
                    if c and c.kind=="Unit" then
                        local g = (item.attributes and item.attributes.grade) or "D"
                        local label = string.format("%s [%s]", item.name, g)
                        table.insert(opts, label); map[label] = id
                    end
                end
            end
        end)
        if #opts==0 then table.insert(opts, "ไม่พบตัวในคลัง") end
        return opts, map
    end
    local unitLabels, unitIdMap = getInvUnitOptions()
    if unitLabels[1] and unitIdMap[unitLabels[1]] then State.TargetGradeUnitKey = unitIdMap[unitLabels[1]] end
    addSection(Grade, "── Auto Reroll ──")
    Grade:Dropdown("gradeUnit", "เลือกตัวละคร", unitLabels, unitLabels[1] or "", false,
        function(v) local id = unitIdMap[v]; if id then State.TargetGradeUnitKey = id end end)
    Grade:Dropdown("targetGrade", "เกรดเป้าหมาย", {"A","A+","S","S+","Z","Z+","神"}, "S", false,
        function(v) State.TargetGrade = (string.match(v, "^[^%s]+") or v) end)
    Grade:Toggle("autoReroll", "เปิดรีเกรดอัตโนมัติ", "", State.AutoRerollGrade,
        function(v) State.AutoRerollGrade = v end)

    local Move = Window:Tab("เคลื่อนที่", "move")
    addSection(Move, "── ความเร็ว ──")
    Move:Slider("walkSpeed", "ความเร็วเดิน", "", 16, 200, State.WalkSpeed, 0,
        function(v)
            State.WalkSpeed = v
            if LP.Character then
                local h = LP.Character:FindFirstChildOfClass("Humanoid")
                if h then h.WalkSpeed = v end
            end
        end)
    Move:Slider("jumpPower", "แรงกระโดด", "", 50, 250, State.JumpPower, 0,
        function(v)
            State.JumpPower = v
            if LP.Character then
                local h = LP.Character:FindFirstChildOfClass("Humanoid")
                if h then h.JumpPower = v end
            end
        end)
    Move:Toggle("infJump", "กระโดดไม่จำกัด", "", State.InfJump,
        function(v) State.InfJump = v end)
    Move:Toggle("noclip", "เดินทะลุกำแพง", "", State.Noclip,
        function(v) State.Noclip = v end)

    local Hook = Window:Tab("เว็บฮุก", "send")
    addSection(Hook, "── Discord Webhook ──")
    Hook:Input("webhookURL", "Webhook URL", "", State.WebhookURL,
        function(v) State.WebhookURL = string.gsub(v or "", "%s+", "") end)
    Hook:Toggle("webhookOn", "เปิดใช้งาน Webhook", "", State.WebhookEnabled,
        function(v) State.WebhookEnabled = v end)
    Hook:Button("ทดสอบส่ง Webhook", "", function()
        if State.WebhookURL == "" then
            Window:Notify("Webhook", "กรุณาใส่ URL ก่อน", 2.5); return
        end
        sendDiscordWebhook("ทดสอบสำเร็จ!", "**Ozemen Hub v2.1** พร้อมใช้งาน", 0x00FF88, {
            {name="ผู้เล่น", value=LP.DisplayName, inline=true},
        })
    end)

    local Trade = Window:Tab("เทรด", "repeat")
    addSection(Trade, "── Auto Trade ──")
    Trade:Toggle("autoTrade", "เปิดระบบเทรดอัตโนมัติ", "", State.AutoTrade,
        function(v) State.AutoTrade = v end)
    Trade:Input("tradeHost", "ชื่อ Host (คั่นด้วย ,)", "", table.concat(State.TradeHost or {}, ","),
        function(v)
            State.TradeHost = {}
            for name in string.gmatch(v or "", "([^,]+)") do
                table.insert(State.TradeHost, string.gsub(name, "^%s*(.-)%s*$", "%1"))
            end
        end)
    Trade:Dropdown("tradeSendMode", "โหมดส่ง",
        {"none","keep_slotted","keep_income","all"}, State.TradeSendMode, false,
        function(v) State.TradeSendMode = v end)

    local Config = Window:Tab("คอนฟิก", "save")
    addSection(Config, "── โปรไฟล์ ──")
    local selectedConfigName = ""
    local newConfigName = "Default"
    local configList = listConfigs()
    Config:Input("configName", "ชื่อคอนฟิกใหม่", "", "Default",
        function(v) newConfigName = string.gsub(v or "", "%s+", "") end)
    Config:Button("สร้างคอนฟิกใหม่", "", function()
        local n = newConfigName
        if n=="" then n = "Default" end
        local ok, msg = saveConfigFile(n)
        if ok then
            configList = listConfigs()
            Window:Notify("Config", "บันทึก ["..msg.."] เรียบร้อย!", 3)
        else
            Window:Notify("Config", "ผิดพลาด: "..tostring(msg), 3)
        end
    end)
    Config:Dropdown("configList", "เลือกคอนฟิก", configList, configList[1] or "ไม่มีคอนฟิก (ว่าง)", false,
        function(v) selectedConfigName = v end)
    Config:Button("โหลดคอนฟิก", "", function()
        if selectedConfigName=="" or selectedConfigName=="ไม่มีคอนฟิก (ว่าง)" then
            Window:Notify("Config", "เลือกคอนฟิกก่อน", 2.5); return
        end
        local ok, msg = loadConfigFile(selectedConfigName)
        Window:Notify("Config", ok and ("โหลด ["..msg.."] สำเร็จ") or ("ล้มเหลว: "..tostring(msg)), 3)
    end)
    Config:Button("บันทึกทับ", "", function()
        if selectedConfigName=="" or selectedConfigName=="ไม่มีคอนฟิก (ว่าง)" then
            Window:Notify("Config", "เลือกคอนฟิกก่อน", 2.5); return
        end
        local ok, msg = saveConfigFile(selectedConfigName)
        Window:Notify("Config", ok and ("บันทึกทับ ["..msg.."] สำเร็จ") or ("ล้มเหลว: "..tostring(msg)), 3)
    end)
    Config:Button("ตั้งเป็น AutoLoad", "", function()
        if selectedConfigName=="" or selectedConfigName=="ไม่มีคอนฟิก (ว่าง)" then
            Window:Notify("Config", "เลือกคอนฟิกก่อน", 2.5); return
        end
        local ok, msg = setAutoloadConfig(selectedConfigName)
        Window:Notify("Config", ok and ("AutoLoad: "..msg) or ("ล้มเหลว: "..tostring(msg)), 3)
    end)
    Config:Button("ยกเลิก AutoLoad", "", function()
        setAutoloadConfig(nil)
        Window:Notify("Config", "ยกเลิก AutoLoad เรียบร้อย", 2.5)
    end)

    local Settings = Window:Tab("ตั้งค่า", "settings")
    Settings:Settings({ Discord = "https://discord.gg/4Yg72kYT6s" })
    Settings:Button("ปิดสคริปต์ (Unload)", "", function()
        if _G.OzemenCleanup then _G.OzemenCleanup() end
    end)

    Window:SelectTab(1)

    local minGui = Instance.new("ScreenGui")
    minGui.Name = "OzemenMinBtn"
    minGui.ResetOnSpawn = false
    minGui.Parent = (gethui and select(2, pcall(gethui))) or CoreGui or LP:WaitForChild("PlayerGui")
    _G.OzemenMinGui = minGui

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.fromOffset(58, 52)
    minBtn.Position = UDim2.new(0, 20, 0.5, -26)
    minBtn.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
    minBtn.BorderSizePixel = 0
    minBtn.Text = ""
    minBtn.AutoButtonColor = false
    minBtn.Active = true
    minBtn.Draggable = true
    minBtn.Parent = minGui
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 14)

    local minStroke = Instance.new("UIStroke")
    minStroke.Color = Color3.fromRGB(180, 100, 255)
    minStroke.Thickness = 2.2
    minStroke.Parent = minBtn

    local textMain = Instance.new("TextLabel")
    textMain.Size = UDim2.new(1,0,1,0)
    textMain.BackgroundTransparency = 1
    textMain.RichText = true
    textMain.Text = '<font color="#FFD54A">◆</font><font color="#00E5FF">OZ</font>'
    textMain.TextSize = 20
    textMain.Font = Enum.Font.GothamBlack
    textMain.Parent = minBtn

    local function toggleUI()
        pcall(function()
            local root = Window.Root or Window.Gui or Window.Container
            if not root then return end
            while root and not root:IsA("ScreenGui") do root = root.Parent end
            if root then root.Enabled = not root.Enabled end
        end)
    end

    minBtn.Activated:Connect(toggleUI)

    if cfg("AutoStart", true) then
        task.wait(0.5)
        if cfg("StartHidden", true) then
            pcall(function()
                local root = Window.Root or Window.Gui or Window.Container
                if root then
                    while root and not root:IsA("ScreenGui") do root = root.Parent end
                    if root then root.Enabled = false end
                end
            end)
        end
        Window:Notify("Ozemen Hub", "เริ่มฟาร์มอัตโนมัติแล้ว!", 5)
    end

    task.spawn(function()
        task.wait(1.5)
        pcall(function()
            local auto = getAutoloadConfigName()
            if auto and auto ~= "" and auto ~= "ไม่มีคอนฟิก (ว่าง)" then
                local ok, name = loadConfigFile(auto)
                if ok then
                    Window:Notify("Config", "โหลดคอนฟิกอัตโนมัติ: "..tostring(name), 4)
                end
            end
        end)
    end)

    Window:Notify("Ozemen Hub", "Anime Dice v2.1 — Bug Fixed | discord.gg/4Yg72kYT6s", 5)

    print("[Ozemen] ✅ UI mode")
end

-- ═══════ สรุป ═══════
task.spawn(function()
    task.wait(1)
    print("══════════════════════════════════════════════════")
    print("  [Ozemen] v2.1 — Bug Fixed")
    print("  [Ozemen] Trash Tier:", TrashState.currentTier)
    print("══════════════════════════════════════════════════")
end)
