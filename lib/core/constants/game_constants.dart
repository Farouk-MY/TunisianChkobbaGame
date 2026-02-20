// lib/core/constants/game_constants.dart

/// Game configuration and rules constants for Chkobba
class GameConstants {
  // ==================== DECK CONFIGURATION ====================

  /// Total number of cards in the deck (40 cards - French suits without 8, 9, 10)
  static const int totalCards = 40;

  /// Number of cards dealt to each player per round
  static const int cardsPerDeal = 3;

  /// Number of cards initially placed on the table
  static const int initialTableCards = 4;

  /// Number of suits in the deck
  static const int numberOfSuits = 4;

  /// Cards per suit
  static const int cardsPerSuit = 10;

  // ==================== CARD VALUES ====================

  /// Ace value
  static const int aceValue = 1;

  /// Queen value
  static const int queenValue = 8;

  /// Jack (Lieutenant) value
  static const int jackValue = 9;

  /// King value
  static const int kingValue = 10;

  /// Minimum card rank (Ace)
  static const int minCardRank = 1;

  /// Maximum card rank (King = 10)
  static const int maxCardRank = 10;

  // ==================== GAME SETUP ====================

  /// Minimum number of players
  static const int minPlayers = 2;

  /// Maximum number of players
  static const int maxPlayers = 4;

  /// Default number of players
  static const int defaultPlayers = 2;

  // ==================== SCORING ====================

  /// Points for having most cards (Carta)
  static const int pointsForMostCards = 1;

  /// Points for having most diamonds (Dinari)
  static const int pointsForMostDiamonds = 1;

  /// Points for capturing 7 of Diamonds
  static const int pointsForSevenOfDiamonds = 1;

  /// Points for having most 7s (Bermila)
  static const int pointsForMostSevens = 1;

  /// Points per Chkobba (table sweep)
  static const int pointsPerChkobba = 1;

  /// Default target score to win
  static const int defaultTargetScore = 21;

  /// Alternative target scores
  static const List<int> availableTargetScores = [11, 21, 31];

  /// Minimum point lead required to win
  static const int minPointLeadToWin = 2;

  // ==================== SPECIAL CARDS ====================

  /// Seven of Diamonds - special scoring card
  static const String sevenOfDiamonds = '7_diamonds';

  /// All seven cards for Bermila scoring
  static const List<int> sevenRanks = [7];

  /// All six cards for Bermila tiebreaker
  static const List<int> sixRanks = [6];

  // ==================== GAME RULES ====================

  /// Whether capture is mandatory when possible
  static const bool captureMandatory = true;

  /// Whether single card match has priority over sum
  static const bool singleMatchPriority = true;

  /// Whether Chkobba can be scored on final move
  static const bool chkobbaOnFinalMove = false;

  /// Whether remaining table cards go to last capturer
  static const bool remainingCardsToLastCapturer = true;

  // ==================== AI CONFIGURATION ====================

  /// AI difficulty levels
  static const String aiEasy = 'easy';
  static const String aiMedium = 'medium';
  static const String aiHard = 'hard';
  static const String aiExpert = 'expert';

  /// Default AI difficulty
  static const String defaultAiDifficulty = aiMedium;

  /// AI thinking delay (milliseconds) for realistic gameplay
  static const int aiThinkingDelay = 1500;

  // ==================== MULTIPLAYER ====================

  /// Room code length
  static const int roomCodeLength = 6;

  /// Maximum room name length
  static const int maxRoomNameLength = 30;

  /// Room inactivity timeout (seconds)
  static const int roomInactivityTimeout = 300; // 5 minutes

  /// Maximum spectators per room
  static const int maxSpectators = 10;

  // ==================== TIMING ====================

  /// Turn timeout (seconds) - 0 means no timeout
  static const int turnTimeout = 60;

  /// Animation duration for card movement (milliseconds)
  static const int cardAnimationDuration = 500;

  /// Animation duration for card flip (milliseconds)
  static const int cardFlipDuration = 300;

  /// Delay before dealing next round (milliseconds)
  static const int dealDelay = 1000;

  /// Score calculation animation duration (milliseconds)
  static const int scoreAnimationDuration = 2000;

  // ==================== CARD SUITS ====================

  /// Hearts suit
  static const String hearts = 'hearts';

  /// Diamonds suit
  static const String diamonds = 'diamonds';

  /// Clubs suit
  static const String clubs = 'clubs';

  /// Spades suit
  static const String spades = 'spades';

  /// All suits
  static const List<String> allSuits = [hearts, diamonds, clubs, spades];

  // ==================== CARD RANKS ====================

  /// All card ranks in the deck
  static const List<int> allRanks = [1, 2, 3, 4, 5, 6, 7, 11, 12, 13];
  // Note: 11 = Jack, 12 = Queen, 13 = King

  /// Face card ranks
  static const List<int> faceCardRanks = [11, 12, 13]; // Jack, Queen, King

  /// Number card ranks
  static const List<int> numberCardRanks = [1, 2, 3, 4, 5, 6, 7];

  // ==================== DISPLAY NAMES ====================

  /// Card rank display names
  static const Map<int, String> rankNames = {
    1: 'Ace',
    2: '2',
    3: '3',
    4: '4',
    5: '5',
    6: '6',
    7: '7',
    11: 'Jack',
    12: 'Queen',
    13: 'King',
  };

  /// Card rank display names (Arabic)
  static const Map<int, String> rankNamesArabic = {
    1: 'آس',
    2: '٢',
    3: '٣',
    4: '٤',
    5: '٥',
    6: '٦',
    7: '٧',
    11: 'ولد',
    12: 'بنت',
    13: 'ملك',
  };

  /// Suit display names
  static const Map<String, String> suitNames = {
    hearts: 'Hearts',
    diamonds: 'Diamonds',
    clubs: 'Clubs',
    spades: 'Spades',
  };

  /// Suit display names (Arabic)
  static const Map<String, String> suitNamesArabic = {
    hearts: 'قلوب',
    diamonds: 'ديناري',
    clubs: 'سباتي',
    spades: 'كبة',
  };

  /// Suit symbols
  static const Map<String, String> suitSymbols = {
    hearts: '♥',
    diamonds: '♦',
    clubs: '♣',
    spades: '♠',
  };

  // ==================== VALIDATION ====================

  /// Check if a rank is valid
  static bool isValidRank(int rank) {
    return allRanks.contains(rank);
  }

  /// Check if a suit is valid
  static bool isValidSuit(String suit) {
    return allSuits.contains(suit);
  }

  /// Check if a target score is valid
  static bool isValidTargetScore(int score) {
    return availableTargetScores.contains(score);
  }

  /// Get card value from rank
  static int getCardValue(int rank) {
    switch (rank) {
      case 1: // Ace
        return aceValue;
      case 11: // Jack
        return jackValue;
      case 12: // Queen
        return queenValue;
      case 13: // King
        return kingValue;
      default:
        return rank; // 2-7 have face value
    }
  }

  /// Get display name for rank
  static String getRankName(int rank, {bool isArabic = false}) {
    return isArabic
        ? (rankNamesArabic[rank] ?? rank.toString())
        : (rankNames[rank] ?? rank.toString());
  }

  /// Get display name for suit
  static String getSuitName(String suit, {bool isArabic = false}) {
    return isArabic
        ? (suitNamesArabic[suit] ?? suit)
        : (suitNames[suit] ?? suit);
  }

  /// Get symbol for suit
  static String getSuitSymbol(String suit) {
    return suitSymbols[suit] ?? '';
  }
}