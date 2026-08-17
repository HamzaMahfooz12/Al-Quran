import re
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

def sanitize_word_text(text):
    if not text:
        return text
    # Map known IndoPak PUA ligatures
    s = text
    s = s.replace('\uf61f', 'ٱ') # Wasla on Allah
    s = s.replace('\uf66d', 'ۭ') # Small low meem
    s = s.replace('\uf65d', '')  # Small ligature mark
    s = s.replace('\uf64a', 'ۙ') # Stop mark
    s = s.replace('\uf64b', 'ۚ')
    s = s.replace('\uf64c', 'ؕ')
    s = s.replace('\uf64d', 'ۖ')
    s = s.replace('\uf64e', 'ۛ')
    # Remove remaining PUA characters
    return re.sub(r'[\ue000-\uf8ff]', '', s)

test_words = [
    'للّٰهُ',     # Wasla + Allah
    'بَىِٕیْسٍ',   # Bayeesin + small meem
    'مِنْ',       # Min + ligature
    'فَخَلَفَ',     # Regular word
    'قَوْمَا ۙ',    # Qawman + waqf
]

print("=== Testing Word Sanitization ===")
for w in test_words:
    clean = sanitize_word_text(w)
    print(f"Original: '{w}' -> Cleaned: '{clean}'")

