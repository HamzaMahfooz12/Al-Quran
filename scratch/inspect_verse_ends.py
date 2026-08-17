import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

# Find the last word of every ayah in word_layout
rows = cur.execute("""
    SELECT surah, ayah, max(CAST(substr(word_id, length(surah || ':' || ayah || ':') + 1) AS INTEGER)) as max_w, glyph_code, word_id
    FROM word_layout
    WHERE mushaf='15_line' AND word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%'
    GROUP BY surah, ayah
    LIMIT 20
""").fetchall()

print("=== Actual Verse End Tokens in word_layout ===")
for r in rows:
    hexes = [f"0x{ord(c):x}" for c in r[3]]
    print(f"Surah {r[0]:3d} Ayah {r[1]:3d} word_{r[2]} : text='{r[3]}' id='{r[4]}' hex={hexes}")

# Check how many total ayahs exist and what the last word is for each
total_ayahs = cur.execute("SELECT COUNT(*) FROM ayahs").fetchone()[0]
print(f"\nTotal canonical ayahs: {total_ayahs}")

# Check if every ayah's LAST word in word_layout starts with 0x06DF (the circle waqf/ayah symbol in indopak) or has specific property
ayah_end_tokens = cur.execute("""
    SELECT w.surah, w.ayah, w.word_pos, w.glyph_code, w.word_id
    FROM word_layout w
    JOIN (
        SELECT surah, ayah, max(CAST(substr(word_id, length(surah || ':' || ayah || ':') + 1) AS INTEGER)) as max_w
        FROM word_layout
        WHERE mushaf='15_line' AND word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%'
        GROUP BY surah, ayah
    ) last_w ON w.surah = last_w.surah AND w.ayah = last_w.ayah 
           AND CAST(substr(w.word_id, length(w.surah || ':' || w.ayah || ':') + 1) AS INTEGER) = last_w.max_w
    WHERE w.mushaf='15_line'
""").fetchall()

print(f"Total verse end tokens found: {len(ayah_end_tokens)}")
non_df_count = 0
for r in ayah_end_tokens:
    if not r[3].startswith('\u06df') and not r[3].startswith('﴿') and '' not in r[3] and '\uf500' not in r[3]:
        non_df_count += 1
        print(f"  Non-standard end token: Surah {r[0]} Ayah {r[1]} : '{r[3]}' id={r[4]}")

print(f"Total non-standard verse end tokens: {non_df_count}")

con.close()
