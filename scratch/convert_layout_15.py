import sqlite3
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

def convert_layout():
    # 1. Define database paths
    layout_db_path = r"D:\AL Quran\qudratullah-indopak-15-lines.db"
    quran_db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"

    if not os.path.exists(layout_db_path):
        print(f"Layout database not found at: {layout_db_path}")
        return
    if not os.path.exists(quran_db_path):
        print(f"Quran database not found at: {quran_db_path}")
        return

    print("Connecting to databases...")
    conn_layout = sqlite3.connect(layout_db_path)
    conn_quran = sqlite3.connect(quran_db_path)

    c_layout = conn_layout.cursor()
    c_quran = conn_quran.cursor()

    # 2. Build global words list from ayahs
    print("Loading Uthmani Quranic text...")
    c_quran.execute("SELECT surah, ayah_number, arabic_text FROM ayahs ORDER BY id ASC;")
    ayahs = c_quran.fetchall()

    all_words = []
    for surah, ayah_num, text in ayahs:
        words = text.strip().split()
        for w_idx, w_text in enumerate(words):
            all_words.append({
                'surah': surah,
                'ayah': ayah_num,
                'word_pos': w_idx + 1,
                'text': w_text
            })

    total_quran_words = len(all_words)
    print(f"Loaded {total_quran_words} words from Quran database.")

    # 3. Clear existing 15_line layout rows
    print("Clearing old 15_line rows in word_layout...")
    c_quran.execute("DELETE FROM word_layout WHERE mushaf = '15_line';")

    # 4. Fetch layout rows from pages table
    c_layout.execute("SELECT page_number, line_number, line_type, first_word_id, last_word_id, surah_number FROM pages ORDER BY page_number ASC, line_number ASC;")
    pages_rows = c_layout.fetchall()

    print("Mapping and inserting layout data...")
    inserted_count = 0

    for page_num, line_num, line_type, first_word_id, last_word_id, surah_num in pages_rows:
        # Check if it's a structural line (surah_name or basmallah)
        if line_type in ('surah_name', 'basmallah') or not first_word_id or not last_word_id:
            # We can insert a special placeholder word for structural lines to render them correctly
            text_placeholder = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ" if line_type == 'basmallah' else f"سورة {surah_num}"
            word_id = f"structural:{page_num}:{line_num}:{line_type}"
            c_quran.execute(
                """
                INSERT INTO word_layout (mushaf, page, line, surah, ayah, word_pos, word_id, glyph_code, font_file)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
                """,
                ('15_line', page_num, line_num, surah_num or 1, 0, 1, word_id, text_placeholder, 'Amiri')
            )
            inserted_count += 1
            continue

        # Map actual words in the specified range
        f_id = int(first_word_id)
        l_id = int(last_word_id)

        for w_id in range(f_id, l_id + 1):
            w_idx = w_id - 1
            if w_idx >= total_quran_words:
                # Clamp/fallback if we exceed the text words list
                continue

            word_info = all_words[w_idx]
            word_key = f"{word_info['surah']}:{word_info['ayah']}:{word_info['word_pos']}"

            c_quran.execute(
                """
                INSERT INTO word_layout (mushaf, page, line, surah, ayah, word_pos, word_id, glyph_code, font_file)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
                """,
                ('15_line', page_num, line_num, word_info['surah'], word_info['ayah'], word_info['word_pos'], word_key, word_info['text'], 'Amiri')
            )
            inserted_count += 1

    conn_quran.commit()
    conn_layout.close()
    conn_quran.close()
    print(f"Layout conversion completed successfully! Imported {inserted_count} words/lines into word_layout.")

if __name__ == "__main__":
    convert_layout()
