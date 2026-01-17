-- RSGCore Stable Client
-- Variables

cam = nil
hided = false
spawnedCamera = nil
choosePed = {}
pedSelected = nil
sex = nil
zoom = 4.0
offset = 0.2
DeleteeEntity = true

local InterP = true
local adding = true
local showroomHorse_entity
local showroomHorse_model
local MyHorse_entity
local IdMyHorse
local saddlecloths = {}
local acshorn = {}
local bags = {}
local horsetails = {}
local manes = {}
local saddles = {}
local stirrups = {}
local acsluggage = {}
local promptGroup
local varStringCasa = CreateVarString(10, "LITERAL_STRING", Lang:t('stable.stable'))
local blip
local prompts = {}
local SpawnPoint = {}
local StablePoint = {}
local HeadingPoint
local CamPos = {}
local CamPosGear = {}
local SpawnplayerHorse = 0
local horseModel
local horseName
local horseComponents = {}
local initializing = false
local alreadySentShopData = false

myHorses = {}
SaddlesUsing = nil
SaddleclothsUsing = nil
StirrupsUsing = nil
BagsUsing = nil
ManesUsing = nil
HorseTailsUsing = nil
AcsHornUsing = nil
AcsLuggageUsing = nil

cameraUsing = {
    {
        name = "Horse",
        x = 0.2,
        y = 0.0,
        z = 1.8
    },
    {
        name = "Olhos",
        x = 0.0,
        y = -0.4,
        z = 0.65
    }
}

-- Functions

local function SetHorseInfo(horse_model, horse_name, horse_components)
    horseModel = horse_model
    horseName = horse_name
    horseComponents = horse_components
end

local function NativeSetPedComponentEnabled(ped, component)
    Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, component, true, true, true)
end

local function createCamera(entity)
    if not CamPos then 
        print("ERROR: No CamPos defined")
        return 
    end
    
    -- CamPos now holds {x, y, z, rx, ry, rz}
    local finalX = CamPos.x
    local finalY = CamPos.y
    local finalZ = CamPos.z
    local rotX = CamPos.rx
    local rotY = CamPos.ry or 0.0
    local rotZ = CamPos.rz

    groundCam = CreateCam("DEFAULT_SCRIPTED_CAMERA")
    SetCamCoord(groundCam, finalX, finalY, finalZ)
    SetCamRot(groundCam, rotX, rotY, rotZ, 2)
    
    SetCamActive(groundCam, true)
    RenderScriptCams(true, false, 1, true, true)
    
    fixedCam = CreateCam("DEFAULT_SCRIPTED_CAMERA")
    SetCamCoord(fixedCam, finalX, finalY, finalZ)
    SetCamRot(fixedCam, rotX, rotY, rotZ, 2)
    SetCamActive(fixedCam, true)
end


local function getShopData()
    alreadySentShopData = true
    return Config.Horses
end

local function setcloth(hash)
    if not MyHorse_entity then return end
    local model2 = GetHashKey(tonumber(hash))
    if not HasModelLoaded(model2) then
        Citizen.InvokeNative(0xFA28FE3A6246FC30, model2)
    end
    Citizen.InvokeNative(0xD3A7B003ED343FD9, MyHorse_entity, tonumber(hash), true, true, true)
end

local function OpenStable()
    inCustomization = true
    horsesp = true
    DeleteeEntity = true
    SetNuiFocus(true, true)
    InterP = true
    
    -- Safety check for MyHorse_entity
    if MyHorse_entity and DoesEntityExist(MyHorse_entity) then
        SetEntityHeading(MyHorse_entity, 334.0)
        createCamera(PlayerPedId())
    else
        createCamera(PlayerPedId())
    end
    
    if not alreadySentShopData then
        SendNUIMessage({
            action = "show",
            shopData = getShopData()
        })
    else
        SendNUIMessage({
            action = "show"
        })
    end
    TriggerServerEvent("rsg-stable:AskForMyHorses")
end

local function rotation(dir)
    local playerHorse = MyHorse_entity
    if not playerHorse or not DoesEntityExist(playerHorse) then 
        playerHorse = showroomHorse_entity 
    end
    
    if playerHorse and DoesEntityExist(playerHorse) then
        local pedRot = GetEntityHeading(playerHorse) + dir
        SetEntityHeading(playerHorse, pedRot % 360)
    end
end

local function SetHorseName(data)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "hide"
    })
    Wait(200)
    local HorseName = ""

    CreateThread(function()
        AddTextEntry('FMMC_MPM_NA', Lang:t('stable.set_name'))
        DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 30)
        
        while (UpdateOnscreenKeyboard() == 0) do
            DisableAllControlActions(0)
            Wait(0)
        end
        
        if (GetOnscreenKeyboardResult()) then
            HorseName = GetOnscreenKeyboardResult()
            TriggerServerEvent('rsg-stable:BuyHorse', data, HorseName)
            Wait(1000)
            
            -- Re-open UI after purchase attempt
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = "show",
                shopData = getShopData()
            })
            TriggerServerEvent("rsg-stable:AskForMyHorses")
        else
            -- Check if cancelled
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = "show",
                shopData = getShopData()
            })
        end
    end)
end

local function CloseStable()
    -- Only update if we have a horse
    if not IdMyHorse or not MyHorse_entity then return end

    local dados = {
        SaddlesUsing,
        SaddleclothsUsing,
        StirrupsUsing,
        BagsUsing,
        ManesUsing,
        HorseTailsUsing,
        AcsHornUsing,
        AcsLuggageUsing
    }
    local DadosEncoded = json.encode(dados)
    if DadosEncoded ~= "{}" then
        TriggerServerEvent("rsg-stable:UpdateHorseComponents", dados, IdMyHorse, MyHorse_entity)
    end
end

local function InitiateHorse(atCoords)
    if initializing then return end
    initializing = true

    if horseModel == nil and horseName == nil then
        TriggerServerEvent("rsg-stable:RequestMyHorseInfo") -- Verify this event exists on server? It was VP:HORSE:RequestMyHorseInfo in orig, renamed? 
        -- Wait, I didn't see rsg-stable:RequestMyHorseInfo in server.lua! 
        -- Checking server.lua... "rsg-stable:CheckSelectedHorse" seems to be the one that sets info.
        -- Let's use CheckSelectedHorse instead if requesting info
        TriggerServerEvent("rsg-stable:CheckSelectedHorse")
        
        local timeoutatgametimer = GetGameTimer() + (3 * 1000)
        while horseModel == nil and timeoutatgametimer > GetGameTimer() do
            Wait(0)
        end
        
        if horseModel == nil and horseName == nil then
            initializing = false
            return
        end
    end

    if SpawnplayerHorse ~= 0 and DoesEntityExist(SpawnplayerHorse) then
        DeleteEntity(SpawnplayerHorse)
        SpawnplayerHorse = 0
    end

    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local modelHash = GetHashKey(horseModel)

    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Wait(10) end
    end

    local spawnPosition = atCoords
    if not spawnPosition then
        local x, y, z = table.unpack(pCoords)
        local bool, nodePosition = GetClosestVehicleNode(x, y, z, 1, 3.0, 0.0)
        if bool then spawnPosition = nodePosition else spawnPosition = pCoords end -- Fallback to player coords
    end

    local entity = CreatePed(modelHash, spawnPosition, GetEntityHeading(ped), true, true)
    SetModelAsNoLongerNeeded(modelHash)

    -- Basic horsepower/stats
    Citizen.InvokeNative(0x9587913B9E772D29, entity, 0)
    Citizen.InvokeNative(0x4DB9D03AC4E1FA84, entity, -1, -1, 0)
    Citizen.InvokeNative(0x23f74c2fda6e7c61, -1230993421, entity)
    Citizen.InvokeNative(0xBCC76708E5677E1D9, entity, 0)
    Citizen.InvokeNative(0xB8B6430EAD2D2437, entity, GetHashKey("PLAYER_HORSE"))
    Citizen.InvokeNative(0xFD6943B6DF77E449, entity, false)

    -- Config flags from original script
    SetPedConfigFlag(entity, 324, true)
    SetPedConfigFlag(entity, 211, true)
    SetPedConfigFlag(entity, 208, true)
    SetPedConfigFlag(entity, 209, true)
    SetPedConfigFlag(entity, 400, true)
    SetPedConfigFlag(entity, 297, true)
    SetPedConfigFlag(entity, 136, false)
    SetPedConfigFlag(entity, 312, false)
    SetPedConfigFlag(entity, 113, false)
    SetPedConfigFlag(entity, 301, false)
    SetPedConfigFlag(entity, 277, true)
    SetPedConfigFlag(entity, 319, true)
    SetPedConfigFlag(entity, 6, true)

    SetAnimalTuningBoolParam(entity, 25, false)
    SetAnimalTuningBoolParam(entity, 24, false)
    TaskAnimalUnalerted(entity, -1, false, 0, 0)
    Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
    SpawnplayerHorse = entity
    Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
    SetPedNameDebug(entity, horseName)
    SetPedPromptName(entity, horseName)
    
    if horseComponents ~= nil and horseComponents ~= "0" then
        local validJson, components = pcall(json.decode, horseComponents)
        if validJson and components then
            for _, componentHash in pairs(components) do
                NativeSetPedComponentEnabled(entity, tonumber(componentHash))
            end
        end
    end

    if horseModel == "A_C_Horse_MP_Mangy_Backup" then
        NativeSetPedComponentEnabled(entity, 0x106961A8)
        NativeSetPedComponentEnabled(entity, 0x508B80B9)
    end

    TaskGoToEntity(entity, ped, -1, 7.2, 2.0, 0, 0)
    SetPedConfigFlag(entity, 297, true)
    initializing = false
end

local function WhistleHorse()
    if SpawnplayerHorse ~= 0 and DoesEntityExist(SpawnplayerHorse) then
        local scriptTaskStatus = GetScriptTaskStatus(SpawnplayerHorse, 0x4924437D, 0)
        if scriptTaskStatus ~= 0 and scriptTaskStatus ~= 1 then -- 1 is waiting/running
             local pcoords = GetEntityCoords(PlayerPedId())
             local hcoords = GetEntityCoords(SpawnplayerHorse)
             if #(pcoords - hcoords) >= 100 then
                 DeleteEntity(SpawnplayerHorse)
                 Wait(1000)
                 SpawnplayerHorse = 0
             else
                 TaskGoToEntity(SpawnplayerHorse, PlayerPedId(), -1, 7.2, 2.0, 0, 0)
             end
        else
            -- Already doing something or idle
            TaskGoToEntity(SpawnplayerHorse, PlayerPedId(), -1, 7.2, 2.0, 0, 0)
        end
    else
        TriggerServerEvent('rsg-stable:CheckSelectedHorse')
        Wait(500) -- Increased wait
        InitiateHorse()
    end
end

local function fleeHorse(playerHorse)
    if SpawnplayerHorse ~= 0 and DoesEntityExist(SpawnplayerHorse) then
        TaskAnimalFlee(SpawnplayerHorse, PlayerPedId(), -1)
        Wait(5000)
        DeleteEntity(SpawnplayerHorse)
        Wait(1000)
        SpawnplayerHorse = 0
    end
end

local function interpCamera(cameraName, entity)
    -- Check if we are in "Absolute Mode" (CamPos has keys x,y,z)
    if CamPos and CamPos.x then
        local targetPos = CamPos
        local targetRot = {x=CamPos.rx, y=CamPos.ry, z=CamPos.rz}

        if cameraName == "Horse" then
             targetPos = CamPos
             targetRot = {x=CamPos.rx, y=CamPos.ry, z=CamPos.rz}
        elseif cameraName == "Gear" and CamPosGear and CamPosGear.x then
             targetPos = CamPosGear
             targetRot = {x=CamPosGear.rx, y=CamPosGear.ry, z=CamPosGear.rz}
        end

        tempCam = CreateCam("DEFAULT_SCRIPTED_CAMERA")
        
        -- Use absolute world coordinates, do NOT attach to entity (as CamPos works for static showroom)
        SetCamCoord(tempCam, targetPos.x, targetPos.y, targetPos.z)
        SetCamRot(tempCam, targetRot.x, targetRot.y or 0.0, targetRot.z, 2)
        
        SetCamActive(tempCam, true)
        
        if InterP then
            -- Interpolate to fixedCam (which should be at same pos if created correctly)
            SetCamActiveWithInterp(tempCam, fixedCam, 1200, true, true)
            InterP = false
        end
        return
    end

    for k, v in pairs(cameraUsing) do
        if cameraUsing[k].name == cameraName then
            tempCam = CreateCam("DEFAULT_SCRIPTED_CAMERA")
            -- Only use array indexing if it's the old config style
            local offX = (CamPos[1] or 0) + cameraUsing[k].x
            local offY = (CamPos[2] or 0) + cameraUsing[k].y
            local offZ = (CamPos[3] or 0) + cameraUsing[k].z
            
            AttachCamToEntity(tempCam, entity, offX, offY, offZ)
            SetCamActive(tempCam, true)
            SetCamRot(tempCam, -30.0, 0, HeadingPoint + 50.0)
            if InterP then
                SetCamActiveWithInterp(tempCam, fixedCam, 1200, true, true)
                InterP = false
            end
        end
    end
end

-- NUI Callbacks

RegisterNUICallback("rotate", function(data, cb)
    if (data["key"] == "left") then
        rotation(20)
    else
        rotation(-20)
    end
    cb("ok")
end)

RegisterNUICallback("Saddles", function(data)
    zoom = 4.0
    offset = 0.2
    if tonumber(data.id) == 0 then
        num = 0
        SaddlesUsing = num
        if MyHorse_entity then
            Citizen.InvokeNative(0xD710A5007C2AC539, MyHorse_entity, 0xBAA7E618, 0)
            Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse_entity, 0, 1, 1, 1, 0)
        end
    else
        local num = tonumber(data.id)
        hash = ("0x" .. saddles[num])
        setcloth(hash)
        SaddlesUsing = ("0x" .. saddles[num])
    end
end)

RegisterNUICallback("Saddlecloths", function(data)
    zoom = 4.0
    offset = 0.2
    if tonumber(data.id) == 0 then
        num = 0
        SaddleclothsUsing = num
        if MyHorse_entity then
            Citizen.InvokeNative(0xD710A5007C2AC539, MyHorse_entity, 0x17CEB41A, 0)
            Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse_entity, 0, 1, 1, 1, 0)
        end
    else
        local num = tonumber(data.id)
        hash = ("0x" .. saddlecloths[num])
        setcloth(hash)
        SaddleclothsUsing = ("0x" .. saddlecloths[num])
    end
end)

RegisterNUICallback("Stirrups", function(data)
    zoom = 4.0
    offset = 0.2
    if tonumber(data.id) == 0 then
        num = 0
        StirrupsUsing = num
        if MyHorse_entity then
            Citizen.InvokeNative(0xD710A5007C2AC539, MyHorse_entity, 0xDA6DADCA, 0)
            Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse_entity, 0, 1, 1, 1, 0)
        end
    else
        local num = tonumber(data.id)
        hash = ("0x" .. stirrups[num])
        setcloth(hash)
        StirrupsUsing = ("0x" .. stirrups[num])
    end
end)

RegisterNUICallback("Bags", function(data)
    zoom = 4.0
    offset = 0.2
    if tonumber(data.id) == 0 then
        num = 0
        BagsUsing = num
        if MyHorse_entity then
            Citizen.InvokeNative(0xD710A5007C2AC539, MyHorse_entity, 0x80451C25, 0)
            Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse_entity, 0, 1, 1, 1, 0)
        end
    else
        local num = tonumber(data.id)
        hash = ("0x" .. bags[num])
        setcloth(hash)
        BagsUsing = ("0x" .. bags[num])
    end
end)

RegisterNUICallback("Manes", function(data)
    zoom = 4.0
    offset = 0.2
    if tonumber(data.id) == 0 then
        num = 0
        ManesUsing = num
        if MyHorse_entity then
            Citizen.InvokeNative(0xD710A5007C2AC539, MyHorse_entity, 0xAA0217AB, 0)
            Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse_entity, 0, 1, 1, 1, 0)
        end
    else
        local num = tonumber(data.id)
        hash = ("0x" .. manes[num])
        setcloth(hash)
        ManesUsing = ("0x" .. manes[num])
    end
end)

RegisterNUICallback("HorseTails", function(data)
    zoom = 4.0
    offset = 0.2
    if tonumber(data.id) == 0 then
        num = 0
        HorseTailsUsing = num
        if MyHorse_entity then
            Citizen.InvokeNative(0xD710A5007C2AC539, MyHorse_entity, 0x17CEB41A, 0)
            Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse_entity, 0, 1, 1, 1, 0)
        end
    else
        local num = tonumber(data.id)
        hash = ("0x" .. horsetails[num])
        setcloth(hash)
        HorseTailsUsing = ("0x" .. horsetails[num])
    end
end)

RegisterNUICallback("AcsHorn", function(data)
    zoom = 4.0
    offset = 0.2
    if tonumber(data.id) == 0 then
        num = 0
        AcsHornUsing = num
        if MyHorse_entity then
            Citizen.InvokeNative(0xD710A5007C2AC539, MyHorse_entity, 0x5447332, 0)
            Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse_entity, 0, 1, 1, 1, 0)
        end
    else
        local num = tonumber(data.id)
        hash = ("0x" .. acshorn[num])
        setcloth(hash)
        AcsHornUsing = ("0x" .. acshorn[num])
    end
end)

RegisterNUICallback("AcsLuggage", function(data)
    zoom = 4.0
    offset = 0.2
    if tonumber(data.id) == 0 then
        num = 0
        AcsLuggageUsing = num
        if MyHorse_entity then
            Citizen.InvokeNative(0xD710A5007C2AC539, MyHorse_entity, 0xEFB31921, 0)
            Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse_entity, 0, 1, 1, 1, 0)
        end
    else
        local num = tonumber(data.id)
        hash = ("0x" .. acsluggage[num])
        setcloth(hash)
        AcsLuggageUsing = ("0x" .. acsluggage[num])
    end
end)

RegisterNUICallback("selectHorse", function(data)
    TriggerServerEvent("rsg-stable:SelectHorseWithId", tonumber(data.horseID))
end)

RegisterNUICallback("sellHorse", function(data)
    if showroomHorse_entity and DoesEntityExist(showroomHorse_entity) then
        DeleteEntity(showroomHorse_entity)
    end
    TriggerServerEvent("rsg-stable:SellHorseWithId", tonumber(data.horseID))
    TriggerServerEvent("rsg-stable:AskForMyHorses")
    alreadySentShopData = false
    Wait(300)

    SendNUIMessage({
        action = "show",
        shopData = getShopData()
    })
    TriggerServerEvent("rsg-stable:AskForMyHorses")
end)

RegisterNUICallback("loadHorse", function(data)
    print('[RSG-Stable] loadHorse called with model: ' .. tostring(data.horseModel))
    local horseModel = data.horseModel

    if showroomHorse_model == horseModel then
        print('[RSG-Stable] loadHorse: Same model, returning')
        return
    end

    if MyHorse_entity ~= nil and DoesEntityExist(MyHorse_entity) then
        DeleteEntity(MyHorse_entity)
        MyHorse_entity = nil
    end

    local modelHash = GetHashKey(horseModel)

    if IsModelValid(modelHash) then
        if not HasModelLoaded(modelHash) then
            RequestModel(modelHash)
            local timeout = 0
            while not HasModelLoaded(modelHash) and timeout < 100 do
                Wait(10)
                timeout = timeout + 1
            end
        end
    else
        print('[RSG-Stable] loadHorse: Invalid model hash')
    end

    if showroomHorse_entity ~= nil and DoesEntityExist(showroomHorse_entity) then
        DeleteEntity(showroomHorse_entity)
        showroomHorse_entity = nil
    end

    -- Safety check for SpawnPoint
    if not SpawnPoint or not SpawnPoint.x then
        print("ERROR: SpawnPoint is nil in loadHorse")
        return 
    end

    -- Remove Z offset and snap to ground
    showroomHorse_entity = CreatePed(modelHash, SpawnPoint.x, SpawnPoint.y, SpawnPoint.z, SpawnPoint.h, false, 0)
    
    if DoesEntityExist(showroomHorse_entity) then
        print('[RSG-Stable] Showroom horse created at: ' .. SpawnPoint.x .. ', ' .. SpawnPoint.y .. ', ' .. SpawnPoint.z)
        
        -- Configuration for showroom horse
        SetEntityVisible(showroomHorse_entity, true)
        SetEntityAlpha(showroomHorse_entity, 255, false)
        Citizen.InvokeNative(0x283978A15512B2FE, showroomHorse_entity, true) -- SetRandomOutfitVariation
        Citizen.InvokeNative(0x58A850EAEE20FAA3, showroomHorse_entity) -- Unknown native, keeping as legacy
        
        FreezeEntityPosition(showroomHorse_entity, true)
        SetEntityInvincible(showroomHorse_entity, true)
        SetBlockingOfNonTemporaryEvents(showroomHorse_entity, true)
        PlaceEntityOnGroundProperly(showroomHorse_entity)
        
        interpCamera("Horse", showroomHorse_entity)
    else
        print('[RSG-Stable] Showroom horse creation failed!')
    end
end)

RegisterNUICallback("loadMyHorse", function(data)
    local horseModel = data.horseModel
    IdMyHorse = data.IdHorse

    if showroomHorse_model == horseModel then
        return
    end

    if showroomHorse_entity ~= nil then
        DeleteEntity(showroomHorse_entity)
        showroomHorse_entity = nil
    end

    if MyHorse_entity ~= nil then
        DeleteEntity(MyHorse_entity)
        MyHorse_entity = nil
    end

    showroomHorse_model = horseModel

    local modelHash = GetHashKey(showroomHorse_model)

    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end
    end

    MyHorse_entity = CreatePed(modelHash, SpawnPoint.x, SpawnPoint.y, SpawnPoint.z, SpawnPoint.h, false, 0)
    
    SetEntityVisible(MyHorse_entity, true)
    SetEntityAlpha(MyHorse_entity, 255, false)
    Citizen.InvokeNative(0x283978A15512B2FE, MyHorse_entity, true)
    Citizen.InvokeNative(0x58A850EAEE20FAA3, MyHorse_entity)
    FreezeEntityPosition(MyHorse_entity, true)
    SetEntityInvincible(MyHorse_entity, true)
    SetBlockingOfNonTemporaryEvents(MyHorse_entity, true)
    PlaceEntityOnGroundProperly(MyHorse_entity)
    
    SetVehicleHasBeenOwnedByPlayer(MyHorse_entity, true) -- Keeping for legacy, though it's a ped
    
    local componentsHorse = json.decode(data.HorseComp)
    if componentsHorse ~= '[]' then
        for _, Key in pairs(componentsHorse) do
            local model2 = GetHashKey(tonumber(Key))
            if not HasModelLoaded(model2) then
                Citizen.InvokeNative(0xFA28FE3A6246FC30, model2)
            end
            Citizen.InvokeNative(0xD3A7B003ED343FD9, MyHorse_entity, tonumber(Key), true, true, true)
        end
    end

    interpCamera("Horse", MyHorse_entity)
end)

RegisterNUICallback("BuyHorse", function(data)
    SetHorseName(data)
end)

RegisterNUICallback("CloseStable", function()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "hide"
    })
    SetEntityVisible(PlayerPedId(), true)

    showroomHorse_model = nil

    if showroomHorse_entity ~= nil then
        DeleteEntity(showroomHorse_entity)
    end

    if MyHorse_entity ~= nil then
        DeleteEntity(MyHorse_entity)
    end

    DestroyAllCams(true)
    showroomHorse_entity = nil
    CloseStable()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, prompt in pairs(prompts) do
            PromptDelete(prompt)
            RemoveBlip(blip)
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "hide"
    })
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteEntity(SpawnplayerHorse)
        SpawnplayerHorse = 0
    end
end)

RegisterNetEvent("rsg-stable:SetHorseInfo", SetHorseInfo)

RegisterNetEvent('rsg-stable:client:UpdateHorseComponents', function(horseEntity, components)
    for _, value in pairs(components) do
        NativeSetPedComponentEnabled(horseEntity, value)
    end
end)

RegisterNetEvent("rsg-stable:ReceiveHorsesData", function(dataHorses)
    SendNUIMessage({
        myHorsesData = dataHorses
    })
end)

local promptGroup = GetRandomIntInRange(0, 0xffffff)
local varStringCasa = CreateVarString(10, "LITERAL_STRING", Lang:t('stable.stable'))

local spawnedPeds = {}

local function SpawnStableNPCs()
    print("[RSG-Stable] Starting NPC Spawn...")
    for k, v in pairs(Config.Stables) do
        if v.StableNPC then
            print("[RSG-Stable] Attempting to spawn NPC for: " .. v.Name)
            local model = GetHashKey(v.StableNPC.model)
            
            if not IsModelInCdimage(model) then
                print("[RSG-Stable] ERROR: Model not found in CD image: " .. v.StableNPC.model)
                goto continue
            end

            RequestModel(model)
            local timeout = 0
            while not HasModelLoaded(model) and timeout < 100 do
                Wait(10)
                timeout = timeout + 1
            end
            
            if not HasModelLoaded(model) then
                print("[RSG-Stable] ERROR: Failed to load model: " .. v.StableNPC.model)
                goto continue 
            end

            local npc = CreatePed(model, v.StableNPC.x, v.StableNPC.y, v.StableNPC.z, v.StableNPC.h, false, false)
            
            if DoesEntityExist(npc) then
                print("[RSG-Stable] NPC Created ID: " .. npc)
                SetEntityVisible(npc, true)
                SetEntityAlpha(npc, 255, false)
                Citizen.InvokeNative(0x283978A15512B2FE, npc, true)
                FreezeEntityPosition(npc, true)
                SetEntityInvincible(npc, true)
                SetBlockingOfNonTemporaryEvents(npc, true)
                spawnedPeds[#spawnedPeds + 1] = npc
                
                exports['rsg-target']:AddTargetEntity(npc, {
                    options = {
                        {
                            type = "client",
                            event = "rsg-stable:client:OpenStableTarget",
                            icon = "fas fa-horse-head",
                            label = Lang:t('stable.stable'),
                            stableId = k, 
                            stableData = v 
                        },
                    },
                    distance = 3.0,
                })
                print("[RSG-Stable] Target added for NPC at " .. v.Name)
                
                if v.showblip ~= false then 
                    local blip = N_0x554d9d53f696d002(1664425300, v.Pos.x, v.Pos.y, v.Pos.z)
                    SetBlipSprite(blip, 4221798391, 1)
                    SetBlipScale(blip, 0.2)
                    Citizen.InvokeNative(0x9CB1A1623062F402, blip, v.Name)
                end
            else
                print("[RSG-Stable] ERROR: CreatePed failed for " .. v.Name)
            end
            ::continue::
        end
    end
    print("[RSG-Stable] NPC Spawn Loop Finished")
end

-- Event to handle opening from target
RegisterNetEvent('rsg-stable:client:OpenStableTarget', function(data)
    local v = data.stableData
    
    -- New Data Model Support (checks for SpawnHorse key)
    if v.SpawnHorse then
        HeadingPoint = v.SpawnHorse.h
        StablePoint = {v.SpawnHorse.x, v.SpawnHorse.y, v.SpawnHorse.z}
        
        -- Store full cam data
        CamPos = v.CamHorse -- Now contains x, y, z, rx, ry, rz
        CamPosGear = v.CamHorseGear -- Store Gear Cam
        
        SpawnPoint = {x = v.SpawnHorse.x, y = v.SpawnHorse.y, z = v.SpawnHorse.z, h = v.SpawnHorse.h}
        
    -- Check for Legacy Config format
    elseif v.SpawnPoint and v.SpawnPoint.Pos then
        HeadingPoint = v.SpawnPoint.Heading
        StablePoint = {v.SpawnPoint.Pos.x, v.SpawnPoint.Pos.y, v.SpawnPoint.Pos.z}
        CamPos = v.SpawnPoint.CamPos
        SpawnPoint = {x = v.SpawnPoint.Pos.x, y = v.SpawnPoint.Pos.y, z = v.SpawnPoint.Pos.z, h = v.SpawnPoint.Heading}
    else
        print("[RSG-Stable] ERROR: Stable configuration missing Spawn data for " .. v.Name)
        return
    end
    
    OpenStable()
end)

-- Initialize
CreateThread(function()
    SpawnStableNPCs()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, ped in pairs(spawnedPeds) do
            DeleteEntity(ped)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(100)
        if MyHorse_entity ~= nil then
            SendNUIMessage({
                EnableCustom = "true"
            })
        else
            SendNUIMessage({
                EnableCustom = "false"
            })
        end
    end
end)

CreateThread(function()
    while true do
        local getHorseMood = Citizen.InvokeNative(0x42688E94E96FD9B4, SpawnplayerHorse, 3, 0, Citizen.ResultAsFloat())
        if getHorseMood >= 0.60 then
            Citizen.InvokeNative(0x06D26A96CA1BCA75, SpawnplayerHorse, 3, PlayerPedId())
            Citizen.InvokeNative(0xA1EB5D029E0191D3, SpawnplayerHorse, 3, 0.99)
        end
        Wait(30000)
    end
end)

CreateThread(function()
    while true do
        Wait(1)
        if Citizen.InvokeNative(0x91AEF906BCA88877, 0, 0x24978A28) then -- Control = H
            WhistleHorse()
            Wait(10000) -- Flood Protection
        end

        if Citizen.InvokeNative(0x91AEF906BCA88877, 0, 0xB2F377E8) then -- Control = Horse Flee
            if SpawnplayerHorse ~= 0 then
                fleeHorse(SpawnplayerHorse)
            end
        end
    end
end)

CreateThread(function()
    while adding do
        Wait(0)
        for i, v in ipairs(HorseComp) do
            if v.category == "Saddlecloths" then
                saddlecloths[#saddlecloths + 1] = v.Hash
            elseif v.category == "AcsHorn" then
                acshorn[#acshorn + 1] = v.Hash
            elseif v.category == "Bags" then
                bags[#bags + 1] = v.Hash
            elseif v.category == "HorseTails" then
                horsetails[#horsetails + 1] = v.Hash
            elseif v.category == "Manes" then
                manes[#manes + 1] = v.Hash
            elseif v.category == "Saddles" then
                saddles[#saddles + 1] = v.Hash
            elseif v.category == "Stirrups" then
                stirrups[#stirrups + 1] = v.Hash
            elseif v.category == "AcsLuggage" then
                acsluggage[#acsluggage + 1] = v.Hash
            end
        end
        adding = false
    end
end)

exports('CheckActiveHorse', function()
    return SpawnplayerHorse
end)

RegisterCommand('fixstable', function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hide" })
    local ped = PlayerPedId()
    SetEntityVisible(ped, true)
    FreezeEntityPosition(ped, false)
    DestroyAllCams(true)
    if showroomHorse_entity then DeleteEntity(showroomHorse_entity) end
    showroomHorse_entity = nil
    print("[RSG-Stable] Emergency fix applied.")
end)
