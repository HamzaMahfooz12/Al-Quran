import sqlite3
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_layout = sqlite3.connect(r"D:\AL Quran\qudratullah-indopak-15-lines.db")
conn_quran = sqlite3.connect(r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db")

c_layout = conn_layout.cursor()
c_quran = conn_quran.cursor()

# Get all words from the Quran database in order
c_quran.execute("SELECT arabic_text FROM ayahs ORDER BY id ASC;")
texts = [r[0] for r in c_quran.fetchall()]
all_words = []
for t in texts:
    all_words.extend(t.strip().split())

print(f"Total words in Quran text: {len(all_words)}")

# Print some page lines mapping
c_layout.execute("SELECT page_number, line_number, first_word_id, last_word_id FROM pages WHERE page_number = 1;")
lines = c_layout.fetchall()
for page_num, line_num, first_id, last_id in lines:
    if first_id and last_id:
        f_idx = int(first_id) - 1
        l_idx = int(last_id) - 1
        words_on_line = all_words[f_idx:l_idx+1]
        print(f"Page {page_num} Line {line_num} (IDs {first_id}-{last_id}): {' '.join(words_on_line)}")
    else:
        print(f"Page {page_num} Line {line_num}: Empty / Non-Ayah")

conn_layout.close()
conn_quran.close()
