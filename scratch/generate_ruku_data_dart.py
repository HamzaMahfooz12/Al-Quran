import sqlite3
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

db_path = r"D:\AL Quran\al_quran_app\.dart_tool\sqflite_common_ffi\databases\al_quran.db"
con = sqlite3.connect(db_path)
cur = con.cursor()

cur.execute("SELECT surah, ayah_number, ruku FROM ayahs ORDER BY surah, ayah_number")
rows = cur.fetchall()

ruku_end_map = {}
current_surah = None
surah_ruku_count = 0
prev_ruku = None

for i, (s, a, r) in enumerate(rows):
    if s != current_surah:
        current_surah = s
        surah_ruku_count = 0
        prev_ruku = None

    if r != prev_ruku:
        surah_ruku_count += 1
        prev_ruku = r

    is_last = False
    if i == len(rows) - 1:
        is_last = True
    else:
        next_s, next_a, next_r = rows[i+1]
        if next_s != s or next_r != r:
            is_last = True

    if is_last:
        ruku_end_map[f"{s}:{a}"] = (surah_ruku_count, r)

con.close()

dart_code = """// AUTO-GENERATED FILE: Ruku (Rukh) data mapping
class RukuInfo {
  final int rukuInSurah;
  final int globalRuku;

  const RukuInfo({required this.rukuInSurah, required this.globalRuku});
}

class RukuData {
  static const Map<String, RukuInfo> endPoints = {
"""

for key, (r_in_surah, g_ruku) in ruku_end_map.items():
    dart_code += f"    '{key}': RukuInfo(rukuInSurah: {r_in_surah}, globalRuku: {g_ruku}),\n"

dart_code += """  };

  static RukuInfo? getRukuEndInfo(int surah, int ayah) {
    return endPoints['$surah:$ayah'];
  }
}
"""

with open(r"D:\AL Quran\al_quran_app\lib\data\ruku_data.dart", "w", encoding="utf-8") as f:
    f.write(dart_code)

print(f"Generated ruku_data.dart with {len(ruku_end_map)} Ruku end entries.")
