local config = require 'config'

local activeItem
local activeSlot
local activeObject
local consuming = false
local animationMissingSince = 0
local animationMissingTimeout = 1500

local function getItemConfig(itemName)
    return config.items[itemName]
end

local function getPropData(prop)
    if not prop then return end

    return {
        {
            model = prop.model,
            bone = prop.bone,
            pos = { x = prop.pos.x, y = prop.pos.y, z = prop.pos.z },
            rot = { x = prop.rot.x, y = prop.rot.y, z = prop.rot.z }
        }
    }
end

local function loadAnimation(animation)
    lib.requestAnimDict(animation.dict)
end

local function deleteObject()
    if activeObject and DoesEntityExist(activeObject) then
        DetachEntity(activeObject, true, true)
        SetEntityAsMissionEntity(activeObject, true, true)
        DeleteObject(activeObject)
    end

    activeObject = nil
end

local function stopHolding()
    deleteObject()
    lib.hideTextUI()

    activeItem = nil
    activeSlot = nil
    consuming = false
    animationMissingSince = 0

    ClearPedTasks(cache.ped)
end

local function attachObject(itemConfig, attachment)
    local prop = attachment or itemConfig.prop
    local model = joaat(prop.model)

    if not activeObject or not DoesEntityExist(activeObject) then
        lib.requestModel(model)

        activeObject = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
        SetModelAsNoLongerNeeded(model)
    end

    AttachEntityToEntity(
        activeObject,
        cache.ped,
        GetPedBoneIndex(cache.ped, prop.bone),
        prop.pos.x,
        prop.pos.y,
        prop.pos.z,
        prop.rot.x,
        prop.rot.y,
        prop.rot.z,
        true,
        true,
        false,
        true,
        1,
        true
    )
end

local function showControls(itemConfig)
    local slow = itemConfig.slow

    lib.showTextUI(('[E]  %s\n[X]  Put away'):format(slow.useLabel or 'Consume'), {
        position = 'bottom-center',
        style = {
            borderRadius = 0,
            backgroundColor = '#48BB78',
            color = 'white'
        }
    })
end

local function playAnimation(animation)
    loadAnimation(animation)

    TaskPlayAnim(
        cache.ped,
        animation.dict,
        animation.clip,
        2.0,
        2.0,
        -1,
        animation.flag or 49,
        0.0,
        false,
        false,
        false
    )

end

local function startHolding(slot)
    if activeItem then
        stopHolding()
    end

    activeSlot = slot

    TriggerServerEvent('iz_consumable:server:start', slot)
end

local function useNormally(_, data, slotData)
    local itemConfig = getItemConfig(data.name)
    local normal = itemConfig and itemConfig.normal

    if not normal then
        return false
    end

    local progressProp = getPropData(normal.prop)

    local success = lib.progressBar({
        duration = normal.duration,
        label = normal.label,
        useWhileDead = false,
        canCancel = normal.cancel ~= false,
        disable = normal.disable or { combat = true },
        anim = normal.anim,
        prop = progressProp
    })

    if not success then
        return false
    end

    exports.ox_inventory:useItem(data, function(result)
        if result and normal.notification then
            lib.notify({ description = normal.notification })
        end
    end, true)
end
exports('useNormally', useNormally)

local function consumeItem()
    if not activeItem or not activeSlot or consuming then
        return
    end

    local itemConfig = getItemConfig(activeItem)
    local slow = itemConfig and itemConfig.slow

    if not slow then
        stopHolding()
        return
    end

    consuming = true

    local animation = slow.consume
    attachObject(slow, animation.prop)
    loadAnimation(animation)

    TaskPlayAnim(
        cache.ped,
        animation.dict,
        animation.clip,
        2.0,
        2.0,
        animation.duration,
        animation.flag or 49,
        0.0,
        false,
        false,
        false
    )

    Wait(animation.duration)

    local result = lib.callback.await(
        'iz_consumable:server:consume',
        false,
        activeSlot
    )

    consuming = false

    if not result or result.finished then
        if result and slow.consume.notification then
            lib.notify({ description = slow.consume.notification })
        end

        stopHolding()
        return
    end

    attachObject(slow)
    playAnimation(slow.idle)

    if slow.consume.notification then
        lib.notify({ description = slow.consume.notification })
    end
end

local function isActiveAnimationPlaying()
    if not activeItem then return false end

    local itemConfig = getItemConfig(activeItem)
    if not itemConfig then return false end

    local slow = itemConfig.slow
    local idle = slow.idle
    local consume = slow.consume

    local idlePlaying = IsEntityPlayingAnim(
        cache.ped,
        idle.dict,
        idle.clip,
        3
    )

    local consumePlaying = IsEntityPlayingAnim(
        cache.ped,
        consume.dict,
        consume.clip,
        3
    )

    return idlePlaying or consumePlaying
end

RegisterNetEvent('iz_consumable:client:started', function(itemName, slot)
    local itemConfig = getItemConfig(itemName)

    if not itemConfig then
        return
    end

    activeItem = itemName
    activeSlot = slot

    attachObject(itemConfig.slow)
    playAnimation(itemConfig.slow.idle)
    showControls(itemConfig)
end)

RegisterNetEvent('iz_consumable:client:rejected', function()
    stopHolding()
end)

RegisterNetEvent('iz_consumable:client:useSlowly', function(slot)
    startHolding(slot)
end)

RegisterNetEvent('iz_consumable:client:stop', stopHolding)

CreateThread(function()
    while true do
        if not activeItem then
            Wait(500)
        else
            Wait(0)

            DisableControlAction(0, config.consumeControl, true)
            DisableControlAction(0, config.stopControl, true)

            if IsDisabledControlJustReleased(0, config.consumeControl) then
                consumeItem()
            elseif IsDisabledControlJustReleased(0, config.stopControl) then
                stopHolding()
            end

            if IsEntityDead(cache.ped) then
                stopHolding()
            elseif not activeObject or not DoesEntityExist(activeObject) then
                stopHolding()
            elseif consuming then
                animationMissingSince = 0
            elseif isActiveAnimationPlaying() then
                animationMissingSince = 0
            elseif animationMissingSince == 0 then
                animationMissingSince = GetGameTimer()
            elseif GetGameTimer() - animationMissingSince >= animationMissingTimeout then
                stopHolding()
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        stopHolding()
    end
end)