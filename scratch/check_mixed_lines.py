import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

print("=" * 80)
print("CHECKING FOR ANY LINES MIXING HEADERS AND AYAH WORDS ACROSS ALL PAGES")
print("=" * 80)

mixed_lines_query = """
    SELECT mushaf, page, line, 
           COUNT(CASE WHEN word_id LIKE 'surah_name:%' OR word_id LIKE 'basmallah:%' THEN 1 END) as header_count,
           COUNT(CASE WHEN word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%' THEN 1 END) as ayah_count
    FROM word_layout
    GROUP BY mushaf, page, line
    HAVING header_count > 0 AND ayah_count > 0
    ORDER BY mushaf, page, line
"""

mixed_rows = cur.execute(mixed_lines_query).fetchall()

print(f"Total lines found mixing headers and ayah words: {len(mixed_rows)}")
if mixed_rows:
    for r in mixed_rows:
        print(f"  Mushaf: {r[0]} | Page: {r[1]:3d} | Line: {r[2]:2d} | Headers: {r[3]} | Ayah Words: {r[4]}")
else:
    print("✅ PERFECT: 0 lines across ALL pages of 15-line and 16-line mushafs mix headers with ayah words.")

con.close()
