local QBCore = exports['qb-core']:GetCoreObject()

local function InitializeDatabase()
    local sql = [[
        CREATE TABLE IF NOT EXISTS player_pets (
            id INT(11) NOT NULL AUTO_INCREMENT,
            citizenid VARCHAR(50) NOT NULL,
            pet_model VARCHAR(50) DEFAULT NULL,
            pet_hash VARCHAR(50) DEFAULT NULL,
            pet_breed VARCHAR(50) DEFAULT NULL,
            PRIMARY KEY (id)
        );
    ]]

    MySQL.Async.execute(sql, {}, function(affectedRows)
        print("Database table `player_pets` initialized or already exists.")
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        InitializeDatabase()
    end
end)

RegisterNetEvent('qb-pets:buyPetServer')
AddEventHandler('qb-pets:buyPetServer', function(data)
    local playerId = source
    local player = QBCore.Functions.GetPlayer(playerId) 
    local citizenId = player.PlayerData.citizenid 

    local petModel = data.model
    local petHash = GetHashKey(petModel)
    local price = data.price
    local petBreed = data.breed  

    if player.PlayerData.money.cash >= price then
        player.Functions.RemoveMoney('cash', price, 'buy-pet')
        MySQL.Async.execute('INSERT INTO player_pets (citizenid, pet_model, pet_hash, pet_breed) VALUES (@citizenid, @pet_model, @pet_hash, @pet_breed)', {
            ['@citizenid'] = citizenId,
            ['@pet_model'] = petModel,
            ['@pet_hash'] = petHash,
            ['@pet_breed'] = petBreed,
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('qb-pets:buyPetSuccess', playerId, data)
            else
                TriggerClientEvent('QBCore:Notify', playerId, 'There was an error processing your purchase.', 'error')
            end
        end)
    else
        TriggerClientEvent('QBCore:Notify', playerId, 'You do not have enough cash to buy this pet.', 'error')
    end
end)

RegisterNetEvent('qb-pets:spawnPet')
AddEventHandler('qb-pets:spawnPet', function(petModel)
    local playerId = source
    local player = QBCore.Functions.GetPlayer(playerId)
    local citizenId = player.PlayerData.citizenid

    MySQL.Async.fetchAll('SELECT pet_model FROM player_pets WHERE citizenid = @citizenid AND pet_model = @pet_model', {
        ['@citizenid'] = citizenId,
        ['@pet_model'] = petModel
    }, function(result)
        if result[1] then
            TriggerClientEvent('qb-pets:spawnPetClient', playerId, petModel)
        else
            TriggerClientEvent('QBCore:Notify', playerId, 'Pet not found.', 'error')
        end
    end)
end)


RegisterNetEvent('qb-pets:getPets')
AddEventHandler('qb-pets:getPets', function()
    local playerId = source
    local player = QBCore.Functions.GetPlayer(playerId)
    local citizenId = player.PlayerData.citizenid

    MySQL.Async.fetchAll('SELECT id, pet_breed, pet_model FROM player_pets WHERE citizenid = @citizenid', {
        ['@citizenid'] = citizenId
    }, function(result)
        TriggerClientEvent('qb-pets:openPetMenu', playerId, result)
    end)
end)