import sqlite3
import os

def convert_layout():
    # 1. Define paths (Adjust input path to the downloaded layout db filename)
    input_db_path = r"D:\AL Quran\qudratullah-indopak-15-lines.db"
    output_db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"

    if not os.path.exists(input_db_path):
        print(f"Input layout database not found at: {input_db_path}")
        return

    print("Opening databases...")
    conn_in = sqlite3.connect(input_db_path)
    conn_out = sqlite3.connect(output_db_path)

    cursor_in = conn_in.cursor()
    cursor_out = conn_out.cursor()

    # Clear existing 15_line layouts to prevent duplicate keys
    cursor_out.execute("DELETE FROM word_layout WHERE mushaf = '15_line';")

    print("Reading layout pages table...")
    cursor_in.execute("SELECT page_number, line_number, first_word_id, last_word_id, surah_number FROM pages;")
    rows = cursor_in.fetchall()

    insert_count = 0
    for page_num, line_num, first_id, last_id, surah_num in rows:
        # Check if this line has words assigned
        if first_id is None or last_id is None:
            continue
        
        # Insert word layouts for the line segment
        for word_pos in range(first_id, last_id + 1):
            word_id = f"{surah_num}:{page_num}:{word_pos}"
            # Calculate corresponding QCF Font file page index (47 files cover the 604 pages)
            font_index = ((page_num - 1) // 13) + 1
            font_file = f"QCF_P{str(font_index).zfill(3)}"

            cursor_out.execute(
                """
                INSERT INTO word_layout (mushaf, page, line, surah, ayah, word_pos, word_id, glyph_code, font_file)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
                """,
                ('15_line', page_num, line_num, surah_num, 1, word_pos, word_id, chr(0xE000 + word_pos), font_file)
            )
            insert_count += 1

    conn_out.commit()
    conn_in.close()
    conn_out.close()
    print(f"Conversion completed successfully! Imported {insert_count} word layouts into target database.")

if __name__ == "__main__":
    convert_layout()
