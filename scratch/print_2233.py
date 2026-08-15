import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

def print_2233():
    print("=" * 80)
    print("SURAH 2:233 WORD COMPARISON")
    print("=" * 80)

    uth_text = cur.execute("SELECT arabic_text FROM ayahs WHERE surah=2 AND ayah_number=233").fetchone()[0]
    words_15 = cur.execute("SELECT page, line, word_pos, glyph_code FROM word_layout WHERE mushaf='15_line' AND surah=2 AND ayah=233 AND word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%' ORDER BY page, line, word_pos").fetchall()
    words_16 = cur.execute("SELECT page, line, word_pos, glyph_code FROM word_layout WHERE mushaf='16_line' AND surah=2 AND ayah=233 AND word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%' ORDER BY page, line, word_pos").fetchall()

    print(f"\n[A] Uthmani Text ({len(uth_text.split())} words):")
    print(f"    {uth_text}")

    print(f"\n[B] IndoPak 15-Line ({len(words_15)} entries incl. verse-end symbol):")
    for i, w in enumerate(words_15, 1):
        print(f"    {i:2d}. P.{w[0]} L.{w[1]} Pos.{w[2]} : '{w[3]}'")

    print(f"\n[C] IndoPak 16-Line ({len(words_16)} entries incl. verse-end symbol):")
    for i, w in enumerate(words_16, 1):
        print(f"    {i:2d}. P.{w[0]} L.{w[1]} Pos.{w[2]} : '{w[3]}'")

print_2233()
con.close()
