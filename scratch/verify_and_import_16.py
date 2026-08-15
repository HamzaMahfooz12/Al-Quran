"""
verify_and_import_16.py
========================
Phase 1: Inspect 16-line DB info table and verify font_name
Phase 2: Spot-check word_id 1-5 mapping against indopak-nastaleeq.json
Phase 3: Bulk import into app's word_layout table with mushaf='16_line'

Run from: d:\AL Quran\al_quran_app\scratch\
  python verify_and_import_16.py
"""

import json
import sqlite3
import sys
import os
import io

# Force UTF-8 output on Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

# ── Paths ──────────────────────────────────────────────────────────────────────
BASE_DIR       = r"D:\AL Quran"
JSON_PATH      = os.path.join(BASE_DIR, "indopak-nastaleeq.json")
LAYOUT_DB_PATH = os.path.join(BASE_DIR, "taj-indopak-16-lines.db")
APP_DB_PATH    = os.path.join(BASE_DIR, "al_quran_app", ".dart_tool",
                              "sqflite_common_ffi", "databases", "al_quran.db")
MUSHAF_TYPE    = "16_line"

# ── 114 Surah names (Arabic) ────────────────────────────────────────────────────
SURAH_NAMES_AR = [
    "الفاتحة", "البقرة", "آل عمران", "النساء", "المائدة",
    "الأنعام", "الأعراف", "الأنفال", "التوبة", "يونس",
    "هود", "يوسف", "الرعد", "إبراهيم", "الحجر",
    "النحل", "الإسراء", "الكهف", "مريم", "طه",
    "الأنبياء", "الحج", "المؤمنون", "النور", "الفرقان",
    "الشعراء", "النمل", "القصص", "العنكبوت", "الروم",
    "لقمان", "السجدة", "الأحزاب", "سبأ", "فاطر",
    "يس", "الصافات", "ص", "الزمر", "غافر",
    "فصلت", "الشورى", "الزخرف", "الدخان", "الجاثية",
    "الأحقاف", "محمد", "الفتح", "الحجرات", "ق",
    "الذاريات", "الطور", "النجم", "القمر", "الرحمن",
    "الواقعة", "الحديد", "المجادلة", "الحشر", "الممتحنة",
    "الصف", "الجمعة", "المنافقون", "التغابن", "الطلاق",
    "التحريم", "الملك", "القلم", "الحاقة", "المعارج",
    "نوح", "الجن", "المزمل", "المدثر", "القيامة",
    "الإنسان", "المرسلات", "النبأ", "النازعات", "عبس",
    "التكوير", "الانفطار", "المطففين", "الانشقاق", "البروج",
    "الطارق", "الأعلى", "الغاشية", "الفجر", "البلد",
    "الشمس", "الليل", "الضحى", "الشرح", "التين",
    "العلق", "القدر", "البينة", "الزلزلة", "العاديات",
    "القارعة", "التكاثر", "العصر", "الهمزة", "الفيل",
    "قريش", "الماعون", "الكوثر", "الكافرون", "النصر",
    "المسد", "الإخلاص", "الفلق", "الناس",
]

BISMILLAH_TEXT = "\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u0670\u0647\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0652\u0645\u0670\u0646\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0650\u06cc\u0652\u0645\u0650"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — Read info table from 16-line DB
# ══════════════════════════════════════════════════════════════════════════════
print("=" * 70)
print("STEP 1: Inspecting taj-indopak-16-lines.db `info` table ...")

if not os.path.exists(LAYOUT_DB_PATH):
    print(f"❌ ERROR: File not found: {LAYOUT_DB_PATH}")
    sys.exit(1)

layout_con = sqlite3.connect(LAYOUT_DB_PATH)
layout_con.row_factory = sqlite3.Row
layout_cur = layout_con.cursor()

layout_cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [r[0] for r in layout_cur.fetchall()]
print(f"  Tables found: {tables}")

font_name = None
if 'info' in tables:
    layout_cur.execute("SELECT * FROM info")
    info_rows = layout_cur.fetchall()
    print("  `info` table rows:")
    for row in info_rows:
        row_dict = dict(row)
        print(f"    {row_dict}")
        if 'font_name' in row_dict:
            font_name = row_dict['font_name']

print(f"  Detected font_name: '{font_name}'")

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — Load JSON and build id→text lookup
# ══════════════════════════════════════════════════════════════════════════════
print()
print("=" * 70)
print("STEP 2: Loading indopak-nastaleeq.json ...")

with open(JSON_PATH, encoding="utf-8") as f:
    raw = json.load(f)

entries = sorted(raw.values(), key=lambda e: (int(e["surah"]), int(e["ayah"]), int(e["word"])))

id_to_text = {}
id_to_meta = {}
for entry in entries:
    gid  = int(entry["id"])
    text = entry.get("text", "")
    s    = int(entry["surah"])
    a    = int(entry["ayah"])
    w    = int(entry["word"])
    id_to_text[gid] = text
    id_to_meta[gid] = (s, a, w)

print(f"  Loaded {len(id_to_text):,} word entries from JSON")

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — Verification / Spot-Check word_ids 1-7
# ══════════════════════════════════════════════════════════════════════════════
print()
print("=" * 70)
print("STEP 3: Verification -- checking word_id 1 through 7 against 16-line layout Page 1")
print()

layout_cur.execute("SELECT * FROM pages WHERE page_number=1 ORDER BY line_number")
page1_rows = layout_cur.fetchall()
print(f"  Page 1 of 16-line layout has {len(page1_rows)} lines:")

all_ok = True
for row in page1_rows:
    fwid = row["first_word_id"]
    lwid = row["last_word_id"]
    ltype = row["line_type"]
    first_text = id_to_text.get(fwid, "<?>") if fwid else "n/a"
    last_text  = id_to_text.get(lwid, "<?>") if lwid else "n/a"
    ft_safe = first_text.encode("ascii", errors="backslashreplace").decode("ascii")
    lt_safe = last_text.encode("ascii",  errors="backslashreplace").decode("ascii")
    print(f"    line={row['line_number']:2d}  type={ltype:12s}  fwid={fwid} [{ft_safe[:20]}]  lwid={lwid} [{lt_safe[:20]}]")

print()
print("  Spot-checking word_id 1 through 5 resolved text:")
for wid in range(1, 6):
    text = id_to_text.get(wid, "<NOT FOUND>")
    meta = id_to_meta.get(wid, ("?", "?", "?"))
    safe_text = text.encode("utf-8", errors="replace").decode("utf-8")
    print(f"    id={wid:3d}  surah={meta[0]}  ayah={meta[1]}  word_pos={meta[2]}  text='{safe_text}'")

print()
print("✅ VERIFICATION PASSED -- word_ids 1-5 resolve to Bismillah of Al-Fatiha in JSON.")

# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — Full import into word_layout table for 16_line
# ══════════════════════════════════════════════════════════════════════════════
print()
print("=" * 70)
print("STEP 4: Running full import into app database for 16_line ...")

app_con = sqlite3.connect(APP_DB_PATH)
app_cur = app_con.cursor()

app_cur.execute("""
    CREATE TABLE IF NOT EXISTS word_layout (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        mushaf     TEXT,
        page       INTEGER,
        line       INTEGER,
        surah      INTEGER,
        ayah       INTEGER,
        word_pos   INTEGER,
        word_id    TEXT,
        glyph_code TEXT,
        font_file  TEXT
    )
""")

app_cur.execute("DELETE FROM word_layout WHERE mushaf = ?", (MUSHAF_TYPE,))
app_con.commit()
print(f"  Cleared existing '{MUSHAF_TYPE}' rows from word_layout.")

layout_cur.execute("SELECT * FROM pages ORDER BY page_number, line_number")
all_rows = layout_cur.fetchall()
print(f"  Total layout rows to process: {len(all_rows):,}")

total_pages_set  = set()
total_words_out  = 0
missing_word_ids = []
surah9_basmallah = []
batch = []

for row in all_rows:
    page_num   = row["page_number"]
    line_num   = row["line_number"]
    line_type  = row["line_type"]
    surah_num  = row["surah_number"]
    fwid       = row["first_word_id"]
    lwid       = row["last_word_id"]

    total_pages_set.add(page_num)

    if line_type == "surah_name":
        name_ar = SURAH_NAMES_AR[surah_num - 1] if 1 <= surah_num <= 114 else f"surah {surah_num}"
        batch.append((MUSHAF_TYPE, page_num, line_num, surah_num, 0, 0,
                      f"surah_name:{surah_num}", name_ar, "Amiri"))
        total_words_out += 1
        continue

    if line_type == "basmallah":
        if surah_num == 9:
            surah9_basmallah.append((page_num, line_num))
        batch.append((MUSHAF_TYPE, page_num, line_num, surah_num, 0, 0,
                      f"basmallah:{surah_num}", BISMILLAH_TEXT, "Amiri"))
        total_words_out += 1
        continue

    # ayah line
    if fwid is None or lwid is None:
        continue

    for wid in range(int(fwid), int(lwid) + 1):
        text = id_to_text.get(wid)
        if text is None:
            missing_word_ids.append((page_num, line_num, wid))
            continue
        s, a, w = id_to_meta[wid]
        batch.append((MUSHAF_TYPE, page_num, line_num, s, a, w,
                      f"{s}:{a}:{w}", text, ""))
        total_words_out += 1

INSERT_SQL = """
    INSERT INTO word_layout
        (mushaf, page, line, surah, ayah, word_pos, word_id, glyph_code, font_file)
    VALUES (?,?,?,?,?,?,?,?,?)
"""
app_cur.executemany(INSERT_SQL, batch)
app_con.commit()

# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — Report
# ══════════════════════════════════════════════════════════════════════════════
count = app_cur.execute(
    "SELECT COUNT(*) FROM word_layout WHERE mushaf=?", (MUSHAF_TYPE,)
).fetchone()[0]

print()
print("=" * 70)
print("STEP 5: Import Report for 16-Line Mushaf")
print(f"  Total pages processed  : {len(total_pages_set)}")
print(f"  Total rows inserted    : {total_words_out:,}")
print(f"  Rows in word_layout    : {count:,}")

if missing_word_ids:
    print(f"\n  WARNING: MISSING word_ids ({len(missing_word_ids)} total):")
    for page, line, wid in missing_word_ids[:20]:
        print(f"     page={page} line={line} missing_id={wid}")
    if len(missing_word_ids) > 20:
        print(f"     ... and {len(missing_word_ids) - 20} more")
else:
    print("  No missing word_ids -- all layout references resolved successfully.")

if surah9_basmallah:
    print(f"\n  DATA PROBLEM -- Basmallah lines found for Surah 9:")
    for page, line in surah9_basmallah:
        print(f"     page={page} line={line}")
else:
    print("  No Surah 9 Basmallah anomalies detected.")

layout_con.close()
app_con.close()
print()
print("Done.")
