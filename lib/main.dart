import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_ruby_text/flutter_ruby_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_helper.dart';
// import 'ruby_service.dart';
import 'sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // SUPABASE
  // ============================================================

  try {
    await Supabase.initialize(
      url: 'https://lbbbryrfncmcrqrzgcct.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxiYmJyeXJmbmNtY3JxcnpnY2N0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzMDY0MzcsImV4cCI6MjEwNTg4MjQzN30.JucxLqnTUSpKvvUjvwDO1dRZZoDFaWiRM147_g8ot6Q',
    );
  } catch (e) {
    debugPrint(
      'Supabase initialization failed: $e',
    );
  }

  // ============================================================
  // APP
  // ============================================================

  runApp(
    const MyApp(),
  );
}

// ================================================================
// MY APP
// ================================================================

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JLPT Offline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ================================================================
// HOME SCREEN
// ================================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JLPT Japanese Study',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(
            title: 'Sentences',
            subtitle: 'Study Japanese sentences',
            icon: Icons.menu_book,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SentenceScreen(),
                ),
              );
            },
          ),
          _MenuCard(
            title: 'Questions',
            subtitle: 'Practice JLPT questions',
            icon: Icons.quiz,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QuestionScreen(),
                ),
              );
            },
          ),
          _MenuCard(
            title: 'Kanji',
            subtitle: 'Study JLPT kanji',
            icon: Icons.translate,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KanjiScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MENU CARD
// ================================================================

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ================================================================
// SENTENCE SCREEN
// ================================================================

class SentenceScreen extends StatefulWidget {
  const SentenceScreen({
    super.key,
  });

  @override
  State<SentenceScreen> createState() => _SentenceScreenState();
}

class _SentenceScreenState extends State<SentenceScreen> {
  List<Map<String, dynamic>> sentences = [];

  bool loading = true;

  String? error;

  @override
  void initState() {
    super.initState();

    _loadSentences();
  }

  // ============================================================
  // LOAD SENTENCES
  // ============================================================

  Future<void> _loadSentences() async {
    setState(() {
      loading = true;
      error = null;
    });

    // First load local data.
    try {
      final localData = await DatabaseHelper.instance.getSentences();

      if (mounted) {
        setState(() {
          sentences = localData;
        });
      }
    } catch (e) {
      debugPrint(
        'Local sentence loading failed: $e',
      );
    }

    // Then try online synchronization.
    try {
      await SyncService.instance.syncSentences();

      final updatedData = await DatabaseHelper.instance.getSentences();

      if (mounted) {
        setState(() {
          sentences = updatedData;
        });
      }
    } catch (e) {
      debugPrint(
        'Offline mode: $e',
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JLPT Sentences',
        ),
      ),
      body: loading && sentences.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : sentences.isEmpty
              ? _EmptyState(
                  message: 'No sentences available.',
                  onRetry: _loadSentences,
                )
              : RefreshIndicator(
                  onRefresh: _loadSentences,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: sentences.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      return SentenceCard(
                        item: sentences[index],
                      );
                    },
                  ),
                ),
    );
  }
}

// ================================================================
// SENTENCE CARD
// ================================================================

class SentenceCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const SentenceCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final japanese = item['japanese'] as String? ?? '';

    final meaning = item['meaning'] as String? ?? '';

    final ruby = item['ruby'] as String?;

    final level = item['level'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEVEL
            Chip(
              label: Text(level),
            ),

            const SizedBox(
              height: 12,
            ),

            // JAPANESE WITH RUBY
            if (ruby != null && ruby.trim().isNotEmpty)
              RubyText.parse(
                ruby,
                parser: const RubyTextBracketParser(),
                style: const TextStyle(
                  fontSize: 24,
                ),
                rubyStyle: const TextStyle(
                  fontSize: 11,
                  color: Colors.cyan,
                ),
              )
            else
              Text(
                japanese,
                style: const TextStyle(
                  fontSize: 24,
                ),
              ),

            const SizedBox(
              height: 12,
            ),

            // ENGLISH
            Text(
              meaning,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//I changed color from blue to purple and red to cyan
// ================================================================
// QUESTION SCREEN
// ================================================================

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({
    super.key,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  List<Map<String, dynamic>> questions = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      loading = true;
    });

    try {
      // Load local first.
      questions = await DatabaseHelper.instance.getQuestions();

      if (mounted) {
        setState(() {});
      }

      // Try online update.
      try {
        await SyncService.instance.syncQuestions();

        questions = await DatabaseHelper.instance.getQuestions();

        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        debugPrint(
          'Question offline mode: $e',
        );
      }
    } catch (e) {
      debugPrint(
        'Question loading error: $e',
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JLPT Questions',
        ),
      ),
      body: loading && questions.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : questions.isEmpty
              ? _EmptyState(
                  message: 'No questions available.',
                  onRetry: _loadQuestions,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: questions.length,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    return QuestionCard(
                      item: questions[index],
                    );
                  },
                ),
    );
  }
}

// ================================================================
// QUESTION CARD
// ================================================================

class QuestionCard extends StatefulWidget {
  final Map<String, dynamic> item;

  const QuestionCard({
    super.key,
    required this.item,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  String? selectedAnswer;

  bool answered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final question = item['question'] as String? ?? '';

    final ruby = item['ruby'] as String?;

    final answer = item['answer'] as String? ?? '';

    final explanation = item['explanation'] as String? ?? '';

    final choices = _parseChoices(
      item['choices'],
    );

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QUESTION
            if (ruby != null && ruby.trim().isNotEmpty)
              RubyText.parse(
                ruby,
                parser: const RubyTextBracketParser(),
                style: const TextStyle(
                  fontSize: 24,
                ),
                rubyStyle: const TextStyle(
                  fontSize: 11,
                  color: Colors.blue,
                ),
              )
            else
              Text(
                question,
                style: const TextStyle(
                  fontSize: 24,
                ),
              ),

            const SizedBox(
              height: 16,
            ),

            // CHOICES
            ...choices.map(
              (choice) {
                final isSelected = selectedAnswer == choice;

                final isCorrect = choice == answer;

                Color? background;

                if (answered) {
                  if (isCorrect) {
                    background = Colors.green.shade100;
                  } else if (isSelected) {
                    background = Colors.red.shade100;
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 8,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: choice,
                    groupValue: selectedAnswer,
                    title: Text(
                      choice,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    onChanged: answered
                        ? null
                        : (value) {
                            setState(() {
                              selectedAnswer = value;
                              answered = true;
                            });
                          },
                  ),
                );
              },
            ),

            if (answered) ...[
              const Divider(),
              Text(
                selectedAnswer == answer ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: selectedAnswer == answer ? Colors.green : Colors.red,
                ),
              ),
              if (explanation.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 8,
                  ),
                  child: Text(
                    explanation,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _parseChoices(dynamic value) {
    if (value == null) {
      return [];
    }

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        return [];
      }
    }

    return [];
  }
}

// ================================================================
// KANJI SCREEN
// ================================================================

class KanjiScreen extends StatefulWidget {
  const KanjiScreen({
    super.key,
  });

  @override
  State<KanjiScreen> createState() => _KanjiScreenState();
}

class _KanjiScreenState extends State<KanjiScreen> {
  List<Map<String, dynamic>> kanji = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    _loadKanji();
  }

  Future<void> _loadKanji() async {
    try {
      kanji = await DatabaseHelper.instance.getKanji();

      if (mounted) {
        setState(() {});
      }

      try {
        await SyncService.instance.syncKanji();

        kanji = await DatabaseHelper.instance.getKanji();

        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        debugPrint(
          'Kanji offline mode: $e',
        );
      }
    } catch (e) {
      debugPrint(
        'Kanji loading error: $e',
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JLPT Kanji',
        ),
      ),
      body: loading && kanji.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : kanji.isEmpty
              ? _EmptyState(
                  message: 'No kanji available.',
                  onRetry: _loadKanji,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: kanji.length,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    return KanjiCard(
                      item: kanji[index],
                    );
                  },
                ),
    );
  }
}

// ================================================================
// KANJI CARD
// ================================================================

class KanjiCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const KanjiCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final character = item['character'] as String? ?? '';

    final level = item['level'] as String? ?? '';

    final meanings = _toList(item['meanings']);

    final onyomi = _toList(item['onyomi']);

    final kunyomi = _toList(item['kunyomi']);

    final strokeCount = item['stroke_count'];

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              character,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              width: 24,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Meaning: ${meanings.join(', ')}',
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Onyomi: ${onyomi.join(', ')}',
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Kunyomi: ${kunyomi.join(', ')}',
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Strokes: $strokeCount',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _toList(dynamic value) {
    if (value == null) {
      return [];
    }

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // If it's just a raw comma-separated string or plain text
        return [value];
      }
    }

    return [];
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EmptyState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
            ),
          ),
        ],
      ),
    );
  }
}
