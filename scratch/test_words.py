import sqlite3
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get all ayahs of Surah 1
cursor.execute("SELECT id, surah, ayah_number, arabic_text FROM ayahs WHERE surah = 1 ORDER BY ayah_number ASC;")
ayahs = cursor.fetchall()

global_words = []
for aid, surah, ayah_num, text in ayahs:
    words = text.strip().split()
    print(f"Ayah {ayah_num}: {words}")
    for w in words:
        global_words.append(w)

print(f"Total words in Surah 1: {len(global_words)}")
for idx, w in enumerate(global_words[:15]):
    print(f"Word {idx+1}: {w}")

conn.close()
