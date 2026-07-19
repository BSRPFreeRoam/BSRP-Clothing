Config = {}

Config.ShopName = 'BINCO // SUBURBAN'
Config.Subtitle = 'WARDROBE // FREE STYLING'
Config.BarberShopName = 'BARBER // STYLE'
Config.BarberSubtitle = 'CUTS // COLOR // FREE'
Config.InteractKey = 38 -- E
Config.InteractDistance = 2.2
Config.MarkerDistance = 22.0
Config.DrawMarker = true

-- Max saved outfits (client KVP — no database)
Config.MaxOutfits = 12
Config.KvpKey = 'bs_clothing_outfits_v1'
Config.KvpLastKey = 'bs_clothing_last_v1'

-- Re-apply last saved look a moment after spawn
Config.RestoreOnSpawn = true
Config.RestoreDelayMs = 2500

-- All vanilla GTA V clothing stores (Binco / Suburban / Ponsonbys / Discount)
-- shop = 'clothing' (default) or 'barber'
Config.Locations = {
    -- Binco
    {
        name = 'Binco — Strawberry',
        coords = vector3(75.950, -1392.891, 29.376),
        heading = 270.0,
        shop = 'clothing',
    },
    {
        name = 'Binco — Sinner Street',
        coords = vector3(425.236, -806.008, 29.491),
        heading = 90.0,
        shop = 'clothing',
    },
    {
        name = 'Binco — Vespucci',
        coords = vector3(-822.194, -1074.134, 11.328),
        heading = 210.0,
        shop = 'clothing',
    },

    -- Suburban
    {
        name = 'Suburban — Del Perro',
        coords = vector3(-1192.945, -772.689, 17.326),
        heading = 125.0,
        shop = 'clothing',
    },
    {
        name = 'Suburban — Hawick',
        coords = vector3(121.76, -224.6, 54.56),
        heading = 340.0,
        shop = 'clothing',
    },
    {
        name = 'Suburban — Chumash',
        coords = vector3(-3171.453, 1043.857, 20.863),
        heading = 335.0,
        shop = 'clothing',
    },
    {
        name = 'Suburban — Route 68',
        coords = vector3(615.180, 2762.933, 42.088),
        heading = 180.0,
        shop = 'clothing',
    },

    -- Ponsonbys
    {
        name = 'Ponsonbys — Rockford Hills',
        coords = vector3(-712.216, -155.353, 37.415),
        heading = 120.0,
        shop = 'clothing',
    },
    {
        name = 'Ponsonbys — Burton',
        coords = vector3(-162.658, -303.397, 39.733),
        heading = 250.0,
        shop = 'clothing',
    },
    {
        name = 'Ponsonbys — Morningwood',
        coords = vector3(-1450.711, -236.83, 49.809),
        heading = 50.0,
        shop = 'clothing',
    },

    -- Discount Store
    {
        name = 'Discount Store — Paleto Bay',
        coords = vector3(4.254, 6512.813, 31.877),
        heading = 45.0,
        shop = 'clothing',
    },
    {
        name = 'Discount Store — Grapeseed',
        coords = vector3(1693.32, 4823.48, 42.06),
        heading = 100.0,
        shop = 'clothing',
    },
    {
        name = 'Discount Store — Grand Senora',
        coords = vector3(1196.785, 2709.558, 38.222),
        heading = 180.0,
        shop = 'clothing',
    },
    {
        name = 'Discount Store — Route 68',
        coords = vector3(-1100.959, 2710.211, 19.107),
        heading = 220.0,
        shop = 'clothing',
    },

    -- Extra clothing shop (Vespucci Canals / beach strip)
    {
        name = 'Clothing — Vespucci Canals',
        coords = vector3(-1207.65, -1456.88, 4.378),
        heading = 35.0,
        shop = 'clothing',
    },

    ----------------------------------------------------------------
    -- Barber shops (vanilla GTA V)
    ----------------------------------------------------------------
    {
        name = 'Herr Kutz — Davis',
        coords = vector3(132.278, -1710.762, 29.292),
        heading = 140.0,
        shop = 'barber',
    },
    {
        name = 'Herr Kutz — Hawick',
        coords = vector3(1212.460, -472.828, 66.208),
        heading = 75.0,
        shop = 'barber',
    },
    {
        name = 'Herr Kutz — Paleto Bay',
        coords = vector3(-278.109, 6228.463, 31.696),
        heading = 50.0,
        shop = 'barber',
    },
    {
        name = 'Beachcombover — Vespucci',
        coords = vector3(-1282.605, -1116.758, 6.990),
        heading = 90.0,
        shop = 'barber',
    },
    {
        name = "O'Sheas — Sandy Shores",
        coords = vector3(1931.513, 3729.671, 32.844),
        heading = 210.0,
        shop = 'barber',
    },
    {
        name = 'Bob Mulét — Rockford Hills',
        coords = vector3(-814.308, -183.796, 37.569),
        heading = 120.0,
        shop = 'barber',
    },
    {
        name = 'Hair on Hawick — Alta',
        coords = vector3(-33.224, -152.516, 57.076),
        heading = 340.0,
        shop = 'barber',
    },
}

Config.Marker = {
    type = 27,
    scale = vector3(1.4, 1.4, 0.6),
    color = { r = 0, g = 229, b = 255, a = 140 },
    bob = false,
    rotate = true,
}

Config.BarberMarker = {
    type = 27,
    scale = vector3(1.4, 1.4, 0.6),
    color = { r = 255, g = 120, b = 40, a = 140 },
    bob = false,
    rotate = true,
}

Config.Blip = {
    enabled = true,
    sprite = 73,
    color = 3,
    scale = 0.75,
    label = 'Clothing Store',
}

Config.BarberBlip = {
    enabled = true,
    sprite = 71, -- scissors
    color = 17, -- orange
    scale = 0.75,
    label = 'Barber Shop',
}

-- Ped clothing slots (GTA component IDs)
Config.Components = {
    { id = 1,  key = 'mask',        label = 'Mask',        icon = '◈' },
    { id = 2,  key = 'hair',        label = 'Hair',        icon = '✂' },
    { id = 3,  key = 'torso',       label = 'Arms / Torso', icon = '◎' },
    { id = 4,  key = 'legs',        label = 'Pants',       icon = '▣' },
    { id = 5,  key = 'bag',         label = 'Bag / Parachute', icon = '◆' },
    { id = 6,  key = 'shoes',       label = 'Shoes',       icon = '◇' },
    { id = 7,  key = 'accessory',   label = 'Accessory',   icon = '✦' },
    { id = 8,  key = 'undershirt',  label = 'Undershirt',  icon = '◇' },
    { id = 9,  key = 'armor',       label = 'Body Armor',  icon = '⬡' },
    { id = 10, key = 'decal',       label = 'Decals',      icon = '✧' },
    { id = 11, key = 'top',         label = 'Tops / Jackets', icon = '▢' },
}

-- Ped prop slots
Config.Props = {
    { id = 0, key = 'hat',      label = 'Hat / Helmet', icon = '▲' },
    { id = 1, key = 'glasses',  label = 'Glasses',     icon = '◉' },
    { id = 2, key = 'ears',     label = 'Ear Piece',   icon = '◎' },
    { id = 6, key = 'watch',    label = 'Watch',       icon = '◷' },
    { id = 7, key = 'bracelet', label = 'Bracelet',    icon = '◯' },
}

-- Categories shown only at barber shops (plus hair color)
Config.BarberComponents = {
    { id = 2, key = 'hair', label = 'Hair Style', icon = '✂' },
}

Config.BarberProps = {
    { id = 0, key = 'hat',     label = 'Hat / Helmet', icon = '▲' },
    { id = 1, key = 'glasses', label = 'Glasses',      icon = '◉' },
}

-- Enable hair primary + highlight color controls
Config.HairColor = true
Config.MaxHairColors = 64

-- Quick strip + emotes (clothing store UI)
Config.ShowStripBar = true
Config.StripActions = {
    { key = 'hat',     label = 'Hat',     icon = '🎩', kind = 'prop', propId = 0 },
    { key = 'mask',    label = 'Mask',    icon = '🎭', kind = 'component', componentId = 1, drawable = 0, texture = 0 },
    { key = 'glasses', label = 'Glasses', icon = '👓', kind = 'prop', propId = 1 },
    { key = 'shirt',   label = 'Shirt',   icon = '👕', kind = 'shirt' }, -- freemode bare torso set
    { key = 'shoes',   label = 'Shoes',   icon = '👟', kind = 'shoes' },
    { key = 'pants',   label = 'Pants',   icon = '👖', kind = 'pants' },
}

-- Freemode "removed clothing" drawables
Config.StripDrawables = {
    male = {
        torso = 15,   -- component 3
        top = 15,     -- component 11
        undershirt = 15, -- component 8
        pants = 21,   -- component 4
        shoes = 34,   -- component 6
        bag = 0,      -- component 5
        armor = 0,    -- component 9
        decal = 0,    -- component 10
        accessory = 0,-- component 7
        mask = 0,     -- component 1
    },
    female = {
        torso = 15,
        top = 15,
        undershirt = 15,
        pants = 15,
        shoes = 35,
        bag = 0,
        armor = 0,
        decal = 0,
        accessory = 0,
        mask = 0,
    },
}

Config.Emotes = {
    {
        key = 'handsup',
        label = 'Hands Up',
        icon = '🙌',
        dict = 'missminuteman_1ig_2',
        anim = 'handsup_base',
        flag = 49, -- upper body + loop
    },
    {
        key = 'handsup2',
        label = 'Hands Up (Alt)',
        icon = '✋',
        dict = 'random@mugging3',
        anim = 'handsup_standing_base',
        flag = 49,
    },
    {
        key = 'cancel',
        label = 'Stop Emote',
        icon = '⏹',
        cancel = true,
    },
}

-- Ped model changer (clothing store only)
Config.AllowPedChange = true
Config.Peds = {
    -- Freemode (fully customizable)
    { model = 'mp_m_freemode_01', label = 'Freemode Male',   group = 'Freemode' },
    { model = 'mp_f_freemode_01', label = 'Freemode Female', group = 'Freemode' },

    -- Story protagonists
    { model = 'player_zero',   label = 'Michael',  group = 'Story' },
    { model = 'player_one',    label = 'Franklin', group = 'Story' },
    { model = 'player_two',    label = 'Trevor',   group = 'Story' },

    -- Online / street
    { model = 'a_m_y_hipster_01',   label = 'Hipster',        group = 'Civilian' },
    { model = 'a_m_y_hipster_02',   label = 'Hipster 2',      group = 'Civilian' },
    { model = 'a_m_y_business_01',  label = 'Business Man',   group = 'Civilian' },
    { model = 'a_f_y_business_01',  label = 'Business Woman', group = 'Civilian' },
    { model = 'a_m_y_beach_01',     label = 'Beach Male',     group = 'Civilian' },
    { model = 'a_f_y_beach_01',     label = 'Beach Female',   group = 'Civilian' },
    { model = 'a_m_m_skater_01',    label = 'Skater',         group = 'Civilian' },
    { model = 'a_m_y_skater_01',    label = 'Skater Young',   group = 'Civilian' },
    { model = 'a_m_y_stbla_02',     label = 'Street',         group = 'Civilian' },
    { model = 'a_m_y_stwhi_01',     label = 'Street White',   group = 'Civilian' },
    { model = 'a_m_y_genstreet_01', label = 'Gen Street',     group = 'Civilian' },
    { model = 'a_f_y_genhot_01',    label = 'Hot Girl',       group = 'Civilian' },
    { model = 'a_f_y_hipster_01',   label = 'Hipster Female', group = 'Civilian' },
    { model = 'a_f_y_fitness_01',   label = 'Fitness',        group = 'Civilian' },
    { model = 'a_m_y_runner_01',    label = 'Runner',         group = 'Civilian' },
    { model = 'a_m_m_tourist_01',   label = 'Tourist',        group = 'Civilian' },
    { model = 'a_m_y_vinewood_01',  label = 'Vinewood',       group = 'Civilian' },
    { model = 'a_f_y_vinewood_01',  label = 'Vinewood Female', group = 'Civilian' },
    { model = 'a_m_m_soucent_01',   label = 'South Central',  group = 'Civilian' },
    { model = 'a_m_y_mexthug_01',   label = 'Mex Thug',       group = 'Civilian' },
    { model = 'g_m_y_ballaorig_01', label = 'Ballas',         group = 'Gangs' },
    { model = 'g_m_y_famca_01',     label = 'Families',       group = 'Gangs' },
    { model = 'g_m_y_lost_01',      label = 'Lost MC',        group = 'Gangs' },
    { model = 'g_m_y_mexgoon_01',   label = 'Vagos',          group = 'Gangs' },
    { model = 'g_m_m_armboss_01',   label = 'Armenian Boss',  group = 'Gangs' },
    { model = 's_m_y_cop_01',       label = 'LSPD Cop',       group = 'Jobs' },
    { model = 's_f_y_cop_01',       label = 'LSPD Female',    group = 'Jobs' },
    { model = 's_m_y_sheriff_01',   label = 'Sheriff',        group = 'Jobs' },
    { model = 's_m_m_paramedic_01', label = 'Paramedic',      group = 'Jobs' },
    { model = 's_m_y_fireman_01',   label = 'Firefighter',    group = 'Jobs' },
    { model = 's_m_m_doctor_01',    label = 'Doctor',         group = 'Jobs' },
    { model = 's_m_y_construct_01', label = 'Construction',   group = 'Jobs' },
    { model = 's_m_m_security_01',  label = 'Security',       group = 'Jobs' },
    { model = 's_m_y_swat_01',      label = 'SWAT',           group = 'Jobs' },
    { model = 's_m_y_marine_01',    label = 'Marine',         group = 'Jobs' },
    { model = 'u_m_y_zombie_01',    label = 'Zombie',         group = 'Special' },
    { model = 'u_m_y_imporage',     label = 'Impotent Rage',  group = 'Special' },
    { model = 'u_m_y_pogo_01',      label = 'Pogo',           group = 'Special' },
    { model = 'u_m_y_rsranger_01',  label = 'Space Ranger',   group = 'Special' },
    { model = 'ig_lestercrest',     label = 'Lester',         group = 'Special' },
    { model = 'ig_lamardavis',      label = 'Lamar',          group = 'Special' },
    { model = 'ig_jimmydisanto',    label = 'Jimmy',          group = 'Special' },
    { model = 'ig_tracydisanto',    label = 'Tracey',         group = 'Special' },
    { model = 'ig_wade',            label = 'Wade',           group = 'Special' },
    { model = 'ig_djblamadon',      label = 'DJ Blamadon',    group = 'Special' },
}
