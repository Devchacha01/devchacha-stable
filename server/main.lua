-- RSGCore Stable Server
local RSGCore = exports['rsg-core']:GetCoreObject()

local SelectedHorseId = {}
local Horses
local SaddlebagInUse = {} -- Track which saddlebags are currently open { [stashId] = playerId }

-- Resource name check (optional warning)
CreateThread(function()
    local resourceName = GetCurrentResourceName()
    print("^2[RSG-Stable] ^7Resource started: " .. resourceName)
end)

-- Helper function to get player
local function GetPlayer(src)
    return RSGCore.Functions.GetPlayer(src)
end

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

-- UpdateHorseComponents handler moved to end of file for better organization

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
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You already have ' .. Config.MaxNumberOfHorses .. ' horses! You cannot buy more.', duration = 5000})
            TriggerClientEvent('rsg-stable:client:CloseUI', src) -- Close the UI
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
        
        -- Generate Stats (Use gender from client or default to random)
        local gender = data.Gender or (math.random(1, 2) == 1 and "Male" or "Female")
        local age = math.random(Config.Aging.MinStartAge, Config.Aging.MaxStartAge)
        local iq = math.random(0, 10) -- Base IQ for untrained horses
        local xp = 0
        local born_date = os.time()
        local last_age_update = os.time()
        local breed_type = "Standard"
        local is_fertile = 1
        local breed_count = 0
        
        -- Insert horse into database
        MySQL.query.await('INSERT INTO horses (`cid`, `name`, `model`, `gender`, `age`, `iq`, `xp`, `breed_type`, `stable`, `born_date`, `last_age_update`, `is_fertile`, `breed_count`) VALUES (@Playercid, @name, @model, @gender, @age, @iq, @xp, @breed_type, @stable, @born, @last, @fertile, @bcount);', {
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
            last = last_age_update,
            fertile = is_fertile,
            bcount = breed_count
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


-- Store Horse in Stable
RegisterNetEvent('rsg-stable:server:StoreHorse', function(horseId, stableLoc)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid

    MySQL.update('UPDATE horses SET stable = ?, selected = 0 WHERE id = ? AND cid = ?', {stableLoc, horseId, cid})
end)


-- Create Transfer Offer
RegisterNetEvent("rsg-stable:server:createTransfer", function(data)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local horseId = data.horseID
    local targetServerId = data.targetServerId
    local price = data.price or 0
    
    if not horseId or not targetServerId then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Invalid transfer data!', duration = 5000})
        return
    end
    
    local TargetPlayer = GetPlayer(targetServerId)
    if not TargetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Target player not found!', duration = 5000})
        return
    end
    
    local ownerCid = Player.PlayerData.citizenid
    local targetCid = TargetPlayer.PlayerData.citizenid
    
    if ownerCid == targetCid then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Cannot transfer to yourself!', duration = 5000})
        return
    end
    
    -- Verify ownership
    MySQL.query('SELECT * FROM horses WHERE id = ? AND cid = ?', {horseId, ownerCid}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You do not own this horse!', duration = 5000})
            return
        end
        
        local horse = result[1]
        
        -- Check target's horse count
        MySQL.query('SELECT COUNT(*) as count FROM horses WHERE cid = ?', {targetCid}, function(countResult)
            local targetCount = countResult and countResult[1] and countResult[1].count or 0
            
            if targetCount >= Config.MaxNumberOfHorses then
                TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Target player has too many horses!', duration = 5000})
                return
            end
            
            -- Cancel any existing pending transfer for this horse
            MySQL.update("UPDATE horse_transfers SET status = 'cancelled' WHERE horse_id = ? AND status = 'pending'", { horseId })
            
            -- Create new transfer offer
            MySQL.insert('INSERT INTO horse_transfers (horse_id, from_cid, to_cid, price) VALUES (?, ?, ?, ?)', {
                horseId, ownerCid, targetCid, price
            }, function(transferId)
                if transferId then
                    TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'Transfer offer sent to player!', duration = 5000})
                    TriggerClientEvent('ox_lib:notify', targetServerId, {type = 'success', description = 'You received a horse transfer offer for: ' .. horse.name, duration = 8000})
                end
            end)
        end)
    end)
end)

-- Get Pending Transfers
RegisterNetEvent('rsg-stable:server:getPendingTransfers', function()
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local cid = Player.PlayerData.citizenid
    
    MySQL.query([[
        SELECT 
            t.id, t.horse_id, t.price, t.created_at,
            h.name as horse_name, h.model,
            p.charinfo
        FROM horse_transfers t
        JOIN horses h ON t.horse_id = h.id
        JOIN players p ON t.from_cid = p.citizenid
        WHERE t.to_cid = ? AND t.status = 'pending'
    ]], { cid }, function(results)
        local transfers = {}
        if results then
            for _, row in ipairs(results) do
                local charinfo = json.decode(row.charinfo)
                local senderName = charinfo.firstname .. ' ' .. charinfo.lastname
                
                table.insert(transfers, {
                    id = row.id,
                    horse_id = row.horse_id,
                    horse_name = row.horse_name,
                    price = row.price,
                    sender_name = senderName
                })
            end
        end
        TriggerClientEvent('rsg-stable:client:receivePendingTransfers', src, transfers)
    end)
end)

-- Respond to Transfer (Accept/Decline)
RegisterNetEvent('rsg-stable:server:respondTransfer', function(transferId, accepted)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM horse_transfers WHERE id = ? AND to_cid = ? AND status = "pending"', {transferId, cid}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('rsg-core:notify', src, 'Transfer offer not found or expired.', 'error')
            return
        end
        
        local transfer = result[1]
        
        if not accepted then
            MySQL.update('UPDATE horse_transfers SET status = "declined" WHERE id = ?', {transferId})
            TriggerClientEvent('rsg-core:notify', src, 'Transfer declined.', 'primary')
            
            -- Notify sender
            local Sender = RSGCore.Functions.GetPlayerByCitizenId(transfer.from_cid)
            if Sender then
                TriggerClientEvent('rsg-core:notify', Sender.PlayerData.source, 'Your transfer offer for horse ID '..transfer.horse_id..' was declined.', 'error')
            end
            return
        end
        
        -- Handle Acceptance
        if transfer.price > 0 then
            local cash = Player.PlayerData.money['cash']
            if cash < transfer.price then
                TriggerClientEvent('rsg-core:notify', src, 'Not enough cash!', 'error')
                return
            end
            
            Player.Functions.RemoveMoney('cash', transfer.price, 'horse-transfer-buy')
            
            -- Try to give money to sender if online
            local Sender = RSGCore.Functions.GetPlayerByCitizenId(transfer.from_cid)
            if Sender then
                Sender.Functions.AddMoney('cash', transfer.price, 'horse-transfer-sell')
                TriggerClientEvent('rsg-core:notify', Sender.PlayerData.source, 'Your horse was sold for $'..transfer.price, 'success')
            else
                -- TODO: Add offline support (money management usually requires player online)
            end
        end
        
        -- Check max horses again
        MySQL.query('SELECT COUNT(*) as count FROM horses WHERE cid = ?', {cid}, function(countResult)
            local currentCount = countResult and countResult[1] and countResult[1].count or 0
             if currentCount >= Config.MaxNumberOfHorses then
                TriggerClientEvent('rsg-core:notify', src, 'You have reached the maximum number of horses.', 'error')
                return
            end

            -- Update horse owner
            MySQL.update('UPDATE horses SET cid = ?, selected = 0, stable = "Valentine" WHERE id = ?', {cid, transfer.horse_id}, function(rows)
                if rows > 0 then
                    MySQL.update('UPDATE horse_transfers SET status = "accepted" WHERE id = ?', {transferId})
                    TriggerClientEvent('rsg-core:notify', src, 'Transfer accepted! The horse is now yours.', 'success')
                    
                    -- Refresh UI
                    TriggerEvent('rsg-stable:AskForMyHorses') 
                end
            end)
        end)
    end)
end) 


-- Sell horse with ID
RegisterNetEvent("rsg-stable:SellHorseWithId", function(id)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local Playercid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM horses WHERE `cid`=@cid AND `id`=@id;', {cid = Playercid, id = id}, function(horses)
        if not horses or #horses == 0 then return end
        
        -- Delete the horse
        MySQL.query('DELETE FROM horses WHERE `cid`=@cid AND `id`=@id;', {
            cid = Playercid,
            id = id
        })
        
        -- Give fixed sell price
        local sellPrice = Config.SellPrice or 50
        Player.Functions.AddMoney("cash", sellPrice, "stable-sell-horse")
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'Horse sold for $' .. sellPrice, duration = 5000})
        
        -- Log the sale
        TriggerEvent('rsg-log:server:CreateLog', 'shops', 'Stable Sale', 'red', 
            "**" .. GetPlayerName(src) .. "** (citizenid: " .. Playercid .. " | id: " .. src .. ") sold a horse for $" .. sellPrice)
    end)
end)

-- Feed Horse - removes item from inventory and heals horse
RegisterNetEvent("rsg-stable:server:FeedHorse", function(itemName, horseNetId)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    -- Get feed items config
    local feedItems = Config.HorseCare and Config.HorseCare.FeedItems or {}
    local healthRestore = feedItems[itemName]
    
    if not healthRestore then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'This item cannot be fed to horses.', duration = 3000})
        return
    end
    
    -- Check if player has the item
    local hasItem = Player.Functions.GetItemByName(itemName)
    if not hasItem or hasItem.amount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You don\'t have any ' .. itemName .. '!', duration = 3000})
        return
    end
    
    -- Remove item from inventory
    Player.Functions.RemoveItem(itemName, 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], "remove")
    
    -- Trigger client to play feed animation and heal horse
    TriggerClientEvent('rsg-stable:client:ApplyFeedEffect', src, horseNetId, healthRestore, itemName)
    
    TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'Fed horse with ' .. itemName .. '!', duration = 3000})
end)

-- Saddlebag Lock System - Check if saddlebag is available
RegisterNetEvent("rsg-stable:server:CheckSaddlebag", function(stashId)
    local src = source
    
    if SaddlebagInUse[stashId] then
        local usingPlayer = SaddlebagInUse[stashId]
        if usingPlayer ~= src then
            -- Someone else is using it
            local playerName = GetPlayerName(usingPlayer) or "Another player"
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = playerName .. ' is already using this saddlebag!', duration = 5000})
            TriggerClientEvent('rsg-stable:client:SaddlebagDenied', src)
            return
        end
    end
    
    -- Lock the saddlebag for this player
    SaddlebagInUse[stashId] = src
    TriggerClientEvent('rsg-stable:client:SaddlebagApproved', src, stashId)
end)

-- Saddlebag Lock System - Release lock when closed
RegisterNetEvent("rsg-stable:server:CloseSaddlebag", function(stashId)
    local src = source
    
    -- Only release if this player owns the lock
    if SaddlebagInUse[stashId] == src then
        SaddlebagInUse[stashId] = nil
    end
end)

-- Clean up saddlebag locks when player disconnects
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    -- Remove all locks held by this player
    for stashId, playerId in pairs(SaddlebagInUse) do
        if playerId == src then
            SaddlebagInUse[stashId] = nil
        end
    end
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
    
    local cid = Player.PlayerData.citizenid

    MySQL.query('SELECT * FROM horses WHERE id IN (?, ?) AND cid = ?', {sireId, damId, cid}, function(horses)
        if not horses or #horses ~= 2 then
            TriggerClientEvent('rsg-core:notify', src, 'You need two horses to breed!', 'error')
            return
        end
        
        local sire, dam
        for _, h in pairs(horses) do
            if h.gender == 'Male' then sire = h else dam = h end
        end
        
        if not sire or not dam then
            TriggerClientEvent('rsg-core:notify', src, 'You need one Male and one Female!', 'error')
            return
        end
        
        -- Fertility Check
        if sire.is_fertile ~= 1 then
            TriggerClientEvent('rsg-core:notify', src, 'The male horse is infertile!', 'error')
            return
        end
        if dam.is_fertile ~= 1 then
            TriggerClientEvent('rsg-core:notify', src, 'The female horse is infertile!', 'error')
            return
        end
        
        -- Breed Count Check
        if sire.breed_count >= Config.Breeding.MaxBreedCount then
            TriggerClientEvent('rsg-core:notify', src, 'The male horse has reached max breeding limit!', 'error')
            return
        end
        if dam.breed_count >= Config.Breeding.MaxBreedCount then
            TriggerClientEvent('rsg-core:notify', src, 'The female horse has reached max breeding limit!', 'error')
            return
        end

        -- Increment breed count for both parents
        local newSireCount = sire.breed_count + 1
        local newDamCount = dam.breed_count + 1
        
        -- Check if parents become infertile after this breeding (luck-based at max)
        local sireInfertile = newSireCount >= Config.Breeding.MaxBreedCount and 0 or 1
        local damInfertile = newDamCount >= Config.Breeding.MaxBreedCount and 0 or 1
        
        MySQL.update('UPDATE horses SET breed_count = ?, is_fertile = ? WHERE id = ?', {newSireCount, sireInfertile, sire.id})
        MySQL.update('UPDATE horses SET breed_count = ?, is_fertile = ? WHERE id = ?', {newDamCount, damInfertile, dam.id})

        -- Create Foal
        local foalModel = math.random() > 0.5 and sire.model or dam.model
        local foalGender = math.random(1, 2) == 1 and "Male" or "Female"
        local foalIQ = math.floor((sire.iq + dam.iq) / 2) + math.random(-5, 5)
        foalIQ = math.max(0, math.min(foalIQ, Config.Training.MaxIQ))
        
        -- Roll for infertility
        local foalFertile = 1
        if math.random(1, 100) <= Config.Breeding.InfertilityChance then
            foalFertile = 0
        end
        
        local foalAge = Config.Breeding.FoalStartAge
        local bornDate = os.time()
        
        MySQL.insert('INSERT INTO horses (cid, name, model, gender, age, iq, xp, breed_type, is_fertile, breed_count, born_date, last_age_update) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            cid, name, foalModel, foalGender, foalAge, foalIQ, 0, 'Bred', foalFertile, 0, bornDate, bornDate
        }, function(id)
            if id then
                local fertilityMsg = foalFertile == 1 and "" or " (Infertile)"
                TriggerClientEvent('rsg-core:notify', src, 'Congratulations! A foal was born!' .. fertilityMsg, 'success')
            end
        end)
    end)
end)


-- Save Horse Components
RegisterNetEvent('rsg-stable:UpdateHorseComponents', function(components, horseId, horseEntity)
    local src = source
    
    -- Filter out nil values from components array
    local cleanComponents = {}
    if type(components) == "table" then
        for _, v in ipairs(components) do
            if v ~= nil and v ~= 0 then
                cleanComponents[#cleanComponents+1] = v
            end
        end
    end
    
    -- Don't save if no valid components
    if #cleanComponents == 0 then return end
    
    local Player = GetPlayer(src)
    if not Player then return end
    
    local cid = Player.PlayerData.citizenid
    
    -- Verify ownership
    MySQL.query('SELECT * FROM horses WHERE id = ? AND cid = ?', {horseId, cid}, function(result)
        if result and result[1] then
             local componentsJson = json.encode(cleanComponents)
             MySQL.update('UPDATE horses SET components = ? WHERE id = ?', {componentsJson, horseId})
             
             -- Update client with new components to ensure consistency across re-logs
             TriggerClientEvent("rsg-stable:client:UpdateHorseComponents", src, horseEntity, cleanComponents)
        end
    end)
end)

-- Charge for Customization
RegisterNetEvent('rsg-stable:server:ChargeCustomization', function(amount)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local currentCash = Player.PlayerData.money['cash']
    if currentCash >= amount then
        Player.Functions.RemoveMoney('cash', amount, 'stable-customization')
        TriggerClientEvent('rsg-core:notify', src, 'Paid $'..amount..' for customization services.', 'success')
    else
        TriggerClientEvent('rsg-core:notify', src, 'You could not afford the customization fee ($'..amount..').', 'error')
    end
end)

-- Usable Items for Horse Care

-- brush horse
RSGCore.Functions.CreateUseableItem('horse_brush', function(source, item)
    TriggerClientEvent('rsg-horses:client:playerbrushhorse', source, item.name)
end)

-- player horselantern
RSGCore.Functions.CreateUseableItem('horse_lantern', function(source, item)
    TriggerClientEvent('rsg-horses:client:equipHorseLantern', source, item.name)
end)

 -- horse stimulant
 RSGCore.Functions.CreateUseableItem('horse_stimulant', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[item.name], "remove")
    end
end)

-- feed horse carrot
RSGCore.Functions.CreateUseableItem('horse_carrot', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[item.name], "remove")
    end
end)

 -- feed apple
 RSGCore.Functions.CreateUseableItem('horse_apple', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[item.name], "remove")
    end
end)

-- feed horse sugarcube
RSGCore.Functions.CreateUseableItem('sugarcube', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[item.name], "remove")
    end
end)

-- feed horse haysnack
RSGCore.Functions.CreateUseableItem('haysnack', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[item.name], "remove")
    end
end)

-- feed horse horsemeal
RSGCore.Functions.CreateUseableItem('horsemeal', function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-horses:client:playerfeedhorse', source, item.name)
        TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[item.name], "remove")
    end
end)
