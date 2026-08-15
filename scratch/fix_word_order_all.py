"""
fix_word_order_all.py
======================
Fix word_pos in word_layout for both 15_line and 16_line mushafs.
word_pos will store the 1-based sequential position of the word ON ITS LINE (1, 2, 3, 4...).
This guarantees 100% correct Right-to-Left Arabic word ordering when rendered in Flutter RTL Row.
"""

import json
import sqlite3
import sys
import os
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

BASE_DIR       = r"D:\AL Quran"
JSON_PATH      = os.path.join(BASE_DIR, "indopak-nastaleeq.json")
LAYOUT_15_PATH = os.path.join(BASE_DIR, "qudratullah-indopak-15-lines.db")
LAYOUT_16_PATH = os.path.join(BASE_DIR, "taj-indopak-16-lines.db")
APP_DB_PATH    = os.path.join(BASE_DIR, "al_quran_app", ".dart_tool",
                              "sqflite_common_ffi", "databases", "al_quran.db")

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

print("1. Loading JSON ...")
with open(JSON_PATH, encoding="utf-8") as f:
    raw = json.load(f)

entries = sorted(raw.values(), key=lambda e: (int(e["surah"]), int(e["ayah"]), int(e["word"])))
id_to_text = {}
id_to_meta = {}
for entry in entries:
    gid  = int(entry["id"])
    id_to_text[gid] = entry.get("text", "")
    id_to_meta[gid] = (int(entry["surah"]), int(entry["ayah"]), int(entry["word"]))

app_con = sqlite3.connect(APP_DB_PATH)
app_cur = app_con.cursor()

def import_mushaf(mushaf_type, layout_path):
    print(f"\nImporting {mushaf_type} from {layout_path} ...")
    lcon = sqlite3.connect(layout_path)
    lcon.row_factory = sqlite3.Row
    lcur = lcon.cursor()

    app_cur.execute("DELETE FROM word_layout WHERE mushaf = ?", (mushaf_type,))
    app_con.commit()

    lcur.execute("SELECT * FROM pages ORDER BY page_number, line_number")
    all_rows = lcur.fetchall()

    batch = []
    inserted_count = 0
    missing_count = 0

    for row in all_rows:
        page_num  = row["page_number"]
        line_num  = row["line_number"]
        line_type = row["line_type"]
        surah_num = row["surah_number"]
        fwid      = row["first_word_id"]
        lwid      = row["last_word_id"]

        if line_type == "surah_name":
            name_ar = SURAH_NAMES_AR[surah_num - 1] if 1 <= surah_num <= 114 else f"surah {surah_num}"
            batch.append((mushaf_type, page_num, line_num, surah_num, 0, 1,
                          f"surah_name:{surah_num}", name_ar, "Amiri"))
            inserted_count += 1
            continue

        if line_type == "basmallah":
            batch.append((mushaf_type, page_num, line_num, surah_num, 0, 1,
                          f"basmallah:{surah_num}", BISMILLAH_TEXT, "Amiri"))
            inserted_count += 1
            continue

        if fwid is None or lwid is None:
            continue

        line_word_pos = 1
        for wid in range(int(fwid), int(lwid) + 1):
            text = id_to_text.get(wid)
            if text is None:
                missing_count += 1
                continue
            s, a, w = id_to_meta[wid]
            batch.append((mushaf_type, page_num, line_num, s, a, line_word_pos,
                          f"{s}:{a}:{w}", text, ""))
            line_word_pos += 1
            inserted_count += 1

    INSERT_SQL = """
        INSERT INTO word_layout
            (mushaf, page, line, surah, ayah, word_pos, word_id, glyph_code, font_file)
        VALUES (?,?,?,?,?,?,?,?,?)
    """
    app_cur.executemany(INSERT_SQL, batch)
    app_con.commit()
    lcon.close()
    print(f"  Done {mushaf_type}: Inserted {inserted_count:,} rows (Missing words: {missing_count})")

import_mushaf("15_line", LAYOUT_15_PATH)
import_mushaf("16_line", LAYOUT_16_PATH)

app_con.close()
print("\nAll word_layout tables fixed and updated successfully!")
