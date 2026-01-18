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
local pendingTransferHorse = nil

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
local ShowroomPoint = {} -- Added ShowroomPoint variable
local currentSpawnPoint = nil
local HeadingPoint
local CamPos = {}
local CamPosGear = {}
local SpawnplayerHorse = 0
local horseModel
local horseName
local horseComponents = {}
local horseStats = {} -- New stats variable
local initializing = false
local horseComponents = {}
local horseStats = {} -- New stats variable
local initializing = false
local alreadySentShopData = false
local currentStableLocation = nil -- Track current stable location


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

local function SetHorseInfo(horse_model, horse_name, horse_components, horse_stats, horse_id)
    horseModel = horse_model
    horseName = horse_name
    horseComponents = horse_components
    horseStats = horse_stats or {}
    IdMyHorse = horse_id
end

local function NativeSetPedComponentEnabled(ped, component)
    Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, component, true, true, true)
end

-- Initialize Components from shared HorseComp
CreateThread(function()
    print("[RSG-Stable] Initializing Components...")
    if HorseComp then
        for _, comp in pairs(HorseComp) do
            local hash = comp.Hash
            -- Normalize hash: if string with 0x, remove 0x. If generic string, keep it.
            if type(hash) == "string" and hash:find("0x") then
                hash = hash:gsub("0x", "")
            end
            
            if comp.category == "Saddlecloths" then
                table.insert(saddlecloths, hash)
            elseif comp.category == "AcsHorn" then
                table.insert(acshorn, hash)
            elseif comp.category == "Bags" then
                table.insert(bags, hash)
            elseif comp.category == "HorseTails" then
                table.insert(horsetails, hash)
            elseif comp.category == "Manes" then
                table.insert(manes, hash)
            elseif comp.category == "Saddles" then
                table.insert(saddles, hash)
            elseif comp.category == "Stirrups" then
                table.insert(stirrups, hash)
            elseif comp.category == "AcsLuggage" then
                table.insert(acsluggage, hash)
            end
        end
        print("[RSG-Stable] Components Loaded: " .. #saddlecloths .. " Saddlecloths, " .. #saddles .. " Saddles.")
    else
        print("[RSG-Stable] ERROR: HorseComp is nil!")
    end
end)

-- Top of file or near Init
DecorRegister("horseId", 3)

-- ...



RegisterNetEvent('rsg-stable:client:BreedHorse', function(data)
    local entity = data.entity
    local myHorse = SpawnplayerHorse
    
    if not entity or not DoesEntityExist(entity) then return end
    if not myHorse or not DoesEntityExist(myHorse) then return end
    
    if entity == myHorse then
        TriggerEvent('rsg-core:notify', "You cannot breed with yourself!", "error")
        return
    end

    local idA = DecorGetInt(entity, "horseId")
    local idB = DecorGetInt(myHorse, "horseId")
    
    if not idA or idA == 0 or not idB or idB == 0 then
         TriggerEvent('rsg-core:notify', "Invalid horse data.", "error")
         return
    end
    
    -- Simple Input for Name
    local foalName = "Foal" -- Default
    -- We can try to get input, but for stability, let's use a server-generated name or simpler flow
    -- Trigger Server
    TriggerServerEvent('rsg-stable:BreedHorse', idA, idB, foalName)
end)

local function createCamera(entity)
    if not CamPos then 
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
            location = currentStableLocation,
            shopData = getShopData()
        })
    else
        SendNUIMessage({
            action = "show",
            location = currentStableLocation
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
    
    -- Force InitiateHorse to re-fetch updated data
    -- By setting horseModel to nil, InitiateHorse (lines 266-282) will trigger CheckSelectedHorse
    horseModel = nil 
    horseName = nil
    MyHorse_entity = nil -- Clear old entity ref so InitiateHorse creates new one
end

local function HasSaddlebag()
    if not horseComponents or horseComponents == "0" then return false end
    
    local components = json.decode(horseComponents)
    if type(components) ~= "table" then return false end
    
    local bagHashes = {}
    -- Build Bag Hash Set from global HorseComp
    if HorseComp then
        for _, comp in pairs(HorseComp) do
            if comp.category == "Bags" then
                local hash = comp.Hash
                if type(hash) == "string" then
                    -- Store both string and number variants
                    hash = hash:gsub("0x", "")
                    bagHashes[tonumber("0x"..hash)] = true
                    bagHashes[hash] = true
                else
                    bagHashes[hash] = true
                end
            end
        end
    end

    for _, hash in pairs(components) do
        local hVal = tonumber(hash)
        if bagHashes[hVal] or bagHashes[tostring(hash)] then
            return true
        end
    end
    return false
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
    local Heading = 0.0

    if not spawnPosition then
        if currentSpawnPoint then
            spawnPosition = vector3(currentSpawnPoint.x, currentSpawnPoint.y, currentSpawnPoint.z)
            Heading = currentSpawnPoint.h
        else
            local x, y, z = table.unpack(pCoords)
            local bool, nodePosition = GetClosestVehicleNode(x, y, z, 1, 3.0, 0.0)
            if bool then spawnPosition = nodePosition else spawnPosition = pCoords end -- Fallback to player coords
            Heading = GetEntityHeading(ped)
        end
    end
    
    TriggerEvent('RSGCore:Notify', 'Get your horse ready!', 'primary')

    local entity
    local isVehicle = IsModelAVehicle(modelHash)

    if isVehicle then
        entity = CreateVehicle(modelHash, spawnPosition, GetEntityHeading(ped), true, false)
        SetModelAsNoLongerNeeded(modelHash)
        SpawnplayerHorse = entity
    else
        entity = CreatePed(modelHash, spawnPosition, GetEntityHeading(ped), true, true)
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
        SetPedConfigFlag(entity, 6, true)

        SetAnimalTuningBoolParam(entity, 25, false)
        SetAnimalTuningBoolParam(entity, 24, false)
        TaskAnimalUnalerted(entity, -1, false, 0, 0)
        Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
        SpawnplayerHorse = entity
        Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
        SetPedNameDebug(entity, horseName)
        SetPedPromptName(entity, horseName)
        DecorSetInt(entity, "horseId", IdMyHorse)

        
        -- Components
        if horseComponents ~= nil and horseComponents ~= "0" then
            local componentsh = json.decode(horseComponents)
            if componentsh ~= "[]" then
                for _, Key in pairs(componentsh) do
                    Citizen.InvokeNative(0xD3A7B003ED343FD9, entity, tonumber(Key), true, true, true)
                end
            end
        end
        
        -- Foal Size Scaling based on Age
        if horseStats and horseStats.age ~= nil then
            local age = horseStats.age
            local fullyGrownAge = Config.Breeding and Config.Breeding.FullyGrownAge or 6
            local foalScale = Config.Breeding and Config.Breeding.FoalScale or 0.5
            
            if age < fullyGrownAge then
                local scaleProgress = age / fullyGrownAge
                local currentScale = foalScale + (scaleProgress * (1.0 - foalScale))
                SetPedScale(entity, currentScale)
            end
        end

        if horseModel == "A_C_Horse_MP_Mangy_Backup" then
            NativeSetPedComponentEnabled(entity, 0x106961A8)
            NativeSetPedComponentEnabled(entity, 0x508B80B9)
        end
        
    end -- End of isVehicle check

    -- Natural Mount Logic
    -- Wait a moment for entity to settle
    Wait(500)
    
    if SetPlayerOwnsMount then
        SetPlayerOwnsMount(ped, entity)
    end
    
    TriggerEvent('rsg-core:notify', 'Horse ready.', 'success')
    
    -- Command ped to mount naturally
    TaskMountAnimal(ped, entity, -1, -1, 2.0, 1, 0, 0)
    SetPedKeepTask(ped, true)
    
    if not isVehicle then
        SetPedConfigFlag(entity, 297, true)
        -- Add Interations (Train Horse) - Only for horses
        exports['rsg-target']:AddTargetEntity(entity, {
            options = {
                {
                    type = "client",
                    event = "rsg-stable:client:TrainHorse",
                    icon = "fas fa-dumbbell",
                    label = "Train Horse",
                    job = {["valhorsetrainer"] = 0, ["rhohorsetrainer"] = 0, ["blkhorsetrainer"] = 0, ["strhorsetrainer"] = 0, ["stdenhorsetrainer"] = 0},
                },
                {
                    type = "client",
                    event = "rsg-stable:client:OpenSaddlebag",
                    icon = "fas fa-box-open",
                    label = "Open Saddlebag",
                    canInteract = function(entity)
                        -- Allow interaction if it has a horseId decorator (owned horse)
                        return DecorGetInt(entity, "horseId") ~= 0 and HasSaddlebag()
                    end,
                },
            },
            distance = 2.0,
        })
    end
    
    initializing = false
end

RegisterNetEvent('rsg-stable:client:TrainHorse', function()
    -- Only allow training your own horse or a horse you are targeting (which we are)
    -- We need the entity network ID
    if SpawnplayerHorse and DoesEntityExist(SpawnplayerHorse) then
        local netId = NetworkGetNetworkIdFromEntity(SpawnplayerHorse)
        TriggerServerEvent('rsg-stable:TrainHorse', netId)
    end
end)

RegisterNetEvent('rsg-stable:client:OpenSaddlebag', function(data)
    print("DEBUG: OpenSaddlebag triggered")
    -- rsg-target passes data which includes .entity
    local entity = data and data.entity
    if not entity then 
        print("DEBUG: No entity found in data")
        return 
    end

    local horseId = DecorGetInt(entity, "horseId")
    print("DEBUG: Entity found, horseId decorator:", horseId)

    if not horseId or horseId == 0 then
        -- Fallback to global if decorating failed or old horse
        horseId = IdMyHorse
        print("DEBUG: Fallback to global IdMyHorse:", IdMyHorse)
    end

    if not horseId then 
        TriggerEvent('rsg-core:notify', 'Cannot identify this horse.', 'error')
        print("DEBUG: Failed to identify horseId")
        return 
    end
    
    local stashId = "stable_" .. horseId
    print("DEBUG: Opening stash:", stashId)
    
    -- Try triggering the inventory open event
    -- Try triggering the custom stable stash open event
    -- Corrected trigger for rsg-inventory
    TriggerServerEvent("rsg-inventory:server:OpenInventory", stashId, {
        maxweight = 40000,
        slots = 30,
        label = "Saddlebag"
    })
    TriggerEvent("rsg-inventory:client:SetCurrentStash", stashId)
end)

-- Ride Restriction for Young Horses
CreateThread(function()
    while true do
        if SpawnplayerHorse and DoesEntityExist(SpawnplayerHorse) then
            Wait(1000) -- Check every second instead of 500ms
            local rideableAge = Config.Breeding and Config.Breeding.RideableAge or 4
            local horseAge = (horseStats and horseStats.age) or 100 -- Default to rideable if no stats
            
            if horseAge < rideableAge then
                -- Check if player is trying to mount
                local ped = PlayerPedId()
                if IsPedOnMount(ped) and GetMount(ped) == SpawnplayerHorse then
                    -- Force dismount
                    TaskDismountAnimal(ped, 0, 0, 0, 0, 0)
                    TriggerEvent('rsg-core:notify', 'This horse is too young to ride! (Age: ' .. horseAge .. '/' .. rideableAge .. ')', 'error')
                    Wait(2000) -- Cooldown to prevent spam
                end
            end
        else
            Wait(2000) -- Sleep if no horse
        end
    end
end)

-- Handling Loop for IQ Effect
CreateThread(function()
    while true do
        if SpawnplayerHorse and DoesEntityExist(SpawnplayerHorse) then
             Wait(5000)
             if IsPedInVehicle(PlayerPedId(), SpawnplayerHorse, false) then
                if horseStats and horseStats.iq and horseStats.iq < 20 then
                    -- Low IQ Effect: Random agitation or refusal
                    if math.random(1, 100) < 10 then
                       TaskAnimalAgitated(SpawnplayerHorse, -1)
                    end
                end
             end
        else
             Wait(5000) -- Sleep
        end
    end
end)

local function WhistleHorse()
    -- Whistle Disabled
    TriggerEvent('rsg-core:notify', 'Whistling is disabled. You must retrieve your horse from the stable.', 'error')
end

local function fleeHorse(playerHorse)
    if SpawnplayerHorse ~= 0 and DoesEntityExist(SpawnplayerHorse) then
        TaskAnimalFlee(SpawnplayerHorse, PlayerPedId(), -1)
        
        -- Check if near any stable to store
        local pCoords = GetEntityCoords(SpawnplayerHorse)
        local stored = false
        for location, data in pairs(Config.Stables) do
            local dist = #(pCoords - data.Pos)
            if dist < 50.0 then
                local horseId = DecorGetInt(SpawnplayerHorse, "horseId")
                if horseId and horseId ~= 0 then
                    TriggerServerEvent('rsg-stable:server:StoreHorse', horseId, location)
                    TriggerEvent('RSGCore:Notify', 'Horse stored in ' .. data.Name, 'success')
                    stored = true
                end
                break
            end
        end
        
        if not stored then
            TriggerEvent('RSGCore:Notify', 'Horse has returned to the stable', 'primary')
        end
        
        Wait(5000)
        DeleteEntity(SpawnplayerHorse)
        Wait(1000)
        SpawnplayerHorse = 0
    end
end

-- Whistle Command & Key Mapping (DISABLED/REMOVED)
-- RegisterCommand('whistleHorse', function()
--     WhistleHorse()
-- end, false)
-- RegisterKeyMapping('whistleHorse', 'Whistle for Horse', 'keyboard', 'H')

-- Flee Command & Key Mapping (F4 default, user can change)
-- Flee Input Loop (Fallback for missing RegisterKeyMapping)
CreateThread(function()
    while true do
        if SpawnplayerHorse ~= 0 and DoesEntityExist(SpawnplayerHorse) then
            Wait(5)
            -- Check for Flee Control (INPUT_CONTEXT_B / 0xB2F377E8)
            if Citizen.InvokeNative(0x91AEF906BCA88877, 0, 0xB2F377E8) then
                 fleeHorse(SpawnplayerHorse)
                 Wait(1000) -- Debounce
            end
        else
            Wait(2000) -- Sleep deeply if no horse is spawned
        end
    end
end)

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
        if saddles[num] then
            hash = ("0x" .. saddles[num])
            setcloth(hash)
            SaddlesUsing = ("0x" .. saddles[num])
        end
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
        if saddlecloths[num] then
            hash = ("0x" .. saddlecloths[num])
            setcloth(hash)
            SaddleclothsUsing = ("0x" .. saddlecloths[num])
        end
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
        if stirrups[num] then
            hash = ("0x" .. stirrups[num])
            setcloth(hash)
            StirrupsUsing = ("0x" .. stirrups[num])
        end
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
        if bags[num] then
            hash = ("0x" .. bags[num])
            setcloth(hash)
            BagsUsing = ("0x" .. bags[num])
        end
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
        if manes[num] then
            hash = ("0x" .. manes[num])
            setcloth(hash)
            ManesUsing = ("0x" .. manes[num])
        end
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
        if horsetails[num] then
            hash = ("0x" .. horsetails[num])
            setcloth(hash)
            HorseTailsUsing = ("0x" .. horsetails[num])
        end
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
        if acshorn[num] then
            hash = ("0x" .. acshorn[num])
            setcloth(hash)
            AcsHornUsing = ("0x" .. acshorn[num])
        end
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
        if acsluggage[num] then
            hash = ("0x" .. acsluggage[num])
            setcloth(hash)
            AcsLuggageUsing = ("0x" .. acsluggage[num])
        end
    end
end)

RegisterNUICallback("selectHorse", function(data)
    local horseID = tonumber(data.horseID)
    
    -- Strict Stable Check
    if currentStableLocation then
        local foundStable = nil
        for _, h in pairs(myHorses) do
            if h.id == horseID then
                foundStable = h.stable
                break
            end
        end
        
        -- If horse is stored elsewhere, prevent taking out
        if foundStable and foundStable ~= currentStableLocation and foundStable ~= "null" then
             -- Get Human Readable Name
             local stableName = "Another Stable"
             if Config.Stables[foundStable] then stableName = Config.Stables[foundStable].Name end
             TriggerEvent('rsg-core:notify', 'This horse is at ' .. stableName, 'error')
             return
        end
    end

    TriggerServerEvent("rsg-stable:SelectHorseWithId", horseID)
    TriggerServerEvent("rsg-stable:AskForMyHorses") 
    -- Refresh needed? ask server
    -- Actually SelectHorseWithId triggers client update if implementation is correct
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
    local horseModel = data.horseModel
    
    if not horseModel or horseModel == "" then
        return
    end
    
    if showroomHorse_model == horseModel then
        return
    end
    
    showroomHorse_model = horseModel -- Update tracking variable

    if MyHorse_entity ~= nil and DoesEntityExist(MyHorse_entity) then
        DeleteEntity(MyHorse_entity)
        MyHorse_entity = nil
    end
    
    inCustomization = false -- Shop horses cannot be customized until bought

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
        -- invalid model hash
    end

    if showroomHorse_entity ~= nil and DoesEntityExist(showroomHorse_entity) then
        DeleteEntity(showroomHorse_entity)
        showroomHorse_entity = nil
    end

    -- Safety check for ShowroomPoint
    if not ShowroomPoint or not ShowroomPoint.x then
        return 
    end

    -- Remove Z offset and snap to ground
    showroomHorse_entity = CreatePed(modelHash, ShowroomPoint.x, ShowroomPoint.y, ShowroomPoint.z, ShowroomPoint.h, false, 0)
    
    if DoesEntityExist(showroomHorse_entity) then
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
        -- creation failed
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
    
    -- Enable Customization for owned horses
    inCustomization = true

    showroomHorse_model = horseModel

    local modelHash = GetHashKey(showroomHorse_model)

    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end
    end

    if IsModelAVehicle(modelHash) then
        if not SpawnCartPoint or not SpawnCartPoint.x then return end
        
        MyHorse_entity = CreateVehicle(modelHash, SpawnCartPoint.x, SpawnCartPoint.y, SpawnCartPoint.z, SpawnCartPoint.h, false, false)
        
        SetEntityVisible(MyHorse_entity, true)
        SetEntityAlpha(MyHorse_entity, 255, false)
        FreezeEntityPosition(MyHorse_entity, true)
        SetEntityInvincible(MyHorse_entity, true)
        SetBlockingOfNonTemporaryEvents(MyHorse_entity, true)
        SetModelAsNoLongerNeeded(modelHash)
        
        interpCamera("Cart", MyHorse_entity)
    else
        if not ShowroomPoint or not ShowroomPoint.x then return end
    
        MyHorse_entity = CreatePed(modelHash, ShowroomPoint.x, ShowroomPoint.y, ShowroomPoint.z, ShowroomPoint.h, false, 0)
        
        SetEntityVisible(MyHorse_entity, true)
        SetEntityAlpha(MyHorse_entity, 255, false)
        Citizen.InvokeNative(0x283978A15512B2FE, MyHorse_entity, true)
        Citizen.InvokeNative(0x58A850EAEE20FAA3, MyHorse_entity)
        FreezeEntityPosition(MyHorse_entity, true)
        SetEntityInvincible(MyHorse_entity, true)
        SetBlockingOfNonTemporaryEvents(MyHorse_entity, true)
        PlaceEntityOnGroundProperly(MyHorse_entity)
        SetModelAsNoLongerNeeded(modelHash)
        
        SetVehicleHasBeenOwnedByPlayer(MyHorse_entity, true)
        
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
    end
end)

RegisterNUICallback("BuyHorse", function(data)
    SetHorseName(data)
end)

RegisterNUICallback("SelectHorse", function(data)
    -- Deprecated: Use 'selectHorse' (lowercase) which handles server event correctly
end)

RegisterNUICallback("transferHorse", function(data)
    TriggerServerEvent("rsg-stable:TransferHorse", data)
end)



RegisterNUICallback("startTransfer", function(data)
    -- Close the stable UI first
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hide" })
    SetEntityVisible(PlayerPedId(), true)
    
    if showroomHorse_entity then DeleteEntity(showroomHorse_entity) showroomHorse_entity = nil end
    if MyHorse_entity then DeleteEntity(MyHorse_entity) MyHorse_entity = nil end
    DestroyAllCams(true)
    CloseStable()
    
    -- Open Input Dialog
    local input = exports.ox_lib:inputDialog("Transfer Horse: " .. (data.horseName or "Unknown"), {
        { type = 'number', label = "Player ID (Server ID)", required = true },
        { type = 'number', label = "Price (0 for free)", default = 0 }
    })
    
    if not input then return end
    
    local targetId = tonumber(input[1])
    local price = tonumber(input[2]) or 0
    
    if not targetId then return end
    
    TriggerServerEvent('rsg-stable:server:createTransfer', {
        horseID = data.horseID,
        targetServerId = targetId,
        price = price
    })
end)

RegisterNUICallback("getPendingTransfers", function(data, cb)
    TriggerServerEvent('rsg-stable:server:getPendingTransfers')
    if cb then cb('ok') end
end)

RegisterNUICallback("respondTransfer", function(data, cb)
    TriggerServerEvent('rsg-stable:server:respondTransfer', data.transferId, data.accepted)
    if cb then cb('ok') end
end)

RegisterNUICallback("notify", function(data, cb)
    TriggerEvent('ox_lib:notify', {type = data.type, description = data.msg, duration = 5000})
    if cb then cb('ok') end
end)

RegisterNetEvent('rsg-stable:client:receivePendingTransfers', function(transfers)
    SendNUIMessage({
        action = "updatePendingTransfers",
        transfers = transfers
    })
end)

RegisterCommand("transferhorse", function(source, args)
    if not pendingTransferHorse then
        TriggerEvent('rsg-core:notify', 'No horse selected for transfer. Select "Transfer" in the Stable first.', 'error')
        return
    end

    local targetId = tonumber(args[1])
    local price = tonumber(args[2]) or 0

    if not targetId then
        TriggerEvent('rsg-core:notify', 'Usage: /transferhorse [PlayerID] [Price (Optional)]', 'error')
        return
    end

    TriggerServerEvent('rsg-stable:server:createTransfer', {
        horseID = pendingTransferHorse.horseID,
        targetServerId = targetId,
        price = price
    })
    
    -- Clear pending transfer after sending offer attempt
    pendingTransferHorse = nil
end)

RegisterNUICallback("CloseStable", function(data)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "hide"
    })
    SetEntityVisible(PlayerPedId(), true)

    -- SAVE CUSTOMIZATION
    -- Only save if we are indeed in customization mode (EnableCustom was true)
    -- We can check if any *Using variable is set? Or just always save for safety if MyHorse_entity exists
    if MyHorse_entity and DoesEntityExist(MyHorse_entity) and IdMyHorse then
        -- Gather components
        -- Gather components using index-based array to ensure valid JSON array
        local components = {}
        if SaddlesUsing then components[#components+1] = SaddlesUsing end
        if SaddleclothsUsing then components[#components+1] = SaddleclothsUsing end
        if StirrupsUsing then components[#components+1] = StirrupsUsing end
        if BagsUsing then components[#components+1] = BagsUsing end
        if ManesUsing then components[#components+1] = ManesUsing end
        if HorseTailsUsing then components[#components+1] = HorseTailsUsing end
        if AcsHornUsing then components[#components+1] = AcsHornUsing end
        if AcsLuggageUsing then components[#components+1] = AcsLuggageUsing end
        
        -- Save to Server
        TriggerServerEvent('rsg-stable:UpdateHorseComponents', components, IdMyHorse, MyHorse_entity)
        
        -- Charge Cost (e.g. $10 service fee for accessing stable customization)
        -- Only charge if data.spawn is FALSE (meaning we clicked Confirm inside customization)
        -- or we can track if 'inCustomization' was true.
        if inCustomization and data.customized and data.cost and data.cost > 0 then
             TriggerServerEvent('rsg-stable:server:ChargeCustomization', data.cost) 
        end
    end


    showroomHorse_model = nil

    if showroomHorse_entity ~= nil then
        DeleteEntity(showroomHorse_entity)
    end

    if MyHorse_entity ~= nil then
        DeleteEntity(MyHorse_entity)
    end

    DestroyAllCams(true)
    showroomHorse_entity = nil
    inCustomization = false -- Reset customization state
    CloseStable()
    
    -- Spawn logic for "Take Out" - Only if requested
    if data and data.spawn then
        Wait(200) 
        InitiateHorse()
    end
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
    for k, v in pairs(Config.Stables) do
        if v.StableNPC then
            local model = GetHashKey(v.StableNPC.model)
            
            if not IsModelInCdimage(model) then
                goto continue
            end

            RequestModel(model)
            local timeout = 0
            while not HasModelLoaded(model) and timeout < 100 do
                Wait(10)
                timeout = timeout + 1
            end
            
            if not HasModelLoaded(model) then
                goto continue 
            end

            local npc = CreatePed(model, v.StableNPC.x, v.StableNPC.y, v.StableNPC.z, v.StableNPC.h, false, false)
            
            if DoesEntityExist(npc) then
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
                
                if v.showblip ~= false then 
                    local blip = N_0x554d9d53f696d002(1664425300, v.Pos.x, v.Pos.y, v.Pos.z)
                    SetBlipSprite(blip, 4221798391, 1)
                    SetBlipScale(blip, 0.2)
                    Citizen.InvokeNative(0x9CB1A1623062F402, blip, v.Name)
                end
            else
                -- creation failed
            end
            ::continue::
        end
    end
end

-- Event to handle opening from target
RegisterNetEvent('rsg-stable:client:OpenStableTarget', function(data)
    local v = Config.Stables[data.stableId] or data.stableData
    currentStableLocation = data.stableId -- Store current stable key (e.g., "valentinestable")
    
    -- New Data Model Support (checks for SpawnHorse key)
    if v.SpawnHorse then
        HeadingPoint = v.SpawnHorse.h
        currentSpawnPoint = v.SpawnHorse
        StablePoint = {v.SpawnHorse.x, v.SpawnHorse.y, v.SpawnHorse.z}
        
        -- Store full cam data
        CamPos = v.CamHorse -- Now contains x, y, z, rx, ry, rz
        CamPosGear = v.CamHorseGear -- Store Gear Cam
        
        SpawnPoint = {x = v.SpawnHorse.x, y = v.SpawnHorse.y, z = v.SpawnHorse.z, h = v.SpawnHorse.h}
        
        if v.Showroom then
             ShowroomPoint = {x = v.Showroom.x, y = v.Showroom.y, z = v.Showroom.z, h = v.Showroom.h}
        else
             -- Fallback if no Showroom defined
             ShowroomPoint = SpawnPoint
        end
        
    -- Check for Legacy Config format
    elseif v.SpawnPoint and v.SpawnPoint.Pos then
        HeadingPoint = v.SpawnPoint.Heading
        StablePoint = {v.SpawnPoint.Pos.x, v.SpawnPoint.Pos.y, v.SpawnPoint.Pos.z}
        CamPos = v.SpawnPoint.CamPos
        SpawnPoint = {x = v.SpawnPoint.Pos.x, y = v.SpawnPoint.Pos.y, z = v.SpawnPoint.Pos.z, h = v.SpawnPoint.Heading}
        ShowroomPoint = SpawnPoint -- Legacy fallback
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
        if inCustomization and MyHorse_entity ~= nil then
            SendNUIMessage({ EnableCustom = "true" })
            Wait(200)
        elseif inCustomization then
            SendNUIMessage({ EnableCustom = "false" })
            Wait(200)
        else
            Wait(2000) -- Sleep deeply when not customizing
        end
    end
end)

CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds
        if SpawnplayerHorse and DoesEntityExist(SpawnplayerHorse) then
             local getHorseMood = Citizen.InvokeNative(0x42688E94E96FD9B4, SpawnplayerHorse, 3, 0, Citizen.ResultAsFloat())
             if getHorseMood >= 0.60 then
                 Citizen.InvokeNative(0x06D26A96CA1BCA75, SpawnplayerHorse, 3, PlayerPedId())
                 Citizen.InvokeNative(0xA1EB5D029E0191D3, SpawnplayerHorse, 3, 0.99)
             end
        end
    end
end)

-- Whistle Command & Key Mapping (H)


-- Legacy duplicate loop removed


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
