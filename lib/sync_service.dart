import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();

  SyncService._init();

  final SupabaseClient supabase = Supabase.instance.client;

  final DatabaseHelper database = DatabaseHelper.instance;
 //this is good
  // ============================================================
  // SYNC SENTENCES
  // ============================================================

  Future<int> syncSentences() async {
    debugPrint('Starting sentence sync...');

    try {
      //Download all sentence rows.
      final response = await supabase.from('sentences').select().order('id');

      debugPrint('Supabase returned ${response.length} sentences');

      for (final row in response) {
        await database.insertSentence(//Save into SQLite.
          Map<String, dynamic>.from(row),
        );
      }

      return response.length;
    } catch (e) {
      debugPrint('CRITICAL SYNC ERROR (Sentences): $e'); // <-- Add this
      rethrow;
    }
  }

  // ============================================================
  // SYNC QUESTIONS
  // ============================================================

  Future<int> syncQuestions() async {
    debugPrint('Starting question sync...');

    final response = await supabase.from('questions').select().order('id');

    debugPrint(
      'Supabase returned ${response.length} questions',
    );

    for (final row in response) {
      await database.insertQuestion(
        Map<String, dynamic>.from(row),
      );
    }

    return response.length;
  }

  // ============================================================
  // SYNC KANJI
  // ============================================================

  Future<int> syncKanji() async {
    debugPrint('Starting kanji sync...');

    final response = await supabase.from('kanji').select().order('id');

    debugPrint(
      'Supabase returned ${response.length} kanji',
    );

    for (final row in response) {
      await database.insertKanji(
        Map<String, dynamic>.from(row),
      );
    }

    return response.length;
  }

  // ============================================================
  // SYNC EVERYTHING
  // ============================================================

  Future<void> syncAll() async {
    await syncSentences();
    await syncQuestions();
    await syncKanji();
  }
}
