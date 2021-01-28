ESX  = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

players = {}

RegisterServerEvent("esx_zombiesystem:newplayer")
AddEventHandler("esx_zombiesystem:newplayer", function(id)
    players[source] = id
    TriggerClientEvent("esx_zombiesystem:playerupdate", -1, players)
end)

AddEventHandler("playerDropped", function(reason)
    players[source] = nil
    TriggerClientEvent("esx_zombiesystem:clear", source)
    TriggerClientEvent("esx_zombiesystem:playerupdate", -1, players)
end)

AddEventHandler("onResourceStop", function()
	 TriggerClientEvent("esx_zombiesystem:clear", -1)
end)

RegisterServerEvent('zombies:moneyloot')
AddEventHandler('zombies:moneyloot', function()
    local xPlayer = ESX.GetPlayerFromId(source)
	local random = math.random(15, 100)
    xPlayer.addMoney(random)
    TriggerClientEvent("esx:showNotification", xPlayer.source, ('You found ~g~$' .. random .. ' dolars'))
end)

RegisterServerEvent('zombies:itemloot')
AddEventHandler('zombies:itemloot', function(item)
    local xPlayer = ESX.GetPlayerFromId(source)
	local random = math.random(1, 3)
    if xPlayer.canCarryItem(item, random) then
        xPlayer.addInventoryItem(item, random)
        TriggerClientEvent("esx:showNotification", xPlayer.source, ('You found ~y~' .. random .. 'x ~b~' .. item))
    else
        xPlayer.showNotification('You cannot pickup that because your inventory is full!')
    end
end)