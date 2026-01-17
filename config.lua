Config = {}

Config.MaxNumberOfHorses = 3
Config.Training = {
    MaxIQ = 100,
    MaxXP = 1000,
    XPPerTrain = 10,
    IQIncreasePerLevel = 5,
    BreedingMinAge = 3,
    TrainingCooldown = 1 * 60 * 1000, -- 1 minute
    BreedingCooldown = 60 * 60 * 1000, -- 1 hour
    Jobs = {
        ['valhorsetrainer'] = true,
        ['rhohorsetrainer'] = true,
        ['blkhorsetrainer'] = true,
        ['strhorsetrainer'] = true,
        ['stdenhorsetrainer'] = true,
    }
}

Config.Aging = {
    MinStartAge = 14,
    MaxStartAge = 15,
    LifespanDays = 75,      -- Horse dies after 75 days (2.5 months)
    AgeIntervalDays = 3,    -- Horse ages 1 year every 3 days
}

Config.Stables = {
    valentine = {
        Pos = vector3(-365.87, 789.51, 116.17), -- Using EnterStable as main Pos
        Name = "Stable of Valentine",
        StableNPC = { x = -365.15, y = 792.68, z = 115.18, h = 178.47, model = "u_m_m_bwmstablehand_01" },
        SpawnHorse = { x = -366.07, y = 781.81, z = 115.14, h = 5.97 },
        CamHorse = { x = -367.9267, y = 783.0237, z = 117.7778, rx = -36.42624, ry = 0.0, rz = -100.9786 },
        CamHorseGear = { x = -367.9267, y = 783.0237, z = 117.7778, rx = -36.42624, ry = 0.0, rz = -100.9786 }
    },
    rhodes = {
        Pos = vector3(1432.97, -1295.39, 76.82),
        Name = "Stable of Rhodes",
        StableNPC = { x = 1434.64, y = -1294.89, z = 76.82, h = 105.08, model = "u_m_m_bwmstablehand_01" },
        SpawnHorse = { x = 1431.56, y = -1288.21, z = 76.82, h = 87.28 },
        CamHorse = { x = 1431.58, y = -1292.27, z = 79.0, rx = -16.0, ry = 0.0, rz = 6.0 },
        CamHorseGear = { x = 1431.58, y = -1292.27, z = 79.0, rx = -16.0, ry = 0.0, rz = 6.0 }
    },
    saintdenis = {
        Pos = vector3(2510.58, -1456.83, 46.31),
        Name = "Saint Denis Stable",
        StableNPC = { x = 2512.35, y = -1456.89, z = 45.2, h = 91.68, model = "u_m_m_bwmstablehand_01" },
        SpawnHorse = { x = 2508.59, y = -1449.96, z = 45.5, h = 90.09 },
        CamHorse = { x = 2506.807, y = -1452.29, z = 48.61699, rx = -34.77003, ry = 0.0, rz = -35.20742 },
        CamHorseGear = { x = 2508.876, y = -1451.953, z = 48.67999, rx = -35.29771, ry = 0.0, rz = -0.4993192 }
    },
    strawberry = {
        Pos = vector3(-1816.81, -561.99, 156.07),
        Name = "Strawberry Stable",
        StableNPC = { x = -1818.45, y = -564.83, z = 155.06, h = 347.22, model = "u_m_m_bwmstablehand_01" },
        SpawnHorse = { x = -1820.26, y = -555.84, z = 155.16, h = 163.01 },
        CamHorse = { x = -1819.512, y = -558.6999, z = 157.6765, rx = -23.95241, ry = 0.0, rz = 28.46066 },
        CamHorseGear = { x = -1819.512, y = -558.6999, z = 157.6765, rx = -23.95241, ry = 0.0, rz = 28.46066 }
    },
    blackwater = {
        Pos = vector3(-876.57, -1365.1, 43.53),
        Name = "Blackwater Stable",
        StableNPC = { x = -878.35, y = -1364.81, z = 42.53, h = 266.28, model = "u_m_m_bwmstablehand_01" },
        SpawnHorse = { x = -864.25, y = -1361.8, z = 42.7, h = 177.48 },
        CamHorse = { x = -862.6163, y = -1362.927, z = 45.58158, rx = -40.96593, ry = 0.0, rz = 71.8129 },
        CamHorseGear = { x = -862.6163, y = -1362.927, z = 45.58158, rx = -40.96593, ry = 0.0, rz = 71.8129 }
    },
    tumbleweed = {
        Pos = vector3(-5514.24, -3041.81, -2.39),
        Name = "Tumbleweed Stable",
        StableNPC = { x = -5515.07, y = -3039.51, z = -3.39, h = 179.88, model = "u_m_m_bwmstablehand_01" },
        SpawnHorse = { x = -5519.47, y = -3039.32, z = -3.31, h = 181.62 },
        CamHorse = { x = -5517.651, y = -3041.113, z = -0.50949, rx = -33.14523, ry = 0.0, rz = 55.47822 },
        CamHorseGear = { x = -5517.651, y = -3041.113, z = -0.50949, rx = -33.14523, ry = 0.0, rz = 55.47822 }
    }
}

Config.Horses = {
	{
		name = "Arabian",
		["A_C_Horse_Arabian_White"] = {"White", 1500, 1500},
		["A_C_Horse_Arabian_RoseGreyBay"] = {"Rose Grey Bay", 1350, 12350},
		["A_C_Horse_Arabian_Black"] = {"Black", 1250, 1250},
		["A_C_Horse_Arabian_Grey"] = {"Grey", 1150, 1150},
		["A_C_Horse_Arabian_WarpedBrindle_PC"] = {"Warped Brindle", 650, 650},
		["A_C_Horse_Arabian_RedChestnut"] = {"Red Chestnut", 350, 350},
	},
	{
		name = "Ardennes",
		["A_C_Horse_Ardennes_IronGreyRoan"] = {"Iron Grey Roan", 1200, 1200},
		["A_C_Horse_Ardennes_StrawberryRoan"] = {"Strawberry Roan", 450, 450},
		["A_C_Horse_Ardennes_BayRoan"] = {"Bay Roan", 140, 140},
	},	
	{
		name = "Missouri Fox Trotter",
		["A_C_Horse_MissouriFoxTrotter_AmberChampagne"] = {"Amber Champagne", 950, 950},
		["A_C_Horse_MissouriFoxTrotter_SableChampagne"] = {"Sable Champagne", 950, 950},
		["A_C_Horse_MissouriFoxTrotter_SilverDapplePinto"] = {"Silver Dapple Pinto", 950, 950},
	},
	{
		name = "Turkoman",
		["A_C_Horse_Turkoman_Gold"] = {"Gold", 950, 950},
		["A_C_Horse_Turkoman_Silver"] = {"Silver", 950, 950},
		["A_C_Horse_Turkoman_DarkBay"] = {"Dark Bay", 925, 925},
	},
	{
		name = "Appaloosa",
		["A_C_Horse_Appaloosa_BlackSnowflake"] = {"Snow Flake", 900, 900},
		["A_C_Horse_Appaloosa_BrownLeopard"] = {"Brown Leopard", 450, 450},
		["A_C_Horse_Appaloosa_Leopard"] = {"Leopard", 430, 430},
		["A_C_Horse_Appaloosa_FewSpotted_PC"] = {"Few Spotted", 140, 140},
		["A_C_Horse_Appaloosa_Blanket"] = {"Blanket", 200, 200},
		["A_C_Horse_Appaloosa_LeopardBlanket"] = {"Lepard Blanket", 130, 130},
	},	
	{
		name = "Mustang",
		["A_C_Horse_Mustang_GoldenDun"] = {"Golden Dun", 950, 950},
		["A_C_Horse_Mustang_TigerStripedBay"] = {"Tiger Striped Bay", 350, 350},
		["A_C_Horse_Mustang_GrulloDun"] = {"Grullo Dun", 130, 130},
		["A_C_Horse_Mustang_WildBay"] = {"Wild Bay", 130, 130},
	},	
	{
		name = "Thoroughbred",
		["A_C_Horse_Thoroughbred_BlackChestnut"] = {"Black Chestnut", 550, 550},
		["A_C_Horse_Thoroughbred_BloodBay"] = {"Blood Bay", 550, 550},
		["A_C_Horse_Thoroughbred_Brindle"] = {"Brindle", 550, 550},
		["A_C_Horse_Thoroughbred_ReverseDappleBlack"] = {"Reverse Dapple Black", 550, 550},
		["A_C_Horse_Thoroughbred_DappleGrey"] = {"Dapple Grey", 130, 130},
	},	
	{
		name = "Andalusian",
		["A_C_Horse_Andalusian_Perlino"] = {"Perlino", 450, 450},
		["A_C_Horse_Andalusian_RoseGray"] = {"Rose Gray", 440, 440},
		["A_C_Horse_Andalusian_DarkBay"] = {"Dark Bay", 140, 140},
	},	
	{
		name = "Dutch Warmblood",
		["A_C_Horse_DutchWarmblood_ChocolateRoan"] = {"Chocolate Roan", 450, 450},
		["A_C_Horse_DutchWarmblood_SealBrown"] = {"Seal Brown", 150, 150},
		["A_C_Horse_DutchWarmblood_SootyBuckskin"] = {"Sooty Buckskin", 150, 150},
	},
	{
		name = "Nokota",
		["A_C_Horse_Nokota_ReverseDappleRoan"] = {"Reverse Dapple Roan", 450, 450},
		["A_C_Horse_Nokota_BlueRoan"] = {"Blue Roan", 130, 130},
		["A_C_Horse_Nokota_WhiteRoan"] = {"White Roan", 130, 130},
	},
	{
		name = "American Paint",
		["A_C_Horse_AmericanPaint_Greyovero"] = {"Grey Overo", 425, 425},
		["A_C_Horse_AmericanPaint_SplashedWhite"] = {"Splashed White", 140, 140},
		["A_C_Horse_AmericanPaint_Tobiano"] = {"Tobiano", 140, 140},
		["A_C_Horse_AmericanPaint_Overo"] = {"Overo", 130, 130},
	},	
	{
		name = "American Standardbred",
		["A_C_Horse_AmericanStandardbred_SilverTailBuckskin"] = {"Silver Tail Buckskin", 400, 400},
		["A_C_Horse_AmericanStandardbred_PalominoDapple"] = {"Palomino Dapple", 150, 150},
		["A_C_Horse_AmericanStandardbred_Black"] = {"Black", 130, 130},
		["A_C_Horse_AmericanStandardbred_Buckskin"] = {"Buckskin", 130, 130},
	},	
	{
		name = "Kentucky Saddle",
		["A_C_Horse_KentuckySaddle_ButterMilkBuckskin_PC"] = {"Butter Milk Buckskin", 240, 240},
		["A_C_Horse_KentuckySaddle_Black"] = {"Black", 50, 50},
		["A_C_Horse_KentuckySaddle_ChestnutPinto"] = {"Chestnut Pinto", 50, 50},
		["A_C_Horse_KentuckySaddle_Grey"] = {"Grey", 50, 50},
		["A_C_Horse_KentuckySaddle_SilverBay"] = {"Silver Bay", 50, 50},
	},	
	{
		name = "Hungarian Halfbred",
		["A_C_Horse_HungarianHalfbred_DarkDappleGrey"] = {"Dark Dapple Grey", 150, 150},
		["A_C_Horse_HungarianHalfbred_LiverChestnut"] = {"Liver Chestnut", 150, 150},
		["A_C_Horse_HungarianHalfbred_FlaxenChestnut"] = {"Flaxen Chestnut", 130, 130},
		["A_C_Horse_HungarianHalfbred_PiebaldTobiano"] = {"Piebald Tobiano", 130, 130},
	},	
	{
		name = "Suffolk Punch",
		["A_C_Horse_SuffolkPunch_RedChestnut"] = {"Red Chestnut", 150, 150},
		["A_C_Horse_SuffolkPunch_Sorrel"] = {"Sorrel", 120, 120},
	},	
	{
		name = "Tennessee Walker",
		["A_C_Horse_TennesseeWalker_FlaxenRoan"] = {"Flaxen Roan", 150, 150},
		["A_C_Horse_TennesseeWalker_BlackRabicano"] = {"Black Rabicano", 60, 60},
		["A_C_Horse_TennesseeWalker_Chestnut"] = {"Chestnut", 60, 60},
		["A_C_Horse_TennesseeWalker_DappleBay"] = {"Dapple Bay", 60, 60},
		["A_C_Horse_TennesseeWalker_MahoganyBay"] = {"Mahogany Bay", 60, 60},
		["A_C_Horse_TennesseeWalker_RedRoan"] = {"Red Roan", 60, 60},
		["A_C_Horse_TennesseeWalker_GoldPalomino_PC"] = {"Gold Palomino", 60, 60},
	},
	{
		name = "Shire",
		["A_C_Horse_Shire_LightGrey"] = {"Light Grey", 130, 130},
		["A_C_Horse_Shire_RavenBlack"] = {"Raven Black", 130, 130},
		["A_C_Horse_Shire_DarkBay"] = {"Dark Bay", 120, 120},
	},
	{
		name = "Belgian Draft",
		["A_C_Horse_Belgian_BlondChestnut"] = {"Blond Chestnut", 120, 120},
		["A_C_Horse_Belgian_MealyChestnut"] = {"Mealy Chestnut", 120, 120},
	},			
	{
		name = "Morgan",
		["A_C_Horse_Morgan_Palomino"] = {"Palomino", 60, 60},
		["A_C_Horse_Morgan_Bay"] = {"Bay", 55, 55},
		["A_C_Horse_Morgan_BayRoan"] = {"Bay Roan", 55, 55},
		["A_C_Horse_Morgan_FlaxenChestnut"] = {"Flaxen Chestnut", 55, 55},
		["A_C_Horse_Morgan_LiverChestnut_PC"] = {"Liver Chestnut", 55, 55},
	},		
	{
		name = "Other",
		["A_C_Horse_Gang_Dutch"] = {"Gang Duch", 3000, 3000},
		["A_C_HorseMule_01"] = {"Mule", 18, 18},
		["A_C_HorseMulePainted_01"] = {"Zebra", 15, 15},
		["A_C_Donkey_01"] = {"Donkey", 15, 15},
		["A_C_Horse_MP_Mangy_Backup"] = {"Mangy Backup", 15, 15},
	}
}
