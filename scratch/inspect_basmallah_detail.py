import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

def inspect_basmallah(db_name, db_path):
    print(f"\n=== Inspecting {db_name} ===")
    con = sqlite3.connect(db_path)
    con.row_factory = sqlite3.Row
    cur = con.cursor()

    # Check distinct line_types
    ltypes = cur.execute("SELECT DISTINCT line_type FROM pages").fetchall()
    print(f"Distinct line_types: {[r[0] for r in ltypes]}")

    # Check rows for Surah 2, 3, 4 where line_type='basmallah' or line_type='surah_name'
    rows = cur.execute("""
        SELECT page_number, line_number, line_type, surah_number, first_word_id, last_word_id 
        FROM pages 
        WHERE surah_number IN (1, 2, 3, 4, 9, 10, 36, 114) AND line_type != 'ayah'
        ORDER BY page_number, line_number
    """).fetchall()

    for r in rows:
        print(f"  p.{r['page_number']:3d} l.{r['line_number']:2d} type={r['line_type']:12s} surah={r['surah_number']:3d} fwid={r['first_word_id']} lwid={r['last_word_id']}")

    con.close()

inspect_basmallah("15-Line DB", r"D:\AL Quran\qudratullah-indopak-15-lines.db")
inspect_basmallah("16-Line DB", r"D:\AL Quran\taj-indopak-16-lines.db")
