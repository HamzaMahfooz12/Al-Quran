import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

l16_path = r"D:\AL Quran\taj-indopak-16-lines.db"
l16_con = sqlite3.connect(l16_path)
l16_cur = l16_con.cursor()

def inspect_page_before_after(page_num, surah_num):
    print(f"\n" + "=" * 80)
    print(f"PAGE {page_num} (Surah {surah_num}) — BEFORE (taj-indopak-16-lines.db) vs AFTER (word_layout)")
    print("=" * 80)

    # Raw 16-line DB
    raw_rows = l16_cur.execute("SELECT line_number, line_type, surah_number, first_word_id, last_word_id FROM pages WHERE page_number=? ORDER BY line_number", (page_num,)).fetchall()
    print(f"\n[A] BEFORE: Raw taj-indopak-16-lines.db ({len(raw_rows)} lines):")
    for r in raw_rows:
        print(f"    Line {r[0]:2d} | type={r[1]:12s} | surah={str(r[2]):3s} | words={r[3]}..{r[4]}")

    # word_layout DB
    wl_rows = cur.execute("""
        SELECT line, word_pos, surah, ayah, word_id, glyph_code 
        FROM word_layout 
        WHERE mushaf='16_line' AND page=? 
        ORDER BY line, word_pos
    """, (page_num,)).fetchall()

    lines = {}
    for r in wl_rows:
        lines.setdefault(r[0], []).append(r)

    print(f"\n[B] AFTER: App SQLite word_layout ({len(lines)} distinct line numbers):")
    for l_num in sorted(lines.keys()):
        words = lines[l_num]
        sample = " ".join([w[5] for w in words[:4]])
        print(f"    Line {l_num:2d} | entries={len(words):2d} | word_id={words[0][4]} | sample='{sample}'")

inspect_page_before_after(45, 3)    # Surah 3 (one of the 82 inserted)
inspect_page_before_after(396, 36)  # Surah 36 (had existing basmallah line 12 in raw DB)
inspect_page_before_after(547, 112) # Surahs 109, 110, 111, 112 (multiple surahs on 1 page)

con.close()
l16_con.close()
