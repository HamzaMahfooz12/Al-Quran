import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

def check_basmallah_surah_field(db_name, db_path):
    print(f"\n=== Basmallah rows in {db_name} ===")
    con = sqlite3.connect(db_path)
    con.row_factory = sqlite3.Row
    cur = con.cursor()

    rows = cur.execute("SELECT page_number, line_number, line_type, surah_number FROM pages WHERE line_type='basmallah'").fetchall()
    print(f"Total 'basmallah' line rows found: {len(rows)}")
    for r in rows[:15]:
        print(f"  p.{r['page_number']:3d} l.{r['line_number']:2d} surah={r['surah_number']}")

    # Also check surah_name rows
    s_rows = cur.execute("SELECT page_number, line_number, surah_number FROM pages WHERE line_type='surah_name'").fetchall()
    print(f"Total 'surah_name' line rows found: {len(s_rows)}")

    # Check for Surah 9 (At-Tawbah) surah_name line and the line following it
    s9_row = cur.execute("SELECT page_number, line_number FROM pages WHERE line_type='surah_name' AND surah_number=9").fetchone()
    if s9_row:
        p9, l9 = s9_row['page_number'], s9_row['line_number']
        print(f"Surah 9 header is at Page {p9} Line {l9}")
        around = cur.execute("SELECT page_number, line_number, line_type, surah_number FROM pages WHERE page_number=? AND line_number BETWEEN ? AND ?", (p9, l9-1, l9+3)).fetchall()
        for r in around:
            print(f"    p.{r['page_number']} l.{r['line_number']} type={r['line_type']} surah={r['surah_number']}")

    con.close()

check_basmallah_surah_field("15-Line DB", r"D:\AL Quran\qudratullah-indopak-15-lines.db")
check_basmallah_surah_field("16-Line DB", r"D:\AL Quran\taj-indopak-16-lines.db")
