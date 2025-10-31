local spawnedPeds = {}

---------------------------------------------
-- Spawning NPCs for Apiary Shop
---------------------------------------------
local function NearPed(npcmodel, npccoords)
    RequestModel(npcmodel)
    while not HasModelLoaded(npcmodel) do
        Wait(50)
    end
    spawnedPed = CreatePed(npcmodel, npccoords.x, npccoords.y, npccoords.z - 1.0, npccoords.w, false, false, 0, 0)
    SetEntityAlpha(spawnedPed, 0, false)
    SetRandomOutfitVariation(spawnedPed, true)
    SetEntityCanBeDamaged(spawnedPed, false)
    SetEntityInvincible(spawnedPed, true)
    FreezeEntityPosition(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    -- set relationship group between npc and player
    SetPedRelationshipGroupHash(spawnedPed, GetPedRelationshipGroupHash(spawnedPed))
    SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(spawnedPed), `PLAYER`)
    if Config.Debug then
        local relationship = GetRelationshipBetweenGroups(GetPedRelationshipGroupHash(spawnedPed), `PLAYER`)
        print(relationship)
    end
    -- end of relationship group
    if Config.FadeIn then
        for i = 0, 255, 51 do
            Citizen.Wait(50)
            SetEntityAlpha(spawnedPed, i, false)
        end
    end
    -- target start
    exports['rsg-target']:AddTargetEntity(spawnedPed, {
        options = {
            {
                icon = 'fa-solid fa-eye',
                label = 'Open Farm Shop',
                targeticon = 'fa-solid fa-eye',
                action = function()
                    TriggerEvent('qc-beekeeping:client:OpenApiaryShop')
                end
            },
        },
        distance = 2.0,
    })
    -- target end
    return spawnedPed
end
---------------------------------------------
-- Thread to spawn NPCs for Apiary Shop
-- This thread checks the distance to the NPCs and spawns them if the player is close enough.
---------------------------------------------
CreateThread(function()
    while true do
        Wait(500)
        for k,v in pairs(Config.ApiaryShopLoc) do
            local playerCoords = GetEntityCoords(cache.ped)
            local distance = #(playerCoords - v.npccoords.xyz)

            if distance < Config.DistanceSpawn and not spawnedPeds[k] then
                local spawnedPed = NearPed(v.npcmodel, v.npccoords)
                spawnedPeds[k] = { spawnedPed = spawnedPed }
            end
            
            if distance >= Config.DistanceSpawn and spawnedPeds[k] then
                if Config.FadeIn then
                    for i = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(spawnedPeds[k].spawnedPed, i, false)
                    end
                end
                DeletePed(spawnedPeds[k].spawnedPed)
                spawnedPeds[k] = nil
            end
        end
    end
end)

---------------------------------------------
-- Cleanup spawned NPCs when the resource stops
-- This ensures that all NPCs are deleted when the resource is stopped to prevent memory leaks or leftover entities.
---------------------------------------------
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k,v in pairs(spawnedPeds) do
        DeletePed(spawnedPeds[k].spawnedPed)
        spawnedPeds[k] = nil
    end
end)
