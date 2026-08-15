"""
quran_full_integrity_check.py
==============================
Comprehensive 6-point automated integrity verification across the ENTIRE Quran dataset.
Flags structural/count mismatches, gaps, duplicates, boundary errors, and word-count discrepancies.
"""

import sqlite3
import json
import sys
import os
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

# ── Paths ──────────────────────────────────────────────────────────────────────
BASE_DIR       = r"D:\AL Quran"
APP_DB_PATH    = os.path.join(BASE_DIR, "al_quran_app", ".dart_tool",
                              "sqflite_common_ffi", "databases", "al_quran.db")
LAYOUT_15_PATH = os.path.join(BASE_DIR, "qudratullah-indopak-15-lines.db")
LAYOUT_16_PATH = os.path.join(BASE_DIR, "taj-indopak-16-lines.db")
JSON_PATH      = os.path.join(BASE_DIR, "indopak-nastaleeq.json")

# ── Canonical Ayah Counts (114 Surahs) ─────────────────────────────────────────
CANONICAL_AYAH_COUNTS = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
    5, 4, 5, 6
]

print("=" * 80)
print("              COMPREHENSIVE QURAN INTEGRITY VERIFICATION REPORT            ")
print("=" * 80)

app_con = sqlite3.connect(APP_DB_PATH)
app_cur = app_con.cursor()

l15_con = sqlite3.connect(LAYOUT_15_PATH)
l15_con.row_factory = sqlite3.Row
l15_cur = l15_con.cursor()

l16_con = sqlite3.connect(LAYOUT_16_PATH)
l16_con.row_factory = sqlite3.Row
l16_cur = l16_con.cursor()

results = {}

# ══════════════════════════════════════════════════════════════════════════════
# CHECK 1: AYAH COUNT INTEGRITY
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "─" * 80)
print("CHECK 1: AYAH COUNT INTEGRITY (App SQLite 'ayahs' table)")
print("─" * 80)

total_ayahs_db = app_cur.execute("SELECT COUNT(*) FROM ayahs").fetchone()[0]
surah_count_db = app_cur.execute("SELECT COUNT(DISTINCT surah) FROM ayahs").fetchone()[0]

print(f"Total Ayahs in Database : {total_ayahs_db} (Expected: 6236)")
print(f"Total Surahs in Database: {surah_count_db} (Expected: 114)")

c1_issues = []

if total_ayahs_db != 6236:
    c1_issues.append(f"Global Ayah count mismatch: Found {total_ayahs_db}, expected 6236")

if surah_count_db != 114:
    c1_issues.append(f"Surah count mismatch: Found {surah_count_db}, expected 114")

surah_rows = app_cur.execute("SELECT surah, COUNT(*) FROM ayahs GROUP BY surah ORDER BY surah").fetchall()
db_surah_map = dict(surah_rows)

for s in range(1, 115):
    cnt = db_surah_map.get(s, 0)
    expected = CANONICAL_AYAH_COUNTS[s - 1]
    if cnt != expected:
        c1_issues.append(f"Surah {s:3d}: Found {cnt:3d} ayahs, expected {expected:3d}")

if c1_issues:
    print(f"❌ CHECK 1 FAILED — {len(c1_issues)} issues found:")
    for issue in c1_issues:
        print(f"   - {issue}")
else:
    print("✅ CHECK 1 PASSED — All 114 surahs have 100% correct canonical ayah counts (6,236 ayahs total).")

results['Check 1: Ayah Count Integrity'] = (len(c1_issues) == 0, len(c1_issues), c1_issues)


# ══════════════════════════════════════════════════════════════════════════════
# CHECK 2: WORD ID CONTINUITY (15-line & 16-line word_layout)
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "─" * 80)
print("CHECK 2: WORD ID CONTINUITY (indopak-nastaleeq.json & word_layout)")
print("─" * 80)

c2_issues = []

with open(JSON_PATH, encoding="utf-8") as f:
    json_data = json.load(f)

json_entries = sorted(json_data.values(), key=lambda e: (int(e["surah"]), int(e["ayah"]), int(e["word"])))
json_numeric_ids = [int(e["id"]) for e in json_entries]
min_id = min(json_numeric_ids)
max_id = max(json_numeric_ids)
total_json_words = len(json_numeric_ids)

print(f"Reference JSON Word Range: ID {min_id} to {max_id} (Total: {total_json_words:,} words)")

id_set = set(json_numeric_ids)
gaps = []
duplicates = []

if len(json_numeric_ids) != len(id_set):
    duplicates.append(f"JSON has {len(json_numeric_ids) - len(id_set)} duplicate numeric IDs")

for expected_id in range(min_id, max_id + 1):
    if expected_id not in id_set:
        gaps.append(expected_id)

if gaps:
    c2_issues.append(f"JSON Word ID gaps found ({len(gaps)} missing IDs): {gaps[:10]}...")

if duplicates:
    c2_issues.append(f"JSON Word ID duplicates found: {duplicates}")

for m_type in ['15_line', '16_line']:
    wl_rows = app_cur.execute("""
        SELECT page, line, word_id, surah, ayah 
        FROM word_layout 
        WHERE mushaf=? AND word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%'
    """, (m_type,)).fetchall()
    
    wl_ids = [r[2] for r in wl_rows]
    unique_wl_ids = set(wl_ids)
    if len(wl_ids) != len(unique_wl_ids):
        c2_issues.append(f"'{m_type}' word_layout has {len(wl_ids) - len(unique_wl_ids)} duplicate word_ids")

if c2_issues:
    print(f"❌ CHECK 2 FAILED — {len(c2_issues)} issues found:")
    for issue in c2_issues:
        print(f"   - {issue}")
else:
    print(f"✅ CHECK 2 PASSED — Word IDs are 100% sequential from {min_id} to {max_id} with 0 gaps and 0 duplicates.")

results['Check 2: Word ID Continuity'] = (len(c2_issues) == 0, len(c2_issues), c2_issues)


# ══════════════════════════════════════════════════════════════════════════════
# CHECK 3: AYAH WORD-RANGE BOUNDARY CONSISTENCY (15-line & 16-line DBs)
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "─" * 80)
print("CHECK 3: AYAH WORD-RANGE BOUNDARY CONSISTENCY")
print("─" * 80)

c3_issues = []

def check_layout_boundaries(mushaf_name, cur):
    rows = cur.execute("""
        SELECT page_number, line_number, line_type, first_word_id, last_word_id 
        FROM pages 
        WHERE line_type='ayah' 
        ORDER BY page_number, line_number
    """).fetchall()

    prev_last_id = None
    prev_loc = None

    for r in rows:
        fwid = r['first_word_id']
        lwid = r['last_word_id']
        loc = f"Page {r['page_number']} Line {r['line_number']}"

        if fwid is None or lwid is None:
            c3_issues.append(f"{mushaf_name} {loc}: NULL word_id bounds (first={fwid}, last={lwid})")
            continue

        if fwid > lwid:
            c3_issues.append(f"{mushaf_name} {loc}: Invalid bound range (first_word_id {fwid} > last_word_id {lwid})")

        if prev_last_id is not None:
            if fwid != prev_last_id + 1:
                c3_issues.append(f"{mushaf_name} Boundary Mismatch at {loc}: Expected first_word_id={prev_last_id + 1}, got {fwid} (previous {prev_loc} ended at {prev_last_id})")

        prev_last_id = lwid
        prev_loc = loc

print("Checking 15-line DB boundaries (qudratullah-indopak-15-lines.db)...")
check_layout_boundaries("15-Line", l15_cur)

print("Checking 16-line DB boundaries (taj-indopak-16-lines.db)...")
check_layout_boundaries("16-Line", l16_cur)

if c3_issues:
    print(f"❌ CHECK 3 FAILED — {len(c3_issues)} issues found:")
    for issue in c3_issues[:20]:
        print(f"   - {issue}")
    if len(c3_issues) > 20:
        print(f"   ... and {len(c3_issues) - 20} more")
else:
    print("✅ CHECK 3 PASSED — 100% boundary consistency across all ayah lines (last_word_id + 1 = next first_word_id).")

results['Check 3: Ayah Word-Range Boundaries'] = (len(c3_issues) == 0, len(c3_issues), c3_issues)


# ══════════════════════════════════════════════════════════════════════════════
# CHECK 4: BASMALLAH PLACEMENT
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "─" * 80)
print("CHECK 4: BASMALLAH PLACEMENT")
print("─" * 80)

c4_issues = []

# 1. Surah 1 Bismillah check (must be Ayah 1, not separate header)
s1_a1 = app_cur.execute("SELECT arabic_text FROM ayahs WHERE surah=1 AND ayah_number=1").fetchone()
if not s1_a1 or "بسم" not in s1_a1[0].replace("بِسْمِ", "بسم"):
    c4_issues.append("Surah 1 Ayah 1 is missing Bismillah text")

# 2. Surah 9 check in layout DBs and word_layout (Surah 9 MUST NOT have Bismillah line)
s9_l15_basmallah = l15_cur.execute("""
    SELECT p.page_number, p.line_number 
    FROM pages p 
    JOIN pages p_surah ON p.page_number = p_surah.page_number 
    WHERE p_surah.surah_number=9 AND p_surah.line_type='surah_name' AND p.line_type='basmallah'
""").fetchall()

if s9_l15_basmallah:
    for r in s9_l15_basmallah:
        c4_issues.append(f"15-Line DB: Surah 9 has invalid Basmallah at Page {r['page_number']} Line {r['line_number']}")

s9_l16_basmallah = l16_cur.execute("""
    SELECT p.page_number, p.line_number 
    FROM pages p 
    JOIN pages p_surah ON p.page_number = p_surah.page_number 
    WHERE p_surah.surah_number=9 AND p_surah.line_type='surah_name' AND p.line_type='basmallah'
""").fetchall()

if s9_l16_basmallah:
    for r in s9_l16_basmallah:
        c4_issues.append(f"16-Line DB: Surah 9 has invalid Basmallah at Page {r['page_number']} Line {r['line_number']}")

s9_wl_basmallah = app_cur.execute("SELECT mushaf, page, line FROM word_layout WHERE surah=9 AND word_id LIKE 'basmallah:%'").fetchall()
if s9_wl_basmallah:
    for r in s9_wl_basmallah:
        c4_issues.append(f"word_layout ({r[0]}): Surah 9 has invalid Basmallah at Page {r[1]} Line {r[2]}")

# 3. Check Surahs 2 to 114 (excl. 9) have Basmallah in word_layout
for m_type in ['15_line', '16_line']:
    for s in range(2, 115):
        if s == 9:
            continue
        has_b = app_cur.execute("SELECT COUNT(*) FROM word_layout WHERE mushaf=? AND surah=? AND word_id LIKE 'basmallah:%'", (m_type, s)).fetchone()[0]
        if has_b == 0:
            c4_issues.append(f"'{m_type}' word_layout: Surah {s} is missing its 'basmallah' line entry")

if c4_issues:
    print(f"❌ CHECK 4 FAILED — {len(c4_issues)} issues found:")
    for issue in c4_issues:
        print(f"   - {issue}")
else:
    print("✅ CHECK 4 PASSED — Basmallah lines correctly placed for Surahs 2-114 (excl. Surah 9), and Surah 1 Bismillah correctly included in Ayah 1.")

results['Check 4: Basmallah Placement'] = (len(c4_issues) == 0, len(c4_issues), c4_issues)


# ══════════════════════════════════════════════════════════════════════════════
# CHECK 5: CROSS-REFERENCE TEXT DIFF (Word Count Comparison per Ayah)
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "─" * 80)
print("CHECK 5: CROSS-REFERENCE WORD COUNT COMPARISON (IndoPak word_layout vs Uthmani ayahs)")
print("─" * 80)

c5_issues = []

# Compare word counts per ayah between Uthmani ayahs table and IndoPak word_layout table
# Note: In IndoPak script, compound words or waqf marks might differ slightly (±1-2 words),
# so we flag any ayah with a difference > 2 words for manual review.

for surah in range(1, 115):
    expected_ayah_count = CANONICAL_AYAH_COUNTS[surah - 1]
    for ayah in range(1, expected_ayah_count + 1):
        # Uthmani text word count
        uth_row = app_cur.execute("SELECT arabic_text FROM ayahs WHERE surah=? AND ayah_number=?", (surah, ayah)).fetchone()
        if not uth_row:
            c5_issues.append(f"Surah {surah:3d} Ayah {ayah:3d}: Missing in 'ayahs' table!")
            continue
            
        uth_text = uth_row[0].strip()
        if ayah == 1 and surah != 1 and surah != 9:
            uth_text = uth_text.replace("بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِیْمِ", "").strip()
            uth_text = uth_text.replace("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", "").strip()
        uth_words = [w for w in uth_text.split() if w not in ['۠', '۬', 'ۙ', 'ؕ', 'ۚ', 'ۖ', '۟']]
        uth_cnt = len(uth_words)

        # IndoPak 15_line word_layout count for this ayah
        ip15_cnt = app_cur.execute("""
            SELECT COUNT(*) FROM word_layout 
            WHERE mushaf='15_line' AND surah=? AND ayah=? AND word_id NOT LIKE 'surah_name:%' AND word_id NOT LIKE 'basmallah:%'
        """, (surah, ayah)).fetchone()[0]

        # In IndoPak word_layout, the verse end marker symbol is 1 extra word entry at the end of each ayah
        ip15_word_cnt = max(0, ip15_cnt - 1)

        diff = abs(ip15_word_cnt - uth_cnt)
        if diff > 2:
            c5_issues.append(f"Surah {surah:3d} Ayah {ayah:3d}: IndoPak 15_line has {ip15_word_cnt:2d} words vs Uthmani {uth_cnt:2d} words (Diff: {diff})")

if c5_issues:
    print(f"⚠️ CHECK 5 NOTICE — {len(c5_issues)} ayahs have > 2 word count variation between IndoPak and Uthmani scripts:")
    for issue in c5_issues[:20]:
        print(f"   - {issue}")
    if len(c5_issues) > 20:
        print(f"   ... and {len(c5_issues) - 20} more")
else:
    print("✅ CHECK 5 PASSED — 0 ayahs have significant word count discrepancies (> 2 words) across the entire Quran.")

results['Check 5: Cross-Ref Word Counts'] = (len(c5_issues) == 0, len(c5_issues), c5_issues)


# ══════════════════════════════════════════════════════════════════════════════
# CHECK 6: PAGE AND LINE LIMITS (15-line & 16-line mushafs)
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "─" * 80)
print("CHECK 6: PAGE AND LINE LIMITS")
print("─" * 80)

c6_issues = []

def check_page_line_limits(mushaf_name, cur, max_allowed_lines):
    rows = cur.execute("""
        SELECT page_number, COUNT(*) as line_cnt 
        FROM pages 
        GROUP BY page_number
    """).fetchall()

    pages_found = set()
    for r in rows:
        p_num = r['page_number']
        l_cnt = r['line_cnt']
        pages_found.add(p_num)

        if l_cnt > max_allowed_lines:
            c6_issues.append(f"{mushaf_name} Page {p_num} EXCEEDS line limit: Has {l_cnt} lines (Max allowed: {max_allowed_lines})")

    if pages_found:
        min_p = min(pages_found)
        max_p = max(pages_found)
        print(f"  {mushaf_name}: Pages {min_p} to {max_p} (Total: {len(pages_found)} pages, Max lines/page allowed: {max_allowed_lines})")
        
        for p in range(1, max_p + 1):
            if p not in pages_found:
                c6_issues.append(f"{mushaf_name} MISSING PAGE: Page {p} has 0 rows in DB!")
    else:
        c6_issues.append(f"{mushaf_name}: NO PAGES FOUND in database!")

print("Checking 15-line Mushaf limits (qudratullah-indopak-15-lines.db)...")
check_page_line_limits("15-Line Mushaf", l15_cur, 15)

print("Checking 16-line Mushaf limits (taj-indopak-16-lines.db)...")
check_page_line_limits("16-Line Mushaf", l16_cur, 16)

if c6_issues:
    print(f"❌ CHECK 6 FAILED — {len(c6_issues)} issues found:")
    for issue in c6_issues:
        print(f"   - {issue}")
else:
    print("✅ CHECK 6 PASSED — All pages respect maximum line limits (15 & 16), with zero missing pages.")

results['Check 6: Page/Line Limits'] = (len(c6_issues) == 0, len(c6_issues), c6_issues)


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY REPORT TABLE
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "=" * 80)
print("                           7. SUMMARY REPORT TABLE                             ")
print("=" * 80)
print(f"{'Check Category':<45} | {'Status':<10} | {'Issues Count':<12}")
print("─" * 75)

total_issues_all = 0
for cat, (passed, count, details) in results.items():
    status_str = "PASS ✅" if passed else "FAIL ❌"
    print(f"{cat:<45} | {status_str:<10} | {count:<12}")
    total_issues_all += count

print("─" * 75)
overall_str = "PASSED ✅" if total_issues_all == 0 else "FAILED ❌"
print(f"{'OVERALL INTEGRITY STATUS':<45} | {overall_str:<10} | {total_issues_all:<12}")
print("=" * 80 + "\n")

app_con.close()
l15_con.close()
l16_con.close()
