import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

print("=== Checking word_id conventions in word_layout ===")
rows = cur.execute("""
    SELECT DISTINCT word_id 
    FROM word_layout 
    WHERE word_id LIKE 'basmallah:%' OR word_id LIKE 'surah_name:%'
    LIMIT 10
""").fetchall()

for r in rows:
    print(r)

# Check if any non-surah/non-ayah word_ids exist
anomalous_ids = cur.execute("""
    SELECT mushaf, page, line, word_id, glyph_code 
    FROM word_layout 
    WHERE word_id NOT LIKE 'surah_name:%' 
      AND word_id NOT LIKE 'basmallah:%' 
      AND word_id NOT LIKE '%:%:%'
""").fetchall()

print(f"Anomalous / fabricated word_id count: {len(anomalous_ids)}")

con.close()
