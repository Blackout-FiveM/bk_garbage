ESX = nil

local PlayerData = {}

local JobsBool = false
local GarbageVehiclePlate
local Bags
local hasBin = false
local cachedBins = {}
local PlayerHasProp = false
local PlayerProps
local vehicleSpawner = vector3(Config.VehicleSpawnPoint.x, Config.VehicleSpawnPoint.y, Config.VehicleSpawnPoint.z)

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
end)

CreatePedWithInteraction("s_m_y_garbage", -621.39, -1640.72, 24.97, 151.66, {Invicible = true, BlockingTemporaryEvents = true, Freeze = true}, {Visible = true, Sprite = 318, Color = 2, Text = Locale.BlipTitle}, {Type = 1, g = 200}, "", {
    onInteract = function (this)
       if PlayerData.job and PlayerData.job.name == "garbage" then

            if JobsBool == false then
                if ESX.Game.IsSpawnPointClear(vehicleSpawner, 5.0) then

                    local model = GetHashKey("trash")
                    
                    RequestModel(model)
                    while not HasModelLoaded(model) do
                            Citizen.Wait(10) 
                    end
    
                    local vehicle = CreateVehicle(model, vehicleSpawner, Config.VehicleSpawnPoint.h, true, false)
                    TaskWarpPedIntoVehicle(PlayerPedId(-1), vehicle, -1)
    
                    GarbageVehiclePlate = GetVehicleNumberPlateText(vehicle)
                    Bags = 0

                    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                        if skin.sex == 0 then
                            TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
                        else
                            TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
                        end
                    end)
                    
                    JobsBool = true
                else
                    ESX.ShowNotification(Locale.SpawnBlocked)
                end

            else

                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                    TriggerEvent('skinchanger:loadSkin', skin)
                end)

                DestroyBins()
                ClearPedTasksImmediately(GetPlayerPed(-1))

                Bags = 0

                JobsBool = false
            end

        end

    end,

    onActive = function (this)
        if JobsBool == false then
            this.HelpText = Locale.HelpText_1
        else
            this.HelpText = Locale.HelpText_2
        end
    end
})

local msec_sell = 200

Citizen.CreateThread(function()
    
    while true do

        if PlayerData.job and PlayerData.job.name == "garbage" and JobsBool == true then

            local position = GetEntityCoords(PlayerPedId(-1))
            local distance = GetDistanceBetweenCoords(position, Config.SellPoint, true)

            if distance > 50 then
                msec_sell = 200
            else
                msec_sell = 1
                DrawMarker(1, Config.SellPoint, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 5.0, 5.0, 1.0, 0, 200, 0, 200, false, true, 2, nil, nil, false)
                
                if distance < 4 then
                
                    AddTextEntry("HELP", Locale.SellInfo)
                    DisplayHelpTextThisFrame("HELP", false)
                    
                    if IsControlJustPressed(1, 51) then
                        
                        if IsPedInAnyVehicle(PlayerPedId(-1)) then

                            local vehicle = GetVehiclePedIsUsing(PlayerPedId(-1))

                            if GarbageVehiclePlate == GetVehicleNumberPlateText(vehicle) then

                                if Bags > 0 then
                                    
                                    local Price = Bags * Config.Price

                                    TriggerServerEvent('bk_garbage:pay', Price)

                                    ESX.ShowNotification(string.format(Locale.Pay, Price))
                                    
                                    Bags = 0

                                else

                                    ESX.ShowNotification(Locale.NoBags)

                                end

                            end

                        end

                    end
        
                end
            end

        end


    Citizen.Wait(msec_sell)
    end
end)

local msec_delete = 200

Citizen.CreateThread(function()
    while true do

        if PlayerData.job and PlayerData.job.name == "garbage" and JobsBool == true then
            
            local position = GetEntityCoords(PlayerPedId(-1))
            local distance = GetDistanceBetweenCoords(position, Config.DeletePoint, true)

            if distance > 50 then
                msec_delete = 200
            else
                msec_delete = 1
                DrawMarker(1, Config.DeletePoint, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 5.0, 5.0, 1.0, 200, 0, 0, 200, false, true, 2, nil, nil, false)
                
                if distance < 4 then
                
                    AddTextEntry("HELP", Locale.DeleteVehicle)
                    DisplayHelpTextThisFrame("HELP", false)
                    
                    if IsControlJustPressed(1, 51) then
                        
                        if IsPedInAnyVehicle(PlayerPedId(-1)) then

                            local vehicle = GetVehiclePedIsUsing(PlayerPedId(-1))

                            if GarbageVehiclePlate == GetVehicleNumberPlateText(vehicle) then

                                DeleteVehicle(vehicle)

                                Bags = 0
                                
                            end

                        end

                    end
        
                end
            end
        end

    Citizen.Wait(msec_delete)
    end
end)

Citizen.CreateThread(function()

    while true do

        local msec = 1000

        if PlayerData.job and PlayerData.job.name == "garbage" and JobsBool == true then

            if hasBin == false then

                if IsPedInAnyVehicle(PlayerPedId(-1)) == false then
                    
                    local entity, entityDst = ESX.Game.GetClosestObject(Config.BinsAvailable)

                    if DoesEntityExist(entity) and entityDst <= 1.5 then
                        msec = 5

                        local binsCoords = GetEntityCoords(entity)

                        ESX.Game.Utils.DrawText3D(binsCoords + vector3(0.0, 0.0, 0.5), "[~g~E~s~] Collected the garbage bag", 0.7)

                        if IsControlJustReleased(0, 38) then
                            if not cachedBins[entity] then
                                cachedBins[entity] = true

                                TaskStartScenarioInPlace(PlayerPedId(-1), "PROP_HUMAN_BUM_BIN", 0, true)
                                Citizen.Wait(10000)
                                ClearPedTasks(PlayerPedId(-1))

                                if not HasAnimDictLoaded("anim@heists@narcotics@trash") then
                                    RequestAnimDict("anim@heists@narcotics@trash")
                                end

                                AddBinsToPlayer()

                                TaskPlayAnim(PlayerPedId(-1), 'anim@heists@narcotics@trash', 'walk', 1.0, -1.0,-1,49,0,0, 0,0)

                                hasBin = true
                            else
                                ESX.ShowNotification(Locale.AlreadySearch)
                            end
                        end

                    end

                end
            else

                if IsPedInAnyVehicle(PlayerPedId(-1)) == false then

                    local coords = GetEntityCoords(PlayerPedId(-1))
                    
                    local vehicle, distance = ESX.Game.GetClosestVehicle({
                        x = coords.x,
                        y = coords.y,
                        z = coords.z
                    })

                    local TruckCoords = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "platelight"))
                    local TrapDistance = GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), TruckCoords)

                    if DoesEntityExist(vehicle) and TrapDistance <= 3 and GetEntityModel(vehicle) == GetHashKey("trash") then
                        msec = 5

                        if GarbageVehiclePlate == GetVehicleNumberPlateText(vehicle) then
                                
                            ESX.ShowHelpNotification(Locale.DropBin)

                            if IsControlJustReleased(0, 38) then

                                if Bags >= Config.Max then
                                    ESX.ShowNotification(Locale.TruckFull)
                                else
                                    ClearPedTasksImmediately(GetPlayerPed(-1))
                                    TaskPlayAnim(GetPlayerPed(-1), 'anim@heists@narcotics@trash', 'throw_b', 1.0, -1.0,-1,2,0,0, 0,0)
                                    Citizen.Wait(3000)
                                    DestroyBins()
                                    ClearPedTasksImmediately(GetPlayerPed(-1))
                                
                                    hasBin = false

                                    Bags = Bags + 1
                                end

                            end

                        end

                    end

                end

            end

        end

        Citizen.Wait(msec)
    end
end)

function AddBinsToPlayer()
    local Player = PlayerPedId()
    local x,y,z = table.unpack(GetEntityCoords(Player))
    local model = GetHashKey("hei_prop_heist_binbag")


    if not HasModelLoaded(model) then
        while not HasModelLoaded(model) do
            RequestModel(model)
            Wait(10)
        end
    end
  
    prop =  CreateObject(model, 0, 0, 0, true, true, true)
    AttachEntityToEntity(prop, Player, GetPedBoneIndex(Player, 57005), 0.12, 0.0, 0.00, 25.0, 270.0, 180.0, true, true, false, true, 1, true)
    PlayerProps = prop
    PlayerHasProp = true
    SetModelAsNoLongerNeeded(model)
  end

function DestroyBins()
    DeleteEntity(PlayerProps)
    PlayerHasProp = false
  end

function table.contains(table, element)
    for _, value in pairs(table) do
      if value == element then
        return true
      end
    end
    return false
  end

RegisterCommand("getpos", function(source, args, raw)
    local ped = GetPlayerPed(PlayerId())
    local coords = GetEntityCoords(ped, false)
    local heading = GetEntityHeading(ped)
    Citizen.Trace(tostring("X: " .. coords.x .. " Y: " .. coords.y .. " Z: " .. coords.z .. " HEADING: " .. heading))
end, false)