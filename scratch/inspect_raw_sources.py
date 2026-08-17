import json, sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

# Let's inspect the original raw qudratullah-indopak-15-lines.db tables
con_orig = sqlite3.connect(r"D:\AL Quran\qudratullah-indopak-15-lines.db")
cur_orig = con_orig.cursor()
tables = cur_orig.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
print("Tables in qudratullah-indopak-15-lines.db:", tables)

for t in tables:
    cols = cur_orig.execute(f"PRAGMA table_info({t[0]})").fetchall()
    print(f"Table {t[0]} columns:", [c[1] for c in cols])
    sample = cur_orig.execute(f"SELECT * FROM {t[0]} LIMIT 3").fetchall()
    print("Sample:", sample)

# Check indopak-nastaleeq.json for Page 20
with open(r"D:\AL Quran\indopak-nastaleeq.json", "r", encoding="utf-8") as f:
    data = json.load(f)

print("\n=== Page 20 in indopak-nastaleeq.json ===")
p20_json = data.get("20", {})
for line_idx, line_words in list(p20_json.items())[:3]:
    print(f"Line {line_idx}:")
    for w in line_words:
        print(f"   pos={w.get('word_pos')} id={w.get('word_id')} glyph='{w.get('glyph_code')}'")

con_orig.close()
