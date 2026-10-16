
class RubyService {
  static final RubyService instance = RubyService._init();

  RubyService._init();

  /// Converts ordinary Japanese text into the representation
  /// expected by flutter_ruby_text.
  ///
  /// IMPORTANT:
  /// This function is NOT a Japanese morphological analyzer.
  ///
  /// Your Sudachi/MeCab processing should generate the ruby
  /// string before it reaches this function.
  ///
  /// Example generated value:
  ///
  /// (東京)[とうきょう]へ(行)[い]きます。
  String prepareForRubyText(String? ruby) {
    if (ruby == null || ruby.trim().isEmpty) {
      return '';
    }

    return ruby;
  }
}
