import sqlite3
import sys, io
import re

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

def is_verse_end(word_id, glyph_code, ayah):
    if ayah <= 0:
        return False
    if word_id.endswith(':end') or '﴿' in glyph_code:
        return True
    
    # In IndoPak dataset:
    # 1. Contains '۟' (\u06df)
    # 2. Or is a standalone ornament symbol (starts with or contains \uf500-\uf5ff without standard arabic alphabet letters)
    if '\u06df' in glyph_code:
        return True
    
    # Check if contains private use ornament \uf500..\uf5ff and has no standard arabic letters
    has_ornament = any(0xF500 <= ord(c) <= 0xF5FF for c in glyph_code)
    has_letters = bool(re.search(r'[\u0621-\u064A\u0671-\u06D3]', glyph_code))
    if has_ornament and not has_letters:
        return True
        
    return False

for m in ['15_line', '16_line']:
    rows = cur.execute("""
        SELECT page, line, word_pos, surah, ayah, word_id, glyph_code 
        FROM word_layout 
        WHERE mushaf=? AND word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%'
        ORDER BY page, line, word_pos
    """, (m,)).fetchall()

    detected_ends = []
    ayah_end_map = {} # (surah, ayah) -> list of word_ids

    for r in rows:
        if is_verse_end(r[5], r[6], r[4]):
            detected_ends.append(r)
            ayah_end_map.setdefault((r[3], r[4]), []).append(r[5])

    print(f"\n=== Mushaf: {m} ===")
    print(f"Total verse ends detected: {len(detected_ends)} (Expected: 6,236)")
    
    duplicates = {k: v for k, v in ayah_end_map.items() if len(v) > 1}
    print(f"Ayahs with MULTIPLE verse end badges: {len(duplicates)}")
    if duplicates:
        for k, v in list(duplicates.items())[:5]:
            print(f"  Surah {k[0]} Ayah {k[1]} has multiple ends: {v}")

    # Check for any ayah missing an end
    missing = []
    for s in range(1, 115):
        cnt = cur.execute("SELECT COUNT(*) FROM ayahs WHERE surah=?", (s,)).fetchone()[0]
        for a in range(1, cnt + 1):
            if (s, a) not in ayah_end_map:
                missing.append((s, a))
    print(f"Ayahs MISSING verse end badges: {len(missing)}")

con.close()
