import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const TKPEnglishApp());
}

class TKPEnglishApp extends StatelessWidget {
  const TKPEnglishApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TKP English System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// 數據統計管理模型
class LearningStats {
  static int wordsLearned = 0;
  static int spellingSuccessCount = 0;
  static int listeningCompleted = 0;
  static double totalPronunciationScore = 0.0;
  static int pronunciationAttempts = 0;
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const VocabPracticeScreen(),
    const ListeningScreen(),
    const ReadingScreen(),
    const StatsSummaryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.spellcheck), label: '詞彙與拼讀'),
          NavigationDestination(icon: Icon(Icons.headphones), label: '聽力對話'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'DSE閱讀'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '學習小結與統計'),
        ],
      ),
    );
  }
}

/* ========================================================
 * 1. 詞彙與拼讀模組（TKP 校本教材）
 * ======================================================== */
class VocabPracticeScreen extends StatefulWidget {
  const VocabPracticeScreen({Key? key}) : super(key: key);

  @override
  State<VocabPracticeScreen> createState() => _VocabPracticeScreenState();
}

class _VocabPracticeScreenState extends State<VocabPracticeScreen> {
  final FlutterTts _tts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = '';
  String _evalResult = '按住麥克風並清晰朗讀單詞進行評測';
  int _spellingStep = 1;
  final TextEditingController _spellController = TextEditingController();

  final List<Map<String, String>> tkpVocabList = [
    {
      'word': 'perseverance',
      'phonetic': '/ˌpɜːsɪˈvɪərəns/',
      'meaning': '堅持不懈 (鄧鏡波學校慈幼會核心德育價值)',
      'unit': 'TKP Unit 1: School Spirit & Core Values'
    },
    {
      'word': 'benevolence',
      'phonetic': '/bəˈnevələns/',
      'meaning': '仁愛、仁慈 (Salesian Preventive System)',
      'unit': 'TKP Unit 1: School Spirit & Core Values'
    },
    {
      'word': 'sustainability',
      'phonetic': '/səˌsteɪnəˈbɪləti/',
      'meaning': '可持續發展 (HKDSE 跨學科常考詞)',
      'unit': 'TKP Unit 2: Hong Kong Urban Development'
    },
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.45); // 適合學習的慢速
  }

  void _speak(String word) async {
    await _tts.stop();
    await _tts.speak(word);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            _evaluatePronunciation();
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _spokenText = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _evaluatePronunciation();
    }
  }

  void _evaluatePronunciation() {
    String target = tkpVocabList[_currentIndex]['word']!.toLowerCase();
    String spoken = _spokenText.trim().toLowerCase();
    LearningStats.pronunciationAttempts++;
    if (spoken == target) {
      LearningStats.totalPronunciationScore += 100;
      setState(() => _evalResult = '🌟 發音優秀！精確匹配美式標準音 (100分)');
    } else if (spoken.isNotEmpty && target.contains(spoken)) {
      LearningStats.totalPronunciationScore += 75;
      setState(() => _evalResult = '👍 發音尚可 ($spoken)，請更注意音節清晰度 (75分)');
    } else {
      LearningStats.totalPronunciationScore += 50;
      setState(() => _evalResult = '⚠️ 識別為: "$spoken"，請點擊喇叭多聽一遍重試');
    }
  }

  void _checkSpelling() {
    String target = tkpVocabList[_currentIndex]['word']!;
    if (_spellController.text.trim().toLowerCase() == target.toLowerCase()) {
      if (_spellingStep < 5) {
        setState(() {
          _spellingStep++;
          _spellController.clear();
        });
      } else {
        LearningStats.spellingSuccessCount++;
        LearningStats.wordsLearned++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 恭喜！已完成 5 遍拼讀強化循環，單詞已掌握！')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('拼寫有誤，請對照單詞重新輸入')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var cur = tkpVocabList[_currentIndex];
    return Scaffold(
      appBar: AppBar(title: const Text('TKP 鄧鏡波學校 - 詞彙拼讀')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(cur['unit']!, style: const TextStyle(color: Colors.indigo, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cur['word']!,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: Colors.indigo, size: 30),
                          onPressed: () => _speak(cur['word']!),
                        ),
                      ],
                    ),
                    Text(cur['phonetic']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(cur['meaning']!, style: const TextStyle(fontSize: 16)),
                    const Divider(height: 30),
                    // 發音評測區塊
                    Text(_evalResult, style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _listen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening ? Colors.red : Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      label: Text(_isListening ? '正在聆聽...點擊停止' : '按此開口發音 (評測)'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 5 遍拼讀循環
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('5 遍記憶強化拼讀 [當前進度: 步驟 $_spellingStep / 5]',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _spellingStep / 5),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _spellController,
                      decoration: InputDecoration(
                        hintText: _spellingStep <= 2 ? '提示輸入: ${cur['word']}' : '請盲打盲拼單詞...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(onPressed: _checkSpelling, child: const Text('核對拼寫')),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentIndex = (_currentIndex + 1) % tkpVocabList.length;
                              _spellingStep = 1;
                              _spellController.clear();
                              _evalResult = '按住麥克風並清晰朗讀單詞進行評測';
                            });
                          },
                          child: const Text('下一個詞彙 ➔'),
                        )
                      ],
                    ),
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

/* ========================================================
 * 2. 聽力與對話模組（修復音訊播放與按鈕無響應）
 * ======================================================== */
class ListeningScreen extends StatefulWidget {
  const ListeningScreen({Key? key}) : super(key: key);

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final FlutterTts _tts = FlutterTts();
  String _listeningFeedback = '';

  @override
  void initState() {
    super.initState();
    _setupAudio();
  }

  void _setupAudio() async {
    await _tts.setLanguage('en-GB'); // 英式發音（匹配 HKDSE 聽力考評標準）
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.48);
  }

  void _playTTS(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TKP 聽力練習 (DSE Paper 3 模組)')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 題目 1
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('【題目 1】單詞音節與重音識別',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _playTTS('benevolence'),
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('播放單詞朗讀 (UK 核心標準音)'),
                  ),
                  const SizedBox(height: 12),
                  const Text('問題: 請問你聽到的單詞重音在第幾個音節？'),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          LearningStats.listeningCompleted++;
                          setState(() => _listeningFeedback = '題目1：回答正確！重音在第二音節 /bəˈnevələns/');
                        },
                        child: const Text('第二音節'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => setState(() => _listeningFeedback = '題目1：回答錯誤，請多聽一次重音起伏'),
                        child: const Text('第一音節'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 題目 2
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('【題目 2】校園生活短對話錄音',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _playTTS(
                      'Good morning Kelvin. Are you participating in the Tang King Po School annual sports day this Friday? Yes, I will be competing in the 400-meter relay race.',
                    ),
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('播放短對話錄音 (TKP 校園實境)'),
                  ),
                  const SizedBox(height: 12),
                  const Text('問題: What will Kelvin do this Friday?'),
                  ElevatedButton(
                    onPressed: () {
                      LearningStats.listeningCompleted++;
                      setState(() => _listeningFeedback = '題目2：回答正確！參加 400米接力賽 (400-meter relay)');
                    },
                    child: const Text('Compete in relay race'),
                  ),
                ],
              ),
            ),
          ),
          if (_listeningFeedback.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  _listeningFeedback,
                  style: const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* ========================================================
 * 3. 閱讀與生詞點查模組（TKP 慈幼校園專題）
 * ======================================================== */
class ReadingScreen extends StatelessWidget {
  const ReadingScreen({Key? key}) : super(key: key);

  void _showDef(BuildContext context, String word, String def) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(word, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            Text(def, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TKP 閱讀訓練 (點擊生詞點查)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                const Text('At', style: TextStyle(fontSize: 18)),
                ActionChip(
                  label: const Text('Tang King Po School'),
                  backgroundColor: Colors.indigo.shade50,
                  onPressed: () => _showDef(context, 'Tang King Po School', '香港鄧鏡波學校：由慈幼會創辦於九龍靠背壟道的天主教男子中學。'),
                ),
                const Text(', students are encouraged to display', style: TextStyle(fontSize: 18)),
                ActionChip(
                  label: const Text('perseverance'),
                  onPressed: () => _showDef(context, 'perseverance', '堅持、不屈不撓的精神，慈幼會培育的核心價值。'),
                ),
                const Text('and cultivate mutual', style: TextStyle(fontSize: 18)),
                ActionChip(
                  label: const Text('benevolence'),
                  onPressed: () => _showDef(context, 'benevolence', '慈愛與仁善，指關懷社會與同儕之品德。'),
                ),
                const Text('in every academic pursuit.', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================================================
 * 4. 學習小結與效果統計儀表板（補齊統計面板）
 * ======================================================== */
class StatsSummaryScreen extends StatelessWidget {
  const StatsSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double avgScore = LearningStats.pronunciationAttempts == 0
        ? 0.0
        : (LearningStats.totalPronunciationScore / LearningStats.pronunciationAttempts);

    return Scaffold(
      appBar: AppBar(title: const Text('學習小結與效果統計')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: Colors.indigo,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('鄧鏡波學校英語能力掌握總評', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(
                    '${(avgScore * 0.4 + LearningStats.spellingSuccessCount * 12).clamp(0, 100).toStringAsFixed(1)} 分',
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const Text('DSE 銜接水平評等：持續進步中', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('詳細訓練數據小結', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.white,
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('已掌握 5 遍拼讀詞彙數'),
            trailing: Text('${LearningStats.spellingSuccessCount} 個', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ListTile(
            tileColor: Colors.white,
            leading: const Icon(Icons.record_voice_over, color: Colors.indigo),
            title: const Text('口語發音評測平均分'),
            trailing: Text('${avgScore.toStringAsFixed(1)} 分', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ListTile(
            tileColor: Colors.white,
            leading: const Icon(Icons.hearing, color: Colors.orange),
            title: const Text('完成聽力理解測驗數'),
            trailing: Text('${LearningStats.listeningCompleted} 題', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('本週學習小結建議', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('• 詞彙掌握：慈幼核心詞彙拼讀達標，建議加強多音節重音。\n• 聽力表現：短對話抓取資訊準確，建議維持每日 10 分鐘 UK 標準音頻磨耳朵習慣。'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
