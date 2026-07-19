--[[
    Standalone clothing store
    - No SQL / framework
    - Outfits saved with resource KVP
    - Native notify + futuristic NUI
]]

local menuOpen = false
local cam = nil
local camAngle = 180.0
local camPitch = 0.0
local camDist = 1.8
local originalOutfit = nil
local currentOutfit = nil
local currentShopType = 'clothing' -- 'clothing' | 'barber'
local stripToggle = {} -- [actionKey] = saved pieces (toggle off/on)

local CAM_ANGLE_STEP = 8.0
local CAM_PITCH_STEP = 4.0
local CAM_DIST_STEP = 0.12
local CAM_DIST_MIN = 0.9
local CAM_DIST_MAX = 3.2
local CAM_PITCH_MIN = -25.0
local CAM_PITCH_MAX = 35.0

local function notify(msg, ntype, length)
    local ok = pcall(function()
        exports['thommie-notify']:notify(tostring(msg or ''), ntype or 'outfit', length or 3500)
    end)
    if not ok then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(tostring(msg or ''))
        EndTextCommandThefeedPostTicker(false, true)
    end
end

local function isBarber()
    return currentShopType == 'barber'
end

local function resetCamState()
    if isBarber() then
        camAngle = 180.0
        camPitch = 8.0
        camDist = 0.9
    else
        camAngle = 180.0
        camPitch = 0.0
        camDist = 1.8
    end
end

local function destroyCam()
    if cam and DoesCamExist(cam) then
        RenderScriptCams(false, true, 400, true, true)
        DestroyCam(cam, false)
        cam = nil
    end
end

local function updateCam()
    if not cam or not DoesCamExist(cam) then
        return
    end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local rad = math.rad(heading + camAngle)
    local pitchRad = math.rad(camPitch)
    local dist = camDist
    local offsetX = math.sin(rad) * dist * math.cos(pitchRad)
    local offsetY = -math.cos(rad) * dist * math.cos(pitchRad)
    local lookZ = isBarber() and 0.68 or 0.45
    local baseZ = isBarber() and 0.62 or 0.55
    local offsetZ = baseZ + math.sin(pitchRad) * dist
    local camPos = vector3(coords.x + offsetX, coords.y + offsetY, coords.z + offsetZ)
    SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(cam, coords.x, coords.y, coords.z + lookZ)
end

local function createCam()
    destroyCam()
    resetCamState()
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, isBarber() and 36.0 or 42.0)
    updateCam()
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 450, true, true)
end

local function getHairColorCount()
    local n = GetNumHairColors()
    if not n or n < 1 then
        return Config.MaxHairColors or 64
    end
    return n
end

local function resolveModelHash(model)
    if model == nil then
        return nil
    end
    if type(model) == 'string' then
        return joaat(model)
    end
    if type(model) == 'number' then
        return model
    end
    -- JSON may decode large hashes poorly; try string coerce
    local n = tonumber(model)
    return n
end

local function modelHashToName(hash)
    hash = resolveModelHash(hash)
    if not hash then
        return nil
    end
    if Config.Peds then
        for i = 1, #Config.Peds do
            local entry = Config.Peds[i]
            if joaat(entry.model) == hash then
                return entry.model
            end
        end
    end
    return nil
end

local function setPlayerPedModel(model)
    local hash = resolveModelHash(model)
    if not hash or not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return false
    end

    if GetEntityModel(PlayerPedId()) == hash then
        return true
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end
    if not HasModelLoaded(hash) then
        return false
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    local armour = GetPedArmour(ped)

    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)

    ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, heading)
    SetEntityMaxHealth(ped, maxHealth)
    SetEntityHealth(ped, health)
    SetPedArmour(ped, armour)

    if menuOpen then
        FreezeEntityPosition(ped, true)
        ClearPedTasksImmediately(ped)
        updateCam()
    end

    return true
end

local function snapshotOutfit(ped)
    ped = ped or PlayerPedId()
    local primary, highlight = GetPedHairColor(ped)
    local modelHash = GetEntityModel(ped)
    local data = {
        model = modelHash,
        modelName = modelHashToName(modelHash),
        components = {},
        props = {},
        hairColor = {
            primary = primary or 0,
            highlight = highlight or 0,
        },
    }

    for i = 0, 11 do
        data.components[tostring(i)] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i),
            palette = GetPedPaletteVariation(ped, i),
        }
    end

    for _, prop in ipairs({ 0, 1, 2, 6, 7 }) do
        local drawable = GetPedPropIndex(ped, prop)
        data.props[tostring(prop)] = {
            drawable = drawable,
            texture = drawable >= 0 and GetPedPropTextureIndex(ped, prop) or 0,
        }
    end

    return data
end

-- applyOutfit: clothing/props/hair on current ped.
-- allowModelChange: also swap ped model first (outfits / restore / cancel).
local function applyOutfit(data, allowModelChange)
    if not data then
        return false
    end

    local targetModel = data.modelName or data.model
    if allowModelChange and targetModel then
        local ok = setPlayerPedModel(targetModel)
        if not ok then
            return false
        end
    else
        local want = resolveModelHash(targetModel)
        if want and want ~= GetEntityModel(PlayerPedId()) then
            return false
        end
    end

    local ped = PlayerPedId()

    if data.components then
        for i = 0, 11 do
            local c = data.components[tostring(i)] or data.components[i]
            if c then
                SetPedComponentVariation(ped, i, c.drawable or 0, c.texture or 0, c.palette or 0)
            end
        end
    end

    if data.props then
        for _, prop in ipairs({ 0, 1, 2, 6, 7 }) do
            local p = data.props[tostring(prop)] or data.props[prop]
            if p then
                if (p.drawable or -1) < 0 then
                    ClearPedProp(ped, prop)
                else
                    SetPedPropIndex(ped, prop, p.drawable, p.texture or 0, true)
                end
            end
        end
    end

    if data.hairColor then
        SetPedHairColor(ped, data.hairColor.primary or 0, data.hairColor.highlight or 0)
    end

    return true
end

local function loadSavedOutfits()
    local raw = GetResourceKvpString(Config.KvpKey)
    if not raw or raw == '' then
        return {}
    end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then
        return data
    end
    return {}
end

local function saveSavedOutfits(list)
    SetResourceKvp(Config.KvpKey, json.encode(list))
end

local function saveLastOutfit(data)
    SetResourceKvp(Config.KvpLastKey, json.encode(data))
    -- Persist to BSRP DB (bsrp_players.skin) so character creator / reconnect use same data
    if data and GetResourceState('bsrp') == 'started' then
        -- Ensure clothing-compatible keys
        data.modelName = data.modelName or data.model
        data.model = data.model or data.modelName
        TriggerServerEvent('bsrp:server:saveSkin', data)
    elseif data and GetResourceState('bsrp-characters') == 'started' then
        data.modelName = data.modelName or data.model
        data.model = data.model or data.modelName
        TriggerServerEvent('bsrp-characters:server:saveSkin', data)
    end
end

local function loadLastOutfit()
    local raw = GetResourceKvpString(Config.KvpLastKey)
    if not raw or raw == '' then
        return nil
    end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then
        return data
    end
    return nil
end

local function buildPedList()
    local list = {}
    if not Config.Peds then
        return list
    end
    for i = 1, #Config.Peds do
        local p = Config.Peds[i]
        list[#list + 1] = {
            model = p.model,
            label = p.label or p.model,
            group = p.group or 'Other',
            hash = joaat(p.model),
        }
    end
    return list
end

local function buildCategories()
    local categories = {}
    local components = Config.Components
    local props = Config.Props

    if isBarber() then
        components = Config.BarberComponents or {
            { id = 2, key = 'hair', label = 'Hair Style', icon = 'âœ‚' },
        }
        props = Config.BarberProps or {
            { id = 0, key = 'hat', label = 'Hat / Helmet', icon = 'â–²' },
            { id = 1, key = 'glasses', label = 'Glasses', icon = 'â—‰' },
        }
    elseif Config.AllowPedChange ~= false then
        categories[#categories + 1] = {
            key = 'ped',
            label = 'Change Ped',
            icon = 'â™Ÿ',
            kind = 'ped',
        }
    end

    if not isBarber() then
        categories[#categories + 1] = {
            key = 'emotes',
            label = 'Emotes',
            icon = 'ðŸ™Œ',
            kind = 'emotes',
        }
        categories[#categories + 1] = {
            key = 'strip',
            label = 'Take Off',
            icon = 'ðŸ‘•',
            kind = 'strip',
        }
    end

    for _, c in ipairs(components) do
        categories[#categories + 1] = {
            key = c.key,
            label = c.label,
            icon = c.icon,
            kind = 'component',
            componentId = c.id,
        }
    end

    -- Hair color after hair style (available at both shops when enabled)
    if Config.HairColor ~= false then
        local insertAt = #categories + 1
        for i = 1, #categories do
            if categories[i].key == 'hair' then
                insertAt = i + 1
                break
            end
        end
        table.insert(categories, insertAt, {
            key = 'hair_color',
            label = 'Hair Color',
            icon = 'â—',
            kind = 'hair_color',
        })
    end

    for _, p in ipairs(props) do
        categories[#categories + 1] = {
            key = p.key,
            label = p.label,
            icon = p.icon,
            kind = 'prop',
            propId = p.id,
        }
    end

    categories[#categories + 1] = {
        key = 'saved',
        label = isBarber() and 'Saved Styles' or 'Saved Outfits',
        icon = 'â˜…',
        kind = 'saved',
    }

    return categories
end

local function getComponentState(ped, componentId)
    local drawable = GetPedDrawableVariation(ped, componentId)
    local texture = GetPedTextureVariation(ped, componentId)
    local maxDrawable = GetNumberOfPedDrawableVariations(ped, componentId)
    local maxTexture = GetNumberOfPedTextureVariations(ped, componentId, drawable)
    return {
        drawable = drawable,
        texture = texture,
        maxDrawable = math.max(maxDrawable, 1),
        maxTexture = math.max(maxTexture, 1),
    }
end

local function getPropState(ped, propId)
    local drawable = GetPedPropIndex(ped, propId)
    local texture = drawable >= 0 and GetPedPropTextureIndex(ped, propId) or 0
    local maxDrawable = GetNumberOfPedPropDrawableVariations(ped, propId)
    local maxTexture = 1
    if drawable >= 0 then
        maxTexture = math.max(GetNumberOfPedPropTextureVariations(ped, propId, drawable), 1)
    end
    return {
        drawable = drawable, -- -1 = none
        texture = texture,
        maxDrawable = math.max(maxDrawable, 0),
        maxTexture = maxTexture,
        none = true, -- allow clearing prop
    }
end

local function getHairColorState(ped)
    local primary, highlight = GetPedHairColor(ped)
    return {
        primary = primary or 0,
        highlight = highlight or 0,
        maxColor = getHairColorCount(),
    }
end

local function collectMenuData()
    local ped = PlayerPedId()
    local cats = buildCategories()
    local slots = {}

    for _, cat in ipairs(cats) do
        if cat.kind == 'component' then
            slots[cat.key] = getComponentState(ped, cat.componentId)
        elseif cat.kind == 'prop' then
            slots[cat.key] = getPropState(ped, cat.propId)
        elseif cat.kind == 'hair_color' then
            slots[cat.key] = getHairColorState(ped)
        end
    end

    local outfits = loadSavedOutfits()
    local outfitList = {}
    for i = 1, #outfits do
        outfitList[#outfitList + 1] = {
            id = i,
            name = outfits[i].name or ('Outfit ' .. i),
        }
    end

    local modelHash = GetEntityModel(ped)
    return {
        shopName = isBarber() and (Config.BarberShopName or 'BARBER // STYLE') or Config.ShopName,
        subtitle = isBarber() and (Config.BarberSubtitle or 'CUTS // COLOR // FREE') or Config.Subtitle,
        shopType = currentShopType,
        categories = cats,
        slots = slots,
        outfits = outfitList,
        maxOutfits = Config.MaxOutfits,
        peds = (not isBarber() and Config.AllowPedChange ~= false) and buildPedList() or {},
        currentPed = modelHashToName(modelHash) or tostring(modelHash),
        currentPedHash = modelHash,
        stripActions = (not isBarber() and Config.ShowStripBar ~= false) and (Config.StripActions or {}) or {},
        emotes = (not isBarber()) and (Config.Emotes or {}) or {},
        showStripBar = (not isBarber() and Config.ShowStripBar ~= false),
        stripActive = (function()
            local out = {}
            for k, v in pairs(stripToggle) do
                if v then out[k] = true end
            end
            return out
        end)(),
    }
end

local function isFemalePed(ped)
    local model = GetEntityModel(ped)
    return model == `mp_f_freemode_01`
end

local function isFreemodePed(ped)
    local model = GetEntityModel(ped)
    return model == `mp_m_freemode_01` or model == `mp_f_freemode_01`
end

local function getStripSet(ped)
    local d = Config.StripDrawables or {}
    if isFemalePed(ped) then
        return d.female or d.male or {}
    end
    return d.male or {}
end

local function savePropState(ped, propId)
    local drawable = GetPedPropIndex(ped, propId)
    return {
        kind = 'prop',
        propId = propId,
        drawable = drawable,
        texture = drawable >= 0 and GetPedPropTextureIndex(ped, propId) or 0,
    }
end

local function saveCompState(ped, componentId)
    return {
        kind = 'comp',
        componentId = componentId,
        drawable = GetPedDrawableVariation(ped, componentId),
        texture = GetPedTextureVariation(ped, componentId),
        palette = GetPedPaletteVariation(ped, componentId),
    }
end

local function restoreSaved(ped, savedList)
    if not savedList then
        return
    end
    for i = 1, #savedList do
        local s = savedList[i]
        if s.kind == 'prop' then
            if (s.drawable or -1) < 0 then
                ClearPedProp(ped, s.propId)
            else
                SetPedPropIndex(ped, s.propId, s.drawable, s.texture or 0, true)
            end
        elseif s.kind == 'comp' then
            SetPedComponentVariation(ped, s.componentId, s.drawable or 0, s.texture or 0, s.palette or 0)
        end
    end
end

-- Toggle: first press remove, second press put back on
local function applyStripAction(actionKey)
    local ped = PlayerPedId()
    local set = getStripSet(ped)
    local freemode = isFreemodePed(ped)

    -- Already stripped â†’ restore
    if stripToggle[actionKey] then
        restoreSaved(ped, stripToggle[actionKey])
        stripToggle[actionKey] = nil
        local labels = {
            hat = 'Hat put back on.',
            glasses = 'Glasses put back on.',
            ears = 'Ear piece put back on.',
            mask = 'Mask put back on.',
            shirt = 'Shirt / jacket put back on.',
            shoes = 'Shoes put back on.',
            pants = 'Pants put back on.',
            bag = 'Bag put back on.',
        }
        return true, labels[actionKey] or 'Clothing restored.', false
    end

    -- Save then strip
    local saved = {}

    if actionKey == 'hat' then
        saved[1] = savePropState(ped, 0)
        ClearPedProp(ped, 0)
        stripToggle[actionKey] = saved
        return true, 'Hat removed. Press again to put back on.', true
    end
    if actionKey == 'glasses' then
        saved[1] = savePropState(ped, 1)
        ClearPedProp(ped, 1)
        stripToggle[actionKey] = saved
        return true, 'Glasses removed. Press again to put back on.', true
    end
    if actionKey == 'ears' then
        saved[1] = savePropState(ped, 2)
        ClearPedProp(ped, 2)
        stripToggle[actionKey] = saved
        return true, 'Ear piece removed. Press again to put back on.', true
    end
    if actionKey == 'mask' then
        saved[1] = saveCompState(ped, 1)
        SetPedComponentVariation(ped, 1, freemode and (set.mask or 0) or 0, 0, 0)
        stripToggle[actionKey] = saved
        return true, 'Mask removed. Press again to put back on.', true
    end
    if actionKey == 'shirt' then
        for _, id in ipairs({ 11, 8, 3, 10, 9, 7 }) do
            saved[#saved + 1] = saveCompState(ped, id)
        end
        if freemode then
            SetPedComponentVariation(ped, 11, set.top or 15, 0, 0)
            SetPedComponentVariation(ped, 8, set.undershirt or 15, 0, 0)
            SetPedComponentVariation(ped, 3, set.torso or 15, 0, 0)
            SetPedComponentVariation(ped, 10, set.decal or 0, 0, 0)
            SetPedComponentVariation(ped, 9, set.armor or 0, 0, 0)
            SetPedComponentVariation(ped, 7, set.accessory or 0, 0, 0)
        else
            SetPedComponentVariation(ped, 11, 0, 0, 0)
            SetPedComponentVariation(ped, 8, 0, 0, 0)
        end
        stripToggle[actionKey] = saved
        return true, 'Shirt / jacket removed. Press again to put back on.', true
    end
    if actionKey == 'shoes' then
        saved[1] = saveCompState(ped, 6)
        SetPedComponentVariation(ped, 6, freemode and (set.shoes or 34) or 0, 0, 0)
        stripToggle[actionKey] = saved
        return true, 'Shoes removed. Press again to put back on.', true
    end
    if actionKey == 'pants' then
        saved[1] = saveCompState(ped, 4)
        SetPedComponentVariation(ped, 4, freemode and (set.pants or 21) or 0, 0, 0)
        stripToggle[actionKey] = saved
        return true, 'Pants removed. Press again to put back on.', true
    end
    if actionKey == 'bag' then
        saved[1] = saveCompState(ped, 5)
        SetPedComponentVariation(ped, 5, freemode and (set.bag or 0) or 0, 0, 0)
        stripToggle[actionKey] = saved
        return true, 'Bag removed. Press again to put back on.', true
    end

    return false, 'Unknown strip action.', false
end

local function playClothingEmote(emoteKey)
    local ped = PlayerPedId()
    for _, e in ipairs(Config.Emotes or {}) do
        if e.key == emoteKey then
            if e.cancel then
                ClearPedTasks(ped)
                return true, 'Emote stopped.'
            end
            if not e.dict or not e.anim then
                return false, 'Invalid emote.'
            end
            RequestAnimDict(e.dict)
            local t = GetGameTimer() + 2500
            while not HasAnimDictLoaded(e.dict) and GetGameTimer() < t do
                Wait(0)
            end
            if not HasAnimDictLoaded(e.dict) then
                return false, 'Failed to load emote.'
            end
            TaskPlayAnim(ped, e.dict, e.anim, 8.0, -8.0, -1, e.flag or 49, 0.0, false, false, false)
            return true, e.label or 'Emote playing.'
        end
    end
    return false, 'Emote not found.'
end

local function freezePed(state)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, state)
    if state then
        ClearPedTasksImmediately(ped)
    end
end

local function openMenu(shopType)
    if menuOpen then
        return
    end

    stripToggle = {} -- reset toggles each open (saved look still on ped)
    currentShopType = shopType or 'clothing'

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        notify(isBarber() and 'Exit your vehicle to use the barber.' or 'Exit your vehicle to use the clothing store.', 'error')
        return
    end

    originalOutfit = snapshotOutfit()
    currentOutfit = snapshotOutfit()
    menuOpen = true
    freezePed(true)
    createCam()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = collectMenuData(),
    })
    if isBarber() then
        notify('Welcome â€” cuts & color are free. Save styles you like.', 'outfit')
    else
        notify('Welcome â€” style is free. Save looks to your wardrobe.', 'outfit')
    end
end

local function closeMenu(revert)
    if not menuOpen then
        return
    end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    destroyCam()
    freezePed(false)

    if revert and originalOutfit then
        applyOutfit(originalOutfit, true)
        notify('Changes discarded.', 'error', 2500)
    end

    originalOutfit = nil
    currentOutfit = nil
    currentShopType = 'clothing'
end

local function nearestShop(shopFilter)
    local coords = GetEntityCoords(PlayerPedId())
    local best, bestDist = nil, Config.InteractDistance
    for i = 1, #Config.Locations do
        local loc = Config.Locations[i]
        local shop = loc.shop or 'clothing'
        if (not shopFilter or shop == shopFilter) then
            local dist = #(coords - loc.coords)
            if dist < bestDist then
                bestDist = dist
                best = loc
            end
        end
    end
    return best
end

-- NUI callbacks
RegisterNUICallback('close', function(data, cb)
    local keep = data and data.keep
    if keep then
        local look = snapshotOutfit()
        saveLastOutfit(look)
        currentOutfit = look
        closeMenu(false)
        notify('Look applied and saved to wardrobe cache.', 'outfit')
    else
        closeMenu(true)
    end
    cb({ ok = true })
end)

RegisterNUICallback('strip', function(data, cb)
    local key = data and data.key
    if type(key) ~= 'string' then
        cb({ ok = false })
        return
    end
    local ok, msg, stripped = applyStripAction(key)
    if ok then
        notify(msg or 'OK', 'outfit', 2200)
        local payload = collectMenuData()
        cb({ ok = true, data = payload, stripped = stripped == true, key = key })
    else
        notify(msg or 'Failed.', 'error', 2000)
        cb({ ok = false })
    end
end)

RegisterNUICallback('emote', function(data, cb)
    local key = data and data.key
    if type(key) ~= 'string' then
        cb({ ok = false })
        return
    end
    local ok, msg = playClothingEmote(key)
    if ok then
        notify(msg or 'OK', 'outfit', 2000)
        cb({ ok = true })
    else
        notify(msg or 'Failed.', 'error', 2000)
        cb({ ok = false })
    end
end)

RegisterNUICallback('setPed', function(data, cb)
    if isBarber() or Config.AllowPedChange == false then
        cb({ ok = false })
        return
    end

    local model = data and data.model
    if type(model) ~= 'string' or model == '' then
        cb({ ok = false })
        return
    end

    -- Only allow models listed in config
    local allowed = false
    if Config.Peds then
        for i = 1, #Config.Peds do
            if Config.Peds[i].model == model then
                allowed = true
                break
            end
        end
    end
    if not allowed then
        notify('That ped is not available.', 'error')
        cb({ ok = false })
        return
    end

    local ok = setPlayerPedModel(model)
    if not ok then
        notify('Failed to load ped model.', 'error')
        cb({ ok = false })
        return
    end

    notify(('Ped set to %s.'):format(model), 'outfit', 2500)
    cb({ ok = true, data = collectMenuData() })
end)

RegisterNUICallback('preview', function(data, cb)
    local ped = PlayerPedId()
    if not data or not data.kind then
        cb({ ok = false })
        return
    end

    if data.kind == 'component' then
        local comp = tonumber(data.componentId)
        local drawable = tonumber(data.drawable) or 0
        local texture = tonumber(data.texture) or 0
        if not comp then
            cb({ ok = false })
            return
        end
        local maxD = GetNumberOfPedDrawableVariations(ped, comp)
        drawable = math.max(0, math.min(drawable, math.max(maxD - 1, 0)))
        local maxT = GetNumberOfPedTextureVariations(ped, comp, drawable)
        texture = math.max(0, math.min(texture, math.max(maxT - 1, 0)))
        SetPedComponentVariation(ped, comp, drawable, texture, 0)
        cb({
            ok = true,
            state = getComponentState(ped, comp),
        })
        return
    end

    if data.kind == 'hair_color' then
        local max = getHairColorCount()
        local primary = tonumber(data.primary) or 0
        local highlight = tonumber(data.highlight) or 0
        primary = math.max(0, math.min(primary, math.max(max - 1, 0)))
        highlight = math.max(0, math.min(highlight, math.max(max - 1, 0)))
        SetPedHairColor(ped, primary, highlight)
        cb({
            ok = true,
            state = getHairColorState(ped),
        })
        return
    end

    if data.kind == 'prop' then
        local prop = tonumber(data.propId)
        local drawable = tonumber(data.drawable)
        local texture = tonumber(data.texture) or 0
        if prop == nil then
            cb({ ok = false })
            return
        end
        if drawable == nil or drawable < 0 then
            ClearPedProp(ped, prop)
        else
            local maxD = GetNumberOfPedPropDrawableVariations(ped, prop)
            drawable = math.max(0, math.min(drawable, math.max(maxD - 1, 0)))
            local maxT = GetNumberOfPedPropTextureVariations(ped, prop, drawable)
            texture = math.max(0, math.min(texture, math.max(maxT - 1, 0)))
            SetPedPropIndex(ped, prop, drawable, texture, true)
        end
        cb({
            ok = true,
            state = getPropState(ped, prop),
        })
        return
    end

    cb({ ok = false })
end)

RegisterNUICallback('camera', function(data, cb)
    local action = data and data.action
    if action == 'left' then
        camAngle = (camAngle - CAM_ANGLE_STEP) % 360.0
    elseif action == 'right' then
        camAngle = (camAngle + CAM_ANGLE_STEP) % 360.0
    elseif action == 'up' then
        camPitch = math.min(CAM_PITCH_MAX, camPitch + CAM_PITCH_STEP)
    elseif action == 'down' then
        camPitch = math.max(CAM_PITCH_MIN, camPitch - CAM_PITCH_STEP)
    elseif action == 'zoom_in' then
        camDist = math.max(CAM_DIST_MIN, camDist - CAM_DIST_STEP)
    elseif action == 'zoom_out' then
        camDist = math.min(CAM_DIST_MAX, camDist + CAM_DIST_STEP)
    elseif action == 'reset' then
        resetCamState()
    end
    updateCam()
    cb({ ok = true })
end)

RegisterNUICallback('rotatePed', function(data, cb)
    local ped = PlayerPedId()
    local dir = data and data.dir == 'left' and -12.0 or 12.0
    SetEntityHeading(ped, GetEntityHeading(ped) + dir)
    updateCam()
    cb({ ok = true })
end)

RegisterNUICallback('saveOutfit', function(data, cb)
    local name = data and data.name
    if type(name) ~= 'string' then
        name = ''
    end
    name = name:gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then
        name = 'Outfit ' .. tostring(#loadSavedOutfits() + 1)
    end
    if #name > 32 then
        name = name:sub(1, 32)
    end

    local list = loadSavedOutfits()
    if #list >= Config.MaxOutfits then
        notify(('Wardrobe full (%d max). Delete one first.'):format(Config.MaxOutfits), 'error')
        cb({ ok = false, full = true })
        return
    end

    local look = snapshotOutfit()
    list[#list + 1] = {
        name = name,
        model = look.model,
        modelName = look.modelName,
        components = look.components,
        props = look.props,
        hairColor = look.hairColor,
    }
    saveSavedOutfits(list)
    saveLastOutfit(look)
    notify(('Saved "%s" to wardrobe.'):format(name), 'outfit')

    local outfitList = {}
    for i = 1, #list do
        outfitList[#outfitList + 1] = { id = i, name = list[i].name }
    end
    cb({ ok = true, outfits = outfitList })
end)

RegisterNUICallback('loadOutfit', function(data, cb)
    local id = tonumber(data and data.id)
    local list = loadSavedOutfits()
    if not id or not list[id] then
        notify('Outfit not found.', 'error')
        cb({ ok = false })
        return
    end

    local ok = applyOutfit(list[id], true)
    if not ok then
        notify('Could not load that outfit / ped.', 'error')
        cb({ ok = false })
        return
    end

    -- Refresh stored model fields after apply
    local look = snapshotOutfit()
    list[id].model = look.model
    list[id].modelName = look.modelName
    saveLastOutfit(look)
    notify(('Loaded "%s".'):format(list[id].name or 'Outfit'), 'outfit')
    cb({ ok = true, data = collectMenuData() })
end)

RegisterNUICallback('deleteOutfit', function(data, cb)
    local id = tonumber(data and data.id)
    local list = loadSavedOutfits()
    if not id or not list[id] then
        cb({ ok = false })
        return
    end
    local name = list[id].name or 'Outfit'
    table.remove(list, id)
    saveSavedOutfits(list)
    notify(('Deleted "%s".'):format(name), 'outfit')

    local outfitList = {}
    for i = 1, #list do
        outfitList[#outfitList + 1] = { id = i, name = list[i].name }
    end
    cb({ ok = true, outfits = outfitList })
end)

RegisterNUICallback('resetOriginal', function(_, cb)
    if originalOutfit then
        applyOutfit(originalOutfit, true)
        notify('Restored your original look.', 'outfit', 2500)
        cb({ ok = true, data = collectMenuData() })
        return
    end
    cb({ ok = false })
end)

local function createShopBlip(loc, blipCfg)
    if not blipCfg or not blipCfg.enabled then
        return
    end
    local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
    SetBlipSprite(blip, blipCfg.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, blipCfg.scale)
    SetBlipColour(blip, blipCfg.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blipCfg.label)
    EndTextCommandSetBlipName(blip)
end

-- Markers / blips / interaction
CreateThread(function()
    for i = 1, #Config.Locations do
        local loc = Config.Locations[i]
        local shop = loc.shop or 'clothing'
        if shop == 'barber' then
            createShopBlip(loc, Config.BarberBlip)
        else
            createShopBlip(loc, Config.Blip)
        end
    end
end)

local zoneHintShown = false
local zoneHintShop = nil

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local near = false
        local nearShopType = nil

        if not menuOpen then
            for i = 1, #Config.Locations do
                local loc = Config.Locations[i]
                local shop = loc.shop or 'clothing'
                local dist = #(coords - loc.coords)

                if dist < Config.MarkerDistance then
                    sleep = 0
                    if Config.DrawMarker then
                        local m = (shop == 'barber' and Config.BarberMarker) or Config.Marker
                        DrawMarker(
                            m.type,
                            loc.coords.x, loc.coords.y, loc.coords.z + 0.02,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            m.scale.x, m.scale.y, m.scale.z,
                            m.color.r, m.color.g, m.color.b, m.color.a,
                            m.bob, m.rotate, 2, false, nil, nil, false
                        )
                    end
                end

                if dist < Config.InteractDistance then
                    near = true
                    nearShopType = shop
                    sleep = 0
                    if not zoneHintShown or zoneHintShop ~= shop then
                        zoneHintShown = true
                        zoneHintShop = shop
                        if shop == 'barber' then
                            notify('Barber shop â€” press E to style hair (FREE).', 'outfit', 4000)
                        else
                            notify('Clothing store â€” press E to change style (FREE).', 'outfit', 4000)
                        end
                    end
                    if IsControlJustReleased(0, Config.InteractKey) then
                        openMenu(shop)
                    end
                end
            end

            if not near then
                zoneHintShown = false
                zoneHintShop = nil
            end
        else
            sleep = 0
            zoneHintShown = false
            zoneHintShop = nil
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 75, true)
            updateCam()

            if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
                closeMenu(true)
            end
        end

        Wait(sleep)
    end
end)

-- Restore last look after spawn
-- Prefer BSRP DB skin (bsrp_players.skin) so creator + clothing stay in sync
if Config.RestoreOnSpawn then
    CreateThread(function()
        Wait(Config.RestoreDelayMs or 2500)
        local last = nil
        if GetResourceState('bsrp') == 'started' then
            local data = exports.bsrp:GetPlayerData()
            if data and data.skin then
                last = data.skin
            end
        end
        last = last or loadLastOutfit()
        if last then
            applyOutfit(last, true)
        end
    end)

    AddEventHandler('playerSpawned', function()
        CreateThread(function()
            Wait(Config.RestoreDelayMs or 2500)
            local last = loadLastOutfit()
            if last then
                applyOutfit(last, true)
            end
        end)
    end)
end

-- Quick commands (open anywhere for free roam / testing)
RegisterCommand('clothing', function()
    if menuOpen then
        return
    end
    local shop = nearestShop('clothing')
    openMenu(shop and (shop.shop or 'clothing') or 'clothing')
end, false)

RegisterCommand('barber', function()
    if menuOpen then
        return
    end
    local shop = nearestShop('barber')
    openMenu(shop and (shop.shop or 'barber') or 'barber')
end, false)

TriggerEvent('chat:addSuggestion', '/clothing', 'Open the clothing store menu')
TriggerEvent('chat:addSuggestion', '/barber', 'Open the barber shop menu')

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        if menuOpen then
            closeMenu(true)
        end
        destroyCam()
        freezePed(false)
        SetNuiFocus(false, false)
    end
end)
