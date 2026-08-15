import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

print("=== Check verse end marker rows in 15_line ===")
rows = cur.execute("""
    SELECT page, line, surah, ayah, word_pos, word_id, glyph_code 
    FROM word_layout 
    WHERE mushaf='15_line' AND surah=1
""").fetchall()

for r in rows:
    glyph = r[6]
    pua_chars = [hex(ord(c)) for c in glyph if ord(c) >= 0xF000]
    print(f"p.{r[0]} l.{r[1]} s.{r[2]} a.{r[3]} pos.{r[4]} id={r[5]} glyph={repr(glyph)} pua={pua_chars}")

print("\n=== Total verse end markers detected across 15_line ===")
count = 0
cur.execute("SELECT glyph_code, surah, ayah FROM word_layout WHERE mushaf='15_line'")
for g, s, a in cur.fetchall():
    if any(ord(c) >= 0xF500 and ord(c) <= 0xF6FF for c in g):
        count += 1
print(f"Found {count} verse end PUA glyphs in 15_line")

con.close()
