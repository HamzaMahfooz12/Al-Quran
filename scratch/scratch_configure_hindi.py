# scratch_configure_hindi.py
import gzip
import sqlite3
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

gz_path = 'assets/app_database.sqlite.gz'

print(f"Reading {gz_path}...")
with gzip.open(gz_path, 'rb') as f:
    db_data = f.read()

conn = sqlite3.connect(':memory:')
conn.deserialize(db_data)
cursor = conn.cursor()

# 1. Update Hindi translation names to English in editions table
cursor.execute('''
    UPDATE editions
    SET name = 'Tafhim-ul-Quran (Sayyid Abul A''la Maududi)',
        is_bundled = 0,
        is_downloaded = 0
    WHERE api_key = 'hi.maududi'
''')

cursor.execute('''
    UPDATE editions
    SET name = 'Aasan Tarjuma Quran (Mufti Muhammad Taqi Usmani)',
        is_bundled = 1,
        is_downloaded = 1
    WHERE api_key = 'hi.taqiusmani'
''')

# 2. Delete ayah_content rows for hi.maududi (id: 241) so it is genuinely downloadable
cursor.execute("DELETE FROM ayah_content WHERE edition_id = 241")
deleted_count = cursor.rowcount
print(f"Deleted {deleted_count} cached verses for hi.maududi (now downloadable).")

# 3. Verify counts
cursor.execute("SELECT id, api_key, language, name, is_bundled, is_downloaded FROM editions WHERE language = 'hi'")
for row in cursor.fetchall():
    print("Updated Hindi edition:", row)

cursor.execute("SELECT COUNT(*) FROM ayah_content WHERE edition_id = 502")
print("hi.taqiusmani verses in db (available):", cursor.fetchone()[0])
cursor.execute("SELECT COUNT(*) FROM ayah_content WHERE edition_id = 241")
print("hi.maududi verses in db (downloadable):", cursor.fetchone()[0])

conn.commit()
cursor.execute("VACUUM")

serialized = conn.serialize()
conn.close()

print(f"Compressing back to {gz_path}...")
with gzip.open(gz_path, 'wb', compresslevel=9) as f:
    f.write(serialized)

new_size = os.path.getsize(gz_path)
print(f"Done! New {gz_path} size: {new_size:,} bytes")
