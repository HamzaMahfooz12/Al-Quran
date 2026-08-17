import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

# Check Page 173 in word_layout for both 15_line and 16_line
for m in ['15_line', '16_line']:
    print(f"\n=== Mushaf: {m} on Page 173 (or Surah 7:164) ===")
    rows = cur.execute("""
        SELECT page, line, word_pos, surah, ayah, word_id, glyph_code 
        FROM word_layout 
        WHERE surah=7 AND ayah=164 AND mushaf=?
        ORDER BY page, line, word_pos
    """, (m,)).fetchall()
    
    for r in rows:
        code_units = [f"0x{ord(c):x}" for c in r[6]]
        print(f"P.{r[0]} L.{r[1]:2d} Pos.{r[2]:2d} {r[3]}:{r[4]} id='{r[5]}' text='{r[6]}' hex={code_units}")

con.close()
