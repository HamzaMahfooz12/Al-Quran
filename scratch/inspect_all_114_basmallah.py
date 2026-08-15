import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

l16_path = r"D:\AL Quran\taj-indopak-16-lines.db"
l16_con = sqlite3.connect(l16_path)
l16_cur = l16_con.cursor()

rows = l16_cur.execute("SELECT page_number, line_number, line_type, surah_number FROM pages WHERE line_type='basmallah'").fetchall()
print(f"Total 'basmallah' rows in taj-indopak-16-lines.db: {len(rows)}")

# Let's see why previous check said 30:
# Because previous check filtered by: (page_number < ? OR (page_number=? AND line_number < ?))
# Let's inspect all 114 surahs in taj-indopak-16-lines.db and see where surah_name and basmallah are!

surah_name_rows = l16_cur.execute("SELECT page_number, line_number, line_type, surah_number FROM pages WHERE line_type='surah_name' ORDER BY page_number, line_number").fetchall()
print(f"Total 'surah_name' rows in taj-indopak-16-lines.db: {len(surah_name_rows)}")

print("\nSurah Name and following lines in raw taj-indopak-16-lines.db:")
surah_basmallah_status = {}
for r in surah_name_rows:
    p, l, t, s = r[0], r[1], r[2], int(r[3])
    # check next line on same page or next page
    next_line = l16_cur.execute("SELECT page_number, line_number, line_type, surah_number FROM pages WHERE (page_number = ? AND line_number = ?) OR (page_number = ? AND line_number = 1) ORDER BY page_number, line_number LIMIT 1", (p, l+1, p+1)).fetchone()
    surah_basmallah_status[s] = next_line

for s in range(1, 115):
    status = surah_basmallah_status.get(s)
    print(f"Surah {s:3d} (p.{status[0] if status else '?'}, l.{status[1] if status else '?'}): next line_type='{status[2] if status else 'NONE'}'")

l16_con.close()
