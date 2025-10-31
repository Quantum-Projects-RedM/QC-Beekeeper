local RSGCore = exports['rsg-core']:GetCoreObject()
local ApiariesLoaded = false
local CollectedNectar = {}
local ApiaryCooldowns = {} -- [apiarieid] = os.time()
local HarvestCooldown = (Config.ApiaryCooldown or 5) * 60 -- seconds
lib.locale()
---------------------------------------------
-- Webhook Log Function
-- This function sends a message to a Discord webhook.
-- It creates an embed with the message and color, and sends it as a POST request.
---------------------------------------------
local function SendWebhookLog(message, color)
    if not Config.Webhook or Config.Webhook == "" then return end

    local embed = {
        {
            ["color"] = color or 16776960, -- default yellow
            ["title"] = "🐝 QC-Beekeeper Apiary Update",
            ["description"] = message,
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }

    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "QC-Beekeeper",
        embeds = embed,
        avatar_url = "" -- optional: custom bee icon
    }), { ['Content-Type'] = 'application/json' })
end
---------------------------------------------
-- Useable Items Registration
-- This section registers the useable items defined in the Config.ApiarieItems table.
---------------------------------------------
for k, v in pairs(Config.ApiarieItems) do
    RSGCore.Functions.CreateUseableItem(v.item, function(source)
        local src = source
        TriggerClientEvent('qc-beekeeping:Notify', src, '~#FFFF00~Checking...', 'Checking your placed apiaries...', 1500)
        Wait(2000)
        RSGCore.Functions.TriggerCallback('qc-beekeeping:server:canPlaceApiary', src, function(canPlace)
            if canPlace then
                TriggerClientEvent('qc-beekeeping:client:PlaceApiary', src, v.type, v.hash, v.item)
            else
                TriggerClientEvent('qc-beekeeping:Notify', src, '~#E4080A~'..locale('error'), locale('you_already_have_plants_down'), 3000)
            end
        end)
    end)
end

---------------------------------------------
-- Get Apiary Data Callback
-- This callback retrieves the data for a specific apiary based on its ID.
-- It queries the database for the apiary's properties and returns them to the client.
---------------------------------------------
-- Server-side callback
RSGCore.Functions.CreateCallback('qc-beekeeping:server:GetApiaryData', function(source, cb, apiarieid)
    MySQL.Async.fetchAll('SELECT * FROM qc_apiaries WHERE apiarieid = @id', {
        ['@id'] = apiarieid
    }, function(result)
        if result and result[1] then
            local decoded = json.decode(result[1].properties)
            local cid = result[1].citizenid
            local hasQueen = decoded.queen == true or decoded.queen == 1 or decoded.queen == "1"

            cb({
                {
                    properties = decoded,
                    queen = hasQueen,
                    type = decoded.type,
                    cid = cid,
                }
            })
        else
            cb(nil)
        end
    end)
end)


---------------------------------------------
-- NOT USED
-- Check if Nectar is Collected Callback
---------------------------------------------
RSGCore.Functions.CreateCallback('qc-beekeeping:server:CheckCollecNectar', function(source, cb, coords)
    local exists = false
    for i = 1, #CollectedNectar do
        local fertilizer = CollectedNectar[i]

        if fertilizer == coords then
            exists = true
            break
        end
    end
    cb(exists)
end)
---------------------------------------------
-- Check if Apiary can be Placed Callback
-- This callback checks if the player can place a new apiary.
-- It counts the number of apiaries already placed by the player and compares it to the maximum allowed.
---------------------------------------------
RSGCore.Functions.CreateCallback('qc-beekeeping:server:canPlaceApiary', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local CID = Player.PlayerData.citizenid
    local count = 0

    for _, v in pairs(Config.Apiaries) do
        if v.placer == CID then
            count = count + 1
        end
    end

    cb(count < Config.MaxApiaries)
end)

---------------------------------------------
-- Remove Item Event
-- This event is triggered when an item needs to be removed from a player's inventory.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:RemoveItem')
AddEventHandler('qc-beekeeping:server:RemoveItem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(item, amount)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove', amount)
end)
---------------------------------------------
-- Save Apiary Event
-- This event is triggered to save the apiary data to the database.
-- It encodes the apiary data to JSON format and inserts it into the `qc_apiaries` table.
-- The event takes the apiary data, apiarie ID, and citizen ID as parameters.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:SaveApiary')
AddEventHandler('qc-beekeeping:server:SaveApiary', function(data, apiarieid, citizenid)
    local datas = json.encode(data)

    MySQL.Async.execute('INSERT INTO qc_apiaries (properties, apiarieid, citizenid) VALUES (@properties, @apiarieid, @citizenid)',
    {
        ['@properties'] = datas,
        ['@apiarieid'] = apiarieid,
        ['@citizenid'] = citizenid
    })
end)
---------------------------------------------
-- Place New Apiary Event
-- This event is triggered when a player places a new apiary.
-- It checks if the player has reached the maximum number of apiaries allowed,
-- and if not, it creates a new apiary with the specified properties.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:PlaceNewApiary')
AddEventHandler('qc-beekeeping:server:PlaceNewApiary', function(outputitem, prophash, position, heading)
    local src = source
    local apiarieid = math.random(111111, 999999)
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    local startitemData =
    {
        id = apiarieid,
        type = outputitem,
        x = position.x,
        y = position.y,
        z = position.z,
        h = heading,
        necneed = Config.StartingNectar,
        polneed = Config.StartingPollen,
        growth = 100.0,
        queen = false,
        quality = 15.0,
        grace = true,
        hash = prophash,
        beingHarvested = false,
        placer = Player.PlayerData.citizenid,
        placetime = os.time()
    }

    local PlantCount = 0

    for _, v in pairs(Config.Apiaries) do
        if v.placer == Player.PlayerData.citizenid then
            PlantCount = PlantCount + 1
        end
    end

    if PlantCount >= Config.MaxApiaries then
        TriggerClientEvent('qc-beekeeping:Notify', '~#E4080A~'..locale('error'), locale('you_already_have_plants_down'), 2000) --title, text, time
    else
        table.insert(Config.Apiaries, startitemData)
        TriggerEvent('qc-beekeeping:server:SaveApiary', startitemData, apiarieid, citizenid)
        TriggerEvent('qc-beekeeping:server:UpdateApiaries')
    end
end)
---------------------------------------------
-- Add Queen to Apiary Event
-- This event is triggered when a player adds a queen to an apiary.
-- It checks if the apiary already has a queen, and if not, it adds the queen item to the apiary.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:AddQueenToApiary')
AddEventHandler('qc-beekeeping:server:AddQueenToApiary', function(apiarieid, queenItem)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    for i = 1, #Config.Apiaries do
        local v = Config.Apiaries[i]
        if v.id == apiarieid then
            if not v.bees and not v.queen then
                v.bees = queenItem
                v.queen = true
                local updatedProperties = json.encode(v)
                MySQL.Async.execute('UPDATE qc_apiaries SET properties = @props WHERE apiarieid = @apiarieid', {
                    ['@props'] = updatedProperties,
                    ['@apiarieid'] = apiarieid
                })
                Player.Functions.RemoveItem(queenItem, 1)
                TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[queenItem], 'remove', 1)
                TriggerClientEvent('qc-beekeeping:Notify', src, '~#7DDA58~'..locale('success'), locale('queen_added_to_apiary'), 2000)
                TriggerEvent('qc-beekeeping:server:UpdateApiaries')
            else
                TriggerClientEvent('qc-beekeeping:Notify', src, '~#E4080A~'..locale('error'), locale('apiary_already_has_queen'), 2000)
            end
            break
        end
    end
end)

---------------------------------------------
-- Apiary Harvested Event
-- This event is triggered when an apiary is being harvested.
-- It sets the `beingHarvested` flag to true for the specified apiary ID.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:ApiaryHarvested')
AddEventHandler('qc-beekeeping:server:ApiaryHarvested', function(apiarieid)
    for _, v in pairs(Config.Apiaries) do
        if v.id == apiarieid then
            v.beingHarvested = true
        end
    end
    TriggerEvent('qc-beekeeping:server:UpdateApiaries')
end)

---------------------------------------------
-- Destroy Apiary Event
-- This event is triggered when an apiary is destroyed.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:destroyApiary')
AddEventHandler('qc-beekeeping:server:destroyApiary', function(apiarieid)
    local src = source

    for k, v in pairs(Config.Apiaries) do
        if v.id == apiarieid then
            table.remove(Config.Apiaries, k)
        end
    end

    TriggerClientEvent('qc-beekeeping:client:DelApiaryProp', -1, apiarieid)
    TriggerEvent('qc-beekeeping:server:ApiaryRemoved', apiarieid)
    TriggerEvent('qc-beekeeping:server:UpdateApiaries')
    TriggerClientEvent('qc-beekeeping:Notify', '~#7DDA58~'..locale('success'), locale('you_distroyed_the_plant'), 2000) --title, text, time
end)

---------------------------------------------
-- Harvested Apiary Event
-- This event is triggered when an apiary is harvested.
-- It checks the quality of the apiary and gives rewards based on the quality.
-- It also removes the apiary from the config and updates the apiaries for all clients.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:HarvestedApiary')
AddEventHandler('qc-beekeeping:server:HarvestedApiary', function(apiarieid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local now = os.time()

    -- Check cooldown first
    local now = os.time()
    local lastHarvest = ApiaryCooldowns[apiarieid] or 0
    local elapsed = now - lastHarvest
    local wait = HarvestCooldown - elapsed
    if wait > 0 then
        local minutes = math.floor(wait / 60)
        local seconds = wait % 60

        local timeString = ""
        if minutes > 0 then
            timeString = minutes .. " minute" .. (minutes ~= 1 and "s" or "")
        end
        if seconds > 0 then
            if minutes > 0 then
                timeString = timeString .. " and "
            end
            timeString = timeString .. seconds .. " second" .. (seconds ~= 1 and "s" or "")
        end

        TriggerClientEvent('qc-beekeeping:Notify', src, '~#E4080A~'..locale('error'), locale('wait_before_harvest') .. timeString, 2000)
        return
    end


    local poorAmount, goodAmount, excellentAmount = 0, 0, 0
    local poorQuality, goodQuality, excellentQuality = false, false, false
    local hasFound = false
    local label, item = nil, nil

    for k, v in pairs(Config.Apiaries) do
        if tostring(v.id) == tostring(apiarieid) then
            for _, itemData in pairs(Config.ApiarieItems) do
                if tostring(v.type) == tostring(itemData.type) then
                    label = itemData.label
                    item = itemData.receive
                    poorAmount = math.random(itemData.poorRewards.min, itemData.poorRewards.max)
                    goodAmount = math.random(itemData.goodRewards.min, itemData.goodRewards.max)
                    excellentAmount = math.random(itemData.excellentRewards.min, itemData.excellentRewards.max)
                    local quality = tonumber(v.quality) or 0
                    hasFound = true

                    -- Set quality tier
                    if quality > 0 and quality < 25 then
                        poorQuality = true
                    elseif quality >= 25 and quality < 75 then
                        goodQuality = true
                    elseif quality >= 75 then
                        excellentQuality = true
                    end

                    -- ✅ Set last harvested timestamp in memory
                    ApiaryCooldowns[apiarieid] = now

                    -- ✅ Update last_harvested in apiary's property for client to read
                    local props = json.decode(v.properties or "{}")
                    props.last_harvested = now
                    v.properties = json.encode(props)

                    break
                end
            end
            break
        end
    end

    if not hasFound then 
        TriggerClientEvent('qc-beekeeping:Notify', src, '~#E4080A~'..locale('error'), locale('no_plant_found'), 2000)
        return 
    end

    -- Give rewards
    local amount = poorQuality and poorAmount or goodQuality and goodAmount or excellentAmount
    local msg = poorQuality and locale('you_harvested_poorly') or goodQuality and locale('you_harvested_well') or locale('you_harvested_perfectly')

    if amount > 0 then
        Player.Functions.AddItem(item, amount)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add', amount)
        TriggerClientEvent('qc-beekeeping:Notify', src, '~#7DDA58~'..locale('success'), msg .. amount, 2000)
    else
        TriggerClientEvent('qc-beekeeping:Notify', src, '~#E4080A~'..locale('error'), locale('no_plant_found'), 2000)
        return
    end

    -- Update clients
    TriggerEvent('qc-beekeeping:server:UpdateApiaries')
end)


RegisterServerEvent('qc-beekeeping:server:UpdateApiaries')
AddEventHandler('qc-beekeeping:server:UpdateApiaries', function()
    local src = source
    TriggerClientEvent('qc-beekeeping:client:UpdateApiaryData', -1, Config.Apiaries)
    
end)

---------------------------------------------
-- Pollinate Apiary Event
-- This event is triggered when an apiary is pollinated.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:PollinateApiary')
AddEventHandler('qc-beekeeping:server:PollinateApiary', function(apiarieid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    for k, v in pairs(Config.Apiaries) do
        if v.id == apiarieid then
            Config.Apiaries[k].polneed = Config.Apiaries[k].polneed + Config.PollenIncrease
            if Config.Apiaries[k].polneed > 100.0 then
                Config.Apiaries[k].polneed = 100.0
            end
        end
    end

    if not Player.Functions.RemoveItem(Config.PollenItem, 1) then return end

    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.PollenItem], 'remove', 1)
    Player.Functions.AddItem('bucket', 1) --add empty bucket
    TriggerEvent('qc-beekeeping:server:UpdateApiaries')
    
end)

---------------------------------------------
-- Nectar Feeding Event
-- This event is triggered when an apiary is fed with nectar.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:NectarFeeding')
AddEventHandler('qc-beekeeping:server:NectarFeeding', function(apiarieid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    for k, v in pairs(Config.Apiaries) do
        if v.id == apiarieid then
            Config.Apiaries[k].necneed = Config.Apiaries[k].necneed + Config.NectarIncrease

            if Config.Apiaries[k].necneed > 100.0 then
                Config.Apiaries[k].necneed = 100.0
            end
        end
    end

    if not Player.Functions.RemoveItem(Config.NectarItem, 1) then return end

    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.NectarItem], 'remove', 1)
    TriggerEvent('qc-beekeeping:server:UpdateApiaries')
end)

RegisterServerEvent('qc-beekeeping:server:TakeQueen', function(CurrentHive)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local hive = Config.WildHives[CurrentHive]

    if not hive or not hive.queen then
        print(('[QC-Beekeeping] ERROR: Invalid hive index or missing queen item at index: %s'):format(CurrentHive))
        return
    end

    local item = hive.queen
    local amount = math.random(Config.GetQueenItemMin, Config.GetQueenItemMax)

    if Player then
        Player.Functions.AddItem(item, amount)
        TriggerClientEvent('qc-beekeeping:client:QueenTakenFromHive', src, CurrentHive)
        TriggerClientEvent('qc-beekeeping:Notify', src, '~#7DDA58~' .. locale('success'), locale('queen_taken'), 2000)
    end
end)


---------------------------------------------
-- Renew Apiaries Event 
-- This event is triggered to renew the properties of an apiary.
-- It updates the properties of the apiary in the database based on the provided ID and data.
-- It retrieves the apiary from the database, encodes the new data to JSON, and updates the database.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:renewApiaries')
AddEventHandler('qc-beekeeping:server:renewApiaries', function(id, data)
    local result = MySQL.query.await('SELECT * FROM qc_apiaries WHERE apiarieid = @apiarieid', { ['@apiarieid'] = id })

    if not result[1] then return end

    local newData = json.encode(data)
    MySQL.Async.execute('UPDATE qc_apiaries SET properties = @properties WHERE apiarieid = @id', { ['@properties'] = newData, ['@id'] = id })
end)

---------------------------------------------
-- Remove Apiary Event
-- This event is triggered when an apiary is removed.
-- It queries the database for all apiaries, checks if the provided apiarie ID matches,
-- and if so, it deletes the apiary from the database and removes it from the Config.Apiaries table.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:ApiaryRemoved')
AddEventHandler('qc-beekeeping:server:ApiaryRemoved', function(apiarieid)
    local result = MySQL.query.await('SELECT * FROM qc_apiaries')

    if not result then return end

    for i = 1, #result do
        local apiaryData = json.decode(result[i].properties)

        if apiaryData.id == apiarieid then
            MySQL.Async.execute('DELETE FROM qc_apiaries WHERE id = @id', { ['@id'] = result[i].id })
            for k, v in pairs(Config.Apiaries) do
                if v.id == apiarieid then
                    table.remove(Config.Apiaries, k)
                end
            end
        end
    end
end)
---------------------------------------------
-- Get Apiaries Event
-- This event is triggered to retrieve all apiaries from the database.
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:GetApiaries')
AddEventHandler('qc-beekeeping:server:GetApiaries', function()
    local result = MySQL.query.await('SELECT * FROM qc_apiaries')
    if not result[1] then return end
    for i = 1, #result do
        local apiaryData = json.decode(result[i].properties)
        table.insert(Config.Apiaries, apiaryData)
    end
end)
---------------------------------------------
-- Give Item Event
---------------------------------------------
RegisterServerEvent('qc-beekeeping:server:GiveItem')
AddEventHandler('qc-beekeeping:server:GiveItem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.AddItem(item, amount)
    if item == 'fullbucket' then
        Player.Functions.RemoveItem('bucket', 1)
    end
     TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add', amount)
end)
---------------------------------------------
-- Delete Nectar Point Event
---------------------------------------------
RegisterNetEvent('qc-beekeeping:server:DelNectarPoint')
AddEventHandler('qc-beekeeping:server:DelNectarPoint', function(coords)
    -- We remove an object from the server (if any)
    for i = 1, #CollectedNectar do
        local fertilizer = CollectedNectar[i]
        if fertilizer == coords then
            table.remove(CollectedNectar, i)
            -- We inform all clients to remove the facility
            TriggerClientEvent('qc-beekeeping:client:deletefertilizer', -1, coords)
            break
        end
    end
end)

---------------------------------------------
-- Retrieve Nectar Event
-- This event is triggered when a player retrieves nectar.
---------------------------------------------
RegisterNetEvent('qc-beekeeping:server:RetrieveNectar')
AddEventHandler('qc-beekeeping:server:RetrieveNectar', function(coords)
    local exists = false

    for i = 1, #CollectedNectar do
        local fertilizer = CollectedNectar[i]
        if fertilizer == coords then
            exists = true
            break
        end
    end

    if not exists then
        CollectedNectar[#CollectedNectar + 1] = coords
    end
end)

------------------------------------------------------------------------------------------------------------
--- THREADS 
--- --------------------------------------------------------------------------------------------------------

---------------------------------------------
-- Update Apiary Data Thread
-- This thread runs every 5 seconds to update the apiary data for all clients.
---------------------------------------------
CreateThread(function()
    while true do
        Wait(5000)
        if ApiariesLoaded then
            TriggerClientEvent('qc-beekeeping:client:UpdateApiaryData', -1, Config.Apiaries)
        end
    end
end)
---------------------------------------------
-- Load Apiaries Thread
-- This thread is responsible for loading the apiaries from the database when the resource starts.
---------------------------------------------
CreateThread(function()
    TriggerEvent('qc-beekeeping:server:GetApiaries')
    ApiariesLoaded = true
end)
---------------------------------------------
-- Refresh Apiaries Thread
-- This thread runs every Config.RefreshTimer seconds to update the status of all apiaries.
-- It checks the quality, polneed, and necneed of each apiary and updates their status accordingly.
---------------------------------------------
CreateThread(function()
    while true do
        Wait(Config.RefreshTimer)
        local t1 = os.clock()
        local CurrentTime = os.time()
        local decaying = 0
        local healthy = 0
        local toRemove = 0
        for i = 1, #Config.Apiaries do
            local apiary = Config.Apiaries[i]
            local UntilDest = apiary.placetime + Config.DestroyApiaryTime

            if apiary.quality < 100 then
                if apiary.grace then
                    apiary.grace = false
                else
                    apiary.polneed = apiary.polneed - Config.PollenDecay
                    apiary.necneed = apiary.necneed - Config.NectarDecay

                    if not Config.HardDifficulty then
                        if apiary.polneed < 25 or apiary.necneed < 25 then
                            apiary.quality = apiary.quality - Config.QualityDec25Easy
                        elseif apiary.polneed > 75 and apiary.necneed > 75 then
                            apiary.quality = apiary.quality + Config.QualityInc75Easy
                        elseif apiary.polneed > 25 and apiary.necneed > 25 then
                            apiary.quality = apiary.quality + Config.QualityInc25Easy
                        end
                    else
                        if apiary.polneed < 25 or apiary.necneed < 25 then
                            apiary.quality = apiary.quality - Config.QualityDec25Hard
                        elseif apiary.polneed > 75 and apiary.necneed > 75 then
                            apiary.quality = apiary.quality + Config.QualityInc75Hard
                        elseif apiary.polneed > 25 and apiary.necneed > 25 then
                            apiary.quality = apiary.quality + Config.QualityInc25Hard
                        end
                    end
                    -- Clamp values
                    apiary.polneed = math.max(0, math.min(100, apiary.polneed))
                    apiary.necneed = math.max(0, math.min(100, apiary.necneed))
                    apiary.quality = math.max(0, math.min(100, apiary.quality))
                end
            end
            -- Categorize
            if apiary.quality < 25 then decaying = decaying + 1 end
            if apiary.quality >= 75 then healthy = healthy + 1 end
            if CurrentTime > UntilDest then
                toRemove = toRemove + 1
                --print('Removing old Apiary with ID ' .. apiary.id)
                TriggerEvent('qc-beekeeping:server:ApiaryRemoved', apiary.id)
            else
                TriggerEvent('qc-beekeeping:server:renewApiaries', apiary.id, apiary)
            end
        end

        local t2 = os.clock()
        local shouldPrint = type(Config.ConsoleTime) == "number" and (not Config.LastPrint or CurrentTime - Config.LastPrint >= Config.ConsoleTime)
        local shouldWebhook = Config.Webhook and Config.Webhook ~= ""
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local cycleTime = (t2 - t1) * 1000
        if shouldPrint then
            print("^3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("^2🐝 QC-Beekeeper System | Apiary Status Update^7")
            print("^3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print(("^6[INFO]^7 Updating %s active apiaries..."):format(#Config.Apiaries))
            print(("^6[TIME] ^7 %s"):format(timestamp))
            print(("^6[PERF] ^7Cycle Time: %.2fms"):format(cycleTime))
            print(("^6[SUMMARY] ^7Healthy: %s | Decaying: %s | Expired: %s"):format(healthy, decaying, toRemove))
            print("^3━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            Config.LastPrint = CurrentTime
        if shouldWebhook then
            local message = ("**🐝 QC-Beekeeper Apiary Webhook Test**\n\n" ..
                "**🟢 Healthy:** `%s`\n" ..
                "**🔴 Decaying:** `%s`\n" ..
                "**⏳ Expired:** `%s`\n" ..
                "**📈 Cycle Time:** `%.2fms`\n" ..
                "**🕒 Time:** %s"
            ):format(healthy, decaying, toRemove, cycleTime, timestamp)
            SendWebhookLog(message)
            end
        end
        TriggerEvent('qc-beekeeping:server:UpdateApiaries')
    end
end)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------
-- Version Checker
---------------------------------------------
local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Quantum-Projects-RedM/QC-VersionCheckers/master/QC-Beekeeper.txt', function(err, newestVersion, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
        local resourceName = GetCurrentResourceName()
        local discordLink = GetResourceMetadata(resourceName, 'quantum_discord')

        if not newestVersion then
            print("\n^1[Quantum Projects]^7 Unable to perform version check.\n")
            return
        end

        local isLatestVersion = newestVersion:gsub("%s+", "") == currentVersion:gsub("%s+", "")
        if isLatestVersion then
            print(("^3[Quantum Projects]^7: You are running the latest version of ^2%s^7 (^2%s^7)."):format(resourceName, currentVersion))
        else
            print("\n^6========================================^7")
            print("^3[Quantum Projects]^7 Version Checker")
            print("")
            print(("^3Version Check^7:\n ^2Current^7: %s\n ^2Latest^7: %s\n"):format(currentVersion, newestVersion))
            print(("^1You are running an outdated version of %s.\n^6Visit Discord for News: ^4%s^7\n"):format(resourceName, discordLink))
            print("^6========================================^7\n")
        end
    end)
end

CheckVersion()
