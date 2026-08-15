import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

print("=== Page 1 (15_line) lines ===")
rows = cur.execute("SELECT line, word_pos, surah, ayah, word_id, glyph_code FROM word_layout WHERE mushaf='15_line' AND page=1 ORDER BY line, word_pos").fetchall()
for r in rows:
    print(f"L{r[0]:2d} pos{r[1]:2d} {r[2]}:{r[3]} id={r[4]:10s} text={repr(r[5])}")

print("\n=== Page 2 (15_line) lines ===")
rows = cur.execute("SELECT line, word_pos, surah, ayah, word_id, glyph_code FROM word_layout WHERE mushaf='15_line' AND page=2 ORDER BY line, word_pos").fetchall()
for r in rows:
    print(f"L{r[0]:2d} pos{r[1]:2d} {r[2]}:{r[3]} id={r[4]:10s} text={repr(r[5])}")

con.close()
