ESX = nil

Citizen.CreateThread(function()

    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

local PlayerGroup, ZombieGroup = "PLAYER", "ZOMBIE"
DecorRegister("RegisterZombie", 2)
DecorRegister("ZombieLoot", 2)

local ZombieGrunt = {"zombie2", "zombie3", "zombie4", "zombie5", "zombie6", "zombie8", "zombie9", "zombie11", "zombie12", "zombie13",
	"zombie14", "zombie16", "zombie17", "zombie18", "zombie19", "zombie20"}

local ZombieGruntAlert = {"zombie1", "zombie7", "zombie10", "zombie15"}

AddRelationshipGroup(ZombieGroup)
SetRelationshipBetweenGroups(0, GetHashKey(ZombieGroup), GetHashKey(PlayerGroup))
SetRelationshipBetweenGroups(5, GetHashKey(PlayerGroup), GetHashKey(ZombieGroup))

Citizen.CreateThread(function()
    Wait(0)
    local PedHandler = -1
    local Success = false
    local Handler, PedHandler = FindFirstPed()

    repeat
        Wait(10)

        if IsPedHuman(PedHandler) and not IsPedAPlayer(PedHandler) and not IsPedDeadOrDying(PedHandler, true) then
            if not DecorExistOn(PedHandler, "RegisterZombie") then
                ClearPedTasks(PedHandler)
                ClearPedSecondaryTask(PedHandler)
                ClearPedTasksImmediately(PedHandler)
                TaskWanderStandard(PedHandler, 10.0, 10)
                SetPedRelationshipGroupHash(PedHandler, ZombieGroup)
                ApplyPedDamagePack(PedHandler, "BigHitByVehicle", 0.0, 1.0)
                SetEntityHealth(PedHandler, Config.ZombieHealth)

                RequestAnimSet("move_m@drunk@verydrunk")
                while not HasAnimSetLoaded("move_m@drunk@verydrunk") do
                    Wait(0)
                end
                SetPedMovementClipset(PedHandler, "move_m@drunk@verydrunk", 1.0)

                SetPedConfigFlag(PedHandler, 100, false)
                DecorSetBool(PedHandler, "RegisterZombie", true)
            end
        
            ZombiePedAttributes(PedHandler)

            local PlayerCoords = GetEntityCoords(PlayerPedId())
            local PedCoords = GetEntityCoords(PedHandler)
            local Distance = Vdist(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, PedCoords.x, PedCoords.y, PedCoords.z)
            local DistanceTarget = Config.DistanceTarget + 60.0

            if Distance <= DistanceTarget then
                if (Config.ZombieCanRun) then TaskGoStraightToCoord(PedHandler, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 2.0, -1, 0.0, 0.0)
                else TaskGoStraightToCoord(PedHandler, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 1.0, -1, 0.0, 0.0) end
            end

            if Distance <= Config.DistanceTarget then
                if not GetPedConfigFlag(PedHandler, 100, false) and GetEntityHealth(PlayerPedId()) ~= 0 then
                    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', PedHandler, 20.0, math.random(1, #ZombieGrunt), 0.8)
                    SetPedConfigFlag(PedHandler, 100, true)
                end
            end

            if (Distance <= 1.3) then
                if not IsPedRagdoll(PedHandler) and not IsPedGettingUp(PedHandler) then
                    if (GetEntityHealth(PlayerPedId()) == 0) then
                        ClearPedTasks(PedHandler)
                        TaskWanderStandard(PedHandler, 10.0, 10)
                    else
                        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', PedHandler, 20.0, math.random(1, #ZombieGruntAlert), 0.8)
                        RequestAnimSet("melee@unarmed@streamed_core_fps")
                        while not HasAnimSetLoaded("melee@unarmed@steamed_core_fps") do
                            Wait(10)
                        end

                        TaskPlayAnim(PedHandler, "melee@unarmed@streamed_core_fps", "ground_attack_0_psycho", 8.0, 1.0, -1, 48, 0.001, false, false, false)
                        ApplyDamageToPed(PlayerPedID(), Config.ZombieDamage, false)
                    end
                end
            end

            if not NetworkGetEntityIsNetworked(PedHandler) then
                DeleteEntity(PedHandler)
            end

            if (Config.Debug) then
                DrawMarker(1, PedCoords.x, PedCoords.y, PedCoords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 2.0, 2.0, 2.0, 255, 255, 255, 255, false, true, 2, nil, nil, false)
            end
        end

        Success, PedHandler = FindNextPed(Handler)
    until not (Success)

    EndFindPed(Handler)
end)

if Config.NotHealthRecharge then
	SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
end

if Config.MuteAmbience then
	StartAudioScene('CHARACTER_CHANGE_IN_SKY_SCENE')
end

SetBlackout(Config.Blackout)

if Config.ZombieDropLoot then
    Citizen.CreateThread(function()
        local PedHandler = -1
        local Success = false
        local Handler, PedHandler = FindFirstPed()

        repeat

            if IsPedHuman(PedHandler) and not IsPedAPlayer(PedHandler) and IsPedDeadOrDying(PedHandler, true) then
                local PlayerCoords = GetEntityCoords(PlayerPedId())
                local PedCoords = GetEntityCoords(PedHandler)
                local Distance = Vdist(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, PedCoords.x, PedCoords.y, PedCoords.z)

                if Distance <= 1.2 and not IsPedInAnyVehicle(PlayerPedId(), true) and DecorGetBool(PedHandler, "ZombieLoot") then
                    local Ground, Zpos = GetGroundZFor_3dCoord(PedCoords.x, PedCoords.y, PedCoords.y, false)
                    ESX.Game.Utils.DrawText3D({PedCoords.x, PedCoords.y, PedCoords.z}, '~c~PRESS ~b~[E]~c~ TO SEARCH', 0.8, 4)
                    if (IsControlJustReleased(1, 51)) and not Player.Dead() then
                        ClearPedTasksImmediately(PlayerPedId())
                        RequestAnimDict("amb@medic@standing@kneel@base")
                        while not HasAnimDictLoaded("amb@medic@standing@kneel@base") do
                            Wait(0)
                        end
                        TaskPlayAnim(PlayerPedId(), "amb@medic@standing@kneel@base", "base", 5.0, 10.0, -1, 1, 0, false, false, false)

                        Citizen.Wait(2000)
                        randomChance = math.random(1, 100)
					    randomWeapon = Config.WeaponLoot[math.random(1, #Config.WeaponLoot)]
                        randomItem = Config.ItemLoot[math.random(1, #Config.ItemLoot)]
                    
                        if randomChance > 0 and randomChance < Config.ProbabilityWeaponLoot then
                            local randomAmmo = math.random(1, 30)
                            GiveWeaponToPed(PlayerPedId(), randomWeapon, randomAmmo, true, false)
                            ESX.ShowNotification('You found ' .. randomWeapon)
                        elseif randomChance >= Config.ProbabilityWeaponLoot and randomChance < Config.ProbabilityMoneyLoot then
                            TriggerServerEvent('zombies:moneyloot')
                        elseif randomChance >= Config.ProbabilityMoneyLoot and randomChance < Config.ProbabilityItemLoot then
                            TriggerServerEvent('zombies:itemloot', randomItem)
                        elseif randomChance >= Config.ProbabilityItemLoot and randomChance < 100 then
                            ESX.ShowNotification('You not found nothing')
                        end
                        ClearPedSecondaryTask(GetPlayerPed(-1))
                        local model = GetEntityModel(PedHandler)
                        SetEntityAsNoLongerNeeded(PedHandler)
                        SetModelAsNoLongerNeeded(model)
                    end
                end
            end

            Success, PedHandler = FindNextPed(Handler)
        until not (Success)

        EndFindPed(Handler)
    end)
end

if Config.SafeZoneRadioBlip then
	for k, v in pairs(Config.SafeZoneCoords) do
		blip = AddBlipForRadius(v.x, v.y, v.z, v.radio)
		SetBlipHighDetail(blip, true)
		SetBlipColour(blip, 2)
		SetBlipAlpha (blip, 128)
	end
end

if Config.SafeZone then
    Citizen.CreateThread(function()
        local PedHandler = -1
        local Success = false
        local Handler, PedHandler = FindFirstPed()

        repeat
            Citizen.Wait(1)
            if IsPedHuman(PedHandler) and not IsPedAPlayer(PedHandler) and IsPedDeadOrDying(PedHandler, true) then
                local PedCoords = GetEntityCoords(PedHandler)
                local SafeZone = Vdist(PedCoords.x, PedCoords.y, PedCoords.z, v.x, v.y, v.z)
                if(SafeZone < v.radio) then
                    SetEntityHealth(PlayerHandler, 0)
                    SetEntityAsNoLongerNeeded(PlayerHandler)
                    DeleteEntity(PlayerHandler)
                end
            end

            Success, PedHandler = FindNextPed(Handler)
        until not (Success)

        EndFindPed(Handler)
		
	end)
end

if Config.Debug then
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(1)
			for i, entity in pairs(entitys) do
				local playerX, playerY, playerZ = table.unpack(GetEntityCoords(PlayerPedId(), true))
				local pedX, pedY, pedZ = table.unpack(GetEntityCoords(entity, false))	
				DrawLine(playerX, playerY, playerZ, pedX, pedY, pedZ, 250,0,0,250)
			end
		end
	end)
end

if Config.NoPeds then
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(1)
	    	SetVehicleDensityMultiplierThisFrame(0.0)
			SetPedDensityMultiplierThisFrame(0.0)
			SetRandomVehicleDensityMultiplierThisFrame(0.0)
			SetParkedVehicleDensityMultiplierThisFrame(0.0)
			SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
			local playerPed = GetPlayerPed(-1)
			local pos = GetEntityCoords(playerPed) 
			RemoveVehiclesFromGeneratorsInArea(pos['x'] - 500.0, pos['y'] - 500.0, pos['z'] - 500.0, pos['x'] + 500.0, pos['y'] + 500.0, pos['z'] + 500.0);
			SetGarbageTrucks(0)
			SetRandomBoats(0)
		end
	end)
end


function ZombiePedAttributes(Ped)
    if not Config.ZombieCanRagdollByShots then SetPedRagdollBlockingFlags(Ped, 1) end
    SetPedCanRagdollFromPlayerImpact(Ped, false)
    SetPedSuffersCriticalHits(Ped, Config.ZombieInstantDeathByHeadshot)
    SetPedEnableWeaponBlocking(Ped, true)
    DisablePedPainAudio(Ped, true)
    StopPedSpeaking(Ped, true)
    SetPedDiesWhenInjured(Ped, false)
    StopPedRingtone(Ped)
    SetPedMute(Ped)
    SetPedIsDrunk(Ped, true)
    SetPedConfigFlag(Ped, 166, false)
    SetPedConfigFlag(Ped, 170, false)
    SetBlockingOfNonTemporaryEvents(Ped, true)
    SetPedCanEvasiveDive(Ped, false)
    RemoveAllPedWeapons(Ped, true)
end