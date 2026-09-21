import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 一張俚語卡的資料
class SlangEntry {
  final String slang; // 俚語
  final String meaning; // 意思
  final String example; // 英文例句
  final String exampleZh; // 例句中文翻譯

  const SlangEntry({
    required this.slang,
    required this.meaning,
    required this.example,
    required this.exampleZh,
  });
}

/// 第一張卡（先寫死，之後再改成從清單/資料庫讀取）
const todaySlang = SlangEntry(
  slang: 'no cap',
  meaning: '不騙你、說真的（cap 在俚語裡是「說謊」）',
  example: 'This burger is so good, no cap.',
  exampleZh: '這個漢堡超好吃，我不騙你。',
);

/// 學習卡：俚語 + 意思 + 例句 + 「我學會了」按鈕
class SlangCard extends StatefulWidget {
  final SlangEntry entry;

  /// 按下「我學會了」時呼叫，之後在這裡接打卡 / Pop Coins
  final VoidCallback? onLearned;

  const SlangCard({
    super.key,
    this.entry = todaySlang,
    this.onLearned,
  });

  @override
  State<SlangCard> createState() => _SlangCardState();
}

class _SlangCardState extends State<SlangCard> {
  static const _orange = Color(0xFFFF8A3D);
  static const _cream = Color(0xFFFFF5EB);
  static const _brown = Color(0xFF4A2C17);

  bool _learned = false;

  /// 是否已經從手機/瀏覽器儲存空間讀完資料（讀完前先不讓按鈕可按）
  bool _loaded = false;

  /// 儲存用的 key，每張卡各自一個，例如 learned_on_no cap
  /// 內容是「學會的日期」，例如 2026-09-21
  String get _storageKey => 'learned_on_${widget.entry.slang}';

  /// 把今天的日期轉成 yyyy-MM-dd 文字
  String _todayString() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  @override
  void initState() {
    super.initState();
    _loadLearned();
  }

  /// 畫面出現時，讀取「這張卡今天學過了嗎」
  Future<void> _loadLearned() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_storageKey);
    if (!mounted) return;
    setState(() {
      // 只有「存的日期 == 今天」才算學過；隔天就會自動變回沒學過
      _learned = savedDate == _todayString();
      _loaded = true;
    });
  }

  /// 按下「我學會了」：更新畫面、通知外面、把今天日期存起來
  Future<void> _handleLearned() async {
    if (_learned) return;
    setState(() => _learned = true);
    widget.onLearned?.call();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _todayString());
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標籤
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '今日俚語',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _orange,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 俚語
          Text(
            e.slang,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: _brown,
            ),
          ),
          const SizedBox(height: 12),

          // 意思
          Text(
            e.meaning,
            style: const TextStyle(
              fontSize: 17,
              height: 1.4,
              color: _brown,
            ),
          ),
          const SizedBox(height: 20),

          // 例句
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '例句',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _orange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.example,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: _brown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  e.exampleZh,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Color(0xFF8A7565),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 我學會了
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              // 還在讀取資料、或今天已經學會，都不可再按
              onPressed: (!_loaded || _learned) ? null : _handleLearned,
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFFFD9B8),
                disabledForegroundColor: _brown,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: Icon(_learned ? Icons.check_circle : Icons.check),
              label: Text(_learned ? '已學會' : '我學會了'),
            ),
          ),
        ],
      ),
    );
  }
}
