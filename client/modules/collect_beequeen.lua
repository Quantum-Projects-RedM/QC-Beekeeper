local RSGCore = exports['rsg-core']:GetCoreObject()
local CreatedWildBeehives = {}
local SmokedBeehives = {}
local TakenQueenBeehives = {}
local bees_cloud_group = "core"
local bees_cloud_name = "ent_amb_insect_bee_swarm"
local BeeSwarms = {}
lib.locale()


CreateThread(function()
    while true do
        Wait(150)
        local pos = GetEntityCoords(cache.ped)
        local inRange = false

        for i = 1, #Config.WildHives do
            local hive = Config.WildHives[i]
            local dist = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, hive.x, hive.y, hive.z, true)

            if dist >= 50.0 then goto continue end
            inRange = true

            local alreadySpawned = false
            for _, placed in ipairs(CreatedWildBeehives) do
                if placed then
                    local entCoords = GetEntityCoords(placed)
                    if #(vector3(entCoords.x, entCoords.y, entCoords.z) - vector3(hive.x, hive.y, hive.z)) < 0.5 then
                        alreadySpawned = true
                        break
                    end
                end
            end

            if alreadySpawned then goto continue end

            local model = joaat(Config.WildHiveModel)
            lib.requestModel(model)
            while not HasModelLoaded(model) do Wait(10) end

            local obj = CreateObject(model, hive.x, hive.y, hive.z, false, false, false)
            SetEntityHeading(obj, hive.heading)
            FreezeEntityPosition(obj, true)
            SetEntityInvincible(obj, true)
            SetEntityAsMissionEntity(obj, true, false)
            PlaceObjectOnGroundProperly(obj)
            Citizen.InvokeNative(0x203BEFFDBE12E96A, obj, hive.x, hive.y, hive.z, hive.heading, hive.rotx, hive.roty, hive.rotz)

            table.insert(CreatedWildBeehives, obj)

            -- Bee swarm FX
            Citizen.InvokeNative(0xA10DB07FC234DD12, bees_cloud_group)
            local BeeFXSwarm = Citizen.InvokeNative(0xBA32867E86125D3A, bees_cloud_name, hive.x, hive.y, hive.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
            BeeSwarms[#BeeSwarms + 1] = BeeFXSwarm

            -- Add interaction targets
            exports['rsg-target']:AddTargetEntity(obj, {
                options = {
                    {
                        type = 'client',
                        event = 'qc-beekeeping:client:SmokeBeehive',
                        icon = 'fas fa-smoking',
                        label = locale("smoke_beehive")
                    },
                    {
                        type = 'client',
                        event = 'qc-beekeeping:client:TakeQueen',
                        icon = 'fas fa-crown',
                        label = locale("take_queen")
                    }
                },
                distance = 2.0
            })

            ::continue::
        end

        if not inRange then
            Wait(5000)
        end
    end
end)

RegisterNetEvent('qc-beekeeping:client:SmokeBeehive', function ()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local hasItem = RSGCore.Functions.HasItem(Config.SmokerItem, 1)

    -- Uncomment if bee jar is required
     if not hasItem then
         TriggerEvent('qc-beekeeping:Notify','~#ff0000~'..locale('error'), locale("missing_bee_smoker"))
         return
     end

    for i, hive in ipairs(Config.WildHives) do
        local dist = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, hive.x, hive.y, hive.z, true)

        if dist < 2.0 then
            if SmokedBeehives[i] then
                TriggerEvent('qc-beekeeping:Notify','~#ff0000~'..locale('error'), locale("already_smoked"))
                return
            end

            local prop_name = "p_bugkiller01x"
            local prop = CreateObject(joaat(prop_name), coords.x, coords.y, coords.z, true, true, true)
            SetEntityAsMissionEntity(prop, true, true)
            AttachEntityToEntity(prop, ped, GetEntityBoneIndexByName(ped, "SKEL_R_FINGER00"), 0.2, -0.2, -0.0, -40.0, 50.0, 30.0, true, true, false, true, 1, true)

            lib.requestAnimDict("script_rc@gun5@ig@stage_01@ig3_bellposes")
            while not HasAnimDictLoaded("script_rc@gun5@ig@stage_01@ig3_bellposes") do
                Wait(100)
            end

            TaskPlayAnim(ped, "script_rc@gun5@ig@stage_01@ig3_bellposes", "pose_01_idle_famousgunslinger_05", 1.0, 8.0, -1, 1, 0, false, false, false)
            Wait(Config.SmokeTime * 1000)
            ClearPedTasks(ped)

            local done = false
            CreateThread(function()
                while not done do
                    Wait(100)
                    if not IsEntityPlayingAnim(ped, "script_rc@gun5@ig@stage_01@ig3_bellposes", "pose_01_idle_famousgunslinger_05", 3) then
                        DeleteEntity(prop)
                        done = true
                    end
                end
            end)

            -- Mark hive as smoked
            SmokedBeehives[i] = true
            --TriggerEvent('qc-beekeeping:client:BeehiveSmoked', i)
            table.insert(SmokedBeehives, i)
            TriggerEvent('qc-beekeeping:Notify', '~#7DDA58~'..locale('success'), locale("beehive_smoked"))
            break
        end
    end
end)

RegisterNetEvent('qc-beekeeping:client:TakeQueen', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local hasItem = RSGCore.Functions.HasItem(Config.BeeJar, 1)

    -- Uncomment if bee jar is required
     if not hasItem then
         TriggerEvent('qc-beekeeping:Notify','~#ff0000~'..locale('error'), locale("missing_bee_jar"))
         return
     end

    for i, hive in ipairs(Config.WildHives) do
        local dist = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, hive.x, hive.y, hive.z, true)

        if dist < 2.0 then
            if TakenQueenBeehives and TakenQueenBeehives[i] then
                TriggerEvent('qc-beekeeping:Notify','~#ff0000~'..locale('error'), locale("queen_already_taken"))
                return
            end

            -- Uncomment if bees must be smoked before queen can be taken
             if not SmokedBeehives or not SmokedBeehives[i] then
                 TriggerEvent('qc-beekeeping:Notify','~#ff0000~'..locale('error'), locale("wildhive_not_smoked"))
                 return
             end

            local prop_name = "mp005_s_posse_col_net01x"
            local prop = CreateObject(joaat(prop_name), coords.x, coords.y, coords.z, true, true, false)
            SetEntityAsMissionEntity(prop, true, true)
            AttachEntityToEntity(prop, ped, GetEntityBoneIndexByName(ped, "PH_L_Hand"), 0.0, 0.0, -0.45, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

            local animDict = "mini_games@fishing@shore"
            local animName = "cast"
            lib.requestAnimDict(animDict)
            while not HasAnimDictLoaded(animDict) do Wait(10) end

            TaskPlayAnim(ped, animDict, animName, 1.0, -1.0, -1, 1, 0, false, false, false)
            Wait(Config.GetQueenTime * 1000)
            ClearPedTasks(ped)

            -- Cleanup prop
            CreateThread(function()
                while true do
                    Wait(100)
                    if not IsEntityPlayingAnim(ped, animDict, animName, 3) then
                        DeleteEntity(prop)
                        break
                    end
                end
            end)

            -- Mark hive as queen taken
            TakenQueenBeehives = TakenQueenBeehives or {}
            TakenQueenBeehives[i] = true

            -- Give queen item using existing GiveItem event
            local queenItem = hive.queen or "honey_bee_queen"
            local amount = 1
            TriggerServerEvent('qc-beekeeping:server:GiveItem', queenItem, amount)

            TriggerEvent('qc-beekeeping:Notify', '~#7DDA58~'..locale('success'), locale("queen_collected"))
            break
        end
    end
end)

--[[ RegisterNetEvent('qc-beekeeping:client:BeehiveSmoked',function(CurrentHive)
    table.insert(SmokedBeehives,CurrentHive)
end) ]]

RegisterNetEvent('qc-beekeeping:client:QueenTakenFromHive',function(CurrentHive)
    table.insert(TakenQueenBeehives,CurrentHive)
end)

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, obj in ipairs(CreatedWildBeehives) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end

    for _,Swarm in ipairs(BeeSwarms) do
        StopParticleFxLooped(Swarm,true)
        print("Stopping particle fx: " .. bees_cloud_name)
    end
end)
