import sqlite3
import json
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

l16_path = r"D:\AL Quran\taj-indopak-16-lines.db"
l16_con = sqlite3.connect(l16_path)
l16_cur = l16_con.cursor()

# Find the 30 surahs with explicit basmallah in raw 16-line DB
explicit_30 = set()
for r in l16_cur.execute("SELECT page_number, line_number, line_type, surah_number FROM pages WHERE line_type='basmallah'").fetchall():
    p, l = r[0], r[1]
    prev_s = l16_cur.execute("SELECT surah_number FROM pages WHERE (page_number < ? OR (page_number=? AND line_number < ?)) AND line_type='surah_name' ORDER BY page_number DESC, line_number DESC LIMIT 1", (p, p, l)).fetchone()
    if prev_s and prev_s[0]:
        explicit_30.add(int(prev_s[0]))

print(f"Explicit 30 surahs in raw 16-line DB: {sorted(list(explicit_30))}")

# The 82 affected surahs:
affected_82 = [s for s in range(2, 115) if s != 9 and s not in explicit_30]
print(f"Total affected surahs to check: {len(affected_82)}")

print("\n" + "=" * 90)
print(f"{'Surah':<6} | {'15-Line A1 Words':<16} | {'16-Line A1 Words':<16} | {'Has Merged Bismillah?':<22} | {'First 3 Words of Ayah 1'}")
print("─" * 90)

merged_count = 0
not_merged_count = 0

for s in affected_82:
    # 15_line Ayah 1 words
    w15 = cur.execute("""
        SELECT glyph_code FROM word_layout 
        WHERE mushaf='15_line' AND surah=? AND ayah=1 AND word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%'
        ORDER BY page, line, word_pos
    """, (s,)).fetchall()
    w15_words = [w[0] for w in w15]

    # 16_line Ayah 1 words
    w16 = cur.execute("""
        SELECT glyph_code FROM word_layout 
        WHERE mushaf='16_line' AND surah=? AND ayah=1 AND word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%'
        ORDER BY page, line, word_pos
    """, (s,)).fetchall()
    w16_words = [w[0] for w in w16]

    # Check if first words of Ayah 1 contain Bismillah
    first_3_str = " ".join(w16_words[:3])
    has_merged_bismillah = ("بسم" in first_3_str.replace("بِسْمِ", "بسم"))

    if has_merged_bismillah:
        merged_count += 1
        status = "YES (Merged in Ayah 1)"
    else:
        not_merged_count += 1
        status = "NO (Ayah 1 is clean text)"

    # Compare word count excluding verse end marker
    cnt15 = max(0, len(w15_words) - 1)
    cnt16 = max(0, len(w16_words) - 1)
    match_str = f"{cnt15} words"

    print(f"S. {s:<4d} | {cnt15:<16d} | {cnt16:<16d} | {status:<22} | '{first_3_str}'")

print("─" * 90)
print(f"Summary across all 82 affected Surahs:")
print(f"  - Surahs where Bismillah was merged into Ayah 1 text : {merged_count}")
print(f"  - Surahs where Ayah 1 has CLEAN verse text (no Bismillah merged): {not_merged_count}")
print(f"  - In ALL 82 surahs, 15-line word count == 16-line word count: {all(len(cur.execute('SELECT id FROM word_layout WHERE mushaf=\"15_line\" AND surah=? AND ayah=1 AND word_id NOT LIKE \"surah_name:%\" AND word_id NOT LIKE \"basmallah:%\"', (s,)).fetchall()) == len(cur.execute('SELECT id FROM word_layout WHERE mushaf=\"16_line\" AND surah=? AND ayah=1 AND word_id NOT LIKE \"surah_name:%\" AND word_id NOT LIKE \"basmallah:%\"', (s,)).fetchall()) for s in affected_82)}")

con.close()
l16_con.close()
