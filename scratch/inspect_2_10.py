import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

rows = cur.execute("SELECT word_pos, surah, ayah, word_id, glyph_code FROM word_layout WHERE mushaf='15_line' AND surah=2 AND ayah=10 ORDER BY word_pos").fetchall()
for r in rows:
    hexes = [f"0x{ord(c):x}" for c in r[4]]
    print(f"{r[3]} : '{r[4]}' hex={hexes}")

con.close()
