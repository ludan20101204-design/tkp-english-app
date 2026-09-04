import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const TKPS3EnglishApp());
}

class TKPS3EnglishApp extends StatelessWidget {
  const TKPS3EnglishApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TKP S3 English Bridge to DSE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B365D), // 鄧鏡波學校深海藍代表色
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
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
    const S3VocabPracticeScreen(),
    const S3ListeningScreen(),
    const S3ReadingScreen(),
    const S3StatsSummaryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.spellcheck), label: 'S3 核心詞彙'),
          NavigationDestination(icon: Icon(Icons.headphones), label: 'DSE Paper 3 聽力'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'S3 專題閱讀'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '學習小結與統計'),
        ],
      ),
    );
  }
}

/* ========================================================
 * 1. S3 核心詞彙與 5 步拼讀（初中升高中關鍵字）
 * ======================================================== */
class S3VocabPracticeScreen extends StatefulWidget {
  const S3VocabPracticeScreen({Key? key}) : super(key: key);

  @override
  State<S3VocabPracticeScreen> createState() => _S3VocabPracticeScreenState();
}

class _S3VocabPracticeScreenState extends State<S3VocabPracticeScreen> {
  final FlutterTts _tts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = '';
  String _evalResult = '按住麥克風並清晰朗讀單詞進行評測';
  int _spellingStep = 1;
  final TextEditingController _spellController = TextEditingController();

  // 中三（S3）銜接 DSE 的核心學術詞庫（Academic Vocabulary List）
  final List<Map<String, String>> s3VocabList = [
    {
      'word': 'indispensable',
      'pos': 'adj.',
      'phonetic': '/ˌɪndɪˈspensəbl/',
      'meaning': '不可或缺的、絕對必要的 (DSE 議論文高頻加分詞)',
      'example': 'Critical thinking is indispensable for secondary school students.',
      'unit': 'S3 Module 1: Academic Excellence & Self-Discipline'
    },
    {
      'word': 'deteriorate',
      'pos': 'v.',
      'phonetic': '/dɪˈtɪəriəreɪt/',
      'meaning': '惡化、變壞 (常用於香港社會或環境議題寫作)',
      'example': 'Air quality in urban areas may deteriorate without green policies.',
      'unit': 'S3 Module 2: Environmental Challenges in Hong Kong'
    },
    {
      'word': 'advocate',
      'pos': 'v. / n.',
      'phonetic': '/ˈædvəkeɪt/',
      'meaning': '提倡、主張；擁護者 (TKP 領袖培育與德育模組)',
      'example': 'Tang King Po students advocate mutual respect and service to the community.',
      'unit': 'S3 Module 3: Leadership & Social Responsibility'
    },
    {
      'word': 'feasibility',
      'pos': 'n.',
      'phonetic': '/ˌfiːzəˈbɪləti/',
      'meaning': '可行性 (HKDSE 綜合技能整合寫作必備詞)',
      'example': 'The student council examined the feasibility of the proposed recycling scheme.',
      'unit': 'S3 Module 4: Integrated Project Work'
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
    await _tts.setSpeechRate(0.42);
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
    String target = s3VocabList[_currentIndex]['word']!.toLowerCase();
    String spoken = _spokenText.trim().toLowerCase();
    LearningStats.pronunciationAttempts++;
    if (spoken == target) {
      LearningStats.totalPronunciationScore += 100;
      setState(() => _evalResult = '🌟 發音優秀！符合中三英式/美式標準發音 (100分)');
    } else if (spoken.isNotEmpty && (target.contains(spoken) || spoken.contains(target))) {
      LearningStats.totalPronunciationScore += 75;
      setState(() => _evalResult = '👍 發音尚可 ($spoken)，請更注意多音節重音 (75分)');
    } else {
      LearningStats.totalPronunciationScore += 50;
      setState(() => _evalResult = '⚠️ 識別為: "$spoken"，點擊上方喇叭再聽一遍重試');
    }
  }

  void _checkSpelling() {
    String target = s3VocabList[_currentIndex]['word']!;
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
          const SnackBar(content: Text('🎉 恭喜！已完成中三 5 步拼讀強化循環，單詞已永久掌握！')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('拼寫有誤，請仔細比對字根與詞綴後重新輸入')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var cur = s3VocabList[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('TKP 鄧鏡波學校 (中三年級 S3) - 詞彙突破'),
        backgroundColor: const Color(0xFF1B365D),
        foregroundColor: Colors.white,
      ),
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
                    Text(cur['unit']!, style: const TextStyle(color: Color(0xFF1B365D), fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cur['word']!,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: Color(0xFF1B365D), size: 30),
                          onPressed: () => _speak(cur['word']!),
                        ),
                      ],
                    ),
                    Text('${cur['pos']} ${cur['phonetic']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(cur['meaning']!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text('Example: ${cur['example']}', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                    ),
                    const Divider(height: 30),
                    Text(_evalResult, style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _listen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening ? Colors.red : const Color(0xFF1B365D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      label: Text(_isListening ? '正在聆聽...點擊結束' : '按住開口朗讀評測 (S3 標準)'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // S3 5 步拼讀模式
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('中三升高中 5 步拼寫記憶法 [進度: 第 $_spellingStep / 5 步]',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      _spellingStep <= 2 ? '階段一：字形與音節結構對照' : (_spellingStep <= 4 ? '階段二：無提示盲拼挑戰' : '階段三：語境造句拼寫鞏固'),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _spellingStep / 5,
                      color: const Color(0xFF1B365D),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _spellController,
                      decoration: InputDecoration(
                        hintText: _spellingStep <= 2 ? '參照輸入: ${cur['word']}' : '請憑記憶盲拼單詞...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B365D), foregroundColor: Colors.white),
                          onPressed: _checkSpelling,
                          child: const Text('核對拼寫'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentIndex = (_currentIndex + 1) % s3VocabList.length;
                              _spellingStep = 1;
                              _spellController.clear();
                              _evalResult = '按住麥克風並清晰朗讀單詞進行評測';
                            });
                          },
                          child: const Text('下一詞彙 (S3 銜接詞庫) ➔'),
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
 * 2. S3 聽力與考評對話模組（DSE Paper 3 模組）
 * ======================================================== */
class S3ListeningScreen extends StatefulWidget {
  const S3ListeningScreen({Key? key}) : super(key: key);

  @override
  State<S3ListeningScreen> createState() => _S3ListeningScreenState();
}

class _S3ListeningScreenState extends State<S3ListeningScreen> {
  final FlutterTts _tts = FlutterTts();
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  void _initTTS() async {
    await _tts.setLanguage('en-GB'); // 英式標準發音（符合香港 DSE 考評局規定）
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.46);
  }

  void _play(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S3 聽力銜接訓練 (DSE Paper 3 標準)'),
        backgroundColor: const Color(0xFF1B365D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 題目 1：中三常考詞音節識別
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('【題目 1】S3 高頻長難詞音節重音（Stress Pattern）',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _play('indispensable'),
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('播放單詞錄音 (UK RP 標準音)'),
                  ),
                  const SizedBox(height: 12),
                  const Text('問題: 請問單詞 "indispensable" 的主要重音（Primary Stress）落在第幾音節？'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(() => _feedback = '題目1：不正確，in- 是弱讀前綴'),
                        child: const Text('第一音節'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          LearningStats.listeningCompleted++;
                          setState(() => _feedback = '題目1：完全正確！主重音在第三音節 /-spen-/');
                        },
                        child: const Text('第三音節 (/ˈspen/)'),
                      ),
                      OutlinedButton(
                        onPressed: () => setState(() => _feedback = '題目1：不正確，末尾 -able 是輕音節'),
                        child: const Text('第四音節'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 題目 2：S3 校園生活與升中四選科對話
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('【題目 2】S3 升中四選科諮詢會（Subject Selection Dialogue）',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _play(
                      'Teacher: Good afternoon, Matthew. As an S3 student at Tang King Po School, have you decided on your senior secondary elective subjects? '
                      'Matthew: I am strongly interested in taking Physics and Chemistry, because I intend to pursue engineering at university. '
                      'Teacher: Excellent. However, remember that achieving high proficiency in English is equally indispensable for science degrees.',
                    ),
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('播放選科指導實境對話錄音'),
                  ),
                  const SizedBox(height: 12),
                  const Text('問題: According to the teacher, what is indispensable for Matthew\'s university goal?'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      LearningStats.listeningCompleted++;
                      setState(() => _feedback = '題目2：回答正確！高水平的英語能力同樣不可或缺 (High English proficiency)');
                    },
                    child: const Text('Achieving high proficiency in English'),
                  ),
                ],
              ),
            ),
          ),
          if (_feedback.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  _feedback,
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
 * 3. S3 專題閱讀與即時點查（香港本地與 TKP 校園議題）
 * ======================================================== */
class S3ReadingScreen extends StatelessWidget {
  const S3ReadingScreen({Key? key}) : super(key: key);

  void _showDef(BuildContext context, String word, String pos, String def) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(word, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B365D))),
                const SizedBox(width: 8),
                Text('[$pos]', style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
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
      appBar: AppBar(
        title: const Text('S3 專題閱讀 (DSE Paper 1 議論文模組)'),
        backgroundColor: const Color(0xFF1B365D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reading Passage: Building a Sustainable Future at TKP',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 8,
                  children: [
                    const Text('At', style: TextStyle(fontSize: 17)),
                    ActionChip(
                      label: const Text('Tang King Po School'),
                      backgroundColor: Colors.blue.shade50,
                      onPressed: () => _showDef(context, 'Tang King Po School', 'n.', '鄧鏡波學校：天主教慈幼會主辦之九龍城區津貼中學。'),
                    ),
                    const Text(', educators continually', style: TextStyle(fontSize: 17)),
                    ActionChip(
                      label: const Text('advocate'),
                      onPressed: () => _showDef(context, 'advocate', 'v.', '積極倡導、力挺（S3 議論文觀點引述詞彙）。'),
                    ),
                    const Text('environmental stewardship to ensure urban ecosystems do not', style: TextStyle(fontSize: 17)),
                    ActionChip(
                      label: const Text('deteriorate'),
                      onPressed: () => _showDef(context, 'deteriorate', 'v.', '持續惡化、衰退。'),
                    ),
                    const Text('. For all S3 students preparing for Senior Secondary HKDSE curricula, developing scientific thinking and self-reflection is deemed', style: TextStyle(fontSize: 17)),
                    ActionChip(
                      label: const Text('indispensable'),
                      onPressed: () => _showDef(context, 'indispensable', 'adj.', '不可替代的、絕對必要的。'),
                    ),
                    const Text('to evaluate the practical', style: TextStyle(fontSize: 17)),
                    ActionChip(
                      label: const Text('feasibility'),
                      onPressed: () => _showDef(context, 'feasibility', 'n.', '可行性、實行難易度。'),
                    ),
                    const Text('of modern technological innovations.', style: TextStyle(fontSize: 17)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================================================
 * 4. S3 學習小結與效果統計（學期評估指標）
 * ======================================================== */
class S3StatsSummaryScreen extends StatelessWidget {
  const S3StatsSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double avgScore = LearningStats.pronunciationAttempts == 0
        ? 0.0
        : (LearningStats.totalPronunciationScore / LearningStats.pronunciationAttempts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('S3 學習小結與效果統計'),
        backgroundColor: const Color(0xFF1B365D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: const Color(0xFF1B365D),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('中三級 (S3) 升高中 DSE 銜接指數評級', style: TextStyle(color: Colors.white70, fontSize: 15)),
                  const SizedBox(height: 10),
                  Text(
                    '${(avgScore * 0.4 + LearningStats.spellingSuccessCount * 15).clamp(0, 100).toStringAsFixed(1)} 分',
                    style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('狀態：具備升讀中四 (S4) 英文科進階課程潛質', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('中三能力維度分析小結', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.white,
            leading: const Icon(Icons.spellcheck, color: Colors.indigo),
            title: const Text('已熟練掌握之 S3 核心學術詞'),
            trailing: Text('${LearningStats.spellingSuccessCount} 個', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ListTile(
            tileColor: Colors.white,
            leading: const Icon(Icons.record_voice_over, color: Colors.teal),
            title: const Text('DSE 標準口語發音評測平均分'),
            trailing: Text('${avgScore.toStringAsFixed(1)} 分', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ListTile(
            tileColor: Colors.white,
            leading: const Icon(Icons.hearing, color: Colors.orange),
            title: const Text('完成 Paper 3 對話理解題數'),
            trailing: Text('${LearningStats.listeningCompleted} 題', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('中三學期學習回饋與教師建議', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('1. 詞彙建議：中三進入議論文（Argumentative Writing）寫作，需重點記憶因果與對比轉折連接詞。\n2. 聽力建議：中三學生應加強從英國標準音（Received Pronunciation）中快速抓取時間、地點與核心論點的筆記能力。'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
