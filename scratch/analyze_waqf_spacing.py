import sqlite3
import re
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

# Find words with trailing waqf marks in word_layout
rows = cur.execute("""
    SELECT word_id, glyph_code 
    FROM word_layout 
    WHERE glyph_code LIKE '% %' AND word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%'
    LIMIT 30
""").fetchall()

print(f"Sample words with spaces/waqf marks: ({len(rows)} samples)")
for wid, text in rows[:15]:
    hexes = [f"0x{ord(c):X} ('{c}')" for c in text]
    print(f"id={wid:12s} text='{text}' | hex={hexes}")

con.close()
