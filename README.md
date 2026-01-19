# RSG-Stable (Renovated)
🐎 Advanced Horse System for RSGCore

This resource has been massively overhauled to include realistic stabling, trading, aging, and injury/revival mechanics.

## ✨ Features

> [!IMPORTANT]
> **Installation Requirement**: The resource folder MUST be named `devchacha-stable`. If you rename it, the NUI (interface) breaks because `config.lua` and `html/script.js` expect this exact resource name.

### 1. Realistic Stabling & Horse Call
- **Call Your Horse (`H`)**: When your horse is already out, press `H` to make it come to you. It will walk/run to your location.
- **Stable Required**: You must physically go to a stable to initially retrieve your horse.
- **Auto-Mount**: When you "Take Out" a horse from the stable menu, you spawn **already riding it** at the stable entrance.
- **Smart Flee**: If you flee your horse while near a stable (within 50m), it is **automatically stored** in that specific stable.

### 2. Advanced Horse Stats
Every horse is unique with persistent stats:
- **Gender**: Male (♂) or Female (♀) - selectable at purchase.
- **Age**: Horses age over time. Old horses may eventually pass away (lifespan configurable).
- **XP**: Experience tracking for future progression.
- **Stable Location**: Horses are stored in specific towns (e.g., "Valentine Stable"). You must go there to get them.

### 3. Horse Transfer System
Sell or give your horses to other players directly!
- **Transfers Tab**: New tab in the Stable Menu.
- **Send Offer**: Enter a player's Server ID and a Price (or $0 for a gift).
- **Secure Handling**: The buyer receives a notification and can **Accept** or **Decline** via the menu.
- **Money Handling**: Funds are automatically transferred upon acceptance.

### 4. 🆕 Horse Injury & Revival System
Horses can now be injured from accidents and revived at any stable!
- **Death Detection**: If your horse dies (falls, shot, etc.), you receive a notification: *"Your horse is critically injured! Go to a stable to revive it."*
- **Injured Status**: Injured horses show "INJURED" in red instead of "100%" health in the My Horses list.
- **Revive Option**: Instead of "Take Out", injured horses have a **"Revive ($50)"** button.
- **Instant Healing**: After paying $50, the horse is healed and ready to take out immediately.
- **Location Aware**: The horse is revived at the stable you're currently visiting.
- **Old Age Exception**: Horses that die from old age (lifespan reached) are permanently removed and cannot be revived.

### 5. 🆕 Horse Renaming
Give your horse a new identity!
- **Rename Button**: Click "Rename" in the horse action buttons.
- **Cost**: $20 per rename.
- **Validation**: Names must be 2-30 characters.
- **Instant Update**: The new name appears immediately in the UI.

### 6. 🆕 Crash Recovery System
Never lose your horse due to game crashes!
- **10-Minute Grace Period**: If your game crashes while your horse is out, you have 10 minutes to recover it.
- **Reconnect Notification**: Upon reconnecting, you'll see: *"Your horse is waiting! Press H within Xm Xs to recover it."*
- **Instant Recovery**: Press `H` to spawn your horse at your current location.
- **One-Time Use**: After recovery or expiry, normal rules apply (go to stable to retrieve).

---

## 🎮 Controls
| Action | Key / Input | Description |
| :--- | :--- | :--- |
| **Open Stable** | `Prompts` | Walk up to a stable NPC and press the prompt. |
| **Call Horse** | `H` | Makes your active horse come to you. Also used for crash recovery. |
| **Flee** | `Interaction` | Use the flee control (`B`) while near your horse. |
| **Transfer** | `Menu` | Use the "Transfer" button in the "My Horses" tab. |
| **Revive** | `Menu` | Click "Revive ($50)" on an injured horse. |
| **Rename** | `Menu` | Click "Rename" to change your horse's name ($20). |

---

## ⚙️ Configuration
The `config.lua` is extensively commented. Key settings:

- **`Config.MaxNumberOfHorses`**: Maximum horses a player can own (default: 5).
- **`Config.SellPrice`**: Fixed price when selling a horse (default: $50).
- **`Config.Aging`**: Control how fast horses age and their max lifespan.
- **`Config.Stables`**: Customize stable locations, spawn points, camera positions, and NPCs.
- **`Config.HorseCare`**: Configure feed items and their health restore values.

---

## 🗄️ Database
The `horses` table includes columns for the advanced system. 
*If you are updating from an old version, run this SQL:*

```sql
ALTER TABLE `horses`
ADD COLUMN `xp` INT DEFAULT 0,
ADD COLUMN `age` INT DEFAULT 0,
ADD COLUMN `gender` VARCHAR(10) DEFAULT 'Male',
ADD COLUMN `stable` VARCHAR(50) DEFAULT NULL,
ADD COLUMN `born_date` INT DEFAULT 0,
ADD COLUMN `last_age_update` INT DEFAULT 0,
ADD COLUMN `dead` TINYINT(1) DEFAULT 0;

CREATE TABLE IF NOT EXISTS `horse_transfers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `from_cid` varchar(50) DEFAULT NULL,
  `to_cid` varchar(50) DEFAULT NULL,
  `horse_id` int(11) DEFAULT NULL,
  `price` int(11) DEFAULT 0,
  `status` varchar(20) DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
);
```

> **Note:** The script will automatically add the `dead` column if it doesn't exist on resource start.

---

## 📦 Dependencies
- [rsg-core](https://github.com/Starter-Store/RSGCore)
- [ox_lib](https://github.com/overextended/ox_lib)
- [rsg-target](https://github.com/Starter-Store/rsg-target)
- [rsg-inventory](https://github.com/Starter-Store/rsg-inventory)

---

## Credits
- **Original**: Sporny / QBR-Stable
- **Refactor & Advanced Features**: DevChaCha Team (Implemented for RSGCore)