import 'package:flutter/material.dart';
import 'gamification_logic.dart';

/// 《Pop Slang Go!》主頁面雛型
/// 包含：
/// 1. 頭像 + 翅膀外框 + 等級稱號
/// 2. Pop Coins 點數顯示
/// 3. 月曆打卡概況（本月每日是否完成學習）
/// 4. 「開始今日俚語」「開始小考」兩大 CTA 按鈕

class HomeScreen extends StatelessWidget {
  final UserProfile profile;

  /// key: 該月第幾天 (1-31), value: 當天完成的俚語卡片數
  final Map<int, int> monthlyCheckInData;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.monthlyCheckInData,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildAvatarAndRankCard(),
              const SizedBox(height: 20),
              _buildCoinCard(),
              const SizedBox(height: 24),
              _buildCalendarCard(daysInMonth),
              const SizedBox(height: 28),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hi, ${profile.name}! 👋',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3E2C1C)),
        ),
        IconButton(
          icon: const Icon(Icons.storefront_rounded, color: Color(0xFFFF8A3D)),
          iconSize: 30,
          tooltip: 'Pop Shop',
          onPressed: () {
            // TODO: Navigator.push(context, MaterialPageRoute(builder: (_) => PopShopScreen()));
          },
        ),
      ],
    );
  }

  // ---------------- 頭像 + 翅膀外框 + 等級 ----------------

  Widget _buildAvatarAndRankCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD9A0), Color(0xFFFFB86B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          _buildAvatarWithFrame(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lv.${profile.rankLevel}  ${profile.rankTitle}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E2C1C)),
                ),
                const SizedBox(height: 6),
                _buildStreakBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 頭像本體 + 依 unlockedAvatarFrameId 疊加的翅膀外框特效
  Widget _buildAvatarWithFrame() {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 翅膀外框（依解鎖等級變化顏色，實際專案改成對應圖片資源）
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _frameColorForLevel(profile.rankLevel), width: 4),
              boxShadow: [
                BoxShadow(color: _frameColorForLevel(profile.rankLevel).withOpacity(0.6), blurRadius: 10),
              ],
            ),
          ),
          // 頭像本體
          const CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFFFF1DC),
            child: Icon(Icons.emoji_emotions, size: 38, color: Color(0xFFFF8A3D)),
          ),
        ],
      ),
    );
  }

  Color _frameColorForLevel(int level) {
    if (level >= 11) return const Color(0xFFB388FF); // 傳說/頂級：夢幻紫
    if (level >= 8) return const Color(0xFFFFD700); // 黃金
    if (level >= 5) return const Color(0xFFC0C0C0); // 銀
    if (level >= 2) return const Color(0xFFCD7F32); // 青銅
    return const Color(0xFFEEA37A); // 初始
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, size: 16, color: Colors.deepOrange),
          const SizedBox(width: 4),
          Text('連續打卡 ${profile.currentStreakDays} 天',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3E2C1C))),
        ],
      ),
    );
  }

  // ---------------- Pop Coins ----------------

  Widget _buildCoinCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 30),
          const SizedBox(width: 10),
          Text('${profile.popCoins}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          const Text('Pop Coins', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              // TODO: 前往 Pop Shop
            },
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('前往商城'),
          ),
        ],
      ),
    );
  }

  // ---------------- 月曆打卡概況 ----------------

  Widget _buildCalendarCard(int daysInMonth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('本月學習打卡', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final day = index + 1;
              final cardsLearned = monthlyCheckInData[day] ?? 0;
              return _buildDayCell(day, cardsLearned);
            },
          ),
          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day, int cardsLearned) {
    final Color bgColor = cardsLearned == 0
        ? const Color(0xFFF0F0F0)
        : cardsLearned == 1
            ? const Color(0xFFFFD9A0)
            : cardsLearned <= 3
                ? const Color(0xFFFFB86B)
                : const Color(0xFFFF7A1A);

    final bool isToday = day == DateTime.now().day;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: Colors.deepOrange, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cardsLearned > 1 ? Colors.white : const Color(0xFF3E2C1C),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    Widget dot(Color c) => Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
    return Row(
      children: [
        dot(const Color(0xFFF0F0F0)), const SizedBox(width: 4), const Text('未打卡', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 12),
        dot(const Color(0xFFFFD9A0)), const SizedBox(width: 4), const Text('1 卡', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 12),
        dot(const Color(0xFFFF7A1A)), const SizedBox(width: 4), const Text('4+ 卡', style: TextStyle(fontSize: 11)),
      ],
    );
  }

  // ---------------- CTA 按鈕 ----------------

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A3D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              // TODO: Navigator.push -> SlangCardScreen（今日俚語卡片）
            },
            icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
            label: const Text('開始今日俚語', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF8A3D), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              // TODO: Navigator.push -> PopQuizScreen（今日小考）
            },
            icon: const Icon(Icons.quiz_rounded, color: Color(0xFFFF8A3D)),
            label: const Text('開始小考 Pop Quiz', style: TextStyle(fontSize: 16, color: Color(0xFFFF8A3D), fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
