import pandas as pd
from sudachipy import Dictionary, Tokenizer

# Initialize Sudachi tokenizer
tokenizer_obj = Dictionary(dict="core").create()
split_mode = Tokenizer.SplitMode.C

def katakana_to_hiragana(text):
    out = []
    for ch in text:
        cp = ord(ch)
        if 0x30A1 <= cp <= 0x30F6:
            out.append(chr(cp - 0x60))
        else:
            out.append(ch)
    return "".join(out)
# Check for empty data
def generate_sudachi_ruby(sentence):
    # Handle missing/NaN values safely
    if not isinstance(sentence, str):
        return ""
        
    tokens = tokenizer_obj.tokenize(sentence, split_mode)
    formatted_output = ""
    # Loop through every token
    for token in tokens:
        # Get original word
        surface = token.surface()
        reading_kata = token.reading_form()
        
        if not reading_kata or surface == reading_kata:
            formatted_output += surface
            continue
        #  Skip words that don't need furigana   
        reading_hira = katakana_to_hiragana(reading_kata)
        has_kanji = any(ord(c) > 127 for c in surface)
        
        if has_kanji and surface != reading_hira:
            formatted_output += f"({surface})[{reading_hira}]"
        else:
            formatted_output += surface
            
    return formatted_output

# 1. Read directly from your CSV file!
print("Reading sentences.csv...")
df = pd.read_csv('sentences.csv', encoding='utf-8')

print("Processing sentences with Sudachi accuracy...")
# 2. Generate ruby column automatically
df['ruby'] = df['japanese'].apply(generate_sudachi_ruby)

# 3. Export to a clean CSV file ready for Supabase (with UTF-8 encoding)
output_file = 'sentences_supabase_ready.csv'
df.to_csv(output_file, index=False, encoding='utf-8-sig')

print(f"Done! Clean CSV saved as: {output_file}. You can now upload this file to Supabase.")