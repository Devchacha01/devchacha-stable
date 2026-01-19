-- RSGCore Stable Server
local RSGCore = exports['rsg-core']:GetCoreObject()

local SelectedHorseId = {}
local Horses
local SaddlebagInUse = {} -- Track which saddlebags are currently open { [stashId] = playerId }

-- Crash Recovery System
local ActiveHorses = {} -- { [cid] = { horseId, model, name, components, stats, timestamp } }
local CrashRecoveryTime = 600 -- 10 minutes in seconds

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
                            xp = updatedHorse.xp,
                            stable = updatedHorse.stable,
                            dead = updatedHorse.dead or 0
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
        local xp = 0
        local born_date = os.time()
        local last_age_update = os.time()
        
        -- Insert horse into database
        MySQL.query.await('INSERT INTO horses (`cid`, `name`, `model`, `gender`, `age`, `xp`, `stable`, `born_date`, `last_age_update`) VALUES (@Playercid, @name, @model, @gender, @age, @xp, @stable, @born, @last);', {
            Playercid = Playercid,
            name = tostring(name),
            model = data.ModelH,
            gender = gender,
            age = age,
            xp = xp,
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
                if horse[i].dead == 1 then
                    TriggerClientEvent('rsg-core:notify', src, 'This horse is injured and cannot be taken out! Revive it first.', 'error')
                    return
                end

                MySQL.query("UPDATE horses SET `selected`='1' WHERE `cid`=@cid AND `id`=@id", {
                    cid = Playercid,
                    id = id
                }, function(done)
                    local stats = {
                        gender = horse[i].gender,
                        age = horse[i].age,
                        xp = horse[i].xp,
                        stable = horse[i].stable,
                        dead = horse[i].dead or 0
                    }
                    
                    -- Store active horse for crash recovery
                    ActiveHorses[Playercid] = {
                        horseId = horse[i].id,
                        model = horse[i].model,
                        name = horse[i].name,
                        components = horse[i].components,
                        stats = stats,
                        timestamp = os.time()
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

    -- Clear crash recovery when horse is stored
    ActiveHorses[cid] = nil
    
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

-- Set Horse Dead
RegisterNetEvent('rsg-stable:server:SetHorseDead', function(horseId)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local cid = Player.PlayerData.citizenid
    
    MySQL.update('UPDATE horses SET dead = 1, selected = 0, stable = "valentine" WHERE id = ? AND cid = ?', {horseId, cid})
    TriggerClientEvent('rsg-core:notify', src, 'Your horse is critically injured! It has been returned to the stable.', 'error', 5000)
end)

-- Revive Horse
RegisterNetEvent('rsg-stable:server:ReviveHorse', function(horseId, stableLoc)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local cid = Player.PlayerData.citizenid
    local cost = 50
    -- Default to valentine if no location provided
    local newStable = stableLoc or "valentine"
    
    local cash = Player.PlayerData.money['cash']
    if cash >= cost then
        Player.Functions.RemoveMoney('cash', cost, 'stable-revive-horse')
        
        MySQL.update('UPDATE horses SET dead = 0, stable = ? WHERE id = ? AND cid = ?', {newStable, horseId, cid}, function(rows)
            if rows > 0 then
                TriggerClientEvent('rsg-core:notify', src, 'Your horse has been revived ($'..cost..').', 'success')
                
                -- Refresh UI by fetching fresh horse data
                MySQL.query('SELECT * FROM horses WHERE `cid`=@cid;', {cid = cid}, function(horses)
                    local myHorses = {}
                    if horses then
                        for k, v in pairs(horses) do
                            local updatedHorse = CheckHorseAging(v)
                            if updatedHorse then
                                myHorses[#myHorses+1] = updatedHorse
                            end
                        end
                    end
                    TriggerClientEvent("rsg-stable:ReceiveHorsesData", src, myHorses)
                end)
            end
        end)
    else
        TriggerClientEvent('rsg-core:notify', src, 'You cannot afford to revive this horse ($'..cost..').', 'error')
    end
end)

-- Rename Horse
RegisterNetEvent('rsg-stable:server:RenameHorse', function(horseId, newName)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local cid = Player.PlayerData.citizenid
    local cost = 20
    
    -- Validate name
    if not newName or newName == "" or #newName < 2 or #newName > 30 then
        TriggerClientEvent('rsg-core:notify', src, 'Invalid name! Must be 2-30 characters.', 'error')
        return
    end
    
    local cash = Player.PlayerData.money['cash']
    if cash >= cost then
        -- Verify ownership first
        MySQL.query('SELECT * FROM horses WHERE id = ? AND cid = ?', {horseId, cid}, function(result)
            if not result or #result == 0 then
                TriggerClientEvent('rsg-core:notify', src, 'You do not own this horse!', 'error')
                return
            end
            
            Player.Functions.RemoveMoney('cash', cost, 'stable-rename-horse')
            
            MySQL.update('UPDATE horses SET name = ? WHERE id = ? AND cid = ?', {newName, horseId, cid}, function(rows)
                if rows > 0 then
                    TriggerClientEvent('rsg-core:notify', src, 'Horse renamed to "'..newName..'" ($'..cost..').', 'success')
                    
                    -- Refresh UI
                    MySQL.query('SELECT * FROM horses WHERE `cid`=@cid;', {cid = cid}, function(horses)
                        local myHorses = {}
                        if horses then
                            for k, v in pairs(horses) do
                                local updatedHorse = CheckHorseAging(v)
                                if updatedHorse then
                                    myHorses[#myHorses+1] = updatedHorse
                                end
                            end
                        end
                        TriggerClientEvent("rsg-stable:ReceiveHorsesData", src, myHorses)
                    end)
                end
            end)
        end)
    else
        TriggerClientEvent('rsg-core:notify', src, 'You cannot afford to rename this horse ($'..cost..').', 'error')
    end
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
    
    -- Note: We do NOT clear ActiveHorses here - that's the whole point!
    -- The crash recovery data persists so player can recover horse on reconnect
end)

-- Check for crash recovery when player loads
local function CheckCrashRecovery(src)
    local Player = GetPlayer(src)
    if not Player then return end
    
    local cid = Player.PlayerData.citizenid
    local activeData = ActiveHorses[cid]
    
    if activeData then
        local currentTime = os.time()
        local elapsedTime = currentTime - activeData.timestamp
        local remainingTime = CrashRecoveryTime - elapsedTime
        
        if remainingTime > 0 then
            -- Player has crash recovery available
            SetTimeout(5000, function() -- Wait for client to fully load
                TriggerClientEvent('rsg-stable:client:CrashRecovery', src, remainingTime)
                
                -- Also set their horse info so InitiateHorse works
                TriggerClientEvent("rsg-stable:SetHorseInfo", src, activeData.model, activeData.name, activeData.components, activeData.stats, activeData.horseId)
            end)
        else
            -- Expired, clear the data
            ActiveHorses[cid] = nil
        end
    end
end

-- RSGCore player load events (multiple versions for compatibility)
RegisterNetEvent('RSGCore:Server:OnPlayerLoaded', function()
    CheckCrashRecovery(source)
end)

RegisterNetEvent('rsg-core:server:playerLoaded', function()
    CheckCrashRecovery(source)
end)

-- Clear crash recovery when horse dies
RegisterNetEvent('rsg-stable:server:ClearCrashRecovery', function()
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local cid = Player.PlayerData.citizenid
    ActiveHorses[cid] = nil
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
            `age` int(11) NOT NULL DEFAULT 0,
            `xp` int(11) NOT NULL DEFAULT 0,
            `gender` varchar(10) NOT NULL DEFAULT 'Male',
            `stable` varchar(50) DEFAULT NULL,
            `dead` tinyint(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Add dead column if not exists (migration)
    MySQL.query("SHOW COLUMNS FROM `horses` LIKE 'dead'", function(result)
        if not result or #result == 0 then
            MySQL.query("ALTER TABLE `horses` ADD COLUMN `dead` tinyint(1) NOT NULL DEFAULT 0")
            print("^2[RSG-Stable] ^7Added 'dead' column to horses table.")
        end
    end)
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





-- Train Horse Event


-- Breed Horse Event



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
