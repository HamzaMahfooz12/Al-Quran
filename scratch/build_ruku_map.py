import sqlite3
import json
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

# Get all ayahs ordered by surah, ayah_number
cur.execute("SELECT surah, ayah_number, ruku FROM ayahs ORDER BY surah, ayah_number")
rows = cur.fetchall()

ruku_end_map = {} # (surah, ayah) -> { ruku_in_surah, global_ruku }
current_surah = None
surah_ruku_count = 0
prev_ruku = None

for i, (s, a, r) in enumerate(rows):
    if s != current_surah:
        current_surah = s
        surah_ruku_count = 0
        prev_ruku = None

    if r != prev_ruku:
        surah_ruku_count += 1
        prev_ruku = r

    # Check if next ayah has different ruku or different surah
    is_last_in_ruku = False
    if i == len(rows) - 1:
        is_last_in_ruku = True
    else:
        next_s, next_a, next_r = rows[i+1]
        if next_s != s or next_r != r:
            is_last_in_ruku = True

    if is_last_in_ruku:
        ruku_end_map[f"{s}:{a}"] = {
            "surah": s,
            "ayah": a,
            "ruku_in_surah": surah_ruku_count,
            "global_ruku": r
        }

print(f"Found {len(ruku_end_map)} Ruku end positions in Quran database.")
print("Sample entries:")
for k in list(ruku_end_map.keys())[:10]:
    print(f"  {k} -> {ruku_end_map[k]}")

# Save to a Dart/JSON format so we can use it in the Flutter app or repository
with open(r"D:\AL Quran\al_quran_app\lib\data\ruku_map.json", "w", encoding="utf-8") as f:
    json.dump(ruku_end_map, f, indent=2)

con.close()
print("Wrote ruku_map.json successfully.")
