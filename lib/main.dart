import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const TKPEnglishLearningApp());
}

class TKPEnglishLearningApp extends StatelessWidget {
  const TKPEnglishLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TKP 英語學習系統',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F3057)),
        useMaterial3: true,
      ),
      home: const MainDashboardScreen(),
    );
  }
}

// ---------------- 數據結構 ----------------
class WordItem {
  final String word;
  final String phonetic;
  final String pos;
  final String meaning;
  final String example;
  final String unit;

  WordItem({
    required this.word,
    required this.phonetic,
    required this.pos,
    required this.meaning,
    required this.example,
    required this.unit,
  });
}

// 鄧鏡波中學 校本單元詞庫（示例 Unit 1 學校與學習、Unit 2 科技與創新）
final List<WordItem> tkpWordBank = [
  WordItem(
    word: "perseverance",
    phonetic: "/ˌpɜːsɪˈvɪərəns/",
    pos: "n.",
    meaning: "堅持不懈、毅力",
    example: "With perseverance, students overcome HKDSE challenges.",
    unit: "Unit 1: Campus Life",
  ),
  WordItem(
    word: "diligent",
    phonetic: "/ˈdɪlɪdʒənt/",
    pos: "adj.",
    meaning: "勤奮的",
    example: "Diligent revision leads to excellent academic results.",
    unit: "Unit 1: Campus Life",
  ),
  WordItem(
    word: "innovative",
    phonetic: "/ˈɪnəveɪtɪv/",
    pos: "adj.",
    meaning: "創新的、革新的",
    example: "The school encourages innovative STEM projects.",
    unit: "Unit 2: Science & Tech",
  ),
  WordItem(
    word: "sustainable",
    phonetic: "/səˈsteɪnəbl/",
    pos: "adj.",
    meaning: "可持續的、環保的",
    example: "We must adopt sustainable lifestyles to protect the Earth.",
    unit: "Unit 2: Science & Tech",
  ),
];

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const VocabSpellingScreen(),
    const ListeningTestScreen(),
    const ReadingCompScreen(),
    const DSEWritingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.school), label: '詞彙與拼讀'),
          NavigationDestination(icon: Icon(Icons.hearing), label: '聽力測試'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: '閱讀理解'),
          NavigationDestination(icon: Icon(Icons.edit_document), label: 'DSE小作文'),
        ],
      ),
    );
  }
}

// ==========================================
// 模組一：詞彙練習、5遍複讀拼寫與美音發音評測
// ==========================================
class VocabSpellingScreen extends StatefulWidget {
  const VocabSpellingScreen({super.key});

  @override
  State<VocabSpellingScreen> createState() => _VocabSpellingScreenState();
}

class _VocabSpellingScreenState extends State<VocabSpellingScreen> {
  String selectedUnit = "Unit 1: Campus Life";
  int wordIdx = 0;
  int repetitionCount = 0; // 5遍複讀計數器
  final TextEditing4Controller = TextEditingController();
  final FlutterTts tts = FlutterTts();
  late stt.SpeechToText speech;
  bool isListening = false;
  String speechFeedback = "點擊麥克風進行美音發音評估";
  int speechScore = 0;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
  }

  // 原生英音朗讀示範
  void playBritishAudio(String text) async {
    await tts.setLanguage("en-GB");
    await tts.setSpeechRate(0.45);
    await tts.speak(text);
  }

  // 美式英語發音評估 (en-US)
  void evaluatePronunciation(String targetWord) async {
    bool available = await speech.initialize();
    if (available) {
      setState(() => isListening = true);
      speech.listen(
        localeId: "en_US", // 依要求指定美式英語發音
        onResult: (val) {
          String spoken = val.recognizedWords.trim().toLowerCase();
          if (spoken.isNotEmpty) {
            setState(() {
              isListening = false;
              int score = calculateSimilarity(targetWord.toLowerCase(), spoken);
              speechScore = score;
              if (score >= 85) {
                speechFeedback = "🌟 美音極其標準！(得分: $score分 - 辨識為: $spoken)";
              } else if (score >= 60) {
                speechFeedback = "👍 發音尚可，請注意元音 (得分: $score分 - 辨識為: $spoken)";
              } else {
                speechFeedback = "⚠️ 發音有偏差，請跟讀重試 (得分: $score分 - 辨識為: $spoken)";
              }
            });
          }
        },
      );
    }
  }

  // 相似度算法 (Levenshtein Distance 轉百分比)
  int calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 100;
    int maxLen = s1.length > s2.length ? s1.length : s2.length;
    int matches = 0;
    for (int i = 0; i < (s1.length < s2.length ? s1.length : s2.length); i++) {
      if (s1[i] == s2[i]) matches++;
    }
    return ((matches / maxLen) * 100).toInt();
  }

  void checkSpelling() {
    final currentWord = getFilteredWords()[wordIdx];
    if (TextEditing4Controller.text.trim().toLowerCase() == currentWord.word.toLowerCase()) {
      setState(() {
        repetitionCount++;
        TextEditing4Controller.clear();
      });
      if (repetitionCount >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 太棒了！已達成 5 遍複讀拼寫強化！"), backgroundColor: Colors.green),
        );
        setState(() {
          repetitionCount = 0;
          if (wordIdx < getFilteredWords().length - 1) wordIdx++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("正確！請繼續完成第 ${repetitionCount + 1}/5 遍拼寫"), backgroundColor: Colors.blue),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("拼寫有誤，請再聽一次！"), backgroundColor: Colors.redAccent),
      );
    }
  }

  List<WordItem> getFilteredWords() {
    return tkpWordBank.where((w) => w.unit == selectedUnit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final words = getFilteredWords();
    final item = words[wordIdx];

    return Scaffold(
      appBar: AppBar(
        title: const Text("TKP 校本詞彙與拼讀"),
        backgroundColor: const Color(0xFF0F3057),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 單元切換選單
            DropdownButtonFormField<String>(
              value: selectedUnit,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "教材單元選擇"),
              items: ["Unit 1: Campus Life", "Unit 2: Science & Tech"]
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => setState(() {
                selectedUnit = v!;
                wordIdx = 0;
                repetitionCount = 0;
              }),
            ),
            const SizedBox(height: 16),

            // 單詞學習卡片
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.word, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F3057))),
                        IconButton(icon: const Icon(Icons.volume_up, color: Colors.blue), onPressed: () => playBritishAudio(item.word)),
                      ],
                    ),
                    Text("${item.pos}  ${item.phonetic}", style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(item.meaning, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const Divider(height: 24),
                    Text("例句: ${item.example}", style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5 遍複讀拼寫區塊
            Card(
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text("🔁 5 遍強化拼寫（當前進度: $repetitionCount / 5）", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: TextEditing4Controller,
                      decoration: InputDecoration(
                        hintText: "請輸入單詞拼寫 (首字母提示: ${item.word[0]}...)",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(icon: const Icon(Icons.check), onPressed: checkSpelling),
                      ),
                      onSubmitted: (_) => checkSpelling(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 美式發音評估區塊
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("🎙️ 美式英語 (en-US) 發音標準度檢測", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: isListening ? Colors.red : const Color(0xFF0F3057), foregroundColor: Colors.white),
                      onPressed: () => evaluatePronunciation(item.word),
                      icon: Icon(isListening ? Icons.mic_off : Icons.mic),
                      label: Text(isListening ? "正在傾聽發音..." : "按住開口發音"),
                    ),
                    const SizedBox(height: 10),
                    Text(speechFeedback, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 模組二：聽力測試（原生英音 TTS + 選擇題）
// ==========================================
class ListeningTestScreen extends StatefulWidget {
  const ListeningTestScreen({super.key});

  @override
  State<ListeningTestScreen> createState() => _ListeningTestScreenState();
}

class _ListeningTestScreenState extends State<ListeningTestScreen> {
  final FlutterTts tts = FlutterTts();
  int selectedOption = -1;

  void playBritishAudio(String text) async {
    await tts.setLanguage("en-GB");
    await tts.setSpeechRate(0.40); // 聽力測驗標準清晰語速
    await tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("聽力測試 (原生英音)"), backgroundColor: const Color(0xFF0F3057), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("題目 1: 聽詞選義", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => playBritishAudio("perseverance"),
                icon: const Icon(Icons.play_circle_fill),
                label: const Text("播放英音單詞朗讀"),
              ),
            ),
            const SizedBox(height: 16),
            ...[
              "A. 堅持不懈、毅力",
              "B. 勤勉謹慎",
              "C. 環保的可持續性",
              "D. 科技創新"
            ].asMap().entries.map((entry) => RadioListTile<int>(
              value: entry.key,
              groupValue: selectedOption,
              title: Text(entry.value),
              onChanged: (val) {
                setState(() => selectedOption = val!);
                if (val == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("回答正確！")));
                }
              },
            )),
            const Divider(height: 32),
            const Text("題目 2: 聽對話理解題", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => playBritishAudio("Boy: Have you finished the STEM project? Girl: Not yet, but with perseverance we will complete it today."),
              icon: const Icon(Icons.volume_up),
              label: const Text("播放短對話錄音"),
            ),
            const SizedBox(height: 8),
            const Text("問: What is needed to finish the project?"),
            const Text("(A) Money  (B) Perseverance  (C) More tools", style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 模組三：閱讀理解（校本主題 + 點擊查生詞）
// ==========================================
class ReadingCompScreen extends StatelessWidget {
  const ReadingCompScreen({super.key});

  final String passage =
      "At Tang King Po School, students are encouraged to remain diligent even when encountering difficult modules. "
      "Academic excellence is not achieved overnight; rather, it requires extraordinary perseverance. "
      "Furthermore, the new science syllabus guides pupils to create innovative and sustainable solutions for modern society.";

  void showWordDefinition(BuildContext context, String rawWord) {
    String cleaned = rawWord.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    WordItem? match = tkpWordBank.firstWhere(
      (w) => w.word.toLowerCase() == cleaned,
      orElse: () => WordItem(word: cleaned, phonetic: "-", pos: "詞彙", meaning: "日常英語單詞", example: "-", unit: "-"),
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(match.word, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F3057))),
            Text("${match.pos}  ${match.phonetic}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text("釋義：${match.meaning}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text("教材例句：${match.example}", style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> words = passage.split(" ");

    return Scaffold(
      appBar: AppBar(title: const Text("校本主題閱讀理解"), backgroundColor: const Color(0xFF0F3057), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📖 篇章：Campus Life & STEM (點擊藍色單詞查釋義)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Wrap(
                spacing: 4,
                children: words.map((w) {
                  bool isTarget = tkpWordBank.any((t) => w.toLowerCase().contains(t.word.toLowerCase()));
                  return GestureDetector(
                    onTap: () => showWordDefinition(context, w),
                    child: Text(
                      "$w ",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: isTarget ? Colors.blue.shade800 : Colors.black87,
                        fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
                        decoration: isTarget ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Text("閱讀理解題：", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("1. What two qualities are emphasized in the passage?"),
            const Text("答：Diligence and perseverance.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 模組四：DSE 微寫作（關鍵詞偵測與字數統計）
// ==========================================
class DSEWritingScreen extends StatefulWidget {
  const DSEWritingScreen({super.key});

  @override
  State<DSEWritingScreen> createState() => _DSEWritingScreenState();
}

class _DSEWritingScreenState extends State<DSEWritingScreen> {
  String selectedGenre = "Email to the Principal";
  final TextEditingController essayController = TextEditingController();
  final List<String> requiredKeywords = ["diligent", "perseverance", "innovative", "sustainable"];
  int currentWordCount = 0;

  void onTextChanged(String text) {
    List<String> words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    setState(() {
      currentWordCount = words.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DSE 實用文微寫作訓練"), backgroundColor: const Color(0xFF0F3057), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedGenre,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "DSE 寫作文體"),
              items: ["Email to the Principal", "Letter to the Editor", "Diary Entry", "Proposal"]
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => selectedGenre = v!),
            ),
            const SizedBox(height: 12),
            const Text("📝 寫作題目：Write a short proposal (60-100 words) on how our school can build a better learning atmosphere.", style: TextStyle(color: Colors.black87)),
            const SizedBox(height: 10),

            // 關鍵字檢測看板
            const Text("必備指定詞彙偵測 (至少使用 3 個):", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: requiredKeywords.map((kw) {
                bool used = essayController.text.toLowerCase().contains(kw.toLowerCase());
                return Chip(
                  avatar: Icon(used ? Icons.check_circle : Icons.radio_button_unchecked, color: used ? Colors.white : Colors.grey, size: 18),
                  label: Text(kw),
                  backgroundColor: used ? Colors.green : Colors.grey.shade200,
                  labelStyle: TextStyle(color: used ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: essayController,
              maxLines: 8,
              onChanged: onTextChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "在此輸入短文...",
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("字數統計: $currentWordCount 字 (目標: 60-100 字)", style: TextStyle(fontWeight: FontWeight.bold, color: currentWordCount >= 60 && currentWordCount <= 100 ? Colors.green : Colors.orange)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F3057), foregroundColor: Colors.white),
                  onPressed: () {
                    int usedCount = requiredKeywords.where((k) => essayController.text.toLowerCase().contains(k)).length;
                    if (usedCount >= 3 && currentWordCount >= 60) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎉 寫作符合要求！成功覆蓋核心詞彙且字數達標！"), backgroundColor: Colors.green));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("需至少包含 3 個指定詞 (目前: $usedCount) 且字數達 60 字！"), backgroundColor: Colors.redAccent));
                    }
                  },
                  child: const Text("提交評估"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
