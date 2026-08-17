import sqlite3
import sys, io
from collections import Counter

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

pua_usage = {} # hex -> list of (surah, ayah, full_word)

rows = cur.execute("SELECT surah, ayah, word_id, glyph_code FROM word_layout WHERE word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%'").fetchall()
for s, a, wid, text in rows:
    for c in text:
        code = ord(c)
        if 0xE000 <= code <= 0xF8FF:
            h = f"0x{code:X}"
            pua_usage.setdefault(h, []).append((s, a, wid, text))

print(f"=== Complete PUA Glyph Analysis across Entire Quran ===")
print(f"Total distinct PUA characters found: {len(pua_usage)}\n")

# Separate into Ayah End markers (0xF500..0xF5FF) and in-word ligatures (others)
ayah_markers = {k: v for k, v in pua_usage.items() if 0xF500 <= int(k, 16) <= 0xF5FF}
word_ligatures = {k: v for k, v in pua_usage.items() if not (0xF500 <= int(k, 16) <= 0xF5FF)}

print(f"1. Ayah End Circle Marker Glyphs (0xF500..0xF5FF): {len(ayah_markers)} distinct codes ({sum(len(v) for v in ayah_markers.values())} total occurrences)")
print(f"2. In-Word Ligatures / Tajweed Symbols: {len(word_ligatures)} distinct codes ({sum(len(v) for v in word_ligatures.values())} total occurrences)\n")

print("=== In-Word Ligatures & Tajweed Symbols Breakdown ===")
for hex_code, occurrences in sorted(word_ligatures.items(), key=lambda x: -len(x[1])):
    sample = occurrences[0]
    sample_text = sample[3]
    # show clean hexes of sample
    sample_hexes = [f"0x{ord(ch):X}" for ch in sample_text]
    print(f"PUA Code {hex_code} ({len(occurrences):4d}x) | Sample Word: '{sample_text}' in {sample[0]}:{sample[1]} | Context: {sample_hexes}")

con.close()
