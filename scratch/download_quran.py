import sqlite3
import urllib.request
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

def download_and_seed():
    db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
    
    if not os.path.exists(db_path):
        print(f"Database not found at {db_path}")
        return

    print("Fetching Quran Arabic text...")
    url = "https://api.alquran.cloud/v1/quran/quran-uthmani"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Error fetching Quran: {e}")
        return

    if data.get('status') != 'OK':
        print("Invalid status from API")
        return

    print("Connecting to database...")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clear existing ayahs to reseed cleanly
    cursor.execute("DELETE FROM ayahs;")

    surahs = data['data']['surahs']
    insert_count = 0
    
    print("Seeding ayahs table...")
    for surah in surahs:
        surah_num = surah['number']
        for ayah in surah['ayahs']:
            ayah_num = ayah['numberInSurah']
            text = ayah['text']
            global_id = ayah['number']
            juz = ayah['juz']
            hizb = ayah.get('hizbQuarter', 1)
            ruku = ayah.get('ruku', 1)
            manzil = ayah.get('manzil', 1)
            page = ayah.get('page', 1)
            is_sajda = 1 if ayah.get('sajda') else 0

            cursor.execute(
                """
                INSERT INTO ayahs (id, surah, ayah_number, juz, hizb, ruku, manzil, page, is_sajda, arabic_text)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
                """,
                (global_id, surah_num, ayah_num, juz, hizb, ruku, manzil, page, is_sajda, text)
            )
            insert_count += 1

    conn.commit()
    conn.close()
    print(f"Successfully seeded {insert_count} ayahs into active database!")

if __name__ == "__main__":
    download_and_seed()
