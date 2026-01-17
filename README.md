# RSG-Stable (Renovated)
🐎 Advanced Horse System for RSGCore

This resource has been massively overhauled to include realistic stabling, breeding, trading, and aging mechanics.

## ✨ New Features

### 1. Realistic Stabling & Fleeing
- **No More Magic Whistle**: The "Whistle" key (`H`) has been **disabled**. You cannot summon your horse from thin air.
- **Stable Required**: You must physically go to a stable to retrieve your horse.
- **Auto-Mount**: When you "Take Out" a horse from the stable menu, you spawn **already riding it** at the stable entrance.
- **Smart Flee**: If you flee your horse (Interactive Flee / right-click context) while near a stable (within 50m), it is **automatically stored** in that specific stable.

### 2. Advanced Horse Stats
Every horse is unique with persistent stats:
- **Gender**: Male (♂) or Female (♀). Affects breeding.
- **Age**: Horses age over time. Old horses may eventually pass away.
- **XP & IQ**: Train your horse to increase its responsiveness. Low IQ horses may buck or disobey.
- **Stable Location**: Horses are stored in specific towns (e.g., "Valentine Stable"). You must go there to get them.

### 3. Horse Transfer System
Sell or give your horses to other players directly!
- **Transfers Tab**: New tab in the Stable Menu.
- **Send Offer**: Enter a player's Server ID and a Price (or $0 for a gift).
- **Secure Handling**: The buyer receives a notification and can **Accept** or **Decline** via the menu.
- **Money Handling**: Funds are automatically transferred upon acceptance.

### 4. Breeding System
- **Breed Horses**: Owners of a Male and Female horse can breed them to produce a foal.
- **Genetics**: Foals inherit traits from their parents.
- **Cooldowns**: Breeding has fertility intervals.

---

## 🎮 Controls
| Action | Key / Input | Description |
| :--- | :--- | :--- |
| **Open Stable** | `Prompts` | Walk up to a stable NPC/Blip and press the prompt. |
| **Whistle** | `Disabled` | You must retrieve your horse from a stable. |
| **Flee** | `Interaction` | Lock onto your horse (`Right Click`) and select **Flee** (`B` or `F`). |
| **Transfer** | `Menu` | Use the "Transfer" button in the "My Horses" tab. |

---

## ⚙️ Configuration
The `config.lua` is extensively commented. Key settings:

- **`Config.Aging`**: Control how fast horses age and their max lifespan.
- **`Config.Training`**: Set XP gain rates and max IQ.
- **`Config.Breeding`**: Set gestation periods and foal growth rates.
- **`Config.Stables`**: Customize stable locations, spawn points, and NPCs.

---

## 🗄️ Database
The `horses` table includes new columns for the advanced system. 
*If you are updating from an old version, run this SQL:*

```sql
ALTER TABLE `horses`
ADD COLUMN `iq` INT DEFAULT 0,
ADD COLUMN `xp` INT DEFAULT 0,
ADD COLUMN `age` INT DEFAULT 0,
ADD COLUMN `gender` VARCHAR(10) DEFAULT 'Male',
ADD COLUMN `stable` VARCHAR(50) DEFAULT NULL,
ADD COLUMN `born_date` INT DEFAULT 0,
ADD COLUMN `last_age_update` INT DEFAULT 0,
ADD COLUMN `is_fertile` TINYINT(1) DEFAULT 1,
ADD COLUMN `breed_count` INT DEFAULT 0;

CREATE TABLE IF NOT EXISTS `horse_transfers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sender_cid` varchar(50) DEFAULT NULL,
  `target_cid` varchar(50) DEFAULT NULL,
  `horse_id` int(11) DEFAULT NULL,
  `price` int(11) DEFAULT 0,
  `status` varchar(20) DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
);
```

## Credits
- **Original**: Sporny / QBR-Stable
- **Refactor & Advanced Features**: DevChaCha Team (Implemented for RSGCore)