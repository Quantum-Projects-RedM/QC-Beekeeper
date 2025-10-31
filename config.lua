Config = Config or {}
Config.Apiaries = {}
Config.ConsoleTime = 600 -- Time in seconds to wait before the console notifies/webhook sends (300 seconds = 5 minutes, 600 seconds = 10 minutes, etc.)
Config.Webhook = "" -- Replace with your actual webhook URL (LEAVE EMPTY IF NOT USED)
---------------------------------------------
-- Prompt settings
---------------------------------------------
Config.ForwardDistance   = 2.0
Config.PromptGroupName   = 'You a Beekeeper?'
Config.PromptCancelName  = 'Cancel'
Config.PromptPlaceName   = 'Place Apiary'
Config.PromptRotateLeft  = 'Rotate left'
Config.PromptRotateRight = 'Rotate Right'
---------------------------------
-- Notify settings
---------------------------------
Config.Notify = function (Title, Text, Time)-- Custom Notify Exports here
    lib.notify({ title = Title, description = Text, type = 'info', duration = Time })
end
---------------------------------
-- General settings
---------------------------------
Config.FadeIn = true -- If set to true, the Apiaries will fade in when they are placed.
Config.DistanceSpawn = 20.0 -- The distance from the player at which the Apiaries will be spawned. This is used to prevent Apiaries from spawning too close to the player.
Config.RestrictTowns = false -- Will there be limited placing in cities (if set to False, players can place anywhere, including cities)
Config.MaxApiaries = 5 -- The maximum number of apiaries that a player can have at any time (a maximum of 5 apiaries)
---------------------------------
-- Apiary General Settings
---------------------------------
Config.DestroyApiaryTime = 60 * 60 * 24 -- Time until the Apiary dies and is removed from the database (eg 60 *60 *24 for 1 day, 60 *60 *48 in 2 days, 60 *60 *72 in 3 days)
Config.StartingPollen = 10.0 -- The initial amount of pollen that the player starts with when they begin beekeeping.
Config.StartingNectar = 10.0 -- The initial amount of nectar that the player starts with when they begin beekeeping.
Config.NectarIncrease = 35.0 -- The amount of nectar that is added to the Apiary's inventory when the player adds nectar to the Apiary.
Config.PollenIncrease = 35.0 -- The amount of pollen that is added to the Apiary's inventory when the player adds pollen to the Apiary.
Config.ApiaryCooldown = 5 -- Cooldown in MINUTES to harvest again useful if not using ResetQualityOnHarvest (e.g., 5 = 5 minutes)
Config.HarvestLevel = 70 -- The honey required to harvest from the Apiary.
Config.ResetQualityOnHarvest = false -- If set to true, the quality of the Apiary will be reset to 0 when the player harvests from the Apiary.
---------------------------------
-- Apiary Refresh settings
---------------------------------
Config.RefreshTimer = 10000 -- 10000 = Every 10 seconds /testing? set to: 1000 = 1 second (time between each Apiaries growth tick)
Config.PollenDecay = 0.5 -- The amount of pollen that is removed from the Apiary's when the Refresh timer ticks.
Config.NectarDecay = 0.5 -- The amount of nectar that is removed from the Apiary's when the Refresh timer ticks.
---------------------------------
-- Hard Difficulty settings
-- MUST BE SET Config.HardDifficulty TO TRUE IN ORDER FOR THESE SETTINGS TO TAKE EFFECT
---------------------------------
Config.HardDifficulty = false -- If set to true, the Apiaries will be harder to populate and maintain, requiring more resources and time.
Config.QualityDec25Hard = 1.5 -- The amount of quality that is removed from the Apiary's inventory if less than 25% Nectar or Pollen [Config.HardDifficulty = true OR IT WONT WORK].
Config.QualityInc75Hard = 0.5 -- The amount of quality that is added to the Apiary's inventory if both Nectar and Pollen are above 75% [Config.HardDifficulty = true OR IT WONT WORK].
Config.QualityInc25Hard = 0.2 -- The amount of quality that is added to the Apiary's inventory if both Nectar and Pollen are between 25% and 75% [Config.HardDifficulty = true OR IT WONT WORK].
---------------------------------
-- Regular Difficulty settings
---------------------------------
Config.QualityDec25Easy =  0.5 -- The amount of quality that is removed from the Apiary's inventory if less than 25% Nectar or Pollen.
Config.QualityInc75Easy = 0.5 -- The amount of quality that is added to the Apiary's inventory if both Nectar and Pollen are above 75%.
Config.QualityInc25Easy = 0.2 -- The amount of quality that is added to the Apiary's inventory if both Nectar and Pollen are between 25% and 75%.
---------------------------------
-- Collecting settings
---------------------------------
Config.PollenCollectTime = 10000 -- The time it takes to collect pollen from a plant (in milliseconds, 10000 = 10 seconds)
Config.CollectRhodoTime = 3000 -- The time it takes to collect Rhododendron from a plant or prop (in milliseconds, 3000 = 3 seconds)
---------------------------------
-- Apiary Inventory Items
---------------------------------
Config.BeeJar = 'bee_jar'
Config.MadHoney = 'bee_mad_honey'   ---NOT YET IMPLEMENTED
Config.PollenItem = 'bee_pollen'
Config.SmokerItem = 'bee_smoker'
Config.NectarItem = 'bee_nectar'
Config.RhododItem = 'bee_rhododendron'
--[[ Config.RequiredItem = 'bucket' ]]     --NOT YET IMPLEMENTED
---------------------------------
-- Pollen Plants
-- This section defines the plants that can be used to collect pollen.
---------------------------------
Config.PollenPlants = {
    `rdr_bush_sumac_aa_sim`
}
---------------------------------
-- Rhododendron Prop
-- This defines the props to collect Rhododendron for mad honey.
---------------------------------
Config.RhododendronProp = {
    `p_tree_baldcypress_06b` -- 1976.68, -1688.15, 41.73, 188.31      FOR AN EXAMPLE IN GAME
}
---------------------------------
-- Wild BeeHives Settings
---------------------------------
Config.GetQueenTime = 5 -- Time in secs
Config.SmokeTime = 5 -- Time in secs
Config.WildHiveModel = 's_hornetnest_01x' -- Prop for wild beehives (RECOMMEND LEAVING AS IS)

Config.WildHives = {
    --Valentine Area
    { x = -216.408, y = 826.143, z = 125.752, rotx = -2.958, roty = 6.732, rotz = -145.55, heading = 50, queen = 'honey_bee_queen'},
    { x = -193.722, y = 743.794, z = 123.141, rotx = 9.698, roty = -5.618, rotz = -79.592, heading = 50, queen = 'honey_bee_queen'},
    { x = -453.896, y = 834.049, z = 121.246, rotx = -1.0, roty = 5.041, rotz = 170.42, heading = 50, queen = 'honey_bee_queen'},
    { x = -377.553, y = 982.536, z = 120.848, rotx = -4.384, roty = -0.888, rotz = 130.965, heading = 50, queen = 'honey_bee_queen'},
    { x = -154.658, y = 891.411, z = 151.904, rotx = 1.172, roty = 3.543, rotz = 97.143, heading = 50, queen = 'honey_bee_queen'},
    --Ambarino
    { x = 185.459, y = 1365.287, z = 172.666, rotx = -10.664, roty = 27.0, rotz = 39.002, heading = 50, queen = 'carpenter_bee_queen'},
    { x = 337.993, y = 1512.106, z = 182.987, rotx = -42.0, roty = 8.0, rotz = -135.78, heading = 50, queen = 'carpenter_bee_queen'},
    { x = 454.742, y = 1612.141, z = 205.198, rotx = -22.0, roty = 5.739, rotz = -2.234, heading = 50, queen = 'carpenter_bee_queen'},
    { x = 642.597, y = 1265.632, z = 210.373, rotx = -30.0, roty = 3.647, rotz = 95.294, heading = 50, queen = 'carpenter_bee_queen'},
    { x = 821.806, y = 1468.998, z = 204.831, rotx = -41.085, roty = -11.619, rotz = 116.201, heading = 50, queen = 'carpenter_bee_queen'},
    --Grizzlies East
    { x = 748.320, y = 1870.760, z = 243.940, rotx = -8.005, roty = -7.216, rotz = 87.216, heading = 50, queen = 'honey_bee_queen'},
    { x = 729.060, y = 1790.030, z = 232.140, rotx = 5.230, roty = 20.092, rotz = -159.672, heading = 50, queen = 'honey_bee_queen'},
    { x = 766.840, y = 1626.890, z = 214.060, rotx = -13.797, roty = 14.597, rotz = -136.597, heading = 50, queen = 'honey_bee_queen'},
    { x = 981.520, y = 1208.780, z = 181.010, rotx = 2.221, roty = 33.000, rotz = -114.000, heading = 50, queen = 'honey_bee_queen'},
    { x = 946.480, y = 1087.990, z = 154.040, rotx = 10.710, roty = 47.000, rotz = 66.000, heading = 50, queen = 'honey_bee_queen'},
    --Lemoyne
    { x = 1468.310, y = -85.040, z = 99.510, rotx = -5.382, roty = 31.000, rotz = -89.000, heading = 50, queen = 'hornet_bee_queen'},
    { x = 1281.750, y = -145.980, z = 94.960, rotx = 4.294, roty = 23.000, rotz = 175.000, heading = 50, queen = 'hornet_bee_queen'},
    { x = 1083.900, y = -227.720, z = 96.370, rotx = -1.777, roty = -3.428, rotz = -2.126, heading = 50, queen = 'hornet_bee_queen'},
    { x = 894.270, y = -406.610, z = 89.140, rotx = 6.586, roty = 11.716, rotz = -33.000, heading = 50, queen = 'hornet_bee_queen'},
    { x = 740.400, y = -457.180, z = 80.190, rotx = 15.280, roty = 30.000, rotz = 53.000, heading = 50, queen = 'hornet_bee_queen'},
    --West Elizabeth
    { x = 185.459, y = 1365.287, z = 172.666, rotx = -10.664, roty = 27.0, rotz = 39.002, heading = 50, queen = 'carpenter_bee_queen'},
    { x = -1210.260, y = 523.640, z = 80.270, rotx = -29.000, roty = -13.683, rotz = 92.253, heading = 50, queen = 'carpenter_bee_queen'},
    { x = -1347.434, y = 595.400, z = 102.680, rotx = -32.000, roty = -4.195, rotz = 165.864, heading = 50, queen = 'carpenter_bee_queen'},
    { x = -1508.460, y = 655.530, z = 117.420, rotx = -28.000, roty = 3.130, rotz = 135.332, heading = 50, queen = 'carpenter_bee_queen'},
    { x = -2074.910, y = 789.120, z = 144.650, rotx = -27.000, roty = -3.406, rotz = 131.922, heading = 50, queen = 'carpenter_bee_queen'},

}
---------------------------------
-- Bee Apiaries
---------------------------------
Config.ApiarieItems = {
    ---------------------------------------------
    -- Honey Bees Beehive
    -- Requires: Honey Bee Queen
    ---------------------------------------------
    ['honey_beehive'] = {
        type = 'honey',  -- Apiary type, in this case 'honey'. DONT CHANGE THIS NAME, IT IS USED IN THE CODE
        item = 'bee_honey_apiary',  -- The item that the player needs to have in their inventory to place this Apiary.
        hash = 'bee_house_gk_3', -- The hash of the Apiary model that will be used.
        label = 'Basic Beehive',  -- The label that will be displayed to the player when they interact with this Apiary.
        bees = { 'honey_bee_queen' }, -- The types of bees that can be used in this beehive
        -- REWARD SETTINGS (Reward Settings)
        -- These settings define the rewards that the player will receive when they harvest honey from this Apiary.
        receive = 'bee_honey',  -- The name of the item that will be given to the player as a reward for harvesting this Apiary.
        poorRewards = { 
            min = 2,  -- Minimum reward for poor quality Apiaries
            max = 5, -- Maximum reward for poor quality Apiaries
        },
        goodRewards = {
            min = 7, -- Minimum reward for good quality Apiaries
            max = 12, -- Maximum reward for good quality Apiaries
        },
        excellentRewards = {
            min = 15, -- Minimum reward for excellent quality Apiaries
            max = 23, -- Maximum reward for excellent quality Apiaries
        },
    },
    ---------------------------------------------
    -- Carpenter Bees Beehive
    -- Requires: Carpenter Bee Queen
    ---------------------------------------------
    ['carpenter_beehive'] = {
        type = 'carpenter', -- Apiary type, in this case 'carpenter'. DONT CHANGE THIS NAME, IT IS USED IN THE CODE
        item = 'bee_carpe_apiary',
        hash = 'bee_house_gk_4',  --Bluish Apiary
        label = 'Improved Beehive',
        bees = { 'carpenter_bee_queen' },
        receive = 'bee_propolis',
        poorRewards = {
            min = 2,
            max = 4,
        },
        goodRewards = {
            min = 6,
            max = 12,
        },
        excellentRewards = {
            min = 14,
            max = 20,
        },
    },
    ---------------------------------------------
    -- Hornet Beehive
    -- Requires: Hornet Bee Queen
    ---------------------------------------------
    ['hornet_beehive'] = {
        type = 'hornet', -- Apiary type, in this case 'hornet'. DONT CHANGE THIS NAME, IT IS USED IN THE CODE
        item = 'bee_horne_apiary',
        hash = 'bee_house_gk_6', -- Redish Apiary
        label = 'Hornet Beehive',
        bees = { 'hornet_bee_queen'},
        receive = 'bee_venom',
        poorRewards = {
            min = 2,
            max = 4,
        },
        goodRewards = {
            min = 6,
            max = 8,
        },
        excellentRewards = {
            min = 12,
            max = 18,
        },
    },
    ---------------------------------------------
    -- Master Bees Beehive
    -- Requires: Carpenter or Honey or Hornet Bee Queen
    -- Increased output
    ---------------------------------------------
    ['master_beehive'] = {
        type = 'master', -- Apiary type, in this case 'master'. DONT CHANGE THIS NAME, IT IS USED IN THE CODE
        item = 'bee_advan_apiary',
        hash = 'bee_house_gk_5',  -- Bluish Apiary
        label = 'Master Beehive',
        bees = { 'honey_bee_queen', 'carpenter_bee_queen', 'hornet_bee_queen' },
        receive = 'bee_honey',
        poorRewards = {
            min = 5,
            max = 10,
        },
        goodRewards = {
            min = 15,
            max = 20,
        },
        excellentRewards = {
            min = 25,
            max = 30,
        },
    },
}
---------------------------------
-- NOT IN USE YET
-- This section defines the locations of the Apiary shops where players can purchase items related to beekeeping.
---------------------------------
--[[ Config.QueenHives = {
    ---------------------------------------------
    -- Queen Beehive
    -- This is a special type of beehive that requires a queen bees to create royal jelly for new queen bees.
    ---------------------------------------------
} ]]
---------------------------------
-- Apiary Shop Locations
-- This section defines the locations of the Apiary shops where players can purchase items related to beekeeping.
---------------------------------

-- Blip settings
Config.Blip = {
    blipName = 'Apiarists Store', -- Translate to your language
    blipSprite = 'blip_summer_horse', -- Config.blip.blip sprite
    blipScale = 0.2 -- Config.blip.blip scale
}

Config.ApiaryShopLoc = {
   { 
        name = 'Valentine Apiarists',
        prompt = 'val-apiarists',
        coords = vector3(-231.9709, 644.5262, 113.3582),
        showblip = true,
        npcmodel = `a_m_m_valfarmer_01`,
        npccoords = vector4(-231.9709, 644.5262, 113.3582, 310.3258),
    },
    
    { 
        name = 'Blackwater Apiarists',
        prompt = 'bw-apiarists',
        coords = vector3(-841.5115, -1366.1421, 43.6815),
        showblip = true,
        npcmodel = `a_m_m_valfarmer_01`,
        npccoords = vector4(-841.5115, -1366.1421, 43.6815, 87.3671),
    },
    { 
        name = 'SD Apiarists',
        prompt = 'sd-apiarists',
        coords = vector3(2808.6726, -1281.5323, 47.0885),
        showblip = true,
        npcmodel = `a_m_m_valfarmer_01`,
        npccoords = vector4(2808.6726, -1281.5323, 47.0885, 318.5407),
    },
  
}