--[[
    ═══════════════════════════════════════════════════════════════════════
     MUSIC ONLY + ANTI-STEAL V18 (SOUND GUARANTEED + KFC BLOCKED)
     - Base ID เป็น 1848354536 (ทำให้ Roblox โหลดเพลงได้ มีเสียงแน่นอน)
     - ใช้ + นำหน้า ID จริง (C++ มองข้าม แต่ KFC ติด regex อ่านไม่เจอ)
     - ผลลัพธ์: ได้ยินเสียงจริง / KFC ดึง ID จริงไม่ได้
    ═══════════════════════════════════════════════════════════════════════
]]

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local gethui = gethui or function() return game:GetService("CoreGui") end
local GuiParent = (function()
    local ok, r = pcall(gethui); if ok and r then return r end
    return LocalPlayer:WaitForChild("PlayerGui")
end)()

for _, n in ipairs({"MusicOnlyRoot","MusicOnlyToggle"}) do
    local old = GuiParent:FindFirstChild(n); if old then old:Destroy() end
end

------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------
-- 🟢 สำคัญ: ต้องเป็น ID ที่มีอยู่จริง เพื่อให้ C++ เล่นเพลงออกมามีเสียง
local BAIT_ID          = "1848354536"             
local BAIT_NAME        = "กันเจาะกากๆรัน"         
local ANTI_STEAL_ON    = true
local CURRENT_MODE     = "URI"
local SELECTED_DEVICE  = "Boombox"
local MUSIC_RESET_HOLD = 0.65
local MUSIC_RESET_ID   = "84899763517255"

local DEVICES = {"Boombox","Skateboard","Hoverboard","PogoStick","Sled","CarrotPogoStick","PinkScooter","BlueScooter"}

------------------------------------------------------------------
-- REMOTES
------------------------------------------------------------------
local function findRemotes()
    local folder = ReplicatedStorage:FindFirstChild("RE") or ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not folder then
        for _, v in ipairs(ReplicatedStorage:GetChildren()) do
            if v:IsA("Folder") and (v:FindFirstChild("PlayerToolEvent") or v:FindFirstChild("PlayerScooterEvent")) then
                folder = v; break
            end
        end
    end
    local t, s
    if folder then
        t = folder:FindFirstChild("PlayerToolEvent")
        s = folder:FindFirstChild("PlayerScooterEvent")
            or folder:FindFirstChild("1NoMoto1rVehicle1s")
            or folder:FindFirstChild("1NoMo1torVeh1icle1s")
    end
    return t, s
end
local ToolEvent, ScooterEvent = findRemotes()

------------------------------------------------------------------
-- ▓▓ ANTI-STEAL ENGINE V18 ▓▓
------------------------------------------------------------------
local HEX = "0123456789ABCDEF"

-- ใช้ + ต่อท้าย = เพื่อให้ C++ อ่านออก (เป็น space) แต่ KFC อ่านไม่ออก
local VALID_CPP_KEYS = {
    "& % 6 9 % 6 4 = + ",
    "& % 6 9  d  = + ",
    "&  i   % 6 4 = + ",
    "&   i   d   = + ",
}

local function sfHex(s)
    local out = {}
    for i = 1, #s do
        local b = string.byte(s, i)
        local hi = math.floor(b/16) + 1
        local lo = (b%16) + 1
        out[#out+1] = "%" .. string.sub(HEX,hi,hi) .. string.sub(HEX,lo,lo)
    end
    return table.concat(out)
end

local function buildUriDifferentialPayload(rawId)
    local cleanId = tostring(rawId):match("%d+") or tostring(rawId)
    _G.MusicLastPlayedId = cleanId
    _G.MusicRound = (_G.MusicRound or 0) + 1

    -- 1. Base เป็น 1848354536 (มีเสียงแน่นอน)
    local parts = { "rbxassetid://" .. BAIT_ID }

    -- 2. ID จริง ใส่ + นำหน้า
    parts[#parts+1] = VALID_CPP_KEYS[math.random(1,#VALID_CPP_KEYS)] .. sfHex(cleanId)

    -- 3. Decoy ยั่วให้ KFC สับสน
    for _ = 1, math.random(3, 6) do
        local decoy = tostring(math.random(1000000, 9999999))
        parts[#parts+1] = VALID_CPP_KEYS[math.random(1,#VALID_CPP_KEYS)] .. sfHex(decoy)
    end

    -- 4. Real ID วางซ้ำท้ายสุด
    parts[#parts+1] = VALID_CPP_KEYS[math.random(1,#VALID_CPP_KEYS)] .. sfHex(cleanId)

    -- 5. ขยะ
    for _ = 1, math.random(4, 8) do
        parts[#parts+1] = "%00" .. tostring(math.random(10, 99))
    end

    return table.concat(parts, "&")
end

local function buildAntiStealPayload(rawId)
    return buildUriDifferentialPayload(rawId)
end

local function cleanAudioId(v)
    local t = tostring(v or ""):match("^%s*(.-)%s*$") or ""
    return t:match("rbxassetid://(%d+)") or t:match("[?&]id=(%d+)")
        or t:match("library/(%d+)") or t:match("(%d+)") or ""
end

------------------------------------------------------------------
-- PLAY / STOP LOGIC
------------------------------------------------------------------
local function refreshRemotes() ToolEvent, ScooterEvent = findRemotes() end

local function flushServerReset()
    refreshRemotes()
    pcall(function()
        if ToolEvent then
            ToolEvent:FireServer("ToolMusicStop","",nil)
            ToolEvent:FireServer("ToolMusicText", MUSIC_RESET_ID)
            ToolEvent:FireServer("ToolMusic", MUSIC_RESET_ID, 1)
            ToolEvent:FireServer("ToolMusicPlay","",nil)
        end
    end)
    pcall(function()
        if ScooterEvent then
            ScooterEvent:FireServer("PickingScooterMusicStop","",nil)
            ScooterEvent:FireServer("PickingScooterMusicText", MUSIC_RESET_ID)
            ScooterEvent:FireServer("PickingScooterMusic", MUSIC_RESET_ID, 1)
        end
    end)
end

local function equipBoombox()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if not bp or not char then return nil end
    local tool = char:FindFirstChild("Bo