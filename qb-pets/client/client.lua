local QBCore = exports['qb-core']:GetCoreObject()
local pets = {}
local playerPetData = {}

local pedModel = `mp_m_shopkeep_01`
local pedCoords = vector3(-1310.43, -1319.79, 3.85)
local pedHeading = 110.0
local previewPed = nil 
local isPetOut = false
local currentPetEntity
local petBlip = nil

Citizen.CreateThread(function()
    local blip = AddBlipForCoord(pedCoords.x, pedCoords.y, pedCoords.z)
    
    SetBlipSprite(blip, 141) 
    SetBlipDisplay(blip, 4) 
    SetBlipScale(blip, 1.0) 
    SetBlipColour(blip, 56) 
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pet Shop") 
    EndTextCommandSetBlipName(blip)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if isPetOut == true and currentPetEntity ~= nil then
            if not DoesBlipExist(petBlip) then
                petBlip = AddBlipForEntity(currentPetEntity)
                
                SetBlipSprite(petBlip, 141) 
                SetBlipDisplay(petBlip, 4) 
                SetBlipScale(petBlip, 0.7) 
                SetBlipColour(petBlip, 46) 

                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Pet") 
                EndTextCommandSetBlipName(petBlip)
            end
        else
            if DoesBlipExist(petBlip) then
                RemoveBlip(petBlip)
                petBlip = nil 
            end
        end
    end
end)

function SpawnShopPed()
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(1)
    end

    local ped = CreatePed(4, pedModel, pedCoords.x, pedCoords.y, pedCoords.z, pedHeading, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedFleeAttributes(ped, 0, 0)
    SetPedCombatAttributes(ped, 17, 1)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                type = "client",
                event = "qb-pets:openMenu",
                icon = "fas fa-paw",
                label = "Talk to Shopkeeper",
            },
        },
        distance = 1.5
    })
end

function openShopMenu(menuData)
    local menuData = {
        {
            header = "Pet Shop",
            txt = "Choose a pet category",
            isMenuHeader = true
        },
        {
            header = "Dogs",
            txt = "View available dogs",
            params = {
                event = "qb-pets:showDogsMenu"
            }
        },
        {
            header = "Cats",
            txt = "View available cats",
            params = {
                event = "qb-pets:showCatsMenu"
            }
        },
        {
            header = "Take out pet",
            txt = "Take out one of your pets",
            params = {
                event = "qb-pets:getPlayerPets"
            }
        },
        {
            header = "Close",
            txt = "Close the shop menu",
            params = {
                event = "qb-menu:close"
            }
        }
    }

    TriggerEvent('qb-menu:client:openMenu', menuData)
end

function OpenPetPreviewMenu(pet)
    local menuData = {
        {
            header = pet.breed .. " Preview",
            txt = "Here is a preview of the " .. pet.breed,
            isMenuHeader = true
        },
        {
            header = "Buy " .. pet.breed,
            txt = "$" .. pet.price,
            params = {
                event = "qb-pets:buyPet",
                args = pet
            }
        },
        {
            header = "Back",
            txt = "",
            params = {
                event = "qb-pets:openMenu",
                args = pet.category
            }
        }
    }

    TriggerEvent('qb-menu:client:openMenu', menuData)
end

function OpenMenu(menu)
    DeletePreview()
    TriggerEvent('qb-menu:client:openMenu', menu)
end

RegisterNetEvent('qb-pets:openMenu')
AddEventHandler('qb-pets:openMenu', function()
    DeletePreview()
    openShopMenu()
end)

RegisterNetEvent('qb-pets:showDogsMenu')
AddEventHandler('qb-pets:showDogsMenu', function()
    OpenMenu(GenerateMenuData("Dogs"))
end)

RegisterNetEvent('qb-pets:showCatsMenu')
AddEventHandler('qb-pets:showCatsMenu', function()
    OpenMenu(GenerateMenuData("Cats"))
end)

RegisterNetEvent('qb-pets:getPlayerPets')
AddEventHandler('qb-pets:getPlayerPets', function()
    TriggerServerEvent('qb-pets:getPets')
end)

RegisterNetEvent('qb-pets:showPetPreview')
AddEventHandler('qb-pets:showPetPreview', function(pet)
    local petSpawnCoords = vector3(-1311.00, -1320.61, 3.85) 
    SpawnPreviewPet(pet.model, petSpawnCoords)
    OpenPetPreviewMenu(pet)
end)

RegisterNetEvent('qb-pets:getPlayerPets')
AddEventHandler('qb-pets:getPlayerPets', function()
    TriggerServerEvent('qb-pets:getPets')
end)

RegisterNetEvent('qb-pets:buyPet')
AddEventHandler('qb-pets:buyPet', function(data)
    if isPetOut == false then
        local breed = data.breed
        local model = data.model
        local price = data.price

        data.model = CorrectModels(model)
        TriggerServerEvent('qb-pets:buyPetServer', data)
    else
        DeletePreview()
        QBCore.Functions.Notify("You cannot buy a pet while another is out", "error")
    end
end)

RegisterNetEvent('qb-pets:buyPetSuccess')
AddEventHandler('qb-pets:buyPetSuccess', function(data)
    local breed = data.breed
    local model = data.model
    local price = data.price
    local boughtPet = previewPed
    local playerPed = PlayerPedId()

    QBCore.Functions.Notify("You bought a " .. breed .. " for $" .. price, "success")
    GivePetTasks(boughtPet, playerPed)
    table.insert(pets, { boughtPet = boughtPet, model = model })
    previewPed = nil
end)

Citizen.CreateThread(function()
    SpawnShopPed()
end)

function GenerateMenuData(category)
    local menuData = {
        {
            header = category,
            txt = "Available " .. category:lower(),
            isMenuHeader = true
        }
    }

    for _, pet in pairs(Config.Pets[category]) do
        table.insert(menuData, {
            header = pet.breed,
            txt = "$" .. pet.price,
            params = {
                event = "qb-pets:showPetPreview",
                args = { breed = pet.breed, model = pet.model, price = pet.price, category = category }
            }
        })
    end

    table.insert(menuData, {
        header = "Back",
        txt = "Back to main menu",
        params = {
            event = "qb-pets:openMenu"
        }
    })

    return menuData
end

function SpawnPreviewPet(model, petSpawnCoords)
    DeletePreview()

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end

    previewPed = CreatePed(4, model, petSpawnCoords.x, petSpawnCoords.y, petSpawnCoords.z, 108.94, false, true)
    SetEntityAsMissionEntity(previewPed, true, true)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    SetPedDiesWhenInjured(previewPed, false)
    SetPedCanRagdollFromPlayerImpact(previewPed, false)
    SetPedFleeAttributes(previewPed, 0, 0)
    SetPedCombatAttributes(previewPed, 17, 1)
    FreezeEntityPosition(previewPed, true)
    SetEntityInvincible(previewPed, true)
end

function DeletePreview()
    if previewPed then
        DeletePed(previewPed) 
    end
end

local modelCorrections = {
    [1462895032] = "a_c_cat_01",
    [351016938] = "a_c_chop",
    [1318032802] = "a_c_husky",
    [1125994524] = "a_c_poodle",
    [1832265812] = "a_c_pug",
    [882848737] = "a_c_retriever",
    [1126154828] = "a_c_shepherd",
    [-1384627013] = "a_c_westy",
}

function CorrectModels(model)
    return modelCorrections[model] or model
end

function DeletePets()
    for _, pet in ipairs(pets) do
        if DoesEntityExist(pet.ped) then
            DeletePed(pet.ped)
        end
    end
    pets = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent('qb-pets:setPetState', pet, false)
        DeletePets()
    end
end)

RegisterNetEvent('qb-pets:spawnPetClient')
AddEventHandler('qb-pets:spawnPetClient', function(petModel)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    RequestModel(petModel)
    while not HasModelLoaded(petModel) do
        Wait(0)
    end

    local petPed = CreatePed(28, petModel, -1311.02, -1319.05, 3.85, 107.02, true, false)

    GivePetTasks(petPed, playerPed)
    table.insert(pets, { petPed = petPed, model = model })
end)

function GivePetTasks(pet, playerPed)
    SetEntityAsMissionEntity(pet, true, true)
    SetBlockingOfNonTemporaryEvents(pet, true)
    SetPedDiesWhenInjured(pet, false)
    SetPedCanRagdollFromPlayerImpact(pet, false)
    SetPedFleeAttributes(pet, 0, false)
    SetPedCombatAttributes(pet, 46, true)
    FreezeEntityPosition(pet, false)
    TaskFollowToOffsetOfEntity(pet, playerPed, 0.0, 1.0, 0.0, 2.0, -1, 1.0, true)
    SetEntityInvincible(pet, true)
    AssignPetToPlayer(pet)
    isPetOut = true
    currentPetEntity = pet
end

function AssignPetToPlayer(pet)
    local playerId = PlayerId() 
    playerPetData[pet] = playerId
    AddTargetToPet(pet) 
end

function AddTargetToPet(pet)
    local assignedPlayerId = playerPetData[pet]
    if assignedPlayerId and assignedPlayerId == PlayerId() then
    exports['qb-target']:AddTargetEntity(pet, {
        options = {
            {
                type = "client",
                event = "qb-pets:pet",
                icon = "fas fa-paw",
                label = "Pet",
            },
            {
                type = "client",
                event = "qb-pets:feed",
                icon = "fas fa-bone",
                label = "Feed",
            },
            {
                type = "client",
                event = "qb-pets:play",
                icon = "fas fa-futbol",
                label = "Play",
            },
            {
                type = "client",
                event = "qb-pets:sendHome",
                icon = "fas fa-home",
                label = "Send Home",
            }
        },
        distance = 2.0
    })
    end
end

RegisterNetEvent('qb-pets:pet')
AddEventHandler('qb-pets:pet', function(pet)
    if DoesEntityExist(currentPetEntity) then
        local petModel = GetEntityModel(currentPetEntity)
        petModel = CorrectModels(petModel)

        print("Playing sound for entity: ", currentPetEntity)
        print("Pet model: ", petModel)

        if petModel == "a_c_cat_01" then
            SendNUIMessage({
                action = "playCatSound"
            })
        else
            SendNUIMessage({
                action = "playDogSound"
            })
        end
        PetAnimal()

    else
        print("No valid pet entity found.")
    end
end)


RegisterNetEvent('qb-pets:feed')
AddEventHandler('qb-pets:feed', function()
    
end)

RegisterNetEvent('qb-pets:play')
AddEventHandler('qb-pets:play', function()
    
end)


RegisterNetEvent('qb-pets:sendHome')
AddEventHandler('qb-pets:sendHome', function()
    local pet = currentPetEntity
    if DoesEntityExist(pet) then
        local assignedPlayerId = playerPetData[pet]
        if assignedPlayerId and assignedPlayerId == PlayerId() then
            TaskWanderStandard(pet, 10.0, 10)
            SetEntityAsMissionEntity(pet, false, false)
            SetPedCanRagdollFromPlayerImpact(pet, true)
            isPetOut = false
            exports['qb-target']:RemoveTargetEntity(pet)
            print("Pet sent home successfully.")
            pet = nil
            currentPetEntity = nil
        else
            print("You are not the owner of this pet.")
            TriggerEvent('QBCore:Notify', "You are not the owner of this pet.", "error")
        end
    end
end)

RegisterCommand("sendpethome", function()
    TriggerEvent('qb-pets:sendHome')
end, false) 

RegisterNetEvent('qb-pets:openPetMenu')
AddEventHandler('qb-pets:openPetMenu', function(pets)
    local menuOptions = {}

    table.insert(menuOptions, {
        header = "Pets",
        txt = "Owned pets",
        isMenuHeader = true,
    })

    for i = 1, #pets do
        table.insert(menuOptions, {
            header = pets[i].pet_breed,
            txt = "Model: " .. pets[i].pet_model,
            params = {
                event = 'qb-pets:spawnSelectedPet',
                args = {
                    petModel = pets[i].pet_model
                }
            }
        })
    end

    table.insert(menuOptions, {
        header = "Back",
        txt = "Go back",
        params = {
            event = "qb-pets:openMenu"
        }
    })

    exports['qb-menu']:openMenu(menuOptions)
end)

RegisterNetEvent('qb-pets:spawnSelectedPet')
AddEventHandler('qb-pets:spawnSelectedPet', function(data)
    if isPetOut == false then
        local petModel = data.petModel
        data.model = CorrectModels(petModel)
        TriggerServerEvent('qb-pets:spawnPet', petModel)
    else
        QBCore.Functions.Notify("You already have a pet out", "error")
    end  
end)


function PetAnimal()
    QBCore.Functions.Progressbar('pet_animal', 'Petting animal...', 4000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false, 
        disableCombat = true,
    }, {
        animDict = 'creatures@rottweiler@tricks@', 
        anim = 'petting_franklin', 
        flags = 49, 
    }, {}, {}, function() -- Triggered if progress is finished

    end, function() -- Triggered if progress is canceled


    end)
end

RegisterNetEvent('qb-pets:callPet')
AddEventHandler('qb-pets:callPet', function()
    local pet = currentPetEntity
    if DoesEntityExist(pet) then
        local assignedPlayerId = playerPetData[pet]
        if assignedPlayerId and assignedPlayerId == PlayerId() then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            SendNUIMessage({
                action = "playWhistleSound"
            })

            SetEntityCoords(pet, playerCoords.x + 1.5, playerCoords.y, playerCoords.z - 0.5)

            print("Pet teleported to player.")
        else
            print("You are not the owner of this pet.")
            TriggerEvent('QBCore:Notify', "You are not the owner of this pet.", "error")
        end
    else
        print("No pet to call.")
        TriggerEvent('QBCore:Notify', "You do not have a pet out.", "error")
    end
end)

RegisterCommand('callpet', function()
    TriggerEvent('qb-pets:callPet')
end, false)



