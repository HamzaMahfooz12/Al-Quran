import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

print("=== Sample Ayahs with Ruku info ===")
rows = cur.execute("SELECT id, surah, ayah_number, ruku, juz, page FROM ayahs LIMIT 35").fetchall()
for r in rows:
    print(f"id={r[0]:4d} surah={r[1]:2d} ayah={r[2]:3d} ruku={r[3]:3d} juz={r[4]:2d} page={r[5]:3d}")

# Check Ruku changes (where ruku number increments)
print("\n=== Ruku transition points in Surah 2 ===")
rows = cur.execute("""
    SELECT a1.surah, a1.ayah_number, a1.ruku, a1.page
    FROM ayahs a1
    LEFT JOIN ayahs a2 ON a1.surah = a2.surah AND a1.ayah_number = a2.ayah_number + 1
    WHERE a1.surah = 2 AND (a2.ruku IS NULL OR a1.ruku != a2.ruku)
    LIMIT 15
""").fetchall()
for r in rows:
    print(f"Surah {r[0]} Ayah {r[1]} is start/end of Ruku {r[2]} (Page {r[3]})")

con.close()
