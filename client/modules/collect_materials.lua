local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

local function DoAnim(PedID, duration)
    ClearPedTasks(PedID)
    SetCurrentPedWeapon(PedID, `WEAPON_UNARMED`, true)

    local animDict = "mech_pickup@plant@berries"
    local animName = "base"

    lib.requestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(0) end
    
    TaskPlayAnim(PedID, animDict, animName, 1.0, 0.5, duration, 1, 0.0, false, false, false)
end
---------------------------------------------
-- Gather RhododendronProp
---------------------------------------------
CreateThread(function()
    exports['rsg-target']:AddTargetModel(Config.RhododendronProp, {
        options = {
            {
                type = 'client',
                event = 'qc-beekeeping:client:CollectNectar',
                icon = 'fas fa-flask',
                label = locale('gathering_nectar_target'),
            }
        },
        distance = 2.0
    })

    exports['rsg-target']:AddTargetModel(Config.PollenPlants, {
        options = {
            {
                type = 'client',
                event = 'qc-beekeeping:client:CollectPollen',
                icon = 'fas fa-leaf',
                label = locale('gathering_pollen_target'),
            }
        },
        distance = 1.5
    })
end)

---------------------------------------------
-- Collect Pollen Event
---------------------------------------------
RegisterNetEvent('qc-beekeeping:client:CollectPollen', function()
    local ped = PlayerPedId()  -- Retrieve the ped
    local ReqItem = RSGCore.Functions.HasItem(Config.RequiredItem , 1)

--[[     if not ReqItem then
        -- Notification that the player does not have a bucket
        TriggerEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('you_need_bucket_collect_pollen'), 2000) --title, text, time
        return
    end ]]

   -- if ped then
        -- Notification that the player begins with the collection of water
        TriggerEvent('qc-beekeeping:Notify', '~#00ff00~'..locale('success'), locale('collecting_nectar'), 5000) --title, text, timeTriggerClientEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('need_bucket_collect_rhond'), 2000) --title, text, time
        -- Let's clean the previous animation
        ClearPedTasks(ped)

        lib.requestModel("p_shovel02x")  -- Shovel model
            while not HasModelLoaded("p_shovel02x") do
                Wait(1)
            end
        local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_Hand")  -- Players' hand
        shovelObject = CreateObject(joaat("p_shovel02x"), GetEntityCoords(ped), true, true, true)
        SetEntityCoords(shovelObject, GetEntityCoords(ped))
        AttachEntityToEntity(shovelObject, ped, boneIndex, 0.0, -0.19, -0.089, 274.1899, 483.89, 378.40, true, true, false, true, 1, true)

        lib.requestAnimDict("amb_work@world_human_gravedig@working@male_b@base")
            while not HasAnimDictLoaded("amb_work@world_human_gravedig@working@male_b@base") do
                Wait(100)
            end
        TaskPlayAnim(ped, "amb_work@world_human_gravedig@working@male_b@base", "base", 3.0, 3.0, -1, 1, 0, false, false, false)
        
        -- Progress bar to collect water
        LocalPlayer.state:set('inv_busy', true, true)
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
            label = locale('gathering_pollen'),
        })
        -- Let's clean the animation after the collection has been completed
        ClearPedTasks(ped)
        DeleteObject(shovelObject)
        -- Notification that the process is completed
        TriggerEvent('qc-beekeeping:Notify', '~#00ccff~'..locale('finished'), locale('youve_got_pollen'), 5000) --title, text, time
        -- We'll give a player full of bucket
        LocalPlayer.state:set('inv_busy', false, true)
        TriggerServerEvent('qc-beekeeping:server:GiveItem', Config.PollenItem, 1)
   -- end
end)

---------------------------------------------
-- Collect Nectar Event
---------------------------------------------
RegisterNetEvent('qc-beekeeping:client:CollectNectar', function()
    local ped = PlayerPedId()  -- Retrieve the ped
    local ReqItem = RSGCore.Functions.HasItem(Config.RequiredItem, 1)
    if not ReqItem then
        -- Notification that the player does not have a bucket
        TriggerEvent('qc-beekeeping:Notify', '~#ff0000~'..locale('error'), locale('need_bucket_collect_rhond'), 2000) --title, text, time
        return
    end
    if ReqItem then
        -- Notification that the player begins with the collection of fertilizers
        TriggerEvent('qc-beekeeping:Notify', '~#00ff00~'..locale('success'), locale('collecting_rhond'), 5000) --title, text, time
        --clean the previous animation
        ClearPedTasks(ped)
        -- We create a shovel and join it with a hand
        lib.requestModel("p_shovel02x")  -- Shovel model
            while not HasModelLoaded("p_shovel02x") do
                Wait(1)
            end
        local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_Hand")  -- Players' hand
        shovelObject = CreateObject(joaat("p_shovel02x"), GetEntityCoords(ped), true, true, true)
        SetEntityCoords(shovelObject, GetEntityCoords(ped))
        AttachEntityToEntity(shovelObject, ped, boneIndex, 0.0, -0.19, -0.089, 274.1899, 483.89, 378.40, true, true, false, true, 1, true)

        -- We are launching the animation to collect fertilizers
        lib.requestAnimDict("amb_work@world_human_gravedig@working@male_b@base")
        while not HasAnimDictLoaded("amb_work@world_human_gravedig@working@male_b@base") do
            Wait(100)
        end
        TaskPlayAnim(ped, "amb_work@world_human_gravedig@working@male_b@base", "base", 3.0, 3.0, -1, 1, 0, false, false, false)
        -- We start the light effect around the facility (if necessary)
        local pos = GetEntityCoords(ped)
        local fertilizer = GetClosestObjectOfType(pos, 2.5, Config.RhododendronProp[1], false, false, false)
        if fertilizer then
            local fertilizerCoords = GetEntityCoords(fertilizer)
            SetEntityCoordsNoOffset(fertilizer, fertilizerCoords.x, fertilizerCoords.y, fertilizerCoords.z + 0.1, false, false, false)  -- We lift an object for the effect
        end
        -- Progress bar for gathering fertilizers
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
            label = locale('gathering_rhond'),
        })
        -- Let's clean the animation after the collection has been completed
        ClearPedTasks(ped)
        DeleteObject(shovelObject)  -- Wiping a shovel after completion

        -- Notification that the process is completed
        TriggerEvent('qc-beekeeping:Notify', '~#00ccff~'..locale('finished'), locale('youve_got_bucketful_rhond'), 5000) --title, text, time

        -- We'll give a player full of bucket
        LocalPlayer.state:set('inv_busy', false, true)
        TriggerServerEvent('qc-beekeeping:server:GiveItem', Config.RhododItem, 1)
       -- We remove the light effect (if used)
if fertilizer then
    DeleteEntity(fertilizer)  -- We wipe the facility (fertilizer)
end

    end
end)
