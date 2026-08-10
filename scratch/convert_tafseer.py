# convert_tafseer.py
import os
import json
import sqlite3
import sys
import gzip
import shutil

sys.stdout.reconfigure(encoding='utf-8')

import re

def clean_html(text):
    if not text:
        return ""
    # Replace line break tags with newlines
    s = re.sub(r'</p>|<br\s*/?>|</div>', '\n', str(text), flags=re.IGNORECASE)
    # Strip HTML tags
    s = re.sub(r'<[^>]*>', '', s)
    # Clean HTML entities
    s = s.replace('&nbsp;', ' ').replace('&quot;', '"').replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>').replace('&#39;', "'")
    # Normalize multiple linebreaks
    s = re.sub(r'\n\s*\n+', '\n\n', s)
    return s.strip()

SOURCE_DIR = r"D:\AL Quran\tafssir"
DB_OUT = r"D:\AL Quran\al_quran_app\assets\bundled_editions.sqlite"
MANIFEST_OUT = r"D:\AL Quran\al_quran_app\assets\downloadable_editions.json"

# Ensure assets dir exists
os.makedirs(os.path.dirname(DB_OUT), exist_ok=True)

# Standard Quran surah verse counts (114 surahs)
SURAH_AYAH_COUNTS = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
]

surah_ayah_to_global = {}
curr_id = 1
for s_idx, count in enumerate(SURAH_AYAH_COUNTS, start=1):
    for a_num in range(1, count + 1):
        surah_ayah_to_global[f"{s_idx}:{a_num}"] = curr_id
        curr_id += 1

print(f"Total global ayahs mapped: {len(surah_ayah_to_global)}") # 6236

# Selections for bundling (4 files: 1 Arabic, 2 Urdu, 1 Hindi)
BUNDLED_FILES = [
    {"folder": "arabic", "file": "ar-tafsir-ibn-kathir.json", "id": 101, "lang": "ar", "name": "Tafsir Ibn Kathir (تفسير ابن كثير)"},
    {"folder": "urdu", "file": "tafseer-ibn-e-kaseer-urdu.json", "id": 103, "lang": "ur", "name": "Tafseer Ibn e Kaseer (تفسیر ابن کثیر اردو)"},
    {"folder": "urdu", "file": "tafsir-bayan-ul-quran.json", "id": 104, "lang": "ur", "name": "Tafseer Bayan ul Quran (تفسیر بیان القرآن)"},
    {"folder": "hindi", "file": "hindi-mokhtasar.json", "id": 105, "lang": "hi", "name": "Al-Mukhtasar Hindi (तफ़सीर अल-मुख़्तसर)"},
]

DOWNLOADABLE_FILES = [
    # Arabic (6 remaining — only al-Tabari moved from bundled, plus the rest)
    {"folder": "arabic", "file": "ar-tafsir-al-tabari.json", "id": 102, "lang": "ar", "name": "Tafsir al-Tabari (تفسير الطبري)"},
    {"folder": "arabic", "file": "ar-tafseer-al-qurtubi.json", "id": 201, "lang": "ar", "name": "Tafseer Al-Qurtubi (تفسير القرطبي)"},
    {"folder": "arabic", "file": "ar-tafseer-al-saddi.json", "id": 202, "lang": "ar", "name": "Tafseer As-Sa'di (تفسير السعدي)"},
    {"folder": "arabic", "file": "asseraj-fi-bayan-gharib-alquran.json", "id": 203, "lang": "ar", "name": "As-Seraj Fi Bayan Gharib Al-Quran"},
    {"folder": "arabic", "file": "tafsir-ibn-abi-hatim.json", "id": 204, "lang": "ar", "name": "Tafsir Ibn Abi Hatim"},
    {"folder": "arabic", "file": "tafsir-ibn-uthaymeen.json", "id": 205, "lang": "ar", "name": "Tafsir Ibn Uthaymeen"},
    {"folder": "arabic", "file": "tafsir-jalalayn.json", "id": 206, "lang": "ar", "name": "Tafsir Al-Jalalayn (تفسير الجلالين)"},
    # Urdu (3 remaining)
    {"folder": "urdu", "file": "tafsir-as-saadi.json", "id": 207, "lang": "ur", "name": "Tafseer As-Sa'di Urdu"},
    {"folder": "urdu", "file": "tafsir-fe-zalul-quran-syed-qatab.json", "id": 208, "lang": "ur", "name": "Fi Zilal al-Quran (Syed Qutb)"},
    {"folder": "urdu", "file": "tazkiru-quran-ur.json", "id": 209, "lang": "ur", "name": "Tazkirul Quran Urdu"},
    # English (5 — all English now downloadable)
    {"folder": "english", "file": "en-tafisr-ibn-kathir.json", "id": 106, "lang": "en", "name": "Tafseer Ibn Kathir English"},
    {"folder": "english", "file": "Al-Mukhtasar.json", "id": 210, "lang": "en", "name": "Al-Mukhtasar English"},
    {"folder": "english", "file": "en-tafsir-maarif-ul-quran.json", "id": 211, "lang": "en", "name": "Ma'arif-ul-Quran English"},
    {"folder": "english", "file": "tafsir-al-jalalayn.json", "id": 212, "lang": "en", "name": "Tafsir Al-Jalalayn English"},
    {"folder": "english", "file": "tazkirul-quran-en.json", "id": 213, "lang": "en", "name": "Tazkirul Quran English"},
]

if os.path.exists(DB_OUT):
    os.remove(DB_OUT)

conn = sqlite3.connect(DB_OUT)
cursor = conn.cursor()

# Schema aligning with app's DB
cursor.execute('''
CREATE TABLE IF NOT EXISTS editions (
  id INTEGER PRIMARY KEY,
  type TEXT,
  language TEXT,
  name TEXT,
  api_key TEXT,
  is_bundled INTEGER DEFAULT 1,
  is_downloaded INTEGER DEFAULT 1
);
''')

cursor.execute('''
CREATE TABLE IF NOT EXISTS ayah_content (
  ayah_id INTEGER,
  edition_id INTEGER,
  text TEXT,
  PRIMARY KEY (ayah_id, edition_id)
);
''')

total_rows_inserted = 0

for item in BUNDLED_FILES:
    fpath = os.path.join(SOURCE_DIR, item["folder"], item["file"])
    api_key = item["file"].replace(".json", "")
    print(f"Processing {item['name']} from {fpath}...")
    
    cursor.execute('''
    INSERT INTO editions (id, type, language, name, api_key, is_bundled, is_downloaded)
    VALUES (?, ?, ?, ?, ?, 1, 1)
    ''', (item["id"], "tafseer", item["lang"], item["name"], api_key))
    
    with open(fpath, "r", encoding="utf-8") as f:
        tafseer_dict = json.load(f)
    
    rows = []
    unmapped = 0
    for key, val in tafseer_dict.items():
        text_str = val.get("text", "") if isinstance(val, dict) else str(val)
        text_str = clean_html(text_str)
        if key in surah_ayah_to_global:
            global_ayah_id = surah_ayah_to_global[key]
            rows.append((global_ayah_id, item["id"], text_str))
        else:
            unmapped += 1
            
    cursor.executemany('''
    INSERT INTO ayah_content (ayah_id, edition_id, text) VALUES (?, ?, ?)
    ''', rows)
    conn.commit()
    print(f"  Inserted {len(rows)} ayahs (Unmapped/extra keys: {unmapped})")
    total_rows_inserted += len(rows)

# Create index on ayah_content for fast lookups
cursor.execute('CREATE INDEX IF NOT EXISTS idx_ayah_content_lookup ON ayah_content(ayah_id, edition_id);')
conn.commit()

# Optimize / Vacuum DB
cursor.execute('VACUUM;')
conn.close()

db_size_bytes = os.path.getsize(DB_OUT)
db_size_mb = db_size_bytes / (1024 * 1024)
print(f"\nFinal SQLite DB generated at {DB_OUT}")
print(f"Uncompressed DB Size: {db_size_mb:.2f} MB ({db_size_bytes:,} bytes)")
print(f"Total rows inserted: {total_rows_inserted:,}")

# ── Gzip Compression ──────────────────────────────────────────────────────────
GZ_OUT = DB_OUT + '.gz'
print(f"\nCompressing with gzip (level=9)...")
with open(DB_OUT, 'rb') as f_in:
    with gzip.open(GZ_OUT, 'wb', compresslevel=9) as f_out:
        shutil.copyfileobj(f_in, f_out)

gz_size_bytes = os.path.getsize(GZ_OUT)
gz_size_mb = gz_size_bytes / (1024 * 1024)
ratio = (1 - gz_size_bytes / db_size_bytes) * 100
print(f"Compressed .gz file: {GZ_OUT}")
print(f"Compressed Size:      {gz_size_mb:.2f} MB ({gz_size_bytes:,} bytes)")
print(f"Compression Ratio:    {ratio:.1f}% reduction")

# Generate JSON Manifest
manifest = []
for item in DOWNLOADABLE_FILES:
    api_key = item["file"].replace(".json", "")
    fpath_rel = f"tafssir/{item['folder']}/{item['file']}"
    manifest.append({
        "id": item["id"],
        "type": "tafseer",
        "language": item["lang"],
        "name": item["name"],
        "api_key": api_key,
        "is_bundled": 0,
        "is_downloaded": 0,
        "source": fpath_rel
    })

with open(MANIFEST_OUT, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)

print(f"Manifest written to {MANIFEST_OUT} ({len(manifest)} editions)")
