"""
fix_word_order_all.py
======================
Re-import both 15_line and 16_line word_layout tables with:
1. Sequential word_pos per line (1, 2, 3...) for 100% proper Right-to-Left Arabic text.
2. Complete Bismillah header insertion with CORRECT surah integer ID (2..114 excl. 9).
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

    current_surah = 1
    surahs_with_basmallah = set()

    for idx, row in enumerate(all_rows):
        page_num  = row["page_number"]
        line_num  = row["line_number"]
        line_type = row["line_type"]
        fwid      = row["first_word_id"]
        lwid      = row["last_word_id"]

        surah_raw = row["surah_number"]
        surah_num = int(surah_raw) if (surah_raw is not None and str(surah_raw).isdigit()) else None

        if surah_num is not None:
            current_surah = surah_num

        if line_type == "surah_name":
            s_id = surah_num if (surah_num is not None and surah_num > 0) else current_surah
            name_ar = SURAH_NAMES_AR[s_id - 1] if 1 <= s_id <= 114 else f"surah {s_id}"
            batch.append((mushaf_type, page_num, line_num, s_id, 0, 1,
                          f"surah_name:{s_id}", name_ar, "Amiri"))
            inserted_count += 1

            # If surah is 2..114 (excl 9) and next line is not 'basmallah', insert explicit basmallah line
            if s_id != 1 and s_id != 9:
                next_is_basmallah = False
                if idx + 1 < len(all_rows):
                    next_row = all_rows[idx + 1]
                    if next_row["line_type"] == "basmallah":
                        next_is_basmallah = True
                
                if not next_is_basmallah:
                    batch.append((mushaf_type, page_num, line_num, s_id, 0, 2,
                                  f"basmallah:{s_id}", BISMILLAH_TEXT, "Amiri"))
                    inserted_count += 1
                    surahs_with_basmallah.add(s_id)
            continue

        if line_type == "basmallah":
            s_id = surah_num if (surah_num is not None and surah_num > 0) else current_surah
            batch.append((mushaf_type, page_num, line_num, s_id, 0, 1,
                          f"basmallah:{s_id}", BISMILLAH_TEXT, "Amiri"))
            inserted_count += 1
            surahs_with_basmallah.add(s_id)
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
    print(f"  Total Surahs with Basmallah header in {mushaf_type}: {len(surahs_with_basmallah)} (Expected: 112)")

import_mushaf("15_line", LAYOUT_15_PATH)
import_mushaf("16_line", LAYOUT_16_PATH)

app_con.close()
print("\nBoth 15_line and 16_line word_layout tables populated with complete Bismillah headers & correct surah IDs!")
