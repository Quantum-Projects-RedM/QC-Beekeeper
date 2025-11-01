# QC-Beekeeper

A comprehensive beekeeping system for RedM servers using RSG-Core framework with realistic apiary mechanics, wild hive hunting, and resource management.

![Version](https://img.shields.io/badge/version-1.0.3-blue.svg)
![Framework](https://img.shields.io/badge/framework-RSG--Core-green.svg)

## Features

- **4 Beehive Types**: Basic, Improved, Hornet, and Master hives with unique products (Honey, Propolis, Venom)
- **Wild Hive Hunting**: 20+ locations across the map with region-specific bee species
- **Resource Management**: Collect pollen and nectar, maintain quality for better rewards
- **Quality System**: Poor/Good/Excellent ratings affect harvest yields
- **Shop System**: 3 NPC locations (Valentine, Blackwater, Saint Denis)
- **Configurable**: Difficulty modes, decay rates, placement restrictions, and more

## Dependencies

- [rsg-core](https://github.com/Rexshack-RedM/rsg-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [PolyZone](https://github.com/mkafrin/PolyZone)
- [oxmysql](https://github.com/overextended/oxmysql)

## Installation

1. Extract to your resources folder
2. Execute `INSTALLATION/qc-beekeeper.sql` in your database
3. Add items from `INSTALLATION/items.txt` to `rsg-core/shared/items.lua`
4. Add images from `INSTALLATION/IMAGES/` to your inventory script
5. Configure `config.lua` as needed
6. Add `ensure QC-Beekeeper` to server.cfg

**Important**: For stability, move `stream/bee_house_gk_ytyp.ytyp` to a separate streaming resource to prevent crashes on script restart.

## Quick Start

1. Visit an Apiarist shop (map blip)
2. Purchase beekeeping supplies (smoker, beehive kit)
3. Find wild hives and use smoker to collect queen bees
4. Place your apiary and add a queen
5. Collect pollen/nectar from plants to maintain quality
6. Harvest when honey level reaches 70%

## Configuration

Key settings in `config.lua`:
```lua
Config.MaxApiaries = 5              -- Max apiaries per player
Config.HardDifficulty = false       -- Enable hard mode
Config.HarvestLevel = 70            -- Required level to harvest
Config.ApiaryCooldown = 5           -- Minutes between harvests
```

## Support

**Discord**: [Quantum Projects](https://discord.gg/kJ8ZrGM8TS)
**Developer**: Artmines

---

**Version**: 1.0.3 | **Framework**: RSG-Core
