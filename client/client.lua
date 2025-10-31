local RSGCore = exports['rsg-core']:GetCoreObject()
local isBusy = false
local PlacedApiaries = {}
local HarvestedPlants = {}
local bees_cloud_group = "core"
local bees_cloud_name = "ent_amb_insect_bee_swarm"
local BeeSwarms = {}
local canHarvest = true
lib.locale()

---------------------------------------------
-- Do Animation
-- This function plays the harvesting animation for the player
---------------------------------------------
local function DoAnim(PedID, duration)
    ClearPedTasks(PedID)
    SetCurrentPedWeapon(PedID, `WEAPON_UNARMED`, true)

    local animDict = "mech_pickup@plant@berries"
    local animName = "base"

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(0) end
    
    TaskPlayAnim(PedID, animDict, animName, 1.0, 0.5, duration, 1, 0.0, false, false, false)
end
---------------------------------------------
-- Can Place Apiary Location
-- This function checks if the player can place an apiary at the specified position
-- It checks if the position is in a town and if there are no other apiaries nearby
-- Returns true if the apiary can be placed, false otherwise
---------------------------------------------
local function CanPlaceApiaryLoc(pos)
    local canPlace = true

    local ZoneTypeId = 1
    local x,y,z =  table.unpack(GetEntityCoords(cache.ped))
    local town = Citizen.InvokeNative(0x43AD8FC02B429D33, x,y,z, ZoneTypeId)
    if town ~= false then
        canPlace = false
    end

    for i = 1, #Config.Apiaries do
        if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config.Apiaries[i].x, Config.Apiaries[i].y, Config.Apiaries[i].z, true) < 1.3 then
            canPlace = false
        end
    end
    return canPlace
end
---------------------------------------------
-- Notify function
-- This function is used to display notifications to the player
---------------------------------------------
RegisterNetEvent('qc-beekeeping:Notify', function(Title, Text, Time)
    Config.Notify(Title, Text, Time)
end)
---------------------------------------------
-- Apiary Menu
-- This event is triggered when the player interacts with an apiary
-- It retrieves the apiary data from the server and sends it to the NUI for display
---------------------------------------------
RegisterNetEvent('qc-beekeeping:client:ApiaryMenu', function(id)
    RSGCore.Functions.TriggerCallback('qc-beekeeping:server:GetApiaryData', function(result)
        if not result or not result[1] then return end
        local apiarydata = result[1].properties
        apiarydata.id = id
        local queenVal = result[1].queen
        local hasQueen = queenVal == true or queenVal == 1 or queenVal == "1"
        if not hasQueen then
            TriggerEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('no_queen_in_apiary'), 2000)
            return
        end

        apiarydata.necneed = tonumber(apiarydata.necneed or 0)
        apiarydata.polneed = tonumber(apiarydata.polneed or 0)
        apiarydata.quality = tonumber(apiarydata.quality or 0)

        local function getColorScheme(val)
            if val <= 10 then return 'red'
            elseif val <= 50 then return 'yellow'
            else return 'green' end
        end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openPlantMenu",
            data = {
                id = apiarydata.id,
                growth = apiarydata.growth,
                quality = apiarydata.quality,
                necneed = apiarydata.necneed,
                polneed = apiarydata.polneed,
                necneedColor = getColorScheme(apiarydata.necneed),
                polneedColor = getColorScheme(apiarydata.polneed),
                qualityColor = getColorScheme(apiarydata.quality)
            }
        })
    end, id)
end)

---------------------------------------------
-- Add Queen to Apiary
-- This event is triggered when the player wants to add a queen to an apiary
---------------------------------------------
RegisterNetEvent('qc-beekeeping:client:AddQueen', function(id)
    RSGCore.Functions.TriggerCallback('qc-beekeeping:server:GetApiaryData', function(result)
        if not result or not result[1] then return end

        local apiarydata = result[1].properties
        apiarydata.id = id
        apiarydata.queen = result[1].queen
        local apiaryType = result[1].type

        print(('qc-beekeeping:client:AddQueen called with id: %s, type: %s'):format(id, apiaryType))

        if apiarydata.queen then
            TriggerEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('queen_already_in_apiary'), 2000)
            return
        end

        local matchedConfig = nil
        for key, config in pairs(Config.ApiarieItems) do
            print(('Checking config key: %s, type: %s'):format(key, config.type))
            if config.type == apiaryType then
                matchedConfig = config
                break
            end
        end

        if not matchedConfig then
            TriggerEvent('qc-beekeeping:Notify', '~#ff0000~Error', 'No matching config for this apiary type.', 2000)
            return
        end

        print("Allowed queen items for this apiary:")
        for _, q in ipairs(matchedConfig.bees or {}) do
            print(" -", q)
        end

        local hasItem = nil
        for _, queenItem in ipairs(matchedConfig.bees or {}) do
            if RSGCore.Functions.HasItem(queenItem) then
                hasItem = queenItem
                break
            end
        end

        if not hasItem then
            TriggerEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('you_have_no_queen_items'), 2000)
            return
        end
        TriggerServerEvent('qc-beekeeping:server:AddQueenToApiary', id, hasItem)
    end, id)
end)

RegisterNetEvent('qc-beekeeping:client:PickUpApiary', function(id)
    RSGCore.Functions.TriggerCallback('qc-beekeeping:server:GetApiaryData', function(result)
        if not result or not result[1] then return end
        local ped = PlayerPedId()  -- Retrieve the ped
        local pcid = RSGCore.Functions.GetPlayerData().citizenid
        local apiarydata = result[1].properties
        local cid = result[1].cid
        apiarydata.id = id
        --print(('qc-beekeeping:client:PickUpApiary called with id: %s, cid: %s, pcid: %s'):format(id, cid, pcid))
        if pcid ~= cid then
            TriggerEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('not_your_apiary'), 2000)
            return
        end
        ClearPedTasks(ped)
        lib.requestModel("p_shovel02x")
            while not HasModelLoaded("p_shovel02x") do
                Wait(1)
            end
        local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_Hand")
        local shovelObject = CreateObject(joaat("p_shovel02x"), GetEntityCoords(ped), true, true, true)
        SetEntityCoords(shovelObject, GetEntityCoords(ped))
        AttachEntityToEntity(shovelObject, ped, boneIndex, 0.0, -0.19, -0.089, 274.1899, 483.89, 378.40, true, true, false, true, 1, true)
        lib.requestAnimDict("amb_work@world_human_gravedig@working@male_b@base")
        while not HasAnimDictLoaded("amb_work@world_human_gravedig@working@male_b@base") do
            Wait(100)
        end
        TaskPlayAnim(ped, "amb_work@world_human_gravedig@working@male_b@base", "base", 3.0, 3.0, -1, 1, 0, false, false, false)
        local pos = GetEntityCoords(ped)
        local fertilizer = GetClosestObjectOfType(pos, 2.5, Config.RhododendronProp[1], false, false, false)
        if fertilizer then
            local fertilizerCoords = GetEntityCoords(fertilizer)
            SetEntityCoordsNoOffset(fertilizer, fertilizerCoords.x, fertilizerCoords.y, fertilizerCoords.z + 0.1, false, false, false)  -- We lift an object for the effect
        end
        LocalPlayer.state:set('inv_busy', true, true)
        lib.progressBar({
            duration = 7000,--10000
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disableControl = true,
            disable = {
                move = true,
                mouse = true,
            },
            label = locale('removing_apiary'),
        })
        TriggerServerEvent('qc-beekeeping:server:destroyApiary', id)
        ClearPedTasks(ped)
        DeleteObject(shovelObject)  -- Wiping a shovel after completion
        LocalPlayer.state:set('inv_busy', false, true)
    end, id)
end)
---------------------------------------------
-- NUI Callbacks
-- These callbacks handle the interactions from the NUI menu
---------------------------------------------
RegisterNUICallback("CloseMenu", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("PollinateApiary", function(data, cb)
    TriggerEvent('qc-beekeeping:client:PollinateApiary', { apiarieid = data.apiarieid })
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("NectarApiary", function(data, cb)
    TriggerEvent('qc-beekeeping:client:PutNectarApiary', { apiarieid = data.apiarieid })
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("HarvestApiary", function(data, cb)
    TriggerEvent('qc-beekeeping:client:HarvestApiary', { apiarieid = data.apiarieid, quality = data.quality })
    SetNuiFocus(false, false)
    cb("ok")
end)
---------------------------------------------
-- Pollinate Apiary
-- This event is triggered when the player wants to pollinate an apiary
---------------------------------------------
RegisterNetEvent('qc-beekeeping:client:PollinateApiary', function(data)

    local HasItem = RSGCore.Functions.HasItem(Config.PollenItem, 1)

    if HasItem and not isBusy then
        isBusy = true
        LocalPlayer.state:set("inv_busy", true, true)
        FreezeEntityPosition(cache.ped, true)
        Citizen.InvokeNative(0x5AD23D40115353AC, cache.ped, entity, -1)
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_FEED_PIGS`, 0, true)
        Wait(10000)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('qc-beekeeping:server:PollinateApiary', data.apiarieid)
        LocalPlayer.state:set("inv_busy", false, true)
        isBusy = false
    else
        TriggerEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('you_need_pollen'), 2000) --title, text, time
    end

end)
---------------------------------------------
-- Put Nectar in Apiary
-- This event is triggered when the player wants to put nectar in an apiary
---------------------------------------------
RegisterNetEvent('qc-beekeeping:client:PutNectarApiary', function(data)

    --local HasItem1 = RSGCore.Functions.HasItem(Config.RequiredItem, 1)
    local HasItem = RSGCore.Functions.HasItem(Config.NectarItem, 1)

    if HasItem --[[ and HasItem2  ]]and not isBusy then
        isBusy = true
        LocalPlayer.state:set("inv_busy", true, true)
        FreezeEntityPosition(cache.ped, true)
        Citizen.InvokeNative(0x5AD23D40115353AC, cache.ped, entity, -1)
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_FEED_PIGS`, 0, true)
        Wait(14000)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)
        TriggerServerEvent('qc-beekeeping:server:NectarFeeding', data.apiarieid)
        TriggerServerEvent('qc-beekeeping:server:UpdateApiaries')
        LocalPlayer.state:set("inv_busy", false, true)
        isBusy = false
    end
end)
---------------------------------------------
-- Harvest Apiary
-- This event is triggered when the player wants to harvest an apiary
-- It checks the quality of the apiary and if it's ready for harvest
---------------------------------------------
RegisterNetEvent('qc-beekeeping:client:HarvestApiary', function(data)
    if isBusy then return end

    RSGCore.Functions.TriggerCallback('qc-beekeeping:server:GetApiaryData', function(result)
        if not result or not result[1] then
            TriggerEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('no_plant_found'), 2000)
            return
        end
        local player = RSGCore.Functions.GetPlayerData().citizenid
        local apiowner = result[1].cid
        local apiarydata = result[1].properties
        --print(('qc-beekeeping:client:HarvestApiary called with id: %s, player: %s, owner: %s'):format(data.apiarieid, player, apiowner))
        if player ~= apiowner then
            TriggerEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('not_your_apiary'), 2000)
            return
        end

        if not apiarydata or not apiarydata.quality or apiarydata.quality < Config.HarvestLevel then
            TriggerEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('plant_not_grown'), 2000)
            return
        end

        isBusy = true
        LocalPlayer.state:set("inv_busy", true, true)
        table.insert(HarvestedPlants, data.apiarieid)
        DoAnim(cache.ped, 4000)
        lib.progressBar({
            duration = 4000,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disableControl = true,
            disable = {
                move = true,
                mouse = true,
            },
            label = locale('gathering_honey'),
        })
        TriggerServerEvent('qc-beekeeping:server:ApiaryHarvested', data.apiarieid)
        ClearPedTasks(cache.ped)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(cache.ped, false)

        TriggerServerEvent('qc-beekeeping:server:HarvestedApiary', data.apiarieid)
        LocalPlayer.state:set("inv_busy", false, true)
        isBusy = false
        canHarvest = true
    end, data.apiarieid)
end)

---------------------------------------------
-- Update Apiary Data
-- This event is triggered to update the apiary data in the client-side Config.Apiaries
-- It listens for the server event and updates the local database
---------------------------------------------
RegisterNetEvent('qc-beekeeping:client:UpdateApiaryData')
AddEventHandler('qc-beekeeping:client:UpdateApiaryData', function(data)
    Config.Apiaries = data
end)
---------------------------------------------
-- New Apiary Placement
-- This event is triggered when the player places a new apiary
-- It checks if the player can place the apiary in the current location
-- and then triggers the server event to place the new apiary
---------------------------------------------
RegisterNetEvent('qc-beekeeping:client:NewApiaryPlacement')
AddEventHandler('qc-beekeeping:client:NewApiaryPlacement', function(outputitem, inputitem, PropHash, pPos, heading)
    local pos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 1.0, 0.0)
    if Config.RestrictTowns then
        if CanPlaceApiaryLoc(pos) and not IsPedInAnyVehicle(cache.ped, false) and not isBusy then
            isBusy = true
            LocalPlayer.state:set("inv_busy", true, true)
            Wait(100)
            ClearPedTasks(cache.ped)
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
            FreezeEntityPosition(cache.ped, false)
            TriggerServerEvent('qc-beekeeping:server:RemoveItem', inputitem, 1)
            TriggerServerEvent('qc-beekeeping:server:PlaceNewApiary', outputitem, PropHash, pPos, heading)
            LocalPlayer.state:set("inv_busy", false, true)
            isBusy = false
            return
        end
        TriggerEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('cant_plant_here'), 2000) --title, text, time
    else
        if not IsPedInAnyVehicle(cache.ped, false) and not isBusy then
            isBusy = true
            LocalPlayer.state:set("inv_busy", true, true)
            Wait(100)
            ClearPedTasks(cache.ped)
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
            FreezeEntityPosition(cache.ped, false)
            TriggerServerEvent('qc-beekeeping:server:RemoveItem', inputitem, 1)
            TriggerServerEvent('qc-beekeeping:server:PlaceNewApiary', outputitem, PropHash, pPos, heading)
            LocalPlayer.state:set("inv_busy", false, true)
            isBusy = false
            return
        end
    end
end)
---------------------------------------------
-- Open Apiary Shop
-- This event is triggered when the player wants to open the apiary shop
---------------------------------------------
RegisterNetEvent('qc-beekeeping:client:OpenApiaryShop')
AddEventHandler('qc-beekeeping:client:OpenApiaryShop', function()
    TriggerServerEvent('rsg-shops:server:openstore', 'apiary', 'apiary', 'apiary')
end)
---------------------------------------------
-- Remove Apiary Object
-- This event is triggered when the player wants to remove an apiary object
-- It loops through the spawned plants and removes the specified apiary object
---------------------------------------------
RegisterNetEvent('qc-beekeeping:client:DelApiaryProp')
AddEventHandler('qc-beekeeping:client:DelApiaryProp', function(apiary)
    for i = 1, #PlacedApiaries do
        local o = PlacedApiaries[i]

        if o.id == apiary then
            SetEntityAsMissionEntity(o.obj, false, false)
            FreezeEntityPosition(o.obj, false)
            DeleteObject(o.obj)
        end
    end
end)
---------------------------------------------
-- Create Apiary Shop Blips
-- This thread creates blips for the apiary shop locations defined in Config.ApiaryShopLoc
---------------------------------------------
CreateThread(function()
    for _,v in pairs(Config.ApiaryShopLoc) do
        if v.showblip then
            local ApiaryShopBlip = BlipAddForCoords(1664425300, v.coords)
            SetBlipSprite(ApiaryShopBlip, joaat(Config.Blip.blipSprite), true)
            SetBlipScale(ApiaryShopBlip, Config.Blip.blipScale)
            SetBlipName(ApiaryShopBlip, Config.Blip.blipName)
        end
    end
end)
---------------------------------------------
-- Spawn Apiaries
-- This thread will spawn apiaries in the world based on the Config.Apiaries local database
-- It will check if the player is in range of any apiary and spawn it if it hasn't been spawned yet.
---------------------------------------------
CreateThread(function()
    while true do
        Wait(150)
        local pos = GetEntityCoords(cache.ped)
        local InRange = false
        for i = 1, #Config.Apiaries do
            local apiary = Config.Apiaries[i]
            local dist = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, apiary.x, apiary.y, apiary.z, true)
            if dist >= 50.0 then goto continue end
            local hasSpawned = false
            InRange = true
            for z = 1, #PlacedApiaries do
                local p = PlacedApiaries[z]
                if p.id == apiary.id then
                    hasSpawned = true
                end
            end
            if hasSpawned then goto continue end
            local ApiaryObj = apiary.hash
            local ApiHash = joaat(ApiaryObj)
            local data = {}
            while not HasModelLoaded(ApiHash) do
                Wait(10)
                lib.requestModel(ApiHash)
            end
            lib.requestModel(ApiHash)
            data.id = apiary.id
            data.obj = CreateObject(ApiHash, apiary.x, apiary.y, apiary.z, false, false, false)
            SetEntityHeading(data.obj, apiary.h)
            SetEntityAsMissionEntity(data.obj, true, false) -- Set the entity as mission entity
            PlaceObjectOnGroundProperly(data.obj)
            Wait(1000)
            FreezeEntityPosition(data.obj, true)
            SetModelAsNoLongerNeeded(data.obj)
            Citizen.InvokeNative(0xA10DB07FC234DD12, bees_cloud_group)
            local BeeFXSwarm = Citizen.InvokeNative(0xBA32867E86125D3A , bees_cloud_name, apiary.x, apiary.y, apiary.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
            BeeSwarms[#BeeSwarms + 1] = BeeFXSwarm
            -- Target
            exports['rsg-target']:AddTargetEntity(data.obj, {
                options = {
                    {
                        type = 'client',
                        event = 'qc-beekeeping:client:ApiaryMenu',
                        icon = 'fa-solid fa-house',
                        label = locale("open_apiary_menu"),
                        action = function()
                            TriggerEvent('qc-beekeeping:client:ApiaryMenu', data.id)
                        end
                    },
                    {
                        type = 'client',
                        event = 'qc-beekeeping:client:AddQueen',
                        icon = 'fa-solid fa-crown',
                        label = locale("add_queen_to_apiary"),
                        action = function()
                            TriggerEvent('qc-beekeeping:client:AddQueen', data.id)
                        end
                    },
                    {
                        type = 'client',
                        event = 'qc-beekeeping:client:PickUpApiary',
                        icon = 'fa-solid fa-trash',
                        label = locale("remove_apiary"),
                        action = function()
                            TriggerEvent('qc-beekeeping:client:PickUpApiary', data.id)
                        end
                    }   
                },
                distance = 3
            })
            PlacedApiaries[#PlacedApiaries + 1] = data
            hasSpawned = false
            ::continue::
        end

        if not InRange then
            Wait(5000)
        end
    end
end)
---------------------------------------------
-- Create Apiary Shop Prompts
-- This thread creates prompts for the apiary shop locations defined in Config.ApiaryShopLoc
-- It also creates blips and markers if enabled in the configuration
---------------------------------------------
Citizen.CreateThread(function()
    for ApiaryShop, v in pairs(Config.ApiaryShopLoc) do
        -- Creating prompt to open the shop
        exports['rsg-core']:createPrompt(v.name, v.coords, 0xF3830D8E, locale('menu.open') .. " " .. v.name, {
            type = 'client',
            event = 'qc-beekeeping:client:OpenApiaryShop',
        })

        -- Adding the Ballet if enabled
        if v.showblip then
            local ApiaryShopBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.coords)
            SetBlipSprite(ApiaryShopBlip, joaat(Config.Blip.blipSprite), true)
            SetBlipScale(ApiaryShopBlip, Config.Blip.blipScale)
            Citizen.InvokeNative(0x9CB1A1623062F402, ApiaryShopBlip, Config.Blip.blipName)
        end

        -- Marker display if enabled
        if v.showmarker then
            Citizen.CreateThread(function()
                while true do
                    Citizen.InvokeNative(0x2A32FAA57B937173, 0x07DCE236, v.coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 215, 0, 155, false, false, false, 1, false, false, false)
                    Wait(0)
                end
            end)
        end
    end
end)

---------------------------------------------
-- Cleanup on Resource Stop
-- This event is triggered when the resource stops
-- It cleans up all spawned apiary objects and particle effects
---------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for i = 1, #PlacedApiaries do
        local Apiaries = PlacedApiaries[i].obj
        SetEntityAsMissionEntity(Apiaries, false, false)
        FreezeEntityPosition(Apiaries, false)
        DeleteObject(Apiaries)
    end

    for _,Swarm in ipairs(BeeSwarms) do
        StopParticleFxLooped(Swarm,true)
    end
end)
