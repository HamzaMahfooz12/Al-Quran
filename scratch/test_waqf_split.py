import re
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

# Waqf pattern in Arabic
WAQF_REGEX = re.compile(r'[\u06D6-\u06DC\u06DF-\u06E8\u0615\u0617\u0658\u065D\u064A-\u0652]')

def split_word_and_waqf(glyph_code):
    # Check if there is trailing waqf mark(s)
    # Common waqf characters: ؕ (\u0615), ۙ (\u06d9), ۚ (\u06da), ۖ (\u06d6), ۗ (\u06d7), ۘ (\u06d8), ۛ (\u06db), ۜ (\u06dc), ۬ (\u06ec), ۠ (\u06e0)
    waqf_chars = set(['\u0615', '\u0617', '\u06D6', '\u06D7', '\u06D8', '\u06D9', '\u06DA', '\u06DB', '\u06DC', '\u06EC', '\u06E0'])
    
    # Extract waqf marks from the end of glyph_code
    parts = glyph_code.rstrip().split(' ')
    if len(parts) > 1 and all(any(c in waqf_chars for c in p) for p in parts[1:]):
        base_word = parts[0]
        waqf_str = ' '.join(parts[1:])
        return base_word, waqf_str
    
    # Check if trailing characters are waqf marks
    waqf_found = []
    base_chars = list(glyph_code)
    while base_chars and base_chars[-1] in waqf_chars or (base_chars and base_chars[-1] == ' '):
        c = base_chars.pop()
        if c != ' ':
            waqf_found.insert(0, c)
            
    if waqf_found and base_chars:
        return ''.join(base_chars).rstrip(), ''.join(waqf_found)
        
    return glyph_code, ''

test_samples = [
    'وَاِسْمٰعِیْلُ ؕ',
    'مِنَّا ؕ',
    'الْمَوْتُ ۙ',
    'بَعْدِیْ ؕ',
    'شِقَاقٍ ۚ',
    'شَطْرَهٗ ۙ',
    'حُجَّةٌ ۙۗ',
    'الْكِتٰبِ ۙ',
    'رَیْبَ ۛۖۚ',
    'قَوْمَا ۙ',
    'الْقَوَاعِدَ',
]

print("=== Testing Split Word and Waqf ===")
for s in test_samples:
    base, waqf = split_word_and_waqf(s)
    print(f"Original: '{s}' -> Base: '{base}' | Waqf: '{waqf}'")

