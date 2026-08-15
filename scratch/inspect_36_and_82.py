import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

l16_path = r"D:\AL Quran\taj-indopak-16-lines.db"
l16_con = sqlite3.connect(l16_path)
l16_cur = l16_con.cursor()

# 1. Inspect Surah 36 in taj-indopak-16-lines.db
print("=== Surah 36 in raw taj-indopak-16-lines.db ===")
p396_rows = l16_cur.execute("SELECT page_number, line_number, line_type, surah_number, first_word_id, last_word_id FROM pages WHERE page_number=396").fetchall()
for r in p396_rows:
    print(r)

print("\n=== Surah 36 in word_layout (16_line) ===")
p396_wl = cur.execute("SELECT id, mushaf, page, line, surah, ayah, word_pos, word_id, glyph_code FROM word_layout WHERE mushaf='16_line' AND page=396 ORDER BY line, word_pos").fetchall()
# Group by line
lines = {}
for r in p396_wl:
    lines.setdefault(r[3], []).append(r)

for l, words in lines.items():
    print(f"Line {l:2d} ({len(words)} entries): {[w[7] for w in words]}")

# 2. Check all 82 affected surahs where raw 16-line DB lacked a basmallah line
print("\n=== Checking 82 surahs for Ayah 1 word count comparison ===")
# Find which surahs in 16-line raw DB had explicit basmallah lines vs not
raw_16_basmallah_surahs = set()
for r in l16_cur.execute("SELECT page_number, line_number, line_type, surah_number FROM pages WHERE line_type='basmallah'").fetchall():
    # find preceding surah_name
    p, l = r[0], r[1]
    prev_s = l16_cur.execute("SELECT surah_number FROM pages WHERE (page_number < ? OR (page_number=? AND line_number < ?)) AND line_type='surah_name' ORDER BY page_number DESC, line_number DESC LIMIT 1", (p, p, l)).fetchone()
    if prev_s and prev_s[0]:
        raw_16_basmallah_surahs.add(int(prev_s[0]))

print(f"Raw 16-line DB had {len(raw_16_basmallah_surahs)} surahs with explicit basmallah in pages table.")

con.close()
l16_con.close()
