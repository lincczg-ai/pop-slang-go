/// Pop Slang Go! - 年齡分級 / 點數獎勵 / 等級升級 核心邏輯
/// -------------------------------------------------------------
/// 這個檔案示範三個核心行為：
/// 1. calculateAgeAndLevel()  依生日算出年齡與對應學習分級
/// 2. awardDailyLearningCoins() / awardQuizCoins()  獲得點數
/// 3. performDailyCheckIn()  打卡、連續天數計算、等級升級判定

// ------------------------- 資料模型 -------------------------

enum LevelGroup { kids, junior, teenAdult }

extension LevelGroupLabel on LevelGroup {
  String get label {
    switch (this) {
      case LevelGroup.kids:
        return 'KIDS';
      case LevelGroup.junior:
        return 'JUNIOR';
      case LevelGroup.teenAdult:
        return 'TEEN_ADULT';
    }
  }
}

class UserProfile {
  final String userId;
  String name;
  DateTime birthday;
  int age;
  LevelGroup levelGroup;
  int popCoins;
  int totalCoinsEarned;
  int rankLevel;
  String rankTitle;
  int currentStreakDays;
  int longestStreakDays;
  DateTime? lastCheckInDate;
  String? unlockedAvatarFrameId;

  UserProfile({
    required this.userId,
    required this.name,
    required this.birthday,
    required this.age,
    required this.levelGroup,
    this.popCoins = 0,
    this.totalCoinsEarned = 0,
    this.rankLevel = 1,
    this.rankTitle = '俚語新手',
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.lastCheckInDate,
    this.unlockedAvatarFrameId,
  });
}

/// 回傳值物件：一次操作後有哪些副作用發生（方便 UI 顯示彈窗動畫）
class RewardResult {
  final int coinsGained;
  final bool didLevelUp;
  final int? newRankLevel;
  final String? newRankTitle;
  final String? newlyUnlockedFrameId;

  RewardResult({
    required this.coinsGained,
    this.didLevelUp = false,
    this.newRankLevel,
    this.newRankTitle,
    this.newlyUnlockedFrameId,
  });
}

// ------------------------- 1. 年齡與分級 -------------------------

/// 依生日計算年齡（採用「精確足歲」演算法，避免只用年份相減造成誤差）
int calculateAge(DateTime birthday, {DateTime? today}) {
  final now = today ?? DateTime.now();
  int age = now.year - birthday.year;
  final hasHadBirthdayThisYear = (now.month > birthday.month) ||
      (now.month == birthday.month && now.day >= birthday.day);
  if (!hasHadBirthdayThisYear) age -= 1;
  return age;
}

/// 依年齡回傳對應學習分級
/// - KIDS: 0 ~ 6 歲（幼稚園大班以下）
/// - JUNIOR: 7 ~ 12 歲（國小階段）
/// - TEEN_ADULT: 13 歲以上
LevelGroup assignLevelGroup(int age) {
  if (age <= 6) return LevelGroup.kids;
  if (age <= 12) return LevelGroup.junior;
  return LevelGroup.teenAdult;
}

/// Onboarding 時呼叫的整合函式：輸入姓名與生日，直接產生一組新的 UserProfile
UserProfile createUserProfileFromOnboarding({
  required String userId,
  required String name,
  required DateTime birthday,
}) {
  final age = calculateAge(birthday);
  final levelGroup = assignLevelGroup(age);
  return UserProfile(
    userId: userId,
    name: name,
    birthday: birthday,
    age: age,
    levelGroup: levelGroup,
  );
}

// ------------------------- 2. 等級 / 頭像外框對照表 -------------------------

class RankTier {
  final int level;
  final String title;
  final int minTotalCoinsRequired;
  final String? unlocksFrameId;

  const RankTier({
    required this.level,
    required this.title,
    required this.minTotalCoinsRequired,
    this.unlocksFrameId,
  });
}

/// Lv.1 俚語新手 ➡️ Lv.12 頂級羚羊
/// total_coins_earned 為累積歷史總點數（花費點數不會扣除），用來決定等級門檻
const List<RankTier> rankTiers = [
  RankTier(level: 1, title: '俚語新手', minTotalCoinsRequired: 0),
  RankTier(level: 2, title: '單字探索者', minTotalCoinsRequired: 100, unlocksFrameId: 'frame_bronze_wing'),
  RankTier(level: 3, title: '片語小尖兵', minTotalCoinsRequired: 250),
  RankTier(level: 4, title: '俚語小尖兵', minTotalCoinsRequired: 450),
  RankTier(level: 5, title: '口語高手', minTotalCoinsRequired: 700, unlocksFrameId: 'frame_silver_wing'),
  RankTier(level: 6, title: '對話玩家', minTotalCoinsRequired: 1000),
  RankTier(level: 7, title: '流行語獵人', minTotalCoinsRequired: 1400),
  RankTier(level: 8, title: '街頭達人', minTotalCoinsRequired: 1900, unlocksFrameId: 'frame_gold_wing'),
  RankTier(level: 9, title: '俚語大師', minTotalCoinsRequired: 2500),
  RankTier(level: 10, title: '雙語行者', minTotalCoinsRequired: 3200),
  RankTier(level: 11, title: '傳說羚羊', minTotalCoinsRequired: 4000, unlocksFrameId: 'frame_rainbow_wing'),
  RankTier(level: 12, title: '頂級羚羊', minTotalCoinsRequired: 5000, unlocksFrameId: 'frame_legendary_wing'),
];

RankTier _tierForTotalCoins(int totalCoins) {
  RankTier current = rankTiers.first;
  for (final tier in rankTiers) {
    if (totalCoins >= tier.minTotalCoinsRequired) {
      current = tier;
    } else {
      break;
    }
  }
  return current;
}

/// 依目前總點數判斷是否升級，若升級則回傳新的等級資訊（含是否解鎖新外框）
RewardResult _applyLevelUpIfNeeded(UserProfile profile, int coinsGained) {
  final newTier = _tierForTotalCoins(profile.totalCoinsEarned);
  final didLevelUp = newTier.level > profile.rankLevel;

  String? newlyUnlockedFrameId;
  if (didLevelUp) {
    profile.rankLevel = newTier.level;
    profile.rankTitle = newTier.title;
    if (newTier.unlocksFrameId != null) {
      profile.unlockedAvatarFrameId = newTier.unlocksFrameId;
      newlyUnlockedFrameId = newTier.unlocksFrameId;
    }
  }

  return RewardResult(
    coinsGained: coinsGained,
    didLevelUp: didLevelUp,
    newRankLevel: didLevelUp ? newTier.level : null,
    newRankTitle: didLevelUp ? newTier.title : null,
    newlyUnlockedFrameId: newlyUnlockedFrameId,
  );
}

// ------------------------- 3. 點數獎勵邏輯 -------------------------

const int kDailyLearningReward = 5; // 每天完成一個俚語學習
const int kQuizCorrectReward = 10; // 小考答對獎勵

/// 完成一則俚語卡片學習（閱讀/聽語音）後呼叫
RewardResult awardDailyLearningCoins(UserProfile profile) {
  profile.popCoins += kDailyLearningReward;
  profile.totalCoinsEarned += kDailyLearningReward;
  return _applyLevelUpIfNeeded(profile, kDailyLearningReward);
}

/// 完成 Pop Quiz 且答對時呼叫
RewardResult awardQuizCoins(UserProfile profile, {required bool isCorrect}) {
  if (!isCorrect) {
    return RewardResult(coinsGained: 0);
  }
  profile.popCoins += kQuizCorrectReward;
  profile.totalCoinsEarned += kQuizCorrectReward;
  return _applyLevelUpIfNeeded(profile, kQuizCorrectReward);
}

// ------------------------- 4. 每日打卡與連續天數邏輯 -------------------------

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isYesterday(DateTime lastDate, DateTime today) {
  final yesterday = today.subtract(const Duration(days: 1));
  return _isSameDay(lastDate, yesterday);
}

/// 每天使用者打開 App 並完成至少一項學習/測驗時呼叫一次
/// 回傳打卡是否成功（同一天重複打卡會回傳 false，不重複計算天數）
bool performDailyCheckIn(UserProfile profile, {DateTime? today}) {
  final now = today ?? DateTime.now();

  if (profile.lastCheckInDate != null &&
      _isSameDay(profile.lastCheckInDate!, now)) {
    // 今天已經打卡過，不重複累加
    return false;
  }

  if (profile.lastCheckInDate != null &&
      _isYesterday(profile.lastCheckInDate!, now)) {
    profile.currentStreakDays += 1;
  } else {
    // 中斷了，重新從 1 天開始
    profile.currentStreakDays = 1;
  }

  if (profile.currentStreakDays > profile.longestStreakDays) {
    profile.longestStreakDays = profile.currentStreakDays;
  }

  profile.lastCheckInDate = now;
  return true;
}
