import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

# Inspect words around Line 1 (7:164:7, 7:164:8), Line 4 (7:165:15), Line 9 (7:169:1)
target_words = ['7:164:7', '7:164:8', '7:165:14', '7:165:15', '7:169:1', '7:169:2']

for wid in target_words:
    row = cur.execute("SELECT mushaf, page, line, word_pos, word_id, glyph_code FROM word_layout WHERE mushaf='15_line' AND word_id=?", (wid,)).fetchone()
    if row:
        hexes = [f"0x{ord(c):x} ('{c}')" for c in row[5]]
        print(f"id='{row[4]}' text='{row[5]}' hex={hexes}")

# Find ALL characters in word_layout that are in Private Use Area (0xE000-0xF8FF) across the entire dataset!
pua_chars = set()
rows_all = cur.execute("SELECT DISTINCT glyph_code FROM word_layout").fetchall()
for r in rows_all:
    for c in r[0]:
        code = ord(c)
        if 0xE000 <= code <= 0xF8FF:
            pua_chars.add((hex(code), c))

print(f"\nTotal unique Private Use Area (PUA) characters in word_layout: {len(pua_chars)}")
print("Sample PUA characters found:")
for hex_c, c in sorted(list(pua_chars))[:25]:
    print(f"  {hex_c}")

con.close()
