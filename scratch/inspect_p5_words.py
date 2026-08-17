import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

# Check Page 5 words in 15_line word_layout
rows = cur.execute("SELECT line, word_pos, surah, ayah, word_id, glyph_code FROM word_layout WHERE mushaf='15_line' AND page=5 ORDER BY line, word_pos").fetchall()
print(f"Total words on Page 5 of 15_line: {len(rows)}")
for r in rows[:15]:
    code_units = [hex(ord(c)) for c in r[5]]
    print(f"L.{r[0]:2d} P.{r[1]:2d} {r[2]}:{r[3]} id='{r[4]}' text='{r[5]}' hex={code_units}")

con.close()
