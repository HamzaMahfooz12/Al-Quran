import sqlite3
import json
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

print("=== Sample 15_line page 1 words ===")
rows = cur.execute("SELECT line, surah, ayah, word_pos, word_id, glyph_code FROM word_layout WHERE mushaf='15_line' AND page=1").fetchall()
for r in rows:
    print(r[0], r[1], r[2], r[3], r[4], repr(r[5]))

print("\n=== Check ayah table columns for ruku info ===")
cur.execute("PRAGMA table_info(ayahs)")
cols = [c[1] for c in cur.fetchall()]
print("Ayahs table cols:", cols)

print("\n=== Check layout DB pages table columns for ruku / info ===")
lcon = sqlite3.connect(r"D:\AL Quran\qudratullah-indopak-15-lines.db")
lcur = lcon.cursor()
lcur.execute("PRAGMA table_info(pages)")
print("Layout 15 pages cols:", [c[1] for c in lcur.fetchall()])

lcon16 = sqlite3.connect(r"D:\AL Quran\taj-indopak-16-lines.db")
lcur16 = lcon16.cursor()
lcur16.execute("PRAGMA table_info(pages)")
print("Layout 16 pages cols:", [c[1] for c in lcur16.fetchall()])

con.close()
lcon.close()
lcon16.close()
