ESX = nil
TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)

RegisterNetEvent('bk_garbage:pay')
AddEventHandler('bk_garbage:pay', function(price)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if price then
        if xPlayer ~= nil then
            xPlayer.addMoney(price)
        end
    end
end)