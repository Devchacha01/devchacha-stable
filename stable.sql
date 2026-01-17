SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;


CREATE TABLE IF NOT EXISTS `horses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` varchar(50) NOT NULL,
  `selected` int(11) NOT NULL DEFAULT 0,
  `model` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `components`  varchar(5000) NOT NULL DEFAULT '{}',
  `iq` int(11) NOT NULL DEFAULT 0,
  `xp` int(11) NOT NULL DEFAULT 0,
  `age` int(11) NOT NULL DEFAULT 0,
  `gender` varchar(10) NOT NULL DEFAULT 'Male',
  `breed_type` varchar(50) DEFAULT NULL,
  `stable` varchar(50) DEFAULT NULL,
  `born_date` int(11) NOT NULL DEFAULT 0,
  `last_age_update` int(11) NOT NULL DEFAULT 0,
  `is_fertile` int(11) NOT NULL DEFAULT 1,
  `breed_count` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `horse_transfers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `horse_id` int(11) NOT NULL,
  `from_cid` varchar(50) NOT NULL,
  `to_cid` varchar(50) NOT NULL,
  `price` int(11) NOT NULL DEFAULT 0,
  `status` enum('pending','accepted','declined','cancelled') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
);
