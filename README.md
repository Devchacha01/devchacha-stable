# RSG-Stable (Converted for RSGCore)
🐎 Horse Purchasing & Customization System for RSGCore

## Features
- Purchase horses from various stables across the map
- Customize horses with saddles, blankets, manes, tails, bags, stirrups, and more
- Whistle to call your horse (Press H)
- Send horse away (Flee command)
- Sell your horses at any stable
- Multiple stable locations (Valentine, Blackwater, Saint Denis, Annesburg, Rhodes, Tumbleweed)

## Installation

1. Copy `devchacha-stable` into your `resources` folder
2. Add `ensure devchacha-stable` to your `server.cfg`
3. The database table will be created automatically on first start

## Database (Auto-Created)
The `horses` table is automatically created when the resource starts:
```sql
CREATE TABLE IF NOT EXISTS `horses` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `cid` varchar(50) NOT NULL,
    `selected` int(11) NOT NULL DEFAULT 0,
    `model` varchar(50) NOT NULL,
    `name` varchar(50) NOT NULL,
    `components` varchar(5000) NOT NULL DEFAULT '{}',
    PRIMARY KEY (`id`)
);
```

## Config
- `Config.MaxNumberOfHorses` - Maximum number of horses a player can own (default: 3)
- `Config.Stables` - Stable locations with spawn points and camera positions
- `Config.Horses` - Available horses for purchase with prices

More horses can be added in the `config.lua`. 
List of horses can be found here: https://www.rdr2mods.com/wiki/ped-search/?s=horse&pedtype=1&&withComments=1&withDescription=1

## Controls
- **H** - Whistle for your horse
- **Horse Flee Key** - Send horse away

## Dependencies
- [rsg-core](https://github.com/Rexshack-RedM/rsg-core)
- [oxmysql](https://github.com/overextended/oxmysql)

## Credits
- Original Script: [Sporny / QBR-Stable](https://github.com/Luminous-Roleplay/LRP_Stable)
- RSGCore Conversion: Automated conversion for RSG Framework