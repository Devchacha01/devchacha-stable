-- RSGCore Stable Server
local RSGCore = exports['rsg-core']:GetCoreObject()

local SelectedHorseId = {}
local Horses

-- Resource name check (optional warning)
CreateThread(function()
    local resourceName = GetCurrentResourceName()
    print("^2[RSG-Stable] ^7Resource started: " .. resourceName)
end)

-- Helper function to get player
local function GetPlayer(src)
    return RSGCore.Functions.GetPlayer(src)
end

-- Update horse components
RegisterNetEvent("rsg-stable:UpdateHorseComponents", function(components, idhorse, MyHorse_entity)
    local src = source
    local encodedComponents = json.encode(components)
    local Player = GetPlayer(src)
    if not Player then return end
    
    local Playercid = Player.PlayerData.citizenid
    local id = idhorse
    
    MySQL.query("UPDATE horses SET `components`=@components WHERE `cid`=@cid AND `id`=@id", {
        components = encodedComponents,
        cid = Playercid,
        id = id
    }, function(done)
        TriggerClientEvent("rsg-stable:client:UpdateHorseComponents", src, MyHorse_entity, components)
    end)
end)

-- Check selected horse
RegisterNetEvent("rsg-stable:CheckSelectedHorse", function()
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local Playercid = Player.PlayerData.citizenid

    MySQL.query('SELECT * FROM horses WHERE `cid`=@cid;', {cid = Playercid}, function(horses)
        if horses and #horses ~= 0 then
            for i = 1, #horses do
                if horses[i].selected == 1 then
                    local updatedHorse = CheckHorseAging(horses[i])
                    if updatedHorse then
                        local stats = {
                            gender = updatedHorse.gender,
                            age = updatedHorse.age,
                            iq = updatedHorse.iq,
                            xp = updatedHorse.xp,
                            breed_type = updatedHorse.breed_type,
                            stable = updatedHorse.stable
                        }
                        TriggerClientEvent("rsg-stable:SetHorseInfo", src, updatedHorse.model, updatedHorse.name, updatedHorse.components, stats, updatedHorse.id)
                    end
                end
            end
        end
    end)
end)

-- Helper function to process aging and death
local function CheckHorseAging(horse)
    if not horse then return nil end
    local currentTime = os.time()
    local bornDate = horse.born_date or currentTime 
    local lastUpdate = horse.last_age_update or currentTime
    
    -- Check for Death
    local ageInSeconds = currentTime - bornDate
    local lifespanSeconds = Config.Aging.LifespanDays * 24 * 60 * 60
    if ageInSeconds >= lifespanSeconds then
        MySQL.update.await('DELETE FROM horses WHERE id = ?', {horse.id})
        return nil -- Horse Died
    end
    
    -- Check for Aging
    local intervalSeconds = Config.Aging.AgeIntervalDays * 24 * 60 * 60
    local timeSinceLastUpdate = currentTime - lastUpdate
    if timeSinceLastUpdate >= intervalSeconds then
        local yearsToAdd = math.floor(timeSinceLastUpdate / intervalSeconds)
        if yearsToAdd > 0 then
            local newAge = horse.age + yearsToAdd
            local newLastUpdate = lastUpdate + (yearsToAdd * intervalSeconds)
            MySQL.update.await('UPDATE horses SET age = ?, last_age_update = ? WHERE id = ?', {newAge, newLastUpdate, horse.id})
            horse.age = newAge
            horse.last_age_update = newLastUpdate
        end
    end
    return horse
end

-- Ask for my horses
RegisterNetEvent("rsg-stable:AskForMyHorses", function()
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local Playercid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM horses WHERE `cid`=@cid;', {cid = Playercid}, function(horses)
        local myHorses = {}
        if horses then
            for k, v in pairs(horses) do
                 local updatedHorse = CheckHorseAging(v)
                 if updatedHorse then
                     myHorses[#myHorses+1] = updatedHorse
                 else
                     TriggerClientEvent('rsg-core:notify', src, Lang:t('stable.horse_died_old_age'), 'error', 5000)
                 end
            end
        end
        TriggerClientEvent("rsg-stable:ReceiveHorsesData", src, myHorses)
    end)
end)

-- Buy horse
RegisterNetEvent("rsg-stable:BuyHorse", function(data, name)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local Playercid = Player.PlayerData.citizenid

    MySQL.query('SELECT * FROM horses WHERE `cid`=@cid;', {cid = Playercid}, function(horses)
        if horses and #horses >= Config.MaxNumberOfHorses then
            TriggerClientEvent('rsg-core:notify', src, Lang:t('stable.max_horses', {Config.MaxNumberOfHorses}), 'error', 5000)
            return
        end
        
        Wait(200)
        
        local purchaseSuccess = false
        local purchaseAmount = 0
        
        if data.Dollar <= 0 then
             return
        end

        purchaseSuccess = Player.Functions.RemoveMoney("cash", data.Dollar, "stable-bought-horse")
        purchaseAmount = data.Dollar
        
        if not purchaseSuccess then
            TriggerClientEvent('rsg-core:notify', src, Lang:t('stable.not_enough_money'), 'error', 5000)
            return
        end
        
        -- Log the purchase
        TriggerEvent('rsg-log:server:CreateLog', 'shops', 'Stable Purchase', 'green', 
            "**" .. GetPlayerName(src) .. "** (citizenid: " .. Playercid .. " | id: " .. src .. ") bought a horse for $" .. purchaseAmount)
        
        -- Generate Stats
        local gender = math.random(1, 2) == 1 and "Male" or "Female"
        local gender = math.random(1, 2) == 1 and "Male" or "Female"
        local age = math.random(Config.Aging.MinStartAge, Config.Aging.MaxStartAge)
        local iq = math.random(0, 10) -- Base IQ for untrained horses
        local xp = 0
        local born_date = os.time()
        local last_age_update = os.time()
        local iq = math.random(0, 10) -- Base IQ for untrained horses
        local xp = 0
        local breed_type = "Standard" -- Can be expanded based on model later
        
        -- Insert horse into database
        MySQL.query.await('INSERT INTO horses (`cid`, `name`, `model`, `gender`, `age`, `iq`, `xp`, `breed_type`, `stable`, `born_date`, `last_age_update`) VALUES (@Playercid, @name, @model, @gender, @age, @iq, @xp, @breed_type, @stable, @born, @last);', {
            Playercid = Playercid,
            name = tostring(name),
            model = data.ModelH,
            gender = gender,
            age = age,
            iq = iq,
            xp = xp,
            breed_type = breed_type,
            stable = data.Shop,
            born = born_date,
            last = last_age_update
        }, function(rowsChanged)
            if rowsChanged then
                TriggerClientEvent('rsg-core:notify', src, Lang:t('stable.horse_purchased'), 'success', 5000)
            end
        end)
    end)
end)

-- Select horse with ID
RegisterNetEvent("rsg-stable:SelectHorseWithId", function(id)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local Playercid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM horses WHERE `cid`=@cid;', {cid = Playercid}, function(horse)
        if not horse then return end
        
        for i = 1, #horse do
            local horseID = horse[i].id
            MySQL.query("UPDATE horses SET `selected`='0' WHERE `cid`=@cid AND `id`=@id", {
                cid = Playercid,
                id = horseID
            })
        end
        
        Wait(300)
        
        for i = 1, #horse do
            if horse[i].id == id then
                MySQL.query("UPDATE horses SET `selected`='1' WHERE `cid`=@cid AND `id`=@id", {
                    cid = Playercid,
                    id = id
                }, function(done)
                    local stats = {
                        gender = horse[i].gender,
                        age = horse[i].age,
                        iq = horse[i].iq,
                        xp = horse[i].xp,
                        breed_type = horse[i].breed_type
                    }
                    TriggerClientEvent("rsg-stable:SetHorseInfo", src, horse[i].model, horse[i].name, horse[i].components, stats, horse[i].id)
                end)
            end
        end
    end)
end)

-- Sell horse with ID
RegisterNetEvent("rsg-stable:SellHorseWithId", function(id)
    local modelHorse = nil
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local Playercid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM horses WHERE `cid`=@cid;', {cid = Playercid}, function(horses)
        if not horses then return end
        
        for i = 1, #horses do
            if tonumber(horses[i].id) == tonumber(id) then
                modelHorse = horses[i].model
                MySQL.query('DELETE FROM horses WHERE `cid`=@cid AND `id`=@id;', {
                    cid = Playercid,
                    id = id
                })
            end
        end

        -- Calculate and give sell price
        for k, v in pairs(Config.Horses) do
            for models, values in pairs(v) do
                if models ~= "name" then
                    if models == modelHorse then
                        local price = tonumber(values[3] / 2)
                        Player.Functions.AddMoney("cash", price, "stable-sell-horse")
                        TriggerClientEvent('rsg-core:notify', src, Lang:t('stable.horse_sold', {price}), 'success', 5000)
                        
                        -- Log the sale
                        TriggerEvent('rsg-log:server:CreateLog', 'shops', 'Stable Sale', 'red', 
                            "**" .. GetPlayerName(src) .. "** (citizenid: " .. Playercid .. " | id: " .. src .. ") sold a horse for $" .. price)
                    end
                end
            end
        end
    end)
end)

-- Create database table if not exists
local function CreateDatabaseIfNotExists()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `horses` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `cid` varchar(50) NOT NULL,
            `selected` int(11) NOT NULL DEFAULT 0,
            `model` varchar(50) NOT NULL,
            `name` varchar(50) NOT NULL,
            `components` varchar(5000) NOT NULL DEFAULT '{}',
            `iq` int(11) NOT NULL DEFAULT 0,
            `xp` int(11) NOT NULL DEFAULT 0,
            `age` int(11) NOT NULL DEFAULT 0,
            `gender` varchar(10) NOT NULL DEFAULT 'Male',
            `breed_type` varchar(50) DEFAULT NULL,
            `stable` varchar(50) DEFAULT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    print("^2[RSG-Stable] ^7Database table 'horses' verified/created.")
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        CreateDatabaseIfNotExists()
    end
end)

-- Also create table on first load
CreateThread(function()
    Wait(1000)
    CreateDatabaseIfNotExists()
end)

-- Callback for external scripts (rex-horsetrainer)
RSGCore.Functions.CreateCallback('rsg-horses:server:GetActiveHorse', function(source, cb)
    cb({ horsexp = 0 })
end)



-- Train Horse Event
RegisterNetEvent('rsg-stable:TrainHorse', function(netId)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local jobName = Player.PlayerData.job.name
    if not Config.Training.Jobs[jobName] then
        TriggerClientEvent('rsg-core:notify', src, 'You are not a horse trainer!', 'error')
        return
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    -- Verify entity existence if needed, but we mainly need the DB ID which we might need to fetch via Client or store on entity

    -- For MVP, we assume the client passes the horse's DB ID or we find it via the active horse logic
    -- Since we don't have a direct "Active Horse ID", we'll query by the entity model matching the player's selected horse
    -- Optimization: Client should send the horse's database ID. For now, let's look up the selected horse.
    
    local cid = Player.PlayerData.citizenid
    MySQL.query('SELECT * FROM horses WHERE cid = ? AND selected = 1', {cid}, function(result)
        if result and result[1] then
            local horse = result[1]
            local newXP = horse.xp + Config.Training.XPPerTrain
            local newIQ = horse.iq
            
            if newXP >= Config.Training.MaxXP then
                newXP = 0
                newIQ = math.min(horse.iq + Config.Training.IQIncreasePerLevel, Config.Training.MaxIQ)
                TriggerClientEvent('rsg-core:notify', src, 'Your horse learned a new trick! IQ Increased!', 'success')
            else
                TriggerClientEvent('rsg-core:notify', src, 'Training complete. XP Gained.', 'primary')
            end
            
            MySQL.update('UPDATE horses SET xp = ?, iq = ? WHERE id = ?', {newXP, newIQ, horse.id})
            
            -- Refresh client
            TriggerClientEvent("rsg-stable:SetHorseInfo", src, horse.model, horse.name, horse.components) 
            -- Note: SetHorseInfo might need to be updated to accept stats too, or we send a separate update
        else
            TriggerClientEvent('rsg-core:notify', src, 'No active horse found to train!', 'error')
        end
    end)
end)

-- Breed Horse Event
RegisterNetEvent('rsg-stable:BreedHorse', function(sireId, damId, name)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    -- Breeding Logic (Simplified)
    -- Parents must be owned by player (or check ownership if passed IDs)
    -- Verify genders (Male + Female)
    
    local cid = Player.PlayerData.citizenid

    MySQL.query('SELECT * FROM horses WHERE id IN (?, ?) AND cid = ?', {sireId, damId, cid}, function(horses)
        if #horses ~= 2 then
            TriggerClientEvent('rsg-core:notify', src, 'You need two horses to breed!', 'error')
            return
        end
        
        local sire, dam
        if horses[1].gender == 'Male' then sire = horses[1] else dam = horses[1] end
        if horses[2].gender == 'Male' then sire = horses[2] else dam = horses[2] end
        
        if not sire or not dam then
            TriggerClientEvent('rsg-core:notify', src, 'You need one Male and one Female!', 'error')
            return
        end
        
        if sire.gender == dam.gender then -- Double check
             TriggerClientEvent('rsg-core:notify', src, 'You need one Male and one Female!', 'error')
             return
        end

        local foalModel = math.random() > 0.5 and sire.model or dam.model
        local foalGender = math.random(1, 2) == 1 and "Male" or "Female"
        local foalIQ = math.floor((sire.iq + dam.iq) / 2) + math.random(-5, 5)
        foalIQ = math.max(0, math.min(foalIQ, Config.Training.MaxIQ)) -- Clamp
        
        MySQL.insert('INSERT INTO horses (cid, name, model, gender, age, iq, xp, breed_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            cid, name, foalModel, foalGender, 1, foalIQ, 0, 'Bred'
        }, function(id)
            if id then
                TriggerClientEvent('rsg-core:notify', src, 'Congratulation! A foal was born.', 'success')
            end
        end)
    end)
end)