class LevelService {
  static const int maxLevel = 45;

  // Tier thresholds
  static const int bronzeTierEnd = 10;
  static const int silverTierEnd = 20;
  static const int goldTierEnd = 30;
  static const int diamondTierEnd = 44;

  // Games per level within each tier
  static const int gamesPerLevelBronze = 3;
  static const int gamesPerLevelSilver = 5;
  static const int gamesPerLevelGold = 10;
  static const int gamesPerLevelDiamond = 15; // Assuming for Diamond
  static const int gamesForElite = 20; // Assuming for Elite

  // Additional games to enter a new tier
  static const int gamesToEnterSilver = 15;
  static const int gamesToEnterGold = 30;
  static const int gamesToEnterDiamond = 45; // Assuming for Diamond

  String getTierForLevel(int level) {
    if (level <= bronzeTierEnd) {
      return 'Bronze';
    } else if (level <= silverTierEnd) {
      return 'Silver';
    } else if (level <= goldTierEnd) {
      return 'Gold';
    } else if (level < maxLevel) {
      return 'Diamond';
    } else {
      return 'Elite';
    }
  }

  int getGamesRequiredForLevel(int level) {
    if (level <= 1) return 0;

    int totalGames = 0;
    
    // Bronze Tier
    totalGames += bronzeTierEnd * gamesPerLevelBronze;
    
    // Silver Tier
    totalGames += gamesToEnterSilver;
    totalGames += (silverTierEnd - bronzeTierEnd) * gamesPerLevelSilver;

    // Gold Tier
    totalGames += gamesToEnterGold;
    totalGames += (goldTierEnd - silverTierEnd) * gamesPerLevelGold;

    // Diamond Tier
    totalGames += gamesToEnterDiamond;
    totalGames += (diamondTierEnd - goldTierEnd) * gamesPerLevelDiamond;

    // Elite Tier
    if (level == maxLevel) {
      totalGames += gamesForElite;
    }

    if (level <= bronzeTierEnd) {
        return (level - 1) * gamesPerLevelBronze;
    } else if (level <= silverTierEnd) {
        return (bronzeTierEnd * gamesPerLevelBronze) + gamesToEnterSilver + ((level - 1 - bronzeTierEnd) * gamesPerLevelSilver);
    } else if (level <= goldTierEnd) {
        return (bronzeTierEnd * gamesPerLevelBronze) + gamesToEnterSilver + ((silverTierEnd - bronzeTierEnd) * gamesPerLevelSilver) + gamesToEnterGold + ((level - 1 - silverTierEnd) * gamesPerLevelGold);
    } else if (level <= diamondTierEnd) {
        return (bronzeTierEnd * gamesPerLevelBronze) + gamesToEnterSilver + ((silverTierEnd - bronzeTierEnd) * gamesPerLevelSilver) + gamesToEnterGold + ((goldTierEnd - silverTierEnd) * gamesPerLevelGold) + gamesToEnterDiamond + ((level - 1 - goldTierEnd) * gamesPerLevelDiamond);
    }

    return totalGames;
  }

  int getLevelFromGames(int totalGames) {
    int level = 1;
    while (level < maxLevel) {
      if (totalGames < getGamesRequiredForLevel(level + 1)) {
        break;
      }
      level++;
    }
    return level;
  }
}
