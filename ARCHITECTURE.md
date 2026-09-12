# 《Pop Slang Go!》App 架構設計文件

## 1. 整體系統架構

```
┌─────────────────────────────────────────────────────────────┐
│                     Client (Flutter App)                     │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌──────────────┐  │
│  │ Onboarding│ │  Home /   │ │  Quiz /   │ │  Pop Shop /  │  │
│  │  年齡分級  │ │  月曆打卡 │ │  俚語卡片 │ │  頭像商城    │  │
│  └───────────┘ └───────────┘ └───────────┘ └──────────────┘  │
│                State: Riverpod / Bloc (UserProfileProvider)  │
└───────────────────────────┬───────────────────────────────────┘
                             │ REST / GraphQL (HTTPS)
┌───────────────────────────▼───────────────────────────────────┐
│                        Backend (API Layer)                    │
│  AuthService | ContentService | GamificationService | ShopSvc │
└───────────────────────────┬───────────────────────────────────┘
                             │
        ┌────────────────────┼───────────────────────┐
        ▼                    ▼                       ▼
┌───────────────┐   ┌─────────────────┐    ┌────────────────────┐
│  PostgreSQL /  │   │  CDN (音檔/插圖)  │    │  Push Notification │
│  Firestore     │   │  slang audio/img │    │  (每日提醒打卡)     │
│  (核心資料表)   │   │                  │    │                    │
└───────────────┘   └─────────────────┘    └────────────────────┘
```

**核心資料表(Collections / Tables):**
- `user_profile`:使用者基本資料、等級、點數、連續打卡
- `slang_item`:俚語內容庫(依年齡分級)
- `quiz_item`:測驗題庫(與 slang_item 關聯)
- `check_in_record`:每日打卡紀錄(供月曆呈現)
- `shop_item`:商城可兌換商品
- `user_inventory`:使用者已兌換/已解鎖的商品

---

## 2. JSON Schema 設計

### 2.1 `user_profile`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "user_profile",
  "type": "object",
  "properties": {
    "user_id": { "type": "string", "description": "使用者唯一識別碼 (UUID)" },
    "name": { "type": "string", "description": "使用者暱稱" },
    "birthday": { "type": "string", "format": "date", "description": "生日 YYYY-MM-DD" },
    "age": { "type": "integer", "description": "系統依生日自動計算，非使用者輸入" },
    "level_group": {
      "type": "string",
      "enum": ["KIDS", "JUNIOR", "TEEN_ADULT"],
      "description": "依年齡分配的學習分級：KIDS(<=6) / JUNIOR(7-12) / TEEN_ADULT(13+)"
    },
    "pop_coins": { "type": "integer", "default": 0, "description": "累積可用點數" },
    "total_coins_earned": { "type": "integer", "default": 0, "description": "歷史總獲得點數(用於等級計算，不因花費而減少)" },
    "rank_level": { "type": "integer", "minimum": 1, "maximum": 12, "description": "頭像等級 Lv.1 ~ Lv.12" },
    "rank_title": { "type": "string", "description": "例如：俚語新手 / 頂級羚羊" },
    "current_streak_days": { "type": "integer", "default": 0, "description": "目前連續打卡天數" },
    "longest_streak_days": { "type": "integer", "default": 0 },
    "last_check_in_date": { "type": "string", "format": "date" },
    "unlocked_avatar_frame_id": { "type": "string", "description": "目前配戴的翅膀外框商品 id" },
    "unlocked_title_id": { "type": "string", "description": "目前配戴的稱號商品 id" },
    "created_at": { "type": "string", "format": "date-time" }
  },
  "required": ["user_id", "name", "birthday", "age", "level_group", "pop_coins", "rank_level"]
}
```

**範例資料：**
```json
{
  "user_id": "u_1001",
  "name": "小樂",
  "birthday": "2019-05-10",
  "age": 7,
  "level_group": "JUNIOR",
  "pop_coins": 235,
  "total_coins_earned": 890,
  "rank_level": 4,
  "rank_title": "俚語小尖兵",
  "current_streak_days": 12,
  "longest_streak_days": 20,
  "last_check_in_date": "2026-09-12",
  "unlocked_avatar_frame_id": "frame_bronze_wing",
  "unlocked_title_id": "title_word_hunter",
  "created_at": "2026-01-15T08:00:00Z"
}
```

---

### 2.2 `slang_item`（俚語內容庫）

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "slang_item",
  "type": "object",
  "properties": {
    "slang_id": { "type": "string" },
    "phrase": { "type": "string", "description": "俚語原文" },
    "phonetic": { "type": "string", "description": "音標 (IPA)" },
    "meaning_zh": { "type": "string", "description": "中文解釋" },
    "level_group": { "type": "string", "enum": ["KIDS", "JUNIOR", "TEEN_ADULT"] },
    "min_age": { "type": "integer" },
    "max_age": { "type": "integer" },
    "example_sentence_en": { "type": "string" },
    "example_sentence_zh": { "type": "string" },
    "cartoon_image_prompt": { "type": "string", "description": "供圖像生成/插畫師使用的畫面描述 prompt" },
    "audio_tag": { "type": "string", "description": "音檔資源代碼，對應 CDN 上的音檔檔名" },
    "difficulty": { "type": "integer", "minimum": 1, "maximum": 5 },
    "daily_reward_coins": { "type": "integer", "default": 5 }
  },
  "required": ["slang_id", "phrase", "meaning_zh", "level_group", "min_age", "max_age"]
}
```

**4 個示範項目：**
```json
[
  {
    "slang_id": "sl_0001",
    "phrase": "a piece of cake",
    "phonetic": "/ə piːs ʌv keɪk/",
    "meaning_zh": "小事一樁、非常簡單",
    "level_group": "KIDS",
    "min_age": 3,
    "max_age": 6,
    "example_sentence_en": "Don't worry, this puzzle is a piece of cake!",
    "example_sentence_zh": "別擔心，這個拼圖超簡單的！",
    "cartoon_image_prompt": "一隻可愛小熊輕鬆地用一根手指舉起一整塊生日蛋糕，背景有星星特效，色彩鮮豔童趣",
    "audio_tag": "audio_piece_of_cake_en",
    "difficulty": 1,
    "daily_reward_coins": 5
  },
  {
    "slang_id": "sl_0002",
    "phrase": "hold your horses",
    "phonetic": "/hoʊld jʊər ˈhɔːrsɪz/",
    "meaning_zh": "等一下、別急",
    "level_group": "KIDS",
    "min_age": 3,
    "max_age": 6,
    "example_sentence_en": "Hold your horses! We haven't finished breakfast yet.",
    "example_sentence_zh": "等一下啦！我們早餐都還沒吃完呢。",
    "cartoon_image_prompt": "一個小男孩想衝出門，被一隻卡通小馬用韁繩溫柔拉住，畫面活潑逗趣",
    "audio_tag": "audio_hold_your_horses_en",
    "difficulty": 1,
    "daily_reward_coins": 5
  },
  {
    "slang_id": "sl_0003",
    "phrase": "couch potato",
    "phonetic": "/kaʊtʃ pəˈteɪtoʊ/",
    "meaning_zh": "整天窩在沙發看電視的懶骨頭",
    "level_group": "JUNIOR",
    "min_age": 7,
    "max_age": 12,
    "example_sentence_en": "My brother is such a couch potato on weekends.",
    "example_sentence_zh": "我哥哥週末根本是個沙發馬鈴薯，整天賴著不動。",
    "cartoon_image_prompt": "一顆長出手腳的馬鈴薯癱在沙發上拿著遙控器，旁邊放滿洋芋片，畫風可愛擬人化",
    "audio_tag": "audio_couch_potato_en",
    "difficulty": 2,
    "daily_reward_coins": 5
  },
  {
    "slang_id": "sl_0004",
    "phrase": "boy do I let it rip!",
    "phonetic": "/bɔɪ duː aɪ lɛt ɪt rɪp/",
    "meaning_zh": "（口語）表示自己會盡情發揮、火力全開去做某件事",
    "level_group": "TEEN_ADULT",
    "min_age": 13,
    "max_age": 99,
    "example_sentence_en": "When I get on the dance floor, boy do I let it rip!",
    "example_sentence_zh": "只要我一站上舞池，我可是會火力全開盡情跳舞的！",
    "cartoon_image_prompt": "一位青少年戴著耳機在舞池中央盡情跳舞，周圍有動感光暈與音符特效，街頭潮流風格",
    "audio_tag": "audio_let_it_rip_en",
    "difficulty": 4,
    "daily_reward_coins": 5
  }
]
```

---

### 2.3 `quiz_item`（測驗題庫）

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "quiz_item",
  "type": "object",
  "properties": {
    "quiz_id": { "type": "string" },
    "slang_id": { "type": "string", "description": "關聯的 slang_item.slang_id" },
    "quiz_type": { "type": "string", "enum": ["CONTEXT_CHOICE", "LISTEN_AND_PICK_IMAGE"] },
    "question_text": { "type": "string" },
    "question_audio_tag": { "type": "string", "description": "若為聽音選圖題型使用" },
    "options": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "option_id": { "type": "string" },
          "text": { "type": "string" },
          "image_tag": { "type": "string" }
        }
      },
      "minItems": 2,
      "maxItems": 4
    },
    "correct_option_id": { "type": "string" },
    "reward_coins": { "type": "integer", "default": 10 }
  },
  "required": ["quiz_id", "slang_id", "quiz_type", "options", "correct_option_id"]
}
```

**範例資料：**
```json
{
  "quiz_id": "qz_0001",
  "slang_id": "sl_0003",
  "quiz_type": "CONTEXT_CHOICE",
  "question_text": "小明整個週末都窩在沙發上打電動看電視，你會怎麼形容他？",
  "options": [
    { "option_id": "a", "text": "He is a couch potato." },
    { "option_id": "b", "text": "He is a piece of cake." },
    { "option_id": "c", "text": "He is holding his horses." }
  ],
  "correct_option_id": "a",
  "reward_coins": 10
}
```

---

### 2.4 `shop_item`（點數商城）

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "shop_item",
  "type": "object",
  "properties": {
    "item_id": { "type": "string" },
    "type": { "type": "string", "enum": ["avatar_frame", "title", "monster_card"] },
    "name": { "type": "string" },
    "description": { "type": "string" },
    "price_coins": { "type": "integer" },
    "rarity": { "type": "string", "enum": ["common", "rare", "epic", "legendary"] },
    "image_asset": { "type": "string" },
    "min_rank_level_required": { "type": "integer", "description": "需達到的頭像等級才能購買，可選" }
  },
  "required": ["item_id", "type", "name", "price_coins", "rarity"]
}
```

**範例資料：**
```json
[
  {
    "item_id": "frame_bronze_wing",
    "type": "avatar_frame",
    "name": "青銅羽翼外框",
    "description": "初階翅膀外框，象徵你的俚語旅程正式起飛",
    "price_coins": 100,
    "rarity": "common",
    "image_asset": "frame_bronze_wing.png",
    "min_rank_level_required": 2
  },
  {
    "item_id": "title_word_hunter",
    "type": "title",
    "name": "單字獵人",
    "description": "專屬稱號，展示在個人檔案旁",
    "price_coins": 150,
    "rarity": "rare",
    "image_asset": "title_word_hunter.png"
  },
  {
    "item_id": "monster_slangzilla",
    "type": "monster_card",
    "name": "俚語哥吉拉 Slangzilla",
    "description": "稀有俚語怪獸卡，收集全套可解鎖隱藏動畫",
    "price_coins": 500,
    "rarity": "legendary",
    "image_asset": "monster_slangzilla.png",
    "min_rank_level_required": 8
  }
]
```
