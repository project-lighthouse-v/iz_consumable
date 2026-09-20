local config = require 'config'

local function getItemConfig(itemName)
    return config.items[itemName]
end

local function getInventoryItem(source, itemName, slot)
    local item = exports.ox_inventory:GetSlot(source, slot)

    if not item or item.name ~= itemName then
        return nil
    end

    return item
end

local function getConfiguredItemName(source, slot)
    local item = exports.ox_inventory:GetSlot(source, slot)
    return item and item.name, item
end

-- ox_inventory status values use 200000 for 100 Qbox status points.
local OX_STATUS_PER_QBX_POINT = 2000

local function restoreStatus(source, status, consumeFraction)
    for name, oxAmount in pairs(status or {}) do
        if type(oxAmount) == 'number' and oxAmount ~= 0 then
            local oxRestoreAmount = oxAmount * consumeFraction
            local qbxRestoreAmount = oxRestoreAmount / OX_STATUS_PER_QBX_POINT

            if name == 'hunger' then
                --print(('[iz_consumable] restoring hunger: player=%s ox=%.2f fraction=%.2f oxRestore=%.2f qbxRestore=%.2f'):format(source, oxAmount, consumeFraction, oxRestoreAmount, qbxRestoreAmount))
                exports.qbx_smallresources:AddHunger(source, qbxRestoreAmount)
            elseif name == 'thirst' then
                --print(('[iz_consumable] restoring thirst: player=%s ox=%.2f fraction=%.2f oxRestore=%.2f qbxRestore=%.2f'):format(source, oxAmount, consumeFraction, oxRestoreAmount, qbxRestoreAmount))
                exports.qbx_smallresources:AddThirst(source, qbxRestoreAmount)
            end
        end
    end
end

local function getDurabilityFraction(metadata)
    local durability = metadata and metadata.durability

    if type(durability) ~= 'number' then
        return 1.0
    end

    if durability > 100 then
        local degrade = metadata.degrade

        if type(degrade) == 'number' and degrade > 0 then
            return math.min(1.0, math.max(0.0, (durability - os.time()) / (degrade * 60)))
        end
    end

    return math.min(1.0, math.max(0.0, durability / 100))
end

exports.ox_inventory:registerHook('usingItem', function(payload)
    local itemName = type(payload.item) == 'table' and payload.item.name or payload.item or payload.itemName
    local itemConfig = itemName and getItemConfig(itemName)

    TriggerClientEvent('iz_consumable:client:stop', payload.source)
end)

AddEventHandler('ox_inventory:usedItem', function(inventoryId, itemName, slot, metadata)
    local itemConfig = itemName and getItemConfig(itemName)

    if itemConfig then
        restoreStatus(inventoryId, itemConfig.status, getDurabilityFraction(metadata))
    end
end)

RegisterNetEvent('iz_consumable:server:start', function(slot)
    local playerId = source --[[@as number]]
    local itemName, item = getConfiguredItemName(playerId, slot)
    local itemConfig = itemName and getItemConfig(itemName)

    if not itemConfig or not itemConfig.slow then
        return
    end

    if not item then
        TriggerClientEvent('iz_consumable:client:rejected', playerId)
        return
    end

    local durability = item.metadata.durability or 0

    if durability <= 0 then
        exports.ox_inventory:RemoveItem(playerId, itemName, 1, nil, slot)
        TriggerClientEvent('iz_consumable:client:rejected', playerId)
        return
    end

    TriggerClientEvent(
        'iz_consumable:client:started',
        playerId,
        itemName,
        slot
    )
end)

lib.callback.register('iz_consumable:server:consume', function(source, slot)
    local playerId = source --[[@as number]]
    local itemName, item = getConfiguredItemName(playerId, slot)
    local itemConfig = getItemConfig(itemName)

    if not itemConfig or not itemConfig.slow or not item then
        return false
    end

    local durability = item.metadata.durability or 0

    if durability <= 0 then
        exports.ox_inventory:RemoveItem(playerId, itemName, 1, nil, slot)
        return {
            finished = true
        }
    end

    local durabilityBefore = durability
    local consumeFraction = math.min(1, math.max(0, itemConfig.slow.consumePercent or 0))
    local durabilityConsumed = math.min(durabilityBefore, consumeFraction * 100)

    durability -= durabilityConsumed

    restoreStatus(playerId, itemConfig.status, durabilityConsumed / 100)

    if durability <= 0 then
        exports.ox_inventory:RemoveItem(playerId, itemName, 1, nil, slot)

        return {
            finished = true
        }
    end

    local metadata = table.clone(item.metadata)
    metadata.durability = durability

    exports.ox_inventory:SetMetadata(playerId, slot, metadata)

    return {
        finished = false,
        durability = durability,
        consumePercent = durabilityConsumed / 100
    }
end)