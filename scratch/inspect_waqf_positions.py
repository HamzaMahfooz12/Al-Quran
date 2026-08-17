import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

# Inspect Surah 2:127 (Image 1: وَإِذْ يَرْفَعُ إِبْرٰهِيمُ...)
print("=== Surah 2:127 ===")
rows = cur.execute("SELECT line, word_pos, surah, ayah, word_id, glyph_code FROM word_layout WHERE mushaf='15_line' AND surah=2 AND ayah=127 ORDER BY line, word_pos").fetchall()
for r in rows:
    hexes = [f"0x{ord(c):x} ('{c}')" for c in r[5]]
    print(f"L.{r[0]} P.{r[1]} {r[2]}:{r[3]} id='{r[4]}' text='{r[5]}' hex={hexes}")

# Inspect Surah 2:133 (Image 2: أَمْ كُنْتُمْ شُهَدَاءَ...)
print("\n=== Surah 2:133 ===")
rows = cur.execute("SELECT line, word_pos, surah, ayah, word_id, glyph_code FROM word_layout WHERE mushaf='15_line' AND surah=2 AND ayah=133 ORDER BY line, word_pos").fetchall()
for r in rows:
    print(f"L.{r[0]} P.{r[1]} {r[2]}:{r[3]} id='{r[4]}' text='{r[5]}'")

# Inspect Surah 2:137 (Image 3: فَإِنْ آمَنُوا...)
print("\n=== Surah 2:137 ===")
rows = cur.execute("SELECT line, word_pos, surah, ayah, word_id, glyph_code FROM word_layout WHERE mushaf='15_line' AND surah=2 AND ayah=137 ORDER BY line, word_pos").fetchall()
for r in rows:
    print(f"L.{r[0]} P.{r[1]} {r[2]}:{r[3]} id='{r[4]}' text='{r[5]}'")

con.close()
