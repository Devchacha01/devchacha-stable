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
                    TriggerClientEvent("rsg-stable:SetHorseInfo", src, horses[i].model, horses[i].name, horses[i].components)
                end
            end
        end
    end)
end)

-- Ask for my horses
RegisterNetEvent("rsg-stable:AskForMyHorses", function()
    local src = source
    local horseId = nil
    local components = nil
    local Player = GetPlayer(src)
    if not Player then return end
    
    local Playercid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM horses WHERE `cid`=@cid;', {cid = Playercid}, function(horses)
        if horses and horses[1] then
            horseId = horses[1].id
        else
            horseId = nil
        end

        TriggerClientEvent("rsg-stable:ReceiveHorsesData", src, horses or {})
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
        
        if data.IsGold then
            local currentBank = Player.Functions.GetMoney('bank')
            if data.Gold <= currentBank then
                purchaseSuccess = Player.Functions.RemoveMoney("bank", data.Gold, "stable-bought-horse")
                purchaseAmount = data.Gold
            else
                TriggerClientEvent('rsg-core:notify', src, Lang:t('stable.not_enough_money'), 'error', 5000)
                return
            end
        else
            purchaseSuccess = Player.Functions.RemoveMoney("cash", data.Dollar, "stable-bought-horse")
            purchaseAmount = data.Dollar
        end
        
        if not purchaseSuccess then
            TriggerClientEvent('rsg-core:notify', src, Lang:t('stable.not_enough_money'), 'error', 5000)
            return
        end
        
        -- Log the purchase
        TriggerEvent('rsg-log:server:CreateLog', 'shops', 'Stable Purchase', 'green', 
            "**" .. GetPlayerName(src) .. "** (citizenid: " .. Playercid .. " | id: " .. src .. ") bought a horse for $" .. purchaseAmount)
        
        -- Insert horse into database
        MySQL.query.await('INSERT INTO horses (`cid`, `name`, `model`) VALUES (@Playercid, @name, @model);', {
            Playercid = Playercid,
            name = tostring(name),
            model = data.ModelH
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
                    TriggerClientEvent("rsg-stable:SetHorseInfo", src, horse[i].model, horse[i].name, horse[i].components)
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