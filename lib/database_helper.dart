
import 'dart:convert';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // ============================================================
  // DATABASE
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('offline_study.db');

    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();

    final path = join(
      directory.path,
      fileName,
    );

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // ============================================================
  // CREATE DATABASE
  // ============================================================

  Future<void> _createDB(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE sentences (
        id INTEGER PRIMARY KEY,
        level TEXT NOT NULL,
        japanese TEXT NOT NULL,
        meaning TEXT NOT NULL,
        ruby TEXT,
        audio_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY,
        level TEXT NOT NULL,
        question_type TEXT NOT NULL,
        question TEXT NOT NULL,
        meaning TEXT,
        answer TEXT,
        choices TEXT,
        explanation TEXT,
        ruby TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE kanji (
        id INTEGER PRIMARY KEY,
        character TEXT NOT NULL UNIQUE,
        level TEXT,
        meanings TEXT,
        onyomi TEXT,
        kunyomi TEXT,
        stroke_count INTEGER,
        example_words TEXT
      )
    ''');
  }

  // ============================================================
  // SENTENCES
  // ============================================================

  Future<void> insertSentence(
    Map<String, dynamic> item,
  ) async {
    final db = await database;

    await db.insert(
      'sentences',
      {
        'id': item['id'],
        'level': item['level'],
        'japanese': item['japanese'],
        'meaning': item['meaning'],
        'ruby': item['ruby'],
        'audio_url': item['audio_url'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSentences() async {
    final db = await database;

    return db.query(
      'sentences',
      orderBy: 'id ASC',
    );
  }

  Future<void> clearSentences() async {
    final db = await database;

    await db.delete('sentences');
  }

  // ============================================================
  // QUESTIONS
  // ============================================================

  Future<void> insertQuestion(
    Map<String, dynamic> item,
  ) async {
    final db = await database;

    String? choices;

    final rawChoices = item['choices'];

    if (rawChoices != null) {
      if (rawChoices is String) {
        choices = rawChoices;
      } else {
        choices = jsonEncode(rawChoices);
      }
    }

    await db.insert(
      'questions',
      {
        'id': item['id'],
        'level': item['level'],
        'question_type': item['question_type'],
        'question': item['question'],
        'meaning': item['meaning'],
        'answer': item['answer'],
        'choices': choices,
        'explanation': item['explanation'],
        'ruby': item['ruby'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getQuestions() async {
    final db = await database;

    return db.query(
      'questions',
      orderBy: 'id ASC',
    );
  }

  // ============================================================
  // KANJI
  // ============================================================

  Future<void> insertKanji(
    Map<String, dynamic> item,
  ) async {
    final db = await database;

    await db.insert(
      'kanji',
      {
        'id': item['id'],
        'character': item['character'],
        'level': item['level'],
        'meanings': _encodeJson(item['meanings']),
        'onyomi': _encodeJson(item['onyomi']),
        'kunyomi': _encodeJson(item['kunyomi']),
        'stroke_count': item['stroke_count'],
        'example_words': _encodeJson(item['example_words']),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getKanji() async {
    final db = await database;

    return db.query(
      'kanji',
      orderBy: 'id ASC',
    );
  }

  // ============================================================
  // JSON HELPER
  // ============================================================

  String? _encodeJson(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(value);
  }

  // ============================================================
  // CLOSE DATABASE
  // ============================================================

  Future<void> close() async {
    final db = await database;

    await db.close();

    _database = null;
  }
}
