import sqlite3
import sys, io
from collections import Counter

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

pua_counter = Counter()
rows = cur.execute("SELECT word_id, glyph_code FROM word_layout").fetchall()
for wid, text in rows:
    for c in text:
        code = ord(c)
        if 0xE000 <= code <= 0xF8FF:
            pua_counter[hex(code)] += 1

print(f"Total PUA occurrences across entire database: {sum(pua_counter.values())}")
print("\nTop 40 PUA characters and frequencies:")
for code, count in pua_counter.most_common(40):
    print(f"  {code}: {count:5d} times")

con.close()
