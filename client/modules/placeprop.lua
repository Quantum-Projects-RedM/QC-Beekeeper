local RSGCore = exports['rsg-core']:GetCoreObject()

math.randomseed(GetGameTimer())
local CancelPrompt
local SetPrompt
local RotateLeftPrompt
local RotateRightPrompt
local active = false
local Props = {}

local PromptPlacerGroup = GetRandomIntInRange(0, 0xffffff)

Citizen.CreateThread(function()
    Set()
    Del()
    RotateLeft()
    RotateRight()
end)

function Del()
    Citizen.CreateThread(function()
        local str = Config.PromptCancelName
        CancelPrompt = PromptRegisterBegin()
        PromptSetControlAction(CancelPrompt, 0xF84FA74F)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(CancelPrompt, str)
        PromptSetEnabled(CancelPrompt, true)
        PromptSetVisible(CancelPrompt, true)
        PromptSetHoldMode(CancelPrompt, true)
        PromptSetGroup(CancelPrompt, PromptPlacerGroup)
        PromptRegisterEnd(CancelPrompt)
    end)
end

function Set()
    Citizen.CreateThread(function()
        local str = Config.PromptPlaceName
        SetPrompt = PromptRegisterBegin()
        PromptSetControlAction(SetPrompt, 0xC7B5340A)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(SetPrompt, str)
        PromptSetEnabled(SetPrompt, true)
        PromptSetVisible(SetPrompt, true)
        PromptSetHoldMode(SetPrompt, true)
        PromptSetGroup(SetPrompt, PromptPlacerGroup)
        PromptRegisterEnd(SetPrompt)
    end)
end

function RotateLeft()
    Citizen.CreateThread(function()
        local str = Config.PromptRotateLeft
        RotateLeftPrompt = PromptRegisterBegin()
        PromptSetControlAction(RotateLeftPrompt, 0xA65EBAB4)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(RotateLeftPrompt, str)
        PromptSetEnabled(RotateLeftPrompt, true)
        PromptSetVisible(RotateLeftPrompt, true)
        PromptSetStandardMode(RotateLeftPrompt, true)
        PromptSetGroup(RotateLeftPrompt, PromptPlacerGroup)
        PromptRegisterEnd(RotateLeftPrompt)
    end)
end

function RotateRight()
    Citizen.CreateThread(function()
        local str = Config.PromptRotateRight
        RotateRightPrompt = PromptRegisterBegin()
        PromptSetControlAction(RotateRightPrompt, 0xDEB34313)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(RotateRightPrompt, str)
        PromptSetEnabled(RotateRightPrompt, true)
        PromptSetVisible(RotateRightPrompt, true)
        PromptSetStandardMode(RotateRightPrompt, true)
        PromptSetGroup(RotateRightPrompt, PromptPlacerGroup)
        PromptRegisterEnd(RotateRightPrompt)

    end)
end

local function RotationToDirection(rotation)
    local adjustedRotation =
    {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction =
    {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end


function PropPlacer(outputitem, prop, inputitem)
    local myPed = PlayerPedId()
    local PropHash = prop
    local heading = 0.0
    local confirmed = false

    lib.requestModel(PropHash)
    while not HasModelLoaded(PropHash) do
        Wait(100)
    end

    local coords = GetEntityCoords(myPed)
    local forward = GetEntityForwardVector(myPed)
    local placementPos = coords - forward * -Config.ForwardDistance

    SetCurrentPedWeapon(myPed, -1569615261, true)

    local tempObj = CreateObject(PropHash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityAlpha(tempObj, 60)
    FreezeEntityPosition(tempObj, true)
    SetEntityCollision(tempObj, false, false)

    CreateThread(function()
        while not confirmed do
            local hit, coords, _ = RayCastGamePlayCamera(1000.0)
            if hit then
                SetEntityCoordsNoOffset(tempObj, coords.x, coords.y, coords.z, false, false, false, true)
            end

            SetEntityAlpha(tempObj, 150, false)
            SetEntityHeading(tempObj, heading)

            -- Prompt group setup
            local groupName = CreateVarString(10, 'LITERAL_STRING', Config.PromptGroupName)
            PromptSetActiveGroupThisFrame(PromptPlacerGroup, groupName)

            -- Heading adjustments
            if IsControlPressed(0, 0xA65EBAB4) then
                heading = (heading + 1.0) % 360.0
            elseif IsControlPressed(0, 0xDEB34313) then
                heading = (heading - 1.0) % 360.0
            end

            -- Confirmation
            if PromptHasHoldModeCompleted(SetPrompt) then
                confirmed = true

                -- Placement animation
                local placingAnim = {
                    duration = 15000,
                    label = 'Placing Apiary',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { car = true },
                    anim = IsPedMale(myPed) and { scenario = "WORLD_HUMAN_SLEDGEHAMMER" } or nil
                }
                lib.progressBar(placingAnim)

                -- Finalize
                SetEntityAlpha(tempObj, 255, false)
                SetEntityCollision(tempObj, true, true)
                FreezeEntityPosition(tempObj, false)

                TriggerEvent('qc-beekeeping:client:NewApiaryPlacement', outputitem, inputitem, PropHash, coords, heading)
                print(('qc-beekeeping:client:NewApiaryPlacement called with outputitem: %s, inputitem: %s, prop: %s, coords: %s, heading: %s'):format(outputitem, inputitem, PropHash, coords, heading))

                DeleteObject(tempObj)
                SetModelAsNoLongerNeeded(PropHash)
                return
            end

            -- Cancel
            if PromptHasHoldModeCompleted(CancelPrompt) then
                print("[BeeKeeper] Placement canceled.")
                DeleteObject(tempObj)
                SetModelAsNoLongerNeeded(PropHash)
                return
            end

            Wait(0)
        end
    end)
end

RegisterNetEvent('qc-beekeeping:client:PlaceApiary', function( outputitem, prop, inputitem )
    PropPlacer(outputitem, prop, inputitem)
    print(('qc-beekeeping:client:PlaceApiary called with outputitem: %s, prop: %s, inputitem: %s'):format(outputitem, prop, inputitem))
end)
